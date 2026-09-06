-- jumpdrive_tweaks/beacon.lua
-- Ship Transponder Beacon (3D In-World Waypoint) and Quantum Recall Tether

local storage = minetest.get_mod_storage()
local S = minetest.get_translator("jumpdrive_tweaks")

-- In-memory registry of active beacons: hash -> {pos = {x, y, z}, owner = string, name = string}
local active_beacons = {}

-- Load beacons from storage
local function load_beacons()
	local raw = storage:get_string("active_beacons")
	if raw and raw ~= "" then
		active_beacons = minetest.deserialize(raw) or {}
	end
end

-- Save beacons to storage
local function save_beacons()
	storage:set_string("active_beacons", minetest.serialize(active_beacons))
end

load_beacons()

jumpdrive_tweaks = jumpdrive_tweaks or {}
jumpdrive_tweaks.get_active_beacons = function()
	return active_beacons
end

local function pos_to_key(pos)
	return string.format("%d,%d,%d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
end

-- Update beacon positions when a ship executes a jump
jumpdrive_tweaks.on_ship_jump = function(source_pos, target_pos, radius)
	if not source_pos or not target_pos then return end
	local delta = vector.subtract(target_pos, source_pos)
	local r = math.max(radius or 5, 25)
	local updated = false

	local to_remove = {}
	local to_add = {}

	for key, bdata in pairs(active_beacons) do
		local bp = bdata.pos
		if math.abs(bp.x - source_pos.x) <= r and
		   math.abs(bp.y - source_pos.y) <= r and
		   math.abs(bp.z - source_pos.z) <= r then
			table.insert(to_remove, key)
			local new_p = vector.add(bp, delta)
			local new_key = pos_to_key(new_p)
			to_add[new_key] = {
				pos = new_p,
				owner = bdata.owner,
				name = bdata.name
			}
			updated = true
		end
	end

	for _, k in ipairs(to_remove) do
		active_beacons[k] = nil
	end
	for k, v in pairs(to_add) do
		active_beacons[k] = v
	end

	if updated then
		save_beacons()
	end
end

-- 1. Navigation Beacon Node
local function get_beacon_formspec(ship_name)
	return "size[6,3]" ..
		"label[0.5,0.5;Navigation Beacon Configuration]" ..
		"field[0.8,1.5;4.8,0.8;ship_name;Beacon Name;" .. minetest.formspec_escape(ship_name) .. "]" ..
		"button_exit[2,2.3;2,0.8;save;Save]"
end

minetest.register_node("jumpdrive_tweaks:beacon", {
	description = S("Navigation Beacon"),
	tiles = {
		"jumpdrive_warpdevice.png^[colorize:#00e5ff:70",
		"jumpdrive_warpdevice.png",
		"jumpdrive_warpdevice.png^[colorize:#00e5ff:40",
		"jumpdrive_warpdevice.png^[colorize:#00e5ff:40",
		"jumpdrive_warpdevice.png^[colorize:#00e5ff:60",
		"jumpdrive_warpdevice.png^[colorize:#00e5ff:60"
	},
	paramtype = "light",
	light_source = 14,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2, oddly_breakable_by_hand = 1, jumpdrive_ship_part = 1},
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("ship_name", "Beacon")
		meta:set_string("infotext", "Navigation Beacon: [Beacon]")
	end,

	after_place_node = function(pos, placer)
		if placer and placer:is_player() then
			local pname = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", pname)
			meta:set_string("ship_name", "Beacon")
			meta:set_string("infotext", string.format("Navigation Beacon: [Beacon] (Owner: %s)", pname))

			local key = pos_to_key(pos)
			active_beacons[key] = {
				pos = {x = pos.x, y = pos.y, z = pos.z},
				owner = pname,
				name = "Beacon"
			}
			save_beacons()
			minetest.chat_send_player(pname, "Navigation Beacon active: Registered 3D waypoint on HUD.")
		end
	end,

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker or not clicker:is_player() then return itemstack end
		local meta = minetest.get_meta(pos)
		local ship_name = meta:get_string("ship_name")
		if ship_name == "" then ship_name = "Beacon" end
		minetest.show_formspec(clicker:get_player_name(), "jumpdrive_tweaks:beacon_" .. pos_to_key(pos), get_beacon_formspec(ship_name))
		return itemstack
	end,

	on_destruct = function(pos)
		local key = pos_to_key(pos)
		active_beacons[key] = nil
		save_beacons()
	end,
})

-- Handle beacon formspec submission
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("^jumpdrive_tweaks:beacon_") then return false end
	local pos_str = formname:sub(24)
	local p = {}
	for coord in pos_str:gmatch("([^,]+)") do
		table.insert(p, tonumber(coord))
	end
	if #p ~= 3 then return false end
	local pos = {x = p[1], y = p[2], z = p[3]}

	if fields.save and fields.ship_name then
		local new_name = fields.ship_name:sub(1, 24)
		if new_name == "" then new_name = "Beacon" end

		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		meta:set_string("ship_name", new_name)
		meta:set_string("infotext", string.format("Navigation Beacon: [%s] (Owner: %s)", new_name, owner))

		local key = pos_to_key(pos)
		if active_beacons[key] then
			active_beacons[key].name = new_name
			save_beacons()
		end

		minetest.chat_send_player(player:get_player_name(), string.format("Navigation beacon name updated to [%s]", new_name))
		return true
	end
	return false
end)

-- 2. 3D In-World Waypoint HUD Tracking Globalstep
local player_beacon_huds = {} -- playername -> hud_id

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local ppos = player:get_pos()

		if ppos then
			-- Find active beacon for this player (prefer owned, otherwise closest)
			local best_beacon = nil
			local min_dist = math.huge

			for key, bdata in pairs(active_beacons) do
				local dist = vector.distance(ppos, bdata.pos)
				if bdata.owner == pname then
					if dist < min_dist then
						min_dist = dist
						best_beacon = bdata
					end
				elseif not best_beacon and dist < 10000 then
					min_dist = dist
					best_beacon = bdata
				end
			end

			-- Show waypoint whenever valid beacon is tracked
			if best_beacon then
				local waypoint_name = string.format("[Ship: %s]", best_beacon.name or "Vessel")

				if not player_beacon_huds[pname] then
					player_beacon_huds[pname] = player:hud_add({
						hud_elem_type = "waypoint",
						name = waypoint_name,
						text = "m",
						number = 0x00E5FF,
						world_pos = best_beacon.pos
					})
				else
					player:hud_change(player_beacon_huds[pname], "name", waypoint_name)
					player:hud_change(player_beacon_huds[pname], "world_pos", best_beacon.pos)
				end
			else
				if player_beacon_huds[pname] then
					player:hud_remove(player_beacon_huds[pname])
					player_beacon_huds[pname] = nil
				end
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	player_beacon_huds[player:get_player_name()] = nil
end)

-- 3. Quantum Recall Teleport Function
local function execute_quantum_recall(itemstack, user)
	if not user or not user:is_player() then return itemstack end
	local pname = user:get_player_name()
	local imeta = itemstack:get_meta()
	local target_pos_str = imeta:get_string("target_pos")
	local target_name = imeta:get_string("target_name")
	local target_owner = imeta:get_string("target_owner")

	-- Resolve current location of beacon from active_beacons registry
	local target_pos = nil
	if target_name ~= "" and target_owner ~= "" then
		for _, bdata in pairs(active_beacons) do
			if bdata.owner == target_owner and bdata.name == target_name then
				target_pos = bdata.pos
				break
			end
		end
	end

	if not target_pos and target_pos_str and target_pos_str ~= "" then
		target_pos = minetest.string_to_pos(target_pos_str)
	end

	if not target_pos then
		minetest.chat_send_player(pname, "Quantum Tether not tuned! Shift+Right-Click your ship's Transponder Beacon to lock frequency.")
		return itemstack
	end

	local ppos = user:get_pos()
	local dist = vector.distance(ppos, target_pos)

	if dist > 5000 then
		minetest.chat_send_player(pname, string.format("Out of quantum recall range (%dm > 5000m max).", math.floor(dist)))
		return itemstack
	end

	-- Spawn departure particles
	minetest.add_particlespawner({
		amount = 60,
		time = 0.5,
		minpos = vector.subtract(ppos, {x = 0.5, y = 0.5, z = 0.5}),
		maxpos = vector.add(ppos, {x = 0.5, y = 1.5, z = 0.5}),
		minvel = {x = -2, y = -2, z = -2},
		maxvel = {x = 2, y = 2, z = 2},
		texture = "spark.png",
		glow = 10,
	})

	-- Teleport player to destination on top of beacon
	local dest_pos = {x = target_pos.x, y = target_pos.y + 1.2, z = target_pos.z}
	user:set_pos(dest_pos)

	-- Spawn arrival particles
	minetest.add_particlespawner({
		amount = 60,
		time = 0.5,
		minpos = vector.subtract(dest_pos, {x = 0.5, y = 0.5, z = 0.5}),
		maxpos = vector.add(dest_pos, {x = 0.5, y = 1.5, z = 0.5}),
		minvel = {x = -2, y = -2, z = -2},
		maxvel = {x = 2, y = 2, z = 2},
		texture = "spark.png",
		glow = 10,
	})

	minetest.sound_play("telemosaic_arrival", {
		pos = dest_pos,
		gain = 1.0,
		max_hear_distance = 25,
	})

	minetest.chat_send_player(pname, string.format("Quantum Recall successful: Re-anchored to [%s] at (%.0f, %.0f, %.0f).", target_name ~= "" and target_name or "Ship", dest_pos.x, dest_pos.y, dest_pos.z))
	return itemstack
end

-- 4. Register Quantum Recall Tether Tool
minetest.register_tool("jumpdrive_tweaks:quantum_tether", {
	description = S("Quantum Recall Tether\nEmergency Return Beacon\n[Sneak + Right-Click on Beacon]: Tune to Vessel\n[Sneak + Right-Click in Void]: Teleport to Tuned Beacon (Range: 5000m)"),
	inventory_image = "jumpdrive_remote.png^[colorize:#00e5ff:160",
	wield_image = "jumpdrive_remote.png^[colorize:#00e5ff:160",
	stack_max = 1,

	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return itemstack end
		local pname = placer:get_player_name()

		if pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			if node.name == "jumpdrive_tweaks:beacon" then
				local meta = minetest.get_meta(pointed_thing.under)
				local ship_name = meta:get_string("ship_name")
				if ship_name == "" then ship_name = "Vessel" end
				local owner = meta:get_string("owner")

				local imeta = itemstack:get_meta()
				imeta:set_string("target_pos", minetest.pos_to_string(pointed_thing.under))
				imeta:set_string("target_name", ship_name)
				imeta:set_string("target_owner", owner)
				imeta:set_string("description", string.format("Quantum Recall Tether\n[Tuned to: %s @ (%d, %d, %d)]\n[Sneak + Right-Click]: Return to Vessel", ship_name, pointed_thing.under.x, pointed_thing.under.y, pointed_thing.under.z))

				minetest.sound_play("telemosaic_departure", {
					pos = pointed_thing.under,
					gain = 0.8,
					max_hear_distance = 15,
				})

				minetest.chat_send_player(pname, string.format("Quantum Tether frequency locked to ship beacon: [%s]", ship_name))
				return itemstack
			end
		end

		return execute_quantum_recall(itemstack, placer)
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		return execute_quantum_recall(itemstack, user)
	end,
})
