-- tests/test_i_have_hands.lua
-- Unit tests for i_have_hands mod in space/vacuum environments and nil safety

local test_count = 0
local pass_count = 0

local function assert_eq(actual, expected, msg)
	test_count = test_count + 1
	if actual == expected then
		pass_count = pass_count + 1
		print(string.format("  [PASS] %s", msg))
	else
		print(string.format("  [FAIL] %s: expected %s, got %s", msg, tostring(expected), tostring(actual)))
		error("Assertion failed")
	end
end

local function assert_true(cond, msg)
	assert_eq(not not cond, true, msg)
end

-- Mock Minetest environment
local world_nodes = {}
local node_metas = {}
local registered_entities = {}

core = {
	get_modpath = function(mod)
		if mod == "i_have_hands" then return "mods/i_have_hands" end
		return nil
	end,
	get_mod_storage = function()
		local store = {}
		return {
			get_string = function(self, k) return store[k] or "" end,
			set_string = function(self, k, v) store[k] = v end,
			get_keys = function(self)
				local keys = {}
				for k in pairs(store) do table.insert(keys, k) end
				return keys
			end,
		}
	end,
	registered_nodes = {
		["air"] = { name = "air", drawtype = "airlike", buildable_to = true },
		["vacuum:vacuum"] = { name = "vacuum:vacuum", drawtype = "airlike", buildable_to = true },
		["asteroid:atmos"] = { name = "asteroid:atmos", drawtype = "airlike", buildable_to = true },
		["default:stone"] = { name = "default:stone", buildable_to = false, sounds = { place = { name = "default_place_node" } } },
		["default:chest"] = { name = "default:chest", buildable_to = false, sounds = { place = { name = "default_place_node" } } },
	},
	registered_items = {
		[""] = { on_place = function(itemstack) return itemstack end },
	},
	registered_globalsteps = {},
	registered_on_dieplayers = {},
	register_entity = function(name, def)
		registered_entities[name] = def
	end,
	register_chatcommand = function() end,
	register_privilege = function() end,
	register_globalstep = function(fn)
		table.insert(core.registered_globalsteps, fn)
	end,
	register_on_dieplayer = function(fn)
		table.insert(core.registered_on_dieplayers, fn)
	end,
	override_item = function() end,
	get_node = function(pos)
		local k = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		return world_nodes[k] or { name = "air" }
	end,
	set_node = function(pos, node)
		local k = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		world_nodes[k] = { name = node.name, param2 = node.param2 or 0 }
	end,
	remove_node = function(pos)
		local k = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		world_nodes[k] = { name = "vacuum:vacuum" }
	end,
	get_meta = function(pos)
		local k = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		if not node_metas[k] then
			node_metas[k] = {
				store = {},
				get_string = function(self, name) return self.store[name] or "" end,
				set_string = function(self, name, val) self.store[name] = val end,
				get_int = function(self, name) return self.store[name] or 0 end,
				set_int = function(self, name, val) self.store[name] = val end,
				from_table = function(self, t) self.store = t or {} end,
				to_table = function(self) return self.store end,
			}
		end
		return node_metas[k]
	end,
	get_node_timer = function()
		return { start = function() end, stop = function() end }
	end,
	sound_play = function() end,
	is_protected = function() return false end,
	get_objects_inside_radius = function() return {} end,
	get_connected_players = function() return {} end,
	serialize = function(t) return "DUMMY_SERIALIZED" end,
	deserialize = function(s) return { node = { name = "default:chest" }, data = {} } end,
	dir_to_fourdir = function() return 0 end,
	yaw_to_dir = function() return { x = 0, y = 0, z = 1 } end,
	add_entity = function(pos, name)
		if not pos or type(pos) ~= "table" then
			error("Invalid vector (expected table got nil)")
		end
		return {
			set_rotation = function() end,
			set_attach = function() end,
			set_animation = function() end,
			remove = function() end,
		}
	end,
}
minetest = core

vector = {
	new = function(x, y, z) return { x = x or 0, y = y or 0, z = z or 0 } end,
	round = function(v) return { x = math.floor(v.x + 0.5), y = math.floor(v.y + 0.5), z = math.floor(v.z + 0.5) } end,
	from_string = function(s)
		local x, y, z = s:match("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)")
		if x then return { x = tonumber(x), y = tonumber(y), z = tonumber(z) } end
		return nil
	end,
	to_string = function(v) return string.format("%d,%d,%d", v.x, v.y, v.z) end,
}

print("Starting I Have Hands Space Compatibility Test Suite...")

-- Load i_have_hands upstream
dofile("mods/i_have_hands/init.lua")

-- Load i_have_hands_tweaks
dofile("mods/i_have_hands_tweaks/init.lua")

local find_empty_position = i_have_hands_tweaks.find_empty_position
local is_empty_or_buildable = i_have_hands_tweaks.is_empty_or_buildable
local placeDown = i_have_hands_tweaks.placeDown
local animatePlace = i_have_hands_tweaks.animatePlace
local to_animate = i_have_hands_tweaks.to_animate

-- Test 1: find_empty_position in high-altitude space (Y=1200)
local space_pos = { x = 10, y = 1200, z = 20 }
world_nodes["10,1200,20"] = { name = "vacuum:vacuum" }
local empty_pos = find_empty_position(space_pos, 3)
assert_true(empty_pos ~= nil, "find_empty_position returns non-nil at Y=1200 in vacuum")
assert_eq(empty_pos.y, 1200, "find_empty_position identifies Y=1200 as valid empty space")

-- Test 2: is_empty_or_buildable checks
assert_true(is_empty_or_buildable({ x = 0, y = 1000, z = 0 }), "Air is buildable/empty")
world_nodes["0,1000,0"] = { name = "vacuum:vacuum" }
assert_true(is_empty_or_buildable({ x = 0, y = 1000, z = 0 }), "vacuum:vacuum is buildable/empty")
world_nodes["0,1000,0"] = { name = "asteroid:atmos" }
assert_true(is_empty_or_buildable({ x = 0, y = 1000, z = 0 }), "asteroid:atmos is buildable/empty")
world_nodes["0,1000,0"] = { name = "default:stone" }
assert_eq(is_empty_or_buildable({ x = 0, y = 1000, z = 0 }), false, "default:stone is solid and not empty")

-- Test 3: placeDown with nil position safety
local mock_held_obj = {
	entity = { name = "i_have_hands:held", initial_pos = "10,1200,20" },
	get_luaentity = function(self) return self.entity end,
	get_properties = function(self) return { wield_item = "default:chest" } end,
	set_detach = function() end,
	set_yaw = function() end,
	get_rotation = function() return { x = 0, y = 0, z = 0 } end,
	set_properties = function() end,
	set_attach = function() end,
	remove = function() end,
	get_pos = function() return { x = 10, y = 1200, z = 20 } end,
}

local mock_player = {
	pos = { x = 10, y = 1200, z = 20 },
	get_pos = function(self) return self.pos end,
	get_player_control = function() return { sneak = true } end,
	get_player_name = function() return "Astronaut" end,
	get_children = function() return { mock_held_obj } end,
	get_look_horizontal = function() return 0 end,
	get_wielded_item = function() return { get_name = function() return "jumpdrive_tweaks:beacon" end } end,
	set_bone_override = function() end,
}

-- Test placeDown when above is nil (must fallback to placer pos and not push nil)
placeDown(mock_player, 0, mock_held_obj, nil, 0, "default:chest")
assert_true(#to_animate > 0, "placeDown queued animation frame")
assert_true(to_animate[1].pos ~= nil, "to_animate pos is populated from player position fallback")

-- Test 4: animatePlace runs all 10 frames safely in space without crashing
world_nodes["10,1200,20"] = { name = "vacuum:vacuum" }
for frame = 0, 10 do
	animatePlace()
end
assert_eq(world_nodes["10,1200,20"].name, "default:chest", "Chest successfully placed down at Y=1200 in space")
assert_eq(#to_animate, 0, "Animation queue cleanly finalized and emptied")

print(string.format("\nI Have Hands Space Compatibility Test Suite Complete: %d passed, 0 failed.", pass_count))
