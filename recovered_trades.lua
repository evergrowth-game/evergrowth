-- RECOVERED TRADE TABLES (from fresh_villages)
-- These can be adapted for mobs_npc custom traders.

-- 1. Farmer
local farmer_trades = {
    -- Buys
    {item = "farming:wheat", price = 1, buying = true},
    {item = "farming:cotton", price = 1, buying = true},
    {item = "wool:white", price = 2, buying = true},
    -- Sells
    {item = "farming:bread", price = 2, buying = false},
    {item = "farming:seed_wheat", price = 1, buying = false},
    {item = "farming:hoe_stone", price = 3, buying = false},
    {item = "bucket:bucket_water", price = 5, buying = false},
}

-- 2. Lumberjack
local lumberjack_trades = {
    -- Buys
    {item = "default:wood", price = 1, buying = true},
    {item = "default:sapling", price = 1, buying = true},
    {item = "default:apple", price = 2, buying = true},
    -- Sells
    {item = "default:axe_steel", price = 10, buying = false},
    {item = "default:sapling", price = 2, buying = false},
    {item = "default:wood", price = 2, buying = false},
    {item = "default:torch", price = 1, buying = false},
}

-- 3. Miner
local miner_trades = {
    -- Buys
    {item = "default:coal_lump", price = 2, buying = true},
    {item = "default:iron_lump", price = 3, buying = true},
    {item = "default:copper_lump", price = 3, buying = true},
    {item = "default:cobble", price = 1, buying = true},
    -- Sells
    {item = "default:pick_steel", price = 10, buying = false},
    {item = "default:shovel_steel", price = 8, buying = false},
    {item = "tnt:tnt", price = 20, buying = false},
    {item = "default:torch", price = 1, buying = false},
}

-- 4. Smith
local smith_trades = {
    -- Buys
    {item = "default:iron_lump", price = 3, buying = true},
    {item = "default:gold_lump", price = 5, buying = true},
    {item = "default:diamond", price = 20, buying = true},
    -- Sells
    {item = "default:sword_steel", price = 15, buying = false},
    {item = "default:pick_diamond", price = 50, buying = false},
    {item = "default:steel_ingot", price = 4, buying = false},
    {item = "3d_armor:chestplate_steel", price = 25, buying = false},
}

-- 5. Innkeeper
local innkeeper_trades = {
    -- Buys
    {item = "farming:bread", price = 1, buying = true},
    {item = "mobs:meat", price = 2, buying = true},
    {item = "wine:glass_wine", price = 5, buying = true},
    -- Sells
    {item = "farming:bread", price = 3, buying = false},
    {item = "wine:glass_wine", price = 8, buying = false},
    {item = "mobs:meat_cooked", price = 5, buying = false},
    {item = "beds:bed", price = 10, buying = false},
}

-- 6. Merchant (General Store)
local merchant_trades = {
    -- Buys
    {item = "default:gold_lump", price = 5, buying = true},
    {item = "default:diamond", price = 20, buying = true},
    {item = "default:mese_crystal", price = 10, buying = true},
    -- Sells
    {item = "default:book", price = 5, buying = false},
    {item = "default:glass", price = 2, buying = false},
    {item = "default:meselamp", price = 15, buying = false},
    {item = "flowers:rose", price = 2, buying = false},
}

return {
    farmer = farmer_trades,
    lumberjack = lumberjack_trades,
    miner = miner_trades,
    smith = smith_trades,
    innkeeper = innkeeper_trades,
    merchant = merchant_trades
}

--[[
Archived from init.lua prior to the Brewer replacement:
    innkeeper = {
        {"farming:wheat 10", "default:gold_lump 1", 100},
        {"mobs:meat 5", "default:gold_lump 1", 100},
        {"wine:glass_wine 1", "default:gold_lump 2", 50},
        {"default:gold_lump 1", "farming:bread 5", 100},
        {"default:gold_lump 2", "wine:glass_wine 1", 100},
        {"default:gold_lump 5", "beds:bed 1", 100},
    },
]]
