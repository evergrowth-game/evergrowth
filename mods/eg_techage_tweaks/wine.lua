-- Techage Tweaks: Wine Integration
-- Allows placing a Techage water barrel directly into a Wine barrel to instantly fill it.

local wine_barrel = minetest.registered_nodes["wine:wine_barrel"]

if wine_barrel then
    -- We need to safely override the inventory callbacks for the wine barrel
    local old_allow_put = wine_barrel.allow_metadata_inventory_put
    local old_on_put = wine_barrel.on_metadata_inventory_put
    local old_on_punch = wine_barrel.on_punch

    minetest.override_item("wine:wine_barrel", {
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            if listname == "src_b" then
                local item_name = stack:get_name()
                if item_name == "techage:barrel_water" or item_name == "techage:barrel_river_water" then
                    local meta = minetest.get_meta(pos)
                    local water = meta:get_int("water")
                    if water < 100 then
                        return stack:get_count()
                    else
                        return 0 -- Barrel is already full
                    end
                end
            end
            -- Fall back to original logic if it exists
            if old_allow_put then
                return old_allow_put(pos, listname, index, stack, player)
            end
            return 0
        end,

        on_metadata_inventory_put = function(pos, listname, index, stack, player)
            if listname == "src_b" then
                local item_name = stack:get_name()
                if item_name == "techage:barrel_water" or item_name == "techage:barrel_river_water" then
                    local meta = minetest.get_meta(pos)
                    local inv = meta:get_inventory()
                    
                    -- Instantly fill water to 100
                    meta:set_int("water", 100)
                    
                    -- Remove the full barrel and replace with an empty techage barrel
                    inv:remove_item("src_b", item_name)
                    inv:add_item("src_b", "techage:ta3_barrel_empty")

                    -- Start the Node Timer to trigger the formspec and state update immediately
                    local timer = minetest.get_node_timer(pos)
                    if not timer:is_started() then
                        timer:start(5)
                    end
                    
                    -- We don't want to call the old_on_put for techage barrels because the original 
                    -- wine mod function doesn't know about our 100-water instant fill logic and 
                    -- attempts to look up the item in its bucket_list table, which causes a silent failure.
                    return
                end
            end

            -- Fall back to original logic for regular buckets
            if old_on_put then
                old_on_put(pos, listname, index, stack, player)
            end
        end,

        on_punch = function(pos, node, puncher, pointed_thing)
            if puncher and puncher:is_player() then
                local wielded = puncher:get_wielded_item()
                if wielded then
                    local item_name = wielded:get_name()
                    if item_name == "techage:barrel_water" or item_name == "techage:barrel_river_water" then
                        local meta = minetest.get_meta(pos)
                        local water = meta:get_int("water")
                        if water < 100 then
                            -- Instantly fill water to 100
                            meta:set_int("water", 100)
                            
                            if not minetest.settings:get_bool("creative_mode") then
                                wielded:take_item()
                                puncher:set_wielded_item(wielded)
                                
                                local inv = puncher:get_inventory()
                                local empty_barrel = ItemStack("techage:ta3_barrel_empty")
                                if inv:room_for_item("main", empty_barrel) then
                                    inv:add_item("main", empty_barrel)
                                else
                                    minetest.add_item(puncher:get_pos(), empty_barrel)
                                end
                            end
                            
                            -- Start the Node Timer
                            local timer = minetest.get_node_timer(pos)
                            if not timer:is_started() then
                                timer:start(5)
                            end
                            
                            minetest.sound_play("default_water_footstep", {pos = pos, gain = 1.0}, true)
                            return
                        end
                    end
                end
            end
            
            -- Fall back to original punch logic
            if old_on_punch then
                return old_on_punch(pos, node, puncher, pointed_thing)
            end
        end
    })
    
    minetest.log("action", "[techage_tweaks] Wine integration loaded.")
end
