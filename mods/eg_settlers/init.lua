--[[
    Evergrowth Villages - Main Entry Point
    ======================================
    This is the master file for the `evergrowth_villages` mod. It initializes the
    global `evergrowth_villages` table and loads all of the specialized sub-modules
    in the correct dependency order.

    Sub-Modules:
    - trades.lua: Contains the trade definitions and name lists for all NPCs.
    - companions.lua: Handles companion NPC skins, states, and wardrobe interactions.
    - nametags.lua: Contains distance-based rendering logic for NPC nametags.
    - spawners.lua: Contains the mobs_npc entity spawning logic and LBM nodes.
    - contracts.lua: Registers the craftable spawner contracts for players.
]]--

local modpath = minetest.get_modpath("evergrowth_villages")

evergrowth_villages = {}

dofile(modpath .. "/trades.lua")
dofile(modpath .. "/companions.lua")
dofile(modpath .. "/npc_behavior.lua")
dofile(modpath .. "/spawners.lua")
dofile(modpath .. "/settlement.lua")
dofile(modpath .. "/contracts.lua")
dofile(modpath .. "/ward_stone.lua")
