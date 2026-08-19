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

local function engineSoundPlay(self, increment, base)
    increment = increment or 0.0
    if self.sound_handle then core.sound_stop(self.sound_handle) end
    if self.object then
        local base_pitch = base
        local pitch_adjust = base_pitch + increment
        self.sound_handle = core.sound_play({name = self._engine_sound},
            {object = self.object, gain = 2.0,
                pitch = pitch_adjust,
                max_hear_distance = 32,
                loop = true,})
    end
end

local function engine_set_sound_and_animation(self, is_flying, newpitch, newroll)
    is_flying = is_flying or false

    if self._engine_running then
        if not self.sound_handle then
            engineSoundPlay(self, 0.0, 0.9)
        end
        if self._snd_last_cmd ~= self._cmd_snd then
            local increment
            self._snd_last_cmd = self._cmd_snd
            if self._cmd_snd then increment = 0.1 else increment = 0.0 end
            engineSoundPlay(self, increment, 0.9)
        end
        self.object:set_animation_frame_speed(100)
    else
        if is_flying then
            if self._snd_last_cmd ~= self._cmd_snd then
                local increment
                self._snd_last_cmd = self._cmd_snd
                if self._cmd_snd then increment = 0.1 else increment = 0.0 end
                engineSoundPlay(self, increment, 0.6)
            end
            self.object:set_animation_frame_speed(70)
        else
            if self.sound_handle then
                self._snd_last_roll = nil
                self._snd_last_pitch = nil
                core.sound_stop(self.sound_handle)
                self.sound_handle = nil
                self.object:set_animation_frame_speed(0)
            end
        end
    end
end

local function apply_helicopter_tweaks(entity_name)
    local def = minetest.registered_entities[entity_name]
    if def then
        def._use_camera_relocation = false
        def._climb_speed = nil
        def._lift_dead_zone = nil

        def.logic = function(self)
            local velocity = self.object:get_velocity()
            if not velocity then return end
            local curr_pos = self.object:get_pos()
            if not curr_pos then return end
            self._curr_pos = curr_pos
            self._last_accel = self.object:get_acceleration()

            self._last_time_command = (self._last_time_command or 0) + self.dtime
            if self._last_time_command > 1 then self._last_time_command = 1 end

            local player = nil
            if self.driver_name then player = core.get_player_by_name(self.driver_name) end
            local co_pilot = nil
            if self.co_pilot and self._have_copilot then co_pilot = core.get_player_by_name(self.co_pilot) end

            airutils.testImpact(self, velocity, curr_pos)

            local ctrl = nil
            if player then
                ctrl = player:get_player_control()
                if co_pilot and self._have_copilot and self._last_time_command >= 1 then
                    if self._command_is_given == true then
                        if ctrl.sneak or ctrl.jump or ctrl.up or ctrl.down or ctrl.right or ctrl.left then
                            self._last_time_command = 0
                            airutils.transfer_control(self, false)
                        end
                    else
                        if ctrl.sneak == true and ctrl.jump == true then
                            self._last_time_command = 0
                            airutils.transfer_control(self, true)
                        end
                    end
                end
            end

            if not self.object:get_acceleration() then return end
            local rotation = self.object:get_rotation()
            local yaw = rotation.y
            local newyaw = yaw
            local roll = rotation.z

            local hull_direction = airutils.rot_to_dir(rotation)
            local nhdir = {x = hull_direction.z, y = 0, z = -hull_direction.x}

            local is_flying = true
            if self.colinfo then
                is_flying = (not self.colinfo.touching_ground)
            end
            if self.isinliquid == true then
                is_flying = false
            end

            -- Dynamic drag factors: on ground vs cruising
            if not is_flying then
                self._later_drag_factor = 15.0
                self._longit_drag_factor = 15.0
            else
                self._later_drag_factor = 0.06
                self._longit_drag_factor = 0.018
            end

            local longit_speed = vector.dot(velocity, hull_direction)
            self._longit_speed = longit_speed

            local longit_drag = vector.multiply(hull_direction, longit_speed * longit_speed * self._longit_drag_factor * -1 * airutils.sign(longit_speed))
            local later_speed = airutils.dot(velocity, nhdir)
            local later_drag = vector.multiply(nhdir, later_speed * later_speed * self._later_drag_factor * -1 * airutils.sign(later_speed))
            local accel = vector.add(longit_drag, later_drag)

            local is_attached = airutils.checkAttach(self, player)
            if self._indicated_speed == nil then self._indicated_speed = 0 end

            if not is_attached then
                airutils.checkattachBug(self)
            end

            if self._custom_step_additional_function then
                self._custom_step_additional_function(self)
            end

            if self._have_landing_lights then
                airutils.landing_lights_operate(self)
            end

            if self._engine_running then
                local curr_health_percent = (self.hp_max * 100) / self._max_plane_hp
                if curr_health_percent < 20 then
                    airutils.add_smoke_trail(self, 2)
                elseif curr_health_percent < 50 then
                    airutils.add_smoke_trail(self, 1)
                end
            end

            if (math.abs(velocity.x) < 0.1 and math.abs(velocity.z) < 0.1) and not is_flying and not is_attached and not self._engine_running then
                engine_set_sound_and_animation(self, false, 0, 0)
                return
            end

            local y_velocity = 0
            if self._engine_running or is_flying then y_velocity = velocity.y end
            local climb_rate = math.max(-5, math.min(5, y_velocity))

            local newroll = 0
            local newpitch = 0
            if ctrl and is_flying then
                local command_angle = self._tilt_angle or 8
                local max_acc = self._max_engine_acc or 4.0

                local pitch_amount = (math.abs(self._vehicle_acc or 0) * command_angle) / max_acc
                if math.abs(longit_speed) >= self._max_speed then pitch_amount = command_angle end
                pitch_amount = math.rad(math.min(pitch_amount, command_angle))

                if ctrl.up then newpitch = -pitch_amount end
                if ctrl.down then newpitch = pitch_amount end

                local roll_amount = (math.abs(self._lat_acc or 0) * command_angle) / max_acc
                if math.abs(later_speed) >= self._max_speed then roll_amount = command_angle end
                roll_amount = math.rad(math.min(roll_amount, command_angle))

                if ctrl.left then newroll = -roll_amount end
                if ctrl.right then newroll = roll_amount end

                self._cmd_snd = (ctrl.up or ctrl.down or ctrl.left or ctrl.right)
            end

            if math.abs(self._rudder_angle or 0) > 1.5 then
                local turn_rate = math.rad(self._yaw_turn_rate or 14)
                local yaw_turn = self.dtime * math.rad(self._rudder_angle) * turn_rate * 4
                newyaw = yaw + yaw_turn
            end

            local pilot = player
            if self._have_copilot then
                if self._command_is_given and co_pilot then
                    pilot = co_pilot
                else
                    self._command_is_given = false
                end
            end

            local stop = false
            if is_attached or co_pilot then
                accel, stop = airutils.heli_control(self, self.dtime, hull_direction,
                    longit_speed, longit_drag, nhdir, later_speed, later_drag, accel, pilot, is_flying)
            end

            airutils.rescueConnectionFailedPassengers(self)

            if accel == nil then accel = {x = 0, y = 0, z = 0} end

            -- Vertical thrust calculations (smooth proportional governors)
            local grav = math.abs(airutils.gravity or 9.81)
            local target_lift_accel = grav

            if self._engine_running and is_flying then
                if ctrl and ctrl.jump then
                    local max_climb = 5.0
                    local climb_factor = math.max(0, (max_climb - velocity.y) / max_climb)
                    target_lift_accel = grav + (3.5 * climb_factor)
                elseif ctrl and ctrl.sneak then
                    local max_desc = 4.0
                    local desc_factor = math.max(0, (max_desc + velocity.y) / max_desc)
                    target_lift_accel = grav - (3.0 * desc_factor)
                else
                    if math.abs(velocity.y) < 0.25 then
                        target_lift_accel = grav
                    else
                        target_lift_accel = grav - (velocity.y * 3.5)
                    end
                end
            elseif not self._engine_running then
                target_lift_accel = 0
            end

            local new_accel = vector.new(accel)
            new_accel.y = target_lift_accel

            if airutils.wind and is_flying then
                local wind = airutils.get_wind(curr_pos, 0.1)
                new_accel = vector.add(new_accel, wind)
            end

            if stop == true then
                self._last_accel = vector.new(0, 0, 0)
                self.object:set_acceleration({x = 0, y = 0, z = 0})
                self.object:set_velocity({x = 0, y = 0, z = 0})
            else
                self._last_accel = new_accel
                -- Note: Omitted self.object:move_to(curr_pos) to eliminate position reset stutter
            end

            -- Sound and animation
            local is_ship_attached = self.object:get_attach()
            if is_ship_attached then
                engine_set_sound_and_animation(self, false, newpitch, newroll)
            else
                engine_set_sound_and_animation(self, is_flying, newpitch, newroll)
            end

            -- Gauges & HUD
            local climb_angle = airutils.get_gauge_angle(climb_rate)
            self._climb_rate = climb_rate

            local indicated_speed = math.max(0, longit_speed * 0.9)
            self._indicated_speed = indicated_speed
            local speed_angle = airutils.get_gauge_angle(indicated_speed, -45)

            local fixed_power = self._engine_running and 60 or 0
            local power_indicator_angle = airutils.get_gauge_angle(fixed_power / 10) + 90
            local fuel_in_percent = (self._energy * 1) / self._max_fuel
            local energy_indicator_angle = (180 * fuel_in_percent) - 180

            if is_attached then
                if self._show_hud then
                    airutils.update_hud(player, climb_angle, speed_angle, power_indicator_angle, energy_indicator_angle)
                else
                    airutils.remove_hud(player)
                end
            end

            if not is_flying then
                newyaw = yaw
            end

            self.object:set_rotation({x = newpitch, y = newyaw, z = newroll})

            airutils.consumptionCalc(self, accel)

            self._last_vel = self.object:get_velocity()
            self._last_longit_speed = longit_speed
            self._yaw = newyaw
            self._roll = newroll
            self._pitch = newpitch
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
        if minetest.registered_tools["heli:heli"] then
            local tool_def = minetest.registered_tools["heli:heli"]
            local craft_def = table.copy(tool_def)
            craft_def.type = "craftitem"
            minetest.unregister_item("heli:heli")
            minetest.register_craftitem(":heli:heli", craft_def)
            minetest.log("action", "[aircraft_tweaks] Re-registered heli:heli as craftitem")
        end
        apply_helicopter_tweaks("heli:heli")
    end
end)


