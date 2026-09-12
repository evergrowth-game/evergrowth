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
	["asteroid:atmos"] = {buildable_to = true},
	["jumpdrive:engine"] = {description = "Engine"},
	["jumpdrive:backbone"] = {description = "Backbone"},
	["jumpdrive_tweaks:fuel_tank"] = {description = "Tank"},
	["jumpdrive_tweaks:bridge_console"] = {description = "Bridge Console", groups = {jumpdrive_ship_part = 1}},
	["jumpdrive_tweaks:jump_lever"] = {description = "Jump Lever", groups = {jumpdrive_ship_part = 1}},
	["jumpdrive_tweaks:jump_lever_on"] = {description = "Jump Lever Engaged", groups = {jumpdrive_ship_part = 1}},
	["default:glass"] = {description = "Glass"},
	["default:stonebrick"] = {description = "Stone Brick", groups = {stone = 1}},
	["default:cobble"] = {description = "Cobblestone", groups = {stone = 1}},
	["techage:ta4_solar_gen"] = {description = "Solar"},
	["techage:ta4_tank"] = {description = "Liquid Tank"},
	["techage:ta4_solar_inverter"] = {description = "Solar Inverter", cycle_time = 2.0},
	["techage:ta3_akku"] = {description = "Battery Accu", cycle_time = 2.0},
	["default:dirt"] = {description = "Dirt", is_ground_content = true},
	["default:dirt_with_grass"] = {description = "Grass Dirt", is_ground_content = true, groups = {soil = 1}},
	["default:stone"] = {description = "Stone", is_ground_content = true, groups = {stone = 1}},
	["asteroid:stone"] = {description = "Asteroid Stone", is_ground_content = true},
	["asteroid:redstone"] = {description = "Asteroid Redstone", is_ground_content = true},
	["asteroid:cobble"] = {description = "Asteroid Cobble", is_ground_content = true},
	["asteroid:redcobble"] = {description = "Asteroid Red Cobble", is_ground_content = true},
	["asteroid:dust"] = {description = "Asteroid Dust", is_ground_content = true},
	["mars:redgrass"] = {description = "Mars Redgrass", groups = {flora = 1}},
	["other_worlds_tweaks:rich_iron_ore"] = {description = "Rich Asteroid Iron Ore", groups = {cracky = 2}},
	["other_worlds_tweaks:rich_mese_ore"] = {description = "Rich Asteroid Mese Ore", groups = {cracky = 1}},
	["other_worlds_tweaks:comet_ice"] = {description = "Comet Ice", groups = {cracky = 3}},
}

minetest.registered_nodes = registered_nodes

local techage_nvm_store = {}
local networks_updated = {}

_G.techage = {
	RUNNING = 1,
	BLOCKED = 2,
	STANDBY = 3,
	NOPOWER = 4,
	FAULT = 5,
	STOPPED = 6,
	ElectricCable = {tube_type = "electric_cable"},
	peek_nvm = function(pos)
		local h = minetest.hash_node_position(pos)
		return techage_nvm_store[h] or {}
	end,
	get_nvm = function(pos)
		local h = minetest.hash_node_position(pos)
		if not techage_nvm_store[h] then
			techage_nvm_store[h] = {}
		end
		return techage_nvm_store[h]
	end,
	has_nvm = function(pos)
		local h = minetest.hash_node_position(pos)
		return techage_nvm_store[h] ~= nil
	end,
	del_mem = function(pos)
		local h = minetest.hash_node_position(pos)
		techage_nvm_store[h] = nil
	end,
	is_running = function(nvm)
		return nvm.techage_state == 1 or nvm.running == true
	end,
}

_G.networks = {
	registered_networks = {
		power = {["electric_cable"] = {tube_type = "electric_cable"}},
		liquid = {["liquid_pipe"] = {tube_type = "liquid_pipe"}}
	},
	update_network = function(pos, outdir, tlib2)
		local h = minetest.hash_node_position(pos)
		networks_updated[h] = (networks_updated[h] or 0) + 1
	end,
	power = {
		start_storage_calc = function(pos, cable, outdir) end
	}
}

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
	["techage:ta4_tank"] = 17,
	["techage:ta4_solar_inverter"] = 18,
	["techage:ta3_akku"] = 19,
	["default:dirt"] = 20,
	["default:stone"] = 21,
}
local id_to_names = {}
for k, v in pairs(content_ids) do id_to_names[v] = k end

local next_cid = 100
minetest.get_content_id = function(name)
	if not content_ids[name] then
		content_ids[name] = next_cid
		id_to_names[next_cid] = name
		next_cid = next_cid + 1
	end
	return content_ids[name]
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
		start = function(self, timeout) node_timers[h] = {timeout = timeout, elapsed = 0} end,
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
				data[h] = minetest.get_content_id(node.name)
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

local mod_storage_store = {}
minetest.get_mod_storage = function()
	return {
		get_string = function(self, k) return mod_storage_store[k] or "" end,
		set_string = function(self, k, v) mod_storage_store[k] = v end,
	}
end
minetest.serialize = function(t) return "" end
minetest.after = function(delay, cb) if cb then cb() end end
minetest.sound_play = function() return 1 end
minetest.sound_stop = function() end
minetest.add_particlespawner = function() end
minetest.add_particle = function() end
minetest.register_node = function(name, def)
	registered_nodes[name] = def
end
minetest.register_tool = function() end
minetest.register_craft = function() end
minetest.register_on_player_receive_fields = function() end
minetest.register_globalstep = function() end
minetest.register_on_dieplayer = function() end
minetest.register_on_leaveplayer = function() end
default = {node_sound_metal_defaults = function() return {} end}

-- Load modules
dofile("mods/space_modpack/jumpdrive_tweaks/ship_tracker.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/techage_compat.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/terrain_filter.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/jump_fx.lua")
dofile("mods/space_modpack/jumpdrive_tweaks/beacon.lua")
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

-- Test 4: Space Natural Resource Exclusion
run_test("Space resources: comet ice and rich ores are excluded from the ship", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 5000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 0, y = 5001, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 1, y = 5000, z = 0}, {name = "other_worlds_tweaks:comet_ice"})
	minetest.set_node({x = -1, y = 5000, z = 0}, {name = "other_worlds_tweaks:rich_iron_ore"})
	minetest.set_node({x = 0, y = 5002, z = 0}, {name = "other_worlds_tweaks:rich_mese_ore"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_false(scan.mask[minetest.hash_node_position({x = 1, y = 5000, z = 0})], "Comet ice excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = -1, y = 5000, z = 0})], "Rich iron ore excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 5002, z = 0})], "Rich mese ore excluded")
	assert_eq(scan.node_count, 2, "Only engine and backbone counted")
end)

-- Test 5: Protection Gating
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

-- Test 14: TechAge Liquid Tank NVM State Migration
run_test("TechAge Tank Migration: Liquid contents migrate to jump destination and origin NVM is purged", function()
	world_nodes = {}
	techage_nvm_store = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	local tank_pos = {x = 1, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(tank_pos, {name = "techage:ta4_tank"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 1200)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Populate source tank NVM
	local src_nvm = techage.get_nvm(tank_pos)
	src_nvm.liquid = {name = "techage:hydrogen", amount = 8500}

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds: " .. tostring(err))

	local dest_tank_pos = {x = 1, y = 1200, z = 0}
	assert_eq(minetest.get_node(dest_tank_pos).name, "techage:ta4_tank", "Tank exists at destination")

	local dst_nvm = techage.get_nvm(dest_tank_pos)
	assert_true(dst_nvm.liquid ~= nil, "Destination tank retains liquid table")
	assert_eq(dst_nvm.liquid.name, "techage:hydrogen", "Destination tank liquid type is hydrogen")
	assert_eq(dst_nvm.liquid.amount, 8500, "Destination tank liquid amount is 8500")

	-- Origin NVM is completely purged
	assert_false(techage.has_nvm(tank_pos), "Origin tank NVM memory purged")
end)

-- Test 15: TechAge Active Inverter & Battery Continuity
run_test("TechAge Machine Continuity: Active inverters and battery accumulators retain state and restart timers", function()
	world_nodes = {}
	techage_nvm_store = {}
	node_timers = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	local inv_pos = {x = 1, y = 1000, z = 0}
	local accu_pos = {x = 2, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(inv_pos, {name = "techage:ta4_solar_inverter"})
	minetest.set_node(accu_pos, {name = "techage:ta3_akku"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 1500)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Set inverter and accumulator active NVM
	local inv_nvm = techage.get_nvm(inv_pos)
	inv_nvm.techage_state = techage.RUNNING
	inv_nvm.max_power = 100
	inv_nvm.provided = 80

	local accu_nvm = techage.get_nvm(accu_pos)
	accu_nvm.running = true
	accu_nvm.capa = 1500

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds: " .. tostring(err))

	local dest_inv_pos = {x = 1, y = 1500, z = 0}
	local dest_accu_pos = {x = 2, y = 1500, z = 0}

	local dst_inv_nvm = techage.get_nvm(dest_inv_pos)
	assert_eq(dst_inv_nvm.techage_state, techage.RUNNING, "Inverter state remains RUNNING")
	assert_eq(dst_inv_nvm.max_power, 100, "Inverter max power retained")

	local dst_accu_nvm = techage.get_nvm(dest_accu_pos)
	assert_eq(dst_accu_nvm.running, true, "Accu running state retained")
	assert_eq(dst_accu_nvm.capa, 1500, "Accu capa retained")

	-- Node timer started at destination
	local inv_timer = minetest.get_node_timer(dest_inv_pos)
	assert_true(inv_timer:is_started(), "Inverter node timer started at destination")
end)

-- Test 16: TechAge Network Cache Invalidation at Origin & Gated Destination Update
run_test("TechAge Network Invalidation: Origin network caches cleared across directions and destination gated", function()
	world_nodes = {}
	techage_nvm_store = {}
	networks_updated = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	local cable_pos = {x = 1, y = 1000, z = 0}
	local glass_pos = {x = 2, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(cable_pos, {name = "techage:ta4_solar_inverter"})
	minetest.set_node(glass_pos, {name = "default:glass"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 1200)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds")

	local origin_hash = minetest.hash_node_position(cable_pos)
	local dest_cable_hash = minetest.hash_node_position({x = 1, y = 1200, z = 0})
	local dest_glass_hash = minetest.hash_node_position({x = 2, y = 1200, z = 0})

	-- Origin invalidated across all direction indices 0..6 (7 calls per registered network)
	assert_true(networks_updated[origin_hash] ~= nil and networks_updated[origin_hash] >= 7, "Origin network cache invalidated across 0..6")
	-- Destination network refreshed for cable/inverter
	assert_true(networks_updated[dest_cable_hash] ~= nil and networks_updated[dest_cable_hash] > 0, "Destination network cache refreshed")
	-- Destination generic glass node NOT updated to avoid metadata pollution
	assert_true(networks_updated[dest_glass_hash] == nil, "Destination non-network node ignored by network updater")
end)

-- Test 17: Uncharted Sector Emergence Return Contract
run_test("Uncharted Emergence: Returns false with descriptive status, triggers emergence, and executes deferred jump", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 0)
	meta:set_int("y", 2000)
	meta:set_int("z", 0)
	meta:set_int("powerstorage", 100000)

	-- Destination node is 'ignore' (uncharted)
	local dest_pos = {x = 0, y = 2000, z = 0}
	minetest.set_node(dest_pos, {name = "ignore"})

	local emergence_callback_called = false
	minetest.emerge_area = function(p1, p2, cb)
		-- Simulate background map emergence replacing ignore with air
		minetest.set_node(dest_pos, {name = "air"})
		cb(p1, 0, 0, nil)
		emergence_callback_called = true
	end

	local ok, msg = jumpdrive.execute_jump(engine_pos, nil)
	assert_false(ok, "execute_jump returns false on uncharted destination")
	assert_true(type(msg) == "string", "msg is a string, preventing arithmetic errors in engine.lua")
	assert_true(string.find(msg, "uncharted") ~= nil, "msg explains uncharted sector")
	assert_true(emergence_callback_called, "emergence callback executed")
	assert_eq(minetest.get_node(dest_pos).name, "jumpdrive:engine", "deferred jump movement placed engine at destination")
end)

-- Test 18: Beacon Coordinate Migration on Jump
run_test("Beacon Migration: Beacon coordinates migrate during ship jump", function()
	world_nodes = {}
	local engine_pos = {x = 10, y = 20, z = 30}
	local beacon_pos = {x = 11, y = 20, z = 30}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(beacon_pos, {name = "jumpdrive_tweaks:beacon"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 10)
	meta:set_int("y", 6200)
	meta:set_int("z", 30)
	meta:set_int("radius", 5)
	meta:set_int("powerstorage", 500000)

	local active_beacons = jumpdrive_tweaks.get_active_beacons()
	active_beacons["11,20,30"] = {
		pos = {x = 11, y = 20, z = 30},
		name = "OrbitalVessel",
		owner = "Astronaut",
	}
	-- External stationary beacon near the ship (5 blocks away, not in ship_scan.mask)
	active_beacons["15,20,30"] = {
		pos = {x = 15, y = 20, z = 30},
		name = "SpaceStationBeacon",
		owner = "Astronaut",
	}

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds: " .. tostring(err))

	-- Origin beacon location removed
	assert_true(active_beacons["11,20,30"] == nil, "Origin beacon coordinate purged")
	-- Destination beacon location registered at Y=6200
	assert_true(active_beacons["11,6200,30"] ~= nil, "Destination beacon coordinate registered")
	assert_eq(active_beacons["11,6200,30"].name, "OrbitalVessel", "Beacon name preserved")
	assert_eq(active_beacons["11,6200,30"].owner, "Astronaut", "Beacon owner preserved")

	-- External stationary beacon must remain in place at X=15, Y=20, Z=30
	assert_true(active_beacons["15,20,30"] ~= nil, "External stationary beacon remains at origin")
	assert_true(active_beacons["15,6200,30"] == nil, "External stationary beacon was not incorrectly migrated")
end)

-- Test 19: Terrestrial Beacon Altitude Filter (Ignore ground beacons in space HUD)
run_test("Beacon Altitude Filter: Ground beacons (Y < 1000) are excluded from orbital HUD candidates", function()
	local active_beacons = jumpdrive_tweaks.get_active_beacons()
	active_beacons["0,10,0"] = {
		pos = {x = 0, y = 10, z = 0},
		name = "GroundBase",
		owner = "Astronaut",
	}
	active_beacons["0,5000,0"] = {
		pos = {x = 0, y = 5000, z = 0},
		name = "OrbitalStation",
		owner = "Astronaut",
	}

	local ppos = {x = 0, y = 1200, z = 0}
	local pname = "Astronaut"
	local best_beacon = nil
	local min_dist = math.huge

	for key, bdata in pairs(active_beacons) do
		if bdata.pos and bdata.pos.y >= 1000 then
			local dist = vector.distance(ppos, bdata.pos)
			if bdata.owner == pname then
				if dist < min_dist then
					min_dist = dist
					best_beacon = bdata
				end
			end
		end
	end

	assert_true(best_beacon ~= nil, "Orbital beacon identified")
	assert_eq(best_beacon.name, "OrbitalStation", "Ground beacon ignored in favor of orbital beacon")
	assert_eq(best_beacon.pos.y, 5000, "Orbital beacon altitude matches")
end)

-- Test 20: Beacon Priority Resolution (Owned over Unowned, and closest Unowned)
run_test("Beacon Priority: Player-owned beacon prioritized over unowned beacons, and closest unowned selected", function()
	local active_beacons = jumpdrive_tweaks.get_active_beacons()
	-- Clear beacons
	for k in pairs(active_beacons) do active_beacons[k] = nil end

	-- Unowned beacon 1 (dist = 300)
	active_beacons["0,1300,0"] = {
		pos = {x = 0, y = 1300, z = 0},
		name = "Derelict Near",
		owner = "",
	}
	-- Unowned beacon 2 (dist = 100)
	active_beacons["0,1100,0"] = {
		pos = {x = 0, y = 1100, z = 0},
		name = "Derelict Closest",
		owner = "",
	}
	-- Player owned beacon (dist = 600)
	active_beacons["0,1600,0"] = {
		pos = {x = 0, y = 1600, z = 0},
		name = "Player Ship",
		owner = "Astronaut",
	}

	local ppos = {x = 0, y = 1000, z = 0}
	local pname = "Astronaut"

	-- Logic from beacon.lua globalstep
	local best_owned = nil
	local min_owned_dist = math.huge
	local best_unowned = nil
	local min_unowned_dist = 10000

	for key, bdata in pairs(active_beacons) do
		if bdata.pos and bdata.pos.y >= 1000 then
			local dist = vector.distance(ppos, bdata.pos)
			if bdata.owner == pname then
				if dist < min_owned_dist then
					min_owned_dist = dist
					best_owned = bdata
				end
			elseif (not bdata.owner or bdata.owner == "") and dist < min_unowned_dist then
				min_unowned_dist = dist
				best_unowned = bdata
			end
		end
	end

	local best_beacon = best_owned or best_unowned
	assert_true(best_beacon ~= nil, "Best beacon resolved")
	assert_eq(best_beacon.name, "Player Ship", "Player-owned beacon selected over closer unowned distress beacons")

	-- When player has no owned beacons, closest unowned beacon is chosen
	pname = "OtherPlayer"
	best_owned = nil
	min_owned_dist = math.huge
	best_unowned = nil
	min_unowned_dist = 10000

	for key, bdata in pairs(active_beacons) do
		if bdata.pos and bdata.pos.y >= 1000 then
			local dist = vector.distance(ppos, bdata.pos)
			if bdata.owner == pname then
				if dist < min_owned_dist then
					min_owned_dist = dist
					best_owned = bdata
				end
			elseif (not bdata.owner or bdata.owner == "") and dist < min_unowned_dist then
				min_unowned_dist = dist
				best_unowned = bdata
			end
		end
	end

	best_beacon = best_owned or best_unowned
	assert_true(best_beacon ~= nil, "Unowned beacon resolved for third-party player")
	assert_eq(best_beacon.name, "Derelict Closest", "Closest unowned beacon selected (dist 100 over dist 300)")
end)

-- Test 21: Disconnected Floating Terrain & Atmosphere Exclusion
run_test("Disconnected Floating Terrain & Atmosphere Exclusion: Atmos clouds and floating asteroid rock excluded", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 0, y = 1001, z = 0}, {name = "jumpdrive:backbone"})

	-- Disconnected floating comet atmosphere 2 blocks above
	minetest.set_node({x = 0, y = 1003, z = 0}, {name = "asteroid:atmos"})
	minetest.set_node({x = 1, y = 1003, z = 0}, {name = "asteroid:atmos"})

	-- Disconnected floating asteroid stone 2 blocks to the side (separated by vacuum)
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "asteroid:stone"})
	minetest.set_node({x = 2, y = 1001, z = 0}, {name = "asteroid:redcobble"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine included")
	assert_true(scan.mask[minetest.hash_node_position({x = 0, y = 1001, z = 0})], "Backbone included")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 1003, z = 0})], "Disconnected asteroid:atmos excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 1, y = 1003, z = 0})], "Disconnected asteroid:atmos excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 2, y = 1000, z = 0})], "Disconnected asteroid:stone excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 2, y = 1001, z = 0})], "Disconnected asteroid:redcobble excluded")
	assert_eq(scan.node_count, 2, "Only 2 contiguous vessel blocks captured")
end)

-- Test 22: Landed Craft Surface Separation on Asteroid
run_test("Landed Craft Surface Separation: Touching asteroid ground terminated at hull interface", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1001, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1001, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 0, y = 1000, z = 0}, {name = "default:stonebrick"}) -- landing gear
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "default:stonebrick"}) -- landing gear

	-- Asteroid terrain directly touching landing gear at Y=999
	minetest.set_node({x = 0, y = 999, z = 0}, {name = "asteroid:redstone"})
	minetest.set_node({x = 1, y = 999, z = 0}, {name = "asteroid:cobble"})
	minetest.set_node({x = 2, y = 999, z = 0}, {name = "asteroid:dust"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine included")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1001, z = 0})], "Backbone included")
	assert_true(scan.mask[minetest.hash_node_position({x = 0, y = 1000, z = 0})], "Landing gear 1 included")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1000, z = 0})], "Landing gear 2 included")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 999, z = 0})], "Touching asteroid:redstone excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 1, y = 999, z = 0})], "Touching asteroid:cobble excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 2, y = 999, z = 0})], "Adjacent asteroid:dust excluded")
	assert_eq(scan.node_count, 4, "Only 4 ship blocks captured without pulling asteroid terrain")
end)

-- Test 23: Earth Ground Surface Separation
run_test("Earth Ground Surface Separation: Parked vessel excludes touching dirt, grass, and trees", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 11, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 0, y = 12, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 0, y = 10, z = 0}, {name = "default:stonebrick"}) -- strut

	-- Ground blocks directly touching strut at Y=9
	minetest.set_node({x = 0, y = 9, z = 0}, {name = "default:dirt_with_grass"})
	minetest.set_node({x = 0, y = 8, z = 0}, {name = "default:dirt"})
	minetest.set_node({x = 0, y = 7, z = 0}, {name = "default:stone"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine included")
	assert_true(scan.mask[minetest.hash_node_position({x = 0, y = 12, z = 0})], "Backbone included")
	assert_true(scan.mask[minetest.hash_node_position({x = 0, y = 10, z = 0})], "Strut included")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 9, z = 0})], "Grass dirt ground excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 8, z = 0})], "Dirt underground excluded")
	assert_false(scan.mask[minetest.hash_node_position({x = 0, y = 7, z = 0})], "Stone underground excluded")
	assert_eq(scan.node_count, 3, "Only 3 ship blocks captured")
end)

-- Test 24: Contiguous Hull & Truss Propagation
run_test("Contiguous Hull & Truss Propagation: Multi-block chain branching off backbone is captured", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 1, y = 1001, z = 0}, {name = "default:stonebrick"}) -- bridge floor
	minetest.set_node({x = 1, y = 1002, z = 0}, {name = "default:glass"})      -- cockpit canopy
	minetest.set_node({x = 1, y = 1000, z = 1}, {name = "jumpdrive_tweaks:fuel_tank"}) -- tank attached to backbone

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)

	assert_true(scan.mask[minetest.hash_node_position(engine_pos)], "Engine captured")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1000, z = 0})], "Backbone captured")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1001, z = 0})], "Bridge floor captured")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1002, z = 0})], "Cockpit canopy glass captured")
	assert_true(scan.mask[minetest.hash_node_position({x = 1, y = 1000, z = 1})], "Fuel tank captured")
	assert_eq(#scan.fuel_tanks, 1, "1 fuel tank recorded")
	assert_eq(scan.node_count, 5, "5 contiguous components captured")
end)

-- Test 25: Beacon Placement and Registry Update
run_test("Beacon Node Placement: after_place_node registers beacon metadata and active beacon entry", function()
	local beacon_pos = {x = 10, y = 1000, z = 20}
	local placer = {
		is_player = function() return true end,
		get_player_name = function() return "Astronaut" end,
	}

	minetest.set_node(beacon_pos, {name = "jumpdrive_tweaks:beacon"})
	local beacon_def = minetest.registered_nodes["jumpdrive_tweaks:beacon"]
	assert_true(beacon_def ~= nil, "Beacon node registered")
	beacon_def.after_place_node(beacon_pos, placer)

	local meta = minetest.get_meta(beacon_pos)
	assert_eq(meta:get_string("owner"), "Astronaut", "Beacon owner set in metadata")
	assert_eq(meta:get_string("ship_name"), "Astronaut's Ship", "Beacon ship_name set in metadata")

	local active = jumpdrive_tweaks.get_active_beacons()
	local key = string.format("%d,%d,%d", beacon_pos.x, beacon_pos.y, beacon_pos.z)
	assert_true(active[key] ~= nil, "Beacon registered in active_beacons table")
	assert_eq(active[key].name, "Astronaut's Ship", "Active beacon name matches default name")
	assert_eq(active[key].owner, "Astronaut", "Active beacon owner matches placer")
end)

-- Test 26: Unowned Derelict Beacon Migration Immunity
run_test("Unowned Beacon Migration Immunity: Derelict distress beacons never migrate with player ship", function()
	world_nodes = {}
	local engine_pos = {x = 10, y = 5000, z = 10}
	local beacon_pos = {x = 11, y = 5000, z = 10}
	local derelict_beacon_pos = {x = 12, y = 5000, z = 10}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node(beacon_pos, {name = "jumpdrive_tweaks:beacon"})
	minetest.set_node(derelict_beacon_pos, {name = "jumpdrive_tweaks:beacon"})

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 10)
	meta:set_int("y", 6200)
	meta:set_int("z", 10)
	meta:set_int("radius", 5)
	meta:set_int("powerstorage", 500000)

	local active_beacons = jumpdrive_tweaks.get_active_beacons()
	for k in pairs(active_beacons) do active_beacons[k] = nil end

	-- Player-owned beacon on the ship (in mask)
	active_beacons["11,5000,10"] = {
		pos = {x = 11, y = 5000, z = 10},
		name = "Player Vessel",
		owner = "Astronaut",
	}
	-- Unowned derelict beacon also in mask (adjacent to ship)
	active_beacons["12,5000,10"] = {
		pos = {x = 12, y = 5000, z = 10},
		name = "Derelict Heavy Freighter [DISTRESS]",
		owner = "",
	}

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds: " .. tostring(err))

	-- Player's beacon migrated
	assert_true(active_beacons["11,5000,10"] == nil, "Player beacon origin purged")
	assert_true(active_beacons["11,6200,10"] ~= nil, "Player beacon migrated to destination")
	assert_eq(active_beacons["11,6200,10"].name, "Player Vessel", "Player beacon name preserved")

	-- Derelict beacon stays at original position
	assert_true(active_beacons["12,5000,10"] ~= nil, "Derelict beacon remains at original position")
	assert_eq(active_beacons["12,5000,10"].name, "Derelict Heavy Freighter [DISTRESS]", "Derelict beacon name unchanged")
	assert_true(active_beacons["12,6200,10"] == nil, "Derelict beacon was NOT migrated to destination")
end)

-- Test 28: Reverse Engine Discovery (Direct Backbone vs Hull Flood-Fill vs Isolation)
run_test("Reverse Engine Discovery: Backbone traversal, hull propagation, and terrain isolation", function()
	world_nodes = {}
	local engine_pos = {x = 0, y = 1000, z = 0}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 3, y = 1000, z = 0}, {name = "jumpdrive_tweaks:bridge_console"})

	-- Case A: Direct backbone traversal from bridge console
	local found, err = jumpdrive_tweaks.find_connected_engine({x = 3, y = 1000, z = 0}, true)
	assert_true(found ~= nil, "Engine found from bridge console on backbone")
	assert_eq(found.x, 0, "Discovered engine X matches")
	assert_eq(found.y, 1000, "Discovered engine Y matches")
	assert_eq(found.z, 0, "Discovered engine Z matches")

	-- Case B: Console connected via solid hull blocks (default:stonebrick) without direct backbone line
	world_nodes = {}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 0, y = 1001, z = 0}, {name = "default:stonebrick"})
	minetest.set_node({x = 1, y = 1001, z = 0}, {name = "default:stonebrick"})
	minetest.set_node({x = 2, y = 1001, z = 0}, {name = "default:stonebrick"})
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "jumpdrive_tweaks:jump_lever"})

	-- Backbone-only should fail
	local found_bb, err_bb = jumpdrive_tweaks.find_connected_engine({x = 2, y = 1000, z = 0}, true)
	assert_true(found_bb == nil, "Backbone-only search fails on hull-only connection")

	-- Full hull search should succeed
	local found_hull, err_hull = jumpdrive_tweaks.find_connected_engine({x = 2, y = 1000, z = 0}, false)
	assert_true(found_hull ~= nil, "Hull flood-fill discovers connected engine")
	assert_eq(found_hull.x, 0, "Discovered engine X matches")

	-- Case C: Console on separate vessel across asteroid stone terrain should NOT discover engine
	world_nodes = {}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 1, y = 1000, z = 0}, {name = "default:stone"}) -- Asteroid terrain
	minetest.set_node({x = 2, y = 1000, z = 0}, {name = "jumpdrive_tweaks:bridge_console"})

	local found_terrain, err_terrain = jumpdrive_tweaks.find_connected_engine({x = 2, y = 1000, z = 0}, false)
	assert_true(found_terrain == nil, "Terrain interface prevents bridge console binding across asteroid")
end)

-- Test 29: Bridge Controls Integration in Spacecraft Scan & Jump Translation
run_test("Bridge Controls: Console and lever scanned and migrated during hyperjump", function()
	world_nodes = {}
	local engine_pos = {x = 10, y = 5000, z = 10}
	minetest.set_node(engine_pos, {name = "jumpdrive:engine"})
	minetest.set_node({x = 11, y = 5000, z = 10}, {name = "jumpdrive:backbone"})
	minetest.set_node({x = 12, y = 5000, z = 10}, {name = "jumpdrive_tweaks:bridge_console"})
	minetest.set_node({x = 13, y = 5000, z = 10}, {name = "jumpdrive_tweaks:jump_lever"})

	local scan = jumpdrive_tweaks.scan_spacecraft(engine_pos, 3)
	assert_eq(scan.node_count, 4, "Scan captures engine, backbone, bridge console, and jump lever")

	local meta = minetest.get_meta(engine_pos)
	meta:set_int("x", 10)
	meta:set_int("y", 6500)
	meta:set_int("z", 10)
	meta:set_int("radius", 5)
	meta:set_int("powerstorage", 500000)

	local ok, err = jumpdrive.execute_jump(engine_pos, nil)
	assert_true(ok, "execute_jump succeeds: " .. tostring(err))

	assert_eq(minetest.get_node({x = 12, y = 6500, z = 10}).name, "jumpdrive_tweaks:bridge_console", "Bridge console translated to destination")
	assert_eq(minetest.get_node({x = 13, y = 6500, z = 10}).name, "jumpdrive_tweaks:jump_lever", "Jump lever translated to destination")
	assert_eq(minetest.get_node({x = 12, y = 5000, z = 10}).name, "air", "Origin bridge console cleared to air")
	assert_eq(minetest.get_node({x = 13, y = 5000, z = 10}).name, "air", "Origin jump lever cleared to air")
end)

-- Test 30: Hyperjump Sensory Feedback & FX Lifecycle
run_test("Hyperjump Feedback: Spool scaling, ambient HUD glow lifecycle, exterior shockwave ring, and clean abort", function()
	-- 1. Spool duration scaling
	assert_eq(jumpdrive_tweaks.get_spool_duration(100), 2.2, "Short jump (< 1km) is 2.2s")
	assert_eq(jumpdrive_tweaks.get_spool_duration(1000), 2.2, "1km jump is 2.2s")
	assert_eq(jumpdrive_tweaks.get_spool_duration(3000), 3.0, "3km jump is 3.0s")
	assert_eq(jumpdrive_tweaks.get_spool_duration(5000), 3.0, "5km jump is 3.0s")
	assert_eq(jumpdrive_tweaks.get_spool_duration(12000), 4.0, "Long jump (> 5km) is 4.0s")

	-- 2. Mock player with HUD
	local hud_added = {}
	local hud_removed = {}
	local mock_player = {
		is_player = function() return true end,
		get_player_name = function() return "Astronaut" end,
		get_pos = function() return {x = 10, y = 1000, z = 10} end,
		hud_add = function(self, def)
			local id = #hud_added + 1
			table.insert(hud_added, def)
			return id
		end,
		hud_remove = function(self, id)
			table.insert(hud_removed, id)
		end,
	}

	minetest.get_connected_players = function() return {mock_player} end
	minetest.get_player_by_name = function(name)
		if name == "Astronaut" then return mock_player end
		return nil
	end

	local passengers = jumpdrive_tweaks.get_ship_passengers({x = 9, y = 999, z = 9}, {x = 11, y = 1001, z = 11})
	assert_eq(#passengers, 1, "Passenger inside ship bounding box detected")

	-- 3. Spool FX start
	local ship_scan = {
		min_pos = {x = 9, y = 999, z = 9},
		max_pos = {x = 11, y = 1001, z = 11},
	}
	local fx_handle = jumpdrive_tweaks.start_spool_fx({x = 10, y = 1000, z = 10}, 8000, ship_scan)
	assert_true(fx_handle ~= nil, "FX handle created")
	assert_eq(fx_handle.spool_time, 4.0, "Spool time matches 4.0s")
	assert_eq(#hud_added, 1, "Ambient glow HUD added to passenger")
	assert_eq(hud_added[1].text, "jumpdrive_warp_glow.png", "Ambient glow texture used")

	-- 4. Abort cleanup
	jumpdrive_tweaks.abort_spool_fx(fx_handle)
	assert_eq(#hud_removed, 1, "HUD removed on abort")
	assert_false(fx_handle.active, "FX handle deactivated")

	-- 5. Shockwave perimeter calculation (strictly outside ship hull)
	local spawned_particles = {}
	minetest.add_particle = function(def)
		table.insert(spawned_particles, def)
	end

	local center = {x = 100, y = 2000, z = 100}
	jumpdrive_tweaks.spawn_external_shockwave(center, {x = 90, y = 1995, z = 90}, {x = 110, y = 2005, z = 110})
	assert_true(#spawned_particles >= 48, "48 shockwave particles spawned")

	-- 6. Nil-safety resilience
	assert_eq(jumpdrive_tweaks.start_spool_fx({x=0,y=0,z=0}, 500, nil), nil, "Nil ship_scan returns nil safely")
	assert_eq(jumpdrive_tweaks.start_spool_fx({x=0,y=0,z=0}, 500, {}), nil, "Empty ship_scan returns nil safely")
	assert_eq(#jumpdrive_tweaks.get_ship_passengers({}, {}), 0, "Empty min_pos/max_pos tables return 0 passengers")
	jumpdrive_tweaks.abort_spool_fx(nil)
	jumpdrive_tweaks.spawn_external_shockwave({}, {}, {})
	jumpdrive_tweaks.on_jump_discontinuity({x=0,y=0,z=0}, {x=10,y=0,z=0}, nil, nil, nil)
	jumpdrive_tweaks.on_jump_discontinuity({x=0,y=0,z=0}, {x=10,y=0,z=0}, {min_pos = {x=0,y=0,z=0}}, nil, nil)
	jumpdrive_tweaks.on_jump_discontinuity({}, {}, {min_pos = {}, max_pos = {}}, {}, nil)
end)

print(string.format("\nShip Tracker Test Suite Complete: %d passed, %d failed.\n", tests_passed, tests_failed))

if tests_failed > 0 then
	error("Test suite failed!")
end


