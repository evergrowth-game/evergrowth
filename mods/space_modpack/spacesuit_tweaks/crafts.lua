-- spacesuit_tweaks/crafts.lua
-- Advanced industrial recipes for spacesuit components

if minetest.get_modpath("techage") then
	-- Spacesuit Helmet
	minetest.register_craft({
		output = "spacesuit:helmet",
		recipe = {
			{"basic_materials:plastic_sheet", "default:glass", "basic_materials:plastic_sheet"},
			{"techage:aluminum", "airtanks:steel_tank_empty", "techage:aluminum"},
			{"techage:steelmat", "techage:epoxy", "techage:steelmat"}
		}
	})

	-- Spacesuit Chestplate (Life Support Core)
	minetest.register_craft({
		output = "spacesuit:chestplate",
		recipe = {
			{"basic_materials:plastic_sheet", "airtanks:steel_tank_air", "basic_materials:plastic_sheet"},
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
			{"techage:aluminum", "airtanks:steel_tank_air", "techage:aluminum"},
			{"techage:ta4_wlanchip", "basic_materials:motor", "techage:ta4_wlanchip"}
		}
	})
else
	-- Minetest Game fallback recipe for EVA Thruster
	minetest.register_craft({
		output = "spacesuit_tweaks:eva_thruster",
		recipe = {
			{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
			{"default:steel_ingot", "spacesuit:airbottle", "default:steel_ingot"},
			{"default:mese_crystal", "default:gold_ingot", "default:mese_crystal"}
		}
	})
end
