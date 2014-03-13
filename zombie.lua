minetest.register_craftitem("creatures:rotten_flesh", {
	description = "Rotten Flesh",
	inventory_image = "creatures_rotten_flesh.png",
	on_use = minetest.item_eat(1),
})


local z_chillaxin_speed = 1.5
local z_animation_speed = 15
local z_mesh = "creatures_mob.x"
local z_texture = {"creatures_zombie.png"}
local z_hp = 20
local z_drop = "creatures:rotten_flesh"

local z_player_radius = 14
local z_hit_radius = 1.4
local z_ll = 7

local z_sound_normal = "creatures_zombie"
local z_sound_hit = "creatures_zombie_hit"
local z_sound_dead = "creatures_zombie_death"

local z_spawn_nodes = {"default:dirt_with_grass","default:stone","default:dirt","default:desert_sand"}
local z_spawner_range = 17
local z_spawner_max_mobs = 6

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

local ANIM_STAND = 1
local ANIM_SIT = 2
local ANIM_LAY = 3
local ANIM_WALK  = 4
local ANIM_WALK_MINE = 5
local ANIM_MINE = 6

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

spawner_DEF = {
	hp_max = 1,
	physical = true,
	collisionbox = {0,0,0,0,0,0},
	visual = "mesh",
	visual_size = {x=0.42,y=0.42},
	mesh = z_mesh,
	textures = z_texture,
	makes_footstep_sound = false,
	timer = 0,
	automatic_rotate = math.pi * -2.9,
	m_name = "dummy"
}

spawner_DEF.on_activate = function(self)
	z_update_visuals_def(self)
	self.object:setvelocity({x=0, y=0, z=0})
	self.object:setacceleration({x=0, y=0, z=0})
	self.object:set_armor_groups({immortal=1})
end

spawner_DEF.on_step = function(self, dtime)
	self.timer = self.timer + 0.01
	local n = minetest.get_node_or_nil(self.object:getpos())
	if self.timer > 1 then
		if n and n.name and n.name ~= "creatures:zombie_spawner" then
			self.object:remove()
		end
	end
end

spawner_DEF.on_punch = function(self, hitter)
end

ZOMBIE_DEF.on_activate = function(self)
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
			--add wear to swords
			if not minetest.setting_getbool("creative_mode") then
				local item = puncher:get_wielded_item()
				local def = item:get_definition()
				if def and def.tool_capabilities and def.tool_capabilities.groupcaps
				   and def.tool_capabilities.groupcaps.snappy then
					local uses = def.tool_capabilities.groupcaps.snappy.uses or 10
					uses = uses*2 --since default values are too low
					local wear = 65535/uses
					item:add_wear(wear)
					puncher:set_wielded_item(item)
				end
			end
		end
	end

	if self.object:get_hp() < 1 then
	    local obj = minetest.env:add_item(my_pos, z_drop.." "..math.random(0,3))
	end
end

ZOMBIE_DEF.on_step = function(self, dtime)
	if self.dead then return end
	self.timer = self.timer + 0.01
	self.turn_timer = self.turn_timer + 0.01
	self.jump_timer = self.jump_timer + 0.01
	self.punch_timer = self.punch_timer + 0.01
	self.attacking_timer = self.attacking_timer + 0.01
	self.sound_timer = self.sound_timer + 0.01

	local current_pos = self.object:getpos()
	local current_node = minetest.env:get_node(current_pos)
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
	    		local obj = minetest.env:add_item(current_pos, z_drop.." "..math.random(0,3))
		end)
	end
	
	-- die when in water, lava or sunlight
	local wtime = minetest.env:get_timeofday()
	local ll = minetest.env:get_node_light({x=current_pos.x,y=current_pos.y+1,z=current_pos.z}) or 0
	if current_node.name == "default:water_source" or
	   current_node.name == "default:water_flowing" or 
	   current_node.name == "default:lava_source" or 
	   current_node.name == "default:lava_flowing" or
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

		if self.attacker == "" and self.turn_timer > math.random(1,4) then--and yawwer == true then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
		end
		self.object:setvelocity({x=0,y=self.object:getvelocity().y,z=0})
		if self.npc_anim ~= ANIM_STAND then
			self.anim = z_get_animations()
			self.object:set_animation({x=self.anim.stand_START,y=self.anim.stand_END}, z_animation_speed, 0)
			self.npc_anim = ANIM_STAND
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
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
			--self.state = 2
		end
		if self.direction ~= nil then
			self.object:setvelocity({x=self.direction.x*z_chillaxin_speed,y=self.object:getvelocity().y,z=self.direction.z*z_chillaxin_speed})
		end
		if self.turn_timer > math.random(1,4) and not self.attacker then
			self.yaw = 360 * math.random()
			self.object:setyaw(self.yaw)
			self.turn_timer = 0
			self.direction = {x = math.sin(self.yaw)*-1, y = -20, z = math.cos(self.yaw)}
		end
		if self.npc_anim ~= ANIM_WALK then
			self.npc_anim = ANIM_WALK
			--self.anim = z_get_animations()
			self.object:set_animation({x=self.anim.walk_START,y=self.anim.walk_END}, z_animation_speed, 0)
			self.npc_anim = ANIM_WALK
		end
		--jump
		if self.direction ~= nil then
			if self.jump_timer > 0.3 then
				self.jump_timer = 0
				local p = current_pos
				local n = minetest.env:get_node({x=p.x + self.direction.x,y=p.y-0.5,z=p.z + self.direction.z})
				--print(n.name)
				if n and n.name and minetest.registered_items[n.name].walkable then
					self.object:setvelocity({x=self.object:getvelocity().x,y=7,z=self.object:getvelocity().z})
				end
				--end
			end
		end

		if self.attacker ~= "" and minetest.setting_getbool("enable_damage") then
			local s = current_pos
			local p = self.attacker:getpos()
			if (s ~= nil and p ~= nil) then
				local dist = ((p.x-s.x)^2 + (p.y-s.y)^2 + (p.z-s.z)^2)^0.5

				if dist < z_hit_radius and self.attacking_timer > 0.6 then
				self.attacker:punch(self.object, 1.0,  {
					full_punch_interval=1.0,
					damage_groups = {fleshy=1}
				})
					self.attacking_timer = 0
				end
			end
		end
	end
end

minetest.register_entity("creatures:zombie", ZOMBIE_DEF)
minetest.register_entity("creatures:z_spawner_mob", spawner_DEF)


--spawn-egg/spawner

minetest.register_craftitem("creatures:zombie_spawn_egg", {
	description = "Zombie spawn-egg",
	inventory_image = "creatures_egg_zombie.png",
	liquids_pointable = false,
	stack_max = 99,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local p = pointed_thing.above
			p.y = p.y+1
			creatures.spawn(p, 1, "creatures:zombie")
			if not minetest.setting_getbool("creative_mode") then itemstack:take_item() end
			return itemstack
		end
	end,

})

minetest.register_node("creatures:zombie_spawner", {
	description = "Zombie spawner",
	paramtype = "light",
	tiles = {"creatures_spawner.png"},
	is_ground_content = true,
	drawtype = "allfaces",
	groups = {cracky=1,level=1},
	drop = "",
	on_construct = function(pos)
		pos.y = pos.y + 0.08
		minetest.env:add_entity(pos,"creatures:z_spawner_mob")
	end,
	on_destruct = function(pos)
		for  _,obj in ipairs(minetest.env:get_objects_inside_radius(pos, 1)) do
			if not obj:is_player() then 
				if obj ~= nil and obj:get_luaentity().m_name == "dummy" then
					obj:remove()	
				end
			end
		end
	end
})

if not minetest.setting_getbool("only_peaceful_mobs") then
 -- spawn randomly in world
 minetest.register_abm({
	nodenames = z_spawn_nodes,
	interval = 40.0,
	chance = 7200,
	action = function(pos, node, active_object_count, active_object_count_wider)
			local n = minetest.get_node(pos)
			--if n and n.name and n.name ~= "default:stone" and math.random(1,4)>3 then return end
			pos.y = pos.y+1
			local ll = minetest.env:get_node_light(pos)
			local wtime = minetest.env:get_timeofday()
			if not ll then
				return
			end
			if ll >= z_ll then
				return
			end
			if ll < -1 then
				return
			end
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end
			pos.y = pos.y+1
			if minetest.env:get_node(pos).name ~= "air" then
				return
			end
			creatures.spawn(pos, 1, "creatures:zombie")
	end
 })

 minetest.register_abm({
	nodenames = {"creatures:zombie_spawner"},
	interval = 2.0,
	chance = 20,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local player_near = false
		local mobs = 0
		for  _,obj in ipairs(minetest.env:get_objects_inside_radius(pos, z_spawner_range)) do
			if obj:is_player() then
				player_near = true 
			else
				if obj:get_luaentity().mob_name == "zombie" then mobs = mobs + 1 end
			end
		end
		if player_near then
			if mobs < z_spawner_max_mobs then
				pos.x = pos.x+1
				local p = minetest.find_node_near(pos, 5, {"air"})	
				--p.y = p.y+1
				local ll = minetest.env:get_node_light(p)
				local wtime = minetest.env:get_timeofday()
				if not ll then return end
				if ll > 8 then return end
				if ll < -1 then return end
				if minetest.env:get_node(p).name ~= "air" then return end
				p.y = p.y+1
				if minetest.env:get_node(p).name ~= "air" then return end
				if (wtime > 0.2 and wtime < 0.805) and pos.y > 0 then return end
				p.y = p.y-1
				creatures.spawn(p, 1, "creatures:zombie")
			end
		end
	end
 })
end
