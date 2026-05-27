--[[

	TechAge
	=======

	Copyright (C) 2019-2021 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	pillar

]]--

local S = techage.S
local Cable = techage.ElectricCable
local power = networks.power


minetest.register_node("techage:pillar", {
	description = S("TA4 Pillar"),
	tiles = {"techage_concrete.png"},
	drawtype = "mesh",
	mesh = "techage_cylinder_07.obj",
	selection_box = {
		type = "fixed",
		fixed = {-10/32, -16/32, -10/32, 10/32, 16/32, 10/32},
	},
	collision_box = {
		type = "fixed",
		fixed = {-4/32, -16/32, -4/32, 4/32, 16/32, 4/32},
	},
	climbable = true,
	walkable = true,
	paramtype = "light",
	backface_culling = true,
	groups = {cracky=1},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		Cable:after_place_node(pos)
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_node(pos)
	end,

})

minetest.register_craft({
	type = "shapeless",
	output = "techage:pillar",
	recipe = {"basic_materials:concrete_block"},
})

if Cable then
	table.insert(Cable.primary_node_names, "techage:pillar")
	power.register_nodes({"techage:pillar"}, Cable, "junc")
end

