-- dungeon_tweaks: Open-world loot table overhaul and diversification

if not minetest.get_modpath("lootchests") then
	return
end

local function filter_available(list, fallback)
	local out = {}
	for _, entry in ipairs(list) do
		local name = type(entry) == "table" and entry[1] or entry
		if minetest.registered_items[name] then
			table.insert(out, entry)
		end
	end
	if #out == 0 and fallback then
		for _, entry in ipairs(fallback) do
			if minetest.registered_items[entry[1]] then
				table.insert(out, entry)
			end
		end
	end
	-- Absolute safety guarantee
	if #out == 0 then
		table.insert(out, {"default:stick", 8})
	end
	return out
end

local raw_ocean_chest = {
	{"default:gold_ingot", 6},
	{"default:steel_ingot", 8},
	{"default:bronze_ingot", 6},
	{"default:copper_ingot", 8},
	{"default:tin_ingot", 6},
	{"default:diamond", 2},
	{"default:mese_crystal", 2},
	{"default:skeleton_key", 1},
	{"default:obsidian_shard", 16},
	{"default:glass", 16},
	{"default:pick_bronze"},
	{"default:sword_bronze"},
	{"default:axe_bronze"},
	{"default:shovel_bronze"},
	{"default:pick_steel"},
	{"default:sword_steel"},
	{"default:axe_steel"},
	{"3d_armor:helmet_bronze"},
	{"shields:shield_bronze"},
	{"3d_armor:chestplate_steel"},
	{"3d_armor:boots_steel"},
	{"airtanks:steel_tank", 1},
	{"binoculars:binoculars", 1},
	{"ropes:rope", 8},
	{"tnt:gunpowder", 8},
	{"vessels:glass_bottle", 8},
	{"map:mapping_kit", 1},
	{"fire:flint_and_steel"},
	{"dye:cyan", 8},
	{"dye:blue", 8},
	{"dye:white", 8},
	{"magic_materials:ice_rune", 1},
	{"magic_materials:arcanite_crystal", 3},
}

local raw_barrel = {
	{"default:apple", 12},
	{"farming:bread", 8},
	{"farming:cookie", 8},
	{"farming:wheat", 16},
	{"farming:flour", 6},
	{"farming:seed_cotton", 8},
	{"farming:tomato", 6},
	{"farming:cucumber", 6},
	{"farming:potato", 8},
	{"cheese:ricotta", 6},
	{"wine:glass_wine", 2},
	{"wine:bottle_wine", 1},
	{"ropes:rope", 6},
	{"default:torch", 12},
	{"default:wood", 16},
	{"default:stick", 24},
	{"default:flint", 4},
	{"vessels:drinking_glass", 4},
	{"vessels:glass_bottle", 4},
	{"bucket:bucket_empty", 1},
	{"bonemeal:bonemeal", 8},
}

local raw_basket = {
	{"default:apple", 10},
	{"farming:bread", 6},
	{"farming:seed_wheat", 12},
	{"farming:seed_cotton", 8},
	{"farming:tomato", 8},
	{"farming:cucumber", 8},
	{"farming:potato", 8},
	{"farming:corn", 6},
	{"farming:carrot", 6},
	{"farming:onion", 6},
	{"farming:coffee_beans", 6},
	{"farming:grapes", 8},
	{"farming:sugar", 8},
	{"bonemeal:mulch", 6},
	{"bonemeal:fertiliser", 4},
	{"flowers:mushroom_red", 4},
	{"flowers:mushroom_brown", 4},
	{"default:sapling", 4},
	{"default:junglesapling", 4},
	{"default:pine_sapling", 4},
	{"default:acacia_sapling", 4},
	{"farming:hoe_stone"},
	{"farming:hoe_bronze"},
}

local raw_urn = {
	{"default:clay_lump", 12},
	{"default:clay_brick", 12},
	{"default:flint", 6},
	{"default:coal_lump", 8},
	{"default:gold_lump", 4},
	{"default:copper_lump", 6},
	{"default:tin_lump", 6},
	{"default:mese_crystal_fragment", 6},
	{"default:paper", 6},
	{"default:book", 2},
	{"bones:bone", 4},
	{"default:stick", 16},
	{"default:skeleton_key", 1},
	{"magic_materials:earth_rune", 1},
	{"magic_materials:arcanite_crystal", 2},
	{"dye:brown", 6},
	{"dye:orange", 6},
}

local raw_stone_chest = {
	{"default:diamond", 4},
	{"default:mese_crystal", 6},
	{"default:gold_ingot", 8},
	{"default:steel_ingot", 12},
	{"default:bronze_ingot", 10},
	{"default:obsidian", 8},
	{"default:obsidian_shard", 16},
	{"default:pick_diamond"},
	{"default:sword_diamond"},
	{"default:pick_mese"},
	{"default:sword_mese"},
	{"default:pick_steel"},
	{"default:sword_steel"},
	{"3d_armor:chestplate_steel"},
	{"3d_armor:helmet_steel"},
	{"3d_armor:leggings_steel"},
	{"3d_armor:boots_steel"},
	{"shields:shield_steel"},
	{"magic_materials:enchanted_rune", 4},
	{"magic_materials:fire_rune", 2},
	{"magic_materials:storm_rune", 2},
	{"magic_materials:earth_rune", 2},
	{"magic_materials:light_rune", 2},
	{"magic_materials:void_rune", 2},
	{"magic_materials:arcanite_crystal", 8},
	{"magic_materials:enchanted_staff", 1},
	{"tnt:tnt", 3},
}

-- Defer filtering and assignment until all items are registered
minetest.register_on_mods_loaded(function()
	local fallback_base = {{"default:stick", 10}, {"default:torch", 4}}

	lootchests.loot_table["lootchests_default:ocean_chest"] = filter_available(raw_ocean_chest, fallback_base)
	lootchests.loot_table["lootchests_default:barrel"] = filter_available(raw_barrel, fallback_base)
	lootchests.loot_table["lootchests_default:basket"] = filter_available(raw_basket, fallback_base)
	lootchests.loot_table["lootchests_default:urn"] = filter_available(raw_urn, fallback_base)
	lootchests.loot_table["lootchests_default:stone_chest"] = filter_available(raw_stone_chest, fallback_base)

	minetest.log("action", "[dungeon_tweaks] Overhauled open-world loot tables for ocean chests, barrels, baskets, urns, and ancient chests")
end)
