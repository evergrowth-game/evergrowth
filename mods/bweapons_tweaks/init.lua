-- Bweapons Tweaks for Evergrowth
-- This mod preserves custom recipes and durability logic while allowing the use of the official bweapons modpack.

local players = {}

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    players[name] = {reloading=false}
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    players[name] = nil
end)

local function reset_player_cooldown(user)
    if user ~= nil then
        local name = user:get_player_name()
        if players[name] then
            players[name] = {reloading=false}
        end
    end
end

-- Custom recipes table
local custom_recipes = {
    -- Firearms
    ["bweapons_firearms_pack:pistol"] = {
        {{'', 'default:steel_ingot', ''}, {'', 'basic_materials:plastic_sheet', 'default:steel_ingot'}, {'', '', 'group:wood'}}
    },
    ["bweapons_firearms_pack:shotgun"] = {
        {{'default:steel_ingot', 'default:steel_ingot', ''}, {'group:wood', 'basic_materials:plastic_sheet', 'default:steel_ingot'}, {'', 'group:wood', 'group:wood'}}
    },
    ["bweapons_firearms_pack:double_barrel"] = {
        {{'default:steel_ingot', 'default:steel_ingot', 'group:wood'}, {'default:steel_ingot', 'default:steel_ingot', 'techage:steelmat'}, {'', 'group:wood', 'group:wood'}}
    },
    ["bweapons_firearms_pack:rifle"] = {
        {{'default:steel_ingot', 'default:steel_ingot', ''}, {'techage:steelmat', 'group:wood', 'default:steel_ingot'}, {'', 'group:wood', 'group:wood'}}
    },
    ["bweapons_firearms_pack:grenade_launcher"] = {
        {{'default:steel_ingot', 'default:steel_ingot', 'techage:steelmat'}, {'default:steel_ingot', 'default:steel_ingot', 'techage:steelmat'}, {'default:coal_lump', 'group:wood', 'group:wood'}}
    },
    -- Hi-Tech
    ["bweapons_hitech_pack:missile_launcher"] = {
        {{'techage:aluminum', 'techage:aluminum', 'techage:ta4_carbon_fiber'}, {'techage:aluminum', 'techage:aluminum', 'techage:ta4_carbon_fiber'}, {'', '', 'techage:ta4_carbon_fiber'}}
    },
    ["bweapons_hitech_pack:particle_gun"] = {
        {{'default:diamond', 'techage:ta4_silicon_wafer', 'basic_materials:energy_crystal_simple'}, {'basic_materials:motor', 'basic_materials:motor', 'techage:aluminum'}, {'', '', 'techage:aluminum'}}
    },
    ["bweapons_hitech_pack:laser_gun"] = {
        {{'default:diamond', 'techage:ta4_carbon_fiber', 'basic_materials:energy_crystal_simple'}, {'basic_materials:motor', 'basic_materials:copper_wire', 'techage:aluminum'}, {'', '', 'techage:aluminum'}}
    },
    ["bweapons_hitech_pack:plasma_gun"] = {
        {{'default:diamondblock', 'default:obsidian_glass', 'techage:ta4_battery'}, {'techage:ta4_transformer', 'techage:ta4_transformer', 'techage:ta4_carbon_fiber'}, {'', '', 'techage:aluminum'}}
    },
    ["bweapons_hitech_pack:rail_gun"] = {
        {{'basic_materials:copper_wire', 'basic_materials:copper_wire', 'techage:ta4_carbon_fiber'}, {'techage:ta4_transformer', 'techage:ta4_transformer', 'techage:ta4_battery'}, {'basic_materials:copper_wire', 'basic_materials:copper_wire', 'techage:ta4_carbon_fiber'}}
    },
    -- Ammo
    ["bweapons_firearms_pack:pistol_round"] = {
        {{'', 'default:copper_ingot', ''}, {'', 'tnt:gunpowder', ''}, {'', 'basic_materials:brass_ingot', ''}}
    },
    ["bweapons_firearms_pack:rifle_round"] = {
        {{'', 'default:copper_ingot', ''}, {'default:steel_ingot', 'tnt:gunpowder', 'default:steel_ingot'}, {'', 'basic_materials:brass_ingot', ''}}
    },
    ["bweapons_firearms_pack:shotgun_shell"] = {
        {{'', 'default:copper_lump', ''}, {'basic_materials:plastic_sheet', 'tnt:gunpowder', 'basic_materials:plastic_sheet'}, {'', 'basic_materials:brass_ingot', ''}}
    },
    ["bweapons_firearms_pack:grenade"] = {
        {{'default:coal_lump', 'default:steel_ingot', 'default:coal_lump'}, {'tnt:gunpowder', 'tnt:gunpowder', 'tnt:gunpowder'}, {'basic_materials:brass_ingot', 'basic_materials:brass_ingot', 'basic_materials:brass_ingot'}}
    },
    ["bweapons_hitech_pack:rail_slug"] = {
        {{'', 'techage:baborium_ingot', ''}, {'', 'techage:baborium_ingot', ''}, {'', 'default:steel_ingot', ''}}
    },
    ["bweapons_hitech_pack:missile"] = {
        {{'techage:ta4_carbon_fiber', 'techage:ta4_silicon_wafer', 'techage:ta4_carbon_fiber'}, {'tnt:gunpowder', 'tnt:gunpowder', 'tnt:gunpowder'}, {'techage:aluminum', 'techage:graphite_powder', 'techage:aluminum'}}
    },
}

local energy_weapons = {
    ["bweapons_hitech_pack:laser_gun"] = true,
    ["bweapons_hitech_pack:particle_gun"] = true,
    ["bweapons_hitech_pack:plasma_gun"] = true,
    ["bweapons_hitech_pack:rail_gun"] = true,
}

local function reload_with_battery(itemstack, user, def)
    if not user or not user:is_player() then return itemstack end
    if itemstack:get_wear() == 0 then
        return itemstack -- already fully charged
    end
    local inv = user:get_inventory()
    if not inv then return itemstack end

    if inv:contains_item("main", "techage:ta4_battery") then
        inv:remove_item("main", "techage:ta4_battery 1")
        local leftover = inv:add_item("main", "techage:ta4_battery_empty 1")
        if leftover and not leftover:is_empty() then
            minetest.add_item(user:get_pos(), leftover)
        end
        itemstack:set_wear(0)
        local sound = def.reload_sound or "bweapons_hitech_pack_laser_gun_reload"
        minetest.sound_play(sound, {
            object = user,
            gain = def.reload_sound_gain or 0.5,
            max_hear_distance = 2 * 64,
        })
    end
    return itemstack
end

local function handle_reload_action(itemstack, user, pointed_thing, def)
    if not user or not user:is_player() then return itemstack end
    if pointed_thing and pointed_thing.type == "node" then
        local node = minetest.get_node_or_nil(pointed_thing.under)
        if node then
            local nodedef = minetest.registered_nodes[node.name]
            if nodedef and nodedef.on_rightclick and not user:get_player_control().sneak then
                return nodedef.on_rightclick(pointed_thing.under, node, user, itemstack, pointed_thing)
            end
        end
    end
    return reload_with_battery(itemstack, user, def)
end

-- Re-implement bweapons hi-tech weapons to bypass Technic completely
-- We wait for the existing items to load, then redefine them using minetest.register_tool with the ":" prefix
minetest.register_on_mods_loaded(function()
    for name, _ in pairs(minetest.registered_tools) do
        if energy_weapons[name] then
            -- Copy the existing definition
            local def = table.copy(minetest.registered_tools[name])
            local uses = def.uses or 64

            -- Strip Technic requirements and set our custom durability
            def.requires_technic = false
            def.has_durability = true
            def.custom_charge = true
            def.on_refill = nil
            def.wear_represents = "mechanical_wear"
            def.groups = table.copy(def.groups or {})
            def.groups.not_repaired_by_anvil = 1

            if minetest.global_exists("anvil") and anvil.make_unrepairable then
                anvil.make_unrepairable(name)
            end

            -- Quick reload via right-click / secondary use
            def.on_place = function(itemstack, placer, pointed_thing)
                return handle_reload_action(itemstack, placer, pointed_thing, def)
            end
            def.on_secondary_use = function(itemstack, user, pointed_thing)
                return handle_reload_action(itemstack, user, pointed_thing, def)
            end

            local original_on_use = minetest.registered_tools[name].on_use

            def.on_use = function(itemstack, user, pointed_thing)
                if not user then return end
                local playername = user:get_player_name()

                if players[playername] and players[playername].reloading then
                    return
                end

                -- Check our custom durability first
                local wear = itemstack:get_wear()
                if (65535 - wear) < (65535 / uses) then
                    if def.reload_sound then
                        minetest.sound_play(def.reload_sound, {
                            object = user,
                            gain = def.reload_sound_gain or 0.5,
                            max_hear_distance = 2 * 64,
                        })
                    end
                    return itemstack -- Discharged
                end

                -- Create a spoofed itemstack for the original on_use
                local fake_stack = ItemStack(itemstack)
                local meta = minetest.deserialize(fake_stack:get_metadata()) or {}
                meta.charge = 1000000 -- Infinite charge for the original logic
                fake_stack:set_metadata(minetest.serialize(meta))

                -- Call original on_use (handles firing, ammo, sounds, effects)
                local returned_fake_stack = original_on_use(fake_stack, user, pointed_thing)

                if returned_fake_stack then
                    wear = wear + math.floor(65535 / uses)
                    if wear > 65535 then wear = 65535 end
                    itemstack:set_wear(wear)
                end

                return itemstack
            end

            -- Redefine entirely
            minetest.register_tool(":"..name, def)

            -- Register shapeless crafting recharge with Techage battery
            minetest.register_craft({
                type = "shapeless",
                output = name,
                recipe = {name, "techage:ta4_battery"},
                replacements = {{"techage:ta4_battery", "techage:ta4_battery_empty"}},
            })
        end
    end
end)

-- Craft prediction and execution for energy weapon battery recharging
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if energy_weapons[itemstack:get_name()] then
        for _, stack in pairs(old_craft_grid) do
            if stack:get_name() == itemstack:get_name() then
                local res = ItemStack(stack)
                res:set_wear(0)
                return res
            end
        end
    end
end)

minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
    if energy_weapons[itemstack:get_name()] then
        for _, stack in pairs(old_craft_grid) do
            if stack:get_name() == itemstack:get_name() then
                local res = ItemStack(stack)
                res:set_wear(0)
                return res
            end
        end
    end
end)

-- Override bweapons.register_ammo to apply recipes
local old_register_ammo = bweapons.register_ammo
bweapons.register_ammo = function(def)
    if custom_recipes[def.name] then
        def.recipe = custom_recipes[def.name]
    end
    old_register_ammo(def)
end

-- Re-register specific recipes for existing weapons if they were already registered
-- This handles the case where tweaks mod loads AFTER some packs but BEFORE others
for name, recipes in pairs(custom_recipes) do
    if minetest.registered_items[name] then
        minetest.clear_craft({output = name})
        local amount = 1
        if string.find(name, "_round") or string.find(name, "_shell") then
            amount = 8
        elseif string.find(name, "grenade") then
            amount = 4
        elseif string.find(name, "missile") or string.find(name, "slug") then
            amount = 1 -- missiles/slugs are 1 as per custom ammo.lua
        end
        
        for _, recipe in pairs(recipes) do
            minetest.register_craft({
                type = "shaped",
                output = name .. " " .. amount,
                recipe = recipe,
            })
        end
    end
end
