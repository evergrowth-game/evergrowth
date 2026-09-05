-- jumpdrive_tweaks/terrain_filter.lua
-- Prevents planetary terrain (dirt, grass, stone, sand, water) from teleporting with the ship
-- and prevents jumpdrive from carving holes in the landscape under landing sites.

local c_air = minetest.get_content_id("air")
local terrain_cache = {}

local function is_terrain_node(id, nodename)
	if terrain_cache[id] ~= nil then
		return terrain_cache[id]
	end

	if not nodename then
		nodename = minetest.get_name_from_content_id(id)
	end

	if not nodename or nodename == "air" or nodename == "ignore" or nodename == "vacuum:vacuum" then
		terrain_cache[id] = false
		return false
	end

	-- Ship & manufactured components are NEVER treated as terrain
	if nodename:find("^jumpdrive") or nodename:find("^techage") or nodename:find("^spacesuit") or nodename:find("^vacuum") then
		terrain_cache[id] = false
		return false
	end

	local nodedef = minetest.registered_nodes[nodename]
	if not nodedef then
		terrain_cache[id] = false
		return false
	end

	if nodedef.groups and (nodedef.groups.jumpdrive_ship_part or nodedef.groups.techage_node or nodedef.groups.door or nodedef.groups.bed or nodedef.groups.chest or nodedef.groups.vessel or nodedef.groups.wool or nodedef.groups.carpet or nodedef.groups.pane) then
		terrain_cache[id] = false
		return false
	end

	-- Crafted/manufactured construction materials
	if nodename:find("_block$") or nodename:find("glass") or nodename:find("^default:wood") or nodename:find("^default:brick") or nodename:find("^stairs:") or nodename:find("^walls:") or nodename:find("^castle_gates:") or nodename:find("^doors:") or nodename:find("^xdecor:") then
		terrain_cache[id] = false
		return false
	end

	-- Natural ground, rocks, liquids, and wild flora
	if nodedef.is_ground_content then
		terrain_cache[id] = true
		return true
	end

	if nodedef.groups and (nodedef.groups.soil or nodedef.groups.sand or nodedef.groups.tree or nodedef.groups.leaves or nodedef.groups.flora or nodedef.groups.water or nodedef.groups.lava or nodedef.groups.stone) then
		terrain_cache[id] = true
		return true
	end

	if nodename:find("^default:dirt") or nodename:find("^default:stone") or nodename:find("^default:sand") or nodename:find("^default:gravel") or nodename:find("^default:clay") or nodename:find("^default:ice") or nodename:find("^default:snow") or nodename:find("^default:water") or nodename:find("^ethereal:") or nodename:find("^caverealms:") then
		terrain_cache[id] = true
		return true
	end

	terrain_cache[id] = false
	return false
end

-- Override move_mapdata to copy ONLY ship blocks, leaving terrain at source
function jumpdrive.move_mapdata(source_pos1, source_pos2, target_pos1, target_pos2)
	local delta_vector = vector.subtract(target_pos1, source_pos1)

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
		local to_pos = vector.add(from_pos, delta_vector)

		local source_index = source_area:indexp(from_pos)
		local target_index = target_area:indexp(to_pos)

		local id = source_data[source_index]

		-- If this is natural terrain, DO NOT copy it to target
		if is_terrain_node(id) then
			target_data[target_index] = c_air
		else
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

	manip:set_data(target_data)
	manip:set_light_data(target_param1)
	manip:set_param2_data(target_param2)
	manip:write_to_map()
	manip:update_map()

	return movenode_list
end

-- Override clear_area to clear ONLY moved ship blocks, leaving terrain untouched at source
function jumpdrive.clear_area(pos1, pos2)
	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local source_area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local source_data = manip:get_data()

	for z = pos1.z, pos2.z do
	for y = pos1.y, pos2.y do
	for x = pos1.x, pos2.x do
		local source_index = source_area:index(x, y, z)
		local id = source_data[source_index]

		-- Only clear manufactured / ship nodes, KEEP terrain intact
		if not is_terrain_node(id) then
			source_data[source_index] = c_air
		end
	end
	end
	end

	manip:set_data(source_data)
	manip:write_to_map()

	-- Remove metadata only from non-terrain nodes
	local target_meta_pos_list = minetest.find_nodes_with_meta(pos1, pos2)
	for _, target_pos in pairs(target_meta_pos_list) do
		local node = minetest.get_node(target_pos)
		local id = minetest.get_content_id(node.name)
		if not is_terrain_node(id, node.name) then
			local target_meta = minetest.get_meta(target_pos)
			target_meta:from_table(nil)
		end
	end
end

-- Override move_metadata to skip terrain nodes
local orig_move_metadata = jumpdrive.move_metadata
function jumpdrive.move_metadata(source_pos1, source_pos2, delta_vector)
	local target_pos1 = vector.add(source_pos1, delta_vector)
	local target_pos2 = vector.add(source_pos2, delta_vector)

	local target_meta_pos_list = minetest.find_nodes_with_meta(target_pos1, target_pos2)
	for _, target_pos in pairs(target_meta_pos_list) do
		local target_meta = minetest.get_meta(target_pos)
		target_meta:from_table(nil)
	end

	local meta_pos_list = minetest.find_nodes_with_meta(source_pos1, source_pos2)
	for _, source_pos in pairs(meta_pos_list) do
		local node = minetest.get_node(source_pos)
		local id = minetest.get_content_id(node.name)

		if not is_terrain_node(id, node.name) then
			local target_pos = vector.add(source_pos, delta_vector)
			local source_meta = minetest.get_meta(source_pos)
			local source_table = source_meta:to_table()

			minetest.get_meta(target_pos):from_table(source_table)
			jumpdrive.node_compat(node.name, source_pos, target_pos, source_pos1, source_pos2, delta_vector)
			source_meta:from_table(nil)
		end
	end

	jumpdrive.commit_node_compat()
end

minetest.log("action", "[jumpdrive_tweaks] Loaded selective terrain filter for jump execution.")
