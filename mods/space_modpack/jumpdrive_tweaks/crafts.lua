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
			{"jumpdrive:backbone", "techage:ta4_chip", "jumpdrive:backbone"},
			{"jumpdrive:warp_device", "techage:ta4_battery", "jumpdrive:warp_device"},
			{"techage:aluminium_ingot", "techage:ta4_motor", "techage:aluminium_ingot"}
		}
	})

	-- 4. Fleet Controller
	minetest.register_craft({
		output = "jumpdrive:fleet_controller",
		recipe = {
			{"techage:carbon_sheet", "techage:ta4_chip", "techage:carbon_sheet"},
			{"jumpdrive:backbone", "techage:screen_large", "jumpdrive:backbone"},
			{"techage:aluminium_ingot", "jumpdrive:engine", "techage:aluminium_ingot"}
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
