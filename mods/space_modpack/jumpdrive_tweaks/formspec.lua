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
			status_text = "ATMOSPHERIC LOCK: VERTICAL ONLY (Y<1000)"
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
	local beacon_items = {"Select Active Transponder"}
	local active_beacons = jumpdrive_tweaks.get_active_beacons and jumpdrive_tweaks.get_active_beacons() or {}

	for _, binfo in pairs(active_beacons) do
		local label = string.format("%s @ (%d, %d, %d)", binfo.name or "Beacon", math.floor(binfo.pos.x), math.floor(binfo.pos.y), math.floor(binfo.pos.z))
		table.insert(beacon_items, minetest.formspec_escape(label))
	end

	local beacon_dropdown_str = table.concat(beacon_items, ",")

	-- Formspec Layout (Clean 14x12.8 formspec_version[4] grid with distinct functional panels)
	local formspec =
		"formspec_version[4]" ..
		"size[14,12.8]" ..
		"bgcolor[#0a0f18;true]" ..

		-- Button Styles
		"style[jump;bgcolor=#047857;textcolor=#ffffff]" ..
		"style[show,reset,save;bgcolor=#1e293b;textcolor=#ffffff]" ..
		"style[preset_surface,preset_orbit,preset_asteroids,preset_moon,preset_mars;bgcolor=#1e293b;textcolor=#38bdf8]" ..
		"style[nudge_x_neg,nudge_x_pos,nudge_y_neg,nudge_y_pos,nudge_z_neg,nudge_z_pos;bgcolor=#1e293b;textcolor=#f59e0b]" ..
		"style[plot_beacon;bgcolor=#0284c7;textcolor=#ffffff]" ..

		-- 1. TOP TELEMETRY & DIAGNOSTICS HEADER
		"box[0.4,0.4;13.2,2.4;#101826]" ..
		"label[0.7,0.8;STARSHIP PROPULSION & NAVIGATION CONSOLE]" ..
		"label[8.6,0.8;" .. minetest.colorize(status_color, status_text) .. "]" ..

		"label[0.7,1.4;Power Storage: " .. minetest.colorize("#38bdf8", string.format("%d / %d EU (%d%%)", powerstorage, max_powerstorage, power_pct)) .. "]" ..
		"label[0.7,1.9;Propellant Tanks: " .. minetest.colorize("#38bdf8", string.format("%d / %d units [%s] (%d%%)", fuel_amount, fuel_cap, fuel_type, fuel_pct)) .. "]" ..
		"label[0.7,2.4;Jump Radius: " .. minetest.colorize("#f59e0b", string.format("%dm", radius)) .. "]" ..

		"label[7.2,1.4;Target Distance: " .. minetest.colorize("#38bdf8", string.format("%dm", distance)) .. "]" ..
		"label[7.2,1.9;Energy Required: " .. minetest.colorize("#38bdf8", string.format("%d EU", power_req)) .. "]" ..
		"label[7.2,2.4;Transponder Channel: " .. minetest.colorize("#9ca3af", (meta:get_string("channel") ~= "" and meta:get_string("channel") or "None")) .. "]" ..

		-- 2. MIDDLE LEFT: DESTINATION COORDINATES & PRESETS
		"box[0.4,3.1;6.4,3.5;#132034]" ..
		"label[0.7,3.5;DESTINATION COORDINATES]" ..

		"field[0.7,3.9;1.2,0.7;x;X;" .. current_x .. "]" ..
		"field[2.1,3.9;1.2,0.7;y;Y;" .. current_y .. "]" ..
		"field[3.5,3.9;1.2,0.7;z;Z;" .. current_z .. "]" ..
		"field[4.9,3.9;1.6,0.7;radius;Radius;" .. radius .. "]" ..

		"label[0.7,4.9;Orbital Waypoint Presets:]" ..
		"button[0.7,5.2;2.8,0.6;preset_surface;Surface (Y=20)]" ..
		"button[3.7,5.2;2.8,0.6;preset_orbit;Low Orbit (1200)]" ..
		"button[0.7,5.9;2.8,0.6;preset_asteroids;Asteroids (2500)]" ..
		"button[3.7,5.9;2.8,0.6;preset_moon;Moon (5000)]" ..

		-- 3. MIDDLE RIGHT: VECTOR NUDGE & BEACONS
		"box[7.2,3.1;6.4,3.5;#132034]" ..
		"label[7.5,3.5;VECTOR NUDGE & BEACONS]" ..
		"button[7.5,3.9;1.3,0.6;nudge_x_neg;-500 X]" ..
		"button[9.0,3.9;1.3,0.6;nudge_x_pos;+500 X]" ..
		"button[10.5,3.9;1.3,0.6;nudge_y_neg;-250 Y]" ..
		"button[12.0,3.9;1.3,0.6;nudge_y_pos;+250 Y]" ..

		"button[7.5,4.6;1.3,0.6;nudge_z_neg;-500 Z]" ..
		"button[9.0,4.6;1.3,0.6;nudge_z_pos;+500 Z]" ..
		"button[10.5,4.6;2.8,0.6;preset_mars;Mars Orbit (8000)]" ..

		"label[7.5,5.3;Lock Vessel Transponder:]" ..
		"dropdown[7.5,5.6;4.6,0.7;beacon_select;" .. beacon_dropdown_str .. ";1]" ..
		"button[12.3,5.6;1.0,0.7;plot_beacon;Plot]" ..

		-- 4. BOTTOM INVENTORIES & ACTION CONTROLS
		"label[0.4,6.8;Engine Buffer Inventory:]" ..
		"list[context;main;0.4,7.1;8,1;]" ..
		"label[0.4,8.1;Player Cargo Inventory:]" ..
		"list[current_player;main;0.4,8.4;8,4;]" ..
		"listring[context;main]" ..
		"listring[current_player;main]" ..

		"button_exit[8.9,7.1;4.7,1.1;jump;ENGAGE JUMP DRIVE]" ..
		"button[8.9,8.4;4.7,0.8;show;PROJECT BOUNDS]" ..
		"button[8.9,9.4;4.7,0.8;reset;RESET COORDS]" ..
		"button[8.9,10.4;4.7,0.8;save;SAVE SETTINGS]"

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

			-- Always sync any modified coordinate text fields first
			sync_coords_from_fields(meta, fields)

			-- Handle orbital presets
			if fields.preset_surface then
				meta:set_int("y", 20)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_orbit then
				meta:set_int("y", 1200)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_asteroids then
				meta:set_int("y", 2500)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_moon then
				meta:set_int("y", 5000)
				jumpdrive.update_formspec(meta, pos)
				return
			elseif fields.preset_mars then
				meta:set_int("y", 8000)
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

			-- Handle beacon plotting matching dropdown selection
			if fields.plot_beacon and fields.beacon_select then
				local active_beacons = jumpdrive_tweaks.get_active_beacons and jumpdrive_tweaks.get_active_beacons() or {}
				for _, binfo in pairs(active_beacons) do
					local label = string.format("%s @ (%d, %d, %d)", binfo.name or "Beacon", math.floor(binfo.pos.x), math.floor(binfo.pos.y), math.floor(binfo.pos.z))
					if label == fields.beacon_select and binfo.pos then
						meta:set_int("x", jumpdrive.sanitize_coord(math.floor(binfo.pos.x)))
						meta:set_int("y", jumpdrive.sanitize_coord(math.floor(binfo.pos.y)))
						meta:set_int("z", jumpdrive.sanitize_coord(math.floor(binfo.pos.z)))
						jumpdrive.update_formspec(meta, pos)
						if sender then
							minetest.chat_send_player(sender:get_player_name(), "Navigation plotted to beacon: " .. (binfo.name or "Vessel"))
						end
						return
					end
				end
			end

			if orig_on_receive_fields then
				return orig_on_receive_fields(pos, formname, fields, sender)
			end
		end
	})
end)
