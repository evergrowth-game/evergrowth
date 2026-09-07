-- Automated Headless Test Suite for Spacecraft Backbone Discovery & Selective Jump Movement
-- Tests: Graph BFS, Proximity Hull Envelope, Natural Terrain vs Masonry, Mass-Scaled Power,
-- Selective Transfer, Protection Gating, Post-Emergence Collision Recheck, and Fuel/Timer Isolation.

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
-- Minetest & Jumpdrive Headless Mock Environment
--------------------------------------------------------------------------------
_G.minetest = {}
_G.jumpdrive = {config = {max_radius = 25}}
_G.jumpdrive_tweaks = {}

local world_nodes = {}
local node_metadata_store = {}
local node_timers = {}
local protected_positions = {}
local updated_map_called = false

local registered_nodes = {
	["air"] = {buildable_to = true},
	["vacuum:vacuum"] = {buildable_to = true},
	["jumpdrive:engine"] = {description = "Engine"},
	["jumpdrive:backbone"] = {description = "Backbone"},
	["jumpdrive_tweaks:fuel_tank"] = {description = "Tank"},
	["default:glass"] = {description = "Glass"},
	["default:stonebrick"] = {description = "Stone Brick", groups = {stone = 1}},
	["default:cobble"] = {description = "Cobblestone", groups = {stone = 1}},
	["techage:ta4_solar_gen"] = {description = "Solar"},
	["default:dirt"] = {description = "Dirt", is_ground_content = true},
	["default:stone"] = {description = "Stone", is_ground_content = true, groups = {stone = 1}},
}

minetest.registered_nodes = registered_nodes

minetest.get_translator = function()
	return function(str) return str end
end

minetest.get_modpath = function(mod)
	if mod == "jumpdrive_tweaks" or mod == "jumpdrive" or mod == "techage" or mod == "vacuum" then
		return "mods/space_modpack/" .. mod
	end
	return nil
end

minetest.log = function() end
minetest.sound_play = function() end
minetest.add_particlespawner = function() end
minetest.chat_send_player = function() end

minetest.register_abm = function() end

minetest.hash_node_position = function(pos)
	return string.format("%d,%d,%d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
end

local content_ids = {
	["air"] = 0,
	["ignore"] = 1,
	["vacuum:vacuum"] = 2,
	["jumpdrive:engine"] = 10,
	["jumpdrive:backbone"] = 11,
	["jumpdrive_tweaks:fuel_tank"] = 12,
	["default:glass"] = 13,
	["default:stonebrick"] = 14,
	["default:cobble"] = 15,
	["techage:ta4_solar_gen"] = 16,
	["default:dirt"] = 20,
	["default:stone"] = 21,
}
local id_to_names = {}
for k, v in pairs(content_ids) do id_to_names[v] = k end

minetest.get_content_id = function(name)
	return content_ids[name] or 99
end

minetest.get_name_from_content_id = function(id)
	return id_to_names[id] or "unknown"
end

minetest.get_node = function(pos)
	local h = minetest.hash_node_position(pos)
	return world_nodes[h] or {name = "air"}
end

minetest.get_node_or_nil = minetest.get_node

minetest.set_node = function(pos, node)
	local h = minetest.hash_node_position(pos)
	world_nodes[h] = {name = node.name}
end

minetest.is_protected = function(pos, playername)
	local h = minetest.hash_node_position(pos)
	return protected_positions[h] or false
end

minetest.find_nodes_with_meta = function(p1, p2)
	local result = {}
	for h, _ in pairs(node_metadata_store) do
		local parts = {}
		for p in h:gmatch("[^,]+") do table.insert(parts, tonumber(p)) end
		local p = {x = parts[1], y = parts[2], z = parts[3]}
		if p.x >= p1.x and p.x <= p2.x and p.y >= p1.y and p.y <= p2.y and p.z >= p1.z and p.z <= p2.z then
			table.insert(result, p)
		end
	end
	return result
end

minetest.get_meta = function(pos)
	local h = minetest.hash_node_position(pos)
	if not node_metadata_store[h] then
		node_metadata_store[h] = {
			ints = {},
			strings = {},
			tables = {},
		}
	end
	local entry = node_metadata_store[h]
	return {
		get_int = function(self, key) return entry.ints[key] or 0 end,
		set_int = function(self, key, val) entry.ints[key] = val end,
		get_string = function(self, key) return entry.strings[key] or "" end,
		set_string = function(self, key, val) entry.strings[key] = val end,
		to_table = function(self) return {fields = entry.strings, ints = entry.ints} end,
		from_table = function(self, tbl)
			if not tbl or not next(tbl) then
				node_metadata_store[h] = nil
			else
				node_metadata_store[h] = {
					strings = tbl.fields or {},
					ints = tbl.ints or {},
					tables = {},
				}
				entry = node_metadata_store[h]
			end
		end,
	}
end

minetest.get_node_timer = function(pos)
	local h = minetest.hash_node_position(pos)
	return {
		is_started = function(self) return node_timers[h] ~= nil end,
		get_timeout = function(self) return node_timers[h] and node_timers[h].timeout or 0 end,
		get_elapsed = function(self) return node_timers[h] and node_timers[h].elapsed or 0 end,
		stop = function(self) node_timers[h] = nil end,
		set = function(self, timeout, elapsed) node_timers[h] = {timeout = timeout, elapsed = elapsed} end,
	}
end

_G.vector = {
	new = function(x, y, z)
		if type(x) == "table" then return {x = x.x, y = x.y, z = x.z} end
		return {x = x or 0, y = y or 0, z = z or 0}
	end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	distance = function(a, b)
		local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
		return math.sqrt(dx*dx + dy*dy + dz*dz)
	end,
	zero = function() return {x = 0, y = 0, z = 0} end,
}

_G.VoxelArea = {}
function VoxelArea:new(o)
	local obj = {MinEdge = o.MinEdge, MaxEdge = o.MaxEdge}
	setmetatable(obj, self)
	self.__index = self
	return obj
end
function VoxelArea:indexp(p)
	return string.format("%d,%d,%d", p.x, p.y, p.z)
end
function VoxelArea:index(x, y, z)
	return string.format("%d,%d,%d", x, y, z)
end

minetest.get_voxel_manip = function()
	return {
		read_from_map = function(self, p1, p2)
			return p1, p2
		end,
		get_data = function(self)
			local data = {}
			for h, node in pairs(world_nodes) do
				data[h] = content_ids[node.name] or 0
			end
			return setmetatable(data, {
				__index = function() return 0 end
			})
		end,
		get_light_data = function() return {} end,
		get_param2_data = function() return {} end,
		set_data = function(self, data)
			for h, cid in pairs(data) do
				world_nodes[h] = {name = id_to_names[cid] or "air"}
			end
		end,
		set_light_data = function() end,
		set_param2_data = function() end,
		write_to_map = function() end,
		update_map = function() updated_map_called = true end,
	}
end

minetest.get_us_time = function() return 1000 end

jumpdrive.get_meta_pos = function(pos)
	local meta = minetest.get_meta(pos)
	return {x = meta:get_int("x"), y = meta:get_int("y"), z = meta:get_int("z")}
end

jumpdrive.is_area_protected = function(p1, p2, playername)
	for h, val in pairs(protected_positions) do
		if val then return true end
	end
	return false
end

jumpdrive.update_infotext = function() end
jumpdrive.node_compat = function() end
jumpdrive.commit_node_compat = function() end

jumpdrive.move = function(source_pos1, source_pos2, target_pos1, target_pos2)
	local delta = vector.subtract(target_pos1, source_pos1)
	jumpdrive.move_mapdata(source_pos1, source_pos2, target_pos1, target_pos2)
	jumpdrive.move_metadata(source_pos1, source_pos2, delta)
	jumpdrive.move_nodetimers(source_pos1, source_pos2, delta)
	jumpdrive.clear_area(source_pos1, source_pos2)
end

-- Load modules
dofile("mods/space_modpack/jumpdrive_tweaks/ship_tracker.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/terrain_filter.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/validator.lua")

--------------------------------------------------------------------------------
-- Run Comprehensive Unit Tests
--------------------------------------------------------------------------------
print("Starting Spacecraft Backbone Tracker & Geometry Test Suite...\n")

-- Test 1: Single Engine craft
run_test("Single Engine: Discovered with fallback bounds and R=1", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos)
	assert_eq(scan.node_count, 1, "Single engine solid count")
	assert_eq(scan.backbone_count, 1, "Backbone node count")
	assert_eq(scan.effective_radius, 2, "Effective mass radius")
	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine in mask")
end)

-- Test 2: Extended Backbone with Solar Panel Wings
run_test("Asymmetric Solar Wings: 10-node backbone spine captures solar wings without shear", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	for x = 1, 8 do
		minetest.set_node({x = x, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	end

	minetest.set_node({x = 8, y = 1000, z = -2}, {name = "techage:ta4_solar_gen"})
	minetest.set_node({x = 8, y = 1000, z = -1}, {name = "techage:ta4_solar_gen"})
	minetest.set_node({x = 8, y = 1000, z = 1}, {name = "techage:ta4_solar_gen"})
	minetest.set_node({x = 8, y = 1000, z = 2}, {name = "techage:ta4_solar_gen"})

	-- Distant unattached solar panel (X = 20, 12 blocks away from any backbone node)
	minetest.set_node({x = 20, y = 1000, z = 0}, {name = "techage:ta4_solar_gen"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_eq(scan.backbone_count, 9, "9 backbone segments (1 engine + 8 spine)")
	assert_true(scan.mask[minetest.hash_node_position({x = 8, y = 1000, z = 2})], "Wing tip solar panel captured")
	assert_true(scan.mask[minetest.hash_node_position({x = 8, y = 1000, z = -2})], "Wing tip solar panel captured")
	assert_false(scan.mask[minetest.hash_node_position({x = 20, y = 1000, z = 0})], "Distant unattached block excluded")
	assert_eq(scan.min_pos.x, 0, "Min X")
	assert_eq(scan.max_pos.x, 8, "Max X (does not include X=20)")
end)

-- Test 3: Natural Terrain Exclusion vs Masonry Construction Inclusion
run_test("Terrain vs Masonry: Stonebrick and cobble are kept; natural dirt and stone excluded", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 20, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 0, y = 21, z = 0}, {name = "jumpdrive:backbone"})

	-- Crafted masonry hull blocks
	minetest.set_node({x = 1, y = 20, z = 0}, {name = "default:stonebrick"})
	minetest.set_node({x = -1, y = 20, z = 0}, {name = "default:cobble"})

	-- Natural unworked ground
	minetest.set_node({x = 2, y = 20, z = 0}, {name = "default:dirt"})
	minetest.set_node({x = 0, y = 19, z = 0}, {name = "default:stone"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine included")
	assert_true(scan.mask[minetest.hash_node_position({x = 0, y = 21, z = 0})], "Backbone included")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 20, z = 0})], "Stonebrick included")
	assert_true(scan.mask[minetest.hash_node_position({x = -1, y = 20, z = 0})], "Cobble included")
	assert_false(scan.mask[minetest.hash_node_position({x = 2, y = 20, z = 0})], "Natural dirt excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 19, z = 0})], "Natural stone excluded")
	assert_eq(scan.node_count, 4, "4 ship nodes counted (engine, backbone, stonebrick, cobble)")
end)

-- Test 4: Protection Gating
run_test("Protection Gating: Jumps fail cleanly if origin or destination intersects protected areas", function()
	world_nodes = {}
	protected_positions = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 500)
	meta:set_int("y", 1000)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Destination protected
	protected_positions[minetest.hash_node_position({x = 500, y = 1000, z = 0})] = true

	local player_mock = {
		is_player = function() return true end,
		get_player_name = function() return "tester" end,
	}

	local success, err = jumpdrive.execute_jump(engine_pos, player_mock)
	assert_false(success, "Jump should be blocked")
	assert_true(tostring(err):find("protected"), "Error mentions protected area")
end)

-- Test 5: Fuel Tank Isolation between Adjacent Craft
run_test("Fuel Isolation: Onboard fuel drawn strictly from ship's own attached tanks", function()
	world_nodes = {}
	protected_positions = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	-- Ship's own fuel tank (connected to backbone at X=2)
	local ship_tank_pos = {x = 2, y = 1000, z = 0}
	minetest.set_node(ship_tank_pos, {name = "jumpdrive_tweaks:fuel_tank"})
	local ship_tank_meta = minetest.get_meta(ship_tank_pos)
	ship_tank_meta:set_int("fuel_amount", 500)
	ship_tank_meta:set_string("fuel_type", "hydrogen")

	-- Neighboring station fuel tank (unattached at X=15, 12 blocks away)
	local station_tank_pos = {x = 15, y = 1000, z = 0}
	minetest.set_node(station_tank_pos, {name = "jumpdrive_tweaks:fuel_tank"})
	local station_tank_meta = minetest.get_meta(station_tank_pos)
	station_tank_meta:set_int("fuel_amount", 2000)
	station_tank_meta:set_string("fuel_type", "hydrogen")

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 100)
	meta:set_int("y", 1000)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 0) -- Depleted engine

	-- Preflight check triggers fuel transfer
	local preflight = jumpdrive.preflight_check(engine_pos, {x = 100, y = 1000, z = 0}, 5, "tester")
	assert_true(preflight.success, "Preflight succeeded")

	-- Verify ship tank was drained
	assert_true(ship_tank_meta:get_int("fuel_amount") < 500, "Ship tank was drained")

	-- Verify station tank was NOT touched
	assert_eq(station_tank_meta:get_int("fuel_amount"), 2000, "Station tank was NOT touched")
end)

-- Test 6: Node Timer Masking
run_test("Node Timer Isolation: Only timers on active ship nodes are migrated", function()
	world_nodes = {}
	node_timers = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	-- Timer on ship backbone
	local ship_timer_pos = {x = 1, y = 1000, z = 0}
	minetest.get_node_timer(ship_timer_pos):set(10, 5)

	-- Timer on adjacent unattached station block within bounding box (Y=1001)
	minetest.set_node({x = 1, y = 1001, z = 0}, {name = "default:stone"})
	minetest.get_node_timer({x = 1, y = 1001, z = 0}):set(20, 8)

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	jumpdrive_tweaks.active_ship_mask = scan.mask

	local delta = {x = 500, y = 0, z = 0}
	jumpdrive.move_nodetimers(scan.min_pos, scan.max_pos, delta)

	jumpdrive_tweaks.active_ship_mask = nil

	-- Ship timer migrated to X=501
	assert_false(minetest.get_node_timer(ship_timer_pos):is_started(), "Origin ship timer stopped")
	assert_true(minetest.get_node_timer({x = 501, y = 1000, z = 0}):is_started(), "Target ship timer started")

	-- Station timer at X=1, Y=1001 was NOT stopped or migrated
	assert_true(minetest.get_node_timer({x = 1, y = 1001, z = 0}):is_started(), "Station timer preserved at origin")
	assert_false(minetest.get_node_timer({x = 501, y = 1001, z = 0}):is_started(), "Station timer NOT moved to target")
end)

-- Test 7: Selective Jump Execution & Map Lighting Update
run_test("Selective Jump Execution: Teleports ship nodes, preserves background, updates map lighting", function()
	world_nodes = {}
	updated_map_called = false
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "techage:ta4_solar_gen"})

	-- Stationary asteroid / background rock in the same bounding volume
	minetest.set_node({x = 1, y = 1001, z = 0}, {name = "default:stone"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	jumpdrive_tweaks.active_ship_mask = scan.mask

	local delta_vector = {x = 500, y = 0, z = 0}
	local target_p1 = vector.add(scan.min_pos, delta_vector)
	local target_p2 = vector.add(scan.max_pos, delta_vector)

	-- Move mapdata
	jumpdrive.move_mapdata(scan.min_pos, scan.max_pos, target_p1, target_p2)
	jumpdrive.clear_area(scan.min_pos, scan.max_pos)

	jumpdrive_tweaks.active_ship_mask = nil

	-- Verify ship nodes moved to destination
	assert_eq(minetest.get_node({x = 500, y = 1000, z = 0}).name, "jumpdrive:engine", "Engine moved to target")
	assert_eq(minetest.get_node({x = 501, y = 1000, z = 0}).name, "jumpdrive:backbone", "Backbone moved to target")
	assert_eq(minetest.get_node({x = 502, y = 1000, z = 0}).name, "techage:ta4_solar_gen", "Solar moved to target")

	-- Verify source ship positions cleared to air
	assert_eq(minetest.get_node({x = 0, y = 1000, z = 0}).name, "air", "Source engine cleared")
	assert_eq(minetest.get_node({x = 1, y = 1000, z = 0}).name, "air", "Source backbone cleared")
	assert_eq(minetest.get_node({x = 2, y = 1000, z = 0}).name, "air", "Source solar cleared")

	-- Verify stationary asteroid rock was NOT moved or cleared
	assert_eq(minetest.get_node({x = 1, y = 1001, z = 0}).name, "default:stone", "Background stone preserved at origin")
	assert_eq(minetest.get_node({x = 501, y = 1001, z = 0}).name, "air", "Target destination did not copy stone")
	assert_true(updated_map_called, "update_map was called on clear_area")
end)

-- Test 8: Wood Planks and Modded Construction Inclusion
run_test("Wood & Construction Materials: Ethereal and modded wood construction nodes are preserved", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	-- Wood plank nodes
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "ethereal:frost_wood", groups = {wood = 1}})
	minetest.set_node({x = -1, y = 1000, z = 0}, {name = "ethereal:bamboo_floor", groups = {wood = 1}})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1000, z = 0})], "Ethereal frost wood included")
	assert_true(scan.mask[minetest.hash_node_position({x = -1, y = 1000, z = 0})], "Ethereal bamboo floor included")
	assert_eq(scan.node_count, 3, "3 ship nodes counted")
end)

-- Test 9: Destination Metadata Isolation
run_test("Destination Metadata Isolation: Metadata on external unattached destination nodes is preserved", function()
	world_nodes = {}
	node_metadata_store = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	-- Ship metadata on engine
	local ship_meta = minetest.get_meta(engine_pos)
	ship_meta:set_string("ship_name", "Enterprise")

	-- External station metadata at destination within bounding volume (X=501, Y=1001)
	local station_dest_pos = {x = 501, y = 1001, z = 0}
	local station_meta = minetest.get_meta(station_dest_pos)
	station_meta:set_string("station_id", "Dock-9")

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	jumpdrive_tweaks.active_ship_mask = scan.mask

	local delta = {x = 500, y = 0, z = 0}
	jumpdrive.move_metadata(scan.min_pos, scan.max_pos, delta)

	jumpdrive_tweaks.active_ship_mask = nil

	-- Ship metadata moved to destination
	assert_eq(minetest.get_meta({x = 500, y = 1000, z = 0}):get_string("ship_name"), "Enterprise", "Ship metadata moved to target")

	-- External station metadata preserved
	assert_eq(minetest.get_meta(station_dest_pos):get_string("station_id"), "Dock-9", "Station metadata preserved at destination")
end)

-- Test 10: Zero-Displacement Jump Safety (Prevent ship self-erasure)
run_test("Zero Displacement Jump: Aborts in preflight and execution without erasing craft", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 1000)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Preflight check should reject distance 0
	local preflight = jumpdrive.preflight_check(engine_pos, engine_pos, 5, "")
	assert_false(preflight.success, "preflight rejects distance 0")
	assert_true(string.find(preflight.msg, "identical") ~= nil, "message explains identical coordinates")

	-- execute_jump should reject distance 0
	local ok, msg = jumpdrive.execute_jump(engine_pos, nil)
	assert_false(ok, "execute_jump rejects distance 0")
	assert_true(string.find(msg, "identical") ~= nil, "message explains identical coordinates")

	-- Ship nodes are preserved (not cleared)
	assert_eq(minetest.get_node(engine_pos).name, "jumpdrive:engine", "Engine preserved")
	assert_eq(minetest.get_node({x = 1, y = 1000, z = 0}).name, "jumpdrive:backbone", "Backbone preserved")
end)

-- Test 11: Movement Error State Cleanup (pcall isolation)
run_test("Movement Error State Isolation: active_ship_mask is cleanly reset if jumpdrive.move raises error", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 1200)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Temporarily override jumpdrive.move to raise an error
	local old_move = jumpdrive.move
	jumpdrive.move = function()
		error("Simulated low-level mapgen or manipulation failure")
	end

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_false(ok, "execute_jump returns failure on move error")
	assert_true(string.find(tostring(err), "Jump movement error") ~= nil, "error message captured")
	assert_true(jumpdrive_tweaks.active_ship_mask == nil, "active_ship_mask reset to nil")

	-- Restore jumpdrive.move
	jumpdrive.move = old_move
end)

-- Test 12: Short-Jump Overlap Clearance (Origin hull collision false-positive fix)
run_test("Short Jump Overlap: 2m translational maneuver overlapping origin bounds is allowed", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 3, y = 1000, z = 0}, {name = "jumpdrive:backbone"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	local delta = {x = 2, y = 0, z = 0} -- Short jump of 2 meters, overlapping origin voxels

	local empty, msg = jumpdrive_tweaks.is_ship_target_empty(scan, delta)
	assert_true(empty, "short jump overlap recognized as clear since origin nodes vacate")
end)

-- Test 13: Direct Fuel Tank Discovery in scan_spacecraft
run_test("Fuel Tank Discovery: scan_spacecraft populates fuel_tanks table during graph traversal", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	local tank1_pos = {x = 1, y = 1000, z = 0}
	local tank2_pos = {x = -1, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(tank1_pos, {name = "jumpdrive_tweaks:fuel_tank"})
	minetest.set_node(tank2_pos, {name = "jumpdrive_tweaks:fuel_tank"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	assert_true(scan.fuel_tanks ~= nil, "scan has fuel_tanks table")
	assert_eq(#scan.fuel_tanks, 2, "2 fuel tanks discovered directly in scan")
end)

print(string.format("\nShip Tracker Test Suite Complete: %d passed, %d failed.\n", tests_passed, tests_failed))

if tests_failed > 0 then
	error("Test suite failed!")
end
