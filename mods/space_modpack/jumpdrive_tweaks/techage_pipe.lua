-- jumpdrive_tweaks/techage_pipe.lua
-- Integration with Techage Liquid Network and item fuel registration

-- 1. Register inventory items as Jumpdrive fuel
if jumpdrive and jumpdrive.fuel and jumpdrive.fuel.register then
	-- Canonical propellant: Techage Hydrogen
	jumpdrive.fuel.register("techage:cylinder_large_hydrogen", 5000)
	jumpdrive.fuel.register("techage:cylinder_small_hydrogen", 1000)
	jumpdrive.fuel.register("techage:hydrogen", 50)
end

-- 2. Register fuel tank & port into Techage Liquid Network
if minetest.get_modpath("techage") and minetest.get_modpath("networks") then
	local Pipe = techage.LiquidPipe
	local liquid = networks.liquid

	local VALID_FUELS = {
		["techage:hydrogen"] = true,
	}

	-- A. Onboard Fuel Tank Pipe Interface (Direct connection)
	local tank_liquid_def = {
		capa = 5000,
		peek = function(pos, indir)
			local meta = minetest.get_meta(pos)
			local amt = meta:get_int("fuel_amount")
			if amt > 0 then
				local ftype = meta:get_string("fuel_type")
				return (ftype ~= "") and ftype or nil
			end
			return nil
		end,
		put = function(pos, indir, name, amount)
			if not VALID_FUELS[name] then
				return amount
			end
			local meta = minetest.get_meta(pos)
			local current = meta:get_int("fuel_amount")
			local capacity = meta:get_int("capacity")
			if capacity <= 0 then capacity = 5000 end
			local current_type = meta:get_string("fuel_type")

			if current > 0 and current_type ~= "" and current_type ~= name then
				return amount -- Disallow mixing different fuels in same tank
			end

			local space = capacity - current
			local to_add = math.min(space, amount)
			local new_amount = current + to_add
			meta:set_int("fuel_amount", new_amount)
			meta:set_string("fuel_type", name)
			meta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, name))
			return amount - to_add
		end,
		take = function(pos, indir, name, amount)
			local meta = minetest.get_meta(pos)
			local current = meta:get_int("fuel_amount")
			local current_type = meta:get_string("fuel_type")
			if current <= 0 or (name and current_type ~= name) then
				return 0, name
			end
			local capacity = meta:get_int("capacity")
			if capacity <= 0 then capacity = 5000 end
			local to_take = math.min(current, amount)
			local new_amount = current - to_take
			meta:set_int("fuel_amount", new_amount)
			if new_amount == 0 then
				meta:set_string("fuel_type", "")
				meta:set_string("infotext", string.format("Spacecraft Fuel Tank: 0 / %d units", capacity))
			else
				meta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, current_type))
			end
			return to_take, current_type
		end,
		untake = function(pos, indir, name, amount)
			if not VALID_FUELS[name] then return amount end
			local meta = minetest.get_meta(pos)
			local current = meta:get_int("fuel_amount")
			local capacity = meta:get_int("capacity")
			if capacity <= 0 then capacity = 5000 end
			local current_type = meta:get_string("fuel_type")
			if current > 0 and current_type ~= "" and current_type ~= name then
				return amount
			end
			local space = capacity - current
			local to_add = math.min(space, amount)
			local new_amount = current + to_add
			meta:set_int("fuel_amount", new_amount)
			meta:set_string("fuel_type", name)
			meta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, name))
			return amount - to_add
		end,
	}

	-- Helper: Find all fuel tanks attached to the spacecraft connected to this refueling port
	local function get_ship_fuel_tanks(port_pos)
		if jumpdrive_tweaks and jumpdrive_tweaks.scan_spacecraft then
			local ship_scan = jumpdrive_tweaks.scan_spacecraft(port_pos)
			if ship_scan.fuel_tanks then
				return ship_scan.fuel_tanks
			end
			local tanks = {}
			for _, pos in ipairs(ship_scan.nodes) do
				local node = minetest.get_node(pos)
				if node.name == "jumpdrive_tweaks:fuel_tank" then
					table.insert(tanks, pos)
				end
			end
			return tanks
		end
		local p1 = vector.subtract(port_pos, {x = 25, y = 25, z = 25})
		local p2 = vector.add(port_pos, {x = 25, y = 25, z = 25})
		return minetest.find_nodes_in_area(p1, p2, {"jumpdrive_tweaks:fuel_tank"})
	end

	-- B. Exterior Refueling Port Interface (Routes fluid to ship tanks without needing to touch)
	local port_liquid_def
	port_liquid_def = {
		capa = 5000,
		peek = function(pos, indir)
			local tank_positions = get_ship_fuel_tanks(pos)
			for _, tpos in ipairs(tank_positions) do
				local tmeta = minetest.get_meta(tpos)
				local amt = tmeta:get_int("fuel_amount")
				if amt > 0 then
					local ftype = tmeta:get_string("fuel_type")
					if ftype ~= "" then return ftype end
				end
			end
			return nil
		end,
		put = function(pos, indir, name, amount)
			if not VALID_FUELS[name] then
				return amount
			end
			local tank_positions = get_ship_fuel_tanks(pos)
			if #tank_positions == 0 then
				minetest.get_meta(pos):set_string("infotext", "Spacecraft Refueling Port (No fuel tanks in ship range!)")
				return amount
			end

			local remaining = amount
			local total_ship_fuel = 0
			local total_ship_capa = 0

			for _, tpos in ipairs(tank_positions) do
				local tmeta = minetest.get_meta(tpos)
				local current = tmeta:get_int("fuel_amount")
				local capacity = tmeta:get_int("capacity")
				if capacity <= 0 then capacity = 5000 end
				local current_type = tmeta:get_string("fuel_type")

				total_ship_capa = total_ship_capa + capacity

				if remaining > 0 and (current == 0 or current_type == "" or current_type == name) then
					local space = capacity - current
					local to_add = math.min(space, remaining)
					local new_amount = current + to_add
					remaining = remaining - to_add
					tmeta:set_int("fuel_amount", new_amount)
					tmeta:set_string("fuel_type", name)
					tmeta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, name))
					total_ship_fuel = total_ship_fuel + new_amount
				else
					total_ship_fuel = total_ship_fuel + current
				end
			end

			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", string.format("Spacecraft Refueling Port: %d / %d (%s)", total_ship_fuel, total_ship_capa, name))
			return remaining
		end,
		take = function(pos, indir, name, amount)
			local tank_positions = get_ship_fuel_tanks(pos)
			local remaining_to_take = amount
			local taken_type = name

			for _, tpos in ipairs(tank_positions) do
				if remaining_to_take <= 0 then break end
				local tmeta = minetest.get_meta(tpos)
				local current = tmeta:get_int("fuel_amount")
				local current_type = tmeta:get_string("fuel_type")
				if current > 0 and (not taken_type or current_type == taken_type) and (not name or current_type == name) then
					taken_type = taken_type or current_type
					local capacity = tmeta:get_int("capacity")
					if capacity <= 0 then capacity = 5000 end
					local take_from_tank = math.min(current, remaining_to_take)
					remaining_to_take = remaining_to_take - take_from_tank
					local new_amount = current - take_from_tank
					tmeta:set_int("fuel_amount", new_amount)
					if new_amount == 0 then
						tmeta:set_string("fuel_type", "")
						tmeta:set_string("infotext", string.format("Spacecraft Fuel Tank: 0 / %d units", capacity))
					else
						tmeta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_amount, capacity, current_type))
					end
				end
			end

			return amount - remaining_to_take, taken_type
		end,
		untake = function(pos, indir, name, amount)
			return port_liquid_def.put(pos, indir, name, amount)
		end,
	}

	-- Register all 6 sides of both fuel tank and fuel port into TechAge liquid network
	liquid.register_nodes({"jumpdrive_tweaks:fuel_tank"}, Pipe, "tank", {"L", "R", "T", "D", "F", "B"}, tank_liquid_def)
	liquid.register_nodes({"jumpdrive_tweaks:fuel_port"}, Pipe, "tank", {"L", "R", "T", "D", "F", "B"}, port_liquid_def)
end
