local s_chillaxin_speed = 1.5
local s_animation_speed = 15
local s_mesh = "creatures_sheep.x"
local s_texture = {"creatures_sheep.png"}
local s_hp = 8
local s_life_max = 80 --~5min
local s_drop = "wool:white"
local s_drop2 = "creatures:flesh"

local s_player_radius = 14

local s_sound_normal = "creatures_sheep"
local s_sound_hit = "creatures_sheep"
local s_sound_dead = "creatures_sheep"
local s_sound_shears = "creatures_shears"

creatures.s_spawn_nodes = {"default:dirt_with_grass"}

local function s_get_animations()
	return {
		stand_START = 0,
		stand_END = 80,
		walk_START = 81,
		walk_END = 100,
		eat_START = 107,
		eat_END = 185
	}
end

local function s_eat_anim(self)
	self.object:set_animation({x=self.anim.eat_START,y=self.anim.eat_END}, s_animation_speed, 0)
	self.npc_anim = creatures.ANIM_EAT
end

function s_hit(self)
	local sound = s_sound_hit
	if self.object:get_hp() < 1 then sound = s_sound_dead end
	minetest.sound_play(sound, {pos = self.object:getpos(), max_hear_distance = 10, loop = false, gain = 0.4})
	prop = {
		mesh = s_mesh,
		textures = {self.txture[1].."^creatures_sheep_hit.png"},
	}
	self.object:set_properties(prop)
	self.can_punch = false
	minetest.after(0.4, function()
		s_update_visuals_def(self)
	end)
end

function s_update_visuals_def(self)
	self.txture = {"creatures_sheep.png"}
	if not self.has_wool then
		self.txture = {"creatures_sheep_shaved.png"}
	end
	prop = {
		mesh = s_mesh,
		textures = self.txture,
	}
	self.object:set_properties(prop)
end

SHEEP_DEF = {
	physical = true,
	collisionbox = {-0.4, -0.01, -0.6, 0.4, 0.9, 0.4},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = s_mesh,
	textures = s_texture,
	txture = s_texture,
	makes_footstep_sound = true,
	npc_anim = 0,
	lifetime = 0,
	timer = 0,
	turn_timer = 0,
	vec = 0,
	yaw = 0,
	yawwer = 0,
	has_wool = true,
	state = 1,
	can_punch = true,
	dead = false,
	jump_timer = 0,
	last_pos = {x=0,y=0,z=0},
	punch_timer = 0,
	sound_timer = 0,
	feeder = "",
	mob_name = "sheep"
}

SHEEP_DEF.get_staticdata = function(self)
	return minetest.serialize({
		itemstring = self.itemstring,
		timer = self.timer,
		txture = self.txture,
		has_wool = self.has_wool,
		lifetime = self.lifetime,
	})
end

SHEEP_DEF.on_activate = function(self, staticdata, dtime_s)
	self.txture = s_texture
	s_update_visuals_def(self)
	self.anim = s_get_animations()
	self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, s_animation_speed, 0)
	self.npc_anim = ANIM_STAND
	self.object:setacceleration({x=0,y=-20,z=0})
	self.object:setyaw(self.object:getyaw()+((math.random(0,90)-45)/45*math.pi))
	self.lastpos = self.object:getpos()
	self.state = 1
	self.object:set_hp(s_hp)
	self.object:set_armor_groups({fleshy=130})
	self.can_punch = true
	self.dead = false
	self.has_wool = true
	self.lifetime = 0
	self.feeder = ""
	if staticdata then
		local tmp = minetest.deserialize(staticdata)
		if tmp and tmp.timer then
			self.timer = tmp.timer
		end
		if tmp and tmp.has_wool ~= nil then
			self.has_wool = tmp.has_wool
		end
		if tmp and tmp.lifetime ~= nil then
			self.lifetime = tmp.lifetime
		end
		if not self.has_wool then
			s_update_visuals_def(self)
		end
	end
end

SHEEP_DEF.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
	if not self.can_punch then return end
	
	self.feeder = ""
	--SET RUN state (panic)
	self.state = 4
	self.timer = 0

	if puncher ~= nil then
		if time_from_last_punch >= 0.2 then --0.45
			s_hit(self)
			local v = self.object:getvelocity()
			self.direction = {x=v.x, y=v.y, z=v.z}
			self.punch_timer = 0
			self.object:setvelocity({x=dir.x*2.5,y=5.2,z=dir.z*2.5})
			self.state = 9
			-- add wear to sword/tool
			creatures.add_wear(puncher, tool_capabilities)
		end

		local my_pos = self.object:getpos()
		my_pos.y = my_pos.y + 0.4

		-- drop 1-2 whool when punched
		if self.has_wool then
			self.has_wool = false
			creatures.drop(my_pos, {{name=s_drop, count=math.random(1,2)}}, dir)
		end
		if self.object:get_hp() < 1 then
			creatures.drop(my_pos, {{name=s_drop2, count=1}}, dir)
		end
	end

end

SHEEP_DEF.on_rightclick = function(self, clicker)
	if not clicker or not self.has_wool then
		return
	end

	local item = clicker:get_wielded_item()
	local name = item:get_name()
	if item and name and name == "creatures:shears" then
		local my_pos = self.object:getpos()
		minetest.sound_play(s_sound_shears, {pos = my_pos, max_hear_distance = 10, gain = 1})
		my_pos.y = my_pos.y + 0.4
		self.has_wool = false
		s_update_visuals_def(self)
		creatures.drop(my_pos, {{name=s_drop, count=2}})
		if not minetest.setting_getbool("creative_mode") then
			item:add_wear(65535/100)
			clicker:set_wielded_item(item)
		end
	end
end

SHEEP_DEF.on_step = function(self, dtime)
	if self.dead then return end
	if self.lifetime == nil then self.lifetime = 0 end
	self.timer = self.timer + 0.01
	self.lifetime = self.lifetime + 0.01
	self.turn_timer = self.turn_timer + 0.01
	self.jump_timer = self.jump_timer + 0.01
	self.punch_timer = self.punch_timer + 0.01
	self.sound_timer = self.sound_timer + 0.01

	local current_pos = self.object:getpos()
	local current_node = minetest.env:get_node(current_pos)

	-- death
	if self.object:get_hp() < 1 then
		self.object:setvelocity({x=0,y=-20,z=0})
		self.object:set_hp(0)
		self.state = 0
		self.dead = true
		minetest.sound_play(s_sound_dead, {pos = current_pos, max_hear_distance = 10, gain = 0.9})
		self.object:set_animation({x=self.anim.lay_START,y=self.anim.lay_END}, s_animation_speed, 0)
		minetest.after(0.5, function()
			if creatures.drop_on_death then
				local drop = {{name=s_drop2, count=1}}
				if self.has_wool then
					drop[2] = {name=s_drop, count=math.random(1,2)}
				end
				creatures.drop(current_pos, drop, dir)
			end
			self.object:remove()
		end)
	end

	-- die if old and alone
	if self.lifetime > s_life_max then
		if creatures.find_mates(current_pos, "sheep", 15) then
			self.lifetime = 0
		else
			self.object:set_hp(0)
			self.state = 0
			self.dead = true
			self.object:remove()
			return
		end
	end

	-- die when in water, lava
	local wtime = minetest.env:get_timeofday()
	local ll = minetest.env:get_node_light({x=current_pos.x,y=current_pos.y+1,z=current_pos.z}) or 0
	local nn = nil
	if current_node ~= nil then nn = current_node.name end
	if nn ~= nil and nn == "default:water_source" or
	   nn == "default:water_flowing" or 
	   nn == "default:lava_source" or 
	   nn == "default:lava_flowing" then
		self.sound_timer = self.sound_timer + 0.1
		if self.sound_timer >= 0.8 then
			local damage = 2
			self.sound_timer = 0
			self.object:set_hp(self.object:get_hp()-damage)
			s_hit(self)
		end
	 end

	-- update moving state depending on current state
	if self.state < 4 then
		if self.timer > 4/self.state then
			self.timer = 0
			--local new = math.random(1,3)
			--if self.state == 3 then new = 1 end
			--if self.feeder == "" then new = 5 end
			self.state = 5--new
			s_update_visuals_def(self)
		end
	elseif self.state == 4 and self.timer > 1.5 then
		self.state = 2
		self.timer = 0
	elseif self.state == 5 then
		local new = math.random(1,3)
		if self.state == 3 then new = 1 end
		if self.feeder ~= "" then new = 5 end
		self.state = new
		self.timer = 0
		--s_update_visuals_def(self)	
	end

	-- play random sound
	local num = tonumber(self.lifetime/2) or 35
	if num < 6 then num = 6 end
	if self.sound_timer > self.timer + math.random(5, num) then
		minetest.sound_play(s_sound_normal, {pos = current_pos, max_hear_distance = 10, gain = 0.7})
		self.sound_timer = 0
	end

	-- after knocked back
	if self.state >= 8 then
		if self.punch_timer > 0.15 then
			if self.state == 9 then
				self.object:setvelocity({x=self.direction.x*s_chillaxin_speed,y=-20,z=self.direction.z*s_chillaxin_speed})
				self.state = 4
				self.punch_timer = 0
			elseif self.state == 8 then
				self.object:setvelocity({x=0,y=-20,z=0})
				self.state = 1
			end
			self.can_punch = true
		end
	end

	--STANDING
	if self.state == 1 then
		self.yawwer = true
		if self.turn_timer > math.random(1,4) then
			local last = self.yaw
			self.yaw = last + math.random(-0.5,1)
			if self.yaw > 22 or self.yaw < -17 then self.yaw = 0 end
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
		end
		self.object:setvelocity({x=0,y=self.object:getvelocity().y,z=0})
		if self.npc_anim ~= creatures.ANIM_STAND then
			self.anim = s_get_animations()
			self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, s_animation_speed, 0)
			self.npc_anim = creatures.ANIM_STAND
		end
		
	end

	-- stop walking when not moving	
	if self.state == 2 and creatures.compare_pos(self.object:getpos(),self.lastpos) and self.jump_timer <= 0.2 then
		self.state = 1
	end

	-- CHECK FEEDER
	if self.state == 5 then
		self.feeder = ""
		creatures.follow(self, {{name="farming:wheat"}}, 8)
		if self.feeder ~= "" then
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
			self.state = 2
		else 
			local new = math.random(1,3)
			if self.state == 3 then new = 1 end
			self.state = new
		end
	end

	-- WALKING
	if self.state == 2 or self.state == 4 then
		self.lastpos = self.object:getpos()
		local speed = 1
		local anim = creatures.ANIM_WALK
		if self.state == 4 then
			speed = 2.2
			anim = creatures.ANIM_RUN
		end
		if self.feeder ~= "" then
			--use this for following weed, etc
			--self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
			self.state = 5
		end

		if self.direction ~= nil then
			self.object:setvelocity({x=self.direction.x*s_chillaxin_speed*speed,y=self.object:getvelocity().y,z=self.direction.z*s_chillaxin_speed*speed})
		end
		if (self.turn_timer > math.random(0.8,2)) or (self.state == 4 and self.turn_timer > 0.2) then
			if self.state == 2 then
				local last = self.yaw
				self.yaw = last + math.random(-1,0.5)
				if self.yaw > 22 or self.yaw < -17 then self.yaw = 0 end
			else
				self.yaw = 360 * math.random()
			end
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
		end
		if self.npc_anim ~= anim then
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, s_animation_speed*speed, 0)
			self.npc_anim = anim
		end
		--jump
		creatures.jump(self, current_pos, 7.7, 0.2)
	end

	-- EATING
	if self.state == 3 then--and not self.has_wool then
		self.object:setvelocity({x=0,y=-20,z=0})
		local p = {x=current_pos.x,y=current_pos.y-1,z=current_pos.z}
		local n = minetest.get_node(p) or nil
		if n and n.name and n.name == "default:dirt_with_grass" then
			if self.timer == 0 then 
				s_eat_anim(self)
				self.timer = 0.45
			end
		 	minetest.after(1.8,function()
				self.has_wool = true
				minetest.set_node(p,{name="default:dirt"})
			end)
		end
	end
end

minetest.register_entity("creatures:sheep", SHEEP_DEF)
