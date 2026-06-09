local S = minetest.get_translator("eg_settlers")

local seeker_professions = {
    {id = "farmer", name = "Farmer", cost = 5},
    {id = "lumberjack", name = "Lumberjack", cost = 5},
    {id = "miner", name = "Miner", cost = 8},
    {id = "smith", name = "Blacksmith", cost = 10},
    {id = "guard", name = "Guard", cost = 8},
    {id = "gunsmith", name = "Gunsmith", cost = 15},
    {id = "roboticist", name = "Roboticist", cost = 20},
}

local bounty_requests = {
    ["farmer"] = {text = "The Farmer needs 20 Wheat", input = "farming:wheat", in_count = 20, out = "default:gold_lump", out_count = 1},
    ["lumberjack"] = {text = "The Lumberjack needs 20 Wood", input = "default:wood", in_count = 20, out = "default:gold_lump", out_count = 1},
    ["miner"] = {text = "The Miner needs 20 Coal", input = "default:coal_lump", in_count = 20, out = "default:gold_lump", out_count = 1},
    ["smith"] = {text = "The Blacksmith needs 20 Iron", input = "default:iron_lump", in_count = 20, out = "default:gold_lump", out_count = 2},
}

-- Utility to get formspec
local function get_job_board_formspec(pos, tab_index)
    tab_index = tab_index or 1
    local meta = minetest.get_meta(pos)
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    local sid = meta:get_string("settlement_id")
    local status = sid ~= "" and minetest.colorize("#00FF00", S("Connected")) or minetest.colorize("#FF0000", S("Unlinked"))
    
    local formspec = "size[10,10]" ..
        "tabheader[0,0;job_tabs;Bounties,Contracts;" .. tab_index .. ";true;false]"
        
    if tab_index == 1 then
        -- Bounties: Paper theme
        local b_text = meta:get_string("bounty_text")
        local b_id = meta:get_string("bounty_id")
        
        formspec = formspec ..
            "box[0,0;10,10;#EFE4B0]" ..
            "label[0.5,0.5;" .. minetest.colorize("#222222", S("Town Status:")) .. " " .. status .. "]" ..
            "label[0.5,1.5;" .. minetest.colorize("#222222", S("── Daily Bounty ──")) .. "]" ..
            "label[0.5,2.2;" .. minetest.colorize("#222222", S("Current Request: ") .. b_text) .. "]"
            
        if b_id ~= "" and bounty_requests[b_id] then
            local b = bounty_requests[b_id]
            formspec = formspec ..
                "label[0.5,3.5;" .. minetest.colorize("#222222", S("Required:")) .. "]" ..
                "item_image[0.5,4;1,1;" .. b.input .. "]" ..
                "label[1.5,4.3;" .. minetest.colorize("#222222", "x" .. b.in_count) .. "]" ..
                "list[nodemeta:" .. pos_str .. ";bounty_input;2.5,4;1,1;]" ..
                "button[4,4;2,1;submit_bounty;" .. S("Submit") .. "]" ..
                "label[6.5,3.5;" .. minetest.colorize("#222222", S("Reward:")) .. "]" ..
                "item_image[6.5,4;1,1;" .. b.out .. "]" ..
                "label[7.5,4.3;" .. minetest.colorize("#222222", "x" .. b.out_count) .. "]" ..
                "list[nodemeta:" .. pos_str .. ";bounty_output;8.5,4;1,1;]"
        else
            formspec = formspec ..
                "label[0.5,3.5;" .. minetest.colorize("#222222", S("Input:")) .. "]" ..
                "list[nodemeta:" .. pos_str .. ";bounty_input;1.5,4;1,1;]" ..
                "button[3,4;2,1;submit_bounty;" .. S("Submit") .. "]" ..
                "label[5.5,3.5;" .. minetest.colorize("#222222", S("Reward:")) .. "]" ..
                "list[nodemeta:" .. pos_str .. ";bounty_output;6.5,4;1,1;]"
        end
        
        formspec = formspec ..
            "list[current_player;main;1,6.5;8,3.5;]" ..
            "listring[nodemeta:" .. pos_str .. ";bounty_input]" ..
            "listring[current_player;main]"
    elseif tab_index == 2 then
        -- Contracts: Paper theme
        local seekers_str = meta:get_string("seekers")
        local seekers = {}
        if seekers_str ~= "" then
            seekers = minetest.deserialize(seekers_str) or {}
        end
        
        formspec = formspec ..
            "box[0,0;10,10;#EFE4B0]" ..
            "label[0.5,0.5;" .. minetest.colorize("#222222", S("Town Status:")) .. " " .. status .. "]" ..
            "label[0.5,1.5;" .. minetest.colorize("#222222", S("── Daily Seekers ──")) .. "]"
            
        local y = 2.5
        for i, s in ipairs(seekers) do
            local contract_item = "eg_settlers:contract_" .. s.id
            formspec = formspec .. string.format("item_image[0.5,%f;1,1;%s]", y - 0.2, contract_item)
            formspec = formspec .. string.format("label[1.6,%f;%s]", y + 0.1, minetest.colorize("#222222", s.name))
            
            formspec = formspec .. string.format("item_image[4,%f;1,1;default:gold_lump]", y - 0.2)
            formspec = formspec .. string.format("label[5.1,%f;%s]", y + 0.1, minetest.colorize("#222222", "x" .. s.cost))
            
            formspec = formspec .. string.format("button[6.5,%f;2,0.8;recruit_%d;%s]", y - 0.1, i, S("Recruit"))
            y = y + 1.2
        end
        
        formspec = formspec ..
            "label[8,0.5;" .. minetest.colorize("#222222", S("Payment:")) .. "]" ..
            "list[nodemeta:" .. pos_str .. ";contract_payment;8,1;1,1;]" ..
            "list[current_player;main;1,6.5;8,3.5;]" ..
            "listring[nodemeta:" .. pos_str .. ";contract_payment]" ..
            "listring[current_player;main]"
    end
    
    return formspec
end

minetest.register_node("eg_settlers:job_board", {
    description = S("Job Board"),
    drawtype = "mesh",
    mesh = "eg_settlers_job_board.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "default_wood.png",
        "default_wood.png^[colorize:#EFE4B0:230"
    },
    selection_box = {
        type = "fixed",
        fixed = {
            {-0.1, -0.5, 0.0, 0.1, 1.5, 0.2},
            {-0.45, 0.2, -0.05, 0.45, 1.2, 0.0},
            {-0.5, 1.2, -0.2, 0.5, 1.3, 0.2},
        }
    },
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.1, -0.5, 0.0, 0.1, 1.5, 0.2},
            {-0.45, 0.2, -0.05, 0.45, 1.2, 0.0},
            {-0.5, 1.2, -0.2, 0.5, 1.3, 0.2},
        }
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Job Board: Unlinked"))
        meta:set_string("bounty_text", S("No active request."))
        meta:set_string("bounty_id", "")
        
        local inv = meta:get_inventory()
        inv:set_size("contract_payment", 1)
        inv:set_size("bounty_input", 1)
        inv:set_size("bounty_output", 1)
        
        meta:set_int("last_day_count", minetest.get_day_count())
        
        local seekers = {}
        for i=1,3 do
            table.insert(seekers, seeker_professions[math.random(#seeker_professions)])
        end
        meta:set_string("seekers", minetest.serialize(seekers))
        
        local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
        if sid then
            meta:set_string("settlement_id", sid)
            meta:set_string("infotext", S("Job Board: Connected to town"))
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
            meta:set_string("infotext", S("Job Board: Unlinked"))
        end
        
        if sid == "" then
            sid = eg_settlers.db.find_nearest_settlement(pos, 200)
            if sid then
                meta:set_string("settlement_id", sid)
                meta:set_string("infotext", S("Job Board: Connected to town"))
            end
        end
        
        if current_day > last_day then
            meta:set_int("last_day_count", current_day)
            
            local seekers = {}
            for i=1,3 do
                table.insert(seekers, seeker_professions[math.random(#seeker_professions)])
            end
            meta:set_string("seekers", minetest.serialize(seekers))
            
            if sid and sid ~= "" then
                local settlement = eg_settlers.db.get_settlement(sid)
                if settlement and settlement.satiated == 1 then
                    local valid_professions = {}
                    for pos_str, res in pairs(settlement.residents) do
                        table.insert(valid_professions, res.profession)
                    end
                    
                    if #valid_professions > 0 then
                        local chosen_prof = valid_professions[math.random(#valid_professions)]
                        local bounty = bounty_requests[chosen_prof]
                        if bounty then
                            meta:set_string("bounty_id", chosen_prof)
                            meta:set_string("bounty_text", bounty.text)
                            meta:set_string("infotext", S("Job Board Request: ") .. bounty.text)
                        end
                    end
                end
            end
        end
        return true
    end,
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            local formname = "eg_settlers:job_board_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
            minetest.show_formspec(clicker:get_player_name(), formname, get_job_board_formspec(pos, 1))
        end
        return itemstack
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if string.sub(formname, 1, 22) == "eg_settlers:job_board_" then
        local coords = string.sub(formname, 23)
        local parts = string.split(coords, "_")
        if #parts == 3 then
            local pos = {x=tonumber(parts[1]), y=tonumber(parts[2]), z=tonumber(parts[3])}
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local pname = player:get_player_name()
            
            if fields.job_tabs then
                minetest.show_formspec(pname, formname, get_job_board_formspec(pos, tonumber(fields.job_tabs)))
                return true
            end
            
            -- Contracts (now Tab 2)
            for k, v in pairs(fields) do
                if string.sub(k, 1, 8) == "recruit_" then
                    local idx = tonumber(string.sub(k, 9))
                    local seekers_str = meta:get_string("seekers")
                    if seekers_str ~= "" then
                        local seekers = minetest.deserialize(seekers_str)
                        if seekers and seekers[idx] then
                            local s = seekers[idx]
                            local payment_stack = inv:get_stack("contract_payment", 1)
                            if payment_stack:get_name() == "default:gold_lump" and payment_stack:get_count() >= s.cost then
                                payment_stack:take_item(s.cost)
                                inv:set_stack("contract_payment", 1, payment_stack)
                                
                                local contract_item = "eg_settlers:contract_" .. s.id
                                local p_inv = player:get_inventory()
                                if p_inv:room_for_item("main", contract_item) then
                                    p_inv:add_item("main", contract_item)
                                else
                                    minetest.item_drop(ItemStack(contract_item), player, pos)
                                end
                                minetest.chat_send_player(pname, S("Recruited: ") .. s.name)
                                
                                table.remove(seekers, idx)
                                meta:set_string("seekers", minetest.serialize(seekers))
                                minetest.show_formspec(pname, formname, get_job_board_formspec(pos, 2))
                            else
                                minetest.chat_send_player(pname, S("Not enough gold lumps in the payment slot! Need: ") .. s.cost)
                            end
                        end
                    end
                end
            end
            
            -- Bounties (now Tab 1)
            if fields.submit_bounty then
                local b_id = meta:get_string("bounty_id")
                if b_id ~= "" and bounty_requests[b_id] then
                    local b = bounty_requests[b_id]
                    local in_stack = inv:get_stack("bounty_input", 1)
                    if in_stack:get_name() == b.input and in_stack:get_count() >= b.in_count then
                        local out_stack = ItemStack(b.out .. " " .. b.out_count)
                        if inv:room_for_item("bounty_output", out_stack) then
                            in_stack:take_item(b.in_count)
                            inv:set_stack("bounty_input", 1, in_stack)
                            inv:add_item("bounty_output", out_stack)
                            
                            meta:set_string("bounty_id", "")
                            meta:set_string("bounty_text", S("Bounty completed for today!"))
                            meta:set_string("infotext", S("Job Board: Bounty Completed"))
                            minetest.show_formspec(pname, formname, get_job_board_formspec(pos, 1))
                            minetest.chat_send_player(pname, S("Bounty completed!"))
                        else
                            minetest.chat_send_player(pname, S("Clear the reward output slot first!"))
                        end
                    else
                        minetest.chat_send_player(pname, S("Incorrect items for the bounty."))
                    end
                else
                    minetest.chat_send_player(pname, S("No active bounty."))
                end
            end
        end
        return true
    end
end)
