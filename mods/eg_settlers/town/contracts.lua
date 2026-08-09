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

        -- Spawn Villager
        local spawn_pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or pointed_thing.above
        local npc_name = eg_settlers.spawn_trader(spawn_pos, prof_id, true, {
            home_pos = bed_pos,
            job_pos = under_pos,
        })

        -- Bind Job Block & Bed Metadata
        block_meta:set_int("occupied", 1)
        block_meta:set_string("resident_name", npc_name or prof_id)
        block_meta:set_string("profession", prof_id)
        block_meta:set_string("job_pos", minetest.pos_to_string(under_pos))
        block_meta:set_string("home_pos", minetest.pos_to_string(bed_pos))
        block_meta:set_string("infotext", S("Workstation: ") .. prof_id:sub(1,1):upper() .. prof_id:sub(2) .. "\n" .. S("Resident: ") .. (npc_name or prof_id))

        local bmeta = minetest.get_meta(bed_pos)
        bmeta:set_string("assigned_settler", npc_name or prof_id)
        eg_settlers.update_bed_infotext(bed_pos)

        local partner_pos = eg_settlers.get_partner_bed_pos(bed_pos)
        if partner_pos then
            local pmeta = minetest.get_meta(partner_pos)
            pmeta:set_string("assigned_settler", npc_name or prof_id)
            eg_settlers.update_bed_infotext(partner_pos)
        end

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



-- Companion Contracts
minetest.register_craftitem("eg_settlers:contract_companion_male", {
    description = S("Male Companion's Contract"),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local check_pos = pointed_thing.above
        local node = minetest.get_node(check_pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or check_pos
        local owner_name = placer and placer:get_player_name() or ""
        eg_settlers.spawn_companion(pos, false, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:contract_companion_male",
    recipe = {
        {"default:paper", "default:stick"},
    }
})

minetest.register_craftitem("eg_settlers:contract_companion_female", {
    description = S("Female Companion's Contract"),
    inventory_image = "default_paper.png^(default_apple.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local check_pos = pointed_thing.above
        local node = minetest.get_node(check_pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or check_pos
        local owner_name = placer and placer:get_player_name() or ""
        eg_settlers.spawn_companion(pos, true, owner_name)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:contract_companion_female",
    recipe = {
        {"default:paper", "default:apple"},
    }
})

minetest.register_craftitem("eg_settlers:contract_companion_relocation", {
    description = S("Companion Relocation Contract"),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    groups = {not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return end
        local check_pos = pointed_thing.above
        local node = minetest.get_node(check_pos)
        local def = minetest.registered_nodes[node.name]
        if not def or not (node.name == "air" or def.buildable_to) then return end
        local pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or check_pos
        
        local meta = itemstack:get_meta()
        local override_data = {
            nametag = meta:get_string("companion_nametag"),
            skin_index = meta:get_int("companion_skin_index"),
            health = meta:get_int("companion_health")
        }
        if override_data.health == 0 then override_data.health = 20 end
        local is_female = meta:get_int("companion_is_female") == 1
        local owner_name = meta:get_string("companion_owner")
        if owner_name == "" and placer then
            owner_name = placer:get_player_name()
        end
        
        eg_settlers.spawn_companion(pos, is_female, owner_name, override_data)
        minetest.sound_play("default_place_node_hard", {pos = pos, gain = 1.0}, true)
        
        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})

-- Wardrobe Wand
minetest.register_craftitem("eg_settlers:wardrobe_wand", {
    description = S("Wardrobe Wand (Punch Companion to Change Clothes)"),
    inventory_image = "default_stick.png^[colorize:#FF00FF:128",
})

minetest.register_craft({
    output = "eg_settlers:wardrobe_wand",
    recipe = {
        {"", "", "dye:magenta"},
        {"", "default:stick", ""},
        {"default:stick", "", ""},
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
        local trades_str = meta:get_string("trades")
        local override_data = {
            nametag = meta:get_string("resident_name"),
            texture = meta:get_string("texture"),
            health = meta:get_int("health"),
            trades = (trades_str ~= "") and minetest.deserialize(trades_str) or nil,
            home_pos = bed_pos,
            job_pos = under_pos,
        }
        local profession = meta:get_string("profession")
        if profession == "" then profession = prof_id end

        local spawn_pos = eg_settlers.get_safe_spawn_pos(pointed_thing) or pointed_thing.above
        local npc_name = eg_settlers.spawn_trader(spawn_pos, profession, true, override_data)

        block_meta:set_int("occupied", 1)
        block_meta:set_string("resident_name", npc_name or "Villager")
        block_meta:set_string("profession", profession)
        block_meta:set_string("job_pos", minetest.pos_to_string(under_pos))
        block_meta:set_string("home_pos", minetest.pos_to_string(bed_pos))
        block_meta:set_string("infotext", S("Workstation: ") .. profession .. "\n" .. S("Resident: ") .. (npc_name or "Villager"))

        local bed_meta = minetest.get_meta(bed_pos)
        bed_meta:set_string("assigned_settler", npc_name or "Villager")
        eg_settlers.update_bed_infotext(bed_pos)

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
