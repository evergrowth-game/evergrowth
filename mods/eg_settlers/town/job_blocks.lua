--[[
    Evergrowth Settlers - Job Block Workstations
    ===========================================
    Registers profession-specific Job Block workstations for all 18 villager
    professions. Job Blocks occupy physical space in workshops and serve as
    the sole tethering targets for Hiring Contracts.
]]--

local S = minetest.get_translator("eg_settlers")

eg_settlers.registered_job_blocks = {}

function eg_settlers.register_job_block(prof_id, def)
    local node_name = "eg_settlers:job_block_" .. prof_id
    
    local node_groups = def.groups or {choppy = 2, dig_immediate = 2}
    node_groups.job_block = 1
    
    minetest.register_node(node_name, {
        description = S(def.description) .. "\n" .. S("Workstation Node - Place a Hiring Contract on this block."),
        drawtype = "mesh",
        mesh = def.mesh or ("eg_settlers_job_" .. prof_id .. ".obj"),
        tiles = def.tiles,
        paramtype = "light",
        paramtype2 = def.paramtype2 or "facedir",
        sunlight_propagates = true,
        light_source = def.light_source or 0,
        selection_box = def.selection_box or { type = "fixed", fixed = {-0.45, -0.5, -0.45, 0.45, 0.45, 0.45} },
        collision_box = def.collision_box or { type = "fixed", fixed = {-0.45, -0.5, -0.45, 0.45, 0.45, 0.45} },
        groups = node_groups,

        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            meta:set_int("occupied", 0)
            meta:set_string("resident_name", "")
            meta:set_string("profession", prof_id)
            meta:set_string("infotext", S(def.description) .. " (" .. S("Vacant") .. ")")
        end,

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            if placer and placer:is_player() then
                local meta = minetest.get_meta(pos)
                meta:set_string("owner", placer:get_player_name())
                local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                if sid then
                    meta:set_string("settlement_id", sid)
                else
                    minetest.chat_send_player(placer:get_player_name(),
                        S("[eg_settlers] No Town Ledger found nearby. Assigned residents will not be linked to a settlement."))
                end
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
                minetest.chat_send_player(name, S("Only authorized players can remove this Workstation."))
                return false
            end

            if meta:get_int("occupied") == 1 then
                if player:get_player_control().sneak then
                    return true
                end
                minetest.chat_send_player(name, S("Relocate the resident first, or hold Sneak while mining to forcefully break this workstation."))
                return false
            end
            return true
        end,

        on_blast = function(pos, intensity)
            return nil
        end,

        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            if not clicker or not clicker:is_player() then return itemstack end
            local meta = minetest.get_meta(pos)

            if not itemstack:is_empty() then
                local item_name = itemstack:get_name()
                if item_name == "eg_settlers:hiring_contract" or string.match(item_name, "^eg_settlers:contract_") then
                    local idef = itemstack:get_definition()
                    if idef and idef.on_place then
                        return idef.on_place(itemstack, clicker, pointed_thing)
                    end
                end
                return itemstack
            end

            if meta:get_int("occupied") == 1 then
                minetest.chat_send_player(clicker:get_player_name(),
                    S("[eg_settlers] Resident: ") .. meta:get_string("resident_name") .. " (" .. prof_id .. ")")
            else
                minetest.chat_send_player(clicker:get_player_name(),
                    S("[eg_settlers] Workstation is vacant. Use a Hiring Contract on it."))
            end
            return itemstack
        end,
    })

    eg_settlers.registered_job_blocks[prof_id] = {
        name = node_name,
        description = def.description,
        cost = def.cost or 5,
    }
end

-- Register 18 Job Blocks with 3D OBJ Mesh Models & Multi-Material Textures
eg_settlers.register_job_block("farmer", {
    description = "Farmer's Seed Silo",
    cost = 5,
    tiles = {"default_wood.png", "default_dry_grass.png"},
})

eg_settlers.register_job_block("smith", {
    description = "Blacksmith's Quenching Trough",
    cost = 10,
    tiles = {"default_stone_brick.png", "default_water.png"},
})

eg_settlers.register_job_block("carpenter", {
    description = "Carpenter's Drafting Table",
    cost = 8,
    tiles = {"default_wood.png", "default_paper.png"},
})

eg_settlers.register_job_block("librarian", {
    description = "Librarian's Archive Cabinet",
    cost = 8,
    tiles = {"default_wood.png", "default_bookshelf.png"},
})

eg_settlers.register_job_block("mage", {
    description = "Mage's Ward Pedestal",
    cost = 15,
    tiles = {"default_obsidian.png", "default_mese_block.png"},
    light_source = 8,
})

eg_settlers.register_job_block("brewer", {
    description = "Brewer's Fermentation Cask",
    cost = 8,
    tiles = {"default_wood.png", "default_steel_block.png"},
})

eg_settlers.register_job_block("miner", {
    description = "Miner's Ore Cart",
    cost = 8,
    tiles = {"default_steel_block.png", "default_coal_block.png"},
})

eg_settlers.register_job_block("merchant", {
    description = "Merchant's Counter",
    cost = 10,
    tiles = {"default_wood.png", "default_gold_block.png"},
})

eg_settlers.register_job_block("guard", {
    description = "Guard's Watchtower Beacon",
    cost = 8,
    tiles = {"default_cobble.png", "default_copper_block.png"},
    light_source = 10,
})

eg_settlers.register_job_block("rancher", {
    description = "Rancher's Feed Trough",
    cost = 5,
    tiles = {"default_wood.png", "farming_straw.png"},
})

eg_settlers.register_job_block("fisher", {
    description = "Fisher's Fish Barrel",
    cost = 5,
    tiles = {"default_wood.png", "default_steel_block.png"},
})

eg_settlers.register_job_block("lumberjack", {
    description = "Lumberjack's Chopping Stump",
    cost = 5,
    tiles = {"default_tree.png", "default_tree_top.png"},
})

eg_settlers.register_job_block("technologist", {
    description = "Technologist's Server Rack",
    cost = 15,
    tiles = {"default_steel_block.png", "default_copper_block.png"},
    light_source = 4,
})

eg_settlers.register_job_block("gunsmith", {
    description = "Gunsmith's Ordnance Locker",
    cost = 15,
    tiles = {"default_steel_block.png^[multiply:#354B35", "default_chest_front.png^[multiply:#354B35"},
})

eg_settlers.register_job_block("automobile_mechanic", {
    description = "Automobile Mechanic's Tool Chest",
    cost = 15,
    tiles = {"default_chest_front.png^[multiply:#B22222", "default_steel_block.png"},
})

eg_settlers.register_job_block("aircraft_mechanic", {
    description = "Aircraft Mechanic's Canister Rack",
    cost = 15,
    tiles = {"default_steel_block.png^[multiply:#DAA520", "default_copper_block.png"},
})

eg_settlers.register_job_block("nautical_mechanic", {
    description = "Nautical Mechanic's Chain Post",
    cost = 15,
    tiles = {"default_steel_block.png^[multiply:#4682B4", "default_stone.png"},
})

eg_settlers.register_job_block("roboticist", {
    description = "Roboticist's Charging Alcove",
    cost = 20,
    tiles = {"default_steel_block.png", "default_copper_block.png"},
    light_source = 6,
})
