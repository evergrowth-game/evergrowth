-- Headless Test Suite for Optical Rangefinder & Bare-Hand Jump Ignition
-- Tests: Item Registration, Tool Linking, Margin Cycling, Standoff Coordinate Calculation,
-- Self-Ship Mask Exclusion, Standoff Distance Guard, and Bare-Hand Punch Execution.

local tests_passed = 0
local tests_failed = 0

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error(string.format("ASSERTION FAILED: %s (expected: %s, got: %s)", msg or "", tostring(expected), tostring(actual)), 2)
	end
end

local function assert_true(val, msg)
	if not val then
		error(string.format("ASSERTION FAILED: %s (expected truthy, got: %s)", msg or "", tostring(val)), 2)
	end
end

local function assert_false(val, msg)
	if val then
		error(string.format("ASSERTION FAILED: %s (expected falsy, got: %s)", msg or "", tostring(val)), 2)
	end
end

local function run_test(name, fn)
	local status, err = pcall(fn)
	if status then
		tests_passed = tests_passed + 1
		print(string.format("  [PASS] %s", name))
	else
		tests_failed = tests_failed + 1
		print(string.format("  [FAIL] %s: %s", name, tostring(err)))
	end
end

--------------------------------------------------------------------------------
-- Mock Minetest Environment
--------------------------------------------------------------------------------
_G.minetest = {}
_G.jumpdrive = {}
_G.jumpdrive_tweaks = {}

local registered_tools = {}
local registered_nodes = {
	["air"] = {buildable_to = true},
	["vacuum:vacuum"] = {buildable_to = true},
	["vacuum:air_bottle"] = {buildable_to = true},
	["jumpdrive:engine"] = {description = "Engine"},
	["jumpdrive:backbone"] = {description = "Backbone"},
	["default:stone"] = {description = "Asteroid Rock"},
}
local node_world = {}
local node_meta_store = {}
local chat_messages = {}
local last_executed_jump_pos = nil

function minetest.get_translator(mod)
	return function(s) return s end
end

function minetest.colorize(color, str)
	return str
end

function minetest.formspec_escape(s)
	return s
end

function minetest.get_modpath(mod)
	return "mods/" .. mod
end

function minetest.register_tool(name, def)
	registered_tools[name] = def
end

function minetest.override_item(name, def)
	if registered_nodes[name] then
		for k, v in pairs(def) do
			registered_nodes[name][k] = v
		end
	end
end

_G.minetest.registered_nodes = registered_nodes
_G.minetest.registered_tools = registered_tools

function minetest.hash_node_position(pos)
	return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

function minetest.pos_to_string(pos)
	return string.format("(%d,%d,%d)", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
end

function minetest.string_to_pos(str)
	local x, y, z = str:match("%((%-?%d+),(%-?%d+),(%-?%d+)%)")
	if x and y and z then
		return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
	end
	return nil
end

function minetest.get_node(pos)
	local h = minetest.hash_node_position(pos)
	return node_world[h] or {name = "air"}
end

function minetest.get_node_or_nil(pos)
	return minetest.get_node(pos)
end

function minetest.set_node(pos, node)
	local h = minetest.hash_node_position(pos)
	node_world[h] = {name = node.name}
end

function minetest.find_nodes_in_area(minp, maxp, nodenames)
	local results = {}
	local target_map = {}
	for _, n in ipairs(nodenames) do target_map[n] = true end

	for x = minp.x, maxp.x do
		for y = minp.y, maxp.y do
			for z = minp.z, maxp.z do
				local p = {x = x, y = y, z = z}
				local n = minetest.get_node(p)
				if target_map[n.name] then
					table.insert(results, p)
				end
			end
		end
	end
	return results
end

function minetest.get_meta(pos)
	local h = minetest.hash_node_position(pos)
	if not node_meta_store[h] then
		local data = {}
		node_meta_store[h] = {
			get_int = function(self, k) return data[k] or 0 end,
			set_int = function(self, k, v) data[k] = v end,
			get_string = function(self, k) return data[k] or "" end,
			set_string = function(self, k, v) data[k] = v end,
		}
	end
	return node_meta_store[h]
end

function minetest.chat_send_player(name, msg)
	table.insert(chat_messages, {player = name, message = msg})
end

function minetest.is_protected(pos, name)
	return false
end

_G.vector = {
	add = function(a, b)
		if type(b) == "number" then return {x = a.x + b, y = a.y + b, z = a.z + b} end
		return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}
	end,
	subtract = function(a, b)
		if type(b) == "number" then return {x = a.x - b, y = a.y - b, z = a.z - b} end
		return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}
	end,
	multiply = function(a, s)
		return {x = a.x * s, y = a.y * s, z = a.z * s}
	end,
	distance = function(a, b)
		local dx = a.x - b.x
		local dy = a.y - b.y
		local dz = a.z - b.z
		return math.sqrt(dx * dx + dy * dy + dz * dz)
	end
}

function jumpdrive.sanitize_coord(c)
	if c < -30912 then return -30912 end
	if c > 30912 then return 30912 end
	return c
end

function jumpdrive.update_infotext(meta, pos) end
function jumpdrive.update_formspec(meta, pos) end

function jumpdrive.execute_jump(pos, player)
	last_executed_jump_pos = pos
	return true, 1000
end

-- Mock ItemStack
local function create_mock_itemstack(name, initial_meta)
	local meta_data = initial_meta or {}
	local meta_obj = {
		get_int = function(self, k) return meta_data[k] or 0 end,
		set_int = function(self, k, v) meta_data[k] = v end,
		get_string = function(self, k) return meta_data[k] or "" end,
		set_string = function(self, k, v) meta_data[k] = v end,
	}
	return {
		get_name = function() return name end,
		get_meta = function() return meta_obj end,
		is_empty = function() return name == "" or name == nil end,
	}
end

-- Mock Player
local function create_mock_player(name, pos, look_dir, sneak)
	return {
		is_player = function() return true end,
		get_player_name = function() return name end,
		get_pos = function() return pos end,
		get_look_dir = function() return look_dir or {x = 0, y = 0, z = 1} end,
		get_player_control = function() return {sneak = sneak or false} end,
		get_properties = function() return {eye_height = 1.625} end,
		get_wielded_item = function() return create_mock_itemstack("") end,
	}
end

-- Mock raycast
local mock_ray_results = {}
function minetest.raycast(from, to, objects, liquids)
	local idx = 0
	return function()
		idx = idx + 1
		return mock_ray_results[idx]
	end
end

-- Mock spacecraft scanner
jumpdrive_tweaks.scan_spacecraft = function(engine_pos)
	local mask = {}
	mask[minetest.hash_node_position(engine_pos)] = true
	mask[minetest.hash_node_position({x = engine_pos.x, y = engine_pos.y, z = engine_pos.z + 1})] = true
	return {
		node_count = 2,
		backbone_count = 1,
		size = {x = 5, y = 5, z = 5},
		effective_radius = 5,
		mask = mask,
		nodes = {engine_pos},
		min_pos = engine_pos,
		max_pos = {x = engine_pos.x, y = engine_pos.y, z = engine_pos.z + 1}
	}
end

jumpdrive_tweaks.is_ship_target_empty = function(ship_scan, delta_vec)
	return true, nil
end

--------------------------------------------------------------------------------
-- Load target files under test
--------------------------------------------------------------------------------
dofile("mods/space_modpack/jumpdrive_tweaks/rangefinder.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/formspec.lua")

print("--- Starting Optical Rangefinder & Jump Ignition Unit Tests ---")

-- Test 1: Tool Registration
run_test("Tool Registration & Metadata Defaults", function()
	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]
	assert_true(tool ~= nil, "Tool jumpdrive_tweaks:rangefinder must be registered")
	assert_eq(tool.stack_max, 1, "Stack max must be 1")
	assert_true(type(tool.on_place) == "function", "on_place handler must exist")
	assert_true(type(tool.on_secondary_use) == "function", "on_secondary_use handler must exist")
end)

-- Test 2: Tool Linking via direct API and right-click
run_test("Tool Linking to Jump Engine", function()
	local engine_pos = {x = 100, y = 1200, z = 100}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder")
	local player = create_mock_player("TestPilot", {x = 100, y = 1200, z = 98})

	jumpdrive_tweaks.link_rangefinder(itemstack, player, engine_pos)
	local meta = itemstack:get_meta()
	assert_eq(meta:get_string("engine_pos"), "(100,1200,100)", "Engine pos string stored in meta")
	assert_eq(meta:get_int("standoff_margin"), 20, "Default margin stored as 20")
end)

-- Test 3: Standoff Margin Cycling (20 -> 50 -> 100 -> 20)
run_test("Standoff Margin Cycling with Sneak", function()
	local engine_pos = {x = 0, y = 1500, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder", {
		engine_pos = "(0,1500,0)",
		standoff_margin = 20
	})
	local player_sneaking = create_mock_player("Pilot", {x = 0, y = 1500, z = 1}, {x = 0, y = 0, z = 1}, true)

	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]

	-- Cycle 1: 20 -> 50
	tool.on_place(itemstack, player_sneaking, {type = "nothing"})
	assert_eq(itemstack:get_meta():get_int("standoff_margin"), 50, "Margin cycles to 50")

	-- Cycle 2: 50 -> 100
	tool.on_place(itemstack, player_sneaking, {type = "nothing"})
	assert_eq(itemstack:get_meta():get_int("standoff_margin"), 100, "Margin cycles to 100")

	-- Cycle 3: 100 -> 20
	tool.on_place(itemstack, player_sneaking, {type = "nothing"})
	assert_eq(itemstack:get_meta():get_int("standoff_margin"), 20, "Margin cycles back to 20")
end)

-- Test 4: Line-of-sight Raycast & Standoff Coordinate Calculation
run_test("Raycast Standoff Coordinate Programming", function()
	local engine_pos = {x = 0, y = 1500, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder", {
		engine_pos = "(0,1500,0)",
		standoff_margin = 20
	})
	-- Player at (0, 1500, 5), looking straight North along +Z axis
	local player = create_mock_player("Pilot", {x = 0, y = 1500, z = 5}, {x = 0, y = 0, z = 1}, false)

	-- Obstacle placed at (0, 1500, 105) -> Distance from eye = 100m
	local obstacle_pos = {x = 0, y = 1500, z = 105}
	minetest.set_node(obstacle_pos, {name = "default:stone"})

	mock_ray_results = {
		{
			type = "node",
			under = obstacle_pos,
			intersection_point = obstacle_pos,
			intersection_normal = {x = 0, y = 0, z = -1}
		}
	}

	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]
	tool.on_place(itemstack, player, {type = "nothing"})

	-- Effective radius = 5, Margin = 20 -> Standoff distance = 25m
	-- dist = 100m, delta_dist = 100 - 25 = 75m
	-- engine_pos.z (0) + 75 = 75
	local engine_meta = minetest.get_meta(engine_pos)
	assert_eq(engine_meta:get_int("x"), 0, "Arrival X matches")
	assert_eq(engine_meta:get_int("y"), 1500, "Arrival Y matches")
	assert_eq(engine_meta:get_int("z"), 75, "Arrival Z accounts for cockpit offset and standoff")
end)

-- Test 5: Self-Ship Mask Node Exclusion
run_test("Self-Ship Node Filtering", function()
	local engine_pos = {x = 0, y = 2000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	local ship_canopy_pos = {x = 0, y = 2000, z = 1}
	minetest.set_node(ship_canopy_pos, {name = "default:stone"}) -- ship block

	local asteroid_pos = {x = 0, y = 2000, z = 300}
	minetest.set_node(asteroid_pos, {name = "default:stone"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder", {
		engine_pos = "(0,2000,0)",
		standoff_margin = 20
	})
	local player = create_mock_player("Pilot", {x = 0, y = 2000, z = 0}, {x = 0, y = 0, z = 1}, false)

	mock_ray_results = {
		-- First hit is self-ship canopy node (in mask)
		{
			type = "node",
			under = ship_canopy_pos,
			intersection_point = ship_canopy_pos,
		},
		-- Second hit is asteroid
		{
			type = "node",
			under = asteroid_pos,
			intersection_point = asteroid_pos,
		}
	}

	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]
	tool.on_place(itemstack, player, {type = "nothing"})

	local engine_meta = minetest.get_meta(engine_pos)
	-- dist = 300, standoff = 25 -> delta = 275
	assert_eq(engine_meta:get_int("z"), 275, "Self-ship canopy correctly ignored; targeted distant asteroid")
end)

-- Test 6: Standoff Threshold Warning
run_test("Standoff Threshold Warning when Already Close", function()
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder", {
		engine_pos = "(0,1000,0)",
		standoff_margin = 50
	})
	-- Player 10m away from wall (effective_radius 5 + margin 50 = 55m threshold)
	local player = create_mock_player("Pilot", {x = 0, y = 1000, z = 0}, {x = 0, y = 0, z = 1}, false)
	local close_wall = {x = 0, y = 1000, z = 10}
	minetest.set_node(close_wall, {name = "default:stone"})

	mock_ray_results = {
		{
			type = "node",
			under = close_wall,
			intersection_point = close_wall,
		}
	}

	chat_messages = {}
	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]
	tool.on_place(itemstack, player, {type = "nothing"})

	assert_true(#chat_messages > 0, "Chat message received")
	assert_true(chat_messages[#chat_messages].message:find("already within standoff threshold") ~= nil, "Standoff threshold warning reported")
end)

-- Test 7: Post-Jump Engine Rediscovery Fallback
run_test("Post-Jump Engine Rediscovery", function()
	-- Original engine was at (0, 1000, 0), but vessel jumped to (500, 1000, 500)
	local old_pos = {x = 0, y = 1000, z = 0}
	local new_pos = {x = 500, y = 1000, z = 500}
	node_world[minetest.hash_node_position(old_pos)] = nil
	minetest.set_node(new_pos, {name = "jumpdrive:engine"})

	local itemstack = create_mock_itemstack("jumpdrive_tweaks:rangefinder", {
		engine_pos = "(0,1000,0)",
		standoff_margin = 20
	})
	-- Player is near new engine position (500, 1000, 502)
	local player = create_mock_player("Pilot", {x = 500, y = 1000, z = 502}, {x = 0, y = 0, z = 1}, false)

	local asteroid_pos = {x = 500, y = 1000, z = 700}
	minetest.set_node(asteroid_pos, {name = "default:stone"})
	mock_ray_results = {
		{
			type = "node",
			under = asteroid_pos,
			intersection_point = asteroid_pos,
		}
	}

	local tool = registered_tools["jumpdrive_tweaks:rangefinder"]
	tool.on_place(itemstack, player, {type = "nothing"})

	local meta = itemstack:get_meta()
	assert_eq(meta:get_string("engine_pos"), "(500,1000,500)", "Rangefinder rediscovered new engine pos after jump")
	local new_engine_meta = minetest.get_meta(new_pos)
	-- dist = 198m, standoff = 25m, delta = 173m -> z = 500 + 173 = 673
	assert_eq(new_engine_meta:get_int("z"), 673, "Arrival coordinates programmed into relocated engine")
end)

-- Test 8: Bare-Hand on_punch Jump Execution on jumpdrive:engine
run_test("Bare-Hand Punch Jump Ignition & Dig Protection", function()
	local engine_node_def = registered_nodes["jumpdrive:engine"]
	assert_true(type(engine_node_def.on_punch) == "function", "jumpdrive:engine on_punch must be defined")

	local engine_pos = {x = 50, y = 1200, z = 50}
	last_executed_jump_pos = nil

	-- Scenario A: Punch with pickaxe / tool -> Must NOT jump (allows digging)
	local player_with_pick = {
		is_player = function() return true end,
		get_player_name = function() return "Miner" end,
		get_wielded_item = function() return create_mock_itemstack("default:pick_diamond") end,
	}
	engine_node_def.on_punch(engine_pos, {name = "jumpdrive:engine"}, player_with_pick, nil)
	assert_eq(last_executed_jump_pos, nil, "Tool punch must not execute jump")

	-- Scenario B: Punch with empty hand -> Executes jump
	local player_bare_hand = {
		is_player = function() return true end,
		get_player_name = function() return "Pilot" end,
		get_wielded_item = function() return create_mock_itemstack("") end,
	}
	engine_node_def.on_punch(engine_pos, {name = "jumpdrive:engine"}, player_bare_hand, nil)
	assert_eq(last_executed_jump_pos, engine_pos, "Bare-hand punch executes jump")
end)

print(string.format("\nTest Results: %d passed, %d failed", tests_passed, tests_failed))
if tests_failed > 0 then
	os.exit(1)
end
