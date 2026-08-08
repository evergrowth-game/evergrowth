--[[
    Evergrowth Settlers - Backward Compatibility Aliases
    ====================================================
    Maps all old `evergrowth_villages:*` node and item names to their new
    `eg_settlers:*` equivalents. This ensures existing worlds with placed
    nodes or inventory items from the old mod name continue to function.
]]--

-- Nodes
minetest.register_alias("evergrowth_villages:housing_deed", "eg_settlers:housing_deed")
minetest.register_alias("evergrowth_villages:ward_stone", "eg_settlers:ward_stone")

-- Profession Contracts (Unified to eg_settlers:hiring_contract)
minetest.register_alias("eg_settlers:contract_guard", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_farmer", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_smith", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_merchant", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_brewer", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_lumberjack", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_miner", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_librarian", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_mage", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_technologist", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_gunsmith", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_carpenter", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_automobile_mechanic", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_aircraft_mechanic", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_nautical_mechanic", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_fisher", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_rancher", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_roboticist", "eg_settlers:hiring_contract")

minetest.register_alias("evergrowth_villages:contract_guard", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_farmer", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_smith", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_merchant", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_brewer", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_lumberjack", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_miner", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_librarian", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_mage", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_technologist", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_gunsmith", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_carpenter", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:contract_mechanic", "eg_settlers:hiring_contract")
minetest.register_alias("eg_settlers:contract_mechanic", "eg_settlers:hiring_contract")
minetest.register_alias("evergrowth_villages:spawn_mechanic", "eg_settlers:spawn_automobile_mechanic")
minetest.register_alias("eg_settlers:spawn_mechanic", "eg_settlers:spawn_automobile_mechanic")
minetest.register_alias("evergrowth_villages:contract_fisher", "eg_settlers:hiring_contract")


-- Companion Contracts
minetest.register_alias("evergrowth_villages:contract_companion_male", "eg_settlers:contract_companion_male")
minetest.register_alias("evergrowth_villages:contract_companion_female", "eg_settlers:contract_companion_female")
minetest.register_alias("evergrowth_villages:contract_companion_relocation", "eg_settlers:contract_companion_relocation")

-- Villager Relocation
minetest.register_alias("evergrowth_villages:contract_villager_relocation", "eg_settlers:contract_villager_relocation")

-- Tools
minetest.register_alias("evergrowth_villages:wardrobe_wand", "eg_settlers:wardrobe_wand")
