--[[
    Evergrowth Villages - Settlement System
    =======================================
    Registers the Housing Deed node, which acts as a home marker for villager
    NPCs. Players build their own houses and place a Deed inside to designate
    it as a residence. Villagers are then assigned via Contracts.

    The Deed cannot be dug while it has a resident assigned to it.
    The player must relocate the resident first (sneak+right-click the NPC).
]]--

local S = minetest.get_translator("eg_settlers")

-- Housing Deed Node
-- Housing Deed Node (Deprecated for Villagers; Retained for Companions)
minetest.register_node("eg_settlers:housing_deed", {
    description = S("Housing Deed (Companions Only)") .. "\n" .. S("Workstations (Job Blocks) are now required for villager contracts."),
    drawtype = "nodebox",
    tiles = {"default_sign_wall_steel.png^[multiply:#FFD700"},
    inventory_image = "default_sign_steel.png^[multiply:#FFD700",
    wield_image = "default_sign_steel.png^[multiply:#FFD700",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    use_texture_alpha = "opaque",
    node_box = {
        type = "wallmounted",
        wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
        wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
        wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
    },
    selection_box = {
        type = "wallmounted",
    },
    groups = {choppy = 2, dig_immediate = 2, attached_node = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("occupied", 0)
        meta:set_string("resident_name", "")
        meta:set_string("infotext", S("Housing Deed (Companion Deed Only)"))
    end,
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local meta = minetest.get_meta(pos)
            meta:set_string("owner", placer:get_player_name())
        end
    end,

    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        if sid and sid ~= "" then
            eg_settlers.db.unregister_resident(sid, pos)
        end
    end,

    can_dig = function(pos, player)
        if not player or not player:is_player() then return false end
        local meta = minetest.get_meta(pos)
        local sid = meta:get_string("settlement_id")
        local name = player:get_player_name()
        
        local authorized = false
        local owner = meta:get_string("owner")
        local is_node_owner = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
        if is_node_owner then
            authorized = true
        elseif sid and sid ~= "" then
            authorized = eg_settlers.db.is_authorized(sid, name)
        end
        
        if not authorized then
            minetest.chat_send_player(name, S("Only authorized players can remove this Housing Deed."))
            return false
        end

        if meta:get_int("occupied") == 1 then
            if player:get_player_control().sneak then
                return true
            end
            minetest.chat_send_player(name, S("Relocate the companion first, or hold Sneak while mining."))
            return false
        end
        return true
    end,

    on_blast = function(pos, intensity)
        return nil
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then return itemstack end
        minetest.chat_send_player(clicker:get_player_name(),
            S("[eg_settlers] Housing Deeds are deprecated for villagers. Use profession Workstations (Job Blocks) for villager contracts."))
        return itemstack
    end,
})

minetest.register_craft({
    output = "eg_settlers:housing_deed",
    recipe = {
        {"default:paper", "dye:black"},
    }
})

--------------------------------------------------
-- Bed Management & Unassigned Scanner
--------------------------------------------------
function eg_settlers.update_bed_infotext(pos)
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    local reserved = meta:get_string("player_reserved") == "true"
    local assigned = meta:get_string("assigned_settler")

    if reserved or (owner ~= "" and assigned == "") then
        meta:set_string("infotext", S("Player Bed (Owner: ") .. (owner ~= "" and owner or "Player") .. ")")
    elseif assigned ~= "" then
        meta:set_string("infotext", S("Settler Bed (Assigned: ") .. assigned .. ")")
    else
        meta:set_string("infotext", S("Settler Bed (Unassigned)"))
    end
end

function eg_settlers.find_unassigned_bed(pos, radius)
    radius = radius or 30
    local p1 = vector.subtract(pos, radius)
    local p2 = vector.add(pos, radius)
    
    local beds = minetest.find_nodes_in_area(p1, p2, {"group:bed_bottom"})
    if #beds == 0 then
        beds = minetest.find_nodes_in_area(p1, p2, {"group:bed"})
    end

    for _, bed_pos in ipairs(beds) do
        local meta = minetest.get_meta(bed_pos)
        local owner = meta:get_string("owner")
        local reserved = meta:get_string("player_reserved") == "true"
        local assigned = meta:get_string("assigned_settler")
        
        local partner_occupied = false
        local node = minetest.get_node(bed_pos)
        local dir = minetest.facedir_to_dir(node.param2 or 0)
        local partner_pos = vector.add(bed_pos, dir)
        local partner_node = minetest.get_node(partner_pos)
        if minetest.get_item_group(partner_node.name, "bed") > 0 then
            local pmeta = minetest.get_meta(partner_pos)
            if pmeta:get_string("assigned_settler") ~= "" or pmeta:get_string("owner") ~= "" or pmeta:get_string("player_reserved") == "true" then
                partner_occupied = true
            end
        end

        if not reserved and owner == "" and assigned == "" and not partner_occupied then
            return bed_pos
        end
    end
    return nil
end

-- Hook player sleeping and bed destruction across registered bed nodes
minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "bed") > 0 then
            local orig_on_rightclick = def.on_rightclick
            local orig_can_dig = def.can_dig
            minetest.override_item(name, {
                can_dig = function(pos, player)
                    local meta = minetest.get_meta(pos)
                    local assigned = meta:get_string("assigned_settler")
                    if assigned ~= "" and player and player:is_player() then
                        if player:get_player_control().sneak then
                            -- Unassign settler home_pos from active entity memory
                            for _, obj in pairs(minetest.luaentities) do
                                if obj.name and obj.name:find("^eg_settlers:") then
                                    if obj.assigned_name == assigned or (obj.home_pos and vector.equals(obj.home_pos, pos)) then
                                        obj.home_pos = nil
                                    end
                                end
                            end
                            return true
                        end
                        minetest.chat_send_player(player:get_player_name(),
                            minetest.get_translator("eg_settlers")("[eg_settlers] Bed is assigned to ") .. assigned .. ". Relocate settler or hold Sneak to mine.")
                        return false
                    end
                    if orig_can_dig then
                        return orig_can_dig(pos, player)
                    end
                    return true
                end,

                on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
                    if clicker and clicker:is_player() then
                        local meta = minetest.get_meta(pos)
                        meta:set_string("owner", clicker:get_player_name())
                        meta:set_string("player_reserved", "true")
                        local assigned = meta:get_string("assigned_settler")
                        if assigned and assigned ~= "" then
                            meta:set_string("assigned_settler", "")
                        end
                        eg_settlers.update_bed_infotext(pos)
                    end
                    if orig_on_rightclick then
                        return orig_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
                    end
                end
            })
        end
    end
end)


--------------------------------------------------
-- Environmental Validation Checks
--------------------------------------------------
function eg_settlers.validate_job_block_environment(pos, profession)
    if profession == "farmer" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 5), vector.add(pos, 5),
            {"group:soil", "group:food", "farming:soil_wet", "farming:wheat_8"}
        )
        if count < 4 then
            return false, S("Farmer requires at least 4 soil or crop nodes within 5 blocks.")
        end
    elseif profession == "smith" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 3), vector.add(pos, 3),
            {"default:furnace", "default:furnace_active", "group:anvil"}
        )
        if count < 1 then
            return false, S("Blacksmith requires a furnace or anvil within 3 blocks.")
        end
    elseif profession == "carpenter" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 4), vector.add(pos, 4),
            {"group:wood", "group:tree"}
        )
        if count < 4 then
            return false, S("Carpenter requires at least 4 wood or tree blocks within 4 blocks.")
        end
    elseif profession == "librarian" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 4), vector.add(pos, 4),
            {"default:bookshelf"}
        )
        if count < 4 then
            return false, S("Librarian requires at least 4 bookshelves within 4 blocks.")
        end
    elseif profession == "miner" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 5), vector.add(pos, 5),
            {"group:stone"}
        )
        if count < 4 then
            return false, S("Miner requires at least 4 stone blocks within 5 blocks.")
        end
    elseif profession == "merchant" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 4), vector.add(pos, 4),
            {"group:chest"}
        )
        if count < 1 then
            return false, S("Merchant requires at least 1 chest within 4 blocks.")
        end
    elseif profession == "rancher" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 5), vector.add(pos, 5),
            {"group:fence", "farming:straw"}
        )
        if count < 3 then
            return false, S("Rancher requires fences or straw blocks within 5 blocks.")
        end
    elseif profession == "fisher" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 5), vector.add(pos, 5),
            {"group:water"}
        )
        if count < 4 then
            return false, S("Fisher requires water nodes within 5 blocks.")
        end
    elseif profession == "lumberjack" then
        local count = #minetest.find_nodes_in_area(
            vector.subtract(pos, 8), vector.add(pos, 8),
            {"group:tree"}
        )
        if count < 3 then
            return false, S("Lumberjack requires tree trunks within 8 blocks.")
        end
    end
    return true, nil
end

