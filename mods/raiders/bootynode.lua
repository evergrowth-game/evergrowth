local S = minetest.get_translator("raiders")

minetest.register_node("raiders:bootynode", {
	description = S"Booty",
	tiles = {
		"raiders_bootynode_top.png",
		"raiders_bootynode_bottom.png",
		"raiders_bootynode_right.png",
		"raiders_bootynode_left.png",
		"raiders_bootynode_back.png",
		"raiders_bootynode_front.png"
	},
	groups = {choppy = 2},
	drop = "default:gold_lump 20",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_craft({
	type = "fuel",
	recipe = "raiders:bootynode",
	burntime = 4,
})
