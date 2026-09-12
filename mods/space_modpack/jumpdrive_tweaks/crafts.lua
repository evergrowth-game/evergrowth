-- jumpdrive_tweaks/crafts.lua
-- Techage and Minetest Game crafting recipes for Jumpdrive components

-- 1. Jumpdrive Backbone Hull
minetest.register_craft({
	output = "jumpdrive:backbone",
	recipe = {
		{"default:mese_crystal", "default:steelblock", "default:mese_crystal"},
		{"default:steelblock", "default:steelblock", "default:steelblock"},
		{"default:mese_crystal", "default:steelblock", "default:mese_crystal"}
	}
})

-- 2. Warp Device
minetest.register_craft({
	output = "jumpdrive:warp_device",
	recipe = {
		{"default:mese_crystal", "default:diamond", "default:mese_crystal"},
		{"default:mese", "default:steelblock", "default:mese"},
		{"default:mese_crystal", "default:diamond", "default:mese_crystal"}
	}
})

-- 3. Jumpdrive Engine Core
if minetest.get_modpath("techage") then
	minetest.register_craft({
		output = "jumpdrive:engine",
		recipe = {
			{"jumpdrive:backbone", "techage:ta4_wlanchip", "jumpdrive:backbone"},
			{"jumpdrive:warp_device", "techage:ta3_akku", "jumpdrive:warp_device"},
			{"techage:aluminum", "basic_materials:motor", "techage:aluminum"}
		}
	})

	-- 4. Fleet Controller
	minetest.register_craft({
		output = "jumpdrive:fleet_controller",
		recipe = {
			{"basic_materials:plastic_sheet", "techage:ta4_wlanchip", "basic_materials:plastic_sheet"},
			{"jumpdrive:backbone", "techage:ta4_terminal", "jumpdrive:backbone"},
			{"techage:aluminum", "jumpdrive:engine", "techage:aluminum"}
		}
	})
else
	minetest.register_craft({
		output = "jumpdrive:engine",
		recipe = {
			{"jumpdrive:backbone", "default:steelblock", "jumpdrive:backbone"},
			{"jumpdrive:warp_device", "default:mese", "jumpdrive:warp_device"},
			{"jumpdrive:backbone", "default:steelblock", "jumpdrive:backbone"}
		}
	})

	minetest.register_craft({
		output = "jumpdrive:fleet_controller",
		recipe = {
			{"jumpdrive:engine", "default:steelblock", "jumpdrive:engine"},
			{"default:steelblock", "default:steelblock", "default:steelblock"},
			{"jumpdrive:engine", "default:steelblock", "jumpdrive:engine"}
		}
	})
end

-- 5. Ship Transponder Beacon
minetest.register_craft({
	output = "jumpdrive_tweaks:beacon",
	recipe = {
		{"default:glass", "default:mese_crystal", "default:glass"},
		{"default:copper_ingot", "jumpdrive:warp_device", "default:copper_ingot"},
		{"default:steel_ingot", "default:gold_ingot", "default:steel_ingot"}
	}
})

-- 6. Quantum Recall Tether
minetest.register_craft({
	output = "jumpdrive_tweaks:quantum_tether",
	recipe = {
		{"default:diamond", "default:mese_crystal", "default:diamond"},
		{"default:gold_ingot", "jumpdrive_tweaks:beacon", "default:gold_ingot"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
	}
})

-- 7. Starship Thermal Ice Melter
if minetest.get_modpath("techage") and minetest.get_modpath("networks") and minetest.get_modpath("basic_materials") then
	minetest.register_craft({
		output = "jumpdrive_tweaks:ice_melter",
		recipe = {
			{"default:steel_ingot", "default:glass", "default:steel_ingot"},
			{"techage:electric_cableS", "basic_materials:heating_element", "techage:ta3_pipeS"},
			{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
		}
	})
end

-- 8. Optical Rangefinder
if minetest.get_modpath("techage") then
	minetest.register_craft({
		output = "jumpdrive_tweaks:rangefinder",
		recipe = {
			{"default:glass", "default:mese_crystal", "default:glass"},
			{"default:steel_ingot", "techage:ta4_wlanchip", "default:steel_ingot"},
			{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
		}
	})
else
	minetest.register_craft({
		output = "jumpdrive_tweaks:rangefinder",
		recipe = {
			{"default:glass", "default:mese_crystal", "default:glass"},
			{"default:steel_ingot", "default:diamond", "default:steel_ingot"},
			{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
		}
	})
end

-- 9. Bridge Navigation Console
if minetest.get_modpath("techage") then
	minetest.register_craft({
		output = "jumpdrive_tweaks:bridge_console",
		recipe = {
			{"techage:ta4_terminal", "techage:ta4_wlanchip", "default:glass"},
			{"techage:aluminum", "jumpdrive:backbone", "techage:aluminum"},
			{"default:steelblock", "techage:electric_cableS", "default:steelblock"}
		}
	})
else
	minetest.register_craft({
		output = "jumpdrive_tweaks:bridge_console",
		recipe = {
			{"default:glass", "default:mese_crystal", "default:glass"},
			{"default:steel_ingot", "jumpdrive:backbone", "default:steel_ingot"},
			{"default:steelblock", "default:copper_ingot", "default:steelblock"}
		}
	})
end

-- 10. Jump Lever
minetest.register_craft({
	output = "jumpdrive_tweaks:jump_lever",
	recipe = {
		{"default:steel_ingot", "default:mese_crystal", "dye:yellow"},
		{"default:steel_ingot", "jumpdrive:backbone", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
	}
})



