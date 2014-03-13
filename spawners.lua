function creatures.register_spawner(mob,size,offset,mesh,texture,range,max,max_ll,min_ll,day_only)
	local DUMMY  = {
		hp_max = 1,
		physical = true,
		collisionbox = {0,0,0,0,0,0},
		visual = "mesh",
		visual_size = size,
		mesh = mesh,
		textures = texture,
		makes_footstep_sound = false,
		timer = 0,
		automatic_rotate = math.pi * -2.9,
		m_name = "dummy"
	}

	DUMMY.on_activate = function(self)
		self.object:setvelocity({x=0, y=0, z=0})
		self.object:setacceleration({x=0, y=0, z=0})
		self.object:set_armor_groups({immortal=1})
	end

	DUMMY.on_step = function(self, dtime)
		self.timer = self.timer + 0.01
		local n = minetest.get_node_or_nil(self.object:getpos())
		if self.timer > 1 then
			if n and n.name and n.name ~= "creatures:"..mob.."_spawner" then
				self.object:remove()
			end
		end
	end

	DUMMY.on_punch = function(self, hitter)
	end

	minetest.register_entity("creatures:dummy_"..mob, DUMMY)

	-- node
	minetest.register_node("creatures:"..mob.."_spawner", {
		description = mob.." spawner",
		paramtype = "light",
		tiles = {"creatures_spawner.png"},
		is_ground_content = true,
		drawtype = "allfaces",
		groups = {cracky=1,level=1},
		drop = "",
		on_construct = function(pos)
			pos.y = pos.y + offset
			minetest.env:add_entity(pos,"creatures:dummy_"..mob)
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
	--abm
	minetest.register_abm({
		nodenames = {"creatures:"..mob.."_spawner"},
		interval = 2.0,
		chance = 20,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local res,player_near = false
			local mobs = 0
			res,mobs,player_near = creatures.find_mates(pos, mob, range)
			if player_near then
				if mobs < max then
					pos.x = pos.x+1
					local p = minetest.find_node_near(pos, 5, {"air"})	
					local ll = minetest.env:get_node_light(p)
					local wtime = minetest.env:get_timeofday()
					if not ll then return end
					if ll > max_ll then return end
					if ll < min_ll then return end
					if minetest.env:get_node(p).name ~= "air" then return end
					p.y = p.y+1
					if minetest.env:get_node(p).name ~= "air" then return end
					if not day_only then
						if (wtime > 0.2 and wtime < 0.805) and pos.y > 0 then return end
					end
					
					p.y = p.y-1
					creatures.spawn(p, 1, "creatures:"..mob,range,max)
				end
			end
		end })
end

-- spawner
creatures.register_spawner("zombie",{x=0.42,y=0.42},0.08,"creatures_mob.x",{"creatures_zombie.png"},17,6,7,-1,false)
creatures.register_spawner("sheep",{x=0.42,y=0.42},-0.3,"creatures_sheep.x",{"creatures_sheep.png"},17,6,18,10,true)
