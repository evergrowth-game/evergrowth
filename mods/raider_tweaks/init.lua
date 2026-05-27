-- Enhanced spawning for Raiders in ruined structures
-- This ensures raiders spawn near the bootynodes (formerly chests) in ruins

mobs:spawn({
	name = "raiders:pirate",
	nodes = {"raiders:bootynode"},
	neighbors = {"air"},
	min_light = 0,
	interval = 10,  -- Faster spawns for ruins
	active_object_count = 3,
	chance = 5,     -- Higher chance
	min_height = -25,
	max_height = 1000,
})

minetest.log("action", "[raider_tweaks] Enhanced spawning for raiders loaded")
