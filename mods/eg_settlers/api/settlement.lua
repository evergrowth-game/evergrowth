--[[
    Evergrowth Villages - Settlement System
    =======================================
    Manages Bed Management, Unassigned Bed Scanners, Population Counting,
    and Infrastructure Validation for town settlers.
]]--

local S = minetest.get_translator("eg_settlers")

--------------------------------------------------
-- Bed Management & Unassigned Scanner
--------------------------------------------------
function eg_settlers.get_partner_bed_pos(pos)
    local node = minetest.get_node(pos)
    local group = minetest.get_item_group(node.name, "bed")
    if group == 0 then return nil end
    
    local dir = minetest.facedir_to_dir(node.param2 or 0)
    if not dir then return nil end
    
    local partner_pos
    if group == 2 then
        -- Top bed node half: partner bottom node is subtract dir
        partner_pos = vector.subtract(pos, dir)
    else
        -- Bottom bed node half: partner top node is add dir
        partner_pos = vector.add(pos, dir)
    end
    
    local pnode = minetest.get_node(partner_pos)
    if minetest.get_item_group(pnode.name, "bed") > 0 then
        return partner_pos
    end
    return nil
end

function eg_settlers.update_bed_infotext(pos)
    if not pos then return end
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    local reserved = meta:get_string("player_reserved") == "true"
    local assigned = meta:get_string("assigned_settler")

    local ppos = eg_settlers.get_partner_bed_pos(pos)
    if ppos then
        local pmeta = minetest.get_meta(ppos)
        local powner = pmeta:get_string("owner")
        local preserved = pmeta:get_string("player_reserved") == "true"
        local passigned = pmeta:get_string("assigned_settler")

        if assigned == "" and passigned ~= "" then
            assigned = passigned
            meta:set_string("assigned_settler", assigned)
        elseif passigned == "" and assigned ~= "" then
            pmeta:set_string("assigned_settler", assigned)
        end

        if owner == "" and powner ~= "" then
            owner = powner
            meta:set_string("owner", owner)
        elseif powner == "" and owner ~= "" then
            pmeta:set_string("owner", owner)
        end

        if not reserved and preserved then
            reserved = true
            meta:set_string("player_reserved", "true")
        elseif not preserved and reserved then
            pmeta:set_string("player_reserved", "true")
        end
    end

    local infotext
    if reserved or (owner ~= "" and assigned == "") then
        infotext = S("Player Bed (Owner: ") .. (owner ~= "" and owner or "Player") .. ")"
    elseif assigned ~= "" then
        infotext = S("Settler Bed (Assigned: ") .. assigned .. ")"
    else
        infotext = S("Settler Bed (Unassigned)")
    end

    meta:set_string("infotext", infotext)
    if ppos then
        local pmeta = minetest.get_meta(ppos)
        pmeta:set_string("infotext", infotext)
    end
end

function eg_settlers.assign_bed(pos, settler_name)
    if not pos then return end
    settler_name = settler_name or ""
    local meta = minetest.get_meta(pos)
    meta:set_string("assigned_settler", settler_name)
    local ppos = eg_settlers.get_partner_bed_pos(pos)
    if ppos then
        local pmeta = minetest.get_meta(ppos)
        pmeta:set_string("assigned_settler", settler_name)
    end
    eg_settlers.update_bed_infotext(pos)
end

function eg_settlers.clear_bed_assignment(pos)
    if not pos then return end
    local meta = minetest.get_meta(pos)
    meta:set_string("assigned_settler", "")
    local ppos = eg_settlers.get_partner_bed_pos(pos)
    if ppos then
        local pmeta = minetest.get_meta(ppos)
        pmeta:set_string("assigned_settler", "")
    end
    eg_settlers.update_bed_infotext(pos)
end

function eg_settlers.get_total_beds_count(pos, radius)
    radius = radius or 200
    local p1 = vector.subtract(pos, radius)
    local p2 = vector.add(pos, radius)
    local beds = minetest.find_nodes_in_area(p1, p2, {"group:bed_bottom"})
    if #beds == 0 then
        beds = minetest.find_nodes_in_area(p1, p2, {"group:bed"})
        return math.floor(#beds / 2)
    end
    return #beds
end

function eg_settlers.get_total_settlers_count(pos, radius)
    radius = radius or 200
    local count = 0
    local tracked = {}

    -- 1. Count living active entities and track all associated identifiers
    for _, obj in pairs(minetest.luaentities) do
        if obj and (obj.evergrowth_nametag_mode or obj.is_villager) then
            local epos = obj.object and obj.object:get_pos()
            if epos and vector.distance(epos, pos) <= radius then
                count = count + 1
                if obj.nametag then tracked[obj.nametag] = true end
                if obj.game_name then tracked[obj.game_name] = true end
                if obj.job_pos then tracked[minetest.pos_to_string(obj.job_pos)] = true end
                if obj.home_pos then tracked[minetest.pos_to_string(obj.home_pos)] = true end
            end
        end
    end

    -- 2. Check occupied workstation nodes for unloaded settlers vs stale metadata
    local p1 = vector.subtract(pos, radius)
    local p2 = vector.add(pos, radius)
    for name, def in pairs(minetest.registered_nodes) do
        if name:find("^eg_settlers:job_block_") then
            local nodes = minetest.find_nodes_in_area(p1, p2, {name})
            for _, npos in ipairs(nodes) do
                local meta = minetest.get_meta(npos)
                if meta:get_int("occupied") == 1 then
                    local rname = meta:get_string("resident_name")
                    local npos_str = minetest.pos_to_string(npos)
                    local home_str = meta:get_string("home_pos")
                    
                    if not (tracked[rname] or tracked[npos_str] or (home_str ~= "" and tracked[home_str])) then
                        -- Check if assigned bed exists in world to verify if settler is in unloaded chunk
                        local home_pos = minetest.string_to_pos(home_str)
                        local bed_exists = false
                        if home_pos then
                            local hnode = minetest.get_node(home_pos)
                            if minetest.get_item_group(hnode.name, "bed") > 0 then
                                bed_exists = true
                            end
                        end

                        if bed_exists then
                            count = count + 1
                            tracked[npos_str] = true
                        else
                            -- Auto-clean stale workstation metadata from killed/cleared entities
                            meta:set_int("occupied", 0)
                            meta:set_string("resident_name", "")
                            meta:set_string("home_pos", "")
                            if def and def.description then
                                local desc = def.description:match("([^\n]+)")
                                meta:set_string("infotext", desc .. " (" .. minetest.get_translator("eg_settlers")("Vacant") .. ")")
                            end
                        end
                    end
                end
            end
        end
    end
    return count
end

function eg_settlers.find_unassigned_bed(pos, radius)
    radius = radius or 30
    local p1 = vector.subtract(pos, radius)
    local p2 = vector.add(pos, radius)
    
    local beds = minetest.find_nodes_in_area(p1, p2, {"group:bed_bottom"})
    if #beds == 0 then
        beds = minetest.find_nodes_in_area(p1, p2, {"group:bed"})
    end

    -- Collect all home_pos currently assigned to living settlers in memory
    local assigned_home_positions = {}
    for _, obj in pairs(minetest.luaentities) do
        if obj and (obj.evergrowth_nametag_mode or obj.is_villager) and obj.home_pos then
            assigned_home_positions[minetest.pos_to_string(obj.home_pos)] = true
        end
    end

    local valid_beds = {}
    for _, bed_pos in ipairs(beds) do
        local meta = minetest.get_meta(bed_pos)
        local owner = meta:get_string("owner")
        local reserved = meta:get_string("player_reserved") == "true"
        local assigned = meta:get_string("assigned_settler")
        
        local partner_occupied = false
        local partner_pos = eg_settlers.get_partner_bed_pos(bed_pos)
        if partner_pos then
            local pmeta = minetest.get_meta(partner_pos)
            if pmeta:get_string("assigned_settler") ~= "" or pmeta:get_string("owner") ~= "" or pmeta:get_string("player_reserved") == "true" then
                partner_occupied = true
            end
        end

        local pos_str = minetest.pos_to_string(bed_pos)
        local partner_str = partner_pos and minetest.pos_to_string(partner_pos)
        local entity_assigned = assigned_home_positions[pos_str] or (partner_str and assigned_home_positions[partner_str])

        if not reserved and owner == "" and assigned == "" and not partner_occupied and not entity_assigned then
            local dist = vector.distance(pos, bed_pos)
            table.insert(valid_beds, {pos = bed_pos, dist = dist})
        end
    end
    
    if #valid_beds > 0 then
        table.sort(valid_beds, function(a, b) return a.dist < b.dist end)
        return valid_beds[1].pos
    end
    return nil
end

-- LBM to automatically initialize unassigned bed infotext on world/chunk load
minetest.register_lbm({
    name = "eg_settlers:init_bed_infotext",
    nodenames = {"group:bed"},
    run_at_every_load = true,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        if meta:get_string("infotext") == "" then
            eg_settlers.update_bed_infotext(pos)
        end
    end,
})

-- Hook player placement, sleeping, and bed destruction across registered bed nodes
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if minetest.get_item_group(newnode.name, "bed") > 0 then
        eg_settlers.update_bed_infotext(pos)
    end
end)

minetest.register_on_mods_loaded(function()
    for name, def in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "bed") > 0 then
            local orig_on_rightclick = def.on_rightclick
            local orig_on_destruct = def.on_destruct
            local orig_on_place = def.on_place
            minetest.override_item(name, {
                on_place = function(itemstack, placer, pointed_thing)
                    local res = orig_on_place and orig_on_place(itemstack, placer, pointed_thing) or itemstack
                    if pointed_thing then
                        if pointed_thing.above then eg_settlers.update_bed_infotext(pointed_thing.above) end
                        if pointed_thing.under then eg_settlers.update_bed_infotext(pointed_thing.under) end
                    end
                    return res
                end,
                on_destruct = function(pos)
                    -- Clear home_pos from any living settler entity assigned to this bed coordinate
                    for _, obj in pairs(minetest.luaentities) do
                        if obj and (obj.evergrowth_nametag_mode or obj.is_villager) and obj.home_pos then
                            if vector.equals(obj.home_pos, pos) or vector.distance(obj.home_pos, pos) <= 1.5 then
                                obj.home_pos = nil
                            end
                        end
                    end
                    if orig_on_destruct then
                        orig_on_destruct(pos)
                    end
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

                        local ppos = eg_settlers.get_partner_bed_pos(pos)
                        if ppos then
                            local pmeta = minetest.get_meta(ppos)
                            pmeta:set_string("owner", clicker:get_player_name())
                            pmeta:set_string("player_reserved", "true")
                            local passigned = pmeta:get_string("assigned_settler")
                            if passigned and passigned ~= "" then
                                pmeta:set_string("assigned_settler", "")
                            end
                            eg_settlers.update_bed_infotext(ppos)
                        end
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
            {"default:furnace", "default:furnace_active", "group:anvil", "anvil:anvil"}
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
            {
                "group:chest",
                "default:chest",
                "default:chest_locked",
                "default:chest_open",
                "default:chest_locked_open",
                "xdecor:mailbox",
                "xdecor:cabinet",
                "xdecor:barrel",
                "protector:chest"
            }
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

