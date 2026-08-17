-- Aircraft Tweaks
-- Dynamically adjusts lateral drag to fix slipping on ice feeling when taxiing.

local function apply_lateral_drag_fix(entity_name)
    local def = minetest.registered_entities[entity_name]
    if def then
        local old_on_step = def.on_step
        def.on_step = function(self, dtime, moveresult)
            -- Apply dynamic lateral drag on ground vs in air
            if self.isonground then
                self._later_drag_factor = 15.0
            else
                self._later_drag_factor = 2.0 -- restore to default for aerodynamics
            end
            
            -- Call the original step function
            if old_on_step then
                old_on_step(self, dtime, moveresult)
            end
        end
        minetest.log("action", "[aircraft_tweaks] Applied lateral drag fix to " .. entity_name)
    end
end

local function apply_helicopter_tweaks(entity_name)
    local def = minetest.registered_entities[entity_name]
    if def then
        local old_on_step = def.on_step
        def.on_step = function(self, dtime, moveresult)
            -- Dynamic drag factors: prevent sliding on ground and dampen lateral drift in air
            if self.isonground or (self.colinfo and self.colinfo.touching_ground) then
                self._later_drag_factor = 15.0
                self._longit_drag_factor = 15.0
            else
                self._later_drag_factor = 0.8
                self._longit_drag_factor = 0.4
            end

            -- Call the original step function
            if old_on_step then
                old_on_step(self, dtime, moveresult)
            end

            -- Vertical flight damping & altitude stabilization during level flight
            if self._engine_running and not self.isonground and not (self.colinfo and self.colinfo.touching_ground) then
                local pilot = self.driver_name and minetest.get_player_by_name(self.driver_name)
                local ctrl = pilot and pilot:get_player_control()
                local holding_vertical = ctrl and (ctrl.jump or ctrl.sneak)

                if not holding_vertical then
                    local vel = self.object:get_velocity()
                    if vel then
                        if math.abs(vel.y) < 0.35 then
                            vel.y = 0
                            self.object:set_velocity(vel)
                        else
                            vel.y = vel.y * math.max(0, 1.0 - (dtime * 4.0))
                            self.object:set_velocity(vel)
                        end
                    end
                end
            end
        end
        minetest.log("action", "[aircraft_tweaks] Applied helicopter stabilization tweaks to " .. entity_name)
    end
end

minetest.register_on_mods_loaded(function()
    if minetest.get_modpath("supercub") then
        apply_lateral_drag_fix("supercub:supercub")
    end
    
    if minetest.get_modpath("hidroplane") then
        apply_lateral_drag_fix("hidroplane:hidro")
    end

    if minetest.get_modpath("pa28") then
        apply_lateral_drag_fix("pa28:pa28")
    end

    if minetest.get_modpath("heli") then
        apply_helicopter_tweaks("heli:heli")
    end
end)

