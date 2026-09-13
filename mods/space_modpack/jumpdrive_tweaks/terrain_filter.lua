-- jumpdrive_tweaks/terrain_filter.lua
-- Selective Spatial Filtering: Transports only verified spacecraft components (via backbone proximity mask),
-- leaving background terrain, planetary landscape, and disconnected structures untouched.
-- Implements snapshot-buffered atomic voxel movement and set-differential clearance for overlapping jumps.

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local c_air = minetest.get_content_id("air")

local function areas_overlap(s1, s2, t1, t2)
	local min_s = {x = math.min(s1.x, s2.x), y = math.min(s1.y, s2.y), z = math.min(s1.z, s2.z)}
	local max_s = {x = math.max(s1.x, s2.x), y = math.max(s1.y, s2.y), z = math.max(s1.z, s2.z)}
	local min_t = {x = math.min(t1.x, t2.x), y = math.min(t1.y, t2.y), z = math.min(t1.z, t2.z)}
	local max_t = {x = math.max(t1.x, t2.x), y = math.max(t1.y, t2.y), z = math.max(t1.z, t2.z)}

	return (min_s.x <= max_t.x and max_s.x >= min_t.x) and
	       (min_s.y <= max_t.y and max_s.y >= min_t.y) and
	       (min_s.z <= max_t.z and max_s.z >= min_t.z)
end

-- Override move_mapdata to copy ONLY verified spacecraft blocks with overlap immunity
function jumpdrive.move_mapdata(source_pos1, source_pos2, target_pos1, target_pos2)
	local delta_vector = vector.subtract(target_pos1, source_pos1)
	local mask = jumpdrive_tweaks.active_ship_mask
	local nodes = jumpdrive_tweaks.active_ship_nodes
	local c_vacuum = minetest.get_modpath("vacuum") and minetest.get_content_id("vacuum:vacuum")
	local movenode_list = {}

	-- Build destination coordinate mask
	local dest_mask = {}
	if nodes then
		for _, p in ipairs(nodes) do
			local dp = vector.add(p, delta_vector)
			dest_mask[minetest.hash_node_position(dp)] = true
		end
	elseif mask then
		for z = source_pos1.z, source_pos2.z do
		for y = source_pos1.y, source_pos2.y do
		for x = source_pos1.x, source_pos2.x do
			local p = vector.new(x, y, z)
			if mask[minetest.hash_node_position(p)] then
				local dp = vector.add(p, delta_vector)
				dest_mask[minetest.hash_node_position(dp)] = true
			end
		end
		end
		end
	end
	jumpdrive_tweaks.active_dest_mask = dest_mask

	local is_overlapping = areas_overlap(source_pos1, source_pos2, target_pos1, target_pos2)

	if is_overlapping then
		-- Unified bounding box spanning both origin and destination
		local u_min = {
			x = math.min(source_pos1.x, source_pos2.x, target_pos1.x, target_pos2.x),
			y = math.min(source_pos1.y, source_pos2.y, target_pos1.y, target_pos2.y),
			z = math.min(source_pos1.z, source_pos2.z, target_pos1.z, target_pos2.z),
		}
		local u_max = {
			x = math.max(source_pos1.x, source_pos2.x, target_pos1.x, target_pos2.x),
			y = math.max(source_pos1.y, source_pos2.y, target_pos1.y, target_pos2.y),
			z = math.max(source_pos1.z, source_pos2.z, target_pos1.z, target_pos2.z),
		}

		local manip = minetest.get_voxel_manip()
		local e1, e2 = manip:read_from_map(u_min, u_max)
		local area = VoxelArea:new({MinEdge = e1, MaxEdge = e2})
		local data = manip:get_data()
		local param1 = manip:get_light_data()
		local param2 = manip:get_param2_data()

		-- Step 1: Snapshot all origin ship nodes in memory
		local snapshot = {}
		local source_positions = {}
		if nodes then
			source_positions = nodes
		else
			for z = source_pos1.z, source_pos2.z do
			for y = source_pos1.y, source_pos2.y do
			for x = source_pos1.x, source_pos2.x do
				local p = vector.new(x, y, z)
				if not mask or mask[minetest.hash_node_position(p)] then
					table.insert(source_positions, p)
				end
			end
			end
			end
		end

		for _, from_pos in ipairs(source_positions) do
			local s_idx = area:indexp(from_pos)
			local id = data[s_idx]
			if not jumpdrive_tweaks.is_terrain_node(id) then
				if c_vacuum and id == c_vacuum then
					id = c_air
				end
				local p1 = param1[s_idx]
				local p2 = param2[s_idx]
				local to_pos = vector.add(from_pos, delta_vector)
				table.insert(snapshot, {
					from_pos = from_pos,
					to_pos = to_pos,
					id = id,
					param1 = p1,
					param2 = p2
				})

				local nodename = minetest.get_name_from_content_id(id)
				local nodedef = minetest.registered_nodes[nodename]
				if nodedef and type(nodedef.on_movenode) == "function" then
					table.insert(movenode_list, {
						from_pos = from_pos,
						to_pos = to_pos,
						edge = vector.zero(),
						nodedef = nodedef
					})
				end
			end
		end

		-- Step 2: Clear trailing origin nodes (S \ D) in the voxel buffer
		for _, entry in ipairs(snapshot) do
			local from_hash = minetest.hash_node_position(entry.from_pos)
			if not dest_mask[from_hash] then
				local s_idx = area:indexp(entry.from_pos)
				data[s_idx] = c_air
				param1[s_idx] = 0
				param2[s_idx] = 0
			end
		end

		-- Step 3: Write snapshotted ship nodes to destination coordinates (D)
		for _, entry in ipairs(snapshot) do
			local t_idx = area:indexp(entry.to_pos)
			data[t_idx] = entry.id
			param1[t_idx] = entry.param1
			param2[t_idx] = entry.param2
		end

		-- Step 4: Atomic commit to map
		manip:set_data(data)
		manip:set_light_data(param1)
		manip:set_param2_data(param2)
		manip:write_to_map()
		manip:update_map()

	else
		-- Distant Jumps (non-overlapping): Use separate source & target VoxelManips
		local manip_src = minetest.get_voxel_manip()
		local se1, se2 = manip_src:read_from_map(source_pos1, source_pos2)
		local source_area = VoxelArea:new({MinEdge = se1, MaxEdge = se2})
		local source_data = manip_src:get_data()
		local source_param1 = manip_src:get_light_data()
		local source_param2 = manip_src:get_param2_data()

		local manip_dst = minetest.get_voxel_manip()
		local te1, te2 = manip_dst:read_from_map(target_pos1, target_pos2)
		local target_area = VoxelArea:new({MinEdge = te1, MaxEdge = te2})
		local target_data = manip_dst:get_data()
		local target_param1 = manip_dst:get_light_data()
		local target_param2 = manip_dst:get_param2_data()

		for z = source_pos1.z, source_pos2.z do
		for y = source_pos1.y, source_pos2.y do
		for x = source_pos1.x, source_pos2.x do
			local from_pos = vector.new(x, y, z)
			local from_hash = minetest.hash_node_position(from_pos)

			if not mask or mask[from_hash] then
				local to_pos = vector.add(from_pos, delta_vector)
				local source_index = source_area:indexp(from_pos)
				local target_index = target_area:indexp(to_pos)

				local id = source_data[source_index]
				if not jumpdrive_tweaks.is_terrain_node(id) then
					if c_vacuum and id == c_vacuum then
						id = c_air
					end

					target_data[target_index] = id
					target_param1[target_index] = source_param1[source_index]
					target_param2[target_index] = source_param2[source_index]

					local nodename = minetest.get_name_from_content_id(id)
					local nodedef = minetest.registered_nodes[nodename]
					if nodedef and type(nodedef.on_movenode) == "function" then
						table.insert(movenode_list, {
							from_pos = from_pos,
							to_pos = to_pos,
							edge = vector.zero(),
							nodedef = nodedef
						})
					end
				end
			end
		end
		end
		end

		manip_dst:set_data(target_data)
		manip_dst:set_light_data(target_param1)
		manip_dst:set_param2_data(target_param2)
		manip_dst:write_to_map()
		manip_dst:update_map()
	end

	return movenode_list
end

-- Override clear_area to clear ONLY moved ship blocks, leaving terrain & non-ship structures untouched at source
-- and preserving destination coordinates during overlapping jumps
function jumpdrive.clear_area(pos1, pos2)
	local mask = jumpdrive_tweaks.active_ship_mask
	local dest_mask = jumpdrive_tweaks.active_dest_mask
	local c_vacuum = minetest.get_modpath("vacuum") and minetest.get_content_id("vacuum:vacuum")

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local source_area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local source_data = manip:get_data()
	local source_param1 = manip:get_light_data()
	local source_param2 = manip:get_param2_data()

	local modified = false

	for z = pos1.z, pos2.z do
	for y = pos1.y, pos2.y do
	for x = pos1.x, pos2.x do
		local from_pos = vector.new(x, y, z)
		local from_hash = minetest.hash_node_position(from_pos)

		-- Clear only if part of original ship AND NOT part of destination ship
		if (not mask or mask[from_hash]) and (not dest_mask or not dest_mask[from_hash]) then
			local source_index = source_area:index(x, y, z)
			local id = source_data[source_index]

			-- Only clear manufactured / ship nodes, KEEP terrain intact
			if not jumpdrive_tweaks.is_terrain_node(id) then
				if source_data[source_index] ~= c_air then
					source_data[source_index] = c_air
					source_param1[source_index] = 0
					source_param2[source_index] = 0
					modified = true
				end
			end
		end
	end
	end
	end

	if modified then
		manip:set_data(source_data)
		manip:set_light_data(source_param1)
		manip:set_param2_data(source_param2)
		manip:write_to_map()
		manip:update_map()
	end

	-- Remove metadata only from verified moved ship nodes that are NOT in destination mask
	local target_meta_pos_list = minetest.find_nodes_with_meta(pos1, pos2)
	for _, target_pos in pairs(target_meta_pos_list) do
		local thash = minetest.hash_node_position(target_pos)
		if (not mask or mask[thash]) and (not dest_mask or not dest_mask[thash]) then
			local node = minetest.get_node(target_pos)
			local id = minetest.get_content_id(node.name)
			if not jumpdrive_tweaks.is_terrain_node(id, node.name) then
				local target_meta = minetest.get_meta(target_pos)
				target_meta:from_table(nil)
			end
		end
	end
end

-- Override move_metadata to only migrate ship metadata without wiping overlapping destination nodes
function jumpdrive.move_metadata(source_pos1, source_pos2, delta_vector)
	local mask = jumpdrive_tweaks.active_ship_mask
	local dest_mask = jumpdrive_tweaks.active_dest_mask
	local nodes = jumpdrive_tweaks.active_ship_nodes

	-- 1. Snapshot all source node metadata and positions before modifying anything
	local meta_pos_list = minetest.find_nodes_with_meta(source_pos1, source_pos2)
	local meta_snapshots = {}

	for _, source_pos in pairs(meta_pos_list) do
		local shash = minetest.hash_node_position(source_pos)
		if not mask or mask[shash] then
			local node = minetest.get_node(source_pos)
			local id = minetest.get_content_id(node.name)

			if not jumpdrive_tweaks.is_terrain_node(id, node.name) then
				local source_meta = minetest.get_meta(source_pos)
				local source_table = source_meta:to_table()
				local target_pos = vector.add(source_pos, delta_vector)

				table.insert(meta_snapshots, {
					source_pos = source_pos,
					target_pos = target_pos,
					nodename = node.name,
					shash = shash,
					meta_table = source_table,
				})
			end
		end
	end

	-- 2. Clear origin metadata strictly for positions not in destination
	for _, entry in ipairs(meta_snapshots) do
		if not dest_mask or not dest_mask[entry.shash] then
			local smeta = minetest.get_meta(entry.source_pos)
			smeta:from_table(nil)
		end
	end

	-- 3. Write metadata and execute node_compat on destination positions
	local processed_positions = {}
	for _, entry in ipairs(meta_snapshots) do
		local target_meta = minetest.get_meta(entry.target_pos)
		target_meta:from_table(entry.meta_table)
		jumpdrive.node_compat(entry.nodename, entry.source_pos, entry.target_pos, source_pos1, source_pos2, delta_vector)

		if jumpdrive_tweaks.migrate_techage_node then
			jumpdrive_tweaks.migrate_techage_node(entry.source_pos, entry.target_pos)
			processed_positions[entry.shash] = true
		end
	end

	-- 4. Ensure TechAge NVM migration for any ship nodes without standard NodeMeta
	if jumpdrive_tweaks.migrate_techage_node then
		if nodes then
			for _, from_pos in ipairs(nodes) do
				local fhash = minetest.hash_node_position(from_pos)
				if not processed_positions[fhash] then
					local target_pos = vector.add(from_pos, delta_vector)
					jumpdrive_tweaks.migrate_techage_node(from_pos, target_pos)
				end
			end
		elseif mask then
			for z = source_pos1.z, source_pos2.z do
			for y = source_pos1.y, source_pos2.y do
			for x = source_pos1.x, source_pos2.x do
				local from_pos = vector.new(x, y, z)
				local fhash = minetest.hash_node_position(from_pos)
				if mask[fhash] and not processed_positions[fhash] then
					local target_pos = vector.add(from_pos, delta_vector)
					jumpdrive_tweaks.migrate_techage_node(from_pos, target_pos)
				end
			end
			end
			end
		end
	end

	jumpdrive.commit_node_compat()
end

-- Override move_nodetimers to only move timers for active ship nodes with snapshot buffering
function jumpdrive.move_nodetimers(source_pos1, source_pos2, delta_vector)
	local nodes = jumpdrive_tweaks.active_ship_nodes
	local mask = jumpdrive_tweaks.active_ship_mask

	local timer_snapshots = {}

	local source_positions = {}
	if nodes then
		source_positions = nodes
	elseif mask then
		for z = source_pos1.z, source_pos2.z do
		for y = source_pos1.y, source_pos2.y do
		for x = source_pos1.x, source_pos2.x do
			local from_pos = vector.new(x, y, z)
			if mask[minetest.hash_node_position(from_pos)] then
				table.insert(source_positions, from_pos)
			end
		end
		end
		end
	end

	-- 1. Snapshot and stop running timers
	for _, from_pos in ipairs(source_positions) do
		local timer = minetest.get_node_timer(from_pos)
		if timer and timer:is_started() then
			local timeout = timer:get_timeout()
			local elapsed = timer:get_elapsed()
			timer:stop()
			local to_pos = vector.add(from_pos, delta_vector)
			table.insert(timer_snapshots, {
				to_pos = to_pos,
				timeout = timeout,
				elapsed = elapsed,
			})
		end
	end

	-- 2. Start timers at destination coordinates
	for _, entry in ipairs(timer_snapshots) do
		local target_timer = minetest.get_node_timer(entry.to_pos)
		if target_timer then
			target_timer:set(entry.timeout, entry.elapsed)
		end
	end
end

-- Override move_players to stabilize passenger physics and prevent micro-fall / floor clipping
function jumpdrive.move_players(source_pos1, source_pos2, delta_vector)
	local use_player_monoids = (minetest.global_exists and minetest.global_exists("player_monoids")) or (rawget(_G, "player_monoids") ~= nil)
	local mask = jumpdrive_tweaks.active_ship_mask

	for _, player in ipairs(minetest.get_connected_players()) do
		local playerPos = player:get_pos()
		local player_name = player:get_player_name()

		local in_bounds = false
		if playerPos then
			local xMatch = playerPos.x >= (source_pos1.x - 0.5) and playerPos.x <= (source_pos2.x + 0.5)
			local yMatch = playerPos.y >= (source_pos1.y - 0.5) and playerPos.y <= (source_pos2.y + 0.5)
			local zMatch = playerPos.z >= (source_pos1.z - 0.5) and playerPos.z <= (source_pos2.z + 0.5)

			if xMatch and yMatch and zMatch then
				in_bounds = true
			elseif mask then
				local foot_pos = vector.round({x = playerPos.x, y = playerPos.y - 0.1, z = playerPos.z})
				if mask[minetest.hash_node_position(foot_pos)] then
					in_bounds = true
				end
			end
		end

		if in_bounds and player:is_player() then
			minetest.log("action", "[jumpdrive_tweaks] moving passenger with physics anchor: " .. player_name)

			-- 1. Zero out any existing momentum (e.g. falling or running)
			if player.set_velocity then
				player:set_velocity({x = 0, y = 0, z = 0})
			end

			-- 2. Freeze gravity to 0 to prevent client predictive micro-falling before node collision meshes load
			if use_player_monoids and player_monoids.gravity then
				player_monoids.gravity:add_change(player, 0, "jumpdrive:gravity")
			elseif player.set_physics_override then
				player:set_physics_override({gravity = 0})
			end

			-- 3. Teleport passenger
			local new_player_pos = vector.add(playerPos, delta_vector)
			player:set_pos(new_player_pos)

			-- 4. Re-zero velocity at destination to eliminate residual prediction drift
			if player.set_velocity then
				player:set_velocity({x = 0, y = 0, z = 0})
			end

			-- 5. Send mapblocks
			if player.send_mapblock and type(player.send_mapblock) == "function" and jumpdrive.get_mapblock_from_pos then
				player:send_mapblock(jumpdrive.get_mapblock_from_pos(playerPos))
				player:send_mapblock(jumpdrive.get_mapblock_from_pos(new_player_pos))
			end

			-- 6. Restore normal gravity after 0.5s once client meshes have stabilized
			if minetest.after then
				minetest.after(0.5, function()
					local p = minetest.get_player_by_name(player_name)
					if p and p:is_player() then
						if use_player_monoids and player_monoids.gravity then
							player_monoids.gravity:del_change(p, "jumpdrive:gravity")
						elseif p.set_physics_override then
							p:set_physics_override({gravity = 1})
						end
					end
				end)
			end
		end
	end
end

minetest.log("action", "[jumpdrive_tweaks] Loaded selective spatial terrain, timer, player physics, and backbone filter with atomic overlap support.")
