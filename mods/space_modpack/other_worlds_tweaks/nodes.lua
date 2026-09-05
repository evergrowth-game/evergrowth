-- other_worlds_tweaks/nodes.lua
-- Rich Asteroid Ores and Comet Volatiles

local S = minetest.get_translator("other_worlds_tweaks")

-- 1. Rich Asteroid Iron Ore (Drops 2-4 iron lumps)
minetest.register_node("other_worlds_tweaks:rich_iron_ore", {
	description = S("Rich Asteroid Iron Ore"),
	tiles = {"asteroid_stone.png^default_mineral_iron.png"},
	is_ground_content = false,
	groups = {cracky = 2},
	drop = {
		max_items = 4,
		items = {
			{items = {"default:iron_lump 4"}, rarity = 4},
			{items = {"default:iron_lump 3"}, rarity = 2},
			{items = {"default:iron_lump 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 2. Rich Asteroid Copper Ore (Drops 2-4 copper lumps)
minetest.register_node("other_worlds_tweaks:rich_copper_ore", {
	description = S("Rich Asteroid Copper Ore"),
	tiles = {"asteroid_stone.png^default_mineral_copper.png"},
	is_ground_content = false,
	groups = {cracky = 2},
	drop = {
		max_items = 4,
		items = {
			{items = {"default:copper_lump 4"}, rarity = 4},
			{items = {"default:copper_lump 3"}, rarity = 2},
			{items = {"default:copper_lump 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 3. Rich Asteroid Gold Ore (Drops 2-3 gold lumps)
minetest.register_node("other_worlds_tweaks:rich_gold_ore", {
	description = S("Rich Asteroid Gold Ore"),
	tiles = {"asteroid_stone.png^default_mineral_gold.png"},
	is_ground_content = false,
	groups = {cracky = 2},
	drop = {
		max_items = 3,
		items = {
			{items = {"default:gold_lump 3"}, rarity = 2},
			{items = {"default:gold_lump 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 4. Rich Asteroid Diamond Ore (Drops 2-3 diamonds)
minetest.register_node("other_worlds_tweaks:rich_diamond_ore", {
	description = S("Rich Asteroid Diamond Ore"),
	tiles = {"asteroid_stone.png^default_mineral_diamond.png"},
	is_ground_content = false,
	groups = {cracky = 1},
	drop = {
		max_items = 3,
		items = {
			{items = {"default:diamond 3"}, rarity = 3},
			{items = {"default:diamond 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 5. Rich Asteroid Mese Ore (Drops 2-3 mese crystals)
minetest.register_node("other_worlds_tweaks:rich_mese_ore", {
	description = S("Rich Asteroid Mese Ore"),
	tiles = {"asteroid_stone.png^default_mineral_mese.png"},
	is_ground_content = false,
	groups = {cracky = 1},
	drop = {
		max_items = 3,
		items = {
			{items = {"default:mese_crystal 3"}, rarity = 2},
			{items = {"default:mese_crystal 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 6. Comet Ice (Source of off-world water and hydrogen)
minetest.register_node("other_worlds_tweaks:comet_ice", {
	description = S("Comet Ice"),
	tiles = {"default_ice.png^[colorize:#88ccff:40"},
	is_ground_content = false,
	paramtype = "light",
	groups = {cracky = 3, cools_lava = 1},
	sounds = default.node_sound_glass_defaults()
})

-- Smelting comet ice into water bucket or water source
minetest.register_craft({
	type = "cooking",
	output = "bucket:bucket_water",
	recipe = "other_worlds_tweaks:comet_ice",
	cooktime = 3,
})

-- Techage recipe integration: Melt comet ice into water
if minetest.get_modpath("techage") and techage and techage.register_recipe then
	techage.register_recipe("cooking", "other_worlds_tweaks:comet_ice", "bucket:bucket_water")
end

-- Mapgen registrations for rich ores in asteroid layer (Y = 5000 to 12000)
minetest.register_ore({
	ore_type = "scatter",
	ore = "other_worlds_tweaks:rich_iron_ore",
	wherein = "asteroid:stone",
	clust_scarcity = 12 * 12 * 12,
	clust_num_ores = 4,
	clust_size = 3,
	y_min = 5000,
	y_max = 12000,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "other_worlds_tweaks:rich_copper_ore",
	wherein = "asteroid:stone",
	clust_scarcity = 14 * 14 * 14,
	clust_num_ores = 4,
	clust_size = 3,
	y_min = 5000,
	y_max = 12000,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "other_worlds_tweaks:rich_gold_ore",
	wherein = "asteroid:stone",
	clust_scarcity = 18 * 18 * 18,
	clust_num_ores = 3,
	clust_size = 2,
	y_min = 5000,
	y_max = 12000,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "other_worlds_tweaks:rich_diamond_ore",
	wherein = "asteroid:stone",
	clust_scarcity = 22 * 22 * 22,
	clust_num_ores = 2,
	clust_size = 2,
	y_min = 5000,
	y_max = 12000,
})

minetest.register_ore({
	ore_type = "scatter",
	ore = "other_worlds_tweaks:rich_mese_ore",
	wherein = "asteroid:stone",
	clust_scarcity = 20 * 20 * 20,
	clust_num_ores = 3,
	clust_size = 2,
	y_min = 5000,
	y_max = 12000,
})

minetest.register_ore({
	ore_type = "blob",
	ore = "other_worlds_tweaks:comet_ice",
	wherein = {"asteroid:stone", "asteroid:redstone"},
	clust_scarcity = 24 * 24 * 24,
	clust_num_ores = 12,
	clust_size = 4,
	y_min = 5000,
	y_max = 12000,
})
