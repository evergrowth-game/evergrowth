-- Re-implement gadgets_modpack tools to bypass Technic completely
-- We wait for the existing items to load, then redefine them using minetest.register_tool with the ":" prefix
minetest.register_on_mods_loaded(function()
    for name, _ in pairs(minetest.registered_tools) do
        if string.find(name, "gadgets_") then
            local def = table.copy(minetest.registered_tools[name])
            
            -- Only modify tools that originally required technic
            if def.requires_technic then
                -- Strip Technic requirements and set standard durability
                def.requires_technic = false
                def.on_refill = nil
                def.wear_represents = "mechanical_wear"
                
                local original_on_use = minetest.registered_tools[name].on_use
                
                if original_on_use then
                    def.on_use = function(itemstack, user, pointed_thing)
                        if not user then return end

                        local uses = def.uses or 250

                        -- Check standard durability first
                        local wear = itemstack:get_wear()
                        if (65535 - wear) < (65535 / uses) then
                            -- Durability broken, play reload sound if it exists
                            if def.reload_sound then
                                minetest.sound_play(def.reload_sound, {object=user, gain=def.reload_sound_gain or 1.0, max_hear_distance=2*64})
                            end
                            return itemstack
                        end
                        
                        -- Create a spoofed itemstack for the original on_use to bypass Technic block
                        local fake_stack = ItemStack(itemstack)
                        local meta = minetest.deserialize(fake_stack:get_metadata()) or {}
                        
                        -- The original on_use checks if `meta.charge < def.technic_charge_per_use`
                        -- So we spoof a massive charge
                        meta.charge = 1000000 
                        fake_stack:set_metadata(minetest.serialize(meta))
                        
                        -- Call original on_use
                        -- The original on-use handles the spell logic, takes the fake mana, updates the fake metadata, and calls technic dummy API
                        local returned_fake_stack = original_on_use(fake_stack, user, pointed_thing)
                        
                        if returned_fake_stack then
                            -- Apply standard non-Technic wear to the REAL itemstack
                            wear = wear + (65535 / uses)
                            if wear > 65535 then wear = 65535 end
                            itemstack:set_wear(wear)
                            return itemstack
                        end
                        
                        return itemstack
                    end
                end

                -- Redefine entirely to overwrite the original tool registration
                minetest.register_tool(":"..name, def)
            end
        end
    end
end)
