local S = minetest.get_translator("eg_settlers")

local function get_granary_formspec(sid, pos)
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local resident_count = eg_settlers.db.get_resident_count(sid)
    local estimated = S("No residents")
    if resident_count > 0 then
        local days = s.reserve_points / (resident_count * 4)
        estimated = string.format("~%.1f " .. S("days remaining"), days)
    end
    
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    
    local formspec = "size[8,7]" ..
        "box[0,0;8,7;#3E2723]" ..
        "label[0.5,0.5;" .. minetest.colorize("#FFFFFF", S("── Town Granary ──")) .. "]" ..
        "label[0.5,1.2;" .. minetest.colorize("#FFFFFF", S("Food Reserve:") .. " " .. s.reserve_points .. " " .. S("points")) .. "]" ..
        "label[0.5,1.7;" .. minetest.colorize("#FFFFFF", S("Estimated:") .. " " .. estimated) .. "]" ..
        "list[nodemeta:" .. pos_str .. ";granary;3,2.5;2,2;]" ..
        "list[current_player;main;0,5;8,4;]" ..
        "listring[nodemeta:" .. pos_str .. ";granary]" ..
        "listring[current_player;main]"
        
    return formspec
end

minetest.register_node("eg_settlers:town_granary", {
    description = S("Town Granary"),
    drawtype = "mesh",
    mesh = "eg_settlers_town_granary.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "default_cobble.png",
        "default_wood.png^[colorize:#4A2B11:150",
        "default_wood.png^[colorize:#221100:180"
    },
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 1.6, 0.5},
        }
    },
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 1.6, 0.5},
        }
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Town Granary: Unlinked"))
        
        local inv = meta:get_inventory()
        inv:set_size("granary", 4)
        
        local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
        if sid then
            meta:set_string("settlement_id", sid)
            meta:set_string("infotext", S("Town Granary: Connected to town"))
        end
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        
        if sid ~= "" and not eg_settlers.db.get_settlement(sid) then
            sid = ""
            meta:set_string("settlement_id", "")
            meta:set_string("infotext", S("Town Granary: Unlinked"))
        end
        
        if sid == "" then
            sid = eg_settlers.db.find_nearest_settlement(pos, 200)
            if sid then
                meta:set_string("settlement_id", sid)
                meta:set_string("infotext", S("Town Granary: Connected to town"))
            end
        end
        
        if sid and sid ~= "" and clicker and clicker:is_player() then
            local formname = "eg_settlers:granary_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
            minetest.show_formspec(clicker:get_player_name(), formname, get_granary_formspec(sid, pos))
        end
        return itemstack
    end,
    
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "granary" then
            local food_val = eg_settlers.get_food_value(stack:get_name())
            if food_val then
                return stack:get_count()
            end
            return 0
        end
        return 0
    end,
    
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "granary" then
            local meta = minetest.get_meta(pos)
            local sid = meta:get_string("settlement_id")
            if sid and sid ~= "" then
                local food_val = eg_settlers.get_food_value(stack:get_name())
                if food_val then
                    local total_points = food_val * stack:get_count()
                    eg_settlers.db.add_food(sid, total_points)
                    
                    local inv = meta:get_inventory()
                    inv:set_stack("granary", index, ItemStack(""))
                    
                    if player and player:is_player() then
                        local formname = "eg_settlers:granary_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
                        minetest.show_formspec(player:get_player_name(), formname, get_granary_formspec(sid, pos))
                    end
                end
            end
        end
    end,
    
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return 0
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- Inventory movement is handled natively
end)
