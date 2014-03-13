-- hostile mobs
if not minetest.setting_getbool("only_peaceful_mobs") then
	-- zombie
	minetest.register_abm({
		nodenames = creatures.z_spawn_nodes,
		interval = 40.0,
		chance = 7600,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local n = minetest.get_node_or_nil(pos)
			--if n and n.name and n.name ~= "default:stone" and math.random(1,4)>3 then return end
			pos.y = pos.y+1
			local ll = minetest.env:get_node_light(pos)
			local wtime = minetest.env:get_timeofday()
			if not ll then
				return
			end
			if ll >= creatures.z_ll then
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
			creatures.spawn(pos, 1, "creatures:zombie", 2, 20)
		end})
	-- ghost
	minetest.register_abm({
		nodenames = creatures.g_spawn_nodes,
		interval = 44.0,
		chance = 8350,
		action = function(pos, node, active_object_count, active_object_count_wider)
			if pos.y < 0 then return end
			pos.y = pos.y+1
			local ll = minetest.env:get_node_light(pos)
			local wtime = minetest.env:get_timeofday()
			if not ll then
				return
			end
			if ll >= creatures.g_ll then
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
			if (wtime > 0.2 and wtime < 0.805) then
				return
			end
			creatures.spawn(pos, 1, "creatures:ghost", 2, 35)
	end})

end

-- peaceful
minetest.register_abm({
	nodenames = creatures.s_spawn_nodes,
	interval = 55.0,
	chance = 7800,
	action = function(pos, node, active_object_count, active_object_count_wider)
		if pos.y < 0 then return end
		pos.y = pos.y+1
		local ll = minetest.env:get_node_light(pos) or 0
		if ll < 14 then return end
		local wtime = minetest.env:get_timeofday()
		if minetest.env:get_node(pos).name ~= "air" then
			return
		end
		if minetest.env:get_node(pos).name ~= "air" then
			return
		end
		if (wtime < 0.2 and wtime > 0.805) then
			return
		end
		if math.random(1,10) > 8 then return end
		creatures.spawn(pos, math.random(1,2), "creatures:sheep", 5, 35)
	end})
