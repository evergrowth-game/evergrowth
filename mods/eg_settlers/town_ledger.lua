--[[
    Evergrowth Villages - Town Ledger Node & Satiation Ticks
    ========================================================
]]--

local S = minetest.get_translator("eg_settlers")

local function get_formspec(sid, tab_index)
    tab_index = tab_index or 1
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local resident_count = eg_settlers.db.get_resident_count(sid)
    local status_text = s.satiated == 1 and minetest.colorize("#00FF00", S("● Well-Fed")) or minetest.colorize("#FF0000", S("● Starving"))
    
    local estimated = S("No residents")
    if resident_count > 0 then
        local days = s.reserve_points / (resident_count * 4)
        estimated = string.format("~%.1f " .. S("days remaining"), days)
    end
    
    local formspec = "size[8,9]" ..
        "tabheader[0,0;ledger_tabs;Overview,Roster;" .. tab_index .. ";true;false]" ..
        "label[0.5,0.5;" .. S("Town Name:") .. "]" ..
        "field[2.5,0.8;4,1;town_name;;" .. minetest.formspec_escape(s.name) .. "]" ..
        "button[6.5,0.5;1.5,1;rename;" .. S("Rename") .. "]" ..
        "label[0.5,2;" .. S("Population:") .. " " .. resident_count .. " " .. S("residents") .. "]" ..
        "label[0.5,2.5;" .. S("Status:") .. " " .. status_text .. "]" ..
        "label[0.5,3;" .. S("Food Reserve:") .. " " .. s.reserve_points .. " " .. S("points") .. "]" ..
        "label[0.5,3.5;" .. S("Estimated:") .. " " .. estimated .. "]"
        
    if tab_index == 1 then
        formspec = formspec ..
            "label[0.5,4.5;" .. S("── Granary (deposit food below) ──") .. "]" ..
            "list[nodemeta:" .. s.ledger_pos.x .. "," .. s.ledger_pos.y .. "," .. s.ledger_pos.z .. ";granary;2,5;4,1;]" ..
            "list[current_player;main;0,6.5;8,4;]" ..
            "listring[nodemeta:" .. s.ledger_pos.x .. "," .. s.ledger_pos.y .. "," .. s.ledger_pos.z .. ";granary]" ..
            "listring[current_player;main]"
    elseif tab_index == 2 then
        local roster_list = ""
        for pos_str, res in pairs(s.residents) do
            local prof = res.profession or "Unknown"
            local entry = string.format("%s (%s) @ %s", res.name, prof, pos_str)
            if roster_list == "" then
                roster_list = minetest.formspec_escape(entry)
            else
                roster_list = roster_list .. "," .. minetest.formspec_escape(entry)
            end
        end
        formspec = formspec ..
            "label[0.5,4.5;" .. S("── Town Roster ──") .. "]" ..
            "textlist[0.5,5;7,3.5;roster_list;" .. roster_list .. "]"
    end
    
    return formspec
end

minetest.register_node("eg_settlers:town_ledger", {
    description = S("Town Ledger"),
    tiles = {
        "default_chest_top.png^[colorize:#FFD700:80",
        "default_chest_top.png^[colorize:#FFD700:80",
        "default_chest_side.png^[colorize:#FFD700:80",
        "default_chest_side.png^[colorize:#FFD700:80",
        "default_chest_front.png^[colorize:#FFD700:80",
        "default_chest_inside.png^[colorize:#FFD700:80"
    },
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    is_ground_content = false,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local sid = eg_settlers.db.create_settlement(pos, "New Settlement")
        meta:set_string("settlement_id", sid)
        
        local inv = meta:get_inventory()
        inv:set_size("granary", 4)
        
        meta:set_string("infotext", S("Town Ledger: ") .. "New Settlement")
    end,
    
    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            local count = eg_settlers.db.get_resident_count(sid)
            if count > 0 then
                if player and player:is_player() then
                    if player:get_player_control().sneak then
                        return true
                    end
                    minetest.chat_send_player(player:get_player_name(), S("Relocate all residents before removing the Town Ledger, or hold Sneak while mining to forcefully break it."))
                end
                return false
            end
        end
        return true
    end,
    
    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            eg_settlers.db.delete_settlement(sid)
        end
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            minetest.show_formspec(clicker:get_player_name(), "eg_settlers:ledger_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z, get_formspec(sid, 1))
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
                        local formname = "eg_settlers:ledger_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
                        minetest.show_formspec(player:get_player_name(), formname, get_formspec(sid, 1))
                    end
                end
            end
        end
    end,
    
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return 0
    end,
})

minetest.register_craft({
    output = "eg_settlers:town_ledger",
    recipe = {
        {"default:gold_ingot", "default:book", "default:gold_ingot"},
        {"", "default:chest", ""},
        {"", "", ""}
    }
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if string.sub(formname, 1, 19) == "eg_settlers:ledger_" then
        local coords = string.sub(formname, 20)
        local parts = string.split(coords, "_")
        if #parts == 3 then
            local pos = {x=tonumber(parts[1]), y=tonumber(parts[2]), z=tonumber(parts[3])}
            local meta = minetest.get_meta(pos)
            local sid = meta:get_string("settlement_id")
            if sid and sid ~= "" then
                if fields.rename and fields.town_name then
                    eg_settlers.db.set_name(sid, fields.town_name)
                    meta:set_string("infotext", S("Town Ledger: ") .. fields.town_name)
                    minetest.show_formspec(player:get_player_name(), formname, get_formspec(sid, 1))
                elseif fields.ledger_tabs then
                    minetest.show_formspec(player:get_player_name(), formname, get_formspec(sid, tonumber(fields.ledger_tabs)))
                end
            end
        end
        return true
    end
end)

-- Globalstep daily consumption
local tick_timer = 0
minetest.register_globalstep(function(dtime)
    tick_timer = tick_timer + dtime
    if tick_timer >= 10.0 then
        tick_timer = 0
        local gametime = minetest.get_gametime()
        
        local ids = eg_settlers.db.get_all_settlement_ids()
        for _, sid in ipairs(ids) do
            local s = eg_settlers.db.get_settlement(sid)
            if s then
                local time_diff = gametime - s.last_tick_gametime
                if time_diff >= 1200 then
                    eg_settlers.db.process_daily_tick(sid, time_diff)
                end
            end
        end
    end
end)

-- Trade Blocking Override
local target_entities = {"mobs_npc:trader", "mobs_npc:npc"}
for _, entity_name in ipairs(target_entities) do
    local base_entity = minetest.registered_entities[entity_name]
    if base_entity then
        local old_on_rightclick = base_entity.on_rightclick
        base_entity.on_rightclick = function(self, clicker)
            if clicker and clicker:is_player() and clicker:get_player_control().sneak then
                if old_on_rightclick then
                    return old_on_rightclick(self, clicker)
                end
                return
            end
            
            -- Only block if it's a villager with a home
            if self.is_villager and self.home_pos then
                local meta = minetest.get_meta(self.home_pos)
                local sid = meta:get_string("settlement_id")
                if sid and sid ~= "" then
                    if not eg_settlers.db.is_satiated(sid) then
                        if clicker and clicker:is_player() then
                            minetest.chat_send_player(clicker:get_player_name(), "<" .. (self.game_name or "Villager") .. "> " .. S("The town is starving... I have nothing to trade."))
                        end
                        return
                    end
                end
            end
            if old_on_rightclick then
                return old_on_rightclick(self, clicker)
            end
        end
    end
end

-- LBM for Retroactive Deed Registration
minetest.register_lbm({
    label = "Retroactive Deed Registration",
    name = "eg_settlers:retro_deed_registration",
    nodenames = {"eg_settlers:housing_deed"},
    run_at_every_load = true,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        if meta:get_int("occupied") == 1 then
            local sid = meta:get_string("settlement_id")
            if sid and sid ~= "" and not eg_settlers.db.get_settlement(sid) then
                sid = ""
                meta:set_string("settlement_id", "")
            end
            
            if not sid or sid == "" then
                local found_sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                if found_sid then
                    meta:set_string("settlement_id", found_sid)
                    local resident_name = meta:get_string("resident_name")
                    local profession = meta:get_string("profession")
                    eg_settlers.db.register_resident(found_sid, pos, resident_name, profession)
                end
            end
        end
    end,
})
