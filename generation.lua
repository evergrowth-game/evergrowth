--[[
    Evergrowth Villages - Village Generation
    ========================================
    Rewritten to support global master plans, cross-chunk deterministic generation,
    smooth Perlin terrain blending, and LBM anchors for high-quality .mts schematics.
]]--

local modpath = minetest.get_modpath("evergrowth_villages")
local structures = dofile(modpath .. "/structures.lua")

local ENABLE_GENERATION = minetest.settings:get_bool("evergrowth_villages_natural_generation", true)
local VILLAGE_CHANCE = tonumber(minetest.settings:get("evergrowth_villages_chance")) or 1
local GRID_SIZE = 180 

-- Global Registry for Cross-Chunk Master Plans
evergrowth_villages.active_villages = {}

local PALETTES = {
    default = { log="default:tree", wood="default:wood", stone="default:cobble", fence="default:fence_wood" },
    savanna = { log="default:acacia_tree", wood="default:acacia_wood", stone="default:cobble", fence="default:fence_acacia_wood" },
    savannah = { log="default:acacia_tree", wood="default:acacia_wood", stone="default:cobble", fence="default:fence_acacia_wood" },
    prairie = { log="ethereal:birch_trunk", wood="ethereal:birch_wood", stone="default:cobble", fence="ethereal:fence_birch" },
    grove = { log="ethereal:redwood_trunk", wood="ethereal:redwood_wood", stone="default:mossycobble", fence="ethereal:fence_redwood" },
    mediterranean = { log="ethereal:olive_trunk", wood="ethereal:olive_wood", stone="default:cobble", fence="ethereal:fence_olive" },
    bamboo = { log="ethereal:willow_trunk", wood="ethereal:willow_wood", stone="default:cobble", fence="ethereal:fence_willow" },
    mushroom = { log="ethereal:mushroom_trunk", wood="default:wood", stone="default:mossycobble", fence="ethereal:fence_mushroom" },
    grayness = { log="ethereal:willow_trunk", wood="ethereal:willow_wood", stone="default:cobble", fence="ethereal:fence_willow" },
    jumble = { log="default:jungletree", wood="default:junglewood", stone="default:mossycobble", fence="default:fence_junglewood" },
}

local function get_dependency_replacements(biome_name)
    local palette = PALETTES[biome_name] or PALETTES.default
    local replacements = {}
    
    replacements["mcl_core:wood"] = palette.wood
    replacements["mcl_core:tree"] = palette.log
    replacements["mcl_core:cobble"] = palette.stone
    replacements["mcl_core:dirt"] = "default:dirt"
    replacements["mcl_core:dirt_with_grass"] = "default:dirt_with_grass"
    replacements["mcl_core:gravel"] = "default:gravel"
    replacements["mcl_core:stone"] = "default:stone"
    replacements["mcl_core:glass"] = "default:glass"
    replacements["mcl_doors:door_wood_t"] = "doors:door_wood"
    replacements["mcl_doors:door_wood_b"] = "doors:door_wood"
    replacements["mcl_fences:fence"] = palette.fence
    -- Huge dictionary mapping compiled directly from the .mts files
    -- Workstations / Furniture / Decor
    replacements["mcl_anvils:anvil"] = "anvil:anvil"
    replacements["mcl_armor_stand:armor_stand"] = "default:fence_wood"
    replacements["mcl_barrels:barrel_closed"] = "xdecor:barrel"
    replacements["mcl_bells:bell_ceiling"] = "default:goldblock"
    replacements["mcl_blast_furnace:blast_furnace"] = "default:furnace"
    replacements["mcl_books:bookshelf"] = "default:bookshelf"
    replacements["mcl_brewing:stand_000"] = "default:fence_wood"
    replacements["mcl_cartography_table:cartography_table"] = "xdecor:table"
    replacements["mcl_cauldrons:cauldron"] = "xdecor:cauldron_empty"
    replacements["mcl_chests:chest_small"] = "default:chest"
    replacements["mcl_composters:composter"] = "xdecor:barrel"
    replacements["mcl_composters:composterx"] = "xdecor:barrel"
    replacements["mcl_core:stonebrick"] = "default:stonebrick"
    replacements["mcl_crafting_table:crafting_table"] = "xdecor:workbench"
    replacements["mcl_fletching_table:fletching_table"] = "xdecor:table"
    replacements["mcl_furnaces:furnace"] = "default:furnace"
    replacements["mcl_grindstone:grindstone"] = "x_enchanting:grindstone"
    replacements["mcl_itemframes:frame"] = "itemframes:frame"
    replacements["mcl_itemframes:glow_item_frame"] = "itemframes:frame"
    replacements["mcl_lectern:lectern"] = "x_enchanting:table"
    replacements["mcl_loom:loom"] = "default:wood"
    replacements["mcl_smithing_table:table"] = "xdecor:workbench"
    replacements["mcl_smoker:smoker"] = "default:furnace"
    replacements["mcl_stonecutter:stonecutter"] = "default:stone"

    -- Remove Item Frames (requested)
    replacements["mcl_itemframes:frame"] = "air"
    replacements["mcl_itemframes:glow_item_frame"] = "air"

    -- Beds
    replacements["mcl_beds:bed_brown_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_brown_top"] = "beds:bed_top"
    replacements["mcl_beds:bed_lime_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_lime_top"] = "beds:bed_top"
    replacements["mcl_beds:bed_pink_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_pink_top"] = "beds:bed_top"
    replacements["mcl_beds:bed_red_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_red_top"] = "beds:bed_top"
    replacements["mcl_beds:bed_white_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_white_top"] = "beds:bed_top"
    replacements["mcl_beds:bed_yellow_bottom"] = "beds:bed_bottom"
    replacements["mcl_beds:bed_yellow_top"] = "beds:bed_top"

    -- Core / Structural
    replacements["mcl_colorblocks:hardened_clay"] = "default:clay"
    replacements["mcl_core:andesite_smooth"] = "default:stone"
    replacements["mcl_core:brick_block"] = "default:brick"
    replacements["mcl_core:glass_light_blue"] = "default:glass"
    replacements["mcl_core:glass_magenta"] = "default:glass"
    replacements["mcl_core:ladder"] = "default:ladder_wood"
    replacements["mcl_core:lava_source"] = "default:lava_source"
    replacements["mcl_core:water_source"] = "default:water_source"
    replacements["mcl_core:stonebrickcarved"] = "default:stonebrick"

    -- Doors
    replacements["mcl_doors:door_oak_b_1"] = "doors:door_wood_a"
    replacements["mcl_doors:door_oak_b_2"] = "doors:door_wood_a"
    replacements["mcl_doors:door_oak_t_1"] = "doors:hidden"
    replacements["mcl_doors:door_oak_t_2"] = "doors:hidden"
    replacements["mcl_doors:trapdoor_oak_open"] = "doors:trapdoor"

    -- Farming
    replacements["mcl_farming:carrot"] = "farming:carrot"
    replacements["mcl_farming:potato"] = "farming:potato"
    replacements["mcl_farming:soil_wet"] = "farming:soil_wet"
    replacements["mcl_farming:wheat"] = "farming:wheat"
    replacements["mcl_villages:crop_flower_1"] = "farming:wheat_8"
    replacements["mcl_villages:crop_flower_2"] = "farming:wheat_8"
    replacements["mcl_villages:crop_flower_3"] = "farming:wheat_8"
    replacements["mcl_villages:crop_gourd_1"] = "farming:melon_8"
    replacements["mcl_villages:crop_gourd_2"] = "farming:melon_8"
    replacements["mcl_villages:crop_grain_1"] = "farming:wheat_8"
    replacements["mcl_villages:crop_grain_1x"] = "farming:wheat_8"
    replacements["mcl_villages:crop_grain_2"] = "farming:wheat_8"
    replacements["mcl_villages:crop_grain_2x"] = "farming:wheat_8"
    replacements["mcl_villages:crop_grain_3"] = "farming:wheat_8"
    replacements["mcl_villages:crop_root_1"] = "farming:potato_4"
    replacements["mcl_villages:crop_root_2"] = "farming:potato_4"
    replacements["mcl_villages:crop_root_3"] = "farming:potato_4"

    -- Fences
    replacements["mcl_fences:oak_fence"] = palette.fence
    replacements["mcl_fences:oak_fence_gate"] = "doors:gate_wood_closed"

    -- Flowers & Pots
    replacements["mcl_flowerpots:flower_pot_oxeye_daisy"] = "flowerpot:empty"
    replacements["mcl_flowerpots:flower_pot_tulip_red"] = "flowerpot:empty"
    replacements["mcl_flowers:waterlily"] = "flowers:waterlily"

    -- Lanterns / Torches
    replacements["mcl_lanterns:chain"] = "basic_materials:chain_steel"
    replacements["mcl_lanterns:chainx"] = "basic_materials:chain_steel"
    replacements["mcl_lanterns:lantern_ceiling"] = "xdecor:lantern"
    replacements["mcl_lanterns:lantern_ceilingx"] = "xdecor:lantern"
    replacements["mcl_lanterns:lantern_floor"] = "xdecor:lantern"
    replacements["mcl_lanterns:lantern_floorx"] = "xdecor:lantern"
    replacements["mcl_ocean:sea_lantern"] = "default:meselamp"
    replacements["mcl_ocean:sea_lanternx"] = "default:meselamp"
    replacements["mcl_torches:torch"] = "default:torch"
    replacements["mcl_torches:torch_wall"] = "default:torch_wall"
    replacements["mcl_torches:torchx"] = "default:torch"

    -- Panes
    replacements["mcl_panes:bar"] = "xpanes:bar"
    replacements["mcl_panes:bar_flat"] = "xpanes:bar"
    replacements["mcl_panes:pane_brown_flat"] = "xpanes:pane"
    replacements["mcl_panes:pane_magenta_flat"] = "xpanes:pane"
    replacements["mcl_panes:pane_natural_flat"] = "xpanes:pane"
    replacements["mcl_panes:pane_orange_flat"] = "xpanes:pane"

    -- Pressure Plates
    replacements["mcl_pressureplates:pressure_plate_oak_off"] = "xdecor:pressure_wood_off"
    replacements["mesecons_pressureplates:pressure_plate_oak_off"] = "xdecor:pressure_wood_off"
    replacements["mesecons_pressureplates:pressure_plate_oak_on"] = "xdecor:pressure_wood_on"

    -- Stairs & Slabs
    local derived_stair = "stairs:stair_" .. palette.wood:match(":(.*)")
    local derived_slab = "stairs:slab_" .. palette.wood:match(":(.*)")
    
    replacements["mcl_stairs:slab_cobble"] = "stairs:slab_cobble"
    replacements["mcl_stairs:slab_cobble_top"] = "stairs:slab_cobble"
    replacements["mcl_stairs:slab_oak"] = derived_slab
    replacements["mcl_stairs:slab_oak_top"] = derived_slab
    replacements["mcl_stairs:slab_oak_topx"] = derived_slab
    replacements["mcl_stairs:slab_stone"] = "stairs:slab_stone"
    replacements["mcl_stairs:slab_stone_double"] = "default:stone"
    replacements["mcl_stairs:slab_stone_top"] = "stairs:slab_stone"
    
    replacements["mcl_stairs:stair_cobble"] = "stairs:stair_cobble"
    replacements["mcl_stairs:stair_cobble_outer"] = "stairs:stair_outer_cobble"
    replacements["mcl_stairs:stair_cobble_outerx"] = "stairs:stair_outer_cobble"
    replacements["mcl_stairs:stair_diorite_smooth"] = "stairs:stair_stone"
    replacements["mcl_stairs:stair_oak"] = derived_stair
    replacements["mcl_stairs:stair_oak_bark"] = derived_stair
    replacements["mcl_stairs:stair_oak_bark_outer"] = derived_stair
    replacements["mcl_stairs:stair_oak_inner"] = derived_stair
    replacements["mcl_stairs:stair_oak_outer"] = derived_stair
    replacements["mcl_stairs:stair_stonebrick"] = "stairs:stair_stonebrick"
    replacements["mcl_stairs:stair_stonebrick_outer"] = "stairs:stair_outer_stonebrick"
    replacements["mcl_stairs:stair_andesite_smooth"] = "stairs:stair_stone"
    replacements["mcl_stairs:stair_andesite_smooth_outer"] = "stairs:stair_outer_stone"

    -- Farming & Enchanting
    replacements["mcl_farming:wheat"] = "farming:wheat_8"
    replacements["mcl_farming:carrot"] = "farming:carrot_8"
    replacements["mcl_farming:potato"] = "farming:potato_4"
    replacements["mcl_lectern:lectern"] = "x_enchanting:table"
    replacements["wine:wine_barrel"] = "xdecor:barrel"

    -- Flowerpots
    replacements["mcl_flowerpots:flower_pot_blue_orchid"] = "flowerpot:flowers_viola"
    replacements["mcl_flowerpots:flower_pot_tulip_white"] = "flowerpot:flowers_tulip"
    replacements["mcl_flowerpots:flower_pot_tulip_pink"] = "flowerpot:flowers_tulip"
    replacements["mcl_flowerpots:flower_pot_tulip_red"] = "flowerpot:flowers_tulip"
    replacements["mcl_flowerpots:flower_pot_tulip_orange"] = "flowerpot:flowers_tulip"
    replacements["mcl_flowerpots:flower_pot_allium"] = "flowerpot:flowers_viola"

    -- Trees / Paths
    replacements["mcl_trees:tree_oak"] = palette.log
    replacements["mcl_trees:wood_oak"] = palette.wood
    replacements["mcl_villages:no_paths"] = "air"
    replacements["mcl_villages:path_endpoint"] = "air"
    replacements["mcl_villages:path_endpointx"] = "air"

    -- Walls
    replacements["mcl_walls:brick_0"] = "default:brick"
    replacements["mcl_walls:brick_0x"] = "default:brick"
    replacements["mcl_walls:brick_6"] = "default:brick"
    replacements["mcl_walls:cobble_0"] = "walls:cobble"
    replacements["mcl_walls:cobble_0x"] = "walls:cobble"
    replacements["mcl_walls:cobble_1"] = "walls:cobble"
    replacements["mcl_walls:cobble_11"] = "walls:cobble"
    replacements["mcl_walls:cobble_12"] = "walls:cobble"
    replacements["mcl_walls:cobble_13"] = "walls:cobble"
    replacements["mcl_walls:cobble_14"] = "walls:cobble"
    replacements["mcl_walls:cobble_3"] = "walls:cobble"
    replacements["mcl_walls:cobble_3x"] = "walls:cobble"
    replacements["mcl_walls:cobble_4"] = "walls:cobble"
    replacements["mcl_walls:cobble_6"] = "walls:cobble"
    replacements["mcl_walls:cobble_7"] = "walls:cobble"
    replacements["mcl_walls:cobble_7x"] = "walls:cobble"
    replacements["mcl_walls:cobble_9"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_0"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_12"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_15"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_3"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_6"] = "walls:cobble"
    replacements["mcl_walls:stonebrick_9"] = "walls:cobble"

    -- Wool / Carpets
    replacements["mcl_wool:brown_carpet"] = "carpet:wool_brown"
    replacements["mcl_wool:purple_carpet"] = "carpet:wool_violet"
    replacements["mcl_wool:silver_carpet"] = "carpet:wool_grey"
    replacements["mcl_wool:white_carpet"] = "carpet:wool_white"
    
    return replacements
end

local function is_valid_terrain(cx, cz, cy, minp, maxp, heightmap)
    if cy < 2 then return false, 0, 0, "center too low (" .. cy .. ")" end 
    local chunk_size_x = maxp.x - minp.x + 1
    
    local function get_h(x, z)
        if x < minp.x or x > maxp.x or z < minp.z or z > maxp.z then return nil end
        return heightmap[(z - minp.z) * chunk_size_x + (x - minp.x) + 1]
    end
    
    -- Dense sampling over a +/- 35 node area (70 node total span)
    local min_found_h = 1000
    local max_found_h = -1000
    local samples = 0
    
    for oz = -35, 35, 17 do
        for ox = -35, 35, 17 do
            local h = get_h(cx + ox, cz + oz)
            if h then
                -- Strict water avoidance in the core (25 nodes)
                local dist = math.sqrt(ox^2 + oz^2)
                if dist <= 25 and h < 3 then 
                    return false, 0, 0, "water nearby at (" .. (cx+ox) .. "," .. (cz+oz) .. ") height " .. h 
                end
                
                if h < min_found_h then min_found_h = h end
                if h > max_found_h then max_found_h = h end
                samples = samples + 1
            end
        end
    end
    
    -- We need at least 10 valid samples (lowered from 15)
    if samples < 10 then return false, 0, 0, "too few samples (" .. samples .. ")" end
    
    -- REJECT: If total elevation change is greater than 18 blocks (raised from 14)
    if max_found_h - min_found_h > 18 then 
        return false, 0, 0, "too hilly (diff " .. (max_found_h - min_found_h) .. ")"
    end
    
    local h_e = get_h(cx + 20, cz) or cy
    local h_w = get_h(cx - 20, cz) or cy
    local h_n = get_h(cx, cz + 20) or cy
    local h_s = get_h(cx, cz - 20) or cy
    
    local slope_x = (h_e - h_w) / 40
    local slope_z = (h_n - h_s) / 40

    local biome_data = minetest.get_biome_data({x=cx, y=cy, z=cz})
    if biome_data then
        local biome_name = minetest.get_biome_name(biome_data.biome)
        if biome_name then
            if biome_name:find("jungle") or biome_name:find("ocean") or biome_name:find("beach") then
                return false, 0, 0, "blacklisted biome: " .. biome_name
            end
            local blacklist = {
                "sandstone_desert", "cold_desert", "icesheet", "tundra", 
                "tundra_highland", "glacier", "fiery", "grayness", "frost", "mesa"
            }
            for _, name in ipairs(blacklist) do
                if biome_name:find(name) then return false, 0, 0, "blacklisted biome: " .. biome_name end
            end
        end
    end
    
    -- Return valid plus slopes
    return true, slope_x, slope_z
end

-- Generates the deterministic Master Plan
local function generate_master_plan(cx, cz, ch, sx, sz, pr, biome_name)
    local plan = {
        roads = {},      -- list of {x, z, r}
        buildings = {},  -- list of {x, z, rot, schem_id, schem_def}
        center = {x=cx, y=ch, z=cz},
        slope = {x=sx, z=sz},
        replacements = get_dependency_replacements(biome_name),
        radius = 0
    }
    
    -- Central Plaza
    table.insert(plan.buildings, {x=cx, z=cz, rot="0", schem_id="well", schem_def=structures["well"]})
    
    -- Branching Roads
    local function build_branch(startX, startZ, dirX, dirZ, length, depth)
        if depth > 3 or length < 10 then return end
        for i=1, length do
            local rx, rz = startX + (dirX * i), startZ + (dirZ * i)
            table.insert(plan.roads, {x=rx, z=rz, r=2})
            
            local dFromCenter = math.sqrt((rx-cx)^2 + (rz-cz)^2)
            if dFromCenter > plan.radius then plan.radius = dFromCenter end
            
            -- Chance to place house (every 6 blocks, but with a 12-block safety buffer around the well)
            if i % 6 == 0 and dFromCenter > 12 and pr:next(1, 100) > 20 then
                local side = pr:next(1,2) == 1 and 1 or -1
                
                -- Pick random schematic
                local keys = {}
                for k, v in pairs(structures) do 
                    if k ~= "well" and v and v.size and v.size.x and v.size.z then 
                        table.insert(keys, k) 
                    end 
                end
                
                if #keys > 0 then
                    local pick = keys[pr:next(1, #keys)]
                    local schem = structures[pick]
                    
                -- Correct mapping (Schematic front faces -Z at rot 0)
                local base_rot = 0
                if dirX == 1 then base_rot = (side == 1 and 0 or 180)
                elseif dirX == -1 then base_rot = (side == 1 and 180 or 0)
                elseif dirZ == 1 then base_rot = (side == 1 and 90 or 270)
                elseif dirZ == -1 then base_rot = (side == 1 and 270 or 90)
                end
                
                -- Apply building-specific rotation offset
                local final_rot = (base_rot + (schem.rot_offset or 0)) % 360
                local rot = tostring(final_rot)
                
                -- Calculate AABB for collision
                local w, l = schem.size.x, schem.size.z
                if rot == "90" or rot == "270" then
                    w, l = schem.size.z, schem.size.x
                end
                
                -- Adjust px, pz dynamically based on building depth so it's flush with the road
                -- Road radius is 2, so 2.5 + depth/2 puts it 0.5 blocks from the edge.
                local depth = (dirX ~= 0 and l or w)
                local offset = 2.5 + math.ceil(depth / 2)
                local px = rx + (dirZ * side * offset)
                local pz = rz + (dirX * side * offset)
                
                local minX = px - math.floor(w/2)
                local maxX = px + math.ceil(w/2)
                local minZ = pz - math.floor(l/2)
                local maxZ = pz + math.ceil(l/2)
                
                local collision = false
                for _, b in ipairs(plan.buildings) do
                    local bw, bl = b.schem_def.size.x, b.schem_def.size.z
                    if b.rot == "90" or b.rot == "270" then
                        bw, bl = b.schem_def.size.z, b.schem_def.size.x
                    end
                    local bminX = b.x - math.floor(bw/2)
                    local bmaxX = b.x + math.ceil(bw/2)
                    local bminZ = b.z - math.floor(bl/2)
                    local bmaxZ = b.z + math.ceil(bl/2)
                    
                    if minX <= bmaxX and maxX >= bminX and minZ <= bmaxZ and maxZ >= bminZ then
                        collision = true
                        break
                    end
                end
                
                if not collision then
                    for _, r in ipairs(plan.roads) do
                        local testX = math.max(minX, math.min(r.x, maxX))
                        local testZ = math.max(minZ, math.min(r.z, maxZ))
                        local distSq = (r.x - testX)^2 + (r.z - testZ)^2
                        if distSq <= r.r^2 then
                            collision = true
                            break
                        end
                    end
                end
                
                if not collision then
                    table.insert(plan.buildings, {x=px, z=pz, rot=rot, schem_id=pick, schem_def=schem})
                end
            end
            end
            
            -- Chance to branch
            if i == math.floor(length/2) and depth < 3 then
                if pr:next(1, 2) == 1 then
                    build_branch(rx, rz, dirZ, dirX, math.floor(length*0.7), depth + 1)
                else
                    build_branch(rx, rz, -dirZ, -dirX, math.floor(length*0.7), depth + 1)
                end
            end
        end
    end
    
    build_branch(cx, cz, 1, 0, pr:next(20, 50), 1)
    build_branch(cx, cz, -1, 0, pr:next(20, 50), 1)
    build_branch(cx, cz, 0, 1, pr:next(20, 50), 1)
    build_branch(cx, cz, 0, -1, pr:next(20, 50), 1)
    
    plan.radius = plan.radius + 20
    return plan
end

-- Interpolates 2D Perlin Smooth Blending
local function get_blended_height(px, pz, village, raw_h)
    local cx, cz, ch = village.center.x, village.center.z, village.center.y
    local sx, sz = village.slope.x, village.slope.z
    local d = math.sqrt((px - cx)^2 + (pz - cz)^2)
    
    if d > village.radius then return raw_h end
    
    -- Calculate height on the village's tilted plane
    local plane_h = ch + (px - cx) * sx + (pz - cz) * sz
    
    -- Smoothstep interpolation between raw terrain and the village plane
    local t = d / village.radius
    t = t * t * (3 - 2 * t) -- cubic ease in-out
    
    return math.floor(plane_h + (raw_h - plane_h) * t)
end

minetest.register_on_generated(function(minp, maxp, seed)
    if not ENABLE_GENERATION or VILLAGE_CHANCE <= 0 then return end
    
    local chunk_mid_x = (minp.x + maxp.x) / 2
    local chunk_mid_z = (minp.z + maxp.z) / 2
    local cx = math.floor(chunk_mid_x / GRID_SIZE) * GRID_SIZE + (GRID_SIZE / 2)
    local cz = math.floor(chunk_mid_z / GRID_SIZE) * GRID_SIZE + (GRID_SIZE / 2)
    local v_id = cx .. "_" .. cz
    
    local heightmap = minetest.get_mapgen_object("heightmap")
    if not heightmap then 
        -- minetest.log("action", "[evergrowth_villages] No heightmap for chunk " .. minetest.pos_to_string(minp))
        return 
    end
    local chunk_size_x = maxp.x - minp.x + 1
    
    -- INIT VILLAGE
    if evergrowth_villages.active_villages[v_id] == nil then
        -- Only initialize if this is the center chunk
        if minp.x <= cx and maxp.x >= cx and minp.z <= cz and maxp.z >= cz then
            local pr = PseudoRandom(cx + cz + seed % 10000)
            if pr:next(1, VILLAGE_CHANCE) == 1 then
                local ch = heightmap[((cz - minp.z) * chunk_size_x) + (cx - minp.x) + 1]
                local valid, sx, sz, reason = is_valid_terrain(cx, cz, ch, minp, maxp, heightmap)
                if ch and valid then
                    local biome_data = minetest.get_biome_data({x=cx, y=ch, z=cz})
                    local biome_name = minetest.get_biome_name(biome_data.biome)
                    evergrowth_villages.active_villages[v_id] = generate_master_plan(cx, cz, ch, sx, sz, pr, biome_name)
                    minetest.log("action", "[evergrowth_villages] Master Plan Locked: " .. v_id)
                else
                    minetest.log("action", "[evergrowth_villages] Invalid terrain at ("..cx..","..cz.."): " .. (reason or "unknown"))
                    evergrowth_villages.active_villages[v_id] = false
                end
            else
                -- minetest.log("action", "[evergrowth_villages] Chance skip at ("..cx..","..cz..")")
                evergrowth_villages.active_villages[v_id] = false
            end
        else
            -- We are an adjacent chunk loading *before* the center chunk.
            -- This is rare, but we must ignore to prevent partial pre-gen without a plan.
            return
        end
    end
    
    local village = evergrowth_villages.active_villages[v_id]
    if not village then return end
    
    -- If this chunk is outside the blended radius of the village, skip voxel manip
    local dist_to_center = math.sqrt((chunk_mid_x - cx)^2 + (chunk_mid_z - cz)^2)
    if dist_to_center > village.radius + 80 then return end
    
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    local write_required = false
    
    local c_air = minetest.get_content_id("air")
    local c_dirt = minetest.get_content_id("default:dirt")
    local c_grass = minetest.get_content_id("default:dirt_with_grass")
    local c_gravel = minetest.get_content_id("default:gravel")
    local c_ignore = minetest.get_content_id("ignore")
    
    local biome_data = minetest.get_biome_data({x=cx, y=village.center.y, z=cz})
    if biome_data then
        local biome_name = minetest.get_biome_name(biome_data.biome)
        local b_def = minetest.registered_biomes[biome_name]
        if b_def then
            if b_def.node_top then
                c_grass = minetest.get_content_id(b_def.node_top)
            end
            if b_def.node_filler then
                c_dirt = minetest.get_content_id(b_def.node_filler)
            end
        end
    end
    
    -- Pre-calculate building terraces (AABB footprints flattened to their foundation height)
    local terraces = {}
    for _, b in ipairs(village.buildings) do
        local bw, bl = b.schem_def.size.x, b.schem_def.size.z
        if b.rot == "90" or b.rot == "270" then
            bw, bl = b.schem_def.size.z, b.schem_def.size.x
        end
        local minX = b.x - math.floor(bw/2) - 1
        local maxX = b.x + math.ceil(bw/2) + 1
        local minZ = b.z - math.floor(bl/2) - 1
        local maxZ = b.z + math.ceil(bl/2) + 1
        
        -- If building footprint overlaps this chunk at all
        if maxX >= minp.x and minX <= maxp.x and maxZ >= minp.z and minZ <= maxp.z then
            if not b.locked_y then
                -- Calculate height purely based on the village's deterministic plane.
                -- This ensures ALL chunks agree on the foundation height of every building.
                local cx, cz, ch = village.center.x, village.center.z, village.center.y
                local sx, sz = village.slope.x, village.slope.z
                b.locked_y = math.floor(ch + (b.x - cx) * sx + (b.z - cz) * sz)
            end
            
            table.insert(terraces, {minX=minX, maxX=maxX, minZ=minZ, maxZ=maxZ, y=b.locked_y})
        end
    end
    
    -- 1. TERRAIN BLENDING & TREE CLEARING
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local raw_h = heightmap[(z - minp.z) * chunk_size_x + (x - minp.x) + 1]
            if raw_h then
                local blend_h = get_blended_height(x, z, village, raw_h)
                
                -- Support pillars for terraces
                for _, t in ipairs(terraces) do
                    if x >= t.minX and x <= t.maxX and z >= t.minZ and z <= t.maxZ then
                        blend_h = math.max(blend_h, t.y)
                        break
                    end
                end
                
                -- Surgical check: Only clear air if we are near a structure or road
                local d_center_sq = (x-village.center.x)^2 + (z-village.center.z)^2
                local should_clear = (d_center_sq < 256) -- 16 nodes around center well
                
                if not should_clear then
                    for _, r in ipairs(village.roads) do
                        if (x-r.x)^2 + (z-r.z)^2 < 64 then -- 8 nodes around roads
                            should_clear = true
                            break
                        end
                    end
                end
                
                if not should_clear then
                    for _, b in ipairs(village.buildings) do
                        if (x-b.x)^2 + (z-b.z)^2 < 144 then -- 12 nodes around buildings
                            should_clear = true
                            break
                        end
                    end
                end

                if should_clear then
                    -- Clear air up to height 30 above ground to remove trees/leaves
                    local clear_top = math.min(math.max(raw_h, blend_h) + 30, maxp.y)
                    local clear_bottom = math.max(blend_h + 1, minp.y)
                    
                    if clear_bottom <= clear_top then
                        for y = clear_bottom, clear_top do
                            local vi = area:index(x, y, z)
                            if data[vi] ~= c_air and data[vi] ~= c_ignore then
                                data[vi] = c_air
                                write_required = true
                            end
                        end
                    end
                end

                -- Fill/Carve Terrain
                if blend_h < raw_h then
                    if blend_h >= minp.y and blend_h <= maxp.y then
                        data[area:index(x, blend_h, z)] = c_grass
                        write_required = true
                    end
                elseif blend_h > raw_h then
                    local fill_bottom = math.max(raw_h + 1, minp.y)
                    local fill_top = math.min(blend_h, maxp.y)
                    if fill_bottom <= fill_top then
                        for y = fill_bottom, fill_top do
                            local vi = area:index(x, y, z)
                            data[vi] = c_dirt
                            write_required = true
                        end
                        if blend_h >= minp.y and blend_h <= maxp.y then
                            data[area:index(x, blend_h, z)] = c_grass
                            write_required = true
                        end
                    end
                end
            end
        end
    end
    
    -- 2. DRAW ROADS
    for _, road in ipairs(village.roads) do
        -- Check if road overlaps chunk
        if road.x + road.r >= minp.x and road.x - road.r <= maxp.x and 
           road.z + road.r >= minp.z and road.z - road.r <= maxp.z then
            
            for rx = math.max(road.x - road.r, minp.x), math.min(road.x + road.r, maxp.x) do
                for rz = math.max(road.z - road.r, minp.z), math.min(road.z + road.r, maxp.z) do
                    -- Circular road brush
                    if (rx - road.x)^2 + (rz - road.z)^2 <= road.r^2 then
                        local raw_h = heightmap[(rz - minp.z) * chunk_size_x + (rx - minp.x) + 1]
                        if raw_h then
                            local h = get_blended_height(rx, rz, village, raw_h)
                            
                            for _, t in ipairs(terraces) do
                                if rx >= t.minX and rx <= t.maxX and rz >= t.minZ and rz <= t.maxZ then
                                    h = math.max(h, t.y)
                                    break
                                end
                            end
                            
                            if h >= minp.y and h <= maxp.y then
                                data[area:index(rx, h, rz)] = c_gravel
                                
                                local clear_bottom = math.max(h + 1, minp.y)
                                local clear_top = math.min(h + 4, maxp.y)
                                if clear_bottom <= clear_top then
                                    for hy = clear_bottom, clear_top do
                                        local vi_air = area:index(rx, hy, rz)
                                        if data[vi_air] ~= c_air and data[vi_air] ~= c_ignore then
                                            data[vi_air] = c_air
                                        end
                                    end
                                end
                                write_required = true
                            end
                        end
                    end
                end
            end
        end
    end
    
    if write_required then
        vm:set_data(data)
        vm:calc_lighting()
        vm:write_to_map()
        vm:update_map()
    end
    
    -- 3. PLACE LBM ANCHORS AFTER VOXELMANIP WRITE
    for _, b in ipairs(village.buildings) do
        -- If the building ORIGIN is strictly inside this chunk (including Y bounds), place the anchor.
        if b.x >= minp.x and b.x <= maxp.x and b.z >= minp.z and b.z <= maxp.z then
            local anchor_y = b.locked_y or get_blended_height(b.x, b.z, village, village.center.y)
            
            if anchor_y >= minp.y and anchor_y <= maxp.y then
                local anchor_pos = {x=b.x, y=anchor_y, z=b.z}
                minetest.set_node(anchor_pos, {name="evergrowth_villages:build_anchor"})
                
                local meta = minetest.get_meta(anchor_pos)
                meta:set_string("schem_file", b.schem_def.file)
                meta:set_string("rotation", b.rot)
                local replacements = table.copy(village.replacements)
                if b.schem_def.extra_replacements then
                    for k, v in pairs(b.schem_def.extra_replacements) do
                        replacements[k] = v
                    end
                end
                meta:set_string("replacements", minetest.serialize(replacements))
                meta:set_int("y_offset", b.schem_def.y_offset or 0)
                meta:set_float("spawn_y_offset", b.schem_def.spawn_y_offset or 0)
                meta:set_float("spawn_pos_offset_x", b.schem_def.spawn_pos_offset.x or 0)
                meta:set_float("spawn_pos_offset_z", b.schem_def.spawn_pos_offset.z or 0)
                meta:set_int("schem_size_x", b.schem_def.size.x or 0)
                meta:set_int("schem_size_z", b.schem_def.size.z or 0)
                
                if b.schem_def.profession then
                    meta:set_string("spawn_profession", b.schem_def.profession)
                end
            end
        end
    end
end)

