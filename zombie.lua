local z_chillaxin_speed = 1.5
local z_animation_speed = 15
local z_mesh = "creatures_mob.x"
local z_texture = {"creatures_zombie.png"}
local z_hp = 20
local z_drop = "creatures:rotten_flesh"
local z_life_max = 80 --~5min

local z_player_radius = 14
local z_hit_radius = 1.4
creatures.z_ll = 7

local z_sound_normal = "creatures_zombie"
local z_sound_hit = "creatures_zombie_hit"
local z_sound_dead = "creatures_zombie_death"

creatures.z_spawn_nodes = {"default:dirt_with_grass","default:stone","default:dirt","default:desert_sand"}
creatures.z_spawner_range = 17
creatures.z_spawner_max_mobs = 6

local function z_get_animations()
	return {
		stand_START = 0,
		stand_END = 79,
		lay_START = 162,
		lay_END = 166,
		walk_START = 168,
		walk_END = 188,
		--  not used
		sit_START = 81,
		sit_END = 160
	}
end

function z_hit(self)
	local sound = z_sound_hit
	if self.object:get_hp() < 1 then sound = z_sound_dead end
	minetest.sound_play(sound, {pos = self.object:getpos(), max_hear_distance = 10, loop = false, gain = 0.4})
	prop = {
		mesh = z_mesh,
		textures = {"creatures_zombie.png^creatures_zombie_hit.png"},
	}
	self.object:set_properties(prop)
	self.can_punch = false
	minetest.after(0.4, function()
		z_update_visuals_def(self)
	end)
end

function z_update_visuals_def(self)
	self.can_punch = true
	prop = {
		mesh = z_mesh,
		textures = z_texture,
	}
	self.object:set_properties(prop)
end

ZOMBIE_DEF = {
	physical = true,
	collisionbox = {-0.25, -1, -0.3, 0.25, 0.75, 0.3},
	visual = "mesh",
	visual_size = {x=1, y=1},
	mesh = z_mesh,
	textures = z_texture,
	makes_footstep_sound = true,
	npc_anim = 0,
	lifetime = 0,
	timer = 0,
	turn_timer = 0,
	vec = 0,
	yaw = 0,
	yawwer = 0,
	state = 1,
	can_punch = true,
	dead = false,
	jump_timer = 0,
	last_pos = {x=0,y=0,z=0},
	punch_timer = 0,
	sound_timer = 0,
	attacker = "",
	attacking_timer = 0,
	mob_name = "zombie"
}

ZOMBIE_DEF.get_staticdata = function(self)
	return minetest.serialize({
		itemstring = self.itemstring,
		timer = self.timer,
		lifetime = self.lifetime,
	})
end

ZOMBIE_DEF.on_activate = function(self, staticdata, dtime_s)
	z_update_visuals_def(self)
	self.anim = z_get_animations()
	self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, z_animation_speed, 0)
	self.npc_anim = ANIM_STAND
	self.object:setacceleration({x=0,y=-20,z=0})
	self.state = 1
	self.object:set_hp(z_hp)
	self.object:set_armor_groups({fleshy=130})
	self.last_pos = {x=0,y=0,z=0}
	self.can_punch = true
	self.dead = false
	self.lifetime = 0
	if staticdata then
		local tmp = minetest.deserialize(staticdata)
		if tmp and tmp.timer then
			self.timer = tmp.timer
		end
		if tmp and tmp.lifetime ~= nil then
			self.lifetime = tmp.lifetime
		end
	end
end

ZOMBIE_DEF.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
	if not self.can_punch then return end

	local my_pos = self.object:getpos()

	if puncher ~= nil then
		self.attacker = puncher
		if time_from_last_punch >= 0.45 then
			z_hit(self)
			local v = self.object:getvelocity()
			self.direction = {x=v.x, y=v.y, z=v.z}
			self.punch_timer = 0
			self.object:setvelocity({x=dir.x*z_chillaxin_speed,y=5,z=dir.z*z_chillaxin_speed})
			if self.state == 1 then
				self.state = 8
			elseif self.state >= 2 then
				self.state = 9
			end
			-- add wear to sword/tool
			creatures.add_wear(puncher, tool_capabilities)
		end
	end

	if self.object:get_hp() < 1 then
	    creatures.drop(my_pos, {{name=z_drop, count=math.random(0,2)}}, dir)
	end
end

ZOMBIE_DEF.on_step = function(self, dtime)
	if self.dead then return end
	self.timer = self.timer + 0.01
	self.lifetime = self.lifetime + 0.01
	self.turn_timer = self.turn_timer + 0.01
	self.jump_timer = self.jump_timer + 0.01
	self.punch_timer = self.punch_timer + 0.01
	self.attacking_timer = self.attacking_timer + 0.01
	self.sound_timer = self.sound_timer + 0.01

	local current_pos = self.object:getpos()
	local current_node = minetest.env:get_node_or_nil(current_pos)
	if self.time_passed == nil then
		self.time_passed = 0
	end

	-- death
	if self.object:get_hp() < 1 then
		self.object:setvelocity({x=0,y=-20,z=0})
		self.object:set_hp(0)
		self.attacker = ""
		self.state = 0
		self.dead = true
		minetest.sound_play(z_sound_dead, {pos = current_pos, max_hear_distance = 10, gain = 0.9})
		self.object:set_animation({x=self.anim.lay_START,y=self.anim.lay_END}, z_animation_speed, 0)
		minetest.after(1, function()
			self.object:remove()	
			if self.object:get_hp() < 1 and creatures.drop_on_death then
			    creatures.drop(current_pos, {{name=z_drop, count=math.random(0,2)}})
			end
		end)
	end

	-- die if old
	if self.lifetime > z_life_max then
		self.object:set_hp(0)
		self.state = 0
		self.dead = true
		self.object:remove()
		return
	end
	
	-- die when in water, lava or sunlight
	local wtime = minetest.env:get_timeofday()
	local ll = minetest.env:get_node_light({x=current_pos.x,y=current_pos.y+1,z=current_pos.z}) or 0
	local nn = nil
	if current_node ~= nil then nn = current_node.name end
	if nn ~= nil and nn == "default:water_source" or
	   nn == "default:water_flowing" or 
	   nn == "default:lava_source" or 
	   nn == "default:lava_flowing" or
	   (wtime > 0.2 and wtime < 0.805 and current_pos.y > 0 and ll > 11) then
		self.sound_timer = self.sound_timer + dtime
		if self.sound_timer >= 0.8 then
			local damage = 5
			if ll > 11 then damage = 2 end
			self.sound_timer = 0
			self.object:set_hp(self.object:get_hp()-damage)
			z_hit(self)
		end
	 else
		self.time_passed = 0
	 end

	-- update moving state every 0.5 or 1 second
	if self.state < 3 then
		if self.timer > 0.2 then
			if self.attacker == "" then
				self.state = math.random(1,2)
			else self.state = 5 end
			self.timer = 0
		end
	end

	-- play random sound
	if self.sound_timer > math.random(5,35) then
		minetest.sound_play(z_sound_normal, {pos = current_pos, max_hear_distance = 10, gain = 0.7})
		self.sound_timer = 0
	end

	-- after knocked back
	if self.state >= 8 then
		if self.punch_timer > 0.15 then
			if self.state == 9 then
				self.object:setvelocity({x=self.direction.x*z_chillaxin_speed,y=-20,z=self.direction.z*z_chillaxin_speed})
				self.state = 2
			elseif self.state == 8 then
				self.object:setvelocity({x=0,y=-20,z=0})
				self.state = 1
			end
		end
	end

	--STANDING
	if self.state == 1 then
		self.yawwer = true
		self.attacker = ""
		-- seach for players
		for  _,object in ipairs(minetest.env:get_objects_inside_radius(current_pos, z_player_radius)) do
			if object:is_player() then
				self.yawwer = false
				NPC = current_pos
				PLAYER = object:getpos()
				self.vec = {x=PLAYER.x-NPC.x, y=PLAYER.y-NPC.y, z=PLAYER.z-NPC.z}
				self.yaw = math.atan(self.vec.z/self.vec.x)+math.pi^2
				if PLAYER.x > NPC.x then
					self.yaw = self.yaw + math.pi
				end
				self.yaw = self.yaw - 2
				self.object:setyaw(self.yaw)
				self.attacker = object
			end
		end

		if self.attacker == "" and self.turn_timer > math.random(1,4) then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
		end
		self.object:setvelocity({x=0,y=self.object:getvelocity().y,z=0})
		if self.npc_anim ~= creatures.ANIM_STAND then
			self.anim = z_get_animations()
			self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, z_animation_speed, 0)
			self.npc_anim = creatures.ANIM_STAND
		end
		if self.attacker ~= "" then
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
			self.state = 2
		end
	end

	--UPDATE DIR
	if self.state == 5 then
		self.yawwer = true
		self.attacker = ""
		-- seach for players
		for  _,object in ipairs(minetest.env:get_objects_inside_radius(current_pos, z_player_radius)) do
			if object:is_player() then
				self.yawwer = false
				NPC = current_pos
				PLAYER = object:getpos()
				self.vec = {x=PLAYER.x-NPC.x, y=PLAYER.y-NPC.y, z=PLAYER.z-NPC.z}
				self.yaw = math.atan(self.vec.z/self.vec.x)+math.pi^2
				if PLAYER.x > NPC.x then
					self.yaw = self.yaw + math.pi
				end
				self.yaw = self.yaw - 2
				self.object:setyaw(self.yaw)
				self.attacker = object
			end
		end

		if self.attacker ~= "" then
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
			self.state = 2
		else 
			self.state =1
		end
	end

	-- WALKING
	if self.state == 2 then
		
		if self.attacker ~= "" then
			self.direction = {x=math.sin(self.yaw)*-1, y=-20, z=math.cos(self.yaw)}
		end
		if self.direction ~= nil then
			self.object:setvelocity({x=self.direction.x*z_chillaxin_speed,y=self.object:getvelocity().y,z=self.direction.z*z_chillaxin_speed})
		end
		if self.turn_timer > math.random(1,4) and not self.attacker then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x=math.sin(self.yaw)*-1, y=-20, z=math.cos(self.yaw)}
		end
		if self.npc_anim ~= creatures.ANIM_WALK then
			self.npc_anim = creatures.ANIM_WALK
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, z_animation_speed, 0)
		end

		--jump
		local p = current_pos
		p.y = p.y-0.5
		creatures.jump(self, p, 7.4, 0.25)

		if self.attacker ~= "" and minetest.setting_getbool("enable_damage") then
			local s = current_pos
			local attacker_pos = self.attacker:getpos() or nil
			if attacker_pos == nil then return end
			local p = attacker_pos
			if (s ~= nil and p ~= nil) then
				local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5
				creatures.attack(self, current_pos, attacker_pos, dist, z_hit_radius)
			end
		end
	end
end

minetest.register_entity("creatures:zombie", ZOMBIE_DEF)
