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
        def._use_camera_relocation = false
        def._climb_speed = nil
        def._lift_dead_zone = nil

        local old_logic = def.logic
        def.logic = function(self)
            -- Bypass upstream hard step governor to prevent square-wave oscillation
            self._climb_speed = nil
            self._lift_dead_zone = nil

            -- Dynamic drag factors: prevent sliding on ground and dampen lateral drift in air
            if self.isonground or (self.colinfo and self.colinfo.touching_ground) then
                self._later_drag_factor = 15.0
                self._longit_drag_factor = 15.0
            else
                self._later_drag_factor = 0.06
                self._longit_drag_factor = 0.018
            end

            if old_logic then
                old_logic(self)
            end

            -- Smooth vertical control & altitude stabilization
            if self._engine_running and not self.isonground and not (self.colinfo and self.colinfo.touching_ground) then
                local pilot = self.driver_name and minetest.get_player_by_name(self.driver_name)
                local ctrl = pilot and pilot:get_player_control()
                local vel = self.object:get_velocity()

                if vel and self._last_accel then
                    local grav = math.abs(airutils.gravity)
                    if ctrl and ctrl.jump then
                        -- Smooth upward climb capped at 5.0 m/s with continuous proportional force
                        local max_climb = 5.0
                        local climb_factor = math.max(0, (max_climb - vel.y) / max_climb)
                        self._last_accel.y = grav + (3.5 * climb_factor)
                    elseif ctrl and ctrl.sneak then
                        -- Smooth descent capped at -4.0 m/s with continuous proportional force
                        local max_desc = 4.0
                        local desc_factor = math.max(0, (max_desc + vel.y) / max_desc)
                        self._last_accel.y = grav - (3.0 * desc_factor)
                    else
                        -- Neutral level flight: Altitude lock & smooth vertical damping
                        if math.abs(vel.y) < 0.25 then
                            self._last_accel.y = grav
                        else
                            self._last_accel.y = grav - (vel.y * 3.5)
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

