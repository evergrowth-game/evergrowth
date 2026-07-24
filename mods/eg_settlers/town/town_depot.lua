local S = minetest.get_translator("eg_settlers")

local profession_yields = {
    ["farmer"] = {item = "farming:wheat", count = 2},
    ["rancher"] = {item = "mobs:leather", count = 1},
    ["lumberjack"] = {item = "default:wood", count = 1},
    ["miner"] = {item = "default:coal_lump", count = 1},
    ["smith"] = {item = "default:iron_lump", count = 1},
    ["guard"] = {item = "default:copper_lump", count = 1},
}

local function get_depot_formspec(pos)
    local meta = minetest.get_meta(pos)
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    local sid = meta:get_string("settlement_id")
    local status = sid ~= "" and minetest.colorize("#00FF00", S("Connected")) or minetest.colorize("#FF0000", S("Unlinked"))
    
    local formspec = "size[10,8]" ..
        "box[0,0;10,8;#3E2723]" ..
        "label[0.5,0.5;" .. S("Town Status:") .. " " .. status .. "]" ..
        "label[0.5,1.5;" .. minetest.colorize("#FFFFFF", S("── Passive Income Dropbox ──")) .. "]" ..
        "list[nodemeta:" .. pos_str .. ";depot;1,2.5;8,2;]" ..
        "list[current_player;main;1,5.5;8,4;]" ..
        "listring[nodemeta:" .. pos_str .. ";depot]" ..
        "listring[current_player;main]"
        
    return formspec
end

minetest.register_node("eg_settlers:town_depot", {
    description = S("Town Dropbox"),
    drawtype = "mesh",
    mesh = "eg_settlers_town_depot.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "default_wood.png",
        "default_steel_block.png^[colorize:#222222:80"
    },
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.42, -0.5, -0.42, 0.42, 0.31, 0.42},
        }
    },
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.42, -0.5, -0.42, 0.42, 0.31, 0.42},
        }
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Town Dropbox: Unlinked"))
        
        local inv = meta:get_inventory()
        inv:set_size("depot", 8*2)
        
        meta:set_int("last_day_count", minetest.get_day_count())
        
        local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
        if sid then
            meta:set_string("settlement_id", sid)
            meta:set_string("infotext", S("Town Dropbox: Connected to town"))
        end
        
        minetest.get_node_timer(pos):start(10.0)
    end,
    
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local current_day = minetest.get_day_count()
        local last_day = meta:get_int("last_day_count")
        
        local sid = meta:get_string("settlement_id")
        
        if sid ~= "" and not eg_settlers.db.get_settlement(sid) then
            sid = ""
            meta:set_string("settlement_id", "")
            meta:set_string("infotext", S("Town Dropbox: Unlinked"))
        end
        
        if sid == "" then
            sid = eg_settlers.db.find_nearest_settlement(pos, 200)
            if sid then
                meta:set_string("settlement_id", sid)
                meta:set_string("infotext", S("Town Dropbox: Connected to town"))
            end
        end
        
        if current_day > last_day then
            local delta_days = current_day - last_day
            meta:set_int("last_day_count", current_day)
            
            if sid and sid ~= "" then
                local settlement = eg_settlers.db.get_settlement(sid)
                if settlement and settlement.satiated == 1 then
                    local inv = meta:get_inventory()
                    
                    for pos_str, res in pairs(settlement.residents) do
                        local yield = profession_yields[res.profession]
                        if yield then
                            local total_yield = yield.count * delta_days
                            local stack = ItemStack(yield.item .. " " .. total_yield)
                            if inv:room_for_item("depot", stack) then
                                inv:add_item("depot", stack)
                            end
                        end
                    end
                end
            end
        end
        return true
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            local formname = "eg_settlers:town_depot_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
            minetest.show_formspec(clicker:get_player_name(), formname, get_depot_formspec(pos))
        end
        return itemstack
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- Depot doesn't have interactive fields yet, just inventory movement
end)
