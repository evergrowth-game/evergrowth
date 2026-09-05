-- other_worlds_tweaks/init.lua

local modpath = minetest.get_modpath("other_worlds_tweaks")

dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/gravity.lua")
dofile(modpath .. "/climate_hook.lua")

minetest.log("action", "[other_worlds_tweaks] Loaded space worldgen tweaks, rich ores, gravity monoids, and climate hooks.")
