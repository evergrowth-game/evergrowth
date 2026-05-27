--[[

	TechAge
	=======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	TA3/TA4 Power line for electrical landline
	
	[CUSTOM PATCH]
	Auto-Stringing Feature added.
	Original file backed up at: power_line.lua.bak
]]--

-- for lazy programmers
local P = minetest.string_to_pos
local M = minetest.get_meta
local S = techage.S

local Cable = techage.ElectricCable
local power = networks.power

-- [CUSTOM PATCH]
-- Helper: 6-connected 3D Bresenham-like line for Auto-Stringing
-- Ensures valid path for tubelib connection rules
local function get_line_6_connected(pos1, pos2)
	local points = {}
	local x1, y1, z1 = pos1.x, pos1.y, pos1.z
	local x2, y2, z2 = pos2.x, pos2.y, pos2.z
	local sx = (x1 < x2) and 1 or -1
	local sy = (y1 < y2) and 1 or -1
	local sz = (z1 < z2) and 1 or -1

	local p = {x=x1, y=y1, z=z1}
	table.insert(points, {x=x1, y=y1, z=z1})
	
	-- Max height plateau we want to reach/maintain
	local y_plateau = math.max(y1, y2)
	
	while p.x ~= x2 or p.y ~= y2 or p.z ~= z2 do
		local dist_x = math.abs(x2 - p.x)
		local dist_y = math.abs(y2 - p.y)
		local dist_z = math.abs(z2 - p.z)
		local h_dist = dist_x + dist_z
		
		local move_x = false
		local move_y = false
		local move_z = false
		
		-- Step 1: Always take one horizontal step from start if possible
		if #points == 1 and h_dist > 0 then
			if dist_x >= dist_z then move_x = true else move_z = true end
		
		-- Step 2: If we are close to end (h_dist == 1), we MUST resolve vertical now
		-- to ensure we enter the target pole from the side.
		elseif h_dist == 1 and dist_y > 0 then
			move_y = true
			
		-- Step 3: Maintain Altitude (Plateau)
		-- If we are below the plateau, go UP.
		elseif p.y < y_plateau and dist_y > 0 then
			move_y = true
			
		-- Step 4: Standard Horizontal traversal
		elseif h_dist > 0 then
			if dist_x >= dist_z then move_x = true else move_z = true end
			
		-- Step 5: If only vertical left (should only happen if h_dist was 0 initially)
		else
			move_y = true
		end
		
		if move_x then
			p.x = p.x + sx
		elseif move_y then
			p.y = p.y + sy
		else
			p.z = p.z + sz
		end
		table.insert(points, {x=p.x, y=p.y, z=p.z})
	end
	return points
end

-- [CUSTOM PATCH]
-- Main Auto-Stringing Handler
-- Implements:
-- 1. Two-Pass Placement (Place then Update) to fix disjointed cables
-- 2. Forced straightness for collinear lines ("Anchor Fix")
-- 3. Collision and Protection checks
local function on_rightclick_conn(pos, node, clicker, itemstack, pointed_thing)
	if not clicker or not clicker:is_player() then return end
	local name = clicker:get_player_name()
	local held = itemstack:get_name()
	
	if held ~= "techage:power_lineS" then
		return
	end
	
	local meta = clicker:get_meta()
	local start_str = meta:get_string("ta_cable_start")
	
	if start_str == "" then
		meta:set_string("ta_cable_start", minetest.pos_to_string(pos))
		minetest.chat_send_player(name, S("Cable stringing started. Click next pole within 16 blocks."))
		return itemstack
	end
	
	local start_pos = minetest.string_to_pos(start_str)
	if not start_pos then
		meta:set_string("ta_cable_start", "") -- clear invalid
		return itemstack
	end
	
	local dist = vector.distance(start_pos, pos)
	if dist < 1 then
		meta:set_string("ta_cable_start", "")
		minetest.chat_send_player(name, S("Cancelled."))
		return itemstack
	end
	
	if dist > 16 then
		meta:set_string("ta_cable_start", "")
		minetest.chat_send_player(name, S("Too far! Max 16 blocks."))
		return itemstack
	end
    
    -- Calculate path excluding start/end (the poles themselves)
	local path = get_line_6_connected(start_pos, pos)
	local to_place = {}
	
	for _, p in ipairs(path) do
		-- Skip start and end positions
		if not vector.equals(p, start_pos) and not vector.equals(p, pos) then
			local n = minetest.get_node(p)
			if n.name == "air" or n.name == "techage:power_lineS" then
				if minetest.is_protected(p, name) then
					minetest.chat_send_player(name, S("Path protected at").." "..minetest.pos_to_string(p))
					meta:set_string("ta_cable_start", "")
					return itemstack
				end
				table.insert(to_place, p)
			else
				minetest.chat_send_player(name, S("Path blocked at").." "..minetest.pos_to_string(p))
				meta:set_string("ta_cable_start", "")
				return itemstack
			end
		end
	end
	
	if #to_place == 0 then
		minetest.chat_send_player(name, S("No cable needed."))
		meta:set_string("ta_cable_start", "")
		return itemstack
	end
	
	if itemstack:get_count() < #to_place then
		minetest.chat_send_player(name, S("Not enough cable! Needed: ")..#to_place)
		meta:set_string("ta_cable_start", "")
		return itemstack
	end
	
	-- Pass 1: Place all raw nodes to ensure neighbors exist
	for _, p in ipairs(to_place) do
		minetest.set_node(p, {name="techage:power_lineS"})
	end
	
	-- Pass 2: Update connections now that all neighbors are present
	for i, p in ipairs(to_place) do
		Cable:after_place_tube(p, nil, nil)
		
		-- CORRECTION STEP:
		-- If the cable bent into an Angle ("power_lineA") but we are in a straight run,
		-- or if it ignored the pole, we force it to align with the path vector.
		
		-- Determine direction from previous node (or start) to current
		local prev = (i == 1) and start_pos or to_place[i-1]
		local next_p = (i == #to_place) and pos or to_place[i+1]
		
		-- Check alignment
		local dx = math.abs(next_p.x - prev.x)
		local dy = math.abs(next_p.y - prev.y)
		local dz = math.abs(next_p.z - prev.z)
		
		-- If we are moving strictly horizonal AND flat, force straight cable
		-- We must ensure dy is 0, otherwise it's a vertical corner/step!
		if dx > 0 and dz == 0 and dy == 0 then
			-- East-West alignment: param2 = 1 (X+) or 3 (X-)
			-- Force Straight Line S
			minetest.swap_node(p, {name="techage:power_lineS", param2=1})
		elseif dz > 0 and dx == 0 and dy == 0 then
			-- North-South alignment: param2 = 0 (Z+) or 2 (Z-)
			-- Force Straight Line S
			minetest.swap_node(p, {name="techage:power_lineS", param2=0})
		end
		-- Vertical or diagonal steps are left to tubelib's logic
	end
	
	-- ANCHOR FIX: Explicitly force the endpoints to connect to the poles visually
	-- Only force Straight (S) if the line is strictly STRAIGHT (Collinear).
	-- If it turns (Corner) or slopes (Vertical), leave it alone.
	for i, p in ipairs(to_place) do
		local is_start = (i == 1)
		local is_end = (i == #to_place)
		
		if is_start or is_end then
			local pole = is_start and start_pos or pos
			
			-- Determine the 'other' side of this cable (the path side)
			local path_neighbor = nil
			if is_start then
				path_neighbor = (#to_place > 1) and to_place[2] or pos
			else -- is_end
				path_neighbor = (#to_place > 1) and to_place[i-1] or start_pos
			end
			
			-- Strict Collinearity Checks
			-- 1. Must be flat (dy=0)
			local dy_total = math.abs(pole.y - path_neighbor.y)
			
			if dy_total == 0 and p.y == pole.y then
				-- 2. Must be X-Aligned or Z-Aligned
				local is_x_aligned = (pole.z == p.z and p.z == path_neighbor.z)
				local is_z_aligned = (pole.x == p.x and p.x == path_neighbor.x)
				
				if is_x_aligned then
					-- East-West run
					minetest.swap_node(p, {name="techage:power_lineS", param2=1})
				elseif is_z_aligned then
					-- North-South run
					minetest.swap_node(p, {name="techage:power_lineS", param2=0})
				end
			end
		end
	end
	
	itemstack:take_item(#to_place)
	meta:set_string("ta_cable_start", "")
	minetest.chat_send_player(name, S("Stringing complete! Used ")..#to_place..S(" cables."))
	
	return itemstack
end

local function can_dig(pos, digger)
	if digger and digger:is_player() then
		if M(pos):get_string("owner") == digger:get_player_name() then
			return true
		end
		if minetest.check_player_privs(digger:get_player_name(), "powerline") then
			return true
		end
	end
	return false
end

-- legacy node
minetest.register_node("techage:power_line", {
	description = S("TA Power Line"),
	tiles = {"techage_power_line.png"},
	inventory_image = 'techage_power_line_inv.png',
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Cable:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_tube(pos, oldnode)
	end,

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/32, -1/32, -4/8,  1/32, 1/32, 4/8},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-2/32, -2/32, -4/8,  2/32, 2/32, 4/8},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	drop = "techage:power_lineS",
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
	sounds = default.node_sound_defaults(),
})

-- new nodes lineS/lineA
minetest.register_node("techage:power_lineS", {
	description = S("TA Power Line"),
	tiles = {"techage_power_line.png"},
	inventory_image = 'techage_power_line_inv.png',
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Cable:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_tube(pos, oldnode)
	end,

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/32, -1/32, -4/8,  1/32, 1/32, 4/8},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-2/32, -2/32, -4/8,  2/32, 2/32, 4/8},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	drop = "techage:power_lineS",
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("techage:power_lineA", {
	description = S("TA Power Line"),
	tiles = {
		"techage_power_line.png",
		"techage_power_line.png^[transformR180",
		"techage_power_line.png^[transformR270",
		"techage_power_line.png",
		"techage_power_line.png",
		"techage_power_line.png",
	},
	inventory_image = 'techage_power_line_inv.png',
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Cable:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_tube(pos, oldnode)
	end,

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-1/32, -16/32,  -1/32,  1/32, -15/32,   1/32},
			{-1/32, -16/32,  -2/32,  1/32, -14/32,   0/32},
			{-1/32, -15/32,  -3/32,  1/32, -13/32,  -1/32},
			{-1/32, -14/32,  -4/32,  1/32, -12/32,  -2/32},
			{-1/32, -13/32,  -5/32,  1/32, -11/32,  -3/32},
			{-1/32, -12/32,  -6/32,  1/32, -10/32,  -4/32},
			{-1/32, -11/32,  -7/32,  1/32,  -9/32,  -5/32},
			{-1/32, -10/32,  -8/32,  1/32,  -8/32,  -6/32},
			{-1/32,  -9/32,  -9/32,  1/32,  -7/32,  -7/32},
			{-1/32,  -8/32, -10/32,  1/32,  -6/32,  -8/32},
			{-1/32,  -7/32, -11/32,  1/32,  -5/32,  -9/32},
			{-1/32,  -6/32, -12/32,  1/32,  -4/32, -10/32},
			{-1/32,  -5/32, -13/32,  1/32,  -3/32, -11/32},
			{-1/32,  -4/32, -14/32,  1/32,  -2/32, -12/32},
			{-1/32,  -3/32, -15/32,  1/32,  -1/32, -13/32},
			{-1/32,  -2/32, -16/32,  1/32,   0/32, -14/32},
			{-1/32,  -1/32, -16/32,  1/32,   1/32, -15/32},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-2/32, -16/32, 2/32,  2/32, 2/32, -16/32},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	drop = "techage:power_lineS",
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
	sounds = default.node_sound_defaults(),
})

minetest.register_node("techage:power_pole2", {
	description = S("TA Power Pole Top 2 (for landlines)"),
	tiles = {
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole.png"
	},

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -4/32, -16/32,  -4/32,   4/32, 16/32,   4/32},
			{ -1/32,  -6/32, -16/32,   1/32, -4/32,  16/32},
			{ -2/32,  -4/32, -16/32,   2/32,  4/32, -12/32},
			{ -2/32,  -4/32,  12/32,   2/32,  4/32,  16/32},
		},
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		M(pos):set_string("owner", placer:get_player_name())
		if techage.is_protected(pos, placer:get_player_name()) then
			minetest.chat_send_player(placer:get_player_name(), "position is protected   ")
			minetest.remove_node(pos)
			return true
		end
		if not Cable:after_place_tube(pos, placer, pointed_thing) then
			minetest.chat_send_player(placer:get_player_name(), "invalid pole position   ")
			minetest.remove_node(pos)
			Cable:after_dig_node(pos)
			return true
		end
		return false
	end,
	can_dig = can_dig,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_tube(pos, oldnode)
	end,

	-- [CUSTOM PATCH] Hooks into the auto-stringer
	on_rightclick = on_rightclick_conn,

	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky=2, crumbly=2, choppy=2},
	sounds = default.node_sound_defaults(),
})

-- dummy node for the inventory and to be placed and imediately replaced
minetest.register_node("techage:power_pole", {
	description = S("TA Power Pole Top (for up to 6 connections)"),
	tiles = {
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole.png"
	},

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -4/32, -16/32,  -4/32,   4/32, 16/32,   4/32},
			{-16/32,  -6/32,  -1/32,  16/32, -4/32,   1/32},
			{ -1/32,  -6/32, -16/32,   1/32, -4/32,  16/32},
			{-16/32,  -4/32,  -2/32, -12/32,  4/32,   2/32},
			{ 12/32,  -4/32,  -2/32,  16/32,  4/32,   2/32},
			{ -2/32,  -4/32, -16/32,   2/32,  4/32, -12/32},
			{ -2/32,  -4/32,  12/32,   2/32,  4/32,  16/32},
		},
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		M(pos):set_string("owner", placer:get_player_name())
		if techage.is_protected(pos, placer:get_player_name()) then
			minetest.chat_send_player(placer:get_player_name(), "position is protected   ")
			minetest.remove_node(pos)
			return true
		end
		local node = minetest.get_node(pos)
		node.name = "techage:power_pole_conn"
		minetest.swap_node(pos, node)
		Cable:after_place_node(pos)
	end,

	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky=2, crumbly=2, choppy=2},
})






-- secondary node like a junction
minetest.register_node("techage:power_pole_conn", {
	description = "TA Power Pole Top (for up to 6 connections)",
	tiles = {
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole_top.png",
		"default_wood.png^techage_power_pole.png"
	},

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "connected",
		fixed = {{ -4/32, -16/32,  -4/32,   4/32, 16/32,   4/32}},

		connect_left = {{-16/32, -6/32, -1/32,  1/32,  -4/32, 1/32},
			{-16/32, -4/32, -2/32, -12/32, 4/32, 2/32}},
		connect_right = {{ -1/32, -6/32, -1/32,  16/32, -4/32, 1/32},
			{12/32, -4/32, -2/32,  16/32, 4/32, 2/32}},
		connect_back = {{-1/32, -6/32,  -1/32,  1/32, -4/32, 16/32},
			{-2/32, -4/32, 12/32, 2/32, 4/32, 16/32}},
		connect_front = {{-1/32, -6/32, -16/32,  1/32, -4/32, 1/32},
			{-2/32, -4/32, -16/32,  2/32, 4/32, -12/32}},
	},
	connects_to = {"techage:power_line", "techage:power_lineS", "techage:power_lineA"},

	can_dig = can_dig,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Cable:after_dig_node(pos)
	end,
    

    
    -- [CUSTOM PATCH] Hooks into the auto-stringer
    on_rightclick = on_rightclick_conn,

	drop = "techage:power_pole",
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky=2, crumbly=2, choppy=2, not_in_creative_inventory = 1},
	sounds = default.node_sound_defaults(),
})

power.register_nodes({"techage:power_pole_conn"}, Cable, "junc")

minetest.register_node("techage:power_pole3", {
	description = S("TA Power Pole"),
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},

	paramtype2 = "facedir", -- important!
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -4/32, -16/32,  -4/32,   4/32, 16/32,   4/32},
		},
	},
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	use_texture_alpha = techage.CLIP,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky=2, crumbly=2, choppy=2},
	sounds = default.node_sound_defaults(),
})

minetest.register_craft({
	output = "techage:power_lineS 24",
	recipe = {
		{"default:copper_ingot", "", ""},
		{"", "default:copper_ingot", ""},
		{"", "", "default:copper_ingot"},
	},
})

minetest.register_craft({
	output = "techage:power_pole2",
	recipe = {
		{"", "default:stick", ""},
		{"techage:power_lineS", "default:copper_ingot", "techage:power_lineS"},
		{"", "default:stick", ""},
	},
})

minetest.register_craft({
	output = "techage:power_pole",
	recipe = {
		{"", "", ""},
		{"", "techage:power_pole2", ""},
		{"", "techage:power_pole2", ""},
	},
})

minetest.register_craft({
	output = "techage:power_pole3 4",
	recipe = {
		{"", "group:wood", ""},
		{"", "techage:power_lineS", ""},
		{"", "group:wood", ""},
	},
})
