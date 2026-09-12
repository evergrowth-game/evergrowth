-- jumpdrive_tweaks/bridge_console.lua
-- Bridge Navigation Console for diegetic starship flight control

local S = minetest.get_translator("jumpdrive_tweaks")

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

-- Format bridge console infotext based on linked engine telemetry
local function update_console_infotext(console_pos)
	local meta = minetest.get_meta(console_pos)
	local engine_pos = jumpdrive_tweaks.find_connected_engine(console_pos)

	if not engine_pos then
		meta:set_string("infotext", S("Bridge Navigation Console\n[Status: OFFLINE - No Jump Core Connected]"))
		return false
	end

	local emeta = minetest.get_meta(engine_pos)
	local tx = emeta:get_int("x")
	local ty = emeta:get_int("y")
	local tz = emeta:get_int("z")
	local target_pos = {x = tx, y = ty, z = tz}
	local dist = vector.distance(engine_pos, target_pos)

	local powerstorage = emeta:get_int("powerstorage")
	local max_powerstorage = emeta:get_int("max_powerstorage")
	if max_powerstorage <= 0 then max_powerstorage = 1000000 end
	local power_pct = math.max(0, math.min(100, math.floor((powerstorage / max_powerstorage) * 100)))

	local status_str = "STANDBY"
	if dist > 0 and powerstorage > 0 then
		status_str = "READY"
	elseif dist == 0 then
		status_str = "IDLE (Coords Not Set)"
	elseif powerstorage == 0 then
		status_str = "CHARGING (Low Buffer)"
	end

	local info_lines = {
		S("Bridge Navigation Console"),
		string.format("Status: %s | Core: (%d,%d,%d)", status_str, engine_pos.x, engine_pos.y, engine_pos.z),
		string.format("Target: (%d, %d, %d) [Dist: %dm]", tx, ty, tz, math.floor(dist)),
		string.format("Buffer: %d%% (%d / %d EU)", power_pct, powerstorage, max_powerstorage)
	}
	meta:set_string("infotext", table.concat(info_lines, "\n"))
	return true
end

minetest.register_node("jumpdrive_tweaks:bridge_console", {
	description = S("Bridge Navigation Console"),
	drawtype = "mesh",
	mesh = "jumpdrive_bridge_console.obj",
	tiles = {
		"jumpdrive_bridge_console_side.png",
		"jumpdrive_bridge_console_top.png",
		"jumpdrive_bridge_console_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 6,
	is_ground_content = false,
	groups = {
		cracky = 2,
		oddly_breakable_by_hand = 2,
		jumpdrive_ship_part = 1,
	},
	selection_box = { type = "fixed", fixed = {-0.48, -0.5, -0.48, 0.48, 0.48, 0.48} },
	collision_box = { type = "fixed", fixed = {-0.48, -0.5, -0.48, 0.48, 0.48, 0.48} },
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		local online = update_console_infotext(pos)
		timer:start(online and 1.5 or 5.0)
	end,

	on_timer = function(pos)
		local online = update_console_infotext(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(online and 1.5 or 5.0)
		return false
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker or not clicker:is_player() then return itemstack end
		local playername = clicker:get_player_name()

		-- Check if linking rangefinder to bridge console
		if itemstack and itemstack:get_name() == "jumpdrive_tweaks:rangefinder" then
			local engine_pos, err = jumpdrive_tweaks.find_connected_engine(pos)
			if engine_pos then
				return jumpdrive_tweaks.link_rangefinder(itemstack, clicker, engine_pos)
			else
				minetest.chat_send_player(playername, "[Bridge Console] Cannot link Rangefinder: " .. (err or "No Jump Core connected."))
				return itemstack
			end
		end

		if minetest.is_protected(pos, playername) then
			minetest.chat_send_player(playername, "Bridge Console is protected!")
			return itemstack
		end

		local engine_pos, err = jumpdrive_tweaks.find_connected_engine(pos)
		if not engine_pos then
			minetest.chat_send_player(playername, "[Bridge Console] " .. (err or "No Jump Core connected to ship backbone."))
			return itemstack
		end

		if minetest.is_protected(engine_pos, playername) then
			minetest.chat_send_player(playername, "[Bridge Console] Connected Jump Core is protected!")
			return itemstack
		end

		local emeta = minetest.get_meta(engine_pos)
		jumpdrive.update_formspec(emeta, engine_pos)
		local fs = emeta:get_string("formspec")
		local formname = "jumpdrive_tweaks:bridge_console_" .. minetest.pos_to_string(engine_pos)
		minetest.show_formspec(playername, formname, fs)
		return itemstack
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher or not puncher:is_player() then return end
		local wielded = puncher:get_wielded_item()
		if wielded and not wielded:is_empty() then return end
		local playername = puncher:get_player_name()

		local engine_pos, err = jumpdrive_tweaks.find_connected_engine(pos)
		if not engine_pos then
			minetest.chat_send_player(playername, "[Bridge Console] " .. (err or "No Jump Core connected to ship backbone."))
			return
		end

		if minetest.is_protected(engine_pos, playername) or minetest.is_protected(pos, playername) then
			minetest.chat_send_player(playername, "Bridge controls are protected!")
			return
		end

		local ok, res = jumpdrive.execute_jump(engine_pos, puncher)
		local is_emerging = not ok and type(res) == "string" and res:find("emergence initiated")
		if is_emerging then
			minetest.chat_send_player(playername, "[Navigation] " .. tostring(res))
		elseif not ok and res then
			minetest.chat_send_player(playername, "Jump aborted: " .. tostring(res))
		end
	end,
})

minetest.log("action", "[jumpdrive_tweaks] Loaded 3D Bridge Navigation Console.")
