-- jumpdrive_tweaks/validator.lua
-- Transfers propellant from onboard fuel tanks into the Jumpdrive engine and validates preflight

local FUEL_TO_EU_RATIO = 50 -- 1 unit of propellant = 50 EU of jump power

-- Helper: Drain fuel from tanks in area to charge engine
local function charge_engine_from_tanks(engine_pos, radius, target_eu)
	local meta = minetest.get_meta(engine_pos)
	local current_eu = meta:get_int("powerstorage")
	local max_eu = meta:get_int("max_powerstorage")
	if max_eu <= 0 then max_eu = 1000000 end

	local needed_eu = math.min(target_eu or max_eu, max_eu) - current_eu
	if needed_eu <= 0 then return current_eu end

	local search_r = math.max(radius or 5, 25)
	local p1 = vector.subtract(engine_pos, {x = search_r, y = search_r, z = search_r})
	local p2 = vector.add(engine_pos, {x = search_r, y = search_r, z = search_r})
	local tank_positions = minetest.find_nodes_in_area(p1, p2, {"jumpdrive_tweaks:fuel_tank"})

	local total_added_eu = 0
	for _, tpos in ipairs(tank_positions) do
		local tmeta = minetest.get_meta(tpos)
		local tank_fuel = tmeta:get_int("fuel_amount")
		local tank_type = tmeta:get_string("fuel_type")
		local capacity = tmeta:get_int("capacity") or 5000

		if tank_fuel > 0 then
			local fuel_needed = math.ceil((needed_eu - total_added_eu) / FUEL_TO_EU_RATIO)
			local fuel_to_take = math.min(tank_fuel, fuel_needed)

			local eu_gained = fuel_to_take * FUEL_TO_EU_RATIO
			total_added_eu = total_added_eu + eu_gained
			local new_tank_fuel = tank_fuel - fuel_to_take

			tmeta:set_int("fuel_amount", new_tank_fuel)
			if new_tank_fuel == 0 then
				tmeta:set_string("fuel_type", "")
				tmeta:set_string("infotext", string.format("Spacecraft Fuel Tank: 0 / %d units", capacity))
			else
				tmeta:set_string("infotext", string.format("Spacecraft Fuel Tank: %d / %d (%s)", new_tank_fuel, capacity, tank_type))
			end

			if total_added_eu >= needed_eu then
				break
			end
		end
	end

	if total_added_eu > 0 then
		local new_store = current_eu + total_added_eu
		meta:set_int("powerstorage", new_store)
		jumpdrive.update_infotext(meta, engine_pos)
		return new_store
	end

	return current_eu
end

-- Enable automatic background map emergence for jumps into uncharted destinations
if jumpdrive and jumpdrive.config then
	jumpdrive.config.emerge_uncharted = true
end

-- Disable the 10-second mapgen proximity lockout so jumps execute immediately
if jumpdrive then
	jumpdrive.check_mapgen = function(pos)
		return false
	end
end

-- Auto-jump on uncharted destinations (single-click workflow)
if jumpdrive and jumpdrive.execute_jump then
	local orig_execute_jump = jumpdrive.execute_jump

	jumpdrive.execute_jump = function(pos, player)
		local playername = (player and player:is_player()) and player:get_player_name() or ""
		local radius = jumpdrive.get_radius(pos)
		local targetPos = jumpdrive.get_meta_pos(pos)
		local radius_vector = vector.new(radius, radius, radius)
		local target_pos1 = vector.subtract(targetPos, radius_vector)
		local target_pos2 = vector.add(targetPos, radius_vector)

		-- Probe destination blocks
		minetest.get_voxel_manip():read_from_map(target_pos1, target_pos2)
		local is_empty, empty_msg = jumpdrive.is_area_empty(target_pos1, target_pos2)

		if not is_empty and empty_msg == "uncharted" then
			if playername ~= "" then
				minetest.chat_send_player(playername, "Target sector uncharted: generating destination and executing jump...")
			end

			local function emerge_callback(blockpos, action, calls_remaining, data)
				if calls_remaining == 0 then
					local success, msg = orig_execute_jump(pos, player)
					if success then
						if jumpdrive_tweaks and jumpdrive_tweaks.on_ship_jump then
							jumpdrive_tweaks.on_ship_jump(pos, targetPos, radius)
						end
						if playername ~= "" then
							local time_millis = math.floor(msg / 1000)
							minetest.chat_send_player(playername, "Jump executed in " .. time_millis .. " ms")
						end
					else
						if playername ~= "" then
							minetest.chat_send_player(playername, "Auto-jump aborted: " .. tostring(msg))
						end
					end
				end
			end

			minetest.emerge_area(target_pos1, target_pos2, emerge_callback)
			return false, "Charting sector in progress..."
		end

		local success, msg = orig_execute_jump(pos, player)
		if success and jumpdrive_tweaks and jumpdrive_tweaks.on_ship_jump then
			jumpdrive_tweaks.on_ship_jump(pos, targetPos, radius)
		end
		return success, msg
	end
end

-- Override jumpdrive.preflight_check to enforce atmospheric lock and charge engine from fuel tanks
if jumpdrive then
	jumpdrive.preflight_check = function(source, destination, radius, playername)
		-- Atmospheric Navigation Lock: Prohibit horizontal jumps below Y=1,000
		if (source.y < 1000 or destination.y < 1000) and (source.x ~= destination.x or source.z ~= destination.z) then
			return {
				success = false,
				msg = "Atmospheric Navigation Lock: Horizontal hyperjumps are prohibited below Y=1,000. Ascend vertically to orbit (Y >= 1,000) before maneuvering."
			}
		end

		local distance = vector.distance(source, destination)
		local power_req = jumpdrive.calculate_power(radius, distance, source, destination)

		-- Charge engine from onboard fuel tanks
		local available_eu = charge_engine_from_tanks(source, radius, power_req)

		if available_eu < power_req then
			return {
				success = false,
				msg = string.format("Not enough propellant: required %.0f EU, available %d EU. Refill onboard fuel tanks.", power_req, available_eu)
			}
		end

		return { success = true }
	end
end

-- Periodic background charging: engine draws from nearby fuel tanks
minetest.register_abm({
	label = "jumpdrive_fuel_tank_charge",
	nodenames = {"jumpdrive:engine"},
	interval = 2.0,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local radius = meta:get_int("radius")
		if radius < 1 then radius = 5 end
		charge_engine_from_tanks(pos, radius)
	end,
})

minetest.log("action", "[jumpdrive_tweaks] Registered onboard propellant transfer and preflight handler.")
