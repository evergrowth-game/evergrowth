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

-- Fix raiders truncated collision boxes to match standard humanoid dimensions
local humanoid_box = {-0.35, -1.0, -0.35, 0.35, 0.85, 0.35}

for _, mob_name in ipairs({"raiders:pirate", "raiders:plundererstick", "raiders:plunderercrossbow", "raiders:plundererflask"}) do
	local ent = minetest.registered_entities[mob_name]
	if ent then
		if ent.initial_properties then
			ent.initial_properties.collisionbox = humanoid_box
			ent.initial_properties.selectionbox = humanoid_box
		end
		ent.base_colbox = humanoid_box
		ent.base_selbox = humanoid_box
	end
end

minetest.log("action", "[raider_tweaks] Enhanced spawning and collision box fixes for raiders loaded")

