-- Load custom mechanics and commands extracted from local climate mod copy
local modpath = minetest.get_modpath("climate_tweaks")

dofile(modpath .. "/regional_weather/mechanics.lua")
dofile(modpath .. "/regional_weather/forecast.lua")
