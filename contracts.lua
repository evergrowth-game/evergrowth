local S = minetest.get_translator("evergrowth_villages")

local function register_contract(name, profession, recipe_item, description, custom_texture)
    local item_name = "evergrowth_villages:contract_" .. name
    
    local tex_name = custom_texture
    if not tex_name then
        tex_name = recipe_item:gsub(":", "_"):gsub(" ", "_") .. ".png"
    end

    minetest.register_craftitem(item_name, {
        description = S(description),
        inventory_image = "default_paper.png^(" .. tex_name .. "^[resize:16x16)",
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return itemstack end
            
            local pos = pointed_thing.above
            local node = minetest.get_node(pos)
            
            -- Check if space is clear (air or buildable_to)
            local def = minetest.registered_nodes[node.name]
            if not def or not (node.name == "air" or def.buildable_to) then
                return
            end
            
            -- Spawn the trader
            evergrowth_villages.spawn_trader(pos, profession)
            
            -- Play sound
            minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
            
            -- Consume item if not in creative
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
register_contract("mechanic", "mechanic", "automobiles_lib:engine", "Mechanic's Contract", "automobiles_wheel_icon.png")

-- Companion Contracts
minetest.register_craftitem("evergrowth_villages:contract_companion_male", {
    description = S("Male Companion's Contract"),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pos = pointed_thing.above
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local owner_name = placer and placer:get_player_name() or ""
        evergrowth_villages.spawn_companion(pos, false, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "evergrowth_villages:contract_companion_male",
    recipe = {
        {"default:paper", "default:stick"},
    }
})

minetest.register_craftitem("evergrowth_villages:contract_companion_female", {
    description = S("Female Companion's Contract"),
    inventory_image = "default_paper.png^(default_apple.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local pos = pointed_thing.above
        local node = minetest.get_node(pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local owner_name = placer and placer:get_player_name() or ""
        evergrowth_villages.spawn_companion(pos, true, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "evergrowth_villages:contract_companion_female",
    recipe = {
        {"default:paper", "default:apple"},
    }
})

minetest.register_craftitem("evergrowth_villages:contract_companion_relocation", {
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
        
        evergrowth_villages.spawn_companion(pos, is_female, owner_name, override_data)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

-- Wardrobe Wand
minetest.register_craftitem("evergrowth_villages:wardrobe_wand", {
    description = S("Wardrobe Wand (Punch Companion to Change Clothes)"),
    inventory_image = "default_stick.png^[colorize:#FF00FF:128",
})

minetest.register_craft({
    output = "evergrowth_villages:wardrobe_wand",
    recipe = {
        {"", "", "dye:magenta"},
        {"", "default:stick", ""},
        {"default:stick", "", ""},
    }
})
