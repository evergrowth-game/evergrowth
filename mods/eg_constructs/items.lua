--[[
    Evergrowth Constructs - Items & Deployment Cores
    ===============================================
    Registers portable Golem Core and Automaton Core items.
    Allows deploying companions into the world and restoring their stored inventories.
]]--

local S = minetest.get_translator("eg_constructs")

-- Generic helper to deploy a construct from a core itemstack
local function deploy_construct(itemstack, placer, pointed_thing, entity_name, construct_name)
    if not placer or not placer:is_player() then return itemstack end
    if not pointed_thing or pointed_thing.type ~= "node" then return itemstack end

    local pname = placer:get_player_name()
    local spawn_pos = pointed_thing.above
    if minetest.is_protected(spawn_pos, pname) then
        minetest.record_protection_violation(spawn_pos, pname)
        return itemstack
    end

    -- Spawn position adjusted above node
    local pos = {x = spawn_pos.x, y = spawn_pos.y + 0.5, z = spawn_pos.z}
    local obj = minetest.add_entity(pos, entity_name)
    if not obj then return itemstack end

    local ent = obj:get_luaentity()
    if ent then
        ent.owner = pname
        ent.order = "follow"
        ent.following = placer
        ent.construct_id = math.random(100000, 999999)

        -- Restore stored inventory if present in item metadata
        local meta = itemstack:get_meta()
        local stored_str = meta:get_string("stored_inventory")
        if stored_str and stored_str ~= "" then
            local items = minetest.deserialize(stored_str)
            if items then
                ent.stored_inventory = items
                local inv_name = "eg_construct_" .. tostring(ent.construct_id)
                eg_constructs.get_detached_inv(inv_name, pname, items)
            end
        end
    end

    -- Sound and activation particles
    minetest.sound_play("default_place_node_metal", {pos = pos, gain = 1.0}, true)
    minetest.add_particlespawner({
        amount = 15,
        time = 0.5,
        minpos = vector.add(pos, {x = -0.4, y = 0, z = -0.4}),
        maxpos = vector.add(pos, {x = 0.4, y = 1.2, z = 0.4}),
        minvel = {x = -0.5, y = 0.5, z = -0.5},
        maxvel = {x = 0.5, y = 1.5, z = 0.5},
        minexptime = 0.4,
        maxexptime = 0.8,
        minsize = 1,
        maxsize = 2,
        texture = "default_mese_crystal_fragment.png",
        glow = 8,
    })

    minetest.chat_send_player(pname, S("[eg_constructs] @1 deployed. Right-click for pack inventory, Sneak+Punch to toggle follow.", construct_name))

    local meta = itemstack:get_meta()
    local has_stored_items = meta:get_string("stored_inventory") ~= ""
    if has_stored_items or not minetest.is_creative_enabled(pname) then
        itemstack:take_item(1)
    end
    return itemstack
end

-- 1. GOLEM CORE
minetest.register_craftitem("eg_constructs:golem_core", {
    description = S("Golem Core") .. "\n" .. S("Activation focus for the Clay Golem. Right-click the ground to deploy."),
    _doc_items_longdesc = S("A mystical clay and gold matrix infused with arcane energy to animate and command a Clay Golem companion."),
    _doc_items_usagehelp = S("Right-click the ground to deploy the Clay Golem. Sneak+Right-Click an owned golem with an empty hand to recall it back into this core. Stored inventory is preserved inside the core."),
    inventory_image = "eg_constructs_golem_core.png",
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        return deploy_construct(itemstack, placer, pointed_thing, "eg_constructs:golem_clay", S("Clay Golem"))
    end,
})

-- 2. COMBAT DRONE CORE
minetest.register_craftitem("eg_constructs:combat_drone_core", {
    description = S("Combat Drone Core") .. "\n" .. S("Power and logic core for the Combat Drone. Right-click the ground to deploy."),
    _doc_items_longdesc = S("A precision logic module and propulsion core used to manufacture and deploy an autonomous Combat Drone."),
    _doc_items_usagehelp = S("Right-click the ground to deploy the Combat Drone. Sneak+Right-Click an owned drone with an empty hand to recall it back into this core. Stored inventory is preserved inside the core."),
    inventory_image = "eg_constructs_combat_drone_core.png",
    stack_max = 1,
    on_place = function(itemstack, placer, pointed_thing)
        return deploy_construct(itemstack, placer, pointed_thing, "eg_constructs:combat_drone", S("Combat Drone"))
    end,
})

-- 3. CRAFTING RECIPES

-- Golem Core Recipe
minetest.register_craft({
    output = "eg_constructs:golem_core",
    recipe = {
        {"default:clay",       "default:gold_ingot", "default:clay"},
        {"default:gold_ingot", "default:mese_crystal", "dye:red"},
        {"default:clay",       "default:clay",       "default:clay"},
    }
})

-- Combat Drone Core Recipe
minetest.register_craft({
    output = "eg_constructs:combat_drone_core",
    recipe = {
        {"default:steel_ingot",  "default:copper_ingot", "default:steel_ingot"},
        {"default:copper_ingot", "default:mese_crystal", "default:diamond"},
        {"default:steel_ingot",  "default:steel_ingot",  "default:steel_ingot"},
    }
})

-- Aliases for backward compatibility
minetest.register_alias("eg_constructs:automaton_core", "eg_constructs:combat_drone_core")
minetest.register_alias("eg_settlers:golem_core", "eg_constructs:golem_core")
minetest.register_alias("eg_settlers:automaton_core", "eg_constructs:combat_drone_core")
minetest.register_alias("eg_settlers:golem_clay", "eg_constructs:golem_clay")
minetest.register_alias("eg_settlers:automaton", "eg_constructs:combat_drone")

