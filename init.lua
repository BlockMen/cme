creatures = {}

creatures.ANIM_STAND = 1
creatures.ANIM_SIT = 2
creatures.ANIM_LAY = 3
creatures.ANIM_WALK  = 4
creatures.ANIM_EAT = 5
creatures.ANIM_RUN = 6

local tool_uses = {0, 30, 110, 150, 280, 300, 500, 1000}

-- helping functions

function creatures.spawn(pos, number, mob, limit, range)
	if not pos or not number or not mob then return end
	if number < 1 then return end
	if limit == nil then limit = 1 end
	if range == nil then range = 10 end
	local m_name = string.sub(mob,11)
	local res,mobs,player_near = creatures.find_mates(pos, m_name, range)
	for i=1,number do
		local x = 1/math.random(1,3)
		local z = 1/math.random(1,3)
		local p = {x=pos.x+x,y=pos.y,z=pos.z+z}
		if mobs+i <= limit then
			minetest.after(i/5,function()
				minetest.env:add_entity(p, mob)
				minetest.log("action", "Spawned "..mob.." at ("..pos.x..","..pos.y..","..pos.z..")")
			end)
		end
	end
end

function creatures.add_wear(player, def)
	if not minetest.setting_getbool("creative_mode") then
		local item = player:get_wielded_item()
		if def and def.damage_groups and def.damage_groups.fleshy then
			local uses = tool_uses[def.damage_groups.fleshy] or 0
			if uses > 0 then
				local wear = 65535/uses
				item:add_wear(wear)
				player:set_wielded_item(item)
			end
		end
	end
end

function creatures.drop(pos, items, dir)
	if dir == nil then
		dir = {x=1,y=1,z=1}
	end
	for _,item in ipairs(items) do
		for i=1,item.count do
			local x = 1/math.random(1,5)*dir.x--math.random(0, 6)/3 - 0.5*dir.x
			local z = 1/math.random(1,5)*dir.z--math.random(0, 6)/3 - 0.5*dir.z
			local p = {x=pos.x+x,y=pos.y,z=pos.z+z}
			local node = minetest.get_node_or_nil(p)
			if node == nil or not node.name or node.name ~= "air" then
				p = pos
			end
			local obj = minetest.env:add_item(p, {name=item.name})
		end
	end
end

function creatures.find_mates(pos, name, radius)
	local player_near = false
	local mobs = 0
	for  _,obj in ipairs(minetest.env:get_objects_inside_radius(pos, radius)) do
		if obj:is_player() then
			player_near = true 
		else
			local entity = obj:get_luaentity()
			if entity and entity.mob_name and entity.mob_name == name then
				mobs = mobs + 1 
			end
		end
	end
	if mobs > 1 then
		return true,mobs,player_near
	end
	return false,mobs,player_near
end

function creatures.compare_pos(pos1,pos2)
	if pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z then
		return true
	end
	return false
end

function creatures.attack(self, pos1, pos2, dist, range)
	if not self then return end
	if not pos1 or not pos2 then return end
	if minetest.line_of_sight(pos1,pos2) ~= true then
		return
	end
	if dist < range and self.attacking_timer > 0.6 then
		self.attacker:punch(self.object, 1.0,  {
				full_punch_interval=1.0,
				damage_groups = {fleshy=1}
		})
		self.attacking_timer = 0
	end
end

function creatures.jump(self, pos, jump_y, timer)
	if not self or not pos then return end
	if self.direction ~= nil then
		if self.jump_timer > timer then
			self.jump_timer = 0
			local p = {x=pos.x + self.direction.x,y=pos.y,z=pos.z + self.direction.z}-- pos
			local n = minetest.get_node_or_nil(p)
			p.y = p.y+1
			local n2 = minetest.get_node_or_nil(p)
			local def = nil
			local def2 = nil
			if n and n.name then
				def = minetest.registered_items[n.name]
			end
			if n2 and n2.name then
				def2 = minetest.registered_items[n2.name]
			end
			if def and def.walkable and def2 and not def2.walkable and not def.groups.fences and n.name ~= "default:fence_wood" then-- 
				self.object:setvelocity({x=self.object:getvelocity().x,y=jump_y,z=self.object:getvelocity().z})
			end
		end
	end
end

-- hostile mobs
dofile(minetest.get_modpath("creatures").."/ghost.lua")
dofile(minetest.get_modpath("creatures").."/zombie.lua")

-- friendly mobs
dofile(minetest.get_modpath("creatures").."/sheep.lua")

-- spawning
dofile(minetest.get_modpath("creatures").."/spawn.lua")
dofile(minetest.get_modpath("creatures").."/spawners.lua")
-- other stuff
dofile(minetest.get_modpath("creatures").."/items.lua")
