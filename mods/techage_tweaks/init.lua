local S = minetest.get_translator("techage")

minetest.register_on_mods_loaded(function()
    -- TechAge Stackables: Automatically finds any techage barrels, canisters, and cylinders limited to stack size 1
    for item_name, def in pairs(minetest.registered_items) do
        if item_name:find("^techage:") then
            if item_name:find("barrel") or item_name:find("canister") or item_name:find("cylinder") then
                if def.stack_max == 1 then
                    minetest.override_item(item_name, {
                        stack_max = 99
                    })
                end
            end
        end
    end

    if minetest.get_modpath("motorboat") and motorboat and motorboat.fuel then
        motorboat.fuel['techage:ta3_canister_gasoline'] = 1
        motorboat.fuel['techage:ta3_barrel_gasoline'] = 10
    end

    if minetest.get_modpath("airutils") and airutils and airutils.fuel then
        airutils.fuel['techage:ta3_canister_gasoline'] = 1
        airutils.fuel['techage:ta3_barrel_gasoline'] = 10
    end
end)

if minetest.get_modpath("wine") then
    dofile(minetest.get_modpath("techage_tweaks") .. "/wine.lua")
end

if minetest.get_modpath("autobahn") then
    dofile(minetest.get_modpath("techage_tweaks") .. "/road_builder.lua")
end

-- 6. TA3 Oil Explorer Auto-Scan
-- We load the modified explore.lua which uses ":" to override the original nodes entirely.
dofile(minetest.get_modpath("techage_tweaks") .. "/explore.lua")
minetest.register_on_mods_loaded(function()

    -- 1. Autobahn Priv Reset Removal
    for name, def in pairs(minetest.registered_nodes) do
        if name:sub(1, 13) == "autobahn:node" then
            local new_def = table.copy(def)
            new_def.on_rightclick = nil
            minetest.register_node(":"..name, new_def)
        end
    end

    -- 2. Boiler Liquid Support (`techage.boiler.on_punch`)
    if techage and techage.boiler and techage.boiler.on_punch then
        local IsWater = {
            ["bucket:bucket_river_water"] = "bucket:bucket_empty",
            ["bucket:bucket_water"] = "bucket:bucket_empty",
        }
        local IsBucket = {
            ["bucket:bucket_empty"] = "bucket:bucket_water"
        }
        
        local MAX_WATER = 10
        local BLOCKING_TIME = 0.3 -- 300ms

        techage.boiler.on_punch = function(pos, node, puncher, pointed_thing)
            local nvm = techage.get_nvm(pos)
            local mem = techage.get_mem(pos)
            local M = minetest.get_meta(pos)
            mem.blocking_time = mem.blocking_time or 0
            if mem.blocking_time > techage.SystemTime then
                return
            end

            nvm.num_water = nvm.num_water or 0
            local wielded_item = puncher:get_wielded_item():get_name()
            local item_count = puncher:get_wielded_item():get_count()
            
            local ldef = nil
            if techage.liquid and techage.liquid.get_liquid_def then
                ldef = techage.liquid.get_liquid_def(wielded_item)
            end
            
            if not ldef and IsWater[wielded_item] then
                ldef = {
                    container = IsWater[wielded_item],
                    size = 1,
                    inv_item = "techage:water"
                }
            end

            if ldef and (ldef.inv_item == "techage:water" or ldef.inv_item == "techage:river_water") then
                if nvm.num_water < MAX_WATER then
                    local container = ldef.container or ""
                    local inv = puncher:get_inventory()
                    
                    if item_count > 1 then
                        if container ~= "" and not inv:room_for_item("main", ItemStack(container)) then
                            return
                        end
                        puncher:set_wielded_item({name = wielded_item, count = item_count - 1})
                        if container ~= "" then
                            inv:add_item("main", ItemStack(container))
                        end
                    else
                        puncher:set_wielded_item(ItemStack(container))
                    end
                    
                    mem.blocking_time = techage.SystemTime + BLOCKING_TIME
                    nvm.num_water = math.min(MAX_WATER, nvm.num_water + ldef.size)
                    M:set_string("formspec", techage.boiler.formspec(pos, nvm))
                end
            elseif IsBucket[wielded_item] and nvm.num_water > 0 then
                local inv = puncher:get_inventory()
                local filled_bucket = ItemStack(IsBucket[wielded_item])
                if item_count > 1 then
                    if inv:room_for_item("main", filled_bucket) then
                        inv:add_item("main", filled_bucket)
                        puncher:set_wielded_item({name = wielded_item, count = item_count - 1})
                        mem.blocking_time = techage.SystemTime + BLOCKING_TIME
                        nvm.num_water = nvm.num_water - 1
                        M:set_string("formspec", techage.boiler.formspec(pos, nvm))
                    end
                else
                    mem.blocking_time = techage.SystemTime + BLOCKING_TIME
                    nvm.num_water = nvm.num_water - 1
                    puncher:set_wielded_item(filled_bucket)
                    M:set_string("formspec", techage.boiler.formspec(pos, nvm))
                end
            end
        end
    end

    -- 3 & 4. Grid Integrations (`techage:streetlamp_pole`, `techage:streetlamp_arm`, `techage:pillar`)
    local Cable = techage.ElectricCable
    local power = nil
    if networks and networks.power then power = networks.power end

    if Cable and power then
        local nodes_to_patch = {
            "techage:streetlamp_pole",
            "techage:streetlamp_arm",
            "techage:pillar"
        }

        for _, name in ipairs(nodes_to_patch) do
            if minetest.registered_nodes[name] then
                local def = table.copy(minetest.registered_nodes[name])
                def.groups = def.groups or {}
                if name ~= "techage:pillar" then
                    def.groups.techage_trowel = 1
                end
                def.after_place_node = function(pos, placer, itemstack, pointed_thing)
                    Cable:after_place_node(pos)
                end
                def.after_dig_node = function(pos, oldnode, oldmetadata, digger)
                    Cable:after_dig_node(pos)
                end
                minetest.register_node(":"..name, def)

                local found = false
                for _, v in ipairs(Cable.primary_node_names) do
                    if v == name then found = true break end
                end
                if not found then
                    table.insert(Cable.primary_node_names, name)
                end
            end
        end
        power.register_nodes(nodes_to_patch, Cable, "junc")
    end

    -- 5. Power Line Auto-Stringing
    if Cable then
        local found = false
        for _, v in ipairs(Cable.primary_node_names) do
            if v == "techage:power_pole_conn" then found = true break end
        end
        if not found then
            table.insert(Cable.primary_node_names, "techage:power_pole_conn")
        end
        
        local original_clbk = Cable.clbk_after_place_tube
        if original_clbk then
            Cable.clbk_after_place_tube = function(pos, param2, tube_type, num_tubes)
                local node = minetest.get_node(pos)
                if node.name == "techage:power_pole_conn" then
                    return
                end
                original_clbk(pos, param2, tube_type, num_tubes)
            end
        end

        local function get_line_6_connected(pos1, pos2)
            local points = {}
            local x1, y1, z1 = pos1.x, pos1.y, pos1.z
            local x2, y2, z2 = pos2.x, pos2.y, pos2.z
            local sx = (x1 < x2) and 1 or -1
            local sy = (y1 < y2) and 1 or -1
            local sz = (z1 < z2) and 1 or -1

            local p = {x=x1, y=y1, z=z1}
            table.insert(points, {x=x1, y=y1, z=z1})
            
            local y_plateau = math.max(y1, y2)
            
            while p.x ~= x2 or p.y ~= y2 or p.z ~= z2 do
                local dist_x = math.abs(x2 - p.x)
                local dist_y = math.abs(y2 - p.y)
                local dist_z = math.abs(z2 - p.z)
                local h_dist = dist_x + dist_z
                
                local move_x = false
                local move_y = false
                
                if #points == 1 and h_dist > 0 then
                    if dist_x >= dist_z then move_x = true end
                elseif h_dist == 1 and dist_y > 0 then
                    move_y = true
                elseif p.y < y_plateau and dist_y > 0 then
                    move_y = true
                elseif h_dist > 0 then
                    if dist_x >= dist_z then move_x = true end
                else
                    move_y = true
                end
                
                if move_x then p.x = p.x + sx
                elseif move_y then p.y = p.y + sy
                else p.z = p.z + sz end
                table.insert(points, {x=p.x, y=p.y, z=p.z})
            end
            return points
        end

        local function on_rightclick_conn(pos, node, clicker, itemstack, pointed_thing)
            if not clicker or not clicker:is_player() then return end
            local name = clicker:get_player_name()
            local held = itemstack:get_name()
            if held ~= "techage:power_lineS" then return end
            
            local meta = clicker:get_meta()
            local start_str = meta:get_string("ta_cable_start")
            
            if start_str == "" then
                meta:set_string("ta_cable_start", minetest.pos_to_string(pos))
                minetest.chat_send_player(name, S("Cable stringing started. Click next pole within 16 blocks."))
                return itemstack
            end
            
            local start_pos = minetest.string_to_pos(start_str)
            if not start_pos then
                meta:set_string("ta_cable_start", "")
                return itemstack
            end
            
            local dist = vector.distance(start_pos, pos)
            if dist < 1 then
                meta:set_string("ta_cable_start", "")
                minetest.chat_send_player(name, S("Cancelled."))
                return itemstack
            end
            if dist > 16 then
                meta:set_string("ta_cable_start", "")
                minetest.chat_send_player(name, S("Too far! Max 16 blocks."))
                return itemstack
            end
            
            local path = get_line_6_connected(start_pos, pos)
            local to_place = {}
            for _, p in ipairs(path) do
                if not vector.equals(p, start_pos) and not vector.equals(p, pos) then
                    local n = minetest.get_node(p)
                    if n.name == "air" or n.name == "techage:power_lineS" then
                        if minetest.is_protected(p, name) then
                            minetest.chat_send_player(name, S("Path protected at").." "..minetest.pos_to_string(p))
                            meta:set_string("ta_cable_start", "")
                            return itemstack
                        end
                        table.insert(to_place, p)
                    else
                        minetest.chat_send_player(name, S("Path blocked at").." "..minetest.pos_to_string(p))
                        meta:set_string("ta_cable_start", "")
                        return itemstack
                    end
                end
            end
            
            if #to_place == 0 then
                minetest.chat_send_player(name, S("No cable needed."))
                meta:set_string("ta_cable_start", "")
                return itemstack
            end
            
            if not minetest.is_creative_enabled(name) and itemstack:get_count() < #to_place then
                minetest.chat_send_player(name, S("Not enough cable! Needed: ")..#to_place)
                meta:set_string("ta_cable_start", "")
                return itemstack
            end
            
            for _, p in ipairs(to_place) do
                minetest.set_node(p, {name="techage:power_lineS"})
            end
            
            for i, p in ipairs(to_place) do
                Cable:after_place_tube(p, nil, nil)
                local prev = (i == 1) and start_pos or to_place[i-1]
                local next_p = (i == #to_place) and pos or to_place[i+1]
                
                local dx = math.abs(next_p.x - prev.x)
                local dy = math.abs(next_p.y - prev.y)
                local dz = math.abs(next_p.z - prev.z)
                
                if dx > 0 and dz == 0 and dy == 0 then
                    minetest.swap_node(p, {name="techage:power_lineS", param2=1})
                elseif dz > 0 and dx == 0 and dy == 0 then
                    minetest.swap_node(p, {name="techage:power_lineS", param2=0})
                end
            end
            
            for i, p in ipairs(to_place) do
                local is_start = (i == 1)
                local is_end = (i == #to_place)
                if is_start or is_end then
                    local pole = is_start and start_pos or pos
                    local path_neighbor = nil
                    if is_start then
                        path_neighbor = (#to_place > 1) and to_place[2] or pos
                    else
                        path_neighbor = (#to_place > 1) and to_place[i-1] or start_pos
                    end
                    local dy_total = math.abs(pole.y - path_neighbor.y)
                    if dy_total == 0 and p.y == pole.y then
                        local is_x_aligned = (pole.z == p.z and p.z == path_neighbor.z)
                        local is_z_aligned = (pole.x == p.x and p.x == path_neighbor.x)
                        if is_x_aligned then minetest.swap_node(p, {name="techage:power_lineS", param2=1})
                        elseif is_z_aligned then minetest.swap_node(p, {name="techage:power_lineS", param2=0}) end
                    end
                end
            end
            
            if not minetest.is_creative_enabled(name) then
                itemstack:take_item(#to_place)
            end
            meta:set_string("ta_cable_start", "")
            minetest.chat_send_player(name, S("Stringing complete! Used ")..#to_place..S(" cables."))
            
            return itemstack
        end

        local auto_stringing_nodes = {"techage:power_line", "techage:power_pole2", "techage:power_lineS", "techage:power_lineA", "techage:power_pole_conn"}
        for _, nodename in ipairs(auto_stringing_nodes) do
            if minetest.registered_nodes[nodename] then
                minetest.override_item(nodename, {
                    on_rightclick = on_rightclick_conn
                })
            end
        end
    end

    -- 6. Disable Stamina Mod (Conflicts with HBHunger)
    if minetest.global_exists("stamina") and minetest.get_modpath("hbhunger") then
        stamina.update_saturation = function() end
        minetest.register_on_joinplayer(function(player)
            minetest.after(0.1, function()
                for i = 0, 30 do
                    local hud = player:hud_get(i)
                    if hud and hud.name == "stamina" then player:hud_remove(i) end
                end
            end)
        end)
    end

    -- 7. Clean up Test Nodes & Deprecated Legacy Variants
    local clutter_nodes = {
        -- Test & Dev Nodes
        "techage:sink",
        "techage:sink_on",
        "techage:t2_source",
        "techage:t4_source",
        "techage:testblock",
        -- Legacy / Deprecated Variants
        "techage:powerswitch_box",
        "techage:powerswitch_box_on",
        "techage:ta3_doorcontroller",
        "techage:ta4_movecontroller",
        "techage:ta3_logic",
    }

    for _, nodename in ipairs(clutter_nodes) do
        if minetest.registered_items[nodename] then
            local groups = table.copy(minetest.registered_items[nodename].groups or {})
            groups.not_in_creative_inventory = 1
            minetest.override_item(nodename, {
                groups = groups,
            })
            minetest.clear_craft({ output = nodename })
        end
    end

    -- 8. Unified Inventory Button Layout & Privilege Filtering
    if minetest.global_exists("unified_inventory") and unified_inventory then
        unified_inventory.hide_disabled_buttons = true
        if unified_inventory.style_full then
            unified_inventory.style_full.main_button_cols = 14
        end

        -- Remove clear_inv button for all players
        if unified_inventory.buttons then
            for i = #unified_inventory.buttons, 1, -1 do
                if unified_inventory.buttons[i].name == "clear_inv" then
                    table.remove(unified_inventory.buttons, i)
                end
            end
        end
    end
end)

