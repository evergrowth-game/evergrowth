-- jumpdrive_tweaks/nodes_fuel.lua
-- Onboard spacecraft fuel tank and exterior docking refueling port

local S = minetest.get_translator("jumpdrive_tweaks")

-- 1. Spacecraft Onboard Fuel Tank
minetest.register_node("jumpdrive_tweaks:fuel_tank", {
	description = S("Spacecraft Fuel Tank (Techage Compatible)"),
	tiles = {
		"default_steel_block.png^jumpdrive_front.png",
		"default_steel_block.png^jumpdrive_engine_side.png",
		"default_steel_block.png^jumpdrive_engine_side.png",
		"default_steel_block.png^jumpdrive_engine_side.png",
		"default_steel_block.png^jumpdrive_engine_side.png",
		"default_steel_block.png^jumpdrive_front.png"
	},
	groups = {cracky = 1, jumpdrive_ship_part = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("capacity", 5000)
		meta:set_int("fuel_amount", 0)
		meta:set_string("fuel_type", "")
		meta:set_string("infotext", S("Spacecraft Fuel Tank: 0 / 5000 units"))
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		return meta:get_int("fuel_amount") <= 0
	end,
})

-- 2. External Refueling Port (Flush Hull Pipe Coupling)
minetest.register_node("jumpdrive_tweaks:fuel_port", {
	description = S("Spacecraft Refueling Port"),
	tiles = {
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png",
		"default_steel_block.png^jumpdrive_front.png^[colorize:#00ffff:60"
	},
	groups = {cracky = 1, jumpdrive_ship_part = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Spacecraft Refueling Port (Docked / Standby)"))
	end,
})

-- Crafting recipes
minetest.register_craft({
	output = "jumpdrive_tweaks:fuel_tank",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:copper_ingot", "default:glass", "default:copper_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "jumpdrive_tweaks:fuel_port",
	recipe = {
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "jumpdrive:backbone", "default:steel_ingot"},
		{"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"}
	}
})
