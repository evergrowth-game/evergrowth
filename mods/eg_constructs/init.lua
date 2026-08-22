--[[
    Evergrowth Constructs - Mod Entry Point
    ======================================
    Loads items and entities for commandable construct companions (Clay Golem & Automaton).
]]--

local modpath = minetest.get_modpath("eg_constructs")

dofile(modpath .. "/entities.lua")
dofile(modpath .. "/items.lua")
