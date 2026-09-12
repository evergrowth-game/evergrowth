-- tests/test_eva_thruster.lua
-- Unit tests for EVA RCS Thruster compressed air propellant consumption, auto-refuel,
-- and Hands-Free Inertial Station-Keeping Lock

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

-- Mock Minetest Environment
local registered_tools = {}
local registered_crafts = {}
local registered_globalsteps = {}
local registered_items = {
	["vacuum:air_bottle"] = {description = "Air Bottle"},
	["vessels:steel_bottle"] = {description = "Empty Steel Bottle"},
	["airtanks:steel_tank"] = {description = "Steel Air Tank"},
	["airtanks:empty_steel_tank"] = {description = "Empty Steel Air Tank"},
	["techage:cylinder_small_hydrogen"] = {description = "Small Hydrogen Cylinder"},
	["techage:ta3_cylinder_small"] = {description = "Small Gas Cylinder (Empty)"},
	["biofuel:canister_fuel"] = {description = "Biofuel Canister"},
	["biofuel:canister_empty"] = {description = "Empty Biofuel Canister"},
	["default:pick_mese"] = {description = "Mese Pickaxe"},
	["default:steelblock"] = {description = "Steel Block"},
}

local connected_players = {}

minetest = {
	get_translator = function(m) return function(s) return s end end,
	get_modpath = function(m)
		if m == "spacesuit_tweaks" then return "mods/space_modpack/spacesuit_tweaks" end
		if m == "techage" or m == "airtanks" or m == "vacuum" then return "mods/" .. m end
		return nil
	end,
	get_us_time = function() return 1000000 end,
	sound_play = function() return 1 end,
	sound_stop = function(handle) end,
	chat_send_player = function(name, msg) end,
	add_particlespawner = function() return 1 end,
	add_item = function(pos, item) end,
	register_tool = function(name, def)
		registered_tools[name] = def
		registered_items[name] = def
	end,
	register_craft = function(def)
		table.insert(registered_crafts, def)
	end,
	register_globalstep = function(fn)
		table.insert(registered_globalsteps, fn)
	end,
	register_on_leaveplayer = function() end,
	register_on_player_hpchange = function() end,
	registered_items = registered_items,
	get_connected_players = function() return connected_players end,
}

-- Mock player_monoids
player_monoids = {
	gravity = {
		changes = {},
		add_change = function(self, player, val, id)
			local pname = player:get_player_name()
			self.changes[pname] = self.changes[pname] or {}
			self.changes[pname][id] = val
		end,
		del_change = function(self, player, id)
			local pname = player:get_player_name()
			if self.changes[pname] then self.changes[pname][id] = nil end
		end,
		get_change = function(self, player, id)
			local pname = player:get_player_name()
			return self.changes[pname] and self.changes[pname][id]
		end,
	},
	speed = {
		changes = {},
		add_change = function(self, player, val, id)
			local pname = player:get_player_name()
			self.changes[pname] = self.changes[pname] or {}
			self.changes[pname][id] = val
		end,
		del_change = function(self, player, id)
			local pname = player:get_player_name()
			if self.changes[pname] then self.changes[pname][id] = nil end
		end,
	}
}

vector = {
	multiply = function(v, s) return {x = v.x * s, y = v.y * s, z = v.z * s} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
	length = function(v) return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z) end,
	normalize = function(v)
		local len = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
		if len == 0 then return {x=0, y=0, z=0} end
		return {x = v.x / len, y = v.y / len, z = v.z / len}
	end,
	distance = function(a, b)
		local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
		return math.sqrt(dx * dx + dy * dy + dz * dz)
	end,
}

-- Mock ItemStack
function ItemStack(item)
	if type(item) == "table" and item.get_name then return item end
	local item_name = ""
	local item_count = 0
	local item_wear = 0
	if type(item) == "string" then
		local parts = {}
		for p in item:gmatch("%S+") do table.insert(parts, p) end
		item_name = parts[1] or ""
		item_count = tonumber(parts[2]) or (item_name ~= "" and 1 or 0)
	elseif type(item) == "table" then
		item_name = item.name or ""
		item_count = item.count or 1
		item_wear = item.wear or 0
	end

	local obj = {}
	function obj:get_name() return item_name end
	function obj:get_count() return item_count end
	function obj:get_wear() return item_wear end
	function obj:set_wear(w) item_wear = tonumber(w) or 0 end
	function obj:add_wear(w) item_wear = math.min(65535, item_wear + (tonumber(w) or 0)) end
	function obj:is_empty() return item_count <= 0 or item_name == "" end
	function obj:take_item(n)
		local taken = math.min(item_count, n or 1)
		item_count = item_count - taken
		if item_count <= 0 then item_name = "" end
		return ItemStack({name = item_name, count = taken, wear = item_wear})
	end
	function obj:get_definition() return registered_items[item_name] or {} end
	return obj
end

-- Mock Player and Inventory
local function create_mock_player(name, inv_items)
	local list = {}
	for i = 1, 32 do
		list[i] = ItemStack(inv_items[i] or "")
	end

	local inv = {
		get_size = function(l) return 32 end,
		get_stack = function(self, l, i) return list[i] end,
		set_stack = function(self, l, i, s) list[i] = type(s) == "string" and ItemStack(s) or s end,
		get_list = function(self, l) return list end,
		add_item = function(self, l, stack)
			local s = type(stack) == "string" and ItemStack(stack) or stack
			for i = 1, 32 do
				if list[i]:is_empty() then
					list[i] = s
					return ItemStack("")
				end
			end
			return s
		end,
	}

	local pos = {x = 0, y = 2000, z = 0}
	local vel = {x = 0, y = 0, z = 0}
	local ctrl = {jump = false, sneak = false, up = false, down = false, left = false, right = false}
	local wielded = ItemStack("")

	local player = {
		is_player = function(self) return true end,
		get_player_name = function(self) return name end,
		get_pos = function(self) return pos end,
		set_pos = function(self, p) pos = p end,
		get_inventory = function(self) return inv end,
		get_look_dir = function(self) return {x = 0, y = 0, z = 1} end,
		get_look_horizontal = function(self) return 0 end,
		add_velocity = function(self, v) vel = vector.add(vel, v) end,
		set_velocity = function(self, v) vel = v end,
		get_velocity = function(self) return vel end,
		get_player_control = function(self) return ctrl end,
		set_player_control = function(self, c) ctrl = c end,
		get_wielded_item = function(self) return wielded end,
		set_wielded_item = function(self, s) wielded = type(s) == "string" and ItemStack(s) or s end,
	}
	table.insert(connected_players, player)
	return player, inv
end

print("[TEST] Loading spacesuit_tweaks modules...")
dofile("mods/space_modpack/spacesuit_tweaks/eva_thruster.lua")
dofile("mods/space_modpack/spacesuit_tweaks/crafts.lua")

print("[TEST 1] Testing EVA Thruster Registration & Single-Line Description...")
local thruster_def = registered_tools["spacesuit_tweaks:eva_thruster"]
assert_true(thruster_def ~= nil, "eva_thruster tool is registered")
assert_eq(thruster_def.description, "EVA RCS Thruster Pack", "description is single line with no newlines")
assert_true(not thruster_def.description:find("\n"), "description has no newlines to break formspecs")

print("[TEST 2] Testing Manual Right-Click Refuel with Air Bottle...")
local player, inv = create_mock_player("Astronaut", {"vacuum:air_bottle"})
local thruster_stack = ItemStack("spacesuit_tweaks:eva_thruster")
thruster_stack:set_wear(40000) -- worn/half-empty

local result_stack = thruster_def.on_place(thruster_stack, player, nil)
assert_eq(result_stack:get_wear(), 0, "Thruster wear reset to 0 (100% full)")
assert_eq(inv:get_stack("main", 1):get_name(), "vessels:steel_bottle", "Empty steel bottle placed in inventory slot 1")

print("[TEST 3] Testing Manual Right-Click Refuel with Airtank...")
local player2, inv2 = create_mock_player("Cosmonaut", {"airtanks:steel_tank"})
local thruster_stack2 = ItemStack("spacesuit_tweaks:eva_thruster")
thruster_stack2:set_wear(55000)

local result_stack2 = thruster_def.on_place(thruster_stack2, player2, nil)
assert_eq(result_stack2:get_wear(), 0, "Thruster wear reset to 0 (100% full)")
assert_eq(inv2:get_stack("main", 1):get_name(), "airtanks:empty_steel_tank", "Empty airtank placed in inventory slot 1")

print("[TEST 4] Testing Rejection of Incompatible Fuels (Hydrogen, Biofuel)...")
local player_incompat, inv_incompat = create_mock_player("InvalidFuelUser", {"techage:cylinder_small_hydrogen", "biofuel:canister_fuel"})
local thruster_incompat = ItemStack("spacesuit_tweaks:eva_thruster")
thruster_incompat:set_wear(50000)

local res_incompat = thruster_def.on_place(thruster_incompat, player_incompat, nil)
assert_eq(res_incompat:get_wear(), 50000, "Wear unchanged: Hydrogen and biofuel are rejected")
assert_eq(inv_incompat:get_stack("main", 1):get_name(), "techage:cylinder_small_hydrogen", "Hydrogen cylinder untouched")
assert_eq(inv_incompat:get_stack("main", 2):get_name(), "biofuel:canister_fuel", "Biofuel canister untouched")

print("[TEST 5] Testing Rejection when Already 100% Full...")
local full_thruster = ItemStack("spacesuit_tweaks:eva_thruster")
full_thruster:set_wear(0)
local res = thruster_def.on_place(full_thruster, player2, nil)
assert_eq(res:get_wear(), 0, "Wear remains 0")

print("[TEST 6] Testing In-Flight Boost and Auto-Refuel on Depletion...")
-- Player has 1 air bottle in inventory, thruster has only 1 boost worth of propellant left
local player3, inv3 = create_mock_player("Pilot", {"vacuum:air_bottle"})
local thruster_stack3 = ItemStack("spacesuit_tweaks:eva_thruster")
thruster_stack3:set_wear(65500) -- near empty

-- Boost surge on_use
local res_boost = thruster_def.on_use(thruster_stack3, player3, nil)
assert_true(player3:get_velocity().z > 0, "Boost velocity applied")
assert_eq(res_boost:get_wear(), 0, "Auto-refueled thruster to 0 wear using inventory bottle")
assert_eq(inv3:get_stack("main", 1):get_name(), "vessels:steel_bottle", "Empty steel bottle auto-returned in inventory")

print("[TEST 7] Testing Complete Propellant Exhaustion without Fuel in Inventory...")
local player4, inv4 = create_mock_player("Stranded", {})
local thruster_stack4 = ItemStack("spacesuit_tweaks:eva_thruster")
thruster_stack4:set_wear(65500)

-- First boost will exceed threshold, fail auto-refuel, clamp to 65534, and fail to boost
local res_boost2 = thruster_def.on_use(thruster_stack4, player4, nil)
assert_eq(res_boost2:get_wear(), 65534, "Wear clamped at 65534 (NOT deleted / wear 65535)")
assert_eq(player4:get_velocity().z, 0, "No velocity applied when depleted")

print("[TEST 8] Testing Refuel Crafting Recipes...")
local found_vacuum_craft = false
local found_airtank_craft = false
local found_invalid_fuel_craft = false
for _, craft in ipairs(registered_crafts) do
	if craft.type == "shapeless" and craft.output == "spacesuit_tweaks:eva_thruster" then
		if craft.recipe[2] == "vacuum:air_bottle" then
			found_vacuum_craft = true
		elseif craft.recipe[2] == "airtanks:steel_tank" then
			found_airtank_craft = true
		elseif craft.recipe[2]:find("hydrogen") or craft.recipe[2]:find("biofuel") then
			found_invalid_fuel_craft = true
		end
	end
end
assert_true(found_vacuum_craft, "Found shapeless refuel craft with vacuum:air_bottle")
assert_true(found_airtank_craft, "Found shapeless refuel craft with airtanks:steel_tank")
assert_true(not found_invalid_fuel_craft, "No hydrogen or biofuel refuel craft recipes exist")

print("[TEST 9] Testing Continuous Looping Sound Lifecycle in Globalstep...")
-- Mock sound and particle tracking
local sounds_played = {}
local sounds_stopped = {}
local particles_spawned = {}
local handle_counter = 100

minetest.sound_play = function(sname, spec)
	handle_counter = handle_counter + 1
	table.insert(sounds_played, {name = sname, spec = spec, handle = handle_counter})
	return handle_counter
end
minetest.sound_stop = function(handle)
	table.insert(sounds_stopped, handle)
end
minetest.add_particlespawner = function(def)
	table.insert(particles_spawned, {def = def})
	return 1
end

local globalstep_fn = registered_globalsteps[1]
assert_true(globalstep_fn ~= nil, "EVA Thruster globalstep registered")

local player5, inv5 = create_mock_player("VectorPilot", {})
player5:set_wielded_item("spacesuit_tweaks:eva_thruster")
player5:get_wielded_item():set_wear(0)

-- Step 1: Neutral / Idle (dtime = 0.05, less than 0.1)
player5:set_player_control({jump = false, sneak = false, up = false, down = false, left = false, right = false})
globalstep_fn(0.05)
assert_eq(#sounds_played, 0, "No sound played while idle")
assert_eq(#sounds_stopped, 0, "No sound stopped while idle")
assert_eq(#particles_spawned, 0, "No particles while idle")

-- Step 2: Key pressed (up = true) -> starts looping sound attached to player
player5:set_player_control({jump = false, sneak = false, up = true, down = false, left = false, right = false})
globalstep_fn(0.02)
assert_eq(#sounds_played, 1, "Looping sound started immediately when movement key pressed")
assert_eq(sounds_played[1].name, "default_cool_lava", "Thruster sound played")
assert_eq(sounds_played[1].spec.loop, true, "Sound requested with loop = true")
assert_eq(sounds_played[1].spec.object, player5, "Sound attached to player object")
assert_eq(#sounds_stopped, 0, "No sound stopped while moving")
assert_eq(#particles_spawned, 1, "Particles spawned immediately on key-down transition")

-- Step 3: Holding 'up' continuously -> sound continues looping, no redundant sound_play calls
globalstep_fn(0.05)
globalstep_fn(0.1)
assert_eq(#sounds_played, 1, "Continuous hold retains single looping sound handle without restarts")
assert_eq(#sounds_stopped, 0, "Sound not stopped while continuous movement is maintained")
assert_eq(#particles_spawned, 3, "Particles spawn on periodic step_effects")

-- Step 4: Releasing all movement keys -> immediately stops looping sound
player5:set_player_control({jump = false, sneak = false, up = false, down = false, left = false, right = false})
globalstep_fn(0.02)
assert_eq(#sounds_stopped, 1, "Sound stopped immediately when keys released")
assert_eq(sounds_stopped[1], 101, "Stopped handle matches the started looping sound handle")

-- Step 5: Tapping left strafe then releasing
player5:set_player_control({jump = false, sneak = false, up = false, down = false, left = true, right = false})
globalstep_fn(0.02)
assert_eq(#sounds_played, 2, "New looping sound started on strafe key press")
player5:set_player_control({jump = false, sneak = false, up = false, down = false, left = false, right = false})
globalstep_fn(0.02)
assert_eq(#sounds_stopped, 2, "Strafe sound stopped when strafe key released")

print("ALL EVA THRUSTER TESTS PASSED SUCCESSFULLY!")


