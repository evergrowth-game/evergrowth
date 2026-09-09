-- tests/space_modpack/test_climate_skybox.lua
-- Unit tests for space realm calculations and Earth skybox rendering

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

-- Minimal Minetest test harness
minetest = {
	registered_globalsteps = {},
	register_globalstep = function(fn)
		table.insert(minetest.registered_globalsteps, fn)
	end,
	registered_on_mods_loaded = {},
	register_on_mods_loaded = function(fn)
		table.insert(minetest.registered_on_mods_loaded, fn)
	end,
	registered_on_leaveplayers = {},
	register_on_leaveplayer = function(fn)
		table.insert(minetest.registered_on_leaveplayers, fn)
	end,
	get_connected_players = function()
		return {}
	end,
	log = function() end,
}

climate_api = nil
climate_mod = nil

print("Starting Climate & Earth Skybox Test Suite...")

-- Load module
dofile("mods/space_modpack/other_worlds_tweaks/climate_hook.lua")

local climate = other_worlds_tweaks_climate
assert_true(climate ~= nil, "other_worlds_tweaks_climate table is exposed")

-- Test 1: Altitude to Realm mapping
assert_eq(climate.get_realm(-50), "earth", "Ground realm at Y=-50")
assert_eq(climate.get_realm(0), "earth", "Ground realm at Y=0")
assert_eq(climate.get_realm(999), "earth", "Ground realm at Y=999")
assert_eq(climate.get_realm(1000), "space_low", "Low orbit realm at Y=1000")
assert_eq(climate.get_realm(2499), "space_low", "Low orbit realm at Y=2499")
assert_eq(climate.get_realm(2500), "space_mid", "Mid orbit realm at Y=2500")
assert_eq(climate.get_realm(4499), "space_mid", "Mid orbit realm at Y=4499")
assert_eq(climate.get_realm(4500), "space_high", "High orbit realm at Y=4500")
assert_eq(climate.get_realm(5999), "space_high", "High orbit realm at Y=5999")
assert_eq(climate.get_realm(6000), "redsky", "Mars realm at Y=6000")
assert_eq(climate.get_realm(6999), "redsky", "Mars realm at Y=6999")
assert_eq(climate.get_realm(7000), "blackness", "Deep space realm at Y=7000")
assert_eq(climate.get_realm(20000), "blackness", "Deep space realm at Y=20000")

-- Test 2: Skybox Face 3 (-Y bottom face) contains appropriate Earth texture
local skyboxes = climate.skyboxes
assert_true(skyboxes.space_low ~= nil, "space_low skybox exists")
assert_eq(#skyboxes.space_low, 6, "space_low has 6 faces")
assert_true(skyboxes.space_low[3]:find("space_earth_low.png") ~= nil, "space_low face 3 has space_earth_low.png")
assert_true(skyboxes.space_low[3]:find("%^%[transformR270") ~= nil, "space_low face 3 has R270 transform")

assert_true(skyboxes.space_mid[3]:find("space_earth_mid.png") ~= nil, "space_mid face 3 has space_earth_mid.png")
assert_true(skyboxes.space_high[3]:find("space_earth_high.png") ~= nil, "space_high face 3 has space_earth_high.png")
assert_true(skyboxes.redsky[3]:find("space_earth_far.png") ~= nil, "redsky face 3 has space_earth_far.png")
assert_true(skyboxes.blackness[3]:find("space_earth_far.png") ~= nil, "blackness face 3 has space_earth_far.png")

-- Test 3: Standalone player:set_sky execution
local mock_player = {
	name = "Astronaut",
	pos = {x = 0, y = 1500, z = 0},
	sky_calls = {},
	sun_calls = {},
	moon_calls = {},
	stars_calls = {},
	cloud_calls = {},
	get_player_name = function(self) return self.name end,
	get_pos = function(self) return self.pos end,
	set_sky = function(self, def) table.insert(self.sky_calls, def) end,
	set_sun = function(self, def) table.insert(self.sun_calls, def) end,
	set_moon = function(self, def) table.insert(self.moon_calls, def) end,
	set_stars = function(self, def) table.insert(self.stars_calls, def) end,
	set_clouds = function(self, def) table.insert(self.cloud_calls, def) end,
}

climate.apply_space_skybox(mock_player, "space_low")
assert_eq(#mock_player.sky_calls, 1, "set_sky called once")
assert_eq(mock_player.sky_calls[1].type, "skybox", "skybox type set")
assert_eq(mock_player.sky_calls[1].textures[3], skyboxes.space_low[3], "correct -Y face applied")
assert_eq(mock_player.sun_calls[1].scale, 1.0, "sun scale is 1.0 in space_low")

-- Test 4: Blackness and Redsky sun/star settings
mock_player.sky_calls = {}
mock_player.sun_calls = {}
mock_player.stars_calls = {}
climate.apply_space_skybox(mock_player, "blackness")
assert_eq(mock_player.sun_calls[1].scale, 0.1, "blackness sun scale is 0.1")
assert_eq(mock_player.stars_calls[1].visible, true, "blackness stars visible")

mock_player.sun_calls = {}
mock_player.stars_calls = {}
climate.apply_space_skybox(mock_player, "redsky")
assert_eq(mock_player.sun_calls[1].scale, 0.5, "redsky sun scale is 0.5")
assert_eq(mock_player.stars_calls[1].visible, false, "redsky stars hidden")

-- Test 5: Globalstep state caching (no re-triggering when altitude stays in same bracket)
minetest.get_connected_players = function() return {mock_player} end
mock_player.sky_calls = {}
local globalstep = minetest.registered_globalsteps[1]

-- First step at Y=1500 (transitions to space_low)
mock_player.pos.y = 1500
globalstep(1.5)
assert_eq(#mock_player.sky_calls, 1, "Initial step triggers skybox update")

-- Second step at Y=1600 (still in space_low, should NOT call set_sky again)
mock_player.pos.y = 1600
globalstep(1.5)
assert_eq(#mock_player.sky_calls, 1, "Same bracket does not trigger duplicate update")

-- Third step at Y=3000 (transitions to space_mid)
mock_player.pos.y = 3000
globalstep(1.5)
assert_eq(#mock_player.sky_calls, 2, "Transition to space_mid triggers update")
assert_eq(mock_player.sky_calls[2].textures[3], skyboxes.space_mid[3], "space_mid texture applied")

-- Test 6: Player leave cleanup
local on_leave = minetest.registered_on_leaveplayers[1]
on_leave(mock_player)
assert_eq(climate.player_realm_state[mock_player.name], nil, "Player realm state cleared on leave")

print(string.format("\nClimate Skybox Test Suite Complete: %d passed, 0 failed.", pass_count))
