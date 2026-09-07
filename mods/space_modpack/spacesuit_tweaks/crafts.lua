-- spacesuit_tweaks/crafts.lua
-- Industrial recipes and compressed air refuel crafts for spacesuit components

local has_techage = minetest.get_modpath("techage")
local has_vacuum = minetest.get_modpath("vacuum")
local has_airtanks = minetest.get_modpath("airtanks")

if has_techage then
	-- Spacesuit Helmet
	minetest.register_craft({
		output = "spacesuit:helmet",
		recipe = {
			{"basic_materials:plastic_sheet", "default:glass", "basic_materials:plastic_sheet"},
			{"techage:aluminum", has_airtanks and "airtanks:empty_steel_tank" or "vessels:steel_bottle", "techage:aluminum"},
			{"techage:steelmat", "techage:epoxy", "techage:steelmat"}
		}
	})

	-- Spacesuit Chestplate (Life Support Core)
	minetest.register_craft({
		output = "spacesuit:chestplate",
		recipe = {
			{"basic_materials:plastic_sheet", has_airtanks and "airtanks:steel_tank" or "vacuum:air_bottle", "basic_materials:plastic_sheet"},
			{"techage:aluminum", "techage:ta4_wlanchip", "techage:aluminum"},
			{"basic_materials:plastic_sheet", "techage:steelmat", "basic_materials:plastic_sheet"}
		}
	})

	-- Spacesuit Leggings
	minetest.register_craft({
		output = "spacesuit:pants",
		recipe = {
			{"basic_materials:plastic_sheet", "techage:steelmat", "basic_materials:plastic_sheet"},
			{"techage:aluminum", "", "techage:aluminum"},
			{"basic_materials:plastic_sheet", "", "basic_materials:plastic_sheet"}
		}
	})

	-- Spacesuit Boots
	minetest.register_craft({
		output = "spacesuit:boots",
		recipe = {
			{"techage:steelmat", "", "techage:steelmat"},
			{"techage:aluminum", "techage:steelmat", "techage:aluminum"}
		}
	})

	-- EVA RCS Thruster Pack
	minetest.register_craft({
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {
			{"basic_materials:plastic_sheet", "techage:ta3_pipeS", "basic_materials:plastic_sheet"},
			{"techage:aluminum", has_airtanks and "airtanks:steel_tank" or "vacuum:air_bottle", "techage:aluminum"},
			{"techage:ta4_wlanchip", "basic_materials:motor", "techage:ta4_wlanchip"}
		}
	})
else
	-- Minetest Game fallback recipe for EVA Thruster
	minetest.register_craft({
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {
			{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
			{"default:steel_ingot", "vacuum:air_bottle", "default:steel_ingot"},
			{"default:mese_crystal", "default:gold_ingot", "default:mese_crystal"}
		}
	})
end

-- Shapeless Refuel / Recharge Craft Recipes for EVA Thruster (Compressed Air Only)
if has_vacuum then
	minetest.register_craft({
		type = "shapeless",
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {"spacesuit_tweaks:eva_thruster", "vacuum:air_bottle"},
		replacements = {{"vacuum:air_bottle", "vessels:steel_bottle"}},
	})
end

if has_airtanks then
	minetest.register_craft({
		type = "shapeless",
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {"spacesuit_tweaks:eva_thruster", "airtanks:steel_tank"},
		replacements = {{"airtanks:steel_tank", "airtanks:empty_steel_tank"}},
	})
	minetest.register_craft({
		type = "shapeless",
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {"spacesuit_tweaks:eva_thruster", "airtanks:carbon_tank"},
		replacements = {{"airtanks:carbon_tank", "airtanks:empty_carbon_tank"}},
	})
	minetest.register_craft({
		type = "shapeless",
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {"spacesuit_tweaks:eva_thruster", "airtanks:bronze_tank"},
		replacements = {{"airtanks:bronze_tank", "airtanks:empty_bronze_tank"}},
	})
end
