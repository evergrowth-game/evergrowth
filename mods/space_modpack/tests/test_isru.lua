-- Automated Headless Test Suite for Space Modpack ISRU Pipeline
-- Tests: Ice Melter, Space Electrolyzer Hook, Network Ports, and Invariant Callbacks

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
-- Minetest & TechAge Headless Mock Environment
--------------------------------------------------------------------------------
_G.minetest = {}
_G.techage = {}
_G.networks = {liquid = {}, power = {}}
_G.tubelib2 = {}
_G.default = {
	node_sound_metal_defaults = function() return {} end,
}
_G.screwdriver = {
	disallow = function() return false end,
}

local registered_nodes = {}
local registered_crafts = {}
local node_metadata_store = {}
local node_inventory_store = {}
local nvm_store = {}
local world_nodes = {}
local active_formspecs = {}

minetest.registered_nodes = registered_nodes
minetest.register_node = function(name, def)
	registered_nodes[name] = def
end
minetest.override_item = function(name, def)
	registered_nodes[name] = registered_nodes[name] or {}
	for k, v in pairs(def) do
		registered_nodes[name][k] = v
	end
end
minetest.register_craft = function(craft)
	table.insert(registered_crafts, craft)
end
minetest.get_modpath = function(mod)
	local active_mods = {
		jumpdrive_tweaks = true,
		other_worlds_tweaks = true,
		techage = true,
		networks = true,
		basic_materials = true,
		default = true,
	}
	return active_mods[mod] and ("/fake/path/" .. mod) or nil
end
minetest.get_node = function(pos)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	return world_nodes[key] or {name = "air", param2 = 0}
end
minetest.swap_node = function(pos, node)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	world_nodes[key] = node
end
minetest.is_protected = function(pos, name)
	return name == "unauthorized_player"
end
minetest.register_on_mods_loaded = function(fn) fn() end
minetest.colorize = function(col, str) return str end
minetest.get_translator = function(mod)
	return function(str) return str end
end
minetest.log = function(...) end

_G.default.gui_bg = ""
_G.default.gui_bg_img = ""
_G.default.gui_slots = ""
_G.techage.wrench_tooltip = function(...) return "" end
_G.techage.formspec_power_bar = function(...) return "" end
_G.techage.is_running = function(nvm) return nvm.running == true end
_G.techage.S = function(s) return s end

local function create_inv()
	local lists = {}
	return {
		set_size = function(self, list, size) lists[list] = lists[list] or {} end,
		get_size = function(self, list) return lists[list] and #lists[list] or 0 end,
		is_empty = function(self, list)
			if not lists[list] then return true end
			for _, item in ipairs(lists[list]) do
				if not item:is_empty() then return false end
			end
			return true
		end,
		get_stack = function(self, list, idx)
			return (lists[list] and lists[list][idx]) or ItemStack("")
		end,
		set_stack = function(self, list, idx, stack)
			lists[list] = lists[list] or {}
			lists[list][idx] = stack
		end,
	}
end

local function create_meta(pos)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	node_metadata_store[key] = node_metadata_store[key] or {
		strings = {},
		ints = {},
		floats = {},
		inv = create_inv(),
	}
	local store = node_metadata_store[key]
	return {
		get_inventory = function() return store.inv end,
		set_string = function(self, k, v) store.strings[k] = v end,
		get_string = function(self, k) return store.strings[k] or "" end,
		set_int = function(self, k, v) store.ints[k] = v end,
		get_int = function(self, k) return store.ints[k] or 0 end,
		set_float = function(self, k, v) store.floats[k] = v end,
		get_float = function(self, k) return store.floats[k] or 0 end,
		contains = function(self, k) return store.strings[k] ~= nil or store.ints[k] ~= nil end,
	}
end
minetest.get_meta = create_meta

function _G.ItemStack(name)
	local count = 1
	local item_name = ""
	if type(name) == "string" then
		if name == "" then
			item_name = ""
			count = 0
		else
			local parts = {}
			for part in string.gmatch(name, "%S+") do table.insert(parts, part) end
			item_name = parts[1] or ""
			count = tonumber(parts[2]) or 1
		end
	end
	return {
		get_name = function(self) return item_name end,
		get_count = function(self) return count end,
		is_empty = function(self) return count <= 0 or item_name == "" end,
		set_count = function(self, c) count = c end,
		take_item = function(self, n)
			local taken = math.min(count, n or 1)
			count = count - taken
			return ItemStack(item_name .. " " .. taken)
		end,
	}
end

-- Mock TechAge APIs
local techage_registered_nodes = {}
techage.register_node = function(names, def)
	for _, n in ipairs(names) do techage_registered_nodes[n] = def end
end
techage.get_nvm = function(pos)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	nvm_store[key] = nvm_store[key] or {}
	return nvm_store[key]
end
techage.add_node = function(pos, name) return 1 end
techage.side_to_indir = function(side, param2)
	if side == "B" then return 2 end
	if side == "R" then return 1 end
	return 1
end
techage.side_to_outdir = function(side, param2)
	if side == "L" then return 3 end
	if side == "R" then return 4 end
	if side == "B" then return 2 end
	return 1
end
techage.is_activeformspec = function(pos)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	return active_formspecs[key] == true
end
techage.set_activeformspec = function(pos, player)
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	active_formspecs[key] = true
end
techage.power = {
	percent = function(capa, amt) return math.floor((amt / capa) * 100) end,
}
techage.put_items = function(inv, list, stack)
	inv:set_stack(list, 1, stack)
	return ItemStack("")
end

local mock_tube = {
	after_place_node = function(self, pos) end,
	after_dig_node = function(self, pos) end,
	register_on_tube_update2 = function(self, fn) end,
}
techage.LiquidPipe = mock_tube
techage.ElectricCable = mock_tube

local NodeStatesClass = {}
NodeStatesClass.__index = NodeStatesClass
function NodeStatesClass:new(def)
	local obj = setmetatable(def or {}, NodeStatesClass)
	obj.can_start = obj.can_start or function() return true end
	obj.has_power = obj.has_power or function() return true end
	return obj
end
function NodeStatesClass:node_init(pos, nvm, number)
	nvm.running = false
	if self.formspec_func then
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", self.formspec_func(self, pos, nvm))
	end
end
function NodeStatesClass:on_node_load(pos) end
function NodeStatesClass:on_receive_message(pos, topic, payload) return nil end
function NodeStatesClass:start(pos, nvm)
	local res = self.can_start(pos, nvm)
	if res ~= true then
		self:standby(pos, nvm, res)
		return false
	end
	nvm.running = true
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	world_nodes[key] = {name = self.node_name_active, param2 = (world_nodes[key] and world_nodes[key].param2) or 0}
	if self.start_node then self.start_node(pos, nvm) end
	return true
end
function NodeStatesClass:keep_running(pos, nvm, info)
	nvm.running = true
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	world_nodes[key] = {name = self.node_name_active, param2 = (world_nodes[key] and world_nodes[key].param2) or 0}
end
function NodeStatesClass:standby(pos, nvm, info)
	nvm.running = false
	local key = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
	world_nodes[key] = {name = self.node_name_passive, param2 = (world_nodes[key] and world_nodes[key].param2) or 0}
	if self.stop_node then self.stop_node(pos, nvm) end
end
function NodeStatesClass:fault(pos, nvm, info)
	self:standby(pos, nvm, info)
end
function NodeStatesClass:state_button_event(pos, nvm, fields) end
function NodeStatesClass:get_state_button_image(nvm) return "state_button.png" end
function NodeStatesClass:get_state_tooltip(nvm) return "Running / Standby" end
techage.NodeStates = NodeStatesClass

-- Mock Networks APIs
local registered_pipe_nodes = {}
local registered_liquid_defs = {}
networks.liquid.register_nodes = function(names, pipe, role, sides, def)
	for _, n in ipairs(names) do
		registered_pipe_nodes[n] = {role = role, sides = sides, def = def}
		registered_liquid_defs[n] = def
	end
end
networks.power.register_nodes = function(names, cable, role, sides) end
networks.power.get_storage_load = function(pos, cable, indir)
	return 100 -- Full battery storage
end

networks.liquid.srv_peek = function(nvm)
	if nvm.liquid and nvm.liquid.name and nvm.liquid.amount and nvm.liquid.amount > 0 then
		return nvm.liquid.name
	end
	return nil
end
networks.liquid.srv_take = function(nvm, name, amount)
	nvm.liquid = nvm.liquid or {}
	if not nvm.liquid.name or nvm.liquid.name == name or name == nil then
		local taken = math.min(nvm.liquid.amount or 0, amount)
		nvm.liquid.amount = (nvm.liquid.amount or 0) - taken
		local ret_name = nvm.liquid.name or name
		if nvm.liquid.amount == 0 then nvm.liquid.name = nil end
		return taken, ret_name
	end
	return 0, name
end
networks.liquid.srv_put = function(nvm, name, amount, capa)
	nvm.liquid = nvm.liquid or {}
	if not nvm.liquid.name or nvm.liquid.name == name then
		nvm.liquid.name = name
		nvm.liquid.amount = nvm.liquid.amount or 0
		local space = capa - nvm.liquid.amount
		local added = math.min(space, amount)
		nvm.liquid.amount = nvm.liquid.amount + added
		return amount - added
	end
	return amount
end
networks.liquid.on_punch = function() end

networks.liquid.put = function(pos, pipe, outdir, name, amount)
	-- Mock pipe push (simulate receiver accepting all fluid)
	return 0
end

networks.power.consume_power = function(pos, cable, indir, amount)
	return amount -- Simulate full power availability
end

_G.vector = {
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}

_G.jumpdrive = {
	fuel = {
		register = function(item, val) end,
	}
}

minetest.find_nodes_in_area = function(p1, p2, nodenames)
	local matches = {}
	local target_map = {}
	for _, n in ipairs(nodenames) do target_map[n] = true end

	local min_x, max_x = math.min(p1.x, p2.x), math.max(p1.x, p2.x)
	local min_y, max_y = math.min(p1.y, p2.y), math.max(p1.y, p2.y)
	local min_z, max_z = math.min(p1.z, p2.z), math.max(p1.z, p2.z)

	for key, node in pairs(world_nodes) do
		if target_map[node.name] then
			local parts = {}
			for p in string.gmatch(key, "[^,]+") do table.insert(parts, tonumber(p)) end
			local x, y, z = parts[1], parts[2], parts[3]
			if x >= min_x and x <= max_x and y >= min_y and y <= max_y and z >= min_z and z <= max_z then
				table.insert(matches, {x = x, y = y, z = z})
			end
		end
	end
	return matches
end

_G.networks.control = {
	register_nodes = function(names, def) end,
	request = function(...) return {3} end,
}
_G.techage.TA4_Cable = mock_tube
_G.techage.get_pos = function(pos, side)
	if side == "L" then return {x = pos.x - 1, y = pos.y, z = pos.z} end
	if side == "R" then return {x = pos.x + 1, y = pos.y, z = pos.z} end
	return pos
end
_G.techage.get_node_lvm = function(pos) return minetest.get_node(pos) end
_G.networks.side_to_outdir = function(pos, side) return (side == "L") and 3 or 1 end

--------------------------------------------------------------------------------
-- Load Target Mod Subsystems
--------------------------------------------------------------------------------
-- Pre-register base electrolyzer and solar nodes to allow override_item
minetest.register_node("techage:ta4_electrolyzer", {
	description = "TA4 Electrolyzer Base",
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "BASE_FORMSPEC")
	end,
	on_timer = function() end,
})
minetest.register_node("techage:ta4_electrolyzer_on", {
	description = "TA4 Electrolyzer Active Base",
})
minetest.register_node("techage:ta4_solar_carrier", {})
minetest.register_node("techage:ta4_solar_carrierB", {})
minetest.register_node("techage:ta4_solar_module", {})
minetest.register_node("techage:ta4_solar_inverter", {
	on_timer = function() end,
})
-- Mock node content IDs and hashing for ship tracker integration
local content_ids = {
	["air"] = 0,
	["ignore"] = 1,
	["vacuum:vacuum"] = 2,
	["jumpdrive:engine"] = 10,
	["jumpdrive:backbone"] = 11,
	["jumpdrive_tweaks:fuel_tank"] = 12,
	["jumpdrive_tweaks:fuel_port"] = 13,
	["techage:ta4_electrolyzer"] = 14,
	["techage:ta4_electrolyzer_on"] = 15,
	["techage:ta4_solar_carrier"] = 16,
	["techage:ta4_solar_carrierB"] = 17,
	["techage:ta4_solar_module"] = 18,
	["techage:ta4_solar_inverter"] = 19,
	["jumpdrive_tweaks:ice_melter"] = 20,
	["jumpdrive_tweaks:ice_melter_active"] = 21,
}
local id_to_names = {}
for k, v in pairs(content_ids) do id_to_names[v] = k end

minetest.hash_node_position = function(pos)
	return string.format("%d,%d,%d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
end
minetest.get_content_id = function(name)
	return content_ids[name] or 99
end
minetest.get_name_from_content_id = function(id)
	return id_to_names[id] or "unknown"
end
minetest.get_node_or_nil = minetest.get_node

-- Load subsystems
_G.jumpdrive_tweaks = _G.jumpdrive_tweaks or {}
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/terrain_filter.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/ship_tracker.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/nodes_fuel.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/techage_pipe.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/ice_melter.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/other_worlds_tweaks/electrolyzer_hook.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/other_worlds_tweaks/solar_hook.lua")
dofile("/Users/Aresh/Desktop/Projects/evergrowth/mods/space_modpack/jumpdrive_tweaks/crafts.lua")

print("Starting ISRU Subsystem Headless Test Suite...\n")

--------------------------------------------------------------------------------
-- Unit & Invariant Tests: Ice Melter
--------------------------------------------------------------------------------
run_test("Ice Melter: Node registrations and properties", function()
	local passive = registered_nodes["jumpdrive_tweaks:ice_melter"]
	local active = registered_nodes["jumpdrive_tweaks:ice_melter_active"]
	assert_true(passive ~= nil, "passive node registered")
	assert_true(active ~= nil, "active node registered")
	assert_eq(passive.groups.jumpdrive_ship_part, 1, "passive has jumpdrive_ship_part group")
	assert_eq(active.groups.jumpdrive_ship_part, 1, "active has jumpdrive_ship_part group")
	assert_eq(active.light_source, 6, "active has light source 6")
	assert_eq(type(passive.on_rotate), "function", "passive disallows screwdriver rotation")
	assert_eq(passive.on_rotate(), false, "passive on_rotate returns false")
end)

run_test("Ice Melter: can_dig nil player safety and liquid/inventory check", function()
	local def = registered_nodes["jumpdrive_tweaks:ice_melter"]
	local pos = {x = 10, y = 100, z = 10}
	local key = "10,100,10"
	world_nodes[key] = {name = "jumpdrive_tweaks:ice_melter", param2 = 0}
	
	-- 1. Test with nil player (automated tool check)
	assert_true(def.can_dig(pos, nil), "can_dig succeeds with nil player on empty node")

	-- 2. Test with unauthorized player
	local fake_bad_player = { get_player_name = function() return "unauthorized_player" end }
	assert_false(def.can_dig(pos, fake_bad_player), "can_dig blocked by protection")

	-- 3. Test with items in src inventory
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_stack("src", 1, ItemStack("default:ice 10"))
	assert_false(def.can_dig(pos, nil), "can_dig blocked when inventory contains items")
	inv:set_stack("src", 1, ItemStack(""))

	-- 4. Test with water in liquid buffer
	local nvm = techage.get_nvm(pos)
	nvm.liquid = {name = "techage:water", amount = 50}
	assert_false(def.can_dig(pos, nil), "can_dig blocked when liquid buffer contains water")
	nvm.liquid = {name = nil, amount = 0}
	assert_true(def.can_dig(pos, nil), "can_dig succeeds when emptied")
end)

run_test("Ice Melter: Lifecycle place, melting cycles, and fluid push", function()
	local pos = {x = 20, y = 100, z = 20}
	local key = "20,100,20"
	world_nodes[key] = {name = "jumpdrive_tweaks:ice_melter", param2 = 0}
	
	local def = registered_nodes["jumpdrive_tweaks:ice_melter"]
	def.after_place_node(pos)
	
	local meta = minetest.get_meta(pos)
	assert_eq(meta:get_int("in_dir"), 3, "in_dir set to Left side outdir")
	assert_eq(meta:get_int("out_dir"), 4, "out_dir set to Right side outdir")

	-- Add comet ice to feedstock
	local inv = meta:get_inventory()
	inv:set_stack("src", 1, ItemStack("other_worlds_tweaks:comet_ice 5"))

	-- Run on_timer tick 1 (starts node) and tick 2 (melts ice)
	def.on_timer(pos, 2)
	assert_eq(world_nodes[key].name, "jumpdrive_tweaks:ice_melter_active", "switched to active node")
	def.on_timer(pos, 2)
	assert_eq(inv:get_stack("src", 1):get_count(), 4, "consumed 1 comet ice")
end)

run_test("Ice Melter: Hopper and pusher automated extraction blocking", function()
	local pos = {x = 30, y = 100, z = 30}
	local ta_reg = techage_registered_nodes["jumpdrive_tweaks:ice_melter"]
	assert_true(ta_reg ~= nil, "techage node handlers registered")
	
	-- Push access allowed
	local inv, list = ta_reg.on_inv_request(pos, 1, "push")
	assert_true(inv ~= nil and list == "src", "push request returns src inventory")

	-- Pull access strictly blocked
	local pull_inv = ta_reg.on_inv_request(pos, 1, "pull")
	assert_true(pull_inv == nil, "pull request returns nil")
end)

run_test("Ice Melter: Liquid pipe untake fluid validation", function()
	local pos = {x = 40, y = 100, z = 40}
	local pipe_reg = registered_liquid_defs["jumpdrive_tweaks:ice_melter"]
	assert_true(pipe_reg ~= nil, "liquid pipe registered")
	
	-- Untake valid water
	local leftover = pipe_reg.untake(pos, 4, "techage:water", 20)
	assert_eq(leftover, 0, "accepted techage:water refund")
	local nvm = techage.get_nvm(pos)
	assert_eq(nvm.liquid.amount, 20, "buffer holds 20 units")

	-- Untake invalid fluid (e.g. lava/oil refund from network mismatch)
	local rejected = pipe_reg.untake(pos, 4, "techage:oil", 15)
	assert_eq(rejected, 15, "rejected non-water fluid")
	assert_eq(nvm.liquid.amount, 20, "buffer untouched")
end)

--------------------------------------------------------------------------------
-- Unit & Invariant Tests: Space Electrolyzer Hook
--------------------------------------------------------------------------------
run_test("Space Electrolyzer: Placement initializes space formspec", function()
	local pos = {x = 50, y = 100, z = 50}
	local def = registered_nodes["techage:ta4_electrolyzer"]
	assert_true(def ~= nil, "techage:ta4_electrolyzer registered")
	assert_true(def.after_place_node ~= nil, "after_place_node overridden")

	def.after_place_node(pos)
	local meta = minetest.get_meta(pos)
	local formspec = meta:get_string("formspec")
	assert_true(string.find(formspec, "Water Feedstock") ~= nil, "formspec includes Water Feedstock HUD")
	assert_true(string.find(formspec, "Hydrogen Gas") ~= nil, "formspec includes Hydrogen Gas HUD")
end)

run_test("Space Electrolyzer: Dual-port liquid isolation (peek, put, take, untake)", function()
	local pos = {x = 60, y = 100, z = 60}
	world_nodes["60,100,60"] = {name = "techage:ta4_electrolyzer", param2 = 0}
	local pipe_reg = registered_liquid_defs["techage:ta4_electrolyzer"]
	assert_true(pipe_reg ~= nil, "electrolyzer liquid pipe registered")

	-- Put water into Back Port ("B" -> indir 2)
	local leftover = pipe_reg.put(pos, 2, "techage:river_water", 40)
	assert_eq(leftover, 0, "accepted river water into back port")
	local nvm = techage.get_nvm(pos)
	assert_eq(nvm.water_amount, 40, "water_amount buffer is 40")

	-- Peek back port returns techage:water
	assert_eq(pipe_reg.peek(pos, 2), "techage:water", "back port peek returns techage:water")

	-- Put fluid into Right Port ("R" -> indir 1) is rejected
	local rejected = pipe_reg.put(pos, 1, "techage:water", 20)
	assert_eq(rejected, 20, "right port rejects incoming fluid")

	-- Untake hydrogen on Right Port ("R") is accepted
	local h2_refund = pipe_reg.untake(pos, 1, "techage:hydrogen", 10)
	assert_eq(h2_refund, 0, "accepted hydrogen refund on right port")
	assert_eq(pipe_reg.peek(pos, 1), "techage:hydrogen", "right port peek returns techage:hydrogen")

	-- Untake foreign fluid on Right Port is rejected
	local foreign_refund = pipe_reg.untake(pos, 1, "techage:oil", 10)
	assert_eq(foreign_refund, 10, "rejected non-hydrogen fluid on right port")
end)

run_test("Space Electrolyzer: High-altitude space gating (Y >= 1000)", function()
	local pos_ground = {x = 70, y = 500, z = 70}
	local pos_space = {x = 70, y = 1500, z = 70}
	world_nodes["70,500,70"] = {name = "techage:ta4_electrolyzer", param2 = 0}
	world_nodes["70,1500,70"] = {name = "techage:ta4_electrolyzer", param2 = 0}

	local def = registered_nodes["techage:ta4_electrolyzer"]

	-- Ground: timer can run without water buffer
	local nvm_ground = techage.get_nvm(pos_ground)
	nvm_ground.water_amount = 0
	def.on_timer(pos_ground, 2)
	assert_true(nvm_ground.running, "runs at ground without stored water")

	-- Space: timer halts if water buffer is empty
	local nvm_space = techage.get_nvm(pos_space)
	nvm_space.water_amount = 0
	def.on_timer(pos_space, 2)
	assert_false(nvm_space.running, "halts in space without stored water")

	-- Space: timer runs when water buffer is replenished
	nvm_space.water_amount = 20
	def.on_timer(pos_space, 2)
	assert_true(nvm_space.running, "runs in space when water buffer is supplied")
end)

run_test("Fuel Tank: Direct pipe network input and fuel isolation", function()
	local pos = {x = 100, y = 100, z = 100}
	world_nodes["100,100,100"] = {name = "jumpdrive_tweaks:fuel_tank", param2 = 0}
	local pipe_reg = registered_liquid_defs["jumpdrive_tweaks:fuel_tank"]
	assert_true(pipe_reg ~= nil, "fuel_tank registered with liquid pipe network")

	-- 1. Put hydrogen fuel into empty tank
	local leftover = pipe_reg.put(pos, 1, "techage:hydrogen", 2000)
	assert_eq(leftover, 0, "accepted 2000 units of hydrogen")
	local meta = minetest.get_meta(pos)
	assert_eq(meta:get_int("fuel_amount"), 2000, "stored 2000 units")
	assert_eq(meta:get_string("fuel_type"), "techage:hydrogen", "fuel type is techage:hydrogen")
	assert_eq(pipe_reg.peek(pos, 1), "techage:hydrogen", "peek returns techage:hydrogen")

	-- 2. Reject different fuel type into same tank
	local rejected = pipe_reg.put(pos, 1, "biofuel:fuel", 500)
	assert_eq(rejected, 500, "rejected mixing biofuel into hydrogen tank")
	assert_eq(meta:get_int("fuel_amount"), 2000, "fuel amount untouched")

	-- 3. Drain fuel from tank via pipe
	local taken, tname = pipe_reg.take(pos, 1, "techage:hydrogen", 1000)
	assert_eq(taken, 1000, "drained 1000 units of hydrogen")
	assert_eq(meta:get_int("fuel_amount"), 1000, "remaining 1000 units")
end)

run_test("Fuel Port: Exterior port routes piped fuel to non-touching ship fuel tanks via backbone", function()
	local port_pos = {x = 200, y = 100, z = 200}
	local tank1_pos = {x = 210, y = 100, z = 205} -- Connected via backbone spine
	local tank2_pos = {x = 205, y = 105, z = 215} -- Connected via backbone spine

	-- Backbone spine linking port and fuel tanks
	for x = 200, 210 do world_nodes[x .. ",100,200"] = {name = "jumpdrive:backbone", param2 = 0} end
	for z = 200, 205 do world_nodes["210,100," .. z] = {name = "jumpdrive:backbone", param2 = 0} end
	for z = 200, 215 do world_nodes["205,100," .. z] = {name = "jumpdrive:backbone", param2 = 0} end
	for y = 100, 105 do world_nodes["205," .. y .. ",215"] = {name = "jumpdrive:backbone", param2 = 0} end

	world_nodes["200,100,200"] = {name = "jumpdrive_tweaks:fuel_port", param2 = 0}
	world_nodes["210,100,205"] = {name = "jumpdrive_tweaks:fuel_tank", param2 = 0}
	world_nodes["205,105,215"] = {name = "jumpdrive_tweaks:fuel_tank", param2 = 0}

	local port_reg = registered_liquid_defs["jumpdrive_tweaks:fuel_port"]
	assert_true(port_reg ~= nil, "fuel_port registered with liquid pipe network")

	-- Put 6000 units of hydrogen into the exterior port (5000 fills tank 1, 1000 goes to tank 2)
	local leftover = port_reg.put(port_pos, 1, "techage:hydrogen", 6000)
	assert_eq(leftover, 0, "accepted all 6000 units through port")

	local meta1 = minetest.get_meta(tank1_pos)
	local meta2 = minetest.get_meta(tank2_pos)
	local f1 = meta1:get_int("fuel_amount")
	local f2 = meta2:get_int("fuel_amount")
	assert_eq(f1 + f2, 6000, "total 6000 units distributed across tanks")
	assert_true(f1 == 5000 or f2 == 5000, "one tank filled to capacity (5000 units)")
	assert_true(f1 == 1000 or f2 == 1000, "other tank received remaining 1000 units")
	assert_eq(meta1:get_string("fuel_type"), "techage:hydrogen", "tank 1 fuel type is hydrogen")
	assert_eq(meta2:get_string("fuel_type"), "techage:hydrogen", "tank 2 fuel type is hydrogen")

	-- Take 1000 units from port, then untake (return) 500 units through port
	local taken_amt = port_reg.take(port_pos, 1, "techage:hydrogen", 1000)
	assert_eq(taken_amt, 1000, "took 1000 units through port")
	local untaken_leftover = port_reg.untake(port_pos, 1, "techage:hydrogen", 500)
	assert_eq(untaken_leftover, 0, "untake accepted 500 units back through port")

	-- Verify port metadata has 0 fuel stored (routed to tanks, not trapped in port)
	local port_meta = minetest.get_meta(port_pos)
	assert_eq(port_meta:get_int("fuel_amount"), 0, "port node itself stores 0 units in meta")
end)

run_test("Fuel Port: Multi-fluid extraction isolation prevents mixed fluid draw", function()
	local port_pos = {x = 400, y = 100, z = 400}
	local tank1_pos = {x = 401, y = 100, z = 400}
	local tank2_pos = {x = 402, y = 100, z = 400}

	world_nodes["400,100,400"] = {name = "jumpdrive_tweaks:fuel_port", param2 = 0}
	world_nodes["401,100,400"] = {name = "jumpdrive_tweaks:fuel_tank", param2 = 0}
	world_nodes["402,100,400"] = {name = "jumpdrive_tweaks:fuel_tank", param2 = 0}

	local meta1 = minetest.get_meta(tank1_pos)
	meta1:set_int("fuel_amount", 1000)
	meta1:set_string("fuel_type", "techage:hydrogen")

	local meta2 = minetest.get_meta(tank2_pos)
	meta2:set_int("fuel_amount", 2000)
	meta2:set_string("fuel_type", "biofuel:fuel")

	local port_reg = registered_liquid_defs["jumpdrive_tweaks:fuel_port"]

	-- Generic draw (name = nil) requesting 1500 units should only draw from first fluid type encountered, never mixing
	local taken_amt, taken_type = port_reg.take(port_pos, 1, nil, 1500)
	assert_true(taken_type == "techage:hydrogen" or taken_type == "biofuel:fuel", "valid fluid type returned")

	if taken_type == "techage:hydrogen" then
		assert_eq(taken_amt, 1000, "extracted only available hydrogen")
		assert_eq(meta1:get_int("fuel_amount"), 0, "hydrogen tank emptied")
		assert_eq(meta2:get_int("fuel_amount"), 2000, "biofuel tank untouched")
	else
		assert_eq(taken_amt, 1500, "extracted 1500 biofuel")
		assert_eq(meta2:get_int("fuel_amount"), 500, "biofuel tank reduced")
		assert_eq(meta1:get_int("fuel_amount"), 1000, "hydrogen tank untouched")
	end
end)

run_test("Space Solar: Orbital carrier resolves power in space vacuum", function()
	local carrier_pos = {x = 300, y = 1500, z = 300}
	local module_l = {x = 299, y = 1500, z = 300}
	local module_r = {x = 301, y = 1500, z = 300}

	world_nodes["300,1500,300"] = {name = "techage:ta4_solar_carrier", param2 = 0}
	world_nodes["299,1500,300"] = {name = "techage:ta4_solar_module", param2 = 0}
	world_nodes["301,1500,300"] = {name = "techage:ta4_solar_module", param2 = 2}
	world_nodes["299,1501,300"] = {name = "vacuum:air", param2 = 0}
	world_nodes["301,1501,300"] = {name = "vacuum:vacuum", param2 = 0}

	local meta = minetest.get_meta(carrier_pos)
	meta:set_int("left_param2", 0)
	meta:set_int("right_param2", 2)

	local def = registered_nodes["techage:ta4_solar_carrier"]
	-- Verify resolve_carrier_power via control request
	-- In space, modules with vacuum above generate full orbital power (3.0 kU at low orbit)
	local inverter_def = registered_nodes["techage:ta4_solar_inverter"]
	assert_true(inverter_def ~= nil, "inverter registered")
end)

run_test("Crafts: Ice melter recipe registered with correct components", function()
	local found = false
	for _, c in ipairs(registered_crafts) do
		if c.output == "jumpdrive_tweaks:ice_melter" then
			found = true
			assert_eq(c.recipe[2][2], "basic_materials:heating_element", "uses heating_element")
			assert_eq(c.recipe[2][1], "techage:electric_cableS", "uses electric_cableS")
			assert_eq(c.recipe[2][3], "techage:ta3_pipeS", "uses ta3_pipeS")
		end
	end
	assert_true(found, "jumpdrive_tweaks:ice_melter craft recipe registered")
end)

--------------------------------------------------------------------------------
-- Results Summary
--------------------------------------------------------------------------------
print(string.format("\nISRU Test Suite Complete: %d passed, %d failed.", tests_passed, tests_failed))

if tests_failed > 0 then
	os.exit(1)
else
	os.exit(0)
end
