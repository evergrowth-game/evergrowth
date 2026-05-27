
automobiles_lib.vector_up = vector.new(0, 1, 0)

function automobiles_lib.get_speed_factor(obj)
local pos_below = obj:get_pos()
if not pos_below then return 1.0 end
pos_below.y = pos_below.y - 0.1
local node_below = core.get_node(pos_below).name
if node_below:find("autobahn:node") then
return 1.5
end
return 1.0
end

function automobiles_lib.control(self, dtime, hull_direction, longit_speed, longit_drag, later_drag, accel, max_acc_factor, max_speed, steering_limit, steering_speed)
    self._last_time_command = self._last_time_command + dtime
    hull_direction = hull_direction or 0
    longit_speed = longit_speed or 0
    longit_drag = longit_drag or 0
    later_drag = later_drag or 0
    max_acc_factor = max_acc_factor or 0

    max_speed = max_speed or 0

    steering_limit = steering_limit or 0
    steering_speed = steering_speed or 0

    if self._last_time_command > 1 then self._last_time_command = 1 end

    local player = core.get_player_by_name(self.driver_name)
    local retval_accel = accel;
    local stop = false
    
    -- player control
    if player then
        local ctrl = player:get_player_control()
        local rot_x = player:get_look_vertical()
        local pi = math.pi
        local ang_min = -pi / 32
        local ang_max = pi / 64
        local gap = pi / 128

        if self._one_hand == true then
            if rot_x < (ang_min - gap)then 
                player:set_look_vertical(ang_min - gap)
            end
            if rot_x > (ang_max + gap) then
                player:set_look_vertical(ang_max + gap)
            end
        end
                
        local acc = 0
        if self._energy > 0 then
            if self._one_hand == true then
                if rot_x <= ang_min then
                    if longit_speed < max_speed then
                        --get acceleration factor
                        acc = automobiles_lib.check_road_is_ok(self.object, max_acc_factor)
                        if acc > 1 and acc < max_acc_factor and longit_speed > 0 then
                            --improper road will reduce speed
                            acc = -1
                        end
                    end
                end
            else
                local speed_factor = automobiles_lib.get_speed_factor(self.object)
                local effective_max_speed = max_speed * speed_factor

                if longit_speed < effective_max_speed and ctrl.up then
                    --get acceleration factor
                    acc = automobiles_lib.check_road_is_ok(self.object, max_acc_factor)
                    if acc > 1 and acc < max_acc_factor and longit_speed > 0 then
                        --improper road will reduce speed
                        acc = -1
                    end
                end
            end


            --reversing
            if self._one_hand == true then
                if rot_x >= ang_max then
                    acc = -2
                end
            else
                if ctrl.sneak and longit_speed <= 1.0 and longit_speed > -1.0 then
                    acc = -2
                end
            end
        end

        --break
        if self._one_hand == true then
            if rot_x >= ang_max and not ctrl.LMB then
                if longit_speed > 0 then
                    acc = -5
                end
                if longit_speed < 0 then
                    acc = 5
                    if (longit_speed + acc) > 0 then
                        acc = longit_speed * -1
                    end
                end
                if math.abs(longit_speed) < 1 then
                    stop = true
                end
            end
        else
            if ctrl.down or ctrl.jump then
                --total stop
                --wheel break
                if longit_speed > 0 then
                    acc = -5
                end
                if longit_speed < 0 then
                    acc = 5
                    if (longit_speed + acc) > 0 then
                        acc = longit_speed * -1
                    end
                end
                if math.abs(longit_speed) < 1 then
                    stop = true
                end
            end
        end

        if acc then retval_accel=vector.add(accel,vector.multiply(hull_direction,acc)) end

        if ctrl.aux1 then
            if self._one_hand == true then
                local formspec_f = automobiles_lib.driver_formspec
                if self._formspec_function then formspec_f = self._formspec_function end
                formspec_f(self.driver_name)
            end
        end

        -- yaw
        local yaw_cmd = 0
        if self._yaw_by_mouse == true or self._one_hand == true then
            local rot_y = math.deg(player:get_look_horizontal())
            self._steering_angle = automobiles_lib.set_yaw_by_mouse(self, rot_y, steering_limit)
        else
            -- steering
            if ctrl.right then
                self._steering_angle = math.max(self._steering_angle-steering_speed*dtime,-steering_limit)
            elseif ctrl.left then
                self._steering_angle = math.min(self._steering_angle+steering_speed*dtime,steering_limit)
            else
                --center steering
                local abs_speed = math.abs(longit_speed)
                local factor = 1
                if self._steering_angle > 0 then factor = -1 end
                
                -- smooth centering dependent on time, not frames
                -- centering speed increases with car speed, but has a minimum base value
                local centering_speed = (steering_limit * (abs_speed / 15)) + 20
                local correction = centering_speed * dtime * factor
                
                local before_correction = self._steering_angle
                self._steering_angle = self._steering_angle + correction
                if math.sign(before_correction) ~= math.sign(self._steering_angle) then self._steering_angle = 0 end
            end
        end

        local angle_factor = self._steering_angle / 60
        if angle_factor < 0 then angle_factor = angle_factor * -1 end
        local deacc_on_curve = longit_speed * angle_factor
        deacc_on_curve = deacc_on_curve * -1
        if deacc_on_curve then retval_accel=vector.add(retval_accel,vector.multiply(hull_direction,deacc_on_curve)) end
    
    end

    return retval_accel, stop
end
