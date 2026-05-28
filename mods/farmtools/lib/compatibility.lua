local mod_flowers = core.get_modpath("flowers") ~= nil
local mod_bonemeal = core.get_modpath("bonemeal") ~= nil
local mod_trunks = core.get_modpath("trunks") ~= nil
local mod_cottages = core.get_modpath("cottages") ~= nil
local mod_gloopblocks = core.get_modpath("gloopblocks") ~= nil

-- turn moss into fertilizer by cooking
if mod_bonemeal then
	core.register_craft({
		type = "cooking",
		cooktime = 9,
		output = "bonemeal:fertiliser",
		recipe = "group:moss",
	})
end

-- turn moss from trunks mod into this mod's moss
if mod_trunks then
	core.register_alias_force("trunks:moss", "farmtools:moss")

	core.register_craft({
		type = "shapeless",
		output = " trunks:moss_fungus",
		recipe = { "group:moss", "group:mushroom" },
	})
end

-- enable crafting of flower petals
if mod_flowers then
	core.register_craft({
		output = "sickles:petals",
		recipe = {
			{ "flowers:dandelion_white", "flowers:dandelion_white" },
			{ "flowers:dandelion_white", "flowers:dandelion_white" },
		},
	})
end

-- override pitchfork to use sickle mechanic
if mod_cottages then
	core.override_item("default:dirt_with_grass", {
		after_dig_node = function() end,
	})

	local groups = core.registered_tools["cottages:pitchfork"].groups
	groups.sickle = 1
	groups.sickle_uses = 120
	core.override_item("cottages:pitchfork", {
		groups = groups,
	})

	core.register_craft({
		output = "cottages:hay_mat",
		recipe = { { "group:grass", "group:grass", "group:grass" } },
	})
end

-- change crafting recipes of mossy blocks to use moss item
if mod_gloopblocks then
	core.clear_craft({
		output = "gloopblocks:stone_brick_mossy",
	})
	core.register_craft({
		type = "shapeless",
		output = "gloopblocks:stone_brick_mossy",
		recipe = { "default:stonebrick", "farmtools:moss" },
	})

	core.clear_craft({
		output = "gloopblocks:cobble_road_mossy",
	})
	core.register_craft({
		type = "shapeless",
		output = "gloopblocks:cobble_road_mossy",
		recipe = { "gloopblocks:cobble_road", "farmtools:moss" },
	})

	core.clear_craft({
		output = "gloopblocks:stone_mossy",
	})
	core.register_craft({
		type = "shapeless",
		output = "gloopblocks:stone_mossy",
		recipe = { "default:stone", "farmtools:moss" },
	})
end
