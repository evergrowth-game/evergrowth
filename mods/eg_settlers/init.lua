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

dofile(modpath .. "/api/aliases.lua")
dofile(modpath .. "/npc/trades.lua")
dofile(modpath .. "/npc/companions.lua")
dofile(modpath .. "/npc/npc_behavior.lua")
dofile(modpath .. "/npc/spawners.lua")
dofile(modpath .. "/api/settlement.lua")
dofile(modpath .. "/town/contracts.lua")
dofile(modpath .. "/town/ward_stone.lua")
dofile(modpath .. "/api/settlement_db.lua")
dofile(modpath .. "/town/town_ledger.lua")
dofile(modpath .. "/town/job_board.lua")
dofile(modpath .. "/town/town_depot.lua")
dofile(modpath .. "/town/town_granary.lua")
dofile(modpath .. "/docs/guide_content.lua")

