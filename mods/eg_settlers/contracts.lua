local S = minetest.get_translator("eg_settlers")

local function register_contract(name, profession, recipe_item, description, custom_texture)
    local item_name = "eg_settlers:contract_" .. name
    
    local tex_name = custom_texture
    if not tex_name then
        tex_name = recipe_item:gsub(":", "_"):gsub(" ", "_") .. ".png"
    end

    minetest.register_craftitem(item_name, {
        description = S(description) .. "\n" .. S("Use on a Housing Deed to assign a resident"),
        inventory_image = "default_paper.png^(" .. tex_name .. "^[resize:16x16)",
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return itemstack end
            
            local under_pos = pointed_thing.under
            local under_node = minetest.get_node(under_pos)
            
            if under_node.name == "eg_settlers:housing_deed" then
                -- Deed-based: spawn as tethered villager
                local deed_meta = minetest.get_meta(under_pos)
                if deed_meta:get_int("occupied") == 1 then
                    minetest.chat_send_player(placer:get_player_name(),
                        S("This house already has a resident."))
                    return itemstack
                end
                
                local spawn_pos = pointed_thing.above
                local npc_name = eg_settlers.spawn_trader(
                    spawn_pos, profession, true, {home_pos = under_pos})
                
                deed_meta:set_int("occupied", 1)
                deed_meta:set_string("resident_name", npc_name or profession)
                deed_meta:set_string("infotext", S("Resident: ") .. (npc_name or profession))
            else
                -- Free-standing: spawn without tethering (original behavior)
                local pos = pointed_thing.above
                local node = minetest.get_node(pos)
                local def = minetest.registered_nodes[node.name]
                if not def or not (node.name == "air" or def.buildable_to) then
                    return
                end
                eg_settlers.spawn_trader(pos, profession)
            end
            
            minetest.sound_play("default_place_node_hard", {pos = pointed_thing.above, gain = 1.0}, true)
            
            if not minetest.settings:get_bool("creative_mode") then
                itemstack:take_item()
            end
            return itemstack
        end,
    })

    -- Register Recipe
    minetest.register_craft({
        output = item_name,
        recipe = {
            {"default:paper", recipe_item},
        }
    })
end

-- Register all contracts
register_contract("guard", "guard", "default:sword_steel", "Guard's Contract", "default_tool_steelsword.png")
register_contract("farmer", "farmer", "farming:wheat", "Farmer's Contract")
register_contract("smith", "smith", "default:steel_ingot", "Blacksmith's Contract")
register_contract("merchant", "merchant", "default:glass", "Merchant's Contract")
register_contract("brewer", "brewer", "farming:bread", "Brewer's Contract")
register_contract("lumberjack", "lumberjack", "default:wood", "Lumberjack's Contract", "default_tool_woodaxe.png")
register_contract("miner", "miner", "default:coal_lump", "Miner's Contract")
register_contract("librarian", "librarian", "default:book", "Librarian's Contract")
register_contract("mage", "mage", "default:mese_crystal", "Mage's Contract")
register_contract("technologist", "technologist", "techage:electric_cable", "Technologist's Contract", "basic_materials_copper_wire.png")
register_contract("gunsmith", "gunsmith", "tnt:gunpowder", "Gunsmith's Contract", "bweapons_firearms_pack_pistol.png")
register_contract("carpenter", "carpenter", "xdecor:workbench", "Carpenter's Contract", "xdecor_hammer.png")
register_contract("automobile_mechanic", "automobile_mechanic", "automobiles_lib:wheel", "Automobile Mechanic's Contract", "techage_inv_wrench.png")
register_contract("aircraft_mechanic", "aircraft_mechanic", "airutils:repair_tool", "Aircraft Mechanic's Contract")
register_contract("nautical_mechanic", "nautical_mechanic", "motorboat:hull", "Nautical Mechanic's Contract", "motorboat_inv.png")
register_contract("fisher", "fisher", "ethereal:fishing_rod", "Fisher's Contract")


-- Companion Contracts
minetest.register_craftitem("eg_settlers:contract_companion_male", {
    description = S("Male Companion's Contract"),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pos = pointed_thing.above
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local owner_name = placer and placer:get_player_name() or ""
        eg_settlers.spawn_companion(pos, false, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:contract_companion_male",
    recipe = {
        {"default:paper", "default:stick"},
    }
})

minetest.register_craftitem("eg_settlers:contract_companion_female", {
    description = S("Female Companion's Contract"),
    inventory_image = "default_paper.png^(default_apple.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pos = pointed_thing.above
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local owner_name = placer and placer:get_player_name() or ""
        eg_settlers.spawn_companion(pos, true, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:contract_companion_female",
    recipe = {
        {"default:paper", "default:apple"},
    }
})

minetest.register_craftitem("eg_settlers:contract_companion_relocation", {
    description = S("Companion Relocation Contract"),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    groups = {not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pos = pointed_thing.above
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        
        local meta = itemstack:get_meta()
        local override_data = {
            nametag = meta:get_string("companion_nametag"),
            skin_index = meta:get_int("companion_skin_index"),
            health = meta:get_int("companion_health")
        }
        if override_data.health == 0 then override_data.health = 20 end
        local is_female = meta:get_int("companion_is_female") == 1
        local owner_name = meta:get_string("companion_owner")
        if owner_name == "" and placer then
            owner_name = placer:get_player_name()
        end
        
        eg_settlers.spawn_companion(pos, is_female, owner_name, override_data)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

-- Wardrobe Wand
minetest.register_craftitem("eg_settlers:wardrobe_wand", {
    description = S("Wardrobe Wand (Punch Companion to Change Clothes)"),
    inventory_image = "default_stick.png^[colorize:#FF00FF:128",
})

minetest.register_craft({
    output = "eg_settlers:wardrobe_wand",
    recipe = {
        {"", "", "dye:magenta"},
        {"", "default:stick", ""},
        {"default:stick", "", ""},
    }
})

-- Villager Relocation Contract
-- Created when a player sneak+right-clicks a tethered villager NPC.
-- Stores the NPC's name, profession, texture, and health in item metadata.
minetest.register_craftitem("eg_settlers:contract_villager_relocation", {
    description = S("Villager Relocation Contract"),
    inventory_image = "default_paper.png^[colorize:#8B4513:80",
    groups = {not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end

        local under_pos = pointed_thing.under
        local under_node = minetest.get_node(under_pos)

        if under_node.name ~= "eg_settlers:housing_deed" then
            minetest.chat_send_player(placer:get_player_name(),
                S("Use this on a Housing Deed to place the villager."))
            return itemstack
        end

        local deed_meta = minetest.get_meta(under_pos)
        if deed_meta:get_int("occupied") == 1 then
            minetest.chat_send_player(placer:get_player_name(),
                S("This house already has a resident."))
            return itemstack
        end

        local meta = itemstack:get_meta()
        local override_data = {
            nametag = meta:get_string("resident_name"),
            texture = meta:get_string("texture"),
            health = meta:get_int("health"),
            home_pos = under_pos,
        }
        local profession = meta:get_string("profession")
        if profession == "" then profession = "merchant" end

        local spawn_pos = pointed_thing.above
        local npc_name = eg_settlers.spawn_trader(spawn_pos, profession, true, override_data)

        deed_meta:set_int("occupied", 1)
        deed_meta:set_string("resident_name", npc_name or "Villager")
        deed_meta:set_string("infotext", S("Resident: ") .. (npc_name or "Villager"))

        minetest.sound_play("default_place_node_hard", {pos = spawn_pos, gain = 1.0}, true)

        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})
