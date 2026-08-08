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
    -- Farmer
    ["farmer_wheat"] = {prof="farmer", text="The Farmer needs 20 Wheat", input="farming:wheat", in_count=20, out="default:gold_lump", out_count=2},
    ["farmer_cotton"] = {prof="farmer", text="The Farmer needs 50 Cotton", input="farming:cotton", in_count=50, out="default:gold_lump", out_count=7},
    ["farmer_rabbit"] = {prof="farmer", text="The Farmer needs 20 Raw Rabbit", input="mobs:rabbit_raw", in_count=20, out="default:gold_lump", out_count=10},
    -- Lumberjack
    ["lumberjack_wood"] = {prof="lumberjack", text="The Lumberjack needs 50 Wood", input="default:wood", in_count=50, out="default:gold_lump", out_count=4},
    ["lumberjack_jungle"] = {prof="lumberjack", text="The Lumberjack needs 50 Jungle Wood", input="default:junglewood", in_count=50, out="default:gold_lump", out_count=4},
    ["lumberjack_pine"] = {prof="lumberjack", text="The Lumberjack needs 50 Pine Wood", input="default:pine_wood", in_count=50, out="default:gold_lump", out_count=4},
    -- Miner
    ["miner_coal"] = {prof="miner", text="The Miner needs 20 Coal", input="default:coal_lump", in_count=20, out="default:gold_lump", out_count=2},
    ["miner_mese"] = {prof="miner", text="The Miner needs 5 Mese Crystals", input="default:mese_crystal", in_count=5, out="default:gold_lump", out_count=30},
    ["miner_diamond"] = {prof="miner", text="The Miner needs 2 Diamonds", input="default:diamond", in_count=2, out="default:gold_lump", out_count=60},
    -- Blacksmith (smith)
    ["smith_iron"] = {prof="smith", text="The Blacksmith needs 20 Iron Lumps", input="default:iron_lump", in_count=20, out="default:gold_lump", out_count=6},
    ["smith_bronze"] = {prof="smith", text="The Blacksmith needs 20 Bronze Ingots", input="default:bronze_ingot", in_count=20, out="default:gold_lump", out_count=25},
    -- Guard
    ["guard_swords"] = {prof="guard", text="The Guard needs 5 Steel Swords", input="default:sword_steel", in_count=5, out="default:gold_lump", out_count=50},
    ["guard_torches"] = {prof="guard", text="The Guard needs 99 Torches", input="default:torch", in_count=99, out="default:gold_lump", out_count=8},
    ["guard_coffee"] = {prof="guard", text="The Guard needs 10 Cups of Coffee", input="farming:coffee_cup", in_count=10, out="default:gold_lump", out_count=15},
    ["guard_chestplate"] = {prof="guard", text="The Guard needs 1 Steel Chestplate", input="3d_armor:chestplate_steel", in_count=1, out="default:gold_lump", out_count=40},
    ["guard_shield"] = {prof="guard", text="The Guard needs 1 Steel Shield", input="shields:shield_steel", in_count=1, out="default:gold_lump", out_count=35},
    -- Gunsmith
    ["gunsmith_gunpowder"] = {prof="gunsmith", text="The Gunsmith needs 20 Gunpowder", input="tnt:gunpowder", in_count=20, out="default:gold_lump", out_count=8},
    ["gunsmith_tnt"] = {prof="gunsmith", text="The Gunsmith needs 5 TNT", input="tnt:tnt", in_count=5, out="default:gold_lump", out_count=50},
    -- Roboticist
    ["roboticist_bronze"] = {prof="roboticist", text="The Roboticist needs 2 Bronze Blocks", input="default:bronzeblock", in_count=2, out="default:gold_lump", out_count=30},
    ["roboticist_coal"] = {prof="roboticist", text="The Roboticist needs 10 Coal Blocks", input="default:coalblock", in_count=10, out="default:gold_lump", out_count=25},
    -- Merchant
    ["merchant_glass"] = {prof="merchant", text="The Merchant needs 30 Glass", input="default:glass", in_count=30, out="default:gold_lump", out_count=4},
    ["merchant_clay"] = {prof="merchant", text="The Merchant needs 30 Clay Lumps", input="default:clay_lump", in_count=30, out="default:gold_lump", out_count=2},
    ["merchant_leather"] = {prof="merchant", text="The Merchant needs 20 Leather", input="mobs:leather", in_count=20, out="default:gold_lump", out_count=3},
    -- Brewer
    ["brewer_wine"] = {prof="brewer", text="The Brewer needs 5 Wine", input="wine:bottle_wine", in_count=5, out="default:gold_lump", out_count=13},
    ["brewer_beer"] = {prof="brewer", text="The Brewer needs 5 Beer", input="wine:bottle_beer", in_count=5, out="default:gold_lump", out_count=13},
    -- Librarian
    ["librarian_paper"] = {prof="librarian", text="The Librarian needs 20 Paper", input="default:paper", in_count=20, out="default:gold_lump", out_count=3},
    ["librarian_book"] = {prof="librarian", text="The Librarian needs 5 Books", input="default:book", in_count=5, out="default:gold_lump", out_count=13},
    ["librarian_bookshelf"] = {prof="librarian", text="The Librarian needs 2 Bookshelves", input="default:bookshelf", in_count=2, out="default:gold_lump", out_count=13},
    -- Mage
    ["mage_mese"] = {prof="mage", text="The Mage needs 2 Mese Crystals", input="default:mese_crystal", in_count=2, out="default:gold_lump", out_count=13},
    ["mage_obsidian"] = {prof="mage", text="The Mage needs 10 Obsidian", input="default:obsidian", in_count=10, out="default:gold_lump", out_count=13},
    ["mage_etherium"] = {prof="mage", text="The Mage needs 2 Etherium Dust", input="ethereal:etherium_dust", in_count=2, out="default:gold_lump", out_count=8},
    -- Technologist
    ["technologist_copper"] = {prof="technologist", text="The Technologist needs 20 Copper Ingots", input="default:copper_ingot", in_count=20, out="default:gold_lump", out_count=15},
    ["technologist_plastic"] = {prof="technologist", text="The Technologist needs 20 Plastic Sheets", input="basic_materials:plastic_sheet", in_count=20, out="default:gold_lump", out_count=5},
    -- Carpenter
    ["carpenter_cobble"] = {prof="carpenter", text="The Carpenter needs 200 Cobblestone", input="default:cobble", in_count=200, out="default:gold_lump", out_count=5},
    ["carpenter_wood"] = {prof="carpenter", text="The Carpenter needs 50 Wood", input="default:wood", in_count=50, out="default:gold_lump", out_count=3},
    ["carpenter_wool"] = {prof="carpenter", text="The Carpenter needs 40 White Wool", input="wool:white", in_count=40, out="default:gold_lump", out_count=5},
    -- Automobile Mechanic
    ["automobile_mechanic_steel"] = {prof="automobile_mechanic", text="The Mechanic needs 2 Steel Blocks", input="default:steelblock", in_count=2, out="default:gold_lump", out_count=20},
    ["automobile_mechanic_oil"] = {prof="automobile_mechanic", text="The Mechanic needs 2 Barrel Oil", input="techage:ta3_barrel_oil", in_count=2, out="default:gold_lump", out_count=25},
    ["automobile_mechanic_tin"] = {prof="automobile_mechanic", text="The Mechanic needs 40 Tin Ingots", input="default:tin_ingot", in_count=40, out="default:gold_lump", out_count=3},
    -- Nautical Mechanic
    ["nautical_mechanic_steel"] = {prof="nautical_mechanic", text="The Mechanic needs 2 Steel Blocks", input="default:steelblock", in_count=2, out="default:gold_lump", out_count=20},
    ["nautical_mechanic_glass"] = {prof="nautical_mechanic", text="The Mechanic needs 40 Glass", input="default:glass", in_count=40, out="default:gold_lump", out_count=3},
    ["nautical_mechanic_diamond"] = {prof="nautical_mechanic", text="The Mechanic needs 1 Diamond", input="default:diamond", in_count=1, out="default:gold_lump", out_count=25},
    -- Aircraft Mechanic
    ["aircraft_mechanic_tin"] = {prof="aircraft_mechanic", text="The Mechanic needs 2 Tin Blocks", input="default:tinblock", in_count=2, out="default:gold_lump", out_count=25},
    ["aircraft_mechanic_mese"] = {prof="aircraft_mechanic", text="The Mechanic needs 1 Mese Block", input="default:mese_block", in_count=1, out="default:gold_lump", out_count=65},
    -- Fisher
    ["fisher_string"] = {prof="fisher", text="The Fisher needs 40 String", input="farming:string", in_count=40, out="default:gold_lump", out_count=3},
    ["fisher_sticks"] = {prof="fisher", text="The Fisher needs 60 Sticks", input="default:stick", in_count=60, out="default:gold_lump", out_count=3},
    ["fisher_sand"] = {prof="fisher", text="The Fisher needs 40 Sand", input="default:sand", in_count=40, out="default:gold_lump", out_count=2},
}

local bounties_by_prof = {}
for id, req in pairs(bounty_requests) do
    bounties_by_prof[req.prof] = bounties_by_prof[req.prof] or {}
    table.insert(bounties_by_prof[req.prof], {id = id, req = req})
end

-- Utility to get formspec
local function get_job_board_formspec(pos, tab_index)
    tab_index = tab_index or 1
    local meta = minetest.get_meta(pos)
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    local sid = meta:get_string("settlement_id")
    local status = sid ~= "" and minetest.colorize("#00FF00", S("Connected")) or minetest.colorize("#FF0000", S("Unlinked"))
    
    local formspec = "size[10,10]" ..
        "tabheader[0,0;job_tabs;Bounties,Contracts,Workstations;" .. tab_index .. ";true;false]"
        
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
        -- Contracts: Dispenses eg_settlers:hiring_contract
        formspec = formspec ..
            "box[0,0;10,10;#EFE4B0]" ..
            "label[0.5,0.5;" .. minetest.colorize("#222222", S("Town Status:")) .. " " .. status .. "]" ..
            "label[0.5,1.5;" .. minetest.colorize("#222222", S("── Hiring Contract Procurement ──")) .. "]" ..
            "item_image[0.5,2.5;1,1;eg_settlers:hiring_contract]" ..
            "label[1.6,2.8;" .. minetest.colorize("#222222", S("Unified Hiring Contract (Place on any Job Block)")) .. "]" ..
            "item_image[4,3.5;1,1;default:gold_lump]" ..
            "label[5.1,3.8;" .. minetest.colorize("#222222", "x5 Gold Lumps") .. "]" ..
            "button[6.5,3.6;2.5,0.8;buy_hiring_contract;" .. S("Purchase") .. "]" ..
            "list[current_player;main;1,6.5;8,3.5;]"
    elseif tab_index == 3 then
        -- Workstations: Buy Job Blocks
        formspec = formspec ..
            "box[0,0;10,10;#EFE4B0]" ..
            "label[0.5,0.5;" .. minetest.colorize("#222222", S("Town Status:")) .. " " .. status .. "]" ..
            "label[0.5,1.5;" .. minetest.colorize("#222222", S("── Workstation Nodes (Job Blocks) ──")) .. "]" ..
            "textlist[0.5,2.2;6.5,3.8;workstation_list;"
        
        local job_list = {}
        for prof_id, jdef in pairs(eg_settlers.registered_job_blocks) do
            table.insert(job_list, prof_id)
        end
        table.sort(job_list)

        local list_items = {}
        for _, prof_id in ipairs(job_list) do
            local jdef = eg_settlers.registered_job_blocks[prof_id]
            table.insert(list_items, minetest.formspec_escape(jdef.description .. " (" .. jdef.cost .. " Gold)"))
        end

        local sel_idx = meta:get_int("selected_workstation_idx")
        if sel_idx < 1 or sel_idx > #job_list then sel_idx = 1 end
        local sel_prof = job_list[sel_idx]
        local sel_jdef = sel_prof and eg_settlers.registered_job_blocks[sel_prof]
        local sel_item = sel_jdef and sel_jdef.name or ""

        formspec = formspec .. table.concat(list_items, ",") .. ";" .. sel_idx .. ";false]"
        
        if sel_item ~= "" then
            formspec = formspec .. "item_image[7.5,2.0;1.5,1.5;" .. sel_item .. "]"
        end

        formspec = formspec ..
            "button[7.2,3.8;2.2,0.8;buy_workstation;" .. S("Purchase") .. "]" ..
            "list[current_player;main;1,6.5;8,3.5;]"
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
                        local prof_bounties = bounties_by_prof[chosen_prof]
                        if prof_bounties and #prof_bounties > 0 then
                            local chosen_bounty = prof_bounties[math.random(#prof_bounties)]
                            meta:set_string("bounty_id", chosen_bounty.id)
                            meta:set_string("bounty_text", chosen_bounty.req.text)
                            meta:set_string("infotext", S("Job Board Request: ") .. chosen_bounty.req.text)
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
                minetest.chat_send_player(name, S("Only authorized players can access this Job Board."))
                return itemstack
            end
            local formname = "eg_settlers:job_board_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z
            minetest.show_formspec(name, formname, get_job_board_formspec(pos, 1))
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
            local pname = player:get_player_name()
            local sid = meta:get_string("settlement_id")
            local authorized = false
            if sid and sid ~= "" then
                authorized = eg_settlers.db.is_authorized(sid, pname)
            else
                local owner = meta:get_string("owner")
                authorized = (owner == "" or owner == pname or minetest.check_player_privs(pname, {server=true}) or minetest.is_singleplayer())
            end
            if not authorized then
                minetest.close_formspec(pname, formname)
                return true
            end
            
            if fields.job_tabs then
                minetest.show_formspec(pname, formname, get_job_board_formspec(pos, tonumber(fields.job_tabs)))
                return true
            end
            
            -- Buy Hiring Contract (Tab 2)
            if fields.buy_hiring_contract then
                local p_inv = player:get_inventory()
                local cost_stack = ItemStack("default:gold_lump 5")
                if p_inv:contains_item("main", cost_stack) then
                    p_inv:remove_item("main", cost_stack)
                    local item = "eg_settlers:hiring_contract"
                    if p_inv:room_for_item("main", item) then
                        p_inv:add_item("main", item)
                    else
                        minetest.item_drop(ItemStack(item), player, pos)
                    end
                    minetest.chat_send_player(pname, S("Purchased 1x Hiring Contract!"))
                    minetest.show_formspec(pname, formname, get_job_board_formspec(pos, 2))
                else
                    minetest.chat_send_player(pname, S("Not enough gold lumps in inventory! Requires 5 Gold Lumps."))
                end
                return true
            end

            -- Buy Workstation (Tab 3)
            if fields.workstation_list or fields.buy_workstation then
                local evt = minetest.explode_textlist_event(fields.workstation_list or "")
                if evt.index and evt.index > 0 then
                    meta:set_int("selected_workstation_idx", evt.index)
                end

                if fields.buy_workstation or (evt.type == "DCL") then
                    local job_list = {}
                    for prof_id, jdef in pairs(eg_settlers.registered_job_blocks) do
                        table.insert(job_list, prof_id)
                    end
                    table.sort(job_list)

                    local sel_idx = meta:get_int("selected_workstation_idx")
                    if sel_idx < 1 or sel_idx > #job_list then sel_idx = 1 end
                    
                    local prof_id = job_list[sel_idx]
                    local jdef = eg_settlers.registered_job_blocks[prof_id]

                    if jdef then
                        local p_inv = player:get_inventory()
                        local cost_stack = ItemStack("default:gold_lump " .. jdef.cost)
                        if p_inv:contains_item("main", cost_stack) then
                            p_inv:remove_item("main", cost_stack)
                            local item = jdef.name
                            if p_inv:room_for_item("main", item) then
                                p_inv:add_item("main", item)
                            else
                                minetest.item_drop(ItemStack(item), player, pos)
                            end
                            minetest.chat_send_player(pname, S("Purchased 1x ") .. jdef.description .. "!")
                            minetest.show_formspec(pname, formname, get_job_board_formspec(pos, 3))
                        else
                            minetest.chat_send_player(pname, S("Not enough gold lumps in inventory! Need: ") .. jdef.cost .. " Gold Lumps.")
                        end
                    end
                elseif evt.type == "CHG" then
                    minetest.show_formspec(pname, formname, get_job_board_formspec(pos, 3))
                end
                return true
            end


            
            -- Bounties (now Tab 1)
            if fields.submit_bounty then
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
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
