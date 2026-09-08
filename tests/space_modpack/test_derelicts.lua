-- tests/test_derelicts.lua
-- Unit tests for procedural space derelicts generation, rotation math, clearance checks, and loot distribution

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error(string.format("ASSERTION FAILED: %s\nExpected: %s (%s)\nActual:   %s (%s)",
			msg or "Values not equal",
			tostring(expected), type(expected),
			tostring(actual), type(actual)))
	end
end

local function assert_true(cond, msg)
	if not cond then
		error("ASSERTION FAILED: " .. (msg or "Expected true, got false/nil"))
	end
end

-- Mock ItemStack
local function MockItemStack(itemstring)
	itemstring = itemstring or ""
	if itemstring == "" then
		return {
			itemstring = "",
			name = "",
			count = 0,
			is_empty = function(self) return true end,
			get_name = function(self) return "" end,
			get_count = function(self) return 0 end,
		}
	end
	local name, count = itemstring:match("^([^%s]+)%s*(%d*)$")
	count = tonumber(count) or 1
	return {
		itemstring = itemstring,
		name = name or itemstring,
		count = count,
		is_empty = function(self) return (self.name == "" or self.count <= 0) end,
		get_name = function(self) return self.name end,
		get_count = function(self) return self.count end,
	}
end
ItemStack = MockItemStack

-- Mock Inventory and NodeMeta
local node_metas = {}
local function create_mock_meta()
	local inventories = {}
	local inv_sizes = {}
	local strings = {}
	local ints = {}
	local inv_obj = {
		set_size = function(inv_self, listname, size)
			inventories[listname] = inventories[listname] or {}
			inv_sizes[listname] = size
		end,
		get_size = function(inv_self, listname)
			return inv_sizes[listname] or 0
		end,
		get_stack = function(inv_self, listname, i)
			return (inventories[listname] and inventories[listname][i]) or MockItemStack("")
		end,
		set_stack = function(inv_self, listname, i, stack)
			inventories[listname] = inventories[listname] or {}
			inventories[listname][i] = stack
		end,
		get_list = function(inv_self, listname)
			return inventories[listname] or {}
		end,
	}
	return {
		get_inventory = function(self)
			return inv_obj
		end,
		set_string = function(self, key, val) strings[key] = val end,
		get_string = function(self, key) return strings[key] or "" end,
		set_int = function(self, key, val) ints[key] = val end,
		get_int = function(self, key) return ints[key] or 0 end,
	}
end

-- Mock VoxelArea
VoxelArea = {}
function VoxelArea:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	o.ystride = o.MaxEdge.x - o.MinEdge.x + 1
	o.zstride = o.ystride * (o.MaxEdge.y - o.MinEdge.y + 1)
	return o
end

function VoxelArea:index(x, y, z)
	local i = (z - self.MinEdge.z) * self.zstride +
	          (y - self.MinEdge.y) * self.ystride +
	          (x - self.MinEdge.x) + 1
	return i
end

function VoxelArea:containsi(x, y, z)
	return x >= self.MinEdge.x and x <= self.MaxEdge.x and
	       y >= self.MinEdge.y and y <= self.MaxEdge.y and
	       z >= self.MinEdge.z and z <= self.MaxEdge.z
end

-- Mock Minetest Environment
local content_ids = {
	["air"] = 0,
	["default:steelblock"] = 1,
	["default:bronzeblock"] = 2,
	["default:copperblock"] = 3,
	["default:obsidian_glass"] = 4,
	["default:glass"] = 5,
	["techage:chest_ta3"] = 6,
	["techage:chest_ta4"] = 7,
	["techage:ta4_solar_minicell"] = 8,
	["techage:ta4_solar_carrier"] = 9,
	["techage:ta4_electrolyzer"] = 10,
	["jumpdrive_tweaks:fuel_tank"] = 11,
	["asteroid:stone"] = 12,
	["vacuum:vacuum"] = 13,
	["ignore"] = 14,
	["techage:ta4_solar_module"] = 15,
}

local mock_settings = {
	["space_derelict_spawn_rate"] = "45",
}

minetest = {
	get_content_id = function(name)
		return content_ids[name] or 99
	end,
	get_modpath = function(mod)
		if mod == "techage" or mod == "jumpdrive_tweaks" or mod == "airtanks" or mod == "vacuum" then
			return "mods/" .. mod
		end
		return nil
	end,
	registered_nodes = {
		["techage:chest_ta3"] = {description = "TA3 Chest"},
		["techage:chest_ta4"] = {description = "TA4 Chest"},
		["techage:ta4_solar_minicell"] = {description = "Solar Minicell"},
		["techage:ta4_solar_carrier"] = {description = "Solar Carrier"},
		["techage:ta4_solar_module"] = {description = "Solar Module"},
		["techage:ta4_electrolyzer"] = {description = "Electrolyzer"},
		["jumpdrive_tweaks:fuel_tank"] = {description = "Fuel Tank"},
	},
	settings = {
		get = function(self, key)
			return mock_settings[key]
		end,
	},
	get_meta = function(pos)
		local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		if not node_metas[key] then
			node_metas[key] = create_mock_meta()
		end
		return node_metas[key]
	end,
	log = function(lvl, msg) end,
}

-- Load derelicts module
local derelicts = dofile("mods/space_modpack/other_worlds_tweaks/derelicts.lua")
assert_true(derelicts ~= nil, "derelicts module loaded successfully")

print("[TEST 1] Testing 4-way Yaw Coordinate Rotation Math...")
local cmin = {x = 0, y = 5000, z = 0}
local cmax = {x = 79, y = 5079, z = 79}
local area = VoxelArea:new{MinEdge = cmin, MaxEdge = cmax}
local total_nodes = (cmax.x - cmin.x + 1) * (cmax.y - cmin.y + 1) * (cmax.z - cmin.z + 1)

local data = {}
local param2_data = {}
for i = 1, total_nodes do
	data[i] = 0
	param2_data[i] = 0
end

local center = {x = 40, y = 5040, z = 40}
local dummy_schem = {
	name = "test_schem",
	radius = 2,
	nodes = {
		{dx = 1, dy = 0, dz = 0, cid = 1, param2 = 0, is_chest = false},
		{dx = 0, dy = 1, dz = 2, cid = 2, param2 = 1, is_chest = true, tier = "probe"},
	}
}

-- Rotation 0 (East +X)
local chests0 = derelicts.place_schematic(center, dummy_schem, 0, data, param2_data, area)
assert_eq(data[area:index(41, 5040, 40)], 1, "Rot 0 node 1 placement")
assert_eq(data[area:index(40, 5041, 42)], 2, "Rot 0 node 2 placement")
assert_eq(#chests0, 1, "Rot 0 chest count")
assert_eq(chests0[1].pos.x, 40, "Rot 0 chest X")
assert_eq(chests0[1].pos.y, 5041, "Rot 0 chest Y")
assert_eq(chests0[1].pos.z, 42, "Rot 0 chest Z")

-- Rotation 1 (90 deg: dx=1,dz=0 -> rx=0,rz=-1; dx=0,dz=2 -> rx=2,rz=0)
for i = 1, total_nodes do data[i] = 0; param2_data[i] = 0 end
local chests1 = derelicts.place_schematic(center, dummy_schem, 1, data, param2_data, area)
assert_eq(data[area:index(40, 5040, 39)], 1, "Rot 1 node 1 placement")
assert_eq(data[area:index(42, 5041, 40)], 2, "Rot 1 node 2 placement")
assert_eq(param2_data[area:index(42, 5041, 40)], (1 + 1) % 4, "Rot 1 param2 rotated")

-- Rotation 2 (180 deg)
for i = 1, total_nodes do data[i] = 0; param2_data[i] = 0 end
local chests2 = derelicts.place_schematic(center, dummy_schem, 2, data, param2_data, area)
assert_eq(data[area:index(39, 5040, 40)], 1, "Rot 2 node 1 placement")
assert_eq(data[area:index(40, 5041, 38)], 2, "Rot 2 node 2 placement")

-- Rotation 3 (270 deg)
for i = 1, total_nodes do data[i] = 0; param2_data[i] = 0 end
local chests3 = derelicts.place_schematic(center, dummy_schem, 3, data, param2_data, area)
assert_eq(data[area:index(40, 5040, 41)], 1, "Rot 3 node 1 placement")
assert_eq(data[area:index(38, 5041, 40)], 2, "Rot 3 node 2 placement")
print("  ✓ Rotation math verified for all 4 cardinal angles")

print("[TEST 2] Testing Chest Loot Population Engine & Loot Variability for all tiers...")
node_metas = {}
local probe_pos = {x = 10, y = 5000, z = 10}
derelicts.populate_chest(probe_pos, "probe")
local probe_meta = minetest.get_meta(probe_pos)
local probe_inv = probe_meta:get_inventory()
local probe_items = probe_inv:get_list("main")
local probe_count = 0
for _, item in pairs(probe_items) do
	if not item:is_empty() then
		probe_count = probe_count + 1
		assert_true(item:get_name() ~= nil, "Probe item has valid name: " .. tostring(item:get_name()))
	end
end
assert_true(probe_count >= 3, "Probe chest populated with at least 3 loot stacks")
assert_true(probe_meta:get_string("formspec") ~= "", "Probe chest has formspec string")
assert_true(probe_meta:get_string("infotext") ~= "", "Probe chest has infotext string")
assert_eq(probe_meta:get_int("public"), 1, "Probe chest is set to public")

local shuttle_pos = {x = 20, y = 5000, z = 20}
derelicts.populate_chest(shuttle_pos, "shuttle")
local shuttle_meta = minetest.get_meta(shuttle_pos)
local shuttle_inv = shuttle_meta:get_inventory()
local shuttle_items = shuttle_inv:get_list("main")
local shuttle_has_hydrogen = false
for _, item in pairs(shuttle_items) do
	if item:get_name() == "techage:cylinder_small_hydrogen" then
		shuttle_has_hydrogen = true
	end
end
assert_true(shuttle_has_hydrogen, "Shuttle chest contains hydrogen propellant cylinders")
assert_true(shuttle_meta:get_string("formspec") ~= "", "Shuttle chest has formspec string")
assert_eq(shuttle_meta:get_int("public"), 1, "Shuttle chest is set to public")

local lab_pos = {x = 30, y = 5000, z = 30}
derelicts.populate_chest(lab_pos, "lab")
local lab_meta = minetest.get_meta(lab_pos)
local lab_inv = lab_meta:get_inventory()
local lab_items = lab_inv:get_list("main")
local lab_has_high_tech = false
for _, item in pairs(lab_items) do
	if item:get_name() == "techage:ta4_carbon_fiber" or item:get_name() == "techage:ta4_wlanchip" then
		lab_has_high_tech = true
	end
end
assert_true(lab_has_high_tech, "Lab chest contains high-tech materials/chips")
assert_true(lab_meta:get_string("formspec") ~= "", "Lab chest has formspec string")
assert_eq(lab_meta:get_int("public"), 1, "Lab chest is set to public")
assert_eq(lab_inv:get_size("conf"), 50, "Lab chest conf inventory size initialized to 50")

-- Verify loot variability across multiple chests of same tier
local probe_variants = {}
for trial = 1, 10 do
	local ppos = {x = 100 + trial, y = 5000, z = 100}
	derelicts.populate_chest(ppos, "probe")
	local inv = minetest.get_meta(ppos):get_inventory()
	local names = {}
	for _, it in pairs(inv:get_list("main")) do
		if not it:is_empty() then
			table.insert(names, it:get_name() .. ":" .. it:get_count())
		end
	end
	table.sort(names)
	probe_variants[table.concat(names, ",")] = true
end
local variant_count = 0
for _ in pairs(probe_variants) do variant_count = variant_count + 1 end
assert_true(variant_count > 1, "Loot pool generates variable cache compositions across probe instances (found " .. variant_count .. " unique combinations)")
print("  ✓ Loot generation, randomized variability & UI formspec metadata verified for Probe, Shuttle, and Lab tiers")

print("[TEST 3] Testing Clearance Collision Filter...")
-- Fill chunk solid with stone
for i = 1, total_nodes do
	data[i] = 12 -- asteroid stone
end

-- Force mapgen in solid chunk -> clearance check must abort and place 0 nodes
math.randomseed(42)
local solid_placements = 0
for trial = 1, 100 do
	local chests = derelicts.generate_in_chunk(cmin, cmax, data, param2_data, area, "space")
	if #chests > 0 then
		solid_placements = solid_placements + 1
	end
end
assert_eq(solid_placements, 0, "Clearance check prevented derelict spawn inside solid asteroid core")
print("  ✓ Solid rock collision clearance check confirmed")

print("[TEST 4] Testing Chunk Generation in Space / Redsky / Deep Space layers with vacuum:vacuum...")
-- Fill chunk with vacuum:vacuum nodes
for i = 1, total_nodes do
	data[i] = 13 -- vacuum:vacuum
end

local placed_chests_count = 0
for trial = 1, 2000 do
	local chests = derelicts.generate_in_chunk(cmin, cmax, data, param2_data, area, "blackness")
	if chests and #chests > 0 then
		placed_chests_count = placed_chests_count + #chests
		for _, c in ipairs(chests) do
			derelicts.populate_chest(c.pos, c.tier)
		end
	end
end
assert_true(placed_chests_count > 0, "Procedural derelicts successfully placed in vacuum chunks")
print("  ✓ Procedural derelicts generation verified in open vacuum (" .. placed_chests_count .. " chests generated over 2000 trials)")

print("[TEST 5] Testing Small Sub-Volume Boundary Guard...")
local small_min = {x = 0, y = 5000, z = 0}
local small_max = {x = 4, y = 5004, z = 4}
local small_area = VoxelArea:new{MinEdge = small_min, MaxEdge = small_max}
local small_data = {}
for i = 1, 125 do small_data[i] = 0 end
local small_chests = derelicts.generate_in_chunk(small_min, small_max, small_data, nil, small_area, "space")
assert_eq(#small_chests, 0, "Boundary guard safely returned empty table without interval errors on small chunks")
print("  ✓ Small chunk dimension boundary guard confirmed")

print("[TEST 6] Testing Vacuum Air Fallback on Lab Tier (without airtanks)...")
local orig_get_modpath = minetest.get_modpath
minetest.get_modpath = function(mod)
	if mod == "airtanks" then return nil end
	return orig_get_modpath(mod)
end

node_metas = {}
local lab_fallback_pos = {x = 50, y = 5000, z = 50}
derelicts.populate_chest(lab_fallback_pos, "lab")
local lab_fb_inv = minetest.get_meta(lab_fallback_pos):get_inventory()
local lab_fb_items = lab_fb_inv:get_list("main")
local has_vacuum_bottle = false
for _, item in pairs(lab_fb_items) do
	if item:get_name() == "vacuum:air_bottle" then
		has_vacuum_bottle = true
	end
end
assert_true(has_vacuum_bottle, "Lab loot successfully falls back to vacuum:air_bottle when airtanks is absent")
minetest.get_modpath = orig_get_modpath
print("  ✓ Life support vacuum fallback verified on Lab tier")

print("[TEST 7] Testing Lazy VoxelManip Param2 Buffer Handling...")
local vm_param2_fetched = false
local vm_param2_committed = false
local mock_vm = {
	get_param2_data = function(self)
		vm_param2_fetched = true
		local t = {}
		for i = 1, total_nodes do t[i] = 0 end
		return t
	end,
	set_param2_data = function(self, data)
		vm_param2_committed = true
	end,
}

for i = 1, total_nodes do data[i] = 0 end
local vm_chests = {}
for trial = 1, 500 do
	vm_chests = derelicts.generate_in_chunk(cmin, cmax, data, mock_vm, area, "blackness")
	if #vm_chests > 0 then break end
end
assert_true(#vm_chests > 0, "Derelict generated with mock VoxelManip")
assert_true(vm_param2_fetched, "param2_data lazily fetched only on successful derelict generation")
assert_true(vm_param2_committed, "param2_data committed back to VoxelManip")
print("  ✓ Lazy VoxelManip param2 buffer fetch and commit verified")

print("[TEST 8] Testing Airtank Single-Unit Tool Stacking Compliance...")
node_metas = {}
local tank_test_pos = {x = 60, y = 5000, z = 60}
derelicts.populate_chest(tank_test_pos, "lab")
local tank_inv = minetest.get_meta(tank_test_pos):get_inventory()
for _, item in pairs(tank_inv:get_list("main")) do
	if item:get_name() == "airtanks:steel_tank" then
		assert_eq(item:get_count(), 1, "airtanks:steel_tank stack count must be 1 (unstacked tool)")
	end
end
print("  ✓ Airtank single-unit tool stacking compliance verified")

print("[TEST 9] Testing Sector Spatial Hash Isolation (no adjacent chunk clustering)...")
-- Chunk 0 in sector (0,0) is at x=0, z=0
-- Chunk 1 in sector (0,0) is at x=80, z=0
local adj_min = {x = 80, y = 5000, z = 0}
local adj_max = {x = 159, y = 5079, z = 79}
local adj_area = VoxelArea:new{MinEdge = adj_min, MaxEdge = adj_max}
local adj_data = {}
for i = 1, total_nodes do adj_data[i] = 13 end
local adj_chests_count = 0
for trial = 1, 200 do
	local chests = derelicts.generate_in_chunk(adj_min, adj_max, adj_data, nil, adj_area, "blackness")
	if #chests > 0 then adj_chests_count = adj_chests_count + 1 end
end
assert_eq(adj_chests_count, 0, "Non-active chunk in sector (0,0) guaranteed to reject spawn to prevent clustering")
print("  ✓ Sector spatial hashing guarantees anti-clustering isolation")

print("\nALL DERELICT TESTS PASSED SUCCESSFULLY!")
