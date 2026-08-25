-- dungeon_tweaks: Tiered loot generation engine

dungeon_tweaks = dungeon_tweaks or {}

-- Base loot categories definition
local raw_loot_categories = {
	supplies = {
		{name = "default:torch", min = 2, max = 8, weight = 20},
		{name = "default:stick", min = 4, max = 16, weight = 18},
		{name = "default:paper", min = 2, max = 6, weight = 12},
		{name = "default:book", min = 1, max = 2, weight = 8},
		{name = "default:flint", min = 1, max = 4, weight = 14},
		{name = "vessels:glass_bottle", min = 1, max = 4, weight = 10},
		{name = "ropes:rope", min = 2, max = 6, weight = 8},
		{name = "tnt:gunpowder", min = 1, max = 4, weight = 6},
		{name = "binoculars:binoculars", min = 1, max = 1, weight = 2},
	},
	food = {
		{name = "default:apple", min = 2, max = 8, weight = 20},
		{name = "farming:bread", min = 1, max = 4, weight = 18},
		{name = "farming:cookie", min = 2, max = 6, weight = 10},
		{name = "farming:seed_wheat", min = 2, max = 8, weight = 14},
		{name = "farming:seed_cotton", min = 2, max = 6, weight = 10},
		{name = "farming:tomato", min = 1, max = 4, weight = 8},
		{name = "farming:cucumber", min = 1, max = 4, weight = 8},
		{name = "farming:potato", min = 1, max = 4, weight = 8},
		{name = "cheese:ricotta", min = 1, max = 4, weight = 6},
		{name = "cheese:mozzarella", min = 1, max = 4, weight = 6},
	},
	ores_shallow = {
		{name = "default:coal_lump", min = 2, max = 10, weight = 30},
		{name = "default:copper_lump", min = 1, max = 6, weight = 20},
		{name = "default:tin_lump", min = 1, max = 4, weight = 15},
		{name = "default:steel_ingot", min = 1, max = 4, weight = 20},
		{name = "default:bronze_ingot", min = 1, max = 3, weight = 10},
		{name = "default:gold_lump", min = 1, max = 3, weight = 5},
	},
	ores_deep = {
		{name = "default:steel_ingot", min = 2, max = 8, weight = 25},
		{name = "default:bronze_ingot", min = 2, max = 6, weight = 20},
		{name = "default:gold_ingot", min = 1, max = 5, weight = 18},
		{name = "default:mese_crystal_fragment", min = 2, max = 8, weight = 18},
		{name = "default:mese_crystal", min = 1, max = 3, weight = 12},
		{name = "default:diamond", min = 1, max = 2, weight = 8},
		{name = "default:obsidian_shard", min = 2, max = 6, weight = 10},
	},
	tools_shallow = {
		{name = "default:sword_stone", weight = 15, is_tool = true},
		{name = "default:pick_stone", weight = 15, is_tool = true},
		{name = "default:axe_stone", weight = 15, is_tool = true},
		{name = "default:shovel_stone", weight = 12, is_tool = true},
		{name = "farming:hoe_stone", weight = 8, is_tool = true},
		{name = "default:sword_bronze", weight = 10, is_tool = true},
		{name = "default:pick_bronze", weight = 10, is_tool = true},
		{name = "default:sword_steel", weight = 10, is_tool = true},
		{name = "default:pick_steel", weight = 10, is_tool = true},
		{name = "default:axe_steel", weight = 10, is_tool = true},
		{name = "3d_armor:helmet_wood", weight = 5, is_tool = true},
		{name = "shields:shield_wood", weight = 5, is_tool = true},
	},
	tools_deep = {
		{name = "default:sword_steel", weight = 20, is_tool = true},
		{name = "default:pick_steel", weight = 20, is_tool = true},
		{name = "default:axe_steel", weight = 15, is_tool = true},
		{name = "default:shovel_steel", weight = 12, is_tool = true},
		{name = "default:sword_mese", weight = 8, is_tool = true},
		{name = "default:pick_mese", weight = 8, is_tool = true},
		{name = "default:sword_diamond", weight = 4, is_tool = true},
		{name = "default:pick_diamond", weight = 4, is_tool = true},
		{name = "3d_armor:helmet_steel", weight = 8, is_tool = true},
		{name = "3d_armor:chestplate_steel", weight = 6, is_tool = true},
		{name = "3d_armor:leggings_steel", weight = 6, is_tool = true},
		{name = "3d_armor:boots_steel", weight = 8, is_tool = true},
		{name = "shields:shield_steel", weight = 8, is_tool = true},
		{name = "shields:shield_bronze", weight = 6, is_tool = true},
		{name = "3d_armor:helmet_bronze", weight = 6, is_tool = true},
	},
	relics_magic = {
		{name = "magic_materials:arcanite_crystal", min = 1, max = 3, weight = 15},
		{name = "magic_materials:arcanite_fragments", min = 2, max = 6, weight = 12},
		{name = "magic_materials:enchanted_staff", min = 1, max = 1, weight = 8},
		{name = "magic_materials:enchanted_rune", min = 1, max = 2, weight = 10},
		{name = "magic_materials:fire_rune", min = 1, max = 1, weight = 6},
		{name = "magic_materials:ice_rune", min = 1, max = 1, weight = 6},
		{name = "magic_materials:earth_rune", min = 1, max = 1, weight = 6},
		{name = "magic_materials:storm_rune", min = 1, max = 1, weight = 6},
		{name = "magic_materials:light_rune", min = 1, max = 1, weight = 4},
		{name = "magic_materials:void_rune", min = 1, max = 1, weight = 4},
		{name = "magic_materials:energy_rune", min = 1, max = 1, weight = 4},
		{name = "default:skeleton_key", min = 1, max = 1, weight = 12},
		{name = "tnt:tnt", min = 1, max = 2, weight = 5},
	},
}

local filtered_categories = {}

local function filter_loot_tables()
	for cat_name, entries in pairs(raw_loot_categories) do
		filtered_categories[cat_name] = {}
		for _, entry in ipairs(entries) do
			if minetest.registered_items[entry.name] then
				table.insert(filtered_categories[cat_name], entry)
			end
		end
	end

	-- Guaranteed base fallback if supplies somehow has 0 items
	if not filtered_categories.supplies or #filtered_categories.supplies == 0 then
		filtered_categories.supplies = {
			{name = "default:stick", min = 1, max = 8, weight = 10},
			{name = "default:torch", min = 1, max = 4, weight = 10},
			{name = "default:apple", min = 1, max = 4, weight = 10},
		}
	end
end

-- Defer filtering until all mods have registered their items
minetest.register_on_mods_loaded(function()
	filter_loot_tables()
end)

-- Pick a weighted random item from a category table
local function pick_weighted(list, rand)
	if not list or #list == 0 then return nil end
	local total_weight = 0
	for _, entry in ipairs(list) do
		total_weight = total_weight + (entry.weight or 1)
	end
	local roll = rand:next(1, total_weight)
	local current = 0
	for _, entry in ipairs(list) do
		current = current + (entry.weight or 1)
		if roll <= current then
			return entry
		end
	end
	return list[#list]
end

-- Generate a single ItemStack from an entry
local function create_loot_stack(entry, rand)
	if not entry then return nil end
	local stack = ItemStack(entry.name)
	if entry.is_tool or (minetest.registered_tools and minetest.registered_tools[entry.name]) then
		stack:set_wear(rand:next(10000, 45000))
	else
		local count = 1
		if entry.min and entry.max then
			count = rand:next(entry.min, entry.max)
		end
		stack:set_count(count)
	end
	return stack
end

-- Main function to generate dungeon loot for a chest
function dungeon_tweaks.get_dungeon_loot(rand, y_pos)
	-- If called before mods_loaded, ensure filter runs
	if not filtered_categories.supplies or #filtered_categories.supplies == 0 then
		filter_loot_tables()
	end

	local is_deep = (y_pos or 0) < -256
	local is_abyss = (y_pos or 0) < -1024

	-- Category distribution depending on depth
	local chosen_cat_pool
	if is_abyss then
		chosen_cat_pool = {"ores_deep", "ores_deep", "tools_deep", "tools_deep", "relics_magic", "supplies"}
	elseif is_deep then
		chosen_cat_pool = {"ores_deep", "tools_deep", "ores_shallow", "tools_shallow", "supplies", "food", "relics_magic"}
	else
		chosen_cat_pool = {"ores_shallow", "tools_shallow", "supplies", "supplies", "food", "food"}
	end

	local cat_name = chosen_cat_pool[rand:next(1, #chosen_cat_pool)]
	local cat_list = filtered_categories[cat_name]
	if not cat_list or #cat_list == 0 then
		cat_list = filtered_categories.supplies
	end
	local entry = pick_weighted(cat_list, rand)
	if not entry then
		entry = pick_weighted(filtered_categories.supplies, rand)
	end
	return create_loot_stack(entry, rand)
end
