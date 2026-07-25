--[[
    Evergrowth Villages - Settlement System
    =======================================
    Registers the Housing Deed node, which acts as a home marker for villager
    NPCs. Players build their own houses and place a Deed inside to designate
    it as a residence. Villagers are then assigned via Contracts.

    The Deed cannot be dug while it has a resident assigned to it.
    The player must relocate the resident first (sneak+right-click the NPC).
]]--

local S = minetest.get_translator("eg_settlers")

-- Housing Deed Node
minetest.register_node("eg_settlers:housing_deed", {
    description = S("Housing Deed") .. "\n" .. S("Sneak+Right-Click with an empty hand to clear if resident is missing."),
    drawtype = "nodebox",
    tiles = {"default_sign_wall_steel.png^[multiply:#FFD700"},
    inventory_image = "default_sign_steel.png^[multiply:#FFD700",
    wield_image = "default_sign_steel.png^[multiply:#FFD700",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    use_texture_alpha = "opaque",
    node_box = {
        type = "wallmounted",
        wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
        wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
        wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
    },
    selection_box = {
        type = "wallmounted",
    },
    groups = {choppy = 2, dig_immediate = 2, attached_node = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("occupied", 0)
        meta:set_string("resident_name", "")
        meta:set_string("infotext", S("Housing Deed (Vacant) - Use a Contract here"))
    end,
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
            if not sid then
                minetest.chat_send_player(placer:get_player_name(),
                    S("[eg_settlers] No Town Ledger found nearby. If you assign a resident here, they will not be part of a settlement."))
            end
        end
    end,

    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            eg_settlers.db.unregister_resident(sid, pos)
        end
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        if meta:get_int("occupied") == 1 then
            if player and player:is_player() then
                if player:get_player_control().sneak then
                    return true
                end
                minetest.chat_send_player(player:get_player_name(),
                    S("Relocate the resident first, or hold Sneak while mining to forcefully break this deed."))
            end
            return false
        end
        return true
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then return itemstack end
        
        local meta = minetest.get_meta(pos)
        
        -- If player is holding an item, check if it's a Contract
        if not itemstack:is_empty() then
            local item_name = itemstack:get_name()
            -- Only manually trigger on_place for our specific contracts
            if string.match(item_name, "^eg_settlers:contract_") then
                local def = itemstack:get_definition()
                if def and def.on_place then
                    return def.on_place(itemstack, clicker, pointed_thing)
                end
            end
            -- For all other items (like signs), return to consume the click.
            return itemstack
        end
        
        -- If hand is empty, explicitly inform the player the resident is alive
        if meta:get_int("occupied") == 1 then
            minetest.chat_send_player(clicker:get_player_name(), S("[eg_settlers] Resident is alive. Use a Relocation Contract to move them."))
        else
            minetest.chat_send_player(clicker:get_player_name(), S("[eg_settlers] This Deed is vacant. Use a Contract on it to assign a resident."))
        end
        
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:housing_deed",
    recipe = {
        {"default:paper", "dye:black"},
    }
})
