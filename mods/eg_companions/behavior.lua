--[[
    Evergrowth Companions - Behavior & Schedules
    ============================================
    Handles:
    - Daily Schedule: Day (05:30-18:30) at Companion Plaque, Night (18:30-05:30) at Player Bed
    - Waypoint Pathfinding (navigate_to) with A* and auto door opening/closing
    - Accurate Bed Alignment, Mattress Offset (-0.15), and 90-degree Pitch Sleep Rotation
    - Proximity-based Nametag Culling
]]--

local S = minetest.get_translator("eg_companions")

function eg_companions.is_valid_floor(node_name)
    if not node_name or node_name == "air" or node_name == "ignore" then return false end
    local def = minetest.registered_nodes[node_name]
    if not def or not def.walkable then return false end
    if def.drawtype == "glasslike" or def.drawtype == "glasslike_framed" or def.drawtype == "nodebox" or def.drawtype == "fencelike" then
        if node_name:find("glass") or node_name:find("pane") or node_name:find("fence") or node_name:find("wall") or node_name:find("window") then
            return false
        end
    end
    if def.groups and (def.groups.fence or def.groups.wall or def.groups.pane or def.groups.window) then
        return false
    end
    if node_name:find("fence") or node_name:find("window") or node_name:find("pane") or node_name:find("wall") or node_name:find("glass") then
        return false
    end
    return true
end

function eg_companions.get_walkable_goal(target_pos, exclude_obj)
    if not target_pos then return nil end
    local rounded = {
        x = math.floor(target_pos.x + 0.5),
        y = math.floor(target_pos.y + 0.5),
        z = math.floor(target_pos.z + 0.5)
    }
    
    local offsets = {
        {x=0, y=0, z=1}, {x=0, y=0, z=-1},
        {x=1, y=0, z=0}, {x=-1, y=0, z=0},
        {x=1, y=0, z=1}, {x=-1, y=0, z=1},
        {x=1, y=0, z=-1}, {x=-1, y=0, z=-1},
        {x=0, y=1, z=1}, {x=0, y=1, z=-1},
        {x=1, y=1, z=0}, {x=-1, y=1, z=0},
        {x=0, y=-1, z=1}, {x=0, y=-1, z=-1},
        {x=1, y=-1, z=0}, {x=-1, y=-1, z=0},
    }

    local best_fallback = nil

    for _, off in ipairs(offsets) do
        local candidate = {x = rounded.x + off.x, y = rounded.y + off.y, z = rounded.z + off.z}
        local node_body = minetest.get_node(candidate)
        local node_head = minetest.get_node({x = candidate.x, y = candidate.y + 1, z = candidate.z})
        local node_floor = minetest.get_node({x = candidate.x, y = candidate.y - 1, z = candidate.z})
        
        local def_body = minetest.registered_nodes[node_body.name]
        local def_head = minetest.registered_nodes[node_head.name]

        if def_body and not def_body.walkable and
           def_head and not def_head.walkable and
           eg_companions.is_valid_floor(node_floor.name) then
            
            local objs = minetest.get_objects_inside_radius(candidate, 0.7)
            local occupied = false
            for _, obj in ipairs(objs) do
                if obj ~= exclude_obj and not obj:is_player() then
                    occupied = true
                    break
                end
            end

            if not occupied then
                return candidate
            elseif not best_fallback then
                best_fallback = candidate
            end
        end
    end

    return best_fallback or rounded
end

function eg_companions.safe_teleport(self, target_pos)
    if not target_pos or not self.object then return false end
    local goal = eg_companions.get_walkable_goal(target_pos, self.object)
    if goal then
        self.object:set_pos({x = goal.x, y = goal.y + 0.5, z = goal.z})
        self._nav_waypoints = nil
        self._nav_target_pos = nil
        self._nav_stuck_timer = 0
        return true
    end
    return false
end

function eg_companions.navigate_to(self, target_pos)
    if not target_pos or not self.object then return false end
    local current_pos = self.object:get_pos()
    if not current_pos then return false end

    local goal = eg_companions.get_walkable_goal(target_pos, self.object)
    if not goal then return false end

    if vector.distance(current_pos, goal) <= 1.5 then
        self._nav_waypoints = nil
        self._nav_target_pos = nil
        self.order = "stand"
        self:set_velocity(0)
        return true
    end

    -- Pre-open doors near start and goal so A* sees them as passable
    local nearby_doors = minetest.find_nodes_in_area(
        vector.subtract(current_pos, 10),
        vector.add(current_pos, 10),
        {"group:door", "group:gate"}
    )
    for _, dpos in ipairs(nearby_doors) do
        if minetest.get_modpath("doors") and doors.get then
            local door = doors.get(dpos)
            if door and not door:state() then
                door:open()
                self._nav_opened_doors = self._nav_opened_doors or {}
                table.insert(self._nav_opened_doors, dpos)
            end
        end
    end

    minetest.load_area(current_pos, goal)
    local path = minetest.find_path(current_pos, goal, 100, 1, 3, "A*_noprefetch")
    if path and #path > 1 then
        table.remove(path, 1) -- Remove current pos
        self._nav_waypoints = path
        self._nav_target_pos = goal
        self._nav_stuck_timer = 0
        self._nav_last_pos = current_pos
        self.order = "follow"
        return true
    else
        -- Fallback: move towards target directly with stuck timer fallback
        self._nav_waypoints = {goal}
        self._nav_target_pos = goal
        self._nav_stuck_timer = 0
        self._nav_last_pos = current_pos
        return false
    end
end

-- Helper: find player-owned bed within radius
function eg_companions.find_player_bed(pos, radius, player_name)
    radius = radius or 50
    local p1 = vector.subtract(pos, radius)
    local p2 = vector.add(pos, radius)

    local beds = minetest.find_nodes_in_area(p1, p2, {"group:bed_bottom"})
    if #beds == 0 then
        beds = minetest.find_nodes_in_area(p1, p2, {"group:bed"})
    end

    local best_bed = nil
    local min_dist = math.huge

    for _, bpos in ipairs(beds) do
        local meta = minetest.get_meta(bpos)
        local owner = meta:get_string("owner")
        local reserved = meta:get_string("player_reserved") == "true"
        local assigned_comp = meta:get_string("assigned_companion")

        local is_match = false
        if player_name and player_name ~= "" then
            if (owner == player_name or (owner == "" and reserved)) and (assigned_comp == "" or assigned_comp == nil) then
                is_match = true
            end
        elseif reserved and (assigned_comp == "" or assigned_comp == nil) then
            is_match = true
        end

        if is_match then
            local dist = vector.distance(pos, bpos)
            if dist < min_dist then
                min_dist = dist
                best_bed = bpos
            end
        end
    end

    return best_bed
end

-- Companion Entity on_step state machine
function eg_companions.on_step(self, dtime)
    local pos = self.object:get_pos()
    if not pos then return end

    -- If sleeping, lock position and rotation and bypass active companion routines
    if self._sleeping then
        if self._sleep_pos then
            self.object:set_pos(self._sleep_pos)
        end
        if self._sleep_yaw then
            self.object:set_rotation({x = math.pi / 2, y = self._sleep_yaw, z = 0})
        end
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.order = "stand"
        self:set_animation("stand")

        -- Check for morning wake-up
        local current_time = (minetest.get_timeofday() * 24000) % 24000
        local is_night = (current_time >= 19000 or current_time < 6000)
        if not is_night then
            self._sleeping = nil
            self._sleep_pos = nil
            self._sleep_yaw = nil
            self.object:set_properties({
                collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
                physical = true,
            })
            local cur_y = self.object:get_yaw() or 0
            self.object:set_rotation({x = 0, y = cur_y, z = 0})
            self.object:set_pos({x = pos.x, y = pos.y + 0.6, z = pos.z})
            self.object:set_acceleration({x = 0, y = -9.81, z = 0})
            self.order = "wander"
            self:set_animation("stand")
        end
        return true
    end

    -- 1. Nametag Distance Culling (20 blocks)
    self._nametag_timer = (self._nametag_timer or 0) + dtime
    if self._nametag_timer > 1.0 then
        self._nametag_timer = 0
        local game_name = self.game_name or self.nametag
        if game_name and game_name ~= "" then
            local visible = false
            for _, player in ipairs(minetest.get_connected_players()) do
                if vector.distance(pos, player:get_pos()) <= 20 then
                    visible = true
                    break
                end
            end
            local current_nametag = self.object:get_properties().nametag
            if visible and current_nametag == "" then
                self.object:set_properties({nametag = game_name})
            elseif not visible and current_nametag ~= "" then
                self.object:set_properties({nametag = ""})
            end
        end
    end

    -- 2. Anchor Validation (Defensive check for dug plaque or bed nodes)
    if self.plaque_pos then
        local pnode = minetest.get_node(self.plaque_pos)
        if pnode.name ~= "ignore" and pnode.name ~= "eg_companions:companion_plaque" and pnode.name ~= "eg_settlers:housing_deed" then
            self.plaque_pos = nil
        end
    end

    if self.bed_pos then
        local bnode = minetest.get_node(self.bed_pos)
        local is_bed = bnode.name ~= "ignore" and ((minetest.get_item_group(bnode.name, "bed") > 0) or bnode.name:find("bed") ~= nil)
        if bnode.name ~= "ignore" and not is_bed then
            self.bed_pos = nil
        end
    end

    -- Auto-search for player bed if unassigned/lost
    if not self.bed_pos and self.owner and self.owner ~= "" then
        self._bed_search_timer = (self._bed_search_timer or 0) + dtime
        if self._bed_search_timer >= 5.0 then
            self._bed_search_timer = 0
            local search_pos = self.plaque_pos or pos
            local found_bed = eg_companions.find_player_bed(search_pos, 50, self.owner)
            if found_bed then
                self.bed_pos = found_bed
                local bmeta = minetest.get_meta(found_bed)
                bmeta:set_string("assigned_companion", self.game_name or self.nametag or "Companion")
                if self.plaque_pos then
                    local pmeta = minetest.get_meta(self.plaque_pos)
                    if pmeta then
                        pmeta:set_string("bed_pos", minetest.pos_to_string(found_bed))
                    end
                end
            end
        end
    end

    -- 3. Waypoint Navigation Step Logic
    if self._nav_waypoints and #self._nav_waypoints > 0 then
        self._door_timer = (self._door_timer or 0) + dtime
        if self._door_timer >= 0.5 then
            self._door_timer = 0
            -- Auto-close doors left behind
            if self._nav_opened_doors then
                for idx = #self._nav_opened_doors, 1, -1 do
                    local dpos = self._nav_opened_doors[idx]
                    if vector.distance(pos, dpos) >= 2.0 then
                        if minetest.get_modpath("doors") and doors.get then
                            local door = doors.get(dpos)
                            if door and door:state() then door:close() end
                        end
                        table.remove(self._nav_opened_doors, idx)
                    end
                end
            end
        end

        local next_wp = self._nav_waypoints[1]
        local dist_to_wp = vector.distance(pos, next_wp)

        if dist_to_wp < 0.8 then
            table.remove(self._nav_waypoints, 1)
            self._nav_stuck_timer = 0
            if #self._nav_waypoints == 0 then
                self._nav_waypoints = nil
                self._nav_target_pos = nil
                self.order = "stand"
                self:set_velocity(0)
            end
        else
            -- Check stuck timer
            self._nav_stuck_timer = (self._nav_stuck_timer or 0) + dtime
            if self._nav_stuck_timer > 10.0 then
                -- Safe teleport fallback
                eg_companions.safe_teleport(self, self._nav_target_pos or next_wp)
            else
                -- Move towards waypoint
                local dir = vector.direction(pos, next_wp)
                local yaw = minetest.dir_to_yaw(dir)
                self.object:set_yaw(yaw)
                self:set_velocity(self.walk_velocity or 2)
                self:set_animation("walk")
            end
        end
        return true
    end

    -- 4. Day / Night Schedule State Machine
    local current_time = (minetest.get_timeofday() * 24000) % 24000
    local is_night = (current_time >= 19000 or current_time < 6000)

    if is_night then
        -- Night Phase: Sleep in player bed
        if self.bed_pos then
            local bed_node = minetest.get_node(self.bed_pos)
            local is_bed = (minetest.get_item_group(bed_node.name, "bed") > 0) or bed_node.name:find("bed") ~= nil
            if is_bed then
                local is_top = bed_node.name:find("_top") ~= nil
                local param2 = (bed_node.param2 or 0) % 4
                local yaw = 0
                if param2 == 1 then
                    yaw = math.pi / 2
                elseif param2 == 3 then
                    yaw = -math.pi / 2
                elseif param2 == 0 then
                    yaw = math.pi
                else
                    yaw = 0
                end
                local dir = minetest.facedir_to_dir(param2)
                local offset_mult = is_top and -0.4 or 0.4
                local sleep_pos = {
                    x = self.bed_pos.x + dir.x * offset_mult,
                    y = self.bed_pos.y + 0.12,
                    z = self.bed_pos.z + dir.z * offset_mult
                }

                if vector.distance(pos, sleep_pos) > 1.8 then
                    if not self._nav_waypoints then
                        eg_companions.navigate_to(self, self.bed_pos)
                    end
                else
                    -- Assume sleep posture
                    if not self._sleeping or vector.distance(pos, sleep_pos) > 1.8 then
                        self._sleeping = true
                        self._sleep_pos = sleep_pos
                        self._sleep_yaw = yaw
                        self.object:set_properties({
                            collisionbox = {-0.4, -0.05, -0.4, 0.4, 0.2, 0.4},
                            physical = false,
                        })
                        self.object:set_pos(sleep_pos)
                        self.object:set_rotation({x = math.pi / 2, y = yaw, z = 0})
                        self.object:set_velocity({x = 0, y = 0, z = 0})
                        self.object:set_acceleration({x = 0, y = 0, z = 0})
                        self.order = "stand"
                        self:set_animation("stand")
                    end
                    return true
                end
            end
        end
    else
        -- Day Phase: Wake up & wander near Companion Plaque
        if self._sleeping then
            self._sleeping = nil
            self.object:set_properties({
                collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
                physical = true,
            })
            local cur_y = self.object:get_yaw() or 0
            self.object:set_rotation({x = 0, y = cur_y, z = 0})
            self.object:set_pos({x = pos.x, y = pos.y + 0.6, z = pos.z})
            self.object:set_acceleration({x = 0, y = -9.81, z = 0})
            self.order = "wander"
            self:set_animation("stand")
        end

        -- Tether check to Companion Plaque
        if self.plaque_pos then
            local dist_to_plaque = vector.distance(pos, self.plaque_pos)
            if dist_to_plaque > 16 then
                if not self._nav_waypoints then
                    eg_companions.navigate_to(self, self.plaque_pos)
                end
            else
                self.order = "wander"
                self.walk_chance = 10
            end
        end
    end
end
