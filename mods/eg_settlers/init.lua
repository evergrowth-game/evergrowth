--[[
    Evergrowth Settlers - Main Entry Point
    ======================================
    This is the master file for the `eg_settlers` mod. It initializes the
    global `eg_settlers` table and loads all of the specialized sub-modules
    in the correct dependency order.

    Sub-Modules:
    - trades.lua: Contains the trade definitions and name lists for all NPCs.
    - companions.lua: Handles companion NPC skins, states, and wardrobe interactions.
    - nametags.lua: Contains distance-based rendering logic for NPC nametags.
    - spawners.lua: Contains the mobs_npc entity spawning logic and LBM nodes.
    - contracts.lua: Registers the craftable spawner contracts for players.
]]--

local modpath = minetest.get_modpath("eg_settlers")

eg_settlers = {}

dofile(modpath .. "/aliases.lua")
dofile(modpath .. "/trades.lua")
dofile(modpath .. "/companions.lua")
dofile(modpath .. "/npc_behavior.lua")
dofile(modpath .. "/spawners.lua")
dofile(modpath .. "/settlement.lua")
dofile(modpath .. "/contracts.lua")
dofile(modpath .. "/ward_stone.lua")
dofile(modpath .. "/settlement_db.lua")
dofile(modpath .. "/town_ledger.lua")
dofile(modpath .. "/job_board.lua")
dofile(modpath .. "/town_depot.lua")
dofile(modpath .. "/town_granary.lua")
