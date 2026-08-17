-- walls_tweaks/init.lua

local function swap(pos, node, name, param2)
	if node.name == name and node.param2 == param2 then
		return
	end
	minetest.swap_node(pos, {name = name, param2 = param2})
end

local function update_wall(pos)
	local node = minetest.get_node(pos)
	local name = node.name
	local is_straight = false
	if name:sub(-9) == "_straight" then
		name = name:sub(1, -10)
		is_straight = true
	end

	local def = minetest.registered_nodes[name]
	if not def or not def.groups or def.groups.wall == nil then
		return
	end

	local c = {}
	for dir = 0, 3 do
		local d = minetest.facedir_to_dir(dir)
		local aside = vector.add(pos, d)
		local aside_node = minetest.get_node(aside)
		local connects = false
		
		-- Use connects_to if defined, otherwise default groups
		local aside_def = minetest.registered_nodes[aside_node.name]
		if aside_def and aside_def.groups then
			if aside_def.groups.wall or aside_def.groups.stone or aside_def.groups.fence or aside_def.groups.wall_connected then
				connects = true
			end
		end
		c[dir] = connects
	end

	-- Check top node
	local pos_top = {x = pos.x, y = pos.y + 1, z = pos.z}
	local node_top = minetest.get_node(pos_top)
	local top_requires_post = false
	if node_top.name ~= "air" and node_top.name ~= "ignore" then
		if minetest.get_item_group(node_top.name, "wall") == 0 then
			top_requires_post = true
		end
	end

	local should_be_straight = false
	if not top_requires_post then
		local front_back = c[0] and c[2] and not c[1] and not c[3]
		local left_right = c[1] and c[3] and not c[0] and not c[2]
		if front_back or left_right then
			should_be_straight = true
		end
	end

	local straight_name = name .. "_straight"
	if should_be_straight and minetest.registered_nodes[straight_name] then
		swap(pos, node, straight_name, node.param2)
	else
		swap(pos, node, name, node.param2)
	end
end

local function apply_tweaks(name, def)
	local straight_def = table.copy(def)
	straight_def.description = def.description .. " (Straight)"
	straight_def.drop = name
	
	if straight_def.groups then
		straight_def.groups.not_in_creative_inventory = 1
	end
	
	-- Also fix the base node's collision and texture alignment
	local override_def = {}
	local changed_base = false
	
	local fence_collision_extra = 3/8
	if def.collision_box then
		override_def.collision_box = {
			type = "connected",
			fixed = {-3/16, -1/2, -3/16, 3/16, 1/2 + fence_collision_extra, 3/16},
			connect_front = {-3/16, -1/2, -1/2,  3/16, 1/2 + fence_collision_extra, -3/16},
			connect_left = {-1/2, -1/2, -3/16, -3/16, 1/2 + fence_collision_extra,  3/16},
			connect_back = {-3/16, -1/2,  3/16,  3/16, 1/2 + fence_collision_extra,  1/2},
			connect_right = { 3/16, -1/2, -3/16,  1/2, 1/2 + fence_collision_extra,  3/16},
		}
		changed_base = true
	end
	
	if def.tiles then
		local new_tiles = {}
		for i, t in ipairs(def.tiles) do
			if type(t) == "string" then
				new_tiles[i] = {name = t, align_style = "world"}
				changed_base = true
			elseif type(t) == "table" and t.align_style == nil then
				local nt = table.copy(t)
				nt.align_style = "world"
				new_tiles[i] = nt
				changed_base = true
			else
				new_tiles[i] = t
			end
		end
		if changed_base then
			override_def.tiles = new_tiles
		end
	end
	
	if changed_base then
		minetest.override_item(name, override_def)
	end
	
	if straight_def.node_box then
		straight_def.node_box = {
			type = "connected",
			fixed = {-3/16, -1/2, -3/16, 3/16, 3/8, 3/16},
			connect_front = {-3/16, -1/2, -1/2,  3/16, 3/8, -3/16},
			connect_left = {-1/2, -1/2, -3/16, -3/16, 3/8,  3/16},
			connect_back = {-3/16, -1/2,  3/16,  3/16, 3/8,  1/2},
			connect_right = { 3/16, -1/2, -3/16,  1/2, 3/8,  3/16},
		}
	end
	
	if straight_def.collision_box then
		straight_def.collision_box = {
			type = "connected",
			fixed = {-3/16, -1/2, -3/16, 3/16, 1/2 + fence_collision_extra, 3/16},
			connect_front = {-3/16, -1/2, -1/2,  3/16, 1/2 + fence_collision_extra, -3/16},
			connect_left = {-1/2, -1/2, -3/16, -3/16, 1/2 + fence_collision_extra,  3/16},
			connect_back = {-3/16, -1/2,  3/16,  3/16, 1/2 + fence_collision_extra,  1/2},
			connect_right = { 3/16, -1/2, -3/16,  1/2, 1/2 + fence_collision_extra,  3/16},
		}
	end
	
	local clean_name = name:gsub("^:", "")
	minetest.register_node(":" .. clean_name .. "_straight", straight_def)
end

-- Wrap walls API to automatically tweak future walls
if walls and walls.register then
	local old_register = walls.register
	walls.register = function(wall_name, wall_desc, wall_texture_table, wall_mat, wall_sounds)
		old_register(wall_name, wall_desc, wall_texture_table, wall_mat, wall_sounds)
		local craft_name = wall_name:gsub("^:", "")
		local def = minetest.registered_nodes[craft_name]
		if def then
			apply_tweaks(craft_name, def)
		end
	end
end

-- Tweak all already registered walls
local walls_to_tweak = {}
for name, def in pairs(minetest.registered_nodes) do
	if def.groups and def.groups.wall and not name:match("_straight$") then
		walls_to_tweak[name] = def
	end
end

for name, def in pairs(walls_to_tweak) do
	apply_tweaks(name, def)
end

-- Global placement hooks
minetest.register_on_placenode(function(pos, node)
	local def = minetest.registered_nodes[node.name]
	if def and def.groups and def.groups.wall then
		update_wall(pos)
	end
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
		update_wall(vector.add(pos, dir))
	end
	update_wall({x = pos.x, y = pos.y - 1, z = pos.z})
end)

minetest.register_on_dignode(function(pos, oldnode)
	for i = 0, 3 do
		local dir = minetest.facedir_to_dir(i)
		update_wall(vector.add(pos, dir))
	end
	update_wall({x = pos.x, y = pos.y - 1, z = pos.z})
end)

-- LBM to update existing walls
minetest.register_lbm({
	name = "walls_tweaks:update_walls",
	nodenames = {"group:wall"},
	action = function(pos, node)
		update_wall(pos)
	end
})

-- Enforce tall collision box (1.375 height) for all fences, fence rails, and closed fence gates
minetest.register_on_mods_loaded(function()
	local extra = 3/8
	for name, def in pairs(minetest.registered_nodes) do
		if def.groups and def.groups.fence then
			if def.collision_box and def.collision_box.type == "connected" then
				minetest.override_item(name, {
					collision_box = {
						type = "connected",
						fixed = {-1/8, -1/2, -1/8, 1/8, 1/2 + extra, 1/8},
						connect_front = {-1/8, -1/2, -1/2,  1/8, 1/2 + extra, -1/8},
						connect_left =  {-1/2, -1/2, -1/8, -1/8, 1/2 + extra,  1/8},
						connect_back =  {-1/8, -1/2,  1/8,  1/8, 1/2 + extra,  1/2},
						connect_right = { 1/8, -1/2, -1/8,  1/2, 1/2 + extra,  1/8}
					}
				})
			elseif def.collision_box and def.collision_box.type == "fixed" and name:match("_closed$") then
				minetest.override_item(name, {
					collision_box = {
						type = "fixed",
						fixed = {-1/2, -1/2, -1/8, 1/2, 1/2 + extra, 1/8}
					}
				})
			end
		end
	end
end)

