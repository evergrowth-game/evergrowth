-- spacesuit_tweaks/crafts.lua
-- Advanced industrial recipes for spacesuit components

if minetest.get_modpath("techage") then
	-- Spacesuit Helmet
	minetest.register_craft({
		output = "spacesuit:helmet",
		recipe = {
			{"techage:plastic_sheet", "default:glass", "techage:plastic_sheet"},
			{"techage:aluminium_ingot", "airtanks:steel_tank_empty", "techage:aluminium_ingot"},
			{"techage:rubber", "techage:epoxy_resin", "techage:rubber"}
		}
	})

	-- Spacesuit Chestplate (Life Support Core)
	minetest.register_craft({
		output = "spacesuit:chestplate",
		recipe = {
			{"techage:plastic_sheet", "airtanks:steel_tank_air", "techage:plastic_sheet"},
			{"techage:aluminium_ingot", "techage:ta4_chip", "techage:aluminium_ingot"},
			{"techage:plastic_sheet", "techage:rubber", "techage:plastic_sheet"}
		}
	})

	-- Spacesuit Leggings
	minetest.register_craft({
		output = "spacesuit:pants",
		recipe = {
			{"techage:plastic_sheet", "techage:rubber", "techage:plastic_sheet"},
			{"techage:aluminium_ingot", "", "techage:aluminium_ingot"},
			{"techage:plastic_sheet", "", "techage:plastic_sheet"}
		}
	})

	-- Spacesuit Boots
	minetest.register_craft({
		output = "spacesuit:boots",
		recipe = {
			{"techage:rubber", "", "techage:rubber"},
			{"techage:aluminium_ingot", "techage:steelmat", "techage:aluminium_ingot"}
		}
	})
end
