local S = minetest.get_translator("eg_settlers")

minetest.register_craftitem("eg_settlers:hiring_contract", {
    description = S("Hiring Contract") .. "\n" ..

                  S("Place on a Workstation Node (Job Block) to hire a settler.") .. "\n" ..
                  S("Requires an unassigned bed within settlement bounds."),
    inventory_image = "default_paper.png^(default_gold_lump.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end
        
        local under_pos = pointed_thing.under
        local under_node = minetest.get_node(under_pos)
        local prof_id = string.match(under_node.name, "^eg_settlers:job_block_(.+)$")
        
        if not prof_id then
            minetest.chat_send_player(placer:get_player_name(),
                S("[eg_settlers] Hiring Contracts must be placed directly on a Workstation Node (Job Block)."))
            return itemstack
        end

        local block_meta = minetest.get_meta(under_pos)
        if block_meta:get_int("occupied") == 1 then
            minetest.chat_send_player(placer:get_player_name(),
                S("[eg_settlers] This workstation is already occupied by ") .. block_meta:get_string("resident_name") .. ".")
            return itemstack
        end

        -- 1. Environmental Validation
        local valid, err_msg = eg_settlers.validate_job_block_environment(under_pos, prof_id)
        if not valid then
            minetest.chat_send_player(placer:get_player_name(), S("[eg_settlers] Infrastructure check failed: ") .. err_msg)
            return itemstack
        end

        -- 2. Total Bed & Population Check
        local total_beds = eg_settlers.get_total_beds_count(under_pos, 200)
        local total_settlers = eg_settlers.get_total_settlers_count(under_pos, 200)

        if total_settlers >= total_beds then
            minetest.chat_send_player(placer:get_player_name(),
                S("[eg_settlers] Housing cap reached (") .. total_settlers .. S(" settlers / ") .. total_beds .. S(" beds). Build and place another bed first."))
            return itemstack
        end

        local sid = eg_settlers.db.find_nearest_settlement(under_pos, 200)
        local bed_pos = eg_settlers.find_unassigned_bed(under_pos, 200)
        if not bed_pos then
            minetest.chat_send_player(placer:get_player_name(),
                S("[eg_settlers] No unassigned bed found within settlement radius. Build and place a bed first."))
            return itemstack
        end

        -- 3. Population Cap Check
        if sid then
            local current_residents = eg_settlers.db.get_resident_count(sid)
            local cap = eg_settlers.db.get_population_cap(sid)
            if current_residents >= cap then
                minetest.chat_send_player(placer:get_player_name(),
                    S("[eg_settlers] Settlement population cap reached (") .. current_residents .. "/" .. cap .. S("). Upgrade town infrastructure."))
                return itemstack
            end
        end

        -- Guard Shift Determination
        local guard_shift = nil
        if prof_id == "guard" then
            local guard_count = 0
            if sid then
                local residents = eg_settlers.db.get_residents(sid)
                for _, res in pairs(residents) do
                    if res.profession == "guard" then
                        guard_count = guard_count + 1
                    end
                end
            else
                local p1 = vector.subtract(under_pos, 200)
                local p2 = vector.add(under_pos, 200)
                local nodes = minetest.find_nodes_in_area(p1, p2, {"eg_settlers:job_block_guard"})
                for _, npos in ipairs(nodes) do
                    local nmeta = minetest.get_meta(npos)
                    if nmeta:get_int("occupied") == 1 then
                        guard_count = guard_count + 1
                    end
                end
            end
            guard_shift = (guard_count % 2 == 0) and "day" or "night"
        end

        -- Spawn Villager
        local spawn_pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or pointed_thing.above
        local npc_name = eg_settlers.spawn_trader(spawn_pos, prof_id, true, {
            home_pos = bed_pos,
            job_pos = under_pos,
            guard_shift = guard_shift,
        })

        -- Bind Job Block & Bed Metadata
        block_meta:set_int("occupied", 1)
        block_meta:set_string("resident_name", npc_name or prof_id)
        block_meta:set_string("profession", prof_id)
        block_meta:set_string("job_pos", minetest.pos_to_string(under_pos))
        block_meta:set_string("home_pos", minetest.pos_to_string(bed_pos))
        if guard_shift then
            block_meta:set_string("guard_shift", guard_shift)
            local shift_title = guard_shift == "night" and S("Night Shift") or S("Day Shift")
            block_meta:set_string("infotext", S("Workstation: Guard") .. " (" .. shift_title .. ")\n" .. S("Resident: ") .. (npc_name or prof_id))
        else
            block_meta:set_string("infotext", S("Workstation: ") .. prof_id:sub(1,1):upper() .. prof_id:sub(2) .. "\n" .. S("Resident: ") .. (npc_name or prof_id))
        end

        eg_settlers.assign_bed(bed_pos, npc_name or prof_id)

        if sid then
            block_meta:set_string("settlement_id", sid)
            eg_settlers.db.register_resident(sid, under_pos, npc_name or prof_id, prof_id)
        end

        minetest.sound_play("default_place_node_hard", {pos = spawn_pos, gain = 1.0}, true)

        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:hiring_contract",
    recipe = {
        {"default:paper", "default:gold_ingot"},
    }
})

-- Villager Relocation Contract
-- Created when a player sneak+right-clicks a tethered villager NPC.
-- Stores the NPC's name, profession, texture, and health in item metadata.
minetest.register_craftitem("eg_settlers:contract_villager_relocation", {
    description = S("Villager Relocation Contract"),
    inventory_image = "default_paper.png^[colorize:#8B4513:80",
    groups = {not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end

        local under_pos = pointed_thing.under
        local under_node = minetest.get_node(under_pos)
        local prof_id = string.match(under_node.name, "^eg_settlers:job_block_(.+)$")

        if not prof_id then
            minetest.chat_send_player(placer:get_player_name(),
                S("Use this on a Workstation Node (Job Block) to place the villager."))
            return itemstack
        end

        local block_meta = minetest.get_meta(under_pos)
        if block_meta:get_int("occupied") == 1 then
            minetest.chat_send_player(placer:get_player_name(),
                S("This workstation already has a resident."))
            return itemstack
        end

        -- Verify bed availability
        local bed_pos = eg_settlers.find_unassigned_bed(under_pos, 200)
        if not bed_pos then
            minetest.chat_send_player(placer:get_player_name(),
                S("No unassigned bed found within settlement bounds."))
            return itemstack
        end

        local meta = itemstack:get_meta()
        local profession = meta:get_string("profession")
        if profession == "" then profession = prof_id end

        local guard_shift = nil
        if profession == "guard" then
            local sid_check = eg_settlers.db.find_nearest_settlement(under_pos, 200)
            local guard_count = 0
            if sid_check then
                local residents = eg_settlers.db.get_residents(sid_check)
                for _, res in pairs(residents) do
                    if res.profession == "guard" then guard_count = guard_count + 1 end
                end
            else
                local p1 = vector.subtract(under_pos, 200)
                local p2 = vector.add(under_pos, 200)
                local nodes = minetest.find_nodes_in_area(p1, p2, {"eg_settlers:job_block_guard"})
                for _, npos in ipairs(nodes) do
                    local nmeta = minetest.get_meta(npos)
                    if nmeta:get_int("occupied") == 1 then
                        guard_count = guard_count + 1
                    end
                end
            end
            guard_shift = (guard_count % 2 == 0) and "day" or "night"
        end

        local rname = meta:get_string("resident_name")
        if profession == "guard" and rname ~= "" then
            rname = rname:gsub(" the Day Guard", ""):gsub(" the Night Guard", ""):gsub(" the Guard", "")
            if guard_shift then
                local shift_label = guard_shift == "night" and "Night Guard" or "Day Guard"
                rname = rname .. " the " .. shift_label
            end
        end

        local trades_str = meta:get_string("trades")
        local override_data = {
            nametag = rname,
            texture = meta:get_string("texture"),
            health = meta:get_int("health"),
            trades = (trades_str ~= "") and minetest.deserialize(trades_str) or nil,
            home_pos = bed_pos,
            job_pos = under_pos,
            guard_shift = guard_shift,
        }

        local spawn_pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or pointed_thing.above
        local npc_name = eg_settlers.spawn_trader(spawn_pos, profession, true, override_data)

        block_meta:set_int("occupied", 1)
        block_meta:set_string("resident_name", npc_name or "Villager")
        block_meta:set_string("profession", profession)
        block_meta:set_string("job_pos", minetest.pos_to_string(under_pos))
        block_meta:set_string("home_pos", minetest.pos_to_string(bed_pos))
        if guard_shift then
            block_meta:set_string("guard_shift", guard_shift)
            local shift_title = guard_shift == "night" and S("Night Shift") or S("Day Shift")
            block_meta:set_string("infotext", S("Workstation: Guard") .. " (" .. shift_title .. ")\n" .. S("Resident: ") .. (npc_name or "Villager"))
        else
            block_meta:set_string("infotext", S("Workstation: ") .. profession .. "\n" .. S("Resident: ") .. (npc_name or "Villager"))
        end

        eg_settlers.assign_bed(bed_pos, npc_name or "Villager")

        local sid = eg_settlers.db.find_nearest_settlement(under_pos, 200)
        if sid then
            block_meta:set_string("settlement_id", sid)
            eg_settlers.db.register_resident(sid, under_pos, npc_name or "Villager", profession)
        end


        minetest.sound_play("default_place_node_hard", {pos = spawn_pos, gain = 1.0}, true)

        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})
