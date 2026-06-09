--[[
    Evergrowth Villages - Town Ledger Node & Satiation Ticks
    ========================================================
]]--

local S = minetest.get_translator("eg_settlers")

local function get_formspec(sid)
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local resident_count = eg_settlers.db.get_resident_count(sid)
    local status_text = s.satiated == 1 and minetest.colorize("#00FF00", S("● Well-Fed")) or minetest.colorize("#FF0000", S("● Starving"))
    
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
    
    local formspec = "size[8,8]" ..
        "label[0.5,0.5;" .. S("Town Name:") .. "]" ..
        "field[2.5,0.8;4,1;town_name;;" .. minetest.formspec_escape(s.name) .. "]" ..
        "button[6.5,0.5;1.5,1;rename;" .. S("Rename") .. "]" ..
        "label[0.5,2;" .. S("Population:") .. " " .. resident_count .. " " .. S("residents") .. "]" ..
        "label[0.5,2.5;" .. S("Status:") .. " " .. status_text .. "]" ..
        "button[6.5,2;1.5,1;disband_prompt;" .. S("Disband") .. "]" ..
        "label[0.5,3.5;" .. S("── Town Roster ──") .. "]" ..
        "textlist[0.5,4;7,3.5;roster_list;" .. roster_list .. "]"
        
    return formspec
end

local function get_disband_formspec(sid)
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local formspec = "size[6,4]" ..
        "box[0,0;6,4;#550000]" ..
        "label[0.5,0.5;" .. minetest.colorize("#FFFFFF", S("WARNING: You are about to permanently")) .. "]" ..
        "label[0.5,1.0;" .. minetest.colorize("#FFFFFF", S("disband ") .. s.name .. S(".")) .. "]" ..
        "label[0.5,1.8;" .. minetest.colorize("#FFCCCC", S("All data will be lost and villagers released.")) .. "]" ..
        "button[0.5,3;2,1;cancel_disband;" .. S("Cancel") .. "]" ..
        "button[3.5,3;2,1;confirm_disband;" .. minetest.colorize("#FF0000", S("Confirm")) .. "]"
        
    return formspec
end

minetest.register_node("eg_settlers:town_ledger", {
    description = S("Town Ledger"),
    drawtype = "mesh",
    mesh = "eg_settlers_town_ledger.obj",
    tiles = {
        "default_wood.png",
        "default_wood.png^[colorize:#EFE4B0:230" -- Book pages (parchment)
    },
    paramtype = "light",
    paramtype2 = "facedir",
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.4, -0.5, -0.4, 0.4, 0.45, 0.4},
        }
    },
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.4, -0.5, -0.4, 0.4, 0.45, 0.4},
        }
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    is_ground_content = false,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        
        local nearest_sid = eg_settlers.db.find_nearest_settlement(pos, 200)
        if nearest_sid then
            local s = eg_settlers.db.get_settlement(nearest_sid)
            if s then
                local is_exact_spot = vector.equals(pos, s.ledger_pos)
                local node_at_old_pos = minetest.get_node(s.ledger_pos)
                if s.is_orphaned or is_exact_spot or (node_at_old_pos.name ~= "eg_settlers:town_ledger" and node_at_old_pos.name ~= "ignore") then
                    -- Orphaned town! Adopt it.
                    s.is_orphaned = false
                    s.ledger_pos = {x=pos.x, y=pos.y, z=pos.z}
                    eg_settlers.db.mark_dirty()
                    meta:set_string("settlement_id", nearest_sid)
                    meta:set_string("infotext", S("Town Ledger: ") .. s.name)
                    minetest.get_node_timer(pos):start(10.0)
                    return
                else
                    -- Active town nearby! Reject placement.
                    minetest.chat_send_all("[Evergrowth] Cannot place Ledger here. An active Ledger for '" .. s.name .. "' is too close.")
                    minetest.remove_node(pos)
                    minetest.add_item(pos, "eg_settlers:town_ledger")
                    return
                end
            end
        end
        
        -- Create a new settlement
        local sid = eg_settlers.db.create_settlement(pos, "New Settlement")
        meta:set_string("settlement_id", sid)
        meta:set_string("infotext", S("Town Ledger: New Settlement"))
        minetest.get_node_timer(pos):start(10.0)
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
            local s = eg_settlers.db.get_settlement(sid)
            if s and vector.equals(s.ledger_pos, pos) then
                s.is_orphaned = true
                eg_settlers.db.mark_dirty()
            end
        end
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            minetest.show_formspec(clicker:get_player_name(), "eg_settlers:ledger_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z, get_formspec(sid))
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:town_ledger",
    recipe = {
        {"default:gold_ingot", "default:book", "default:gold_ingot"},
        {"", "default:wood", ""},
        {"", "default:wood", ""}
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
                    minetest.show_formspec(player:get_player_name(), formname, get_formspec(sid))
                elseif fields.disband_prompt then
                    minetest.show_formspec(player:get_player_name(), formname, get_disband_formspec(sid))
                elseif fields.cancel_disband then
                    minetest.show_formspec(player:get_player_name(), formname, get_formspec(sid))
                elseif fields.confirm_disband then
                    eg_settlers.db.delete_settlement(sid)
                    minetest.remove_node(pos)
                    minetest.close_formspec(player:get_player_name(), formname)
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
