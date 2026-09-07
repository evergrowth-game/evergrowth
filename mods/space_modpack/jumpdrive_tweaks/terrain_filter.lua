-- jumpdrive_tweaks/terrain_filter.lua
-- Selective Spatial Filtering: Transports only verified spacecraft components (via backbone proximity mask),
-- leaving background terrain, planetary landscape, and disconnected structures untouched.

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local c_air = minetest.get_content_id("air")

-- Override move_mapdata to copy ONLY verified spacecraft blocks
function jumpdrive.move_mapdata(source_pos1, source_pos2, target_pos1, target_pos2)
	local delta_vector = vector.subtract(target_pos1, source_pos1)
	local mask = jumpdrive_tweaks.active_ship_mask

	-- Read source
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(source_pos1, source_pos2)
	local source_area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local source_data = manip:get_data()
	local source_param1 = manip:get_light_data()
	local source_param2 = manip:get_param2_data()

	-- Read target
	manip = minetest.get_voxel_manip()
	e1, e2 = manip:read_from_map(target_pos1, target_pos2)
	local target_area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local target_data = manip:get_data()
	local target_param1 = manip:get_light_data()
	local target_param2 = manip:get_param2_data()

	local movenode_list = {}
	local c_vacuum = minetest.get_modpath("vacuum") and minetest.get_content_id("vacuum:vacuum")

	for z = source_pos1.z, source_pos2.z do
	for y = source_pos1.y, source_pos2.y do
	for x = source_pos1.x, source_pos2.x do
		local from_pos = vector.new(x, y, z)
		local from_hash = minetest.hash_node_position(from_pos)

		-- Only process if position is part of the active spacecraft mask
		if not mask or mask[from_hash] then
			local to_pos = vector.add(from_pos, delta_vector)
			local source_index = source_area:indexp(from_pos)
			local target_index = target_area:indexp(to_pos)

			local id = source_data[source_index]

			-- Never copy natural terrain or atmospheric air
			if not jumpdrive_tweaks.is_terrain_node(id) then
				if c_vacuum and id == c_vacuum then
					id = c_air
				end

				target_data[target_index] = id

				local nodename = minetest.get_name_from_content_id(id)
				local nodedef = minetest.registered_nodes[nodename]
				if nodedef and type(nodedef.on_movenode) == "function" then
					local edge = vector.zero()
					if source_pos1.x == x then edge.x = -1 end
					if source_pos1.y == y then edge.y = -1 end
					if source_pos1.z == z then edge.z = -1 end
					if source_pos2.x == x then edge.x = 1 end
					if source_pos2.y == y then edge.y = 1 end
					if source_pos2.z == z then edge.z = 1 end

					table.insert(movenode_list, {
						from_pos = from_pos,
						to_pos = to_pos,
						edge = edge,
						nodedef = nodedef
					})
				end

				target_param1[target_index] = source_param1[source_index]
				target_param2[target_index] = source_param2[source_index]
			end
		end
	end
	end
	end

	manip:set_data(target_data)
	manip:set_light_data(target_param1)
	manip:set_param2_data(target_param2)
	manip:write_to_map()
	manip:update_map()

	return movenode_list
end

-- Override clear_area to clear ONLY moved ship blocks, leaving terrain & non-ship structures untouched at source
function jumpdrive.clear_area(pos1, pos2)
	local mask = jumpdrive_tweaks.active_ship_mask
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local source_area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local source_data = manip:get_data()

	for z = pos1.z, pos2.z do
	for y = pos1.y, pos2.y do
	for x = pos1.x, pos2.x do
		local from_pos = vector.new(x, y, z)
		local from_hash = minetest.hash_node_position(from_pos)

		if not mask or mask[from_hash] then
			local source_index = source_area:index(x, y, z)
			local id = source_data[source_index]

			-- Only clear manufactured / ship nodes, KEEP terrain intact
			if not jumpdrive_tweaks.is_terrain_node(id) then
				source_data[source_index] = c_air
			end
		end
	end
	end
	end

	manip:set_data(source_data)
	manip:write_to_map()
	manip:update_map()

	-- Remove metadata only from verified moved ship nodes
	local target_meta_pos_list = minetest.find_nodes_with_meta(pos1, pos2)
	for _, target_pos in pairs(target_meta_pos_list) do
		local thash = minetest.hash_node_position(target_pos)
		if not mask or mask[thash] then
			local node = minetest.get_node(target_pos)
			local id = minetest.get_content_id(node.name)
			if not jumpdrive_tweaks.is_terrain_node(id, node.name) then
				local target_meta = minetest.get_meta(target_pos)
				target_meta:from_table(nil)
			end
		end
	end
end

-- Override move_metadata to only migrate ship metadata without wiping external destination nodes
function jumpdrive.move_metadata(source_pos1, source_pos2, delta_vector)
	local mask = jumpdrive_tweaks.active_ship_mask

	local meta_pos_list = minetest.find_nodes_with_meta(source_pos1, source_pos2)
	local processed_positions = {}
	for _, source_pos in pairs(meta_pos_list) do
		local shash = minetest.hash_node_position(source_pos)
		if not mask or mask[shash] then
			local node = minetest.get_node(source_pos)
			local id = minetest.get_content_id(node.name)

			if not jumpdrive_tweaks.is_terrain_node(id, node.name) then
				local target_pos = vector.add(source_pos, delta_vector)
				local target_meta = minetest.get_meta(target_pos)
				target_meta:from_table(nil)

				local source_meta = minetest.get_meta(source_pos)
				local source_table = source_meta:to_table()

				target_meta:from_table(source_table)
				jumpdrive.node_compat(node.name, source_pos, target_pos, source_pos1, source_pos2, delta_vector)
				source_meta:from_table(nil)

				if jumpdrive_tweaks.migrate_techage_node then
					jumpdrive_tweaks.migrate_techage_node(source_pos, target_pos)
					processed_positions[shash] = true
				end
			end
		end
	end

	-- Ensure NVM migration for any ship nodes without standard NodeMeta
	if jumpdrive_tweaks.migrate_techage_node then
		local nodes = jumpdrive_tweaks.active_ship_nodes
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

-- Override move_nodetimers to only move timers for active ship nodes
function jumpdrive.move_nodetimers(source_pos1, source_pos2, delta_vector)
	local nodes = jumpdrive_tweaks.active_ship_nodes
	if nodes then
		for _, from_pos in ipairs(nodes) do
			local timer = minetest.get_node_timer(from_pos)
			if timer and timer:is_started() then
				local timeout = timer:get_timeout()
				local elapsed = timer:get_elapsed()
				timer:stop()

				local to_pos = vector.add(from_pos, delta_vector)
				local target_timer = minetest.get_node_timer(to_pos)
				if target_timer then
					target_timer:set(timeout, elapsed)
				end
			end
		end
		return
	end

	local mask = jumpdrive_tweaks.active_ship_mask
	for z = source_pos1.z, source_pos2.z do
	for y = source_pos1.y, source_pos2.y do
	for x = source_pos1.x, source_pos2.x do
		local from_pos = vector.new(x, y, z)
		local fhash = minetest.hash_node_position(from_pos)

		if not mask or mask[fhash] then
			local timer = minetest.get_node_timer(from_pos)
			if timer and timer:is_started() then
				local timeout = timer:get_timeout()
				local elapsed = timer:get_elapsed()
				timer:stop()

				local to_pos = vector.add(from_pos, delta_vector)
				local target_timer = minetest.get_node_timer(to_pos)
				if target_timer then
					target_timer:set(timeout, elapsed)
				end
			end
		end
	end
	end
	end
end

minetest.log("action", "[jumpdrive_tweaks] Loaded selective spatial terrain, timer, and backbone filter.")
