-- shears
minetest.register_tool("creatures:shears", {
	description = "Shears",
	inventory_image = "creatures_shears.png",
})

minetest.register_craft({
	output = 'creatures:shears',
	recipe = {
		{'','default:steel_ingot'},
		{'default:steel_ingot','default:stick'},
	}
})

-- drop items
minetest.register_craftitem("creatures:flesh", {
	description = "Flesh",
	inventory_image = "creatures_flesh.png",
	on_use = minetest.item_eat(2),
})

minetest.register_craftitem("creatures:rotten_flesh", {
	description = "Rotten Flesh",
	inventory_image = "creatures_rotten_flesh.png",
	on_use = minetest.item_eat(1),
})

-- food
minetest.register_craftitem("creatures:meat", {
	description = "Cooked Meat",
	inventory_image = "creatures_meat.png",
	on_use = minetest.item_eat(4),
})

minetest.register_craft({
	type = "cooking",
	output = "creatures:meat",
	recipe = "creatures:flesh",
})

-- spawn-eggs
minetest.register_craftitem("creatures:zombie_spawn_egg", {
	description = "Zombie spawn-egg",
	inventory_image = "creatures_egg_zombie.png",
	liquids_pointable = false,
	stack_max = 99,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local p = pointed_thing.above
			p.y = p.y+1
			creatures.spawn(p, 1, "creatures:zombie", 1, 1)
			if not minetest.setting_getbool("creative_mode") then itemstack:take_item() end
			return itemstack
		end
	end,

})

minetest.register_craftitem("creatures:ghost_spawn_egg", {
	description = "Ghost spawn-egg",
	inventory_image = "creatures_egg_ghost.png",
	liquids_pointable = false,
	stack_max = 99,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local p = pointed_thing.above
			p.y = p.y+0.5
			creatures.spawn(p, 1, "creatures:ghost", 1, 1)
			if not minetest.setting_getbool("creative_mode") then itemstack:take_item() end
			return itemstack
		end
	end,

})

minetest.register_craftitem("creatures:sheep_spawn_egg", {
	description = "Sheep spawn-egg",
	inventory_image = "creatures_egg_sheep.png",
	liquids_pointable = false,
	stack_max = 99,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "node" then
			local p = pointed_thing.above
			p.y = p.y+0.5
			creatures.spawn(p, 1, "creatures:sheep", 1, 1)
			if not minetest.setting_getbool("creative_mode") then itemstack:take_item() end
			return itemstack
		end
	end,

})
