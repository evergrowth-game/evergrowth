minetest.register_on_mods_loaded(function()
    local motorboat_ent = minetest.registered_entities["motorboat:boat"]
    if motorboat_ent then
        local original_on_step = motorboat_ent.on_step
        
        motorboat_ent.on_step = function(self, dtime)
            -- Call the original on_step which handles base physics, controls, energy, etc.
            original_on_step(self, dtime)

            -- Apply additional lateral drag to prevent "drifting on ice"
            if self.isinliquid then
                local velocity = self.object:get_velocity()
                local yaw = self.object:get_rotation().y
                local hull_direction = minetest.yaw_to_dir(yaw)
                local nhdir = {x = hull_direction.z, y = 0, z = -hull_direction.x}
                
                -- Calculate dot product for lateral speed
                local later_speed = velocity.x * nhdir.x + velocity.y * nhdir.y + velocity.z * nhdir.z
                
                -- We want an effective drag factor of around 3.5 for a boat. 
                -- The original mod hardcodes 2.0, so we add 1.5 extra drag here.
                -- This allows for some realistic watery drift, without feeling like ice.
                local extra_drag_factor = 1.5
                local sign = later_speed >= 0 and 1 or -1
                
                local extra_later_drag = vector.multiply(nhdir, later_speed * later_speed * extra_drag_factor * -1 * sign)
                
                local accel = self.object:get_acceleration()
                accel = vector.add(accel, extra_later_drag)
                self.object:set_acceleration(accel)
            end

            -- INCREASE TURN RATE
            if math.abs(self.rudder_angle) > 5 then
                local rotation = self.object:get_rotation()
                local velocity = self.object:get_velocity()
                
                -- Compute longitudinal speed based on current updated yaw
                local hull_direction = minetest.yaw_to_dir(rotation.y)
                local longit_speed = velocity.x * hull_direction.x + velocity.y * hull_direction.y + velocity.z * hull_direction.z
                local sign = longit_speed >= 0 and 1 or -1
                
                -- Original turn rate was math.rad(24). We add math.rad(15) to make it slightly snappier (total ~39 degrees/sec).
                local extra_turn_rate = math.rad(15)
                
                local extra_yaw = dtime * (1 - 1 / (math.abs(longit_speed) + 1)) *
                                  (self.rudder_angle / 30) * extra_turn_rate * sign
                
                rotation.y = rotation.y + extra_yaw
                self.object:set_rotation(rotation)
            end
        end
    end
end)
