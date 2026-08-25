-- dungeon_tweaks: Deep underground raider spawns around bootynode blocks

if not minetest.get_modpath("raiders") or not minetest.global_exists("mobs") then
	return
end

-- Register active raider spawns near bootynodes across all underground depths
local raider_types = {
	{name = "raiders:pirate", chance = 6, count = 3},
	{name = "raiders:plundererstick", chance = 8, count = 2},
	{name = "raiders:plunderercrossbow", chance = 8, count = 2},
	{name = "raiders:plundererflask", chance = 10, count = 1},
}

for _, def in ipairs(raider_types) do
	if minetest.registered_entities[def.name] then
		mobs:spawn({
			name = def.name,
			nodes = {"raiders:bootynode"},
			neighbors = {"air"},
			min_light = 0,
			max_light = 14,
			interval = 12,
			active_object_count = def.count,
			chance = def.chance,
			min_height = -31000,
			max_height = def.name == "raiders:pirate" and -26 or 1000,
		})
	end
end

minetest.log("action", "[dungeon_tweaks] Registered deep underground raider mob spawns around bootynode blocks")
