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
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
        end
    end,
    
    can_dig = function(pos, player)
        if not player or not player:is_player() then return false end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()
        
        -- Placer / owner bypass
        local owner = meta:get_string("owner")
        if owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then
            return true
        end
        
        if sid and sid ~= "" then
            return eg_settlers.db.is_authorized(sid, name)
        end
        return false
    end,
    
    on_blast = function(pos, intensity)
        return nil
    end,
    
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if not player or not player:is_player() then return 0 end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()
        local authorized = false
        if sid and sid ~= "" then
            authorized = eg_settlers.db.is_authorized(sid, name)
        else
            local owner = meta:get_string("owner")
            authorized = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
        end
        return authorized and stack:get_count() or 0
    end,
    
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if not player or not player:is_player() then return 0 end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()
        local authorized = false
        if sid and sid ~= "" then
            authorized = eg_settlers.db.is_authorized(sid, name)
        else
            local owner = meta:get_string("owner")
            authorized = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
        end
        return authorized and stack:get_count() or 0
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if not player or not player:is_player() then return 0 end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()
        local authorized = false
        if sid and sid ~= "" then
            authorized = eg_settlers.db.is_authorized(sid, name)
        else
            local owner = meta:get_string("owner")
            authorized = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
        end
        return authorized and count or 0
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            local meta = minetest.get_meta(pos)
            local sid = meta:get_string("settlement_id")
            local name = clicker:get_player_name()
            local authorized = false
            if sid and sid ~= "" then
                authorized = eg_settlers.db.is_authorized(sid, name)
            else
                local owner = meta:get_string("owner")
                authorized = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
            end
            if not authorized then
                minetest.chat_send_player(name, S("Only authorized players can access this dropbox."))
                return itemstack
            end
            local formname = "eg_settlers:town_depot_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
            minetest.show_formspec(name, formname, get_depot_formspec(pos))
        end
        return itemstack
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- Depot doesn't have interactive fields yet, just inventory movement
end)
