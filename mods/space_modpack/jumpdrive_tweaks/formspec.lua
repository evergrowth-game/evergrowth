-- jumpdrive_tweaks/formspec.lua
-- Diegetic, telemetry-driven flight computer interface for Jumpdrive

local S = minetest.get_translator("jumpdrive_tweaks")
local has_technic = minetest.get_modpath("technic")

jumpdrive_tweaks = jumpdrive_tweaks or {}

-- Helper to scan nearby tanks for fuel readout (searches full ship volume)
local function get_fuel_telemetry(engine_pos, radius)
	if not engine_pos then return 0, 0, "None" end
	local search_r = math.max(radius or 5, 25)
	local p1 = vector.subtract(engine_pos, {x = search_r, y = search_r, z = search_r})
	local p2 = vector.add(engine_pos, {x = search_r, y = search_r, z = search_r})
	local tank_positions = minetest.find_nodes_in_area(p1, p2, {"jumpdrive_tweaks:fuel_tank"})

	local total_fuel = 0
	local total_cap = 0
	local fuel_type = "None"

	for _, tpos in ipairs(tank_positions) do
		local tmeta = minetest.get_meta(tpos)
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

	-- Fuel telemetry across ship
	local fuel_amount, fuel_cap, fuel_type = get_fuel_telemetry(pos, radius)
	local fuel_pct = (fuel_cap > 0) and math.min(100, math.floor((fuel_amount / fuel_cap) * 100)) or 0

	-- Target calculation
	local target_pos = {x = current_x, y = current_y, z = current_z}
	local distance = pos and math.floor(vector.distance(pos, target_pos)) or 0
	local power_req = (pos and jumpdrive.calculate_power) and math.floor(jumpdrive.calculate_power(radius, distance, pos, target_pos)) or 0

	-- Area safety check
	local status_text = "STATUS: STANDBY"
	local status_color = "#38bdf8" -- Cyan

	if pos then
		local radius_vec = vector.new(radius, radius, radius)
		local target_pos1 = vector.subtract(target_pos, radius_vec)
		local target_pos2 = vector.add(target_pos, radius_vec)

		minetest.get_voxel_manip():read_from_map(target_pos1, target_pos2)
		local is_empty, empty_msg = jumpdrive.is_area_empty(target_pos1, target_pos2)

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

	-- Build Beacon Dropdown entries
	local beacon_items = {"Select Navigation Beacon"}
	local active_beacons = jumpdrive_tweaks.get_active_beacons and jumpdrive_tweaks.get_active_beacons() or {}

	for _, binfo in pairs(active_beacons) do
		local label = string.format("%s @ (%d, %d, %d)", binfo.name or "Beacon", math.floor(binfo.pos.x), math.floor(binfo.pos.y), math.floor(binfo.pos.z))
		table.insert(beacon_items, minetest.formspec_escape(label))
	end

	local beacon_dropdown_str = table.concat(beacon_items, ",")

	-- Formspec Layout (Spacious 15.5x13.6 formspec_version[4] grid with dedicated inventory clearance)
	local formspec =
		"formspec_version[4]" ..
		"size[15.5,13.6]" ..
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
		"label[0.8,2.4;Jump Radius: " .. minetest.colorize("#f59e0b", string.format("%dm", radius)) .. "]" ..

		"label[8.0,1.4;Target Distance: " .. minetest.colorize("#38bdf8", string.format("%dm", distance)) .. "]" ..
		"label[8.0,1.9;Energy Required: " .. minetest.colorize("#38bdf8", string.format("%d EU", power_req)) .. "]" ..
		"label[8.0,2.4;Transponder Channel: " .. minetest.colorize("#9ca3af", (meta:get_string("channel") ~= "" and meta:get_string("channel") or "None")) .. "]" ..

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

		"button[8.2,3.8;3.1,0.6;nudge_y_neg;-250m Descent (-Y)]" ..
		"button[11.5,3.8;3.1,0.6;nudge_y_pos;+250m Ascent (+Y)]" ..

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
		"button[10.6,9.3;4.4,0.85;show;PROJECT BOUNDS]" ..
		"button[10.6,10.45;4.4,0.85;reset;RESET COORDS]" ..
		"button[10.6,11.6;4.4,0.85;save;SAVE SETTINGS]"

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
minetest.register_on_mods_loaded(function()
	local engine_def = minetest.registered_nodes["jumpdrive:engine"]
	if not engine_def then return end

	local orig_on_receive_fields = engine_def.on_receive_fields

	minetest.override_item("jumpdrive:engine", {
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not clicker or not clicker:is_player() then return itemstack end
			local meta = minetest.get_meta(pos)
			jumpdrive.update_formspec(meta, pos)
			return itemstack
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
								meta:set_int("x", jumpdrive.sanitize_coord(bx))
								meta:set_int("y", jumpdrive.sanitize_coord(by))
								meta:set_int("z", jumpdrive.sanitize_coord(bz))
								jumpdrive.update_formspec(meta, pos)
								if sender then
									minetest.chat_send_player(sender:get_player_name(), string.format("Launch Guidance: Plotted vertical ascent to [%s] at (%d, %d, %d).", bname, bx, by, bz))
								end
								return
							end
						else
							-- Case C: Direct navigation (both in space or direct vertical)
							meta:set_int("x", jumpdrive.sanitize_coord(bx))
							meta:set_int("y", jumpdrive.sanitize_coord(by))
							meta:set_int("z", jumpdrive.sanitize_coord(bz))
							jumpdrive.update_formspec(meta, pos)
							if sender then
								minetest.chat_send_player(sender:get_player_name(), string.format("Navigation plotted to beacon: [%s] at (%d, %d, %d)", bname, bx, by, bz))
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
end)
