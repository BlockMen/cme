creatures = {}

function creatures.spawn(pos, number, mob)
	print("spawn"..mob)
	--log spawning?
	for i=1,number do
		minetest.env:add_entity(pos, mob)
	end
end

dofile(minetest.get_modpath("creatures").."/ghost.lua")
dofile(minetest.get_modpath("creatures").."/zombie.lua")