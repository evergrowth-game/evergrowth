local S = minetest.get_translator("techage_tweaks")

-- We need a basic texture for the tool. We will just use a colored stick for now, built into default.
local tool_texture = "default_stick.png^[colorize:#888888:120"

local max_length = 10

-- Table to store undo history
local undo_history = {}

minetest.register_tool("techage_tweaks:road_builder", {
    description = S("Road Builder Wand") .. "\n" .. S("Left-Click: Change settings") .. "\n" .. S("Right-Click: Build road"),
    inventory_image = tool_texture,
    
    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then return itemstack end
        
        local meta = itemstack:get_meta()
        
        -- Default settings
        local width = meta:get_int("width")
        if width == 0 then width = 3 end
        
        local mode = meta:get_string("mode")
        if mode == "" then mode = "straight" end
        
        -- Cycle logic
        local keys = user:get_player_control()
        if keys.sneak then
            -- Toggle mode if sneaking
            if mode == "straight" then
                mode = "diagonal"
            elseif mode == "diagonal" then
                mode = "bridge"
            else
                mode = "straight"
            end
            meta:set_string("mode", mode)
        else
            -- Cycle width if not sneaking
            if width == 3 then width = 5
            elseif width == 5 then width = 7
            else width = 3 end
            meta:set_int("width", width)
        end
        
        minetest.chat_send_player(user:get_player_name(), 
            "[Road Builder] Settings updated: Width=" .. width .. ", Mode=" .. mode)
            
        return itemstack
    end,

    on_place = function(itemstack, placer, pointed_thing)
        if not placer or not placer:is_player() then return itemstack end
        
        local player_name = placer:get_player_name()
        local keys = placer:get_player_control()
        local inv = placer:get_inventory()
        local is_creative = minetest.is_creative_enabled(player_name)
        
        -- Undo Functionality
        if keys.sneak then
            if undo_history[player_name] and #undo_history[player_name].positions > 0 then
                local history = undo_history[player_name]
                local blocks_removed = 0
                for _, p in ipairs(history.positions) do
                    local node = minetest.get_node(p)
                    -- Check if it's an autobahn node (including auto-sloped ones)
                    if node.name:find("^autobahn:node") then
                        minetest.remove_node(p)
                        blocks_removed = blocks_removed + 1
                    end
                end
                
                if not is_creative and blocks_removed > 0 then
                    inv:add_item("main", "autobahn:node1 " .. blocks_removed)
                end
                
                undo_history[player_name] = nil
                minetest.chat_send_player(player_name, "[Road Builder] Undid last placement. Refunded " .. blocks_removed .. " blocks.")
            else
                minetest.chat_send_player(player_name, "[Road Builder] Nothing to undo.")
            end
            return itemstack
        end
        
        local meta = itemstack:get_meta()
        local width = meta:get_int("width")
        if width == 0 then width = 3 end
        local mode = meta:get_string("mode")
        if mode == "" then mode = "straight" end
                
        local ppos = placer:get_pos()
        local look_dir = placer:get_look_dir()
        local facedir = minetest.dir_to_facedir(look_dir)
        
        -- Facedir mappings: 0 = Z+, 1 = X+, 2 = Z-, 3 = X-
        local f_vec = {x=0, y=0, z=0}
        local r_vec = {x=0, y=0, z=0}
        
        if facedir == 0 then
            f_vec.z = 1; r_vec.x = -1
        elseif facedir == 1 then
            f_vec.x = 1; r_vec.z = 1
        elseif facedir == 2 then
            f_vec.z = -1; r_vec.x = 1
        elseif facedir == 3 then
            f_vec.x = -1; r_vec.z = -1
        end
        
        local half_w = math.floor(width / 2)
        local blocks_placed = 0
        local blocks_needed = width * max_length
        
        -- Check inventory first if not creative
        if not is_creative then
            if not inv:contains_item("main", "autobahn:node1 " .. blocks_needed) then
                 minetest.chat_send_player(placer:get_player_name(), 
                    "[Road Builder] Not enough autobahn:node1. Need " .. blocks_needed)
                 return itemstack
            end
        end

        local positions_placed = {}

        for l = 1, max_length do
            for w = -half_w, half_w do
                
                local tx = ppos.x + (f_vec.x * l) + (r_vec.x * w)
                local tz = ppos.z + (f_vec.z * l) + (r_vec.z * w)
                
                if mode == "diagonal" then
                    -- To widen a diagonal line cleanly without holes or overlaps,
                    -- we use a diagonal forward vector but shift along the orthogonal right vector.
                    local df_x = f_vec.x + r_vec.x
                    local df_z = f_vec.z + r_vec.z
                    
                    tx = ppos.x + (df_x * l) + (r_vec.x * w)
                    tz = ppos.z + (df_z * l) + (r_vec.z * w)
                end
                
                local ty = math.floor(ppos.y)
                
                -- Ground search (scan +/- 3 blocks) or Bridge Mode
                local found_ground = false
                local target_y = ty
                
                if mode == "bridge" then
                    found_ground = true
                    target_y = ty
                else
                    for dy = 3, -3, -1 do
                        local node = minetest.get_node({x=tx, y=ty+dy, z=tz})
                        local def = minetest.registered_nodes[node.name]
                        if def and def.walkable and not def.buildable_to then
                            target_y = ty + dy + 1 -- Place on top
                            found_ground = true
                            break
                        end
                    end
                end
                
                if found_ground then
                    local p = {x=tx, y=target_y, z=tz}
                    
                    -- Check if space is empty
                    local n_above = minetest.get_node(p)
                    local ndef = minetest.registered_nodes[n_above.name]
                    if ndef and ndef.buildable_to then
                        
                        -- Figure out orientation for stripes
                        local param2_val = facedir
                        if mode == "diagonal" then
                            -- Diagonal roads shouldn't auto-slope anyway, but we can set stripes to face the grid
                            param2_val = facedir
                        else
                            -- We want the stripes going lengthwise
                           param2_val = facedir
                        end

                        minetest.set_node(p, {name="autobahn:node1", param2=param2_val})
                        table.insert(positions_placed, p)
                        blocks_placed = blocks_placed + 1
                    end
                end
            end
        end
        
        -- Deduct inventory
        if not is_creative and blocks_placed > 0 then
            inv:remove_item("main", "autobahn:node1 " .. blocks_placed)
        end
        
        -- Trigger autobahn slopes AFTER all are placed so it sees neighbours correctly
        if mode == "straight" then
            local autobahn_def = minetest.registered_nodes["autobahn:node1"]
            if autobahn_def and autobahn_def.after_place_node then
                for _, p in ipairs(positions_placed) do
                   autobahn_def.after_place_node(p, placer, nil, nil)
                end
            end
        end
        
        -- Save history for undo
        if #positions_placed > 0 then
            undo_history[player_name] = {
                positions = positions_placed,
                count = blocks_placed
            }
        end
        
        minetest.chat_send_player(player_name, 
            "[Road Builder] " .. blocks_placed .. " blocks placed.")

        return itemstack
    end,
})

minetest.register_craft({
    output = "techage_tweaks:road_builder",
    recipe = {
        {"", "autobahn:node1", ""},
        {"", "default:stick", ""},
        {"", "default:stick", ""}
    }
})
