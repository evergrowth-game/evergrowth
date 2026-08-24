--[[
    Evergrowth Companions - Mod Entry Point
    ======================================
    Domestic companion NPCs dual-tethered between wallmounted Companion Plaques
    (daytime home base) and player-owned beds (nighttime sleep).
]]--

local modpath = minetest.get_modpath("eg_companions")
eg_companions = {}

dofile(modpath .. "/behavior.lua")
dofile(modpath .. "/entities.lua")
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/items.lua")
dofile(modpath .. "/aliases.lua")
