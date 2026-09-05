-- jumpdrive_tweaks/techage_pipe.lua
-- Integration with Techage Liquid Network and item fuel registration

-- 1. Register inventory items as Jumpdrive fuel
if jumpdrive and jumpdrive.fuel and jumpdrive.fuel.register then
	-- High efficiency: Techage Hydrogen
	jumpdrive.fuel.register("techage:cylinder_large_hydrogen", 5000)
	jumpdrive.fuel.register("techage:cylinder_small_hydrogen", 1000)
	jumpdrive.fuel.register("techage:hydrogen", 50)

	-- Medium efficiency: Petrochemicals & Refined Fuel
	jumpdrive.fuel.register("techage:cylinder_large_gas", 5000)
	jumpdrive.fuel.register("techage:ta3_cylinder_large_gas", 5000)
	jumpdrive.fuel.register("techage:ta4_cylinder_large_isobutane", 5000)
	jumpdrive.fuel.register("techage:fuel", 2500)
	jumpdrive.fuel.register("techage:diesel", 2000)
	jumpdrive.fuel.register("techage:petroleum", 1500)

	-- Auxiliary: Biofuel Canisters
	if minetest.get_modpath("biofuel") then
		jumpdrive.fuel.register("biofuel:canister_fuel", 1200)
		jumpdrive.fuel.register("biofuel:bottle_fuel", 300)
		jumpdrive.fuel.register("biofuel:biofuel", 100)
	end
end

-- 2. Register fuel tank & port into Techage Liquid Network
if minetest.get_modpath("techage") and techage and techage.register_node then
	techage.register_node({"jumpdrive_tweaks:fuel_tank", "jumpdrive_tweaks:fuel_port"}, {
		receive_liquid = function(pos, indir, name, amount)
			local meta = minetest.get_meta(pos)
			local current = meta:get_int("fuel_amount")
			local capacity = meta:get_int("capacity") or 5000
			local current_type = meta:get_string("fuel_type")

			if name ~= "techage:hydrogen" and name ~= "techage:fuel" and name ~= "techage:diesel" then
				return 0
			end
			if current > 0 and current_type ~= "" and current_type ~= name then
				return 0
			end

			local space = capacity - current
			local to_add = math.min(space, amount)
			meta:set_int("fuel_amount", current + to_add)
			meta:set_string("fuel_type", name)
			meta:set_string("infotext", string.format("Spacecraft Fuel: %d / %d (%s)", current + to_add, capacity, name))
			return to_add
		end,
		take_liquid = function(pos, indir, name, amount)
			local meta = minetest.get_meta(pos)
			local current = meta:get_int("fuel_amount")
			local to_take = math.min(current, amount)
			meta:set_int("fuel_amount", current - to_take)
			if current - to_take == 0 then
				meta:set_string("fuel_type", "")
			end
			return to_take
		end
	})
end
