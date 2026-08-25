--[[
    Evergrowth Villages - NPC Behavior, Schedules & Pathfinding
    ============================================================
    This module implements:
    - Multi-phase daily schedules (Sleep, Commute, Work, Wander/Supply-Chain, Social/Tavern/Library, Patrol)
    - Waypoint-based pathfinding via minetest.find_path (with safe local wander fallback)
    - Dynamic door & gate automation (open in front, close behind)
    - Accurate bed alignment, sleep freeze, and 90-degree pitch rotation
    - Proximity nametag toggles and atmospheric greetings
    - Relocation contracts and criminal justice enforcement
]]--

local S = minetest.get_translator("eg_settlers")

local SCHEDULES = {
    default = {
        {start = 0,     stop = 6000,  phase = "sleep",  target = "home_pos"},
        {start = 6000,  stop = 17500, phase = "work",   target = "job_pos"},
        {start = 17500, stop = 19000, phase = "social", target = "job_board"},
        {start = 19000, stop = 24000, phase = "sleep",  target = "home_pos"},
    },
    guard_day = {
        {start = 0,     stop = 6000,  phase = "sleep",  target = "home_pos"},
        {start = 6000,  stop = 19000, phase = "patrol", target = "job_pos"},
        {start = 19000, stop = 24000, phase = "sleep",  target = "home_pos"},
    },
    guard_night = {
        {start = 0,     stop = 6500,  phase = "patrol", target = "job_pos"},
        {start = 6500,  stop = 17500, phase = "sleep",  target = "home_pos"},
        {start = 17500, stop = 24000, phase = "patrol", target = "job_pos"},
    },
}

function eg_settlers.is_valid_floor(node_name)
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

function eg_settlers.get_walkable_goal(target_pos, exclude_obj)
    if not target_pos then return nil end
    local rounded = {
        x = math.floor(target_pos.x + 0.5),
        y = math.floor(target_pos.y + 0.5),
        z = math.floor(target_pos.z + 0.5)
    }
    
    local target_node = minetest.get_node(rounded)
    local target_def = minetest.registered_nodes[target_node.name]
    local offset_groups = {}

    -- Primary: Facedir orientation strictly for the Town Square Job Board
    if target_node.name == "eg_settlers:job_board" then
        local front_offsets = {}
        local param2 = (target_node.param2 or 0) % 4
        local raw_dir = minetest.facedir_to_dir(param2)
        local fdir = {x = -raw_dir.x, y = 0, z = -raw_dir.z}
        local right = {x = -fdir.z, y = 0, z = fdir.x}
        
        for f = 1, 3 do
            for s = -3, 3 do
                for y_off = -1, 1 do
                    table.insert(front_offsets, {
                        x = fdir.x * f + right.x * s,
                        y = y_off,
                        z = fdir.z * f + right.z * s,
                    })
                end
            end
        end
        table.insert(offset_groups, front_offsets)
    end

    -- Priority 1: Immediate 1-block adjacent radius (keeps workers inside workshops)
    local immediate_offsets = {
        {x=0, y=0, z=1}, {x=0, y=0, z=-1},
        {x=1, y=0, z=0}, {x=-1, y=0, z=0},
        {x=1, y=0, z=1}, {x=-1, y=0, z=1},
        {x=1, y=0, z=-1}, {x=-1, y=0, z=-1},
        {x=0, y=1, z=1}, {x=0, y=1, z=-1},
        {x=1, y=1, z=0}, {x=-1, y=1, z=0},
        {x=0, y=-1, z=1}, {x=0, y=-1, z=-1},
        {x=1, y=-1, z=0}, {x=-1, y=-1, z=0},
    }
    table.insert(offset_groups, immediate_offsets)

    -- Priority 2: Outer 2-block radius (fallback only if immediate tiles are blocked)
    local outer_offsets = {
        {x=2, y=0, z=0}, {x=-2, y=0, z=0},
        {x=0, y=0, z=2}, {x=0, y=0, z=-2},
        {x=2, y=0, z=1}, {x=-2, y=0, z=1},
        {x=1, y=0, z=2}, {x=-1, y=0, z=2},
        {x=2, y=0, z=-1}, {x=-2, y=0, z=-1},
        {x=-1, y=0, z=-2}, {x=1, y=0, z=-2},
    }
    table.insert(offset_groups, outer_offsets)

    local best_fallback = nil

    for _, offsets in ipairs(offset_groups) do
        local valid_unoccupied = {}

        for _, off in ipairs(offsets) do
            local candidate = {x = rounded.x + off.x, y = rounded.y + off.y, z = rounded.z + off.z}
            local node_body = minetest.get_node(candidate)
            local node_head = minetest.get_node({x = candidate.x, y = candidate.y + 1, z = candidate.z})
            local node_floor = minetest.get_node({x = candidate.x, y = candidate.y - 1, z = candidate.z})
            
            local def_body = minetest.registered_nodes[node_body.name]
            local def_head = minetest.registered_nodes[node_head.name]

            if def_body and not def_body.walkable and
               def_head and not def_head.walkable and
               eg_settlers.is_valid_floor(node_floor.name) then
                
                -- Anti-stacking check (ensures NPCs distribute across the room)
                local objs = minetest.get_objects_inside_radius(candidate, 0.9)
                local occupied = false
                for _, obj in ipairs(objs) do
                    if obj ~= exclude_obj and not obj:is_player() then
                        occupied = true
                        break
                    end
                end

                if not occupied then
                    table.insert(valid_unoccupied, candidate)
                elseif not best_fallback then
                    best_fallback = candidate
                end
            end
        end

        if #valid_unoccupied > 0 then
            return valid_unoccupied[math.random(#valid_unoccupied)]
        end
    end

    return best_fallback or target_pos
end

function eg_settlers.get_walkable_start(pos)
    if not pos then return nil end
    local rounded = {
        x = math.floor(pos.x + 0.5),
        y = math.floor(pos.y + 0.5),
        z = math.floor(pos.z + 0.5)
    }
    local n_body = minetest.get_node(rounded)
    local d_body = minetest.registered_nodes[n_body.name]
    if d_body and d_body.walkable then
        rounded.y = rounded.y + 1
    end
    return rounded
end

function eg_settlers.safe_teleport(self, target_pos)
    if not target_pos then return false end
    local goal = eg_settlers.get_walkable_goal(target_pos, self.object)
    if goal then
        self.object:set_pos({x = goal.x, y = goal.y + 0.5, z = goal.z})
        self.order = "wander"
        self:set_animation("walk")
        return true
    end
    return false
end

function eg_settlers.get_town_square_target(self)
    local pos = (self.object and self.object:get_pos()) or self.job_pos or self.home_pos
    if not pos then return nil end

    local sid = eg_settlers.db and eg_settlers.db.find_nearest_settlement(pos, 200)
    if sid then
        local settlement = eg_settlers.db.get_settlement(sid)
        if settlement then
            return settlement.job_board_pos or settlement.ledger_pos
        end
    end
    return nil
end

function eg_settlers.navigate_to(self, target_pos)
    if not target_pos then return false end
    return eg_settlers.safe_teleport(self, target_pos)
end

local target_entities = {"mobs_npc:trader", "mobs_npc:npc"}
for _, entity_name in ipairs(target_entities) do
    local base_entity = minetest.registered_entities[entity_name]
    if base_entity then
        base_entity.water_damage = 0.001
        base_entity.suffocation = 0
        base_entity.stepheight = 1.1
        if base_entity.initial_properties then
            base_entity.initial_properties.stepheight = 1.1
        end
        base_entity.jump_height = 1.1
        base_entity.jump = true
        
        local old_on_punch = base_entity.on_punch
        base_entity.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
            if puncher then
                self.last_puncher = puncher
                self.last_punch_time = os.time()
                
                if puncher:is_player() and self.is_villager then
                    local pname = puncher:get_player_name()
                    local pos = self.object:get_pos()
                    if pos then
                        local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                        if sid then
                            local settlement = eg_settlers.db.get_settlement(sid)
                            local is_owner = settlement and (settlement.owner == pname or eg_settlers.db.is_authorized(sid, pname))
                            
                            local damage_dealt = 1
                            if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
                                damage_dealt = tool_capabilities.damage_groups.fleshy
                            end
                            local item = puncher:get_wielded_item()
                            local item_name = item:get_name()
                            local is_weapon = item_name ~= "" and (damage_dealt >= 4 or minetest.get_item_group(item_name, "weapon") > 0 or minetest.get_item_group(item_name, "sword") > 0)
                            
                            local is_warning = false
                            local result = eg_settlers.db.register_punch(sid, pname, damage_dealt, is_weapon, is_owner)
                            if result == "warning" then
                                is_warning = true
                                local msg = is_owner and
                                    S("[eg_settlers] Accidental strike forgiven by town authority.") or
                                    S("[eg_settlers] WARNING: You struck a villager! Guards are monitoring you. Repeated bare-hand strikes or weapon attacks will trigger criminal charges.")
                                minetest.chat_send_player(pname, minetest.colorize("#FFAA00", msg))
                            else
                                eg_settlers.db.record_crime(sid, pname, "assault")
                                minetest.chat_send_player(pname, minetest.colorize("#FF5555", S("[eg_settlers] You committed an assault! Pay your fine at the Town Ledger before merchants will trade with you.")))
                                
                                -- Guard Distress Alarm (35 nodes)
                                local objs = minetest.get_objects_inside_radius(pos, 35)
                                for _, obj in ipairs(objs) do
                                    local ent = obj:get_luaentity()
                                    if ent and ent.is_villager and ent.evergrowth_profession == "guard" then
                                        ent.attack = puncher
                                        ent.state = "attack"
                                    end
                                end
                            end
                            
                            -- NPC Panic Fleeing (20 nodes)
                            local panic_objs = minetest.get_objects_inside_radius(pos, 20)
                            for _, pobj in ipairs(panic_objs) do
                                local pent = pobj:get_luaentity()
                                if pent and pent.is_villager and pent.evergrowth_profession ~= "guard" then
                                    pent.state = "runaway"
                                    pent.attack = nil
                                    pent.runaway = true
                                    pent.runaway_timer = 10
                                end
                            end

                            if is_warning then
                                self.attack = nil
                                self.state = "runaway"
                                self.runaway = true
                                self.runaway_timer = 10
                            end
                        end
                    end
                end
            end
            
            local ret = nil
            if old_on_punch then
                ret = old_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
            end
            if puncher and puncher:is_player() and self.is_villager then
                local pos = self.object:get_pos()
                if pos then
                    local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                    local is_wanted = sid and eg_settlers.db.is_criminal(sid, puncher:get_player_name())
                    if not is_wanted then
                        if self.evergrowth_profession == "guard" then
                            if self.stop_attack then
                                self:stop_attack()
                            else
                                self.attack = nil
                                self.state = "stand"
                            end
                        else
                            self.attack = nil
                            self.state = "runaway"
                            self.runaway = true
                            self.runaway_timer = 10
                        end
                    end
                end
            end
            return ret
        end
        
        local old_on_die = base_entity.on_die
        base_entity.on_die = function(self, pos)
            if self.is_villager then
                pos = pos or self.object:get_pos()
                if pos then
                    local death_cause = "Environment"
                    local killer_name = "Environment"
                    
                    if self.last_puncher and self.last_puncher.get_pos and self.last_puncher:get_pos() and self.last_punch_time and (os.time() - self.last_punch_time <= 10) then
                        if self.last_puncher:is_player() then
                            death_cause = "Player"
                            killer_name = self.last_puncher:get_player_name()
                        else
                            local pent = self.last_puncher:get_luaentity()
                            death_cause = "Mob"
                            killer_name = (pent and (pent.name or pent.game_name or pent.nametag)) or "Mob"
                        end
                    end
                    
                    local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                    if sid then
                        local sname = self.game_name or self.nametag or "Settler"
                        local sprof = self.evergrowth_profession or "Settler"
                        local sskin = (self.base_texture and self.base_texture[1]) or ""
                        
                        eg_settlers.db.log_death(sid, {
                            settler_name = sname,
                            profession = sprof,
                            skin = sskin,
                            pos = pos,
                            cause = death_cause,
                            killer = killer_name,
                            status = "Unburied"
                        })
                        
                        if death_cause == "Player" and killer_name ~= "Environment" then
                            eg_settlers.db.record_crime(sid, killer_name, "murder")
                            minetest.chat_send_player(killer_name, minetest.colorize("#FF0000", S("[eg_settlers] You committed murder! A capital fine of 200 Gold Lumps has been levied at the Town Ledger.")))
                        end
                    end
                end

                if self.home_pos then
                    minetest.load_area(self.home_pos, self.home_pos)
                    eg_settlers.clear_bed_assignment(self.home_pos)
                end
                if self.job_pos then
                    minetest.load_area(self.job_pos, self.job_pos)
                    local job_meta = minetest.get_meta(self.job_pos)
                    if job_meta and job_meta:get_int("occupied") == 1 then
                        job_meta:set_int("occupied", 0)
                        job_meta:set_string("resident_name", "")
                        
                        local jnode = minetest.get_node(self.job_pos)
                        local def = minetest.registered_nodes[jnode.name]
                        if def and def.description then
                            local desc = def.description:match("([^\n]+)")
                            job_meta:set_string("infotext", desc .. " (" .. S("Vacant") .. ")")
                        end
                        
                        local sid = job_meta:get_string("settlement_id")
                        if sid and sid ~= "" then
                            eg_settlers.db.unregister_resident(sid, self.job_pos)
                        end
                    end
                end
            end
            if old_on_die then
                return old_on_die(self, pos)
            end
        end
        
        local old_on_step = base_entity.on_step
        base_entity.on_step = function(self, dtime)
            -- If sleeping, lock position and rotation and bypass mobs_redo idle routines
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
                
                -- Check for schedule wake-up
                self._schedule_timer = (self._schedule_timer or 0) + dtime
                if self._schedule_timer >= 1.0 then
                    self._schedule_timer = 0
                    local current_time = (minetest.get_timeofday() * 24000 + (self._schedule_jitter or 0)) % 24000
                    local schedule_key = "default"
                    if self.evergrowth_profession == "guard" then
                        schedule_key = (self.guard_shift == "night") and "guard_night" or "guard_day"
                    end
                    local schedule = SCHEDULES[schedule_key] or SCHEDULES.default
                    for _, entry in ipairs(schedule) do
                        if current_time >= entry.start and current_time < entry.stop then
                            if entry.phase ~= "sleep" then
                                self._sleeping = nil
                                self._sleep_pos = nil
                                self._sleep_yaw = nil
                                self.object:set_properties({
                                    collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
                                    physical = true,
                                })
                                local cur_y = self.object:get_yaw() or 0
                                self.object:set_rotation({x = 0, y = cur_y, z = 0})
                                local cur_p = self.object:get_pos()
                                if cur_p then
                                    self.object:set_pos({x = cur_p.x, y = cur_p.y + 0.6, z = cur_p.z})
                                end
                                self.object:set_acceleration({x = 0, y = -9.81, z = 0})
                                self._current_phase = entry.phase
                                local target_pos = nil
                                if entry.phase == "patrol" then
                                    target_pos = self.job_pos or self.home_pos
                                elseif entry.phase == "social" then
                                    target_pos = eg_settlers.get_town_square_target(self) or self.job_pos or self.home_pos
                                elseif entry.target then
                                    target_pos = self[entry.target]
                                end
                                self._phase_target = target_pos
                                if target_pos then
                                    eg_settlers.safe_teleport(self, target_pos)
                                end
                                self.order = "wander"
                            end
                            break
                        end
                    end
                end
                return
            end

            -- Call original logic
            if old_on_step then old_on_step(self, dtime) end

            -- Scheduled Behavior & Schedule Management
            if self.is_villager then
                local pos = self.object:get_pos()
                if pos then
                    -- Custom Nametag & Engagement Logic (evaluated once per second)
                    if self.evergrowth_nametag_mode then
                        self._behavior_timer = (self._behavior_timer or 0) + dtime
                        if self._behavior_timer > 1.0 then
                            self._behavior_timer = 0
                            
                            if not self.game_name or self.game_name == "" then
                                local props = self.object:get_properties()
                                if props.nametag and props.nametag ~= "" then
                                    self.game_name = props.nametag
                                end
                            end

                            local limit = 20
                            local interact_limit = 5
                            local visible = false
                            local interacting_player = nil
                            
                            local players = minetest.get_connected_players()
                            for _, player in ipairs(players) do
                                local p_pos = player:get_pos()
                                local dist = vector.distance(pos, p_pos)
                                
                                if dist <= limit then
                                    visible = true
                                    if dist <= interact_limit then
                                        interacting_player = player
                                        break
                                    end
                                end
                            end
                            
                            -- Toggle nametag
                            local current_nametag = self.object:get_properties().nametag
                            if visible and current_nametag == "" then
                                self.object:set_properties({nametag = self.game_name})
                            elseif not visible and current_nametag ~= "" then
                                self.object:set_properties({nametag = ""})
                            end
                            
                            -- Defensive anchor check
                            if self.job_pos then
                                local jnode = minetest.get_node(self.job_pos)
                                if jnode.name ~= "ignore" and minetest.get_item_group(jnode.name, "job_block") == 0 then
                                    self.job_pos = nil
                                end
                            end

                            if self.home_pos then
                                local hnode = minetest.get_node(self.home_pos)
                                local hmeta = minetest.get_meta(self.home_pos)
                                local is_bed = hnode.name ~= "ignore" and minetest.get_item_group(hnode.name, "bed") > 0
                                local is_reserved = hmeta and hmeta:get_string("player_reserved") == "true"
                                
                                if (hnode.name ~= "ignore" and not is_bed) or is_reserved then
                                    if is_bed and is_reserved then
                                        eg_settlers.clear_bed_assignment(self.home_pos)
                                    end
                                    self.home_pos = nil
                                end
                            end
                            
                            -- Auto-search for unassigned bed if homeless
                            if not self.home_pos then
                                self._bed_search_timer = (self._bed_search_timer or 0) + 1.0
                                if self._bed_search_timer >= 5.0 then
                                    self._bed_search_timer = 0
                                    local search_pos = self.job_pos or pos
                                    local unassigned_bed = eg_settlers.find_unassigned_bed(search_pos, 50)
                                    if unassigned_bed then
                                        self.home_pos = unassigned_bed
                                        local settler_name = self.nametag or self.game_name or (self.evergrowth_profession and self.evergrowth_profession:gsub("^%l", string.upper)) or "Settler"
                                        eg_settlers.assign_bed(unassigned_bed, settler_name)
                                        
                                        if self.job_pos then
                                            local jmeta = minetest.get_meta(self.job_pos)
                                            if jmeta then
                                                jmeta:set_string("home_pos", minetest.pos_to_string(unassigned_bed))
                                            end
                                        end
                                    end
                                end
                            end
                            
                            -- Schedule evaluation
                            self._schedule_jitter = self._schedule_jitter or math.random(-200, 200)
                            local current_time = (minetest.get_timeofday() * 24000 + self._schedule_jitter) % 24000
                            local schedule_key = "default"
                            if self.evergrowth_profession == "guard" then
                                schedule_key = (self.guard_shift == "night") and "guard_night" or "guard_day"
                            end
                            local schedule = SCHEDULES[schedule_key] or SCHEDULES.default
                            
                            local new_entry = nil
                            for _, entry in ipairs(schedule) do
                                if current_time >= entry.start and current_time < entry.stop then
                                    new_entry = entry
                                    break
                                end
                            end

                            if self.evergrowth_profession == "guard" and self.attack and self.attack:get_pos() and self.attack:is_player() then
                                local target_name = self.attack:get_player_name()
                                local check_pos = pos or self.job_pos or self.home_pos
                                local sid = check_pos and eg_settlers.db.find_nearest_settlement(check_pos, 200)
                                local is_wanted = sid and eg_settlers.db.is_criminal(sid, target_name)
                                if not is_wanted then
                                    if self.stop_attack then
                                        self:stop_attack()
                                    else
                                        self.attack = nil
                                        self.state = "stand"
                                    end
                                end
                            end

                            local is_fighting = (self.evergrowth_profession == "guard" and self.attack and self.attack:get_pos() ~= nil)

                            if new_entry and not is_fighting then
                                -- Schedule phase transition
                                if new_entry.phase ~= self._current_phase then
                                    if self._sleeping and new_entry.phase ~= "sleep" then
                                        self._sleeping = nil
                                        self._sleep_pos = nil
                                        self._sleep_yaw = nil
                                        self.object:set_properties({
                                            collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
                                            physical = true,
                                        })
                                        local cur_y = self.object:get_yaw() or 0
                                        self.object:set_rotation({x = 0, y = cur_y, z = 0})
                                        local cur_p = self.object:get_pos()
                                        if cur_p then
                                            self.object:set_pos({x = cur_p.x, y = cur_p.y + 0.6, z = cur_p.z})
                                        end
                                        self.object:set_acceleration({x = 0, y = -9.81, z = 0})
                                    end

                                    self._current_phase = new_entry.phase
                                    
                                    if new_entry.phase == "social" then
                                        local visit_pos = eg_settlers.get_town_square_target(self) or self.job_pos or self.home_pos
                                        self._phase_target = visit_pos
                                        if visit_pos then
                                            eg_settlers.safe_teleport(self, visit_pos)
                                        end
                                        self.order = "wander"
                                    elseif new_entry.phase == "patrol" then
                                        local guard_target = self.job_pos or self.home_pos
                                        self._phase_target = guard_target
                                        if guard_target then
                                            eg_settlers.safe_teleport(self, guard_target)
                                        end
                                        self.order = "wander"
                                    elseif new_entry.phase == "work" or new_entry.phase == "commute" then
                                        local work_target = self.job_pos or self.home_pos
                                        self._phase_target = work_target
                                        if work_target then
                                            eg_settlers.safe_teleport(self, work_target)
                                        end
                                        self.order = "wander"
                                    elseif new_entry.phase == "sleep" then
                                        local bed_pos = self.home_pos or self.job_pos
                                        if bed_pos then
                                            local bed_node = minetest.get_node(bed_pos)
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
                                                    x = bed_pos.x + dir.x * offset_mult,
                                                    y = bed_pos.y + 0.12,
                                                    z = bed_pos.z + dir.z * offset_mult
                                                }
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
                                                if self.stop_attack then self:stop_attack() end
                                                local anim = self.animation or {}
                                                self.object:set_animation({
                                                    x = anim.stand_start or 0,
                                                    y = anim.stand_end or 79
                                                }, 6, 0, true)
                                            else
                                                eg_settlers.safe_teleport(self, bed_pos)
                                                self.order = "stand"
                                                if self.stop_attack then self:stop_attack() end
                                                self:set_animation("stand")
                                                self:set_velocity(0)
                                            end
                                        end
                                    end
                                else
                                    -- Continuous Tether / Workstation check (keeps NPC in active zone)
                                    if self._current_phase == "sleep" then
                                        local bed_pos = self.home_pos or self.job_pos
                                        if bed_pos then
                                            local bed_node = minetest.get_node(bed_pos)
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
                                                    x = bed_pos.x + dir.x * offset_mult,
                                                    y = bed_pos.y + 0.12,
                                                    z = bed_pos.z + dir.z * offset_mult
                                                }

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
                                                    if self.stop_attack then self:stop_attack() end
                                                    local anim = self.animation or {}
                                                    self.object:set_animation({
                                                        x = anim.stand_start or 0,
                                                        y = anim.stand_end or 79
                                                    }, 6, 0, true)
                                                end
                                            end
                                        end
                                    elseif self._current_phase == "work" or self._current_phase == "commute" then
                                        local work_target = self._phase_target or self.job_pos or self.home_pos
                                        if work_target and vector.distance(pos, work_target) > 16 then
                                            self:yaw_to_pos(work_target)
                                            self:set_velocity(self.walk_velocity or 2)
                                            self:set_animation("walk")
                                        end
                                    elseif self._current_phase == "patrol" then
                                        local guard_target = self._phase_target or self.job_pos or self.home_pos
                                        if guard_target and vector.distance(pos, guard_target) > 45 then
                                            self:yaw_to_pos(guard_target)
                                            self:set_velocity(self.walk_velocity or 2)
                                            self:set_animation("walk")
                                        end
                                    elseif self._current_phase == "social" then
                                        local visit_pos = self._phase_target or self.job_pos or self.home_pos
                                        if visit_pos and vector.distance(pos, visit_pos) > 25 then
                                            self:yaw_to_pos(visit_pos)
                                            self:set_velocity(self.walk_velocity or 2)
                                            self:set_animation("walk")
                                        end
                                    end
                                end
                            end

                                -- Ice Avoidance Check (Prevent wandering onto frozen rivers)
                                local yaw = self.object:get_yaw() or 0
                                local dir_x = -math.sin(yaw)
                                local dir_z = math.cos(yaw)
                                local under_node = minetest.get_node({x = math.floor(pos.x + 0.5), y = math.floor(pos.y - 1.25), z = math.floor(pos.z + 0.5)})
                                local ahead_under = minetest.get_node({x = math.floor(pos.x + dir_x * 1.2 + 0.5), y = math.floor(pos.y - 1.25), z = math.floor(pos.z + dir_z * 1.2 + 0.5)})

                                local is_ice_node = function(nodename)
                                    if not nodename or nodename == "air" or nodename == "ignore" then return false end
                                    local def = minetest.registered_nodes[nodename]
                                    if def and def.groups and (def.groups.ice or def.groups.melts) then
                                        return true
                                    end
                                    return nodename == "regional_weather:ice" or nodename == "ethereal:thin_ice" or nodename == "default:ice" or nodename:find("ice") ~= nil
                                end

                                if is_ice_node(under_node.name) or is_ice_node(ahead_under.name) then
                                    local retreat_target = self.job_pos or self.home_pos
                                    if retreat_target then
                                        self:yaw_to_pos(retreat_target)
                                    else
                                        self:set_yaw(yaw + math.pi, 8)
                                    end
                                    self:set_velocity(self.walk_velocity or 2)
                                    self:set_animation("walk")
                                end

                            -- Player Interaction (Look & Greet)
                            if interacting_player and self._current_phase ~= "sleep" then
                                if self.state == "stand" or self.state == "wander" then
                                    self:yaw_to_pos(interacting_player:get_pos())
                                end
                                
                                self._greet_timer = (self._greet_timer or 0) + 1.0
                                if self._greet_timer > 120 then
                                    self._greet_timer = 0
                                    local greetings = {"Hello there.", "Good day.", "Greetings."}
                                    local msg = greetings[math.random(#greetings)]
                                    local name = interacting_player:get_player_name()
                                    minetest.chat_send_player(name, "<" .. self.game_name .. "> " .. msg)
                                end
                            end
                        end
                    end
                end
            end
        end

        local old_on_activate = base_entity.on_activate
        base_entity.on_activate = function(self, staticdata, dtime)
            if old_on_activate then old_on_activate(self, staticdata, dtime) end

            if self.is_villager then
                self.jump_height = 4
                self.jump = true
                self.object:set_properties({stepheight = 1.1})
                self.evergrowth_nametag_mode = true
                if not self.game_name or self.game_name == "" then
                    if self.nametag and self.nametag ~= "" then
                        self.game_name = self.nametag
                    end
                end
                if self.game_name then
                    self.nametag = self.game_name
                end

                -- Fast Catch-Up on MapBlock / Chunk Activation
                if dtime and dtime > 0 then
                    self._schedule_jitter = self._schedule_jitter or math.random(-200, 200)
                    local current_time = (minetest.get_timeofday() * 24000 + self._schedule_jitter) % 24000
                    local schedule_key = "default"
                    if self.evergrowth_profession == "guard" then
                        schedule_key = (self.guard_shift == "night") and "guard_night" or "guard_day"
                    end
                    local schedule = SCHEDULES[schedule_key] or SCHEDULES.default
                    
                    for _, entry in ipairs(schedule) do
                        if current_time >= entry.start and current_time < entry.stop then
                            self._current_phase = entry.phase
                            local target_pos = entry.target and self[entry.target]
                            if target_pos then
                                if entry.phase == "sleep" then
                                    local bed_node = minetest.get_node(target_pos)
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
                                            x = target_pos.x + dir.x * offset_mult,
                                            y = target_pos.y + 0.12,
                                            z = target_pos.z + dir.z * offset_mult
                                        }
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
                                        local anim = self.animation or {}
                                        self.object:set_animation({
                                            x = anim.stand_start or 0,
                                            y = anim.stand_end or 79
                                        }, 6, 0, true)
                                    else
                                        eg_settlers.safe_teleport(self, target_pos)
                                    end
                                else
                                    self.object:set_rotation({x = 0, y = self.object:get_yaw() or 0, z = 0})
                                    eg_settlers.safe_teleport(self, target_pos)
                                end
                            end
                            break
                        end
                    end
                    self._nav_waypoints = nil
                    self._nav_state = "arrived"
                end
            end

            if self.base_texture then
                self.object:set_properties({textures = self.base_texture, stepheight = 1.1})
            else
                self.object:set_properties({stepheight = 1.1})
            end

            if self.evergrowth_profession == "guard" then
                self.hp_max = 50
                self.object:set_properties({hp_max = 50})

                if not self.health or self.health <= 0 or self.health == 20 or self.health > 50 then
                    self.health = 50
                end
                self.object:set_hp(self.health)
                self.old_health = self.health

                local ntag = self.game_name or self.nametag or ""
                if ntag:find("Day Guard") then
                    self.guard_shift = "day"
                elseif ntag:find("Night Guard") then
                    self.guard_shift = "night"
                else
                    local jmeta = self.job_pos and minetest.get_meta(self.job_pos)
                    local s = jmeta and jmeta:get_string("guard_shift")
                    if s and s ~= "" then
                        self.guard_shift = s
                    else
                        self.guard_shift = "day"
                    end
                end

                local jmeta = self.job_pos and minetest.get_meta(self.job_pos)
                if jmeta then
                    jmeta:set_string("guard_shift", self.guard_shift)
                    local shift_title = self.guard_shift == "night" and S("Night Shift") or S("Day Shift")
                    local rname = self.nametag or self.game_name or "Guard"
                    jmeta:set_string("infotext", S("Workstation: Guard") .. " (" .. shift_title .. ")\n" .. S("Resident: ") .. rname)
                end
            end
        end

        local old_on_rightclick = base_entity.on_rightclick
        base_entity.on_rightclick = function(self, clicker)
            if clicker and clicker:is_player() then
                local name = clicker:get_player_name()
                
                if self._sleeping or self._current_phase == "sleep" then
                    minetest.chat_send_player(name, S("This settler is sleeping."))
                    return
                end
                
                if clicker:get_player_control().sneak then
                    if self.is_villager then
                        local allowed = false
                        if self.home_pos then
                            local db_sid = eg_settlers.db.get_settlement_by_deed(self.home_pos)
                            if db_sid then
                                allowed = eg_settlers.db.is_authorized(db_sid, name)
                            else
                                if minetest.get_node_or_nil(self.home_pos) then
                                    local deed_meta = minetest.get_meta(self.home_pos)
                                    local owner = deed_meta:get_string("owner")
                                    allowed = (owner == "" or owner == name or minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer())
                                else
                                    minetest.chat_send_player(name, minetest.colorize("#FF0000", S("Cannot relocate villager: home area is unloaded.")))
                                    return
                                end
                            end
                        else
                            allowed = minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer()
                        end

                        if not allowed then
                            minetest.chat_send_player(name, minetest.colorize("#FF0000", S("Only the town owner or associates can relocate this villager.")))
                            return
                        end

                        local contract = ItemStack("eg_settlers:contract_villager_relocation")
                        local meta = contract:get_meta()
                        local rname = self.nametag or self.game_name or "Settler"
                        local prof = self.evergrowth_profession or "merchant"
                        local hp = self.health or (prof == "guard" and 50 or 20)
                        if prof == "guard" and (hp <= 0 or hp == 20 or hp > 50) then
                            hp = 50
                        end

                        meta:set_string("resident_name", rname)
                        meta:set_string("profession", prof)
                        meta:set_string("texture", (self.base_texture and self.base_texture[1]) or "mobs_trader.png")
                        meta:set_int("health", hp)
                        if self.guard_shift then
                            meta:set_string("guard_shift", self.guard_shift)
                        end
                        if self.trades then
                            meta:set_string("trades", minetest.serialize(self.trades))
                        end

                        local desc = contract:get_definition().description
                        local formatted_prof = prof:gsub("^%l", string.upper)
                        if prof == "guard" and self.guard_shift then
                            local shift_label = self.guard_shift == "night" and S("Night Guard") or S("Day Guard")
                            meta:set_string("description", desc .. "\n" .. S("Name: ") .. rname .. "\n" .. S("Profession: ") .. shift_label .. "\n" .. S("Health: ") .. tostring(hp))
                        else
                            meta:set_string("description", desc .. "\n" .. S("Name: ") .. rname .. "\n" .. S("Profession: ") .. formatted_prof .. "\n" .. S("Health: ") .. tostring(hp))
                        end

                        if self.home_pos then
                            minetest.load_area(self.home_pos, self.home_pos)
                            eg_settlers.clear_bed_assignment(self.home_pos)
                        end
                        if self.job_pos then
                            minetest.load_area(self.job_pos, self.job_pos)
                            local job_meta = minetest.get_meta(self.job_pos)
                            if job_meta and job_meta:get_int("occupied") == 1 then
                                job_meta:set_int("occupied", 0)
                                job_meta:set_string("resident_name", "")
                                
                                local jnode = minetest.get_node(self.job_pos)
                                local def = minetest.registered_nodes[jnode.name]
                                if def and def.description then
                                    local desc = def.description:match("([^\n]+)")
                                    job_meta:set_string("infotext", desc .. " (" .. S("Vacant") .. ")")
                                end
                                
                                local sid = job_meta:get_string("settlement_id")
                                if sid and sid ~= "" then
                                    eg_settlers.db.unregister_resident(sid, self.job_pos)
                                end
                            end
                        end

                        local inv = clicker:get_inventory()
                        if inv:room_for_item("main", contract) then
                            inv:add_item("main", contract)
                        else
                            minetest.add_item(clicker:get_pos(), contract)
                        end

                        self.object:remove()
                        minetest.chat_send_player(name, S("[eg_settlers] Settler relocated to contract."))
                        return
                    else
                        if minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then
                            self.object:remove()
                            minetest.chat_send_player(name, "[eg_settlers] Trader removed safely.")
                            return
                        end
                    end
                else
                    if self.is_villager then
                        local sid = nil
                        if self.home_pos then
                            local deed_meta = minetest.get_meta(self.home_pos)
                            local s = deed_meta:get_string("settlement_id")
                            if s and s ~= "" then sid = s end
                        end
                        if not sid and self.job_pos then
                            local job_meta = minetest.get_meta(self.job_pos)
                            local s = job_meta:get_string("settlement_id")
                            if s and s ~= "" then sid = s end
                        end
                        if not sid then
                            local pos = self.object:get_pos()
                            if pos then
                                sid = eg_settlers.db.find_nearest_settlement(pos, 200)
                            end
                        end
                        
                        if sid and eg_settlers.db.is_criminal(sid, name) then
                            local days_rem, mins_rem = eg_settlers.db.get_decay_time_estimate(sid, name)
                            local msg = S("Criminals are not welcome in this settlement! Pay your fines at the Town Ledger before trading.")
                            if days_rem > 0 then
                                msg = msg .. " " .. string.format(S("(Assault decay in ~%d in-game days / ~%dm)"), days_rem, mins_rem)
                            elseif mins_rem > 0 then
                                msg = msg .. " " .. string.format(S("(Assault decay in ~%dm)"), mins_rem)
                            end
                            minetest.chat_send_player(name, minetest.colorize("#FF0000", msg))
                            return
                        end

                        local can_trade = false
                        if sid then
                            local settlement = eg_settlers.db.get_settlement(sid)
                            if settlement and settlement.satiated == 1 then
                                can_trade = true
                            end
                        end
                        
                        if not can_trade then
                            local msg = S("The town is starving. I have nothing to trade.")
                            minetest.chat_send_player(name, minetest.colorize("#FF8888", msg))
                            return
                        end
                    end
                end
            end
            if old_on_rightclick then
                return old_on_rightclick(self, clicker)
            end
        end
    end
end
