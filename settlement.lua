--[[
    Evergrowth Villages - Settlement System
    =======================================
    Registers the Housing Deed node, which acts as a home marker for villager
    NPCs. Players build their own houses and place a Deed inside to designate
    it as a residence. Villagers are then assigned via Contracts.

    The Deed cannot be dug while it has a resident assigned to it.
    The player must relocate the resident first (sneak+right-click the NPC).
]]--

local S = minetest.get_translator("evergrowth_villages")

-- Housing Deed Node
minetest.register_node("evergrowth_villages:housing_deed", {
    description = S("Housing Deed"),
    drawtype = "nodebox",
    tiles = {"default_sign_wall_steel.png^[multiply:#FFD700"},
    inventory_image = "default_paper.png^[colorize:#8B4513:80",
    wield_image = "default_paper.png^[colorize:#8B4513:80",
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

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        if meta:get_int("occupied") == 1 then
            if player and player:is_player() then
                minetest.chat_send_player(player:get_player_name(),
                    S("Relocate the resident first."))
            end
            return false
        end
        return true
    end,
})

minetest.register_craft({
    output = "evergrowth_villages:housing_deed",
    recipe = {
        {"default:paper", "dye:black"},
    }
})
