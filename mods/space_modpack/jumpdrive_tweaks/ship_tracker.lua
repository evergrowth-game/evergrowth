-- jumpdrive_tweaks/ship_tracker.lua
-- Dynamic Backbone-Proximity Spacecraft Discovery and Spatial Geometry Resolution

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local c_ignore = minetest.get_content_id("ignore")
local terrain_cache = {}
local buildable_to_cache = {}

-- 1. Planetary & Natural Terrain Classification
function jumpdrive_tweaks.is_terrain_node(id, nodename)
	if id and terrain_cache[id] ~= nil then
		return terrain_cache[id]
	end

	if not nodename and id then
		nodename = minetest.get_name_from_content_id(id)
	end

	if not nodename or nodename == "air" or nodename == "ignore" or nodename == "vacuum:vacuum" or nodename == "asteroid:atmos" then
		if id then terrain_cache[id] = false end
		return false
	end

	-- Ship, industrial, and space mod items are never terrain
	if nodename:find("^jumpdrive") or nodename:find("^techage") or nodename:find("^spacesuit") or nodename:find("^vacuum") then
		if id then terrain_cache[id] = false end
		return false
	end

	-- Space & planetary natural terrain (asteroids, Mars, space crystals)
	if nodename:find("^asteroid:") or nodename:find("^mars:") or nodename:find("^crystals:") then
		if id then terrain_cache[id] = true end
		return true
	end

	local nodedef = minetest.registered_nodes[nodename]
	if not nodedef then
		if id then terrain_cache[id] = false end
		return false
	end

	if nodedef.groups and (nodedef.groups.jumpdrive_ship_part or nodedef.groups.techage_node or nodedef.groups.wood
		or nodedef.groups.door or nodedef.groups.bed or nodedef.groups.chest or nodedef.groups.vessel
		or nodedef.groups.wool or nodedef.groups.carpet or nodedef.groups.pane) then
		if id then terrain_cache[id] = false end
		return false
	end

	-- Crafted construction materials & masonry (MUST be checked before is_ground_content/groups.stone)
	if nodename:find("_block$") or nodename:find("glass") or nodename:find("brick")
		or nodename == "default:cobble" or nodename == "default:mossycobble" or nodename:find("^stairs:")
		or nodename:find("^default:wood") or nodename:find("^walls:")
		or nodename:find("^castle_gates:") or nodename:find("^doors:") or nodename:find("^xdecor:")
		or nodename:find("^basic_materials:") or nodename:find("^building_blocks:") or nodename:find("_wood$")
		or nodename:find("_plank$") or nodename:find("_floor$") then
		if id then terrain_cache[id] = false end
		return false
	end

	-- Natural rocks, liquids, soil, and wild flora
	if nodedef.is_ground_content then
		if id then terrain_cache[id] = true end
		return true
	end

	if nodedef.groups and (nodedef.groups.soil or nodedef.groups.sand or nodedef.groups.tree or nodedef.groups.leaves or nodedef.groups.flora or nodedef.groups.water or nodedef.groups.lava or nodedef.groups.stone) then
		if id then terrain_cache[id] = true end
		return true
	end

	if nodename:find("^default:dirt") or nodename:find("^default:stone") or nodename:find("^default:sand")
		or nodename:find("^default:gravel") or nodename:find("^default:clay") or nodename:find("^default:ice")
		or nodename:find("^default:snow") or nodename:find("^default:water") or nodename:find("^default:lava")
		or nodename:find("^default:tree") or nodename:find("^default:leaves") or nodename:find("^default:apple")
		or nodename:find("^default:grass") or nodename:find("^default:fern") or nodename:find("^ethereal:")
		or nodename:find("^caverealms:") or nodename:find("^flowers:") or nodename:find("^ferns:")
		or nodename:find("^cavestuff:") or nodename:find("^bakedclay:") then
		if id then terrain_cache[id] = true end
		return true
	end

	if id then terrain_cache[id] = false end
	return false
end

-- 2. Buildable_To node check for collision detection
local function is_buildable_to(id, nodename)
	if id and buildable_to_cache[id] ~= nil then
		return buildable_to_cache[id]
	end
	if not nodename and id then
		nodename = minetest.get_name_from_content_id(id)
	end
	if not nodename or nodename == "air" or nodename == "vacuum:vacuum" or nodename == "asteroid:atmos" then
		if id then buildable_to_cache[id] = true end
		return true
	end
	local nodedef = minetest.registered_nodes[nodename]
	local result = (nodedef and nodedef.buildable_to) and true or false
	if id then buildable_to_cache[id] = result end
	return result
end

-- 3. Backbone-Anchored Contiguous Component Traversal & Ship Spatial Mask
function jumpdrive_tweaks.scan_spacecraft(engine_pos, capture_radius)
	capture_radius = capture_radius or 3

	local visited_backbone = {}
	local backbone_nodes = {}
	local queue = {}

	local engine_hash = minetest.hash_node_position(engine_pos)
	visited_backbone[engine_hash] = true
	table.insert(backbone_nodes, engine_pos)
	table.insert(queue, engine_pos)

	-- 1. BFS: Find all connected jumpdrive:backbone / engine / fuel_port nodes (26-connectivity)
	local qi = 1
	while qi <= #queue do
		local curr = queue[qi]
		qi = qi + 1

		for dz = -1, 1 do
		for dy = -1, 1 do
		for dx = -1, 1 do
			if dx ~= 0 or dy ~= 0 or dz ~= 0 then
				local npos = {x = curr.x + dx, y = curr.y + dy, z = curr.z + dz}
				local nhash = minetest.hash_node_position(npos)

				if not visited_backbone[nhash] then
					local node = minetest.get_node_or_nil(npos)
					if node and (node.name == "jumpdrive:backbone" or node.name == "jumpdrive:engine" or node.name == "jumpdrive_tweaks:fuel_port") then
						visited_backbone[nhash] = true
						table.insert(backbone_nodes, npos)
						table.insert(queue, npos)
					end
				end
			end
		end
		end
		end
	end

	-- 2. Precompute spatial lookup for backbone proximity envelope
	local backbone_radius_lookup = {}
	for _, bpos in ipairs(backbone_nodes) do
		for dz = -capture_radius, capture_radius do
		for dy = -capture_radius, capture_radius do
		for dx = -capture_radius, capture_radius do
			local cpos = {x = bpos.x + dx, y = bpos.y + dy, z = bpos.z + dz}
			local chash = minetest.hash_node_position(cpos)
			backbone_radius_lookup[chash] = true
		end
		end
		end
	end

	-- 3. Contiguous Component Flood-Fill: Traverse physically attached solid ship blocks starting from backbone
	local ship_mask = {}
	local ship_node_list = {}
	local fuel_tanks = {}
	local min_pos = {x = engine_pos.x, y = engine_pos.y, z = engine_pos.z}
	local max_pos = {x = engine_pos.x, y = engine_pos.y, z = engine_pos.z}
	local solid_count = 0

	local fill_queue = {}
	for _, bpos in ipairs(backbone_nodes) do
		local bhash = minetest.hash_node_position(bpos)
		ship_mask[bhash] = true
		table.insert(ship_node_list, bpos)
		solid_count = solid_count + 1
		table.insert(fill_queue, bpos)

		if bpos.x < min_pos.x then min_pos.x = bpos.x end
		if bpos.y < min_pos.y then min_pos.y = bpos.y end
		if bpos.z < min_pos.z then min_pos.z = bpos.z end
		if bpos.x > max_pos.x then max_pos.x = bpos.x end
		if bpos.y > max_pos.y then max_pos.y = bpos.y end
		if bpos.z > max_pos.z then max_pos.z = bpos.z end
	end

	local fi = 1
	while fi <= #fill_queue do
		local curr = fill_queue[fi]
		fi = fi + 1

		for dz = -1, 1 do
		for dy = -1, 1 do
		for dx = -1, 1 do
			if dx ~= 0 or dy ~= 0 or dz ~= 0 then
				local npos = {x = curr.x + dx, y = curr.y + dy, z = curr.z + dz}
				local nhash = minetest.hash_node_position(npos)

				if not ship_mask[nhash] then
					if backbone_radius_lookup[nhash] then
						local node = minetest.get_node_or_nil(npos)
						if node and node.name ~= "air" and node.name ~= "ignore" and node.name ~= "vacuum:vacuum" and node.name ~= "asteroid:atmos" then
							local id = minetest.get_content_id(node.name)
							if not jumpdrive_tweaks.is_terrain_node(id, node.name) then
								ship_mask[nhash] = true
								table.insert(ship_node_list, npos)
								solid_count = solid_count + 1
								table.insert(fill_queue, npos)

								if node.name == "jumpdrive_tweaks:fuel_tank" then
									table.insert(fuel_tanks, npos)
								end

								if npos.x < min_pos.x then min_pos.x = npos.x end
								if npos.y < min_pos.y then min_pos.y = npos.y end
								if npos.z < min_pos.z then min_pos.z = npos.z end
								if npos.x > max_pos.x then max_pos.x = npos.x end
								if npos.y > max_pos.y then max_pos.y = npos.y end
								if npos.z > max_pos.z then max_pos.z = npos.z end
							end
						end
					end
				end
			end
		end
		end
		end
	end

	-- Always include engine block
	if not ship_mask[engine_hash] then
		ship_mask[engine_hash] = true
		table.insert(ship_node_list, engine_pos)
		solid_count = solid_count + 1
	end

	-- Dimensions
	local size_x = max_pos.x - min_pos.x + 1
	local size_y = max_pos.y - min_pos.y + 1
	local size_z = max_pos.z - min_pos.z + 1

	-- Mass-effective radius for jump energy scaling:
	-- Scales as cube-root of solid node count
	local effective_radius = math.max(1, math.min(math.ceil(math.pow(solid_count, 1/3) * 1.2), 25))

	return {
		engine_pos = engine_pos,
		mask = ship_mask,
		nodes = ship_node_list,
		fuel_tanks = fuel_tanks,
		node_count = solid_count,
		backbone_count = #backbone_nodes,
		min_pos = min_pos,
		max_pos = max_pos,
		size = {x = size_x, y = size_y, z = size_z},
		effective_radius = effective_radius,
	}
end

-- 4. Calculate jump power requirement based on effective spacecraft mass
function jumpdrive_tweaks.calculate_ship_power(ship_scan, distance)
	local r = ship_scan and ship_scan.effective_radius or 5
	return 10 * distance * r
end

-- 5. Selective Destination Emptiness Check
function jumpdrive_tweaks.is_ship_target_empty(ship_scan, delta_vector)
	local target_min = vector.add(ship_scan.min_pos, delta_vector)
	local target_max = vector.add(ship_scan.max_pos, delta_vector)

	local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(target_min, target_max)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = manip:get_data()

	for _, spos in ipairs(ship_scan.nodes) do
		local tpos = vector.add(spos, delta_vector)
		local thash = minetest.hash_node_position(tpos)

		-- Only check collision against voxels outside the ship's own origin mask
		-- (voxels within ship_scan.mask will be vacated when the ship jumps)
		if not ship_scan.mask[thash] then
			local idx = area:indexp(tpos)
			local id = data[idx]

			if not id or id == c_ignore then
				return false, "uncharted"
			end

			if not is_buildable_to(id) then
				return false, "occupied"
			end
		end
	end

	return true
end

-- 6. Selective Target Area Protection Check
function jumpdrive_tweaks.is_ship_target_protected(ship_scan, delta_vector, playername)
	for _, spos in ipairs(ship_scan.nodes) do
		local tpos = vector.add(spos, delta_vector)
		if minetest.is_protected(tpos, playername) then
			return true
		end
	end
	return false
end

minetest.log("action", "[jumpdrive_tweaks] Loaded backbone-proximity spacecraft tracker and geometry engine.")
