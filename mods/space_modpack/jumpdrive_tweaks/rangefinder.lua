-- jumpdrive_tweaks/rangefinder.lua
-- Optical Rangefinder for diegetic line-of-sight standoff targeting

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local MAX_SCAN_DISTANCE = 1500
local DEFAULT_MARGIN = 20
local MARGIN_CYCLE = { [20] = 50, [50] = 100, [100] = 20 }

-- Helper: Find nearest jump engine within 15 blocks of player
function jumpdrive_tweaks.find_nearby_engine(pos)
	if not pos then return nil end
	local minp = vector.subtract(pos, 15)
	local maxp = vector.add(pos, 15)
	local engines = minetest.find_nodes_in_area(minp, maxp, {"jumpdrive:engine"})
	if engines and #engines > 0 then
		return engines[1]
	end
	return nil
end

-- Helper: Update item description with current link and margin status
local function update_tool_description(meta, engine_pos, margin)
	margin = margin or DEFAULT_MARGIN
	local link_str = engine_pos and minetest.pos_to_string(engine_pos) or "Unlinked"
	meta:set_string("description", string.format("Optical Rangefinder\n[Ship Engine: %s | Standoff Margin: %dm]\nRight-click Engine: Link | Right-click Space: Target Lock | Sneak+Right-click: Cycle Margin", link_str, margin))
end

-- Link rangefinder to engine node
function jumpdrive_tweaks.link_rangefinder(itemstack, user, engine_pos)
	if not itemstack or not user or not engine_pos then return itemstack end
	local meta = itemstack:get_meta()
	meta:set_string("engine_pos", minetest.pos_to_string(engine_pos))
	local margin = meta:get_int("standoff_margin")
	if margin <= 0 then margin = DEFAULT_MARGIN end
	meta:set_int("standoff_margin", margin)
	update_tool_description(meta, engine_pos, margin)

	if user:is_player() then
		minetest.chat_send_player(user:get_player_name(), string.format("Optical Rangefinder linked to Jump Engine at %s (Standoff Margin: %dm)", minetest.pos_to_string(engine_pos), margin))
	end
	return itemstack
end

-- Core Rangefinder Action Handler
local function handle_rangefinder(itemstack, user, pointed_thing)
	if not user or not user:is_player() then return itemstack end
	local playername = user:get_player_name()
	local meta = itemstack:get_meta()

	-- Check if pointed directly at an engine block or bridge console to link
	if pointed_thing and pointed_thing.type == "node" and pointed_thing.under then
		local node = minetest.get_node(pointed_thing.under)
		if node.name == "jumpdrive:engine" then
			return jumpdrive_tweaks.link_rangefinder(itemstack, user, pointed_thing.under)
		elseif node.name == "jumpdrive_tweaks:bridge_console" then
			local engine_pos, err = jumpdrive_tweaks.find_connected_engine(pointed_thing.under)
			if engine_pos then
				return jumpdrive_tweaks.link_rangefinder(itemstack, user, engine_pos)
			else
				minetest.chat_send_player(playername, "[Bridge Console] Cannot link Rangefinder: " .. (err or "No Jump Core connected."))
				return itemstack
			end
		end
	end

	-- Current margin
	local margin = meta:get_int("standoff_margin")
	if margin <= 0 then margin = DEFAULT_MARGIN end

	-- Handle Sneak + Right-Click: Cycle Standoff Margin
	local controls = user:get_player_control()
	if controls and controls.sneak then
		local next_margin = MARGIN_CYCLE[margin] or 20
		meta:set_int("standoff_margin", next_margin)
		local engine_pos_str = meta:get_string("engine_pos")
		local engine_pos = (engine_pos_str ~= "") and minetest.string_to_pos(engine_pos_str) or nil
		update_tool_description(meta, engine_pos, next_margin)
		minetest.chat_send_player(playername, string.format("Rangefinder standoff margin set to %dm", next_margin))
		return itemstack
	end

	-- Retrieve linked engine position
	local engine_pos_str = meta:get_string("engine_pos")
	local engine_pos = (engine_pos_str ~= "") and minetest.string_to_pos(engine_pos_str) or nil

	if not engine_pos then
		engine_pos = jumpdrive_tweaks.find_nearby_engine(user:get_pos())
		if engine_pos then
			meta:set_string("engine_pos", minetest.pos_to_string(engine_pos))
			update_tool_description(meta, engine_pos, margin)
			minetest.chat_send_player(playername, string.format("Auto-linked Rangefinder to nearby Jump Engine at %s", minetest.pos_to_string(engine_pos)))
		else
			minetest.chat_send_player(playername, "Rangefinder unlinked. Right-click your ship's Jump Engine first to link.")
			return itemstack
		end
	end

	-- Verify engine node exists with post-jump rediscovery fallback
	local engine_node = minetest.get_node_or_nil(engine_pos)
	if not engine_node or engine_node.name ~= "jumpdrive:engine" then
		local nearby = jumpdrive_tweaks.find_nearby_engine(user:get_pos())
		if nearby then
			engine_pos = nearby
			meta:set_string("engine_pos", minetest.pos_to_string(engine_pos))
			update_tool_description(meta, engine_pos, margin)
		else
			minetest.chat_send_player(playername, "Linked Jump Engine not found. Right-click a valid Jump Engine to re-link.")
			meta:set_string("engine_pos", "")
			update_tool_description(meta, nil, margin)
			return itemstack
		end
	end

	-- Scan spacecraft hull bounds
	local ship_scan = jumpdrive_tweaks.scan_spacecraft(engine_pos)
	local ship_mask = ship_scan.mask or {}
	local effective_radius = ship_scan.effective_radius or 5

	-- Raycast from eye position
	local eye_height = 1.625
	local props = user:get_properties()
	if props and props.eye_height then
		eye_height = props.eye_height
	end

	local user_pos = user:get_pos()
	local eye_pos = {x = user_pos.x, y = user_pos.y + eye_height, z = user_pos.z}
	local look_dir = user:get_look_dir()
	local end_pos = vector.add(eye_pos, vector.multiply(look_dir, MAX_SCAN_DISTANCE))

	local ray = minetest.raycast(eye_pos, end_pos, false, false)
	local hit_target = nil

	for pointed in ray do
		if pointed.type == "node" and pointed.under then
			local npos = pointed.under
			local nhash = minetest.hash_node_position(npos)

			-- Ignore self ship nodes
			if not ship_mask[nhash] then
				local n = minetest.get_node_or_nil(npos)
				if n and n.name ~= "air" and n.name ~= "vacuum:vacuum" and n.name ~= "vacuum:air_bottle" and n.name ~= "asteroid:atmos" and n.name ~= "ignore" then
					local def = minetest.registered_nodes[n.name]
					if def and not def.buildable_to then
						hit_target = {
							pos = pointed.intersection_point or npos,
							normal = pointed.intersection_normal or {x = 0, y = 0, z = 0},
							node_name = n.name,
							node_pos = npos
						}
						break
					end
				end
			end
		end
	end

	if not hit_target then
		minetest.chat_send_player(playername, string.format("Rangefinder: Clear line of sight (no obstruction within %dm).", MAX_SCAN_DISTANCE))
		return itemstack
	end

	local hit_pos = hit_target.pos
	local dist = vector.distance(eye_pos, hit_pos)
	local standoff_distance = effective_radius + margin

	if dist <= standoff_distance then
		minetest.chat_send_player(playername, string.format("Rangefinder: Vessel already within standoff threshold (%dm <= %dm margin).", math.floor(dist), standoff_distance))
		return itemstack
	end

	local delta_dist = dist - standoff_distance

	-- Compute standoff arrival position by displacing engine_pos along raycast vector
	local arrival_pos = {
		x = jumpdrive.sanitize_coord(math.floor(engine_pos.x + (look_dir.x * delta_dist) + 0.5)),
		y = jumpdrive.sanitize_coord(math.floor(engine_pos.y + (look_dir.y * delta_dist) + 0.5)),
		z = jumpdrive.sanitize_coord(math.floor(engine_pos.z + (look_dir.z * delta_dist) + 0.5)),
	}

	-- Program destination coordinates into linked engine
	local engine_meta = minetest.get_meta(engine_pos)
	engine_meta:set_int("x", arrival_pos.x)
	engine_meta:set_int("y", arrival_pos.y)
	engine_meta:set_int("z", arrival_pos.z)
	jumpdrive.update_infotext(engine_meta, engine_pos)
	jumpdrive.update_formspec(engine_meta, engine_pos)

	-- Output single-line confirmation
	local target_label = hit_target.node_name:gsub("^[^:]+:", ""):gsub("_", " ")
	minetest.chat_send_player(playername, string.format("Target Lock: %s @ %dm | Waypoint: (%d, %d, %d) [Standoff: %dm]",
		target_label, math.floor(dist), arrival_pos.x, arrival_pos.y, arrival_pos.z, margin))

	return itemstack
end

-- Register Optical Rangefinder Tool
minetest.register_tool("jumpdrive_tweaks:rangefinder", {
	description = "Optical Rangefinder\n[Right-click Engine: Link | Right-click Space: Target Lock | Sneak+Right-click: Cycle Margin]",
	short_description = "Optical Rangefinder",
	inventory_image = "jumpdrive_rangefinder.png",
	wield_image = "jumpdrive_rangefinder.png^[transformFX",
	stack_max = 1,
	groups = {tool = 1},

	on_place = function(itemstack, placer, pointed_thing)
		return handle_rangefinder(itemstack, placer, pointed_thing)
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		return handle_rangefinder(itemstack, user, pointed_thing)
	end,
})

