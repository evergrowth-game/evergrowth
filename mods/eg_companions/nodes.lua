--[[
    Evergrowth Companions - Nodes
    =============================
    Registers the wallmounted Companion Plaque (eg_companions:companion_plaque)
    which serves as the companion's daytime home anchor.
]]--

local S = minetest.get_translator("eg_companions")

minetest.register_node("eg_companions:companion_plaque", {
    description = S("Companion Plaque"),
    _doc_items_longdesc = S("Wallmounted plaque to anchor a domestic companion to your home."),
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
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
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type == "node" and placer and placer:is_player() then
            local pos = pointed_thing.above
            if minetest.is_protected(pos, placer:get_player_name()) then
                minetest.record_protection_violation(pos, placer:get_player_name())
                return itemstack
            end
        end
        return minetest.item_place(itemstack, placer, pointed_thing)
    end,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("occupied", 0)
        meta:set_string("resident_name", "")
        meta:set_string("bed_pos", "")
        meta:set_string("infotext", S("Companion Plaque (Vacant)"))
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
        end
    end,

    on_destruct = function(pos)
        for _, obj in pairs(minetest.luaentities) do
            if obj and obj.is_companion and obj.plaque_pos then
                if vector.equals(obj.plaque_pos, pos) or vector.distance(obj.plaque_pos, pos) <= 1.5 then
                    obj.plaque_pos = nil
                end
            end
        end
    end,

    can_dig = function(pos, player)
        if not player then return false end
        local meta = minetest.get_meta(pos)
        local occupied = meta:get_int("occupied")
        local owner = meta:get_string("owner")
        local name = player:get_player_name()

        local is_owner = (owner == "" or owner == name or minetest.is_singleplayer() or minetest.check_player_privs(name, {protection_bypass=true}))

        if not is_owner then
            minetest.chat_send_player(name, S("[eg_companions] Only the owner (@1) can remove this Companion Plaque.", owner))
            return false
        end

        if occupied == 1 then
            if player:get_player_control().sneak then
                return true
            else
                minetest.chat_send_player(name, S("[eg_companions] Relocate the companion first, or hold Sneak while mining."))
                return false
            end
        end
        return true
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then return end
        local meta = minetest.get_meta(pos)
        local occupied = meta:get_int("occupied")
        local name = clicker:get_player_name()

        if occupied == 1 then
            local rname = meta:get_string("resident_name")
            local bpos_str = meta:get_string("bed_pos")
            minetest.chat_send_player(name, S("[eg_companions] Plaque assigned to @1. Bed location: @2", rname, bpos_str))
        else
            minetest.chat_send_player(name, S("[eg_companions] Companion Plaque is vacant. Place a Companion Contract on this plaque to assign a companion."))
        end
    end,
})

-- Craft recipe for Companion Plaque
minetest.register_craft({
    output = "eg_companions:companion_plaque",
    recipe = {
        {"default:steel_ingot", "default:gold_lump"},
    }
})
