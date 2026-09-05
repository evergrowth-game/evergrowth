-- other_worlds_tweaks/nodes.lua
-- Rich Asteroid Ores and Comet Volatiles

local S = minetest.get_translator("other_worlds_tweaks")

-- 1. Rich Asteroid Iron Ore (Drops 2-4 iron lumps)
minetest.register_node("other_worlds_tweaks:rich_iron_ore", {
	description = S("Rich Asteroid Iron Ore"),
	tiles = {"default_stone.png^default_mineral_iron.png"},
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
	tiles = {"default_stone.png^default_mineral_copper.png"},
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
	tiles = {"default_stone.png^default_mineral_gold.png"},
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
	tiles = {"default_stone.png^default_mineral_diamond.png"},
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
	tiles = {"default_stone.png^default_mineral_mese.png"},
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

-- 6. Rich Asteroid Tin Ore (Drops 2-4 tin lumps)
minetest.register_node("other_worlds_tweaks:rich_tin_ore", {
	description = S("Rich Asteroid Tin Ore"),
	tiles = {"default_stone.png^default_mineral_tin.png"},
	is_ground_content = false,
	groups = {cracky = 2},
	drop = {
		max_items = 4,
		items = {
			{items = {"default:tin_lump 4"}, rarity = 4},
			{items = {"default:tin_lump 3"}, rarity = 2},
			{items = {"default:tin_lump 2"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 7. Rich Asteroid Coal Ore (Drops 3-5 coal lumps)
minetest.register_node("other_worlds_tweaks:rich_coal_ore", {
	description = S("Rich Asteroid Coal Ore"),
	tiles = {"default_stone.png^default_mineral_coal.png"},
	is_ground_content = false,
	groups = {cracky = 3},
	drop = {
		max_items = 5,
		items = {
			{items = {"default:coal_lump 5"}, rarity = 4},
			{items = {"default:coal_lump 4"}, rarity = 2},
			{items = {"default:coal_lump 3"}, rarity = 1}
		}
	},
	sounds = default.node_sound_stone_defaults()
})

-- 8. Comet Ice (Source of off-world water and hydrogen)
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

-- Override existing asteroid ores with rich drop yields (2-4x)
if minetest.registered_nodes["asteroid:ironore"] then
	minetest.override_item("asteroid:ironore", {
		drop = {
			max_items = 4,
			items = {
				{items = {"default:iron_lump 4"}, rarity = 4},
				{items = {"default:iron_lump 3"}, rarity = 2},
				{items = {"default:iron_lump 2"}, rarity = 1}
			}
		}
	})
end

if minetest.registered_nodes["asteroid:copperore"] then
	minetest.override_item("asteroid:copperore", {
		drop = {
			max_items = 4,
			items = {
				{items = {"default:copper_lump 4"}, rarity = 4},
				{items = {"default:copper_lump 3"}, rarity = 2},
				{items = {"default:copper_lump 2"}, rarity = 1}
			}
		}
	})
end

if minetest.registered_nodes["asteroid:goldore"] then
	minetest.override_item("asteroid:goldore", {
		drop = {
			max_items = 3,
			items = {
				{items = {"default:gold_lump 3"}, rarity = 2},
				{items = {"default:gold_lump 2"}, rarity = 1}
			}
		}
	})
end

if minetest.registered_nodes["asteroid:diamondore"] then
	minetest.override_item("asteroid:diamondore", {
		drop = {
			max_items = 3,
			items = {
				{items = {"default:diamond 3"}, rarity = 3},
				{items = {"default:diamond 2"}, rarity = 1}
			}
		}
	})
end

if minetest.registered_nodes["asteroid:meseore"] then
	minetest.override_item("asteroid:meseore", {
		drop = {
			max_items = 3,
			items = {
				{items = {"default:mese_crystal 3"}, rarity = 2},
				{items = {"default:mese_crystal 2"}, rarity = 1}
			}
		}
	})
end
