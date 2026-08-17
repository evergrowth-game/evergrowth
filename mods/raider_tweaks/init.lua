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

-- Fix raiders collision boxes to match actual model origins and full heights
-- Pirate & Plundererstick models have origin at feet (y = 0 to ~1.9)
local feet_origin_box = {-0.4, -0.01, -0.4, 0.4, 1.9, 0.4}
for _, mob_name in ipairs({"raiders:pirate", "raiders:plundererstick"}) do
	local ent = minetest.registered_entities[mob_name]
	if ent then
		if ent.initial_properties then
			ent.initial_properties.collisionbox = feet_origin_box
			ent.initial_properties.selectionbox = feet_origin_box
		end
		ent.base_colbox = feet_origin_box
		ent.base_selbox = feet_origin_box
	end
end

-- Plunderercrossbow & Plundererflask models have origin at waist (y = -1.0 to 0.85)
local waist_origin_box = {-0.35, -1.0, -0.35, 0.35, 0.85, 0.35}
for _, mob_name in ipairs({"raiders:plunderercrossbow", "raiders:plundererflask"}) do
	local ent = minetest.registered_entities[mob_name]
	if ent then
		if ent.initial_properties then
			ent.initial_properties.collisionbox = waist_origin_box
			ent.initial_properties.selectionbox = waist_origin_box
		end
		ent.base_colbox = waist_origin_box
		ent.base_selbox = waist_origin_box
	end
end

-- Disable taming/capturing and increase gold lump drop yield on all raiders
local raider_drops = {
	{name = "default:gold_lump", chance = 1, min = 2, max = 5},
}

for _, mob_name in ipairs({"raiders:pirate", "raiders:plundererstick", "raiders:plunderercrossbow", "raiders:plundererflask"}) do
	local ent = minetest.registered_entities[mob_name]
	if ent then
		ent.on_rightclick = nil
		ent.do_punch = nil
		ent.drops = raider_drops
	end
end

minetest.log("action", "[raider_tweaks] Enhanced spawning, collision box fixes, untameable settings, and updated drops for raiders loaded")

