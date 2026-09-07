-- jumpdrive_tweaks/validator.lua
-- Dynamic Backbone-Proximity Spacecraft Validation, Tank Charging, Protection Gating, and Jump Execution

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local FUEL_TO_EU_RATIO = 50 -- 1 unit of propellant = 50 EU of jump power

-- Helper: Drain fuel strictly from tanks attached to the spacecraft
local function charge_engine_from_tanks(engine_pos, ship_scan, target_eu)
	local meta = minetest.get_meta(engine_pos)
	local current_eu = meta:get_int("powerstorage")
	local max_eu = meta:get_int("max_powerstorage")
	if max_eu <= 0 then max_eu = 1000000 end

	local needed_eu = math.min(target_eu or max_eu, max_eu) - current_eu
	if needed_eu <= 0 then return current_eu end

	local total_added_eu = 0
	local scan_tanks = (ship_scan and ship_scan.fuel_tanks) or nil
	if not scan_tanks then
		local scan_nodes = ship_scan and ship_scan.nodes or {engine_pos}
		scan_tanks = {}
		for _, pos in ipairs(scan_nodes) do
			local node = minetest.get_node(pos)
			if node.name == "jumpdrive_tweaks:fuel_tank" then
				table.insert(scan_tanks, pos)
			end
		end
	end

	for _, pos in ipairs(scan_tanks) do
		local tmeta = minetest.get_meta(pos)
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

-- Backbone-Guided Spacecraft Jump Execution
if jumpdrive then
	jumpdrive.execute_jump = function(pos, player)
		local playername = (player and player:is_player()) and player:get_player_name() or ""
		local meta = minetest.get_meta(pos)
		local targetPos = jumpdrive.get_meta_pos(pos)
		local distance = vector.distance(pos, targetPos)
		local delta_vector = vector.subtract(targetPos, pos)

		if distance == 0 or (pos.x == targetPos.x and pos.y == targetPos.y and pos.z == targetPos.z) then
			return false, "Destination coordinates are identical to current location!"
		end

		-- Dynamic backbone discovery
		local ship_scan = jumpdrive_tweaks.scan_spacecraft(pos)
		local power_req = jumpdrive_tweaks.calculate_ship_power(ship_scan, distance)

		local target_pos1 = vector.add(ship_scan.min_pos, delta_vector)
		local target_pos2 = vector.add(ship_scan.max_pos, delta_vector)

		-- Origin Protection Check (evaluated selectively against craft nodes)
		if jumpdrive_tweaks.is_ship_target_protected(ship_scan, {x = 0, y = 0, z = 0}, playername) then
			return false, "Jump source contains protected nodes!"
		end

		-- Destination Protection Check
		if jumpdrive_tweaks.is_ship_target_protected(ship_scan, delta_vector, playername) then
			return false, "Destination is protected!"
		end

		-- Preflight check (reusing pre-computed ship_scan)
		local preflight = jumpdrive.preflight_check(pos, targetPos, ship_scan.effective_radius, playername, ship_scan)
		if not preflight.success then
			return false, preflight.msg or "Preflight check failed!"
		end

		-- Read destination chunk into voxel manipulator
		minetest.get_voxel_manip():read_from_map(target_pos1, target_pos2)
		local is_empty, empty_msg = jumpdrive_tweaks.is_ship_target_empty(ship_scan, delta_vector)

		-- Helper function to perform the actual jump displacement
		local function do_jump_movement()
			-- Final Protection Re-Verification
			if jumpdrive_tweaks.is_ship_target_protected(ship_scan, delta_vector, playername) then
				return false, "Destination is protected!"
			end

			-- Consume power
			local current_power = meta:get_int("powerstorage")
			meta:set_int("powerstorage", math.max(0, current_power - power_req))

			minetest.sound_play("jumpdrive_engine", {
				pos = pos,
				max_hear_distance = 50,
				gain = 0.7,
			})

			local t0 = minetest.get_us_time()

			-- Activate ship mask and node list for selective transfer
			jumpdrive_tweaks.active_ship_mask = ship_scan.mask
			jumpdrive_tweaks.active_ship_nodes = ship_scan.nodes

			-- Execute selective move inside pcall to guarantee cleanup
			local ok, err = pcall(jumpdrive.move, ship_scan.min_pos, ship_scan.max_pos, target_pos1, target_pos2)

			-- Always clear active ship mask and node list
			jumpdrive_tweaks.active_ship_mask = nil
			jumpdrive_tweaks.active_ship_nodes = nil

			if not ok then
				return false, "Jump movement error: " .. tostring(err)
			end

			local t1 = minetest.get_us_time()
			local time_micros = t1 - t0

			-- Animation at destination
			minetest.add_particlespawner({
				amount = 200,
				time = 2,
				minpos = target_pos1,
				maxpos = target_pos2,
				minvel = vector.new(-2, -2, -2),
				maxvel = vector.new(2, 2, 2),
				minacc = vector.new(-3, -3, -3),
				maxacc = vector.new(3, 3, 3),
				minexptime = 0.1,
				maxexptime = 5,
				minsize = 0.5,
				maxsize = 2,
				texture = "bubble.png",
			})

			-- Telemetry logging
			local speed_c = (time_micros > 0) and ((distance / (time_micros / 1000000)) / 299792458) or 0
			minetest.log("action", string.format("[jumpdrive_tweaks] Jump completed: %d nodes, %d backbone, %.1fm distance, %d µs (effective %.2fc)",
				ship_scan.node_count, ship_scan.backbone_count, distance, time_micros, speed_c))

			-- Update engine location metadata to new coordinate
			local new_engine_pos = vector.add(pos, delta_vector)
			local new_meta = minetest.get_meta(new_engine_pos)
			new_meta:set_int("x", new_engine_pos.x)
			new_meta:set_int("y", new_engine_pos.y)
			new_meta:set_int("z", new_engine_pos.z)
			jumpdrive.update_infotext(new_meta, new_engine_pos)

			-- Reconnect TechAge networks and restart active machine loops
			if jumpdrive_tweaks.reconnect_techage_networks then
				jumpdrive_tweaks.reconnect_techage_networks(ship_scan, delta_vector)
			end

			-- Migrate beacon positions with vessel jump
			if jumpdrive_tweaks.on_ship_jump then
				jumpdrive_tweaks.on_ship_jump(pos, new_engine_pos, r, ship_scan)
			end

			-- Trigger callbacks
			if jumpdrive.execute_jump_callbacks then
				jumpdrive.execute_jump_callbacks(pos, delta_vector, target_pos1, target_pos2)
			end

			return true, time_micros
		end

		-- If target is uncharted, attempt map emergence first
		if not is_empty and empty_msg == "uncharted" then
			if minetest.emerge_area then
				minetest.log("action", string.format("[jumpdrive_tweaks] Destination chunk uncharted at [%d,%d,%d] - [%d,%d,%d]. Emerging area...",
					target_pos1.x, target_pos1.y, target_pos1.z, target_pos2.x, target_pos2.y, target_pos2.z))

				minetest.emerge_area(target_pos1, target_pos2, function(blockpos, action, calls_remaining, param)
					if calls_remaining == 0 then
						-- Verify engine node is intact before executing deferred movement
						local current_node = minetest.get_node(pos)
						if not current_node or current_node.name ~= "jumpdrive:engine" then
							minetest.log("warning", "[jumpdrive_tweaks] Deferred jump aborted: Origin engine node modified or removed during emergence.")
							if player and player:is_player() then
								minetest.chat_send_player(playername, "Jump aborted: Origin engine node modified or removed!")
							end
							return
						end

						local recheck, recheck_msg = jumpdrive_tweaks.is_ship_target_empty(ship_scan, delta_vector)
						if recheck then
							local ok, res = do_jump_movement()
							if ok then
								if player and player:is_player() then
									local time_millis = math.floor((res or 0) / 1000)
									minetest.chat_send_player(playername, string.format("Emergence complete: Jump executed in %d ms", time_millis))
								end
							else
								minetest.log("warning", "[jumpdrive_tweaks] Deferred jump movement failed: " .. tostring(res))
								if player and player:is_player() then
									minetest.chat_send_player(playername, "Jump failed: " .. tostring(res))
								end
							end
						else
							minetest.log("warning", "[jumpdrive_tweaks] Post-emergence target obstructed: " .. tostring(recheck_msg))
							if player and player:is_player() then
								minetest.chat_send_player(playername, "Jump failed: Destination area obstructed after emergence!")
							end
						end
					end
				end)
				return false, "Destination uncharted. Sector emergence initiated—vessel will jump upon emergence."
			end
		end

		if not is_empty then
			return false, "Destination hazard: " .. tostring(empty_msg)
		end

		return do_jump_movement()
	end
end

-- Override jumpdrive.preflight_check to enforce atmospheric lock, protection, and charge engine from ship fuel tanks
if jumpdrive then
	jumpdrive.preflight_check = function(source, destination, radius, playername, ship_scan)
		local distance = vector.distance(source, destination)
		if distance == 0 or (source.x == destination.x and source.y == destination.y and source.z == destination.z) then
			return {
				success = false,
				msg = "Destination coordinates are identical to current location!"
			}
		end

		-- Atmospheric Navigation Lock: Prohibit horizontal jumps below Y=1,000
		if (source.y < 1000 or destination.y < 1000) and (source.x ~= destination.x or source.z ~= destination.z) then
			if source.y < 1000 and destination.y < 1000 then
				return {
					success = false,
					msg = "Atmospheric Lock: Surface-to-surface horizontal hyperjumps are prohibited below Y=1,000. Ascend vertically to orbit (Y >= 1,000) first."
				}
			elseif source.y < 1000 then
				return {
					success = false,
					msg = "Atmospheric Launch Lock: Oblique atmospheric ascents are prohibited below Y=1,000. Ascend vertically to orbit (Y >= 1,000) before maneuvering."
				}
			else
				return {
					success = false,
					msg = string.format("Atmospheric Entry Lock: Oblique atmospheric reentry is prohibited. Cruise in orbit to align horizontally with destination (%d, 1200, %d) before vertical descent.", destination.x, destination.z)
				}
			end
		end

		local delta_vector = vector.subtract(destination, source)
		ship_scan = ship_scan or jumpdrive_tweaks.scan_spacecraft(source)
		local power_req = jumpdrive_tweaks.calculate_ship_power(ship_scan, distance)

		-- Protection checks (selective for origin craft nodes and destination footprint)
		if jumpdrive_tweaks.is_ship_target_protected(ship_scan, {x = 0, y = 0, z = 0}, playername) then
			return {
				success = false,
				msg = "Jump source contains protected nodes!"
			}
		end
		if jumpdrive_tweaks.is_ship_target_protected(ship_scan, delta_vector, playername) then
			return {
				success = false,
				msg = "Destination is protected!"
			}
		end

		-- Charge engine strictly from ship's attached fuel tanks
		local available_eu = charge_engine_from_tanks(source, ship_scan, power_req)

		if available_eu < power_req then
			return {
				success = false,
				msg = string.format("Not enough propellant: required %.0f EU, available %d EU. Refill onboard fuel tanks.", power_req, available_eu)
			}
		end

		return { success = true }
	end
end

-- Periodic background charging: engine draws from connected ship fuel tanks only when depleted
local engine_scan_throttle = {}

minetest.register_abm({
	label = "jumpdrive_fuel_tank_charge",
	nodenames = {"jumpdrive:engine"},
	interval = 4.0,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local current_eu = meta:get_int("powerstorage")
		local max_eu = meta:get_int("max_powerstorage")
		if max_eu <= 0 then max_eu = 1000000 end

		if current_eu < max_eu then
			local ehash = minetest.hash_node_position(pos)
			local now = minetest.get_gametime and minetest.get_gametime() or 0
			if not engine_scan_throttle[ehash] or now >= engine_scan_throttle[ehash] then
				local ship_scan = jumpdrive_tweaks.scan_spacecraft(pos)
				local new_eu = charge_engine_from_tanks(pos, ship_scan)
				if new_eu == current_eu then
					-- No propellant available in connected tanks: back off for 16 seconds
					engine_scan_throttle[ehash] = now + 16
				else
					engine_scan_throttle[ehash] = now + 4
				end
			end
		end
	end,
})

minetest.log("action", "[jumpdrive_tweaks] Registered backbone-guided propellant transfer and preflight handler.")
