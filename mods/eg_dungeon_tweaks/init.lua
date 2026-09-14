-- dungeon_tweaks: Main entry point

local modpath = minetest.get_modpath("dungeon_tweaks")

dofile(modpath .. "/loot_pool.lua")
dofile(modpath .. "/dungeons.lua")
dofile(modpath .. "/open_world_loot.lua")
dofile(modpath .. "/raider_spawns.lua")

minetest.log("action", "[dungeon_tweaks] Initialized dungeon and open-world loot tweaks successfully")
