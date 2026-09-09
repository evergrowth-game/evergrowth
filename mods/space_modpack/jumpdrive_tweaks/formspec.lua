-- jumpdrive_tweaks/formspec.lua
-- Diegetic, telemetry-driven flight computer interface for Jumpdrive

local S = minetest.get_translator("jumpdrive_tweaks")
local has_technic = minetest.get_modpath("technic")

jumpdrive_tweaks = jumpdrive_tweaks or {}

-- Helper to scan tanks for fuel readout (restricted to spacecraft nodes)
local function get_fuel_telemetry(ship_scan)
	if not ship_scan or not ship_scan.nodes then return 0, 0, "None" end

	local total_fuel = 0
	local total_cap = 0
	local fuel_type = "None"
	local tank_positions = ship_scan.fuel_tanks

	if not tank_positions then
		tank_positions = {}
		for _, pos in ipairs(ship_scan.nodes) do
			local node = minetest.get_node(pos)
			if node.name == "jumpdrive_tweaks:fuel_tank" then
				table.insert(tank_positions, pos)
			end
		end
	end

	for _, pos in ipairs(tank_positions) do
		local tmeta = minetest.get_meta(pos)
		local amt = tmeta:get_int("fuel_amount")
		local cap = tmeta:get_int("capacity") or 5000
		local ftype = tmeta:get_string("fuel_type")

		total_fuel = total_fuel + amt
		total_cap = total_cap + cap
		if ftype ~= "" and fuel_type == "None" then
			fuel_type = ftype:gsub("techage:", ""):upper()
		end
	end

	return total_fuel, total_cap, fuel_type
end

-- Override jumpdrive.update_formspec with clean, spacious sci-fi layout
jumpdrive.update_formspec = function(meta, pos)
	if not meta then return end

	local current_x = meta:get_int("x")
	local current_y = meta:get_int("y")
	local current_z = meta:get_int("z")
	local radius = meta:get_int("radius")
	if radius < 1 then radius = 5 end

	local powerstorage = meta:get_int("powerstorage")
	local max_powerstorage = meta:get_int("max_powerstorage")
	if max_powerstorage <= 0 then max_powerstorage = 1000000 end

	local power_pct = math.min(100, math.floor((powerstorage / max_powerstorage) * 100))

	-- Dynamic Spacecraft Structure & Telemetry
	local ship_scan = pos and jumpdrive_tweaks.scan_spacecraft(pos) or {
		node_count = 1,
		backbone_count = 1,
		nodes = pos and {pos} or {},
		size = {x = radius * 2 + 1, y = radius * 2 + 1, z = radius * 2 + 1},
		effective_radius = radius,
		min_pos = pos and vector.subtract(pos, {x = radius, y = radius, z = radius}) or {x = 0, y = 0, z = 0},
		max_pos = pos and vector.add(pos, {x = radius, y = radius, z = radius}) or {x = 0, y = 0, z = 0},
	}

	-- Fuel telemetry strictly from ship's tanks
	local fuel_amount, fuel_cap, fuel_type = get_fuel_telemetry(ship_scan)
	local fuel_pct = (fuel_cap > 0) and math.min(100, math.floor((fuel_amount / fuel_cap) * 100)) or 0

	-- Target calculation
	local target_pos = {x = current_x, y = current_y, z = current_z}
	local distance = pos and math.floor(vector.distance(pos, target_pos)) or 0
	local power_req = (pos and jumpdrive_tweaks.calculate_ship_power) and math.floor(jumpdrive_tweaks.calculate_ship_power(ship_scan, distance)) or 0

	-- Area safety check
	local status_text = "STATUS: STANDBY"
	local status_color = "#38bdf8" -- Cyan

	if pos then
		local delta_vec = vector.subtract(target_pos, pos)
		local is_empty, empty_msg = jumpdrive_tweaks.is_ship_target_empty(ship_scan, delta_vec)

		if (pos.y < 1000 or target_pos.y < 1000) and (pos.x ~= target_pos.x or pos.z ~= target_pos.z) then
			if pos.y < 1000 and target_pos.y < 1000 then
				status_text = "ATMOSPHERIC LOCK: VERTICAL ONLY (Y<1000)"
			elseif pos.y < 1000 then
				status_text = "LAUNCH LOCK: VERTICAL ASCENT ONLY"
			else
				status_text = "ENTRY LOCK: ALIGN IN ORBIT BEFORE DESCENT"
			end
			status_color = "#f59e0b" -- Amber
		elseif is_empty then
			status_text = "CLEAR FOR TRANSIT"
			status_color = "#10b981" -- Emerald green
		elseif empty_msg == "uncharted" then
			status_text = "SECTOR UNCHARTED (AUTO-GEN READY)"
			status_color = "#f59e0b" -- Amber
		else
			status_text = "HAZARD: DESTINATION OCCUPIED"
			status_color = "#ef4444" -- Red
		end
	end

	-- Build Beacon Dropdown entries (with stale-entry pruning)
	local beacon_items = {"Select Navigation Beacon"}
	local active_beacons = jumpdrive_tweaks.get_active_beacons and jumpdrive_tweaks.get_active_beacons() or {}
	local stale_keys = {}

	for key, binfo in pairs(active_beacons) do
		local bnode = minetest.get_node_or_nil(binfo.pos)
		if bnode and bnode.name == "jumpdrive_tweaks:beacon" then
			local label = string.format("%s @ (%d, %d, %d)", binfo.name or "Beacon", math.floor(binfo.pos.x), math.floor(binfo.pos.y), math.floor(binfo.pos.z))
			table.insert(beacon_items, minetest.formspec_escape(label))
		else
			table.insert(stale_keys, key)
		end
	end

	-- Prune orphaned beacon entries from registry
	if #stale_keys > 0 then
		for _, k in ipairs(stale_keys) do
			active_beacons[k] = nil
		end
		if jumpdrive_tweaks.save_beacons then
			jumpdrive_tweaks.save_beacons()
		end
	end

	local beacon_dropdown_str = table.concat(beacon_items, ",")

	-- Formspec Layout (Spacious 15.5x14.8 formspec_version[4] grid with full inventory clearance)
	local formspec =
		"formspec_version[4]" ..
		"size[15.5,14.8]" ..
		"bgcolor[#0a0f18;true]" ..

		-- Button Styles
		"style[jump;bgcolor=#047857;textcolor=#ffffff]" ..
		"style[show,reset,save;bgcolor=#1e293b;textcolor=#ffffff]" ..
		"style[preset_surface,preset_orbit,preset_asteroids,preset_mars,preset_deep,preset_void;bgcolor=#1e293b;textcolor=#38bdf8]" ..
		"style[nudge_x_neg,nudge_x_pos,nudge_y_neg,nudge_y_pos,nudge_z_neg,nudge_z_pos;bgcolor=#1e293b;textcolor=#f59e0b]" ..
		"style[plot_beacon;bgcolor=#0284c7;textcolor=#ffffff]" ..

		-- 1. TOP TELEMETRY & DIAGNOSTICS HEADER
		"box[0.5,0.4;14.5,2.4;#101826]" ..
		"label[0.8,0.8;STARSHIP PROPULSION & NAVIGATION CONSOLE]" ..
		"label[9.2,0.8;" .. minetest.colorize(status_color, status_text) .. "]" ..

		"label[0.8,1.4;Power Storage: " .. minetest.colorize("#38bdf8", string.format("%d / %d EU (%d%%)", powerstorage, max_powerstorage, power_pct)) .. "]" ..
		"label[0.8,1.9;Propellant Tanks: " .. minetest.colorize("#38bdf8", string.format("%d / %d units [%s] (%d%%)", fuel_amount, fuel_cap, fuel_type, fuel_pct)) .. "]" ..
		"label[0.8,2.4;Hull Structure: " .. minetest.colorize("#38bdf8", string.format("%d Nodes (%d Backbone)", ship_scan.node_count, ship_scan.backbone_count)) .. "]" ..

		"label[8.0,1.4;Target Distance: " .. minetest.colorize("#38bdf8", string.format("%dm", distance)) .. "]" ..
		"label[8.0,1.9;Energy Required: " .. minetest.colorize("#38bdf8", string.format("%d EU (Rating: R=%d)", power_req, ship_scan.effective_radius)) .. "]" ..
		"label[8.0,2.4;Hull Geometry: " .. minetest.colorize("#f59e0b", string.format("Span %d×%d×%d", ship_scan.size.x, ship_scan.size.y, ship_scan.size.z)) .. "]" ..

		-- 2. MIDDLE LEFT: DESTINATION COORDINATES & PRESETS
		"box[0.5,3.0;7.1,4.2;#132034]" ..
		"label[0.8,3.4;DESTINATION COORDINATES & PRESETS]" ..

		"field[0.8,3.8;1.3,0.7;x;X;" .. current_x .. "]" ..
		"field[2.3,3.8;1.3,0.7;y;Y;" .. current_y .. "]" ..
		"field[3.8,3.8;1.3,0.7;z;Z;" .. current_z .. "]" ..
		"field[5.3,3.8;1.8,0.7;radius;Radius;" .. radius .. "]" ..

		"label[0.8,4.7;Orbital Waypoint Presets:]" ..
		"button[0.8,5.0;3.1,0.6;preset_surface;Surface (Y=20)]" ..
		"button[4.1,5.0;3.1,0.6;preset_orbit;Low Orbit (1200)]" ..
		"button[0.8,5.7;3.1,0.6;preset_asteroids;Asteroids (5200)]" ..
		"button[4.1,5.7;3.1,0.6;preset_mars;Mars Orbit (6200)]" ..
		"button[0.8,6.4;3.1,0.6;preset_deep;Deep Space (10k)]" ..
		"button[4.1,6.4;3.1,0.6;preset_void;Outer Void (20k)]" ..

		-- 3. MIDDLE RIGHT: DIRECTIONAL VECTOR NUDGE & BEACONS
		"box[7.9,3.0;7.1,4.2;#132034]" ..
		"label[8.2,3.4;DIRECTIONAL VECTOR NUDGE & BEACONS]" ..

		"button[8.2,3.8;3.1,0.6;nudge_y_neg;-250 Y (Down)]" ..
		"button[11.5,3.8;3.1,0.6;nudge_y_pos;+250 Y (Up)]" ..

		"button[8.2,4.5;1.5,0.6;nudge_x_neg;-500 X (W)]" ..
		"button[9.9,4.5;1.5,0.6;nudge_x_pos;+500 X (E)]" ..
		"button[11.6,4.5;1.5,0.6;nudge_z_neg;-500 Z (S)]" ..
		"button[13.3,4.5;1.5,0.6;nudge_z_pos;+500 Z (N)]" ..

		"label[8.2,5.4;Lock Navigation Beacon:]" ..
		"dropdown[8.2,5.7;5.0,0.7;beacon_select;" .. beacon_dropdown_str .. ";1]" ..
		"button[13.4,5.7;1.2,0.7;plot_beacon;Plot]" ..

		-- 4. BOTTOM INVENTORIES & ACTION CONTROLS (Isolated columns to avoid overlap)
		"label[0.5,7.5;Engine Buffer Inventory:]" ..
		"list[context;main;0.5,7.8;8,1;]" ..
		"label[0.5,9.0;Player Cargo Inventory:]" ..
		"list[current_player;main;0.5,9.3;8,4;]" ..
		"listring[context;main]" ..
		"listring[current_player;main]" ..

		"button_exit[10.6,7.8;4.4,1.2;jump;ENGAGE JUMP DRIVE]" ..
		"button[10.6,9.4;4.4,0.9;show;PROJECT BOUNDS]" ..
		"button[10.6,10.6;4.4,0.9;reset;RESET COORDS]" ..
		"button[10.6,11.8;4.4,0.9;save;SAVE SETTINGS]"

	meta:set_string("formspec", formspec)
end

-- Helper to sanitize and sync coordinate fields from form input
local function sync_coords_from_fields(meta, fields)
	local x = tonumber(fields.x)
	local y = tonumber(fields.y)
	local z = tonumber(fields.z)
	local radius = tonumber(fields.radius)

	if x then meta:set_int("x", jumpdrive.sanitize_coord(x)) end
	if y then meta:set_int("y", jumpdrive.sanitize_coord(y)) end
	if z then meta:set_int("z", jumpdrive.sanitize_coord(z)) end
	if radius and radius >= 1 then
		local max_r = jumpdrive.config and jumpdrive.config.max_radius or 30
		meta:set_int("radius", math.min(radius, max_r))
	end
end

-- Override jumpdrive:engine to add on_rightclick dynamic refresh and handle all field inputs
local engine_def = minetest.registered_nodes["jumpdrive:engine"]
if engine_def then
	local orig_on_receive_fields = engine_def.on_receive_fields

	minetest.override_item("jumpdrive:engine", {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not clicker or not clicker:is_player() then return itemstack end
			if itemstack and itemstack:get_name() == "jumpdrive_tweaks:rangefinder" then
				if jumpdrive_tweaks.link_rangefinder then
					return jumpdrive_tweaks.link_rangefinder(itemstack, clicker, pos)
				end
			end
			local meta = minetest.get_meta(pos)
			jumpdrive.update_formspec(meta, pos)
			return itemstack
		end,

		on_punch = function(pos, node, puncher, pointed_thing)
			if not puncher or not puncher:is_player() then return end
			local wielded = puncher:get_wielded_item()
			if wielded and not wielded:is_empty() then return end
			local name = puncher:get_player_name()
			if minetest.is_protected(pos, name) then
				minetest.chat_send_player(name, "Jump engine is protected!")
				return
			end
			local ok, res = jumpdrive.execute_jump(pos, puncher)
			if not ok and res then
				minetest.chat_send_player(name, "Jump aborted: " .. tostring(res))
			end
		end,

		on_receive_fields = function(pos, formname, fields, sender)
			local meta = minetest.get_meta(pos)

			-- Handle Reset Button (aligns destination coords with ship position)
			if fields.reset then
				meta:set_int("x", pos.x)
				meta:set_int("y", pos.y)
				meta:set_int("z", pos.z)
				jumpdrive.update_formspec(meta, pos)
				return
			end

			-- Handle Show / Project Bounds Button
			if fields.show then
				local ship_scan = jumpdrive_tweaks.scan_spacecraft(pos)
				local target_pos = {x = meta:get_int("x"), y = meta:get_int("y"), z = meta:get_int("z")}
				local delta_vec = vector.subtract(target_pos, pos)
				local target_min = vector.add(ship_scan.min_pos, delta_vec)
				local target_max = vector.add(ship_scan.max_pos, delta_vec)

				if minetest.get_modpath("vizlib") and vizlib and type(vizlib.draw_box) == "function" then
					vizlib.draw_box(ship_scan.min_pos, ship_scan.max_pos, { color = "#00ff00", player = sender })
					vizlib.draw_box(target_min, target_max, { color = "#ff0000", player = sender })
				end
				if sender and sender.is_player and sender:is_player() then
					minetest.chat_send_player(sender:get_player_name(), string.format("Spacecraft Bounds: %d nodes (%d backbone) spanning [%d,%d,%d] to [%d,%d,%d] (%d×%d×%d)",
						ship_scan.node_count, ship_scan.backbone_count,
						ship_scan.min_pos.x, ship_scan.min_pos.y, ship_scan.min_pos.z,
						ship_scan.max_pos.x, ship_scan.max_pos.y, ship_scan.max_pos.z,
						ship_scan.size.x, ship_scan.size.y, ship_scan.size.z))
				end
				return
			end

			-- Always sync any modified coordinate text fields first
			sync_coords_from_fields(meta, fields)

			-- Handle orbital presets
			if fields.preset_surface then
				meta:set_int("x", pos.x)
				meta:set_int("y", 20)
				meta:set_int("z", pos.z)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_orbit then
				meta:set_int("x", pos.x)
				meta:set_int("y", 1200)
				meta:set_int("z", pos.z)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_asteroids then
				if pos.y < 1000 then
					meta:set_int("x", pos.x)
					meta:set_int("z", pos.z)
				end
				meta:set_int("y", 5200)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_mars then
				if pos.y < 1000 then
					meta:set_int("x", pos.x)
					meta:set_int("z", pos.z)
				end
				meta:set_int("y", 6200)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_deep then
				if pos.y < 1000 then
					meta:set_int("x", pos.x)
					meta:set_int("z", pos.z)
				end
				meta:set_int("y", 10000)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_void then
				if pos.y < 1000 then
					meta:set_int("x", pos.x)
					meta:set_int("z", pos.z)
				end
				meta:set_int("y", 20000)
				jumpdrive.update_formspec(meta, pos)
				return
			end

			-- Handle relative vector nudges
			if fields.nudge_x_pos then
				meta:set_int("x", jumpdrive.sanitize_coord(meta:get_int("x") + 500))
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.nudge_x_neg then
				meta:set_int("x", jumpdrive.sanitize_coord(meta:get_int("x") - 500))
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.nudge_y_pos then
				meta:set_int("y", jumpdrive.sanitize_coord(meta:get_int("y") + 250))
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.nudge_y_neg then
				meta:set_int("y", jumpdrive.sanitize_coord(meta:get_int("y") - 250))
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.nudge_z_pos then
				meta:set_int("z", jumpdrive.sanitize_coord(meta:get_int("z") + 500))
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.nudge_z_neg then
				meta:set_int("z", jumpdrive.sanitize_coord(meta:get_int("z") - 500))
				jumpdrive.update_formspec(meta, pos)
				return
			end

			-- Handle beacon plotting matching dropdown selection with 2-stage guidance
			if fields.plot_beacon and fields.beacon_select then
				local active_beacons = jumpdrive_tweaks.get_active_beacons and jumpdrive_tweaks.get_active_beacons() or {}
				for _, binfo in pairs(active_beacons) do
					local label = string.format("%s @ (%d, %d, %d)", binfo.name or "Beacon", math.floor(binfo.pos.x), math.floor(binfo.pos.y), math.floor(binfo.pos.z))
					if label == fields.beacon_select and binfo.pos then
						local bx = math.floor(binfo.pos.x)
						local by = math.floor(binfo.pos.y)
						local bz = math.floor(binfo.pos.z)
						local bname = binfo.name or "Beacon"

						-- Compute standoff-adjusted arrival position for space targets.
						-- Uses the same effective_radius + margin approach as the
						-- Optical Rangefinder to prevent materializing inside structures.
						local function compute_standoff_arrival(target_x, target_y, target_z)
							local beacon_pos = {x = target_x, y = target_y, z = target_z}
							local dist = vector.distance(pos, beacon_pos)
							if dist < 1 then
								return target_x, target_y, target_z, 0
							end

							local ship_scan = jumpdrive_tweaks.scan_spacecraft(pos)
							local effective_radius = ship_scan and ship_scan.effective_radius or 5
							local standoff_margin = 20
							local standoff_distance = effective_radius + standoff_margin

							if dist <= standoff_distance then
								return target_x, target_y, target_z, 0
							end

							local dir = vector.direction(pos, beacon_pos)
							local delta_dist = dist - standoff_distance
							local ax = jumpdrive.sanitize_coord(math.floor(pos.x + dir.x * delta_dist + 0.5))
							local ay = jumpdrive.sanitize_coord(math.floor(pos.y + dir.y * delta_dist + 0.5))
							local az = jumpdrive.sanitize_coord(math.floor(pos.z + dir.z * delta_dist + 0.5))
							return ax, ay, az, standoff_distance
						end

						-- Case A: Ship in orbit/space (Y >= 1000) and target beacon on surface (Y < 1000)
						if pos.y >= 1000 and by < 1000 then
							if pos.x ~= bx or pos.z ~= bz then
								-- Stage 1: Plot orbital approach waypoint directly above beacon
								meta:set_int("x", jumpdrive.sanitize_coord(bx))
								meta:set_int("y", 1200)
								meta:set_int("z", jumpdrive.sanitize_coord(bz))
								jumpdrive.update_formspec(meta, pos)
								if sender then
									minetest.chat_send_player(sender:get_player_name(), string.format("Orbital Guidance: Plotted approach vector above [%s] at (%d, 1200, %d). Once in position, plot vertical touchdown.", bname, bx, bz))
								end
								return
							else
								-- Stage 2: Already aligned horizontally in orbit -> plot vertical descent
								meta:set_int("x", jumpdrive.sanitize_coord(bx))
								meta:set_int("y", jumpdrive.sanitize_coord(by))
								meta:set_int("z", jumpdrive.sanitize_coord(bz))
								jumpdrive.update_formspec(meta, pos)
								if sender then
									minetest.chat_send_player(sender:get_player_name(), string.format("Landing Guidance: Ship aligned in orbit. Plotted vertical descent to [%s] at (%d, %d, %d).", bname, bx, by, bz))
								end
								return
							end
						-- Case B: Ship on surface (Y < 1000) and target beacon in space (Y >= 1000)
						elseif pos.y < 1000 and by >= 1000 then
							if pos.x ~= bx or pos.z ~= bz then
								-- Stage 1: Plot vertical ascent into orbit first
								meta:set_int("x", jumpdrive.sanitize_coord(pos.x))
								meta:set_int("y", 1200)
								meta:set_int("z", jumpdrive.sanitize_coord(pos.z))
								jumpdrive.update_formspec(meta, pos)
								if sender then
									minetest.chat_send_player(sender:get_player_name(), string.format("Atmospheric Guidance: Plotted vertical ascent to orbit (Y=1,200). Once in orbit, navigate to [%s].", bname))
								end
								return
							else
								-- Vertical ascent to space beacon; apply standoff
								local ax, ay, az, so = compute_standoff_arrival(bx, by, bz)
								meta:set_int("x", ax)
								meta:set_int("y", ay)
								meta:set_int("z", az)
								jumpdrive.update_formspec(meta, pos)
								if sender then
									if so > 0 then
										minetest.chat_send_player(sender:get_player_name(), string.format("Launch Guidance: Plotted ascent to [%s] at (%d, %d, %d) [Standoff: %dm].", bname, ax, ay, az, so))
									else
										minetest.chat_send_player(sender:get_player_name(), string.format("Launch Guidance: Plotted vertical ascent to [%s] at (%d, %d, %d).", bname, ax, ay, az))
									end
								end
								return
							end
						else
							-- Case C: Direct navigation (both in space or both on surface)
							if by >= 1000 then
								-- Space target: apply standoff to avoid materializing inside structures
								local ax, ay, az, so = compute_standoff_arrival(bx, by, bz)
								meta:set_int("x", ax)
								meta:set_int("y", ay)
								meta:set_int("z", az)
								jumpdrive.update_formspec(meta, pos)
								if sender then
									if so > 0 then
										minetest.chat_send_player(sender:get_player_name(), string.format("Navigation plotted to beacon: [%s] at (%d, %d, %d) [Standoff: %dm]", bname, ax, ay, az, so))
									else
										minetest.chat_send_player(sender:get_player_name(), string.format("Navigation plotted to beacon: [%s] at (%d, %d, %d)", bname, ax, ay, az))
									end
								end
							else
								-- Surface target: direct coordinates (player-placed beacons)
								meta:set_int("x", jumpdrive.sanitize_coord(bx))
								meta:set_int("y", jumpdrive.sanitize_coord(by))
								meta:set_int("z", jumpdrive.sanitize_coord(bz))
								jumpdrive.update_formspec(meta, pos)
								if sender then
									minetest.chat_send_player(sender:get_player_name(), string.format("Navigation plotted to beacon: [%s] at (%d, %d, %d)", bname, bx, by, bz))
								end
							end
							return
						end
					end
				end
			end

			if orig_on_receive_fields then
				return orig_on_receive_fields(pos, formname, fields, sender)
			end
		end
	})
end
