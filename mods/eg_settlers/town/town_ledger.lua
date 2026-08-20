--[[
    Evergrowth Villages - Town Ledger Node & Satiation Ticks
    ========================================================
]]--

local S = minetest.get_translator("eg_settlers")

local function parse_pos(str)
    if not str then return nil end
    local x, y, z = str:match("^(%-?%d+%.?%d*),(%-?%d+%.?%d*),(%-?%d+%.?%d*)$")
    if x and y and z then
        return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
    end
    return minetest.string_to_pos(str)
end

local player_selected_resident = {}

local function get_sorted_residents(s)
    local list = {}
    if not s or not s.residents then return list end
    for pos_str, res in pairs(s.residents) do
        local prof = res.profession or "Unknown"
        local shift = nil
        local display_name = res.name or "Settler"
        local rpos = parse_pos(pos_str)
        if prof == "guard" and rpos then
            local rmeta = minetest.get_meta(rpos)
            shift = rmeta:get_string("guard_shift")
            if shift == "" then shift = "day" end
            if shift == "night" and display_name:find(" the Day Guard") then
                display_name = display_name:gsub(" the Day Guard", " the Night Guard")
            elseif shift == "day" and display_name:find(" the Night Guard") then
                display_name = display_name:gsub(" the Night Guard", " the Day Guard")
            end
        end
        table.insert(list, {
            pos_str = pos_str,
            rpos = rpos,
            name = display_name,
            raw_name = res.name,
            profession = prof,
            shift = shift,
        })
    end
    table.sort(list, function(a, b)
        if a.profession == b.profession then
            return a.name < b.name
        end
        return a.profession < b.profession
    end)
    return list
end

local function get_formspec(sid, player_name, tab_index, selected_idx)
    tab_index = tab_index or 1
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local is_owner = eg_settlers.db.is_owner(sid, player_name)
    local is_auth = eg_settlers.db.is_authorized(sid, player_name)
    local resident_count = eg_settlers.db.get_resident_count(sid)
    local tier_num, tier_name, tier_cap = eg_settlers.db.get_town_tier(sid)
    local status_text = s.satiated == 1 and minetest.colorize("#44FF44", S("● Well-Fed")) or minetest.colorize("#FF4444", S("● Starving"))
    
    -- Telemetry: count ward stones and guard distribution
    local ward_stone_count = 0
    if s.ledger_pos then
        local r = 200
        local minp = vector.subtract(s.ledger_pos, r)
        local maxp = vector.add(s.ledger_pos, r)
        local wards = minetest.find_nodes_in_area(minp, maxp, {"eg_settlers:ward_stone"})
        ward_stone_count = #wards
    end

    local res_list = get_sorted_residents(s)
    local day_guard_count = 0
    local night_guard_count = 0
    for _, r in ipairs(res_list) do
        if r.profession == "guard" then
            if r.shift == "night" then
                night_guard_count = night_guard_count + 1
            else
                day_guard_count = day_guard_count + 1
            end
        end
    end
    local total_guards = day_guard_count + night_guard_count
    local guard_ratio = resident_count > 0 and math.floor((total_guards / resident_count) * 100) or 0

    local formspec = "formspec_version[4]" ..
        "size[14.5,9.5]" ..
        "box[0,0;14.5,9.5;#181A20]"
    
    if is_auth then
        formspec = formspec .. "tabheader[0.4,0.3;13.7,0.65;ledger_tabs;" .. S("Overview & Roster") .. "," .. S("Access Control") .. "," .. S("Law & Defenses") .. ";" .. tab_index .. ";true;false]"
    end

    -- Top Header Summary Card (y=1.0 to 2.3)
    formspec = formspec ..
        "box[0.4,1.0;13.7,1.35;#23262F]" ..
        "label[0.7,1.55;" .. minetest.colorize("#AAAAAA", S("Town Name:")) .. "]" ..
        "field[2.5,1.2;3.7,0.75;town_name;;" .. minetest.formspec_escape(s.name) .. "]"
        
    if is_auth then
        formspec = formspec .. "button[6.4,1.2;1.5,0.75;rename;" .. S("Rename") .. "]"
    end

    formspec = formspec ..
        "box[8.1,1.2;2.8,0.75;#1C1E24]" ..
        "label[8.3,1.55;" .. minetest.colorize("#FFAA00", tier_name) .. " " .. minetest.colorize("#DDDDDD", "(" .. resident_count .. "/" .. tier_cap .. ")") .. "]" ..
        "box[11.1,1.2;2.6,0.75;#1C1E24]" ..
        "label[11.4,1.55;" .. status_text .. "]"
        
    if is_owner then
        formspec = formspec .. "button[12.7,0.35;1.4,0.55;disband_prompt;" .. minetest.colorize("#FF6666", S("Disband")) .. "]"
    end

    if tab_index == 1 or not is_auth then
        -- Tab 1: Overview & Resident Census Table
        selected_idx = selected_idx or player_selected_resident[player_name] or 1
        if selected_idx > #res_list then selected_idx = math.max(1, #res_list) end
        player_selected_resident[player_name] = selected_idx
        local selected_res = res_list[selected_idx]

        local guard_summary = total_guards > 0 and 
            string.format("Guards: %d (%d Day / %d Night)", total_guards, day_guard_count, night_guard_count) or 
            "Guards: 0"

        local table_cells = {}
        if #res_list == 0 then
            table.insert(table_cells, S("No residents registered in town"))
            table.insert(table_cells, "-")
            table.insert(table_cells, "-")
            table.insert(table_cells, "-")
        else
            for _, item in ipairs(res_list) do
                local prof_formatted = item.profession:gsub("_", " "):gsub("^%l", string.upper)
                local shift_label = S("Daytime")
                if item.profession == "guard" then
                    shift_label = item.shift == "night" and S("Night Shift") or S("Day Shift")
                end
                table.insert(table_cells, minetest.formspec_escape(item.name))
                table.insert(table_cells, minetest.formspec_escape(prof_formatted))
                table.insert(table_cells, minetest.formspec_escape(shift_label))
                table.insert(table_cells, minetest.formspec_escape(item.pos_str))
            end
        end
        local table_rows = table.concat(table_cells, ",")

        formspec = formspec ..
            "box[0.4,2.5;13.7,5.2;#23262F]" ..
            "label[0.7,2.85;" .. minetest.colorize("#FFFFFF", S("── Town Resident Census ──")) .. "]" ..
            "label[8.8,2.85;" .. minetest.colorize("#00FFFF", guard_summary) .. "]" ..
            "tablecolumns[text,align=left;text,align=left;text,align=center;text,align=center]" ..
            "table[0.7,3.15;13.1,4.35;roster_table;" .. table_rows .. ";" .. selected_idx .. "]"

        -- Resident Inspector / Shift Action Bar (y=7.9 to 9.1)
        formspec = formspec ..
            "box[0.4,7.9;13.7,1.25;#23262F]"
            
        if selected_res then
            if selected_res.profession == "guard" then
                local cur_shift_label = selected_res.shift == "night" and S("Night Shift") or S("Day Shift")
                local target_btn_label = selected_res.shift == "night" and S("Switch to Day Shift") or S("Switch to Night Shift")
                formspec = formspec ..
                    "label[0.7,8.3;" .. minetest.colorize("#AAAAAA", S("Selected Guard:")) .. " " .. minetest.colorize("#FFFF00", selected_res.name) .. " (" .. minetest.colorize("#00FFFF", cur_shift_label) .. ")]" ..
                    "label[0.7,8.7;" .. minetest.colorize("#888888", S("Workstation: ") .. selected_res.pos_str) .. "]"
                    
                if is_auth then
                    formspec = formspec .. "button[10.0,8.15;3.8,0.75;toggle_guard_shift;" .. target_btn_label .. "]"
                end
            else
                local prof_title = selected_res.profession:gsub("_", " "):gsub("^%l", string.upper)
                formspec = formspec ..
                    "label[0.7,8.3;" .. minetest.colorize("#AAAAAA", S("Selected Settler:")) .. " " .. minetest.colorize("#FFFFFF", selected_res.name) .. " (" .. prof_title .. ")]" ..
                    "label[0.7,8.7;" .. minetest.colorize("#888888", S("Workstation: ") .. selected_res.pos_str) .. "]"
            end
        else
            formspec = formspec .. "label[0.7,8.5;" .. minetest.colorize("#888888", S("No residents registered in settlement.")) .. "]"
        end

    elseif tab_index == 2 and is_auth then
        -- Tab 2: Access Control
        local assoc_list = {}
        for _, name in ipairs(s.associates) do
            table.insert(assoc_list, minetest.formspec_escape(name))
        end
        if #assoc_list == 0 then
            table.insert(assoc_list, minetest.formspec_escape(S("(No additional associates authorized)")))
        end
        local assoc_rows = table.concat(assoc_list, ",")

        formspec = formspec ..
            "box[0.4,2.5;13.7,6.65;#23262F]" ..
            "label[0.7,2.9;" .. S("Town Owner: ") .. minetest.colorize("#FFFF00", s.owner) .. "]"
            
        if is_owner then
            formspec = formspec ..
                "field[0.7,3.6;5.0,0.75;new_owner;;" .. S("Transfer Ownership to...") .. "]" ..
                "button[6.0,3.6;2.5,0.75;transfer_owner;" .. S("Transfer") .. "]"
        end
        
        formspec = formspec ..
            "label[0.7,4.8;" .. minetest.colorize("#FFFFFF", S("── Authorized Associates ──")) .. "]" ..
            "tablecolumns[text,align=left]" ..
            "table[0.7,5.1;13.1,2.6;assoc_table;" .. assoc_rows .. ";0]"
            
        if is_owner then
            formspec = formspec ..
                "field[0.7,8.1;5.0,0.75;assoc_name;;" .. S("Player Name") .. "]" ..
                "button[6.0,8.1;2.5,0.75;add_assoc;" .. S("Add Associate") .. "]" ..
                "button[8.8,8.1;2.0,0.75;remove_assoc;" .. S("Remove") .. "]"
        end

    elseif tab_index == 3 and is_auth then
        -- Tab 3: Law & Defenses
        local death_cells = {}
        local deaths = s.death_log or {}
        if #deaths == 0 then
            table.insert(death_cells, "-")
            table.insert(death_cells, S("No settler casualties recorded"))
            table.insert(death_cells, "-")
            table.insert(death_cells, "-")
            table.insert(death_cells, "-")
        else
            for _, d in ipairs(deaths) do
                local pstr = d.pos and string.format("(%d,%d,%d)", d.pos.x, d.pos.y, d.pos.z) or "N/A"
                local dt = os.date("%m/%d %H:%M", d.timestamp or os.time())
                table.insert(death_cells, minetest.formspec_escape(dt))
                table.insert(death_cells, minetest.formspec_escape(d.settler_name or "Settler"))
                table.insert(death_cells, minetest.formspec_escape(d.cause or "Unknown"))
                table.insert(death_cells, minetest.formspec_escape(d.killer or "Unknown"))
                table.insert(death_cells, minetest.formspec_escape(pstr))
            end
        end
        local death_rows = table.concat(death_cells, ",")
        local total_historical = (s.historical_fallen_count or 0) + #deaths

        formspec = formspec ..
            "box[0.4,2.5;13.7,6.65;#23262F]" ..
            "label[0.7,2.85;" .. minetest.colorize("#FFFFFF", S("── Town Defenses & Telemetry ──")) .. "]" ..
            "label[0.7,3.25;" .. S("Active Ward Stones:") .. " " .. minetest.colorize("#00FF00", tostring(ward_stone_count)) .. "    |    " .. S("Guard Coverage:") .. " " .. minetest.colorize("#00FFFF", string.format("%d Guards (%d%%)", total_guards, guard_ratio)) .. "]" ..
            "label[0.7,3.85;" .. minetest.colorize("#FFFFFF", S("── Settler Incident Log (Recent Deaths) ──")) .. "]" ..
            "tablecolumns[text,align=left;text,align=left;text,align=left;text,align=left;text,align=center]" ..
            "table[0.7,4.15;13.1,1.5;death_table;" .. death_rows .. ";0]" ..
            "label[0.7,5.8;" .. S("Total Historical Mortality Count: ") .. minetest.colorize("#FFAA00", tostring(total_historical)) .. "]" ..
            "label[0.7,6.25;" .. minetest.colorize("#FFFFFF", S("── Settlement Criminal Records & Fines ──")) .. "]"

        local criminal_cells = {}
        local records = s.criminal_records or {}
        local count_rec = 0
        for pname, rec in pairs(records) do
            local days_rem, mins_rem = eg_settlers.db.get_decay_time_estimate(sid, pname)
            local parts = {}
            if rec.assault_count and rec.assault_count > 0 then
                local decay_info = days_rem > 0 and string.format("~%dd/%dm", days_rem, mins_rem) or string.format("~%dm", mins_rem)
                table.insert(parts, string.format("%d Assaults (%s)", rec.assault_count, decay_info))
            end
            if rec.murder_count and rec.murder_count > 0 then
                table.insert(parts, string.format("%d Murders (Perm)", rec.murder_count))
            end
            if #parts > 0 then
                count_rec = count_rec + 1
                table.insert(criminal_cells, minetest.formspec_escape(pname))
                table.insert(criminal_cells, minetest.formspec_escape(table.concat(parts, ", ")))
            end
        end
        if count_rec == 0 then
            table.insert(criminal_cells, S("All players in good standing"))
            table.insert(criminal_cells, S("No active warrants or restitution fines"))
        end
        local criminal_rows = table.concat(criminal_cells, ",")

        formspec = formspec ..
            "tablecolumns[text,align=left;text,align=left]" ..
            "table[0.7,6.55;13.1,1.35;wanted_table;" .. criminal_rows .. ";0]"

        local prec = eg_settlers.db.get_criminal_record(sid, player_name)
        if prec and ((prec.assault_count and prec.assault_count > 0) or (prec.murder_count and prec.murder_count > 0)) then
            if prec.assault_count and prec.assault_count > 0 then
                formspec = formspec .. "button[0.7,8.1;6.3,0.75;pay_assault_fine;" .. S("Pay Assault Fine (50 Lumps)") .. "]"
            end
            if prec.murder_count and prec.murder_count > 0 then
                formspec = formspec .. "button[7.4,8.1;6.3,0.75;pay_murder_fine;" .. S("Pay Murder Fine (200 Lumps)") .. "]"
            end
        else
            formspec = formspec .. "label[0.7,8.25;" .. minetest.colorize("#00FF00", S("Your standing in this settlement is clean.")) .. "]"
        end
    end
        
    return formspec
end

local function get_disband_formspec(sid)
    local s = eg_settlers.db.get_settlement(sid)
    if not s then return "" end
    
    local formspec = "size[7,4]" ..
        "box[0,0;7,4;#3A1A1A]" ..
        "label[0.5,0.5;" .. minetest.colorize("#FFFFFF", S("WARNING: You are about to permanently")) .. "]" ..
        "label[0.5,1.0;" .. minetest.colorize("#FFAAAA", S("disband ") .. s.name .. S(".")) .. "]" ..
        "label[0.5,1.8;" .. minetest.colorize("#DDDDDD", S("All town data will be lost and settlers released.")) .. "]" ..
        "button[0.5,2.9;2.5,0.8;cancel_disband;" .. S("Cancel") .. "]" ..
        "button[4.0,2.9;2.5,0.8;confirm_disband;" .. minetest.colorize("#FF4444", S("Confirm Disband")) .. "]"
        
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
        local sid = eg_settlers.db.create_settlement(pos)
        meta:set_string("settlement_id", sid)
        meta:set_string("infotext", S("Town Ledger: Unnamed Outpost"))
        minetest.get_node_timer(pos):start(10.0)
    end,
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local name = placer:get_player_name()
            local meta = minetest.get_meta(pos)
            local sid = meta:get_string("settlement_id")
            if sid and sid ~= "" then
                local s = eg_settlers.db.get_settlement(sid)
                if s and (not s.owner or s.owner == "") then
                    s.owner = name
                    eg_settlers.db.mark_dirty()
                    meta:set_string("owner", name)
                end
            end

            local inv = placer:get_inventory()
            if inv then
                local starter_farmer = ItemStack("eg_settlers:job_block_farmer")
                local starter_contract = ItemStack("eg_settlers:hiring_contract")
                if inv:room_for_item("main", starter_farmer) then
                    inv:add_item("main", starter_farmer)
                else
                    minetest.add_item(pos, starter_farmer)
                end
                if inv:room_for_item("main", starter_contract) then
                    inv:add_item("main", starter_contract)
                else
                    minetest.add_item(pos, starter_contract)
                end
                minetest.chat_send_player(name, minetest.colorize("#00FF00", S("[eg_settlers] Welcome to your new settlement! Starter Farmer Workstation & Hiring Contract added to inventory.")))
            end
        end
    end,
    
    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            local s = eg_settlers.db.get_settlement(sid)
            if s then
                s.is_orphaned = true
                eg_settlers.db.mark_dirty()
            end
        end
    end,

    can_dig = function(pos, player)
        if not player or not player:is_player() then return false end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()

        local is_owner = eg_settlers.db.is_owner(sid, name)
        local is_auth = eg_settlers.db.is_authorized(sid, name)
        local is_admin = minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer()

        if is_owner or is_auth or is_admin then
            return true
        end

        minetest.chat_send_player(name, S("Only the town owner or authorized associates can remove the Town Ledger."))
        return false
    end,

    on_blast = function(pos, intensity)
        -- Immune to TNT and explosion griefing
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            local meta = minetest.get_meta(pos)
            local sid = meta:get_string("settlement_id")
            if sid and sid ~= "" then
                local name = clicker:get_player_name()
                minetest.show_formspec(name, "eg_settlers:ledger_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z, get_formspec(sid, name, 1, 1))
            end
        end
        return itemstack
    end,
    
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            local s = eg_settlers.db.get_settlement(sid)
            if s then
                meta:set_string("infotext", S("Town Ledger: ") .. s.name)
            end
        end
        return true
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
    if formname:sub(1, 18) == "eg_settlers:ledger" then
        local parts = formname:sub(19):split("_")
        if #parts == 3 then
            local pos = {x = tonumber(parts[1]), y = tonumber(parts[2]), z = tonumber(parts[3])}
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
                    return true
                elseif fields.roster_table then
                    local event = minetest.explode_table_event(fields.roster_table)
                    if event.type == "CHG" or event.type == "DCL" then
                        player_selected_resident[name] = event.row
                        minetest.show_formspec(name, formname, get_formspec(sid, name, 1, event.row))
                        return true
                    end
                elseif fields.toggle_guard_shift and is_auth then
                    local s = eg_settlers.db.get_settlement(sid)
                    local res_list = get_sorted_residents(s)
                    local sel_idx = player_selected_resident[name] or 1
                    local selected_res = res_list[sel_idx]
                    if selected_res and selected_res.profession == "guard" and selected_res.rpos then
                        local rmeta = minetest.get_meta(selected_res.rpos)
                        local cur_shift = rmeta:get_string("guard_shift")
                        if cur_shift == "" then cur_shift = "day" end
                        local new_shift = (cur_shift == "night") and "day" or "night"
                        rmeta:set_string("guard_shift", new_shift)
                        
                        local shift_title = new_shift == "night" and S("Night Shift") or S("Day Shift")
                        local rname = rmeta:get_string("resident_name")
                        if rname == "" then rname = selected_res.name end
                        rmeta:set_string("infotext", S("Workstation: Guard") .. " (" .. shift_title .. ")\n" .. S("Resident: ") .. rname)
                        
                        -- Find and update active live guard entity
                        local objs = minetest.get_objects_inside_radius(selected_res.rpos, 80)
                        for _, obj in ipairs(objs) do
                            local ent = obj:get_luaentity()
                            if ent and ent.is_villager and ent.evergrowth_profession == "guard" then
                                local is_target = false
                                if ent.job_pos and vector.distance(ent.job_pos, selected_res.rpos) < 1.0 then
                                    is_target = true
                                elseif ent.game_name and (ent.game_name == selected_res.name or ent.game_name == selected_res.raw_name) then
                                    is_target = true
                                end
                                if is_target then
                                    ent.guard_shift = new_shift
                                    if ent.game_name then
                                        local new_label = new_shift == "night" and "Night Guard" or "Day Guard"
                                        ent.game_name = ent.game_name:gsub("Day Guard", new_label):gsub("Night Guard", new_label):gsub("Guard", new_label)
                                        ent.nametag = ent.game_name
                                        ent.object:set_properties({nametag = ent.nametag})
                                    end
                                    ent._was_off_duty = nil -- trigger immediate schedule tick
                                end
                            end
                        end
                        minetest.chat_send_player(name, minetest.colorize("#00FF00", S("[eg_settlers] Reassigned ") .. rname .. S(" to ") .. shift_title .. "."))
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 1, sel_idx))
                    return true
                elseif fields.disband_prompt and is_owner then
                    minetest.show_formspec(name, formname, get_disband_formspec(sid))
                    return true
                elseif fields.cancel_disband and is_owner then
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 1))
                    return true
                elseif fields.confirm_disband and is_owner then
                    eg_settlers.db.delete_settlement(sid)
                    minetest.remove_node(pos)
                    minetest.close_formspec(name, formname)
                    return true
                elseif fields.add_assoc and fields.assoc_name and is_owner then
                    if fields.assoc_name ~= "" then
                        eg_settlers.db.add_associate(sid, fields.assoc_name)
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 2))
                    return true
                elseif fields.remove_assoc and fields.assoc_name and is_owner then
                    if fields.assoc_name ~= "" then
                        eg_settlers.db.remove_associate(sid, fields.assoc_name)
                    end
                    minetest.show_formspec(name, formname, get_formspec(sid, name, 2))
                    return true
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
                    return true
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
                    return true
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
                    return true
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


-- LBM for Retroactive Deed Registration + Stale Occupied Cleanup
minetest.register_lbm({
    label = "Retroactive Deed Registration and Stale Cleanup",
    name = "eg_settlers:retro_deed_registration_v2",
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

            -- Stale occupied cleanup: disabled because get_objects_inside_radius fails 
            -- to find unloaded entities or entities that wandered >50 blocks away during day/night cycle.
            -- (Occupied clearing is handled gracefully in npc_behavior's on_die hook).
        end
    end,
})

