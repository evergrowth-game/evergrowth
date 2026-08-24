--[[
    Evergrowth Companions - Items & Contracts
    =========================================
    Registers companion recruitment contracts, relocation contracts, and the Wardrobe Wand.
]]--

local S = minetest.get_translator("eg_companions")

local function get_safe_spawn_pos(pointed_thing)
    if not pointed_thing or pointed_thing.type ~= "node" then return nil end
    local under = pointed_thing.under
    local above = pointed_thing.above
    if above.y > under.y then
        return {x = above.x, y = under.y + 2, z = above.z}
    elseif above.y < under.y then
        return {x = above.x, y = above.y, z = above.z}
    else
        return {x = above.x, y = above.y + 1, z = above.z}
    end
end

local function handle_contract_place(itemstack, placer, pointed_thing, is_female, is_relocation)
    if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end
    if not placer or not placer:is_player() then return itemstack end

    local under_pos = pointed_thing.under
    local under_node = minetest.get_node(under_pos)
    local pname = placer:get_player_name()

    -- Target must be a Companion Plaque
    if under_node.name ~= "eg_companions:companion_plaque" and under_node.name ~= "eg_settlers:housing_deed" then
        minetest.chat_send_player(pname, S("[eg_companions] Companion Contracts must be placed directly on a Companion Plaque."))
        return itemstack
    end

    local plaque_meta = minetest.get_meta(under_pos)
    if plaque_meta:get_int("occupied") == 1 then
        minetest.chat_send_player(pname, S("[eg_companions] This plaque is already occupied by @1.", plaque_meta:get_string("resident_name")))
        return itemstack
    end

    -- 1. Scan for nearby player-owned bed within 50 blocks
    local bed_pos = eg_companions.find_player_bed(under_pos, 50, pname)
    if not bed_pos then
        minetest.chat_send_player(pname, S("[eg_companions] No player-owned bed found within 50 blocks. Place and claim a bed first (right-click your bed to claim it)."))
        return itemstack
    end

    -- 2. Spawn Companion in front of Plaque
    local spawn_pos = get_safe_spawn_pos(pointed_thing) or pointed_thing.above

    local override_data = nil
    if is_relocation then
        local meta = itemstack:get_meta()
        override_data = {
            nametag = meta:get_string("companion_nametag"),
            skin_index = meta:get_int("companion_skin_index"),
            health = meta:get_int("companion_health"),
        }
        is_female = (meta:get_int("companion_is_female") == 1)
    end

    local npc_name = eg_companions.spawn_companion(spawn_pos, is_female, pname, under_pos, bed_pos, override_data)
    if not npc_name then
        minetest.chat_send_player(pname, S("[eg_companions] Failed to spawn companion at target position."))
        return itemstack
    end

    -- 3. Update Companion Plaque metadata
    plaque_meta:set_int("occupied", 1)
    plaque_meta:set_string("resident_name", npc_name)
    plaque_meta:set_string("bed_pos", minetest.pos_to_string(bed_pos))
    plaque_meta:set_string("owner", pname)
    plaque_meta:set_string("infotext", S("Companion Plaque") .. "\n" .. S("Resident: ") .. npc_name .. "\n" .. S("Owner: ") .. pname)

    -- 4. Tag Bed metadata
    local bmeta = minetest.get_meta(bed_pos)
    bmeta:set_string("assigned_companion", npc_name)

    minetest.sound_play("default_place_node_hard", {pos = spawn_pos, gain = 1.0}, true)

    if not minetest.settings:get_bool("creative_mode") then
        itemstack:take_item()
    end
    return itemstack
end

-- 1. Male Companion Contract
minetest.register_craftitem("eg_companions:contract_male", {
    description = S("Male Companion's Contract") .. "\n" ..
                  S("Place on a Companion Plaque to assign a companion.") .. "\n" ..
                  S("Requires a claimed player bed within 50 blocks."),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        return handle_contract_place(itemstack, placer, pointed_thing, false, false)
    end,
})

minetest.register_craft({
    output = "eg_companions:contract_male",
    recipe = {
        {"default:paper", "default:stick"},
    }
})

-- 2. Female Companion Contract
minetest.register_craftitem("eg_companions:contract_female", {
    description = S("Female Companion's Contract") .. "\n" ..
                  S("Place on a Companion Plaque to assign a companion.") .. "\n" ..
                  S("Requires a claimed player bed within 50 blocks."),
    inventory_image = "default_paper.png^(default_apple.png^[resize:16x16)",
    on_place = function(itemstack, placer, pointed_thing)
        return handle_contract_place(itemstack, placer, pointed_thing, true, false)
    end,
})

minetest.register_craft({
    output = "eg_companions:contract_female",
    recipe = {
        {"default:paper", "default:apple"},
    }
})

-- 3. Companion Relocation Contract
minetest.register_craftitem("eg_companions:contract_relocation", {
    description = S("Companion Relocation Contract") .. "\n" ..
                  S("Place on a vacant Companion Plaque to reassign the companion."),
    inventory_image = "default_paper.png^(default_stick.png^[resize:16x16)",
    groups = {not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)
        return handle_contract_place(itemstack, placer, pointed_thing, false, true)
    end,
})

-- 4. Wardrobe Wand
minetest.register_craftitem("eg_companions:wardrobe_wand", {
    description = S("Wardrobe Wand (Punch Companion to Change Clothes)"),
    inventory_image = "default_stick.png^[colorize:#FF00FF:128",
})

minetest.register_craft({
    output = "eg_companions:wardrobe_wand",
    recipe = {
        {"", "", "dye:magenta"},
        {"", "default:stick", ""},
        {"default:stick", "", ""},
    }
})
