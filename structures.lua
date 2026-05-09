local modpath = minetest.get_modpath("evergrowth_villages")
local schem_dir = modpath .. "/schematics/"

-- This table maps our logical building IDs to the actual .mts files
-- and defines what NPCs should spawn in them (if any).
local building_defs = {
    -- Basic Housing
    house_1 = { file = "house_1_bed.mts", profession = nil, y_offset = 1, rot_offset = 180, spawn_y_offset = 0.5, spawn_pos_offset = {x=0, z=0} },
    house_2 = { file = "house_2_bed.mts", profession = nil, y_offset = 1, rot_offset = 180, spawn_y_offset = 0.5, spawn_pos_offset = {x=0, z=0} },
    house_3 = { file = "house_3_bed.mts", profession = nil, y_offset = 1, rot_offset = 180, spawn_y_offset = 0.5, spawn_pos_offset = {x=0, z=0} },
    house_4 = { file = "house_4_bed.mts", profession = nil, y_offset = 1, rot_offset = 180, spawn_y_offset = 0.5, spawn_pos_offset = {x=0, z=0} },
    
    -- Trades
    smithy = { file = "blacksmith.mts", profession = "smith", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    toolsmith = { file = "toolsmith.mts", profession = "smith", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    weaponsmith = { file = "weaponsmith.mts", profession = "smith", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    butcher = { file = "butcher.mts", profession = "merchant", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=2, z=2} },
    cartographer = { file = "cartographer.mts", profession = "merchant", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    leather_worker = { file = "leather_worker.mts", profession = "merchant", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=-2, z=2} },
    fletcher = { file = "fletcher.mts", profession = "gunsmith", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    mason = { file = "mason.mts", profession = "miner", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    library = { file = "library.mts", profession = "librarian", y_offset = 1, rot_offset = 180, spawn_y_offset = 2.2, spawn_pos_offset = {x=-4, z=-4} },
    fishery = { file = "fishery.mts", profession = "merchant", y_offset = -2, rot_offset = 180, spawn_y_offset = 2.5, spawn_pos_offset = {x=0, z=0} },
    mill = { file = "mill.mts", profession = "farmer", y_offset = 1, rot_offset = 0, spawn_y_offset = 2.5, spawn_pos_offset = {x=0, z=0} },
    
    -- Farming
    farm_small_1 = { file = "farm_small_1.mts", profession = "farmer", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=3, z=3} },
    farm_small_2 = { file = "farm_small_2.mts", profession = "farmer", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=-3, z=3} },
    farm_large_1 = { file = "farm_large_1.mts", profession = "farmer", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=4, z=4} },
    farm = { file = "farm.mts", profession = "farmer", y_offset = 1, rot_offset = 0, spawn_y_offset = 1.5, spawn_pos_offset = {x=-4, z=4} },
    
    -- Civics
    well = { file = "well.mts", profession = nil, y_offset = -1, rot_offset = 0, spawn_y_offset = 0, spawn_pos_offset = {x=0, z=0} },
    chapel = { file = "chapel.mts", profession = "mage", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    church = { file = "church.mts", profession = "mage", y_offset = 1, rot_offset = 180, spawn_y_offset = 1.5, spawn_pos_offset = {x=0, z=0} },
    belltower = { file = "belltower.mts", profession = nil, y_offset = 1, rot_offset = 180, spawn_y_offset = 0.5, spawn_pos_offset = {x=0, z=0} },
}

local structures = {}

-- Load sizing data dynamically from the .mts files
for key, def in pairs(building_defs) do
    local path = schem_dir .. def.file
    local schem_info = minetest.read_schematic(path, {write_yslice_prob="none"})
    
    if schem_info and schem_info.size then
        structures[key] = {
            file = path,
            profession = def.profession,
            size = schem_info.size, -- {x, y, z}
            y_offset = def.y_offset or 0,
            rot_offset = def.rot_offset or 0,
            spawn_y_offset = def.spawn_y_offset or 0,
            spawn_pos_offset = def.spawn_pos_offset or {x=0, z=0},
            extra_replacements = def.extra_replacements,
        }
    else
        minetest.log("warning", "[evergrowth_villages] Failed to load schematic size for " .. path)
    end
end

return structures
