--[[
    Evergrowth Villages - Town Ledger Node & Satiation Ticks
    ========================================================
]]--

local S = minetest.get_translator("eg_settlers")

local function get_formspec(sid, player_name, tab_index)
    tab_index = tab_index or 1
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local is_owner = eg_settlers.db.is_owner(sid, player_name)
    local is_auth = eg_settlers.db.is_authorized(sid, player_name)
    local resident_count = eg_settlers.db.get_resident_count(sid)
    
    local formspec = "size[8,9]"
    
    if is_auth then
        formspec = formspec .. "tabheader[0,0;ledger_tabs;" .. S("Info") .. "," .. S("Access Control") .. "," .. S("Incidents & Justice") .. ";" .. tab_index .. ";true;false]"
    end
    
    if tab_index == 1 or not is_auth then
        local status_text = s.satiated == 1 and minetest.colorize("#00FF00", S("● Well-Fed")) or minetest.colorize("#FF0000", S("● Starving"))
        local tier_num, tier_name, tier_cap = eg_settlers.db.get_town_tier(sid)
        
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
            "label[0.5,0.5;" .. S("Town Name:") .. "]" ..
            "field[2.5,0.8;4,1;town_name;;" .. minetest.formspec_escape(s.name) .. "]"
            
        if is_auth then
            formspec = formspec .. "button[6.5,0.5;1.5,1;rename;" .. S("Rename") .. "]"
        end
        
        formspec = formspec ..
            "label[0.5,2;" .. S("Tier:") .. " " .. tier_name .. " (" .. resident_count .. "/" .. tier_cap .. " " .. S("residents") .. ")]" ..
            "label[0.5,2.5;" .. S("Status:") .. " " .. status_text .. "]"

            
        if is_owner then
            formspec = formspec .. "button[6.5,2;1.5,1;disband_prompt;" .. S("Disband") .. "]"
        end
        
        formspec = formspec ..
            "label[0.5,3.5;" .. S("── Town Roster ──") .. "]" ..
            "textlist[0.5,4;7,4.5;roster_list;" .. roster_list .. "]"
    elseif tab_index == 2 and is_auth then
        -- Access Control Tab
        formspec = formspec ..
            "label[0.5,0.5;" .. S("Owner: ") .. minetest.colorize("#FFFF00", s.owner) .. "]"
            
        if is_owner then
            formspec = formspec ..
                "field[0.8,1.5;4,1;new_owner;;" .. S("Transfer Ownership to...") .. "]" ..
                "button[4.8,1.2;2.5,1;transfer_owner;" .. S("Transfer") .. "]"
        end
        
        local assoc_list = ""
        for _, name in ipairs(s.associates) do
            if assoc_list == "" then
                assoc_list = minetest.formspec_escape(name)
            else
                assoc_list = assoc_list .. "," .. minetest.formspec_escape(name)
            end
        end
        
        formspec = formspec ..
            "label[0.5,2.5;" .. S("── Authorized Associates ──") .. "]" ..
            "textlist[0.5,3;7,3.5;assoc_list;" .. assoc_list .. "]"
            
        if is_owner then
            formspec = formspec ..
                "field[0.8,7.5;4,1;assoc_name;;" .. S("Associate Name") .. "]" ..
                "button[4.8,7.2;1.2,1;add_assoc;" .. S("Add") .. "]" ..
                "button[6.2,7.2;1.2,1;remove_assoc;" .. S("Remove") .. "]"
        end
    elseif tab_index == 3 and is_auth then
        -- Incidents & Justice Tab
        local death_entries = ""
        local deaths = s.death_log or {}
        for _, d in ipairs(deaths) do
            local pstr = d.pos and string.format("(%d,%d,%d)", d.pos.x, d.pos.y, d.pos.z) or ""
            local line = string.format("[%s] %s (%s) - Cause: %s by %s @ %s [%s]",
                os.date("%m/%d %H:%M", d.timestamp or os.time()),
                d.settler_name or "Settler",
                d.profession or "N/A",
                d.cause or "Unknown",
                d.killer or "Unknown",
                pstr,
                d.status or "Unburied"
            )
            if death_entries == "" then
                death_entries = minetest.formspec_escape(line)
            else
                death_entries = death_entries .. "," .. minetest.formspec_escape(line)
            end
        end
        
        local total_historical = (s.historical_fallen_count or 0) + #deaths
        
        formspec = formspec ..
            "label[0.5,0.4;" .. S("── Settler Incident Log (Recent Deaths) ──") .. "]" ..
            "textlist[0.5,0.8;7,2.8;death_list;" .. death_entries .. "]" ..
            "label[0.5,3.7;" .. S("Total Historical Mortality Count:") .. " " .. minetest.colorize("#FFAA00", tostring(total_historical)) .. "]" ..
            "label[0.5,4.3;" .. S("── Settlement Criminal Records & Fines ──") .. "]"
            
        local criminal_list = ""
        local records = s.criminal_records or {}
        for pname, rec in pairs(records) do
            local line = string.format("%s - Assaults: %d, Murders: %d", pname, rec.assault_count or 0, rec.murder_count or 0)
            if criminal_list == "" then
                criminal_list = minetest.formspec_escape(line)
            else
                criminal_list = criminal_list .. "," .. minetest.formspec_escape(line)
            end
        end
        
        formspec = formspec .. "textlist[0.5,4.7;7,2.2;wanted_list;" .. criminal_list .. "]"
        
        local prec = eg_settlers.db.get_criminal_record(sid, player_name)
        if prec then
            if prec.assault_count and prec.assault_count > 0 then
                formspec = formspec .. "button[0.5,7.3;3.3,1;pay_assault_fine;" .. S("Pay Assault Fine (50 Lumps)") .. "]"
            end
            if prec.murder_count and prec.murder_count > 0 then
                formspec = formspec .. "button[4.2,7.3;3.3,1;pay_murder_fine;" .. S("Pay Murder Fine (200 Lumps)") .. "]"
            end
        else
            formspec = formspec .. "label[0.5,7.5;" .. minetest.colorize("#00FF00", S("Your standing in this settlement is clean.")) .. "]"
        end
    end
        
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
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" and placer and placer:is_player() then
            local s = eg_settlers.db.get_settlement(sid)
            if s then
                s.owner = placer:get_player_name()
                eg_settlers.db.mark_dirty()
                meta:set_string("owner", s.owner)
            end

            -- Starter Kit: Award 1x Farmer Job Block + 1x Hiring Contract
            local inv = placer:get_inventory()
            local items = {"eg_settlers:job_block_farmer", "eg_settlers:hiring_contract"}
            for _, item in ipairs(items) do
                if inv:room_for_item("main", item) then
                    inv:add_item("main", item)
                else
                    minetest.item_drop(ItemStack(item), placer, pos)
                end
            end
            minetest.chat_send_player(placer:get_player_name(),
                S("[eg_settlers] Starter Kit received: 1x Farmer's Seed Silo and 1x Hiring Contract!"))
        end
    end,

    
    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            if player and player:is_player() then
                local name = player:get_player_name()
                if not eg_settlers.db.is_authorized(sid, name) then
                    minetest.chat_send_player(name, S("Only authorized players can remove the Town Ledger."))
                    return false
                end
            else
                return false
            end
            local count = eg_settlers.db.get_resident_count(sid)
            if count > 0 then
                if player and player:is_player() then
                    minetest.chat_send_player(player:get_player_name(), S("Relocate all residents before removing the Town Ledger."))
                end
                return false
            end
        end
        return true
    end,
    
    on_blast = function(pos, intensity)
        return nil
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
        if sid and sid ~= "" and clicker and clicker:is_player() then
            local name = clicker:get_player_name()
            minetest.show_formspec(name, "eg_settlers:ledger_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z, get_formspec(sid, name, 1))
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
                local name = player:get_player_name()
                local is_owner = eg_settlers.db.is_owner(sid, name)
                local is_auth = eg_settlers.db.is_authorized(sid, name)
                
                if fields.ledger_tabs then
                    local tab = tonumber(fields.ledger_tabs)
                    minetest.show_formspec(name, formname, get_formspec(sid, name, tab))
                    return true
                end
                
                if fields.rename and fields.town_name and is_auth then
                    eg_settlers.db.set_name(sid, fields.town_name)
                    meta:set_string("infotext", S("Town Ledger: ") .. fields.town_name)
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 1))
                elseif fields.disband_prompt and is_owner then
                    minetest.show_formspec(name, formname, get_disband_formspec(sid))
                elseif fields.cancel_disband and is_owner then
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 1))
                elseif fields.confirm_disband and is_owner then
                    eg_settlers.db.delete_settlement(sid)
                    minetest.remove_node(pos)
                    minetest.close_formspec(name, formname)
                elseif fields.add_assoc and fields.assoc_name and is_owner then
                    if fields.assoc_name ~= "" then
                        eg_settlers.db.add_associate(sid, fields.assoc_name)
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 2))
                elseif fields.remove_assoc and fields.assoc_name and is_owner then
                    if fields.assoc_name ~= "" then
                        eg_settlers.db.remove_associate(sid, fields.assoc_name)
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 2))
                elseif fields.transfer_owner and fields.new_owner and is_owner then
                    if fields.new_owner ~= "" and fields.new_owner ~= name then
                        if minetest.player_exists(fields.new_owner) then
                            eg_settlers.db.transfer_ownership(sid, fields.new_owner)
                            meta:set_string("owner", fields.new_owner)
                            minetest.show_formspec(name, formname, get_formspec(sid, name, 2))
                            minetest.chat_send_player(name, S("Ownership transferred to ") .. fields.new_owner)
                        else
                            minetest.chat_send_player(name, S("Player does not exist: ") .. fields.new_owner)
                        end
                    end
                elseif fields.pay_assault_fine then
                    local rec = eg_settlers.db.get_criminal_record(sid, name)
                    if rec and rec.assault_count and rec.assault_count > 0 then
                        local inv = player:get_inventory()
                        local fine_stack = ItemStack("default:gold_lump 50")
                        if inv and inv:contains_item("main", fine_stack) then
                            inv:remove_item("main", fine_stack)
                            eg_settlers.db.pay_restitution(sid, name, "assault")
                            minetest.chat_send_player(name, minetest.colorize("#00FF00", S("Assault fine paid! Active assault charges cleared.")))
                        else
                            minetest.chat_send_player(name, minetest.colorize("#FF0000", S("Insufficient gold lumps! You need 50 Gold Lumps to pay the assault fine.")))
                        end
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 3))
                elseif fields.pay_murder_fine then
                    local rec = eg_settlers.db.get_criminal_record(sid, name)
                    if rec and rec.murder_count and rec.murder_count > 0 then
                        local inv = player:get_inventory()
                        local fine_stack = ItemStack("default:gold_lump 200")
                        if inv and inv:contains_item("main", fine_stack) then
                            inv:remove_item("main", fine_stack)
                            eg_settlers.db.pay_restitution(sid, name, "murder")
                            minetest.chat_send_player(name, minetest.colorize("#00FF00", S("Murder fine paid! Capital murder charges cleared.")))
                        else
                            minetest.chat_send_player(name, minetest.colorize("#FF0000", S("Insufficient gold lumps! You need 200 Gold Lumps to pay the murder fine.")))
                        end
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 3))
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
