--[[
    Evergrowth Villages - Spawners & Entities
    =========================================
    This module contains the primary instantiation functions for spawning traders
    and companions (`spawn_trader` and `spawn_companion`). It also registers the 
    Loading Block Modifier (LBM) invisible nodes used to automatically spawn 
    these entities during village generation.
    
    Depends On:
    - trades.lua (for `trades_list` and names)
    - companions.lua (for companion skin lists)
]]--

function evergrowth_villages.spawn_companion(pos, is_female, owner, override_data)
    pos = {x=math.floor(pos.x + 0.5), y=math.floor(pos.y + 0.5), z=math.floor(pos.z + 0.5)}
    
    local obj = minetest.add_entity(pos, "mobs_npc:npc")
    if obj then
        local ent = obj:get_luaentity()
        if ent then
            ent.is_evergrowth_companion = true
            ent.companion_is_female = is_female
            ent.companion_skin_index = override_data and override_data.skin_index or 1
            if owner then
                ent.owner = owner
            end
            
            local skins = is_female and evergrowth_villages.companion_female_skins or evergrowth_villages.companion_male_skins
            ent.base_texture = { skins[ent.companion_skin_index] or skins[1] }
            ent.textures = ent.base_texture
            
            local name_list = is_female and evergrowth_villages.female_names or evergrowth_villages.male_names
            local name = name_list[math.random(#name_list)]
            
            local ntag
            if override_data and override_data.nametag and override_data.nametag ~= "" then
                ntag = override_data.nametag
            else
                ntag = name .. " the Companion"
            end
            
            ent.nametag = ntag
            ent.game_name = ent.nametag
            ent.evergrowth_nametag_mode = true
            
            obj:set_properties({
                textures = ent.base_texture,
                nametag = ent.nametag,
                nametag_color = "#FFFFFF"
            })
            
            ent.walk_chance = 10 
            ent.order = "wander"
            
            if override_data and override_data.health and override_data.health > 0 then
                ent.health = override_data.health
                obj:set_hp(ent.health)
            end
            
            minetest.log("action", "[evergrowth_villages] SPAWNED " .. (is_female and "Female" or "Male") .. " Companion at " .. minetest.pos_to_string(pos))
        end
    end
end

-- Spawner Logic
function evergrowth_villages.spawn_trader(pos, profession, is_villager, override_data)
    pos = {x=math.floor(pos.x + 0.5), y=math.floor(pos.y + 0.5), z=math.floor(pos.z + 0.5)}
    override_data = override_data or {}
    
    local obj = minetest.add_entity(pos, "mobs_npc:trader")
    if obj then
        local ent = obj:get_luaentity()
        if ent then
            -- Set custom flag to enable our patched on_step logic
            ent.evergrowth_nametag_mode = true
            ent.is_villager = is_villager
            ent.evergrowth_profession = profession
            if is_villager then
                ent.home_pos = override_data.home_pos or {x=pos.x, y=pos.y, z=pos.z}
            end
            
            local trade_def = evergrowth_villages.trades_list[profession] or evergrowth_villages.trades_list.merchant
            ent.trades = trade_def
            
            -- Roll gender once for both name and texture
            local is_female = (math.random() < 0.5)
            
            -- Name generation (allow override)
            if override_data.nametag and override_data.nametag ~= "" then
                ent.nametag = override_data.nametag
            else
                local name_list = is_female and evergrowth_villages.female_names or evergrowth_villages.male_names
                local name = name_list[math.random(#name_list)]
                ent.nametag = name .. " the " .. (profession:gsub("^%l", string.upper))
            end
            ent.game_name = ent.nametag
            
            -- Texture selection (allow override)
            if override_data.texture and override_data.texture ~= "" then
                ent.base_texture = { override_data.texture }
            else
                local profession_textures = {
                    farmer = {
                        male = {"male_farmer_1.png", "male_farmer_2.png"},
                        female = {"female_farmer_1.png", "female_farmer_2.png"}
                    },
                    smith = {
                        male = {"male_smith.png"},
                        female = {"female_blacksmith.png"}
                    },
                    lumberjack = {
                        male = {"male_lumberjack.png"},
                        female = {"female_lumberjack.png"}
                    },
                    miner = {
                        male = {"male_miner.png"},
                        female = {"female_miner.png"}
                    },
                    merchant = {
                        male = {"male_merchant.png"},
                        female = {"female_merchant.png"}
                    },
                    brewer = {
                        male = {"male_brewer.png"},
                        female = {"female_brewer.png"}
                    },
                    librarian = {
                        male = {"male_librarian.png"},
                        female = {"female_librarian.png"}
                    },
                    mage = {
                        male = {"male_mage.png"},
                        female = {"female_mage.png"}
                    },
                    gunsmith = {
                        male = {"mobs_trader.png"},
                        female = {"female_gunsmith.png"}
                    }
                }
                
                local texture_pool = profession_textures[profession] and profession_textures[profession][is_female and "female" or "male"]
                if not texture_pool then
                    texture_pool = is_female and {"mobs_trader4.png"} or {"mobs_trader.png"}
                end
                ent.base_texture = { texture_pool[math.random(#texture_pool)] }
            end

            
            ent.textures = ent.base_texture
            obj:set_properties({
                textures = ent.textures,
                nametag = ent.nametag,
                nametag_color = "#FFFFFF" 
            })
            
            ent.walk_chance = 10 
            ent.order = is_villager and "wander" or "stand"
            if is_villager then
                ent.walk_limit = 15
                ent._greet_timer = 120 -- Allow immediate greeting
            end
            
            local hp = (override_data.health and override_data.health > 0) and override_data.health or 20
            ent.health = hp
            obj:set_hp(hp)
            
            minetest.log("action", "[evergrowth_villages] SPAWNED " .. profession .. " at " .. minetest.pos_to_string(pos))
            
            return ent.nametag
        end
    end
end


local function register_spawner(name, profession)
    minetest.register_node("evergrowth_villages:spawn_" .. name, {
        description = profession .. " Spawner",
        drawtype = "airlike", 
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        pointable = false, 
        groups = {not_in_creative_inventory = 1},
    })

    minetest.register_lbm({
        name = "evergrowth_villages:spawn_" .. name,
        nodenames = {"evergrowth_villages:spawn_" .. name},
        run_at_every_load = true, -- Reverted: Optimization caused spawners to fail on schematic placement
        action = function(pos, node)
            minetest.remove_node(pos)
            evergrowth_villages.spawn_trader(pos, profession, true)
        end,
    })
end

register_spawner("farmer", "farmer")
register_spawner("smith", "smith")
register_spawner("merchant", "merchant")
register_spawner("brewer", "brewer")
register_spawner("lumberjack", "lumberjack")
register_spawner("miner", "miner")
register_spawner("librarian", "librarian")
register_spawner("mage", "mage")
register_spawner("technologist", "technologist")
register_spawner("gunsmith", "gunsmith")
register_spawner("carpenter", "carpenter")
register_spawner("mechanic", "mechanic")

minetest.register_node("evergrowth_villages:build_anchor", {
    description = "Village Building Anchor",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    groups = {not_in_creative_inventory = 1},
})

minetest.register_abm({
    label = "Village Schematic ABM",
    nodenames = {"evergrowth_villages:build_anchor"},
    interval = 1,
    chance = 1,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        local schem_file = meta:get_string("schem_file")
        local rotation = meta:get_string("rotation")
        local replacements_str = meta:get_string("replacements")
        local spawn_profession = meta:get_string("spawn_profession")
        
        local y_offset = meta:get_int("y_offset")
        local spawn_y_offset = meta:get_float("spawn_y_offset") or 0.5
        
        minetest.remove_node(pos)
        
        if schem_file and schem_file ~= "" then
            -- Safe Deployment Check: Ensure schematic footprint is dry
            local sx_size = meta:get_int("schem_size_x") or 10
            local sz_size = meta:get_int("schem_size_z") or 10
            
            -- Footprint check (scan every 3 nodes for efficiency)
            local footprint_valid = true
            for dx = -math.floor(sx_size/2), math.ceil(sx_size/2), 3 do
                for dz = -math.floor(sz_size/2), math.ceil(sz_size/2), 3 do
                    local node = minetest.get_node({x = pos.x + dx, y = pos.y, z = pos.z + dz})
                    if node and node.name and minetest.get_item_group(node.name, "water") ~= 0 then
                        minetest.log("action", "[evergrowth_villages] Cancelled building " .. schem_file .. " at " .. minetest.pos_to_string(pos) .. " due to water in footprint.")
                        footprint_valid = false
                        break
                    end
                end
                if not footprint_valid then break end
            end
            
            if not footprint_valid then
                return
            end

            local replacements = nil
            if replacements_str and replacements_str ~= "" then
                replacements = minetest.deserialize(replacements_str)
            end
            
            -- Apply offset directly to the placement coordinates
            if y_offset then
                pos.y = pos.y + y_offset
            end
            
            minetest.place_schematic(pos, schem_file, rotation, replacements, true, "place_center_x, place_center_z")
            
            -- Revert offset for spawning the trader
            if y_offset then
                pos.y = pos.y - y_offset
            end
            
            if spawn_profession and spawn_profession ~= "" then
                local lx = meta:get_float("spawn_pos_offset_x") or 0
                local lz = meta:get_float("spawn_pos_offset_z") or 0
                local sx = meta:get_int("schem_size_x") or 7
                local sz = meta:get_int("schem_size_z") or 7
                
                -- Standard Minetest schematic rotation (Corner-relative)
                local rx, rz = lx, lz
                if rotation == "90" then rx, rz = sz - 1 - lz, lx
                elseif rotation == "180" then rx, rz = sx - 1 - lx, sz - 1 - lz
                elseif rotation == "270" then rx, rz = lz, sx - 1 - lx
                end

                local spawn_pos = {
                    x = pos.x + rx, 
                    y = pos.y + 1.0 + spawn_y_offset, 
                    z = pos.z + rz
                }
                evergrowth_villages.spawn_trader(spawn_pos, spawn_profession, true)
            end
            minetest.log("action", "[evergrowth_villages] Placed building from: " .. schem_file .. " at " .. minetest.pos_to_string(pos))
        end
    end,
})
