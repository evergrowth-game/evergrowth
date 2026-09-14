-- eg_dungeon_tweaks: Main entry point

local modpath = minetest.get_modpath("eg_dungeon_tweaks")

dofile(modpath .. "/loot_pool.lua")
dofile(modpath .. "/dungeons.lua")
dofile(modpath .. "/open_world_loot.lua")
dofile(modpath .. "/raider_spawns.lua")

eg_dungeon_tweaks = dungeon_tweaks

minetest.log("action", "[eg_dungeon_tweaks] Initialized dungeon and open-world loot tweaks successfully")
