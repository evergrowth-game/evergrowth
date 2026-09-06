-- jumpdrive_tweaks/nodes_fuel.lua
-- Onboard spacecraft fuel tank and exterior docking refueling port

local S = minetest.get_translator("jumpdrive_tweaks")

local MANUAL_CANISTERS = {
	-- Techage Gas Cylinders & Petrochemicals
	["techage:cylinder_large_hydrogen"] = {
		liquid = "techage:hydrogen",
		amount = 5000,
		empty = "techage:ta3_cylinder_large",
		label = "Hydrogen"
	},
	["techage:cylinder_small_hydrogen"] = {
		liquid = "techage:hydrogen",
		amount = 1000,
		empty = "techage:ta3_cylinder_small",
		label = "Hydrogen"
	},
	["techage:ta3_cylinder_large_gas"] = {
		liquid = "techage:gas",
		amount = 5000,
		empty = "techage:ta3_cylinder_large",
		label = "Petroleum Gas"
	},
	["techage:ta4_cylinder_large_isobutane"] = {
		liquid = "techage:isobutane",
		amount = 5000,
		empty = "techage:ta3_cylinder_large",
		label = "Isobutane"
	},
	-- Biofuel Canisters & Bottles
	["biofuel:canister_fuel"] = {
		liquid = "biofuel:fuel",
		amount = 2500,
		empty = "biofuel:canister_empty",
		label = "Biofuel"
	},
	["biofuel:bottle_fuel"] = {
		liquid = "biofuel:fuel",
		amount = 500,
		empty = "vessels:glass_bottle",
		label = "Biofuel"
	},
}

-- 1. Spacecraft Onboard Fuel Tank
minetest.register_node("jumpdrive_tweaks:fuel_tank", {
	description = S("Spacecraft Fuel Tank (Techage Compatible)"),
	tiles = {
		"default_steel_block.png^jumpdrive_warpdevice.png",
		"default_steel_block.png^jumpdrive_backbone.png",
		"default_steel_block.png^jumpdrive_backbone.png",
		"default_steel_block.png^jumpdrive_backbone.png",
		"default_steel_block.png^jumpdrive_backbone.png",
		"default_steel_block.png^jumpdrive_warpdevice.png"
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
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker or not itemstack then return itemstack end
		local item_name = itemstack:get_name()
		local canister_data = MANUAL_CANISTERS[item_name]
		if not canister_data then return itemstack end

		local meta = minetest.get_meta(pos)
		local current = meta:get_int("fuel_amount")
		local capacity = meta:get_int("capacity") or 5000
		local current_type = meta:get_string("fuel_type")

		if current >= capacity then
			minetest.chat_send_player(clicker:get_player_name(), S("Fuel tank is already completely full."))
			return itemstack
		end

		if current > 0 and current_type ~= "" and current_type ~= canister_data.liquid then
			minetest.chat_send_player(clicker:get_player_name(), S("Cannot mix different propellant types in the same tank."))
			return itemstack
		end

		local space = capacity - current
		local fill_amount = math.min(space, canister_data.amount)
		local new_amount = current + fill_amount

		meta:set_int("fuel_amount", new_amount)
		meta:set_string("fuel_type", canister_data.liquid)
		meta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, canister_data.label))

		-- Consume 1 filled canister from hand
		itemstack:take_item(1)

		-- Give empty container back to player
		local inv = clicker:get_inventory()
		if canister_data.empty and inv then
			local leftover = inv:add_item("main", ItemStack(canister_data.empty))
			if leftover and not leftover:is_empty() then
				minetest.add_item(pos, leftover)
			end
		end

		minetest.sound_play("default_cool_lava", {pos = pos, gain = 0.5}, true)
		return itemstack
	end,
	can_dig = function(pos, player)
		local player_name = player and player:get_player_name() or ""
		if minetest.is_protected(pos, player_name) then return false end
		local meta = minetest.get_meta(pos)
		return meta:get_int("fuel_amount") <= 0
	end,
	after_place_node = function(pos)
		if techage and techage.LiquidPipe then
			techage.LiquidPipe:after_place_node(pos)
		end
	end,
	after_dig_node = function(pos)
		if techage and techage.LiquidPipe then
			techage.LiquidPipe:after_dig_node(pos)
		end
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
		"default_steel_block.png^jumpdrive.png^[colorize:#00ffff:60"
	},
	groups = {cracky = 1, jumpdrive_ship_part = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Spacecraft Refueling Port"))
	end,
	can_dig = function(pos, player)
		local player_name = player and player:get_player_name() or ""
		if minetest.is_protected(pos, player_name) then return false end
		return true
	end,
	after_place_node = function(pos)
		if techage and techage.LiquidPipe then
			techage.LiquidPipe:after_place_node(pos)
		end
	end,
	after_dig_node = function(pos)
		if techage and techage.LiquidPipe then
			techage.LiquidPipe:after_dig_node(pos)
		end
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
