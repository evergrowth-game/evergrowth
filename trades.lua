--[[
    Evergrowth Villages - Trade Definitions & Names
    ===============================================
    This module defines the available trades for every profession in the mod, 
    including the high-value expert traders (Technologist, Gunsmith, etc.). 
    It also stores the arrays of male and female names used when spawning NPCs.
    
    Feeds Into:
    - spawners.lua: Uses `trades_list` and name lists when mapping entities.
]]--

-- DEFINE TRADES (mobs_npc format: { "goods_item count", "price_item count", chance })
evergrowth_villages.trades_list = {
    farmer = {
        -- Buys
        {"farming:wheat 10", "default:gold_lump 1", 100},
        {"farming:bread 5", "default:gold_lump 1", 100},
        {"farming:seed_wheat 5", "default:gold_lump 1", 100},
        -- Sells
        {"default:gold_lump 1", "farming:wheat 15", 100},
        {"default:gold_lump 1", "farming:cotton 10", 100},
        {"default:gold_lump 1", "farming:tomato 10", 100},
        {"default:gold_lump 1", "farming:potato 10", 100},
        {"default:gold_lump 1", "farming:corn 10", 100},
    },
    smith = {
        -- Buys
        {"default:pick_steel 1", "default:gold_lump 5", 100},
        {"default:shovel_steel 1", "default:gold_lump 4", 100},
        {"default:axe_steel 1", "default:gold_lump 5", 100},
        {"default:sword_steel 1", "default:gold_lump 8", 100},
        {"default:chest_locked 1", "default:gold_lump 3", 100},
        -- Sells
        {"default:gold_lump 1", "default:coal_lump 20", 100},
        {"default:gold_lump 3", "default:iron_lump 15", 100},
        {"default:gold_lump 8", "default:steel_ingot 10", 100},
    },
    merchant = {
        -- Buys
        {"default:book 1", "default:gold_lump 2", 100},
        {"default:torch 10", "default:gold_lump 1", 100},
        {"default:glass 10", "default:gold_lump 1", 100},
        {"wool:red 5", "default:gold_lump 2", 100},
        {"wool:blue 5", "default:gold_lump 2", 100},
        -- Sells
        {"default:gold_lump 20", "default:diamond 1", 100},
        {"default:gold_lump 3", "default:mese_crystal 1", 100},
        {"default:gold_lump 5", "wine:bottle_wine 5", 100},
        {"default:gold_lump 5", "wine:bottle_beer 5", 100},
    },
    brewer = {
        -- Buys
        {"wine:bottle_wine 1", "default:gold_lump 2", 100},
        {"wine:bottle_beer 1", "default:gold_lump 2", 100},
        {"wine:bottle_cider 1", "default:gold_lump 2", 100},
        -- Sells
        {"default:gold_lump 1", "farming:wheat 10", 100},
        {"default:gold_lump 1", "default:apple 10", 100},
        {"default:gold_lump 1", "farming:grapes 10", 100},
        {"default:gold_lump 5", "wine:wine_barrel 1", 100},
    },
    lumberjack = {
        -- Buys
        {"default:wood 10", "default:gold_lump 1", 100},
        {"default:sapling 5", "default:gold_lump 1", 100},
        {"default:apple 10", "default:gold_lump 1", 100},
        -- Sells
        {"default:gold_lump 1", "default:wood 20", 100},
        {"default:gold_lump 1", "default:junglewood 20", 100},
        {"default:gold_lump 1", "default:pine_wood 20", 100},
        {"default:gold_lump 1", "default:acacia_wood 20", 100},
        {"default:gold_lump 1", "default:aspen_wood 20", 100},
        {"default:gold_lump 3", "default:axe_steel 1", 100},
    },
    miner = {
        -- Buys
        {"default:coal_lump 10", "default:gold_lump 2", 100},
        {"default:iron_lump 5", "default:gold_lump 3", 100},
        {"default:cobble 50", "default:gold_lump 1", 100},
        -- Sells
        {"default:gold_lump 1", "default:coal_lump 15", 100},
        {"default:gold_lump 3", "default:pick_steel 1", 100},
        {"default:gold_lump 8", "tnt:tnt 1", 50},
    },
    librarian = {
        -- Buys
        {"default:paper 10", "default:gold_lump 1", 100},
        {"default:book 1", "default:gold_lump 2", 100},
        {"default:bookshelf 1", "default:gold_lump 5", 100},
        -- Sells
        {"default:gold_lump 1", "default:paper 20", 100},
        {"default:gold_lump 1", "dye:black 5", 100},
        {"default:gold_lump 1", "default:book 2", 100},
        {"default:gold_lump 2", "magic_materials:enchanted_page 1", 100},
    },
    mage = {
        -- Buys
        {"default:mese_crystal 1", "default:gold_lump 5", 100},
        {"default:obsidian 5", "default:gold_lump 5", 100},
        {"ethereal:etherium_dust 1", "default:gold_lump 3", 100},
        -- {"x_enchanting:table 1", "default:gold_lump 20", 100},
        {"bweapons_magic_pack:tome_fireball 1", "default:gold_lump 10", 100},
        {"bweapons_magic_pack:tome_iceshard 1", "default:gold_lump 10", 100},
        {"bweapons_magic_pack:tome_electrosphere 1", "default:gold_lump 10", 100},
        -- Sells
        {"default:gold_lump 2", "default:mese_crystal 1", 100},
        {"default:gold_lump 5", "magic_materials:arcanite_crystal 1", 80},
        {"default:gold_lump 5", "magic_materials:februm_crystal 1", 80},
        {"default:gold_lump 1", "ethereal:etherium_dust 1", 100},
        -- {"default:gold_lump 10", "x_enchanting:table 1", 100},
        -- {"default:gold_lump 1", "default:book 1", 100},
    },
    technologist = {
        -- NPC Sells (Trader Sells, Player Buys)
        {"techage:electric_cableS 10", "default:gold_lump 2", 100},
        {"techage:ta4_power_cableS 10", "default:gold_lump 5", 100},
        {"techage:power_pole 2", "default:gold_lump 3", 100},
        {"techage:powerswitch 1", "default:gold_lump 5", 100},
        {"techage:ta3_motor_off 1", "default:gold_lump 10", 100},
        {"techage:ta4_battery 1", "default:gold_lump 15", 100},
        {"techage:ta4_solar_module 1", "default:gold_lump 25", 100},
        {"techage:ta4_lua_controller 1", "default:gold_lump 20", 100},
        -- NPC Buys (Trader Buys, Player Sells)
        {"default:gold_lump 6", "default:copper_ingot 10", 100},
        {"default:gold_lump 2", "basic_materials:plastic_sheet 10", 100},
        -- {"default:gold_lump 2", "default:coal_lump 10", 100},
    },
    gunsmith = {
        -- NPC Sells (Trader Sells, Player Buys)
        {"bweapons_firearms_pack:pistol_round 20", "default:gold_lump 5", 100},
        {"bweapons_firearms_pack:shotgun_shell 10", "default:gold_lump 5", 100},
        {"bweapons_firearms_pack:rifle_round 20", "default:gold_lump 5", 100},
        {"bweapons_firearms_pack:pistol 1", "default:gold_lump 15", 100},
        {"bweapons_firearms_pack:shotgun 1", "default:gold_lump 25", 100},
        {"bweapons_firearms_pack:double_barrel 1", "default:gold_lump 25", 100},
        {"bweapons_firearms_pack:rifle 1", "default:gold_lump 30", 100},
        -- NPC Buys (Trader Buys, Player Sells)
        {"default:gold_lump 8", "default:steel_ingot 10", 100},
        {"default:gold_lump 6", "default:copper_lump 10", 100},
        {"default:gold_lump 3", "tnt:gunpowder 10", 100},
    },
    carpenter = {
        -- NPC Sells (Trader Sells, Player Buys)
        {"xdecor:workbench 1", "default:gold_lump 5", 100},
        {"xdecor:barrel 1", "default:gold_lump 4", 100},
        {"xdecor:lantern 5", "default:gold_lump 3", 100},
        {"xdecor:cushion_block 5", "default:gold_lump 2", 100},
        {"xdecor:chair 4", "default:gold_lump 2", 100},
        {"xdecor:table 1", "default:gold_lump 3", 100},
        -- NPC Buys (Trader Buys, Player Sells)
        {"default:gold_lump 2", "default:cobble 100", 100},
        {"default:gold_lump 2", "default:wood 40", 100},
        {"default:gold_lump 2", "default:clay_lump 40", 100},
        {"default:gold_lump 2", "wool:white 20", 100},
    },
    mechanic = {
        -- NPC Sells (Trader Sells, Player Buys)
        {"automobiles_lib:engine 1", "default:gold_lump 30", 100},
        {"automobiles_lib:wheel 4", "default:gold_lump 10", 100},
        {"automobiles_motorcycle:motorcycle 1", "default:gold_lump 40", 100},
        {"automobiles_buggy:buggy 1", "default:gold_lump 60", 100},
        {"automobiles_beetle:beetle 1", "default:gold_lump 80", 100},
        {"automobiles_coupe:coupe 1", "default:gold_lump 100", 100},
        -- NPC Buys (Trader Buys, Player Sells)
        {"default:gold_lump 36", "default:steelblock 5", 100},
        {"default:gold_lump 10", "techage:ta3_barrel_oil 1", 100},
    },
}

-- NAMES LIST
evergrowth_villages.female_names = {
    "Alice", "Beth", "Catherine", "Diana", "Elena", "Fiona", "Grace", "Hannah",
    "Isabel", "Julia", "Kara", "Lily", "Maria", "Nora", "Olivia", "Penny",
    "Quinn", "Rachel", "Sarah", "Tara", "Uma", "Violet", "Wendy", "Yara", "Zoe",
    "Agatha", "Beatrice", "Clara", "Dorothy", "Edith", "Flora", "Gertrude"
}

evergrowth_villages.male_names = {
    "Arthur", "Ben", "Charles", "David", "Edward", "Frank", "George", "Henry",
    "Isaac", "Jack", "Kevin", "Leo", "Michael", "Nathan", "Oscar", "Peter",
    "Quincy", "Robert", "Sam", "Thomas", "Ulysses", "Victor", "William", "Xavier", 
    "Alfred", "Barnaby", "Cecil", "Desmond", "Edwin", "Fletcher", "Gerald"
}
