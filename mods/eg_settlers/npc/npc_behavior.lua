--[[
    Evergrowth Villages - NPC Behavior & Engagement
    ===============================================
    This module overrides the `on_step` function of the base `mobs_npc:trader` 
    entity. It implements a player-distance check to selectively show or hide 
    nametags, reducing screen clutter when the player is far away.
    
    If the entity possesses the `is_settler` flag (spawned naturally in a settlement),
    it also injects dynamic engagement behaviors:
    - Look at nearby players (yaw_to_pos)
    - Day/Night schedules (return home to sleep)
    - Atmospheric greetings
]]--

local S = minetest.get_translator("eg_settlers")

local target_entities = {"mobs_npc:trader", "mobs_npc:npc"}
for _, entity_name in ipairs(target_entities) do
    local base_entity = minetest.registered_entities[entity_name]
    if base_entity then
        -- Triggers mobs_redo pathfinding to avoid water as a hazard (>0) while taking negligible damage if they fall in
        base_entity.water_damage = 0.001
        -- Stepheight 1.1 allows walking up natural 1.0 terrain ledges, dirt banks, and steps (tall fences at 1.375 height block fence climbing)
        base_entity.stepheight = 1.1
        if base_entity.initial_properties then
            base_entity.initial_properties.stepheight = 1.1
        end
        -- Jump height 4 (vertical velocity 4 m/s, ~0.8m jump) allows jumping out of water and single-block ledges, while mobs_redo blocks fence jumps
        base_entity.jump_height = 4
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
                    if sid then
                        local rec = eg_settlers.db.get_criminal_record(sid, puncher:get_player_name())
                        if not rec or not rec.assault_count or rec.assault_count <= 0 then
                            self.attack = nil
                            if self.evergrowth_profession ~= "guard" then
                                self.state = "runaway"
                                self.runaway = true
                                self.runaway_timer = 10
                            end
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
                    local hnode = minetest.get_node(self.home_pos)
                    if hnode.name == "eg_settlers:housing_deed" then
                        -- Housing deed: clear deed-specific metadata
                        local dmeta = minetest.get_meta(self.home_pos)
                        dmeta:set_int("occupied", 0)
                        dmeta:set_string("resident_name", "")
                        dmeta:set_string("infotext", S("Housing Deed (Companion Deed Only)"))
                        local deed_sid = dmeta:get_string("settlement_id")
                        if deed_sid and deed_sid ~= "" then
                            eg_settlers.db.unregister_resident(deed_sid, self.home_pos)
                        end
                    else
                        -- Bed: clear bed-specific metadata
                        eg_settlers.clear_bed_assignment(self.home_pos)
                    end
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
        -- Call original logic
        if old_on_step then old_on_step(self, dtime) end

        --[[ FUTURE: Fast Path Following (disabled - pathfinding cannot navigate doors)
        -- Dynamically enable pathfinding for existing entities
        if self.is_villager and (not self.pathfinding or self.pathfinding == 0) then
            self.pathfinding = 1
        end

        -- Fast Path Following for Settlers returning to job blocks (Daytime)
        if self.is_villager and self.order == "go_home" then
            local pos = self.object:get_pos()
            if pos then
                if self._cached_is_night == false and self._cached_day_target then
                    local day_target = self._cached_day_target
                    local move_target = nil
                    if self.path and self.path.way and #self.path.way > 0 then
                        local p1 = self.path.way[1]
                        if p1 and math.abs(p1.x - pos.x) + math.abs(p1.z - pos.z) < 0.6 then
                            table.remove(self.path.way, 1)
                            p1 = self.path.way[1]
                        end
                        if p1 then
                            move_target = {x = p1.x, y = p1.y, z = p1.z}
                        end
                    else
                        local head_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
                        local target_head = {x = day_target.x, y = day_target.y + 1, z = day_target.z}
                        if minetest.line_of_sight(head_pos, target_head) then
                            move_target = day_target
                        end
                    end
                    
                    if move_target then
                        self:yaw_to_pos(move_target)
                        self:set_velocity(self.walk_velocity)
                        if move_target.y > pos.y + 0.5 then
                            local v = self.object:get_velocity()
                            if v.y <= 0.1 then
                                self.object:set_velocity({x = v.x, y = 5, z = v.z})
                            end
                        end
                    end
                end
            end
        end
        ]]

        -- Custom Nametag & Engagement Logic (Only if flag is set)
        if self.evergrowth_nametag_mode then
            self._behavior_timer = (self._behavior_timer or 0) + dtime
            if self._behavior_timer > 1.0 then
                self._behavior_timer = 0
                
                -- Ensure we have the name stored (from spawn time)
                if not self.game_name or self.game_name == "" then
                    -- Try to recover from properties if visible
                    local props = self.object:get_properties()
                    if props.nametag and props.nametag ~= "" then
                        self.game_name = props.nametag
                    end
                end

                if self.game_name then
                    local pos = self.object:get_pos()
                    if not pos then return end 

                    local limit = 20          -- Nametag Visibility distance
                    local interact_limit = 5  -- Distance to interact (look/greet)
                    local visible = false
                    local interacting_player = nil
                    
                    -- Check connected players
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
                    
                    -- 1. Toggle nametag
                    local current_nametag = self.object:get_properties().nametag
                    if visible and current_nametag == "" then
                         self.object:set_properties({nametag = self.game_name})
                    elseif not visible and current_nametag ~= "" then
                         self.object:set_properties({nametag = ""})
                    end
                    
                    -- 2. Schedule & Engagement Logic (Settlers Only)
                    if self.is_villager then
                        local current_time = minetest.get_timeofday() * 24000
                        local is_night = (current_time > 18500 or current_time < 4500) and self.evergrowth_profession ~= "guard"
                        
                        --[[ FUTURE: Cache variables for fast path-following loop
                        self._cached_is_night = is_night
                        self._cached_day_target = self.job_pos or self.home_pos
                        ]]
                        
                        -- Defensive check: verify Job Block / Deed still exists
                        if self.job_pos then
                            local jnode = minetest.get_node(self.job_pos)
                            if jnode.name ~= "ignore" and minetest.get_item_group(jnode.name, "job_block") == 0 and jnode.name ~= "eg_settlers:housing_deed" then
                                self.job_pos = nil
                            end
                        end

                        if self.home_pos then
                            local hnode = minetest.get_node(self.home_pos)
                            local hmeta = minetest.get_meta(self.home_pos)
                            local is_bed = hnode.name ~= "ignore" and minetest.get_item_group(hnode.name, "bed") > 0
                            local is_deed = hnode.name == "eg_settlers:housing_deed"
                            local is_reserved = hmeta and hmeta:get_string("player_reserved") == "true"
                            
                            if (hnode.name ~= "ignore" and not is_bed and not is_deed) or is_reserved then
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
                        
                        -- Schedule: Nighttime return home bed shelter, Daytime active at job workstation
                        if is_night then
                            self._was_night = true
                            local night_target = self.home_pos or self.job_pos
                            if night_target then
                                local dist_home = vector.distance(pos, night_target)
                                if dist_home > 3 then
                                    -- Teleport safely by finding an elevated non-solid coordinate above/adjacent to bed
                                    local dest = {x = night_target.x, y = night_target.y + 0.5, z = night_target.z}
                                    local offsets = {
                                        {x=0, y=0.5, z=0},
                                        {x=0, y=1.0, z=0},
                                        {x=0, y=0.5, z=1}, {x=0, y=0.5, z=-1},
                                        {x=1, y=0.5, z=0}, {x=-1, y=0.5, z=0},
                                    }
                                    
                                    for _, off in ipairs(offsets) do
                                        local test_pos = {x = night_target.x + off.x, y = night_target.y + off.y, z = night_target.z + off.z}
                                        local head_pos = {x = test_pos.x, y = test_pos.y + 1, z = test_pos.z}
                                        
                                        local node1 = minetest.get_node(test_pos)
                                        local node2 = minetest.get_node(head_pos)
                                        
                                        local def1 = minetest.registered_nodes[node1.name]
                                        local def2 = minetest.registered_nodes[node2.name]
                                        
                                        if def1 and not def1.walkable and def2 and not def2.walkable then
                                            dest = test_pos
                                            break
                                        end
                                    end
                                    
                                    self.object:set_pos(dest)
                                    self.order = "stand"
                                    if self.stop_attack then self:stop_attack() end
                                    self:set_animation("stand")
                                    self:set_velocity(0)
                                else
                                    -- Arrived at bed shelter
                                    if self.order ~= "stand" then
                                        self.order = "stand"
                                        if self.stop_attack then self:stop_attack() end
                                        self:set_animation("stand")
                                        self:set_velocity(0)
                                    end
                                end
                            else
                                self.order = "stand"
                            end
                        else
                            -- Daytime
                            
                            -- Sunrise teleport: on night→day transition, teleport to job block
                            if self._was_night and not is_night then
                                local day_target = self.job_pos or self.home_pos
                                if day_target then
                                    local dest = {x = day_target.x, y = day_target.y + 0.5, z = day_target.z}
                                    local offsets = {
                                        {x=0, y=0.5, z=0}, {x=0, y=1.0, z=0},
                                        {x=0, y=0.5, z=1}, {x=0, y=0.5, z=-1},
                                        {x=1, y=0.5, z=0}, {x=-1, y=0.5, z=0},
                                        {x=0, y=-0.5, z=1}, {x=0, y=-0.5, z=-1},
                                        {x=1, y=-0.5, z=0}, {x=-1, y=-0.5, z=0},
                                    }
                                    for _, off in ipairs(offsets) do
                                        local test_pos = {x = day_target.x + off.x, y = day_target.y + off.y, z = day_target.z + off.z}
                                        local test_head = {x = test_pos.x, y = test_pos.y + 1, z = test_pos.z}
                                        local node1 = minetest.get_node(test_pos)
                                        local node2 = minetest.get_node(test_head)
                                        local def1 = minetest.registered_nodes[node1.name]
                                        local def2 = minetest.registered_nodes[node2.name]
                                        if def1 and not def1.walkable and def2 and not def2.walkable then
                                            dest = test_pos
                                            break
                                        end
                                    end
                                    
                                    -- Verify destination is safe by explicitly rounding
                                    local check_y = math.floor(dest.y + 0.5)
                                    local d_pos1 = {x = dest.x, y = check_y, z = dest.z}
                                    local d_pos2 = {x = dest.x, y = check_y + 1, z = dest.z}
                                    local d_n1 = minetest.get_node(d_pos1)
                                    local d_n2 = minetest.get_node(d_pos2)
                                    local d_def1 = minetest.registered_nodes[d_n1.name]
                                    local d_def2 = minetest.registered_nodes[d_n2.name]
                                    
                                    if d_def1 and not d_def1.walkable and d_def2 and not d_def2.walkable then
                                        self.object:set_pos(dest)
                                    end
                                end
                            end
                            self._was_night = is_night
                            
                            if self.order == "stand" or self.order == "go_home" then
                                self.order = "wander"
                            end
                            
                            -- Anti-Wander check (Workstation Tether)
                            local day_target = self.job_pos or self.home_pos
                            if day_target then
                                local tether_radius = (self.evergrowth_profession == "guard") and 45 or 14
                                if vector.distance(pos, day_target) > tether_radius then
                                    self.order = "go_home"
                                    self.state = "walk"
                                    self:yaw_to_pos(day_target)
                                    self:set_velocity(self.walk_velocity)
                                    self:set_animation("walk")
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
                            
                            --[[ FUTURE: smart_mobs pathfinding (disabled - cannot navigate doors)
                            if day_target then
                                local tether_radius = (self.evergrowth_profession == "guard") and 45 or 14
                                local head_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
                                local target_head = {x = day_target.x, y = day_target.y + 1, z = day_target.z}
                                if vector.distance(pos, day_target) > tether_radius or not minetest.line_of_sight(head_pos, target_head) then
                                    self.order = "go_home"
                                    self.state = "walk"
                                    if self.pathfinding and self.smart_mobs then
                                        self:smart_mobs(pos, day_target, vector.distance(pos, day_target), dtime)
                                        
                                        if (not self.path or not self.path.way or #self.path.way == 0) and not minetest.line_of_sight(head_pos, target_head) then
                                            self._day_stuck_timer = (self._day_stuck_timer or 0) + 1
                                            if self._day_stuck_timer > 5 then
                                                -- stuck teleport logic
                                            end
                                        else
                                            self._day_stuck_timer = 0
                                        end
                                    end
                                    self:set_animation("walk")
                                end
                            end
                            ]]                            
                        end

                        
                        -- Player Interaction (Look & Greet)
                        if interacting_player and not is_night then
                            -- Look at player
                            if self.state == "stand" or self.state == "wander" then
                                self:yaw_to_pos(interacting_player:get_pos())
                            end
                            
                            -- Simple Greeting "Bark" (Cooldown: 2 minutes)
                            self._greet_timer = (self._greet_timer or 0) + 1.0
                            if self._greet_timer > 120 then
                                self._greet_timer = 0
                                local greetings = {"Hello there.", "Good day.", "Greetings."}
                                local msg = greetings[math.random(#greetings)]
                                
                                -- Determine visually clean way to say hello (send exclusively to nearby player to avoid server spam)
                                local name = interacting_player:get_player_name()
                                minetest.chat_send_player(name, "<" .. self.game_name .. "> " .. msg)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Override on_activate to fix guard HP persistence.
    -- The mobs framework treats hp_max as an object property (via set_properties)
    -- but doesn't write it back to self.*, so it vanishes from staticdata on the
    -- next save. We re-apply it here after every activation.
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
        end

        if self.base_texture then
            self.object:set_properties({textures = self.base_texture, stepheight = 1.1})
        else
            self.object:set_properties({stepheight = 1.1})
        end

        if self.evergrowth_profession == "guard" then
            self.hp_max = 50
            self.object:set_properties({hp_max = 50})

            -- Clamp health to valid range and sync engine HP
            if self.health and self.health > 0 then
                if self.health > 50 then self.health = 50 end
            else
                self.health = 50
            end
            self.object:set_hp(self.health)
            self.old_health = self.health
        end
    end

    local old_on_rightclick = base_entity.on_rightclick
    base_entity.on_rightclick = function(self, clicker)
        if clicker and clicker:is_player() then
            local name = clicker:get_player_name()
            
            if clicker:get_player_control().sneak then
                if self.is_villager then
                    local allowed = false
                    if self.home_pos then
                        local db_sid = eg_settlers.db.get_settlement_by_deed(self.home_pos)
                        if db_sid then
                            allowed = eg_settlers.db.is_authorized(db_sid, name)
                        else
                            -- Fallback to metadata verification only if the block is loaded
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

                    -- Relocation: create a contract item with this NPC's data
                    local contract = ItemStack("eg_settlers:contract_villager_relocation")
                    local meta = contract:get_meta()
                    local rname = self.nametag or self.game_name or "Settler"
                    local prof = self.evergrowth_profession or "merchant"
                    local hp = self.health or 20

                    meta:set_string("resident_name", rname)
                    meta:set_string("profession", prof)
                    meta:set_string("texture", (self.base_texture and self.base_texture[1]) or "mobs_trader.png")
                    meta:set_int("health", hp)
                    if self.trades then
                        meta:set_string("trades", minetest.serialize(self.trades))
                    end

                    local desc = contract:get_definition().description
                    local formatted_prof = prof:gsub("^%l", string.upper)
                    meta:set_string("description", desc .. "\n" .. S("Name: ") .. rname .. "\n" .. S("Profession: ") .. formatted_prof .. "\n" .. S("Health: ") .. tostring(hp))

                    -- Mark old Job Block as vacant and Bed/Deed as unassigned
                    if self.home_pos then
                        minetest.load_area(self.home_pos, self.home_pos)
                        local hnode = minetest.get_node(self.home_pos)
                        if hnode.name == "eg_settlers:housing_deed" then
                            -- Housing deed: clear deed-specific metadata
                            local dmeta = minetest.get_meta(self.home_pos)
                            dmeta:set_int("occupied", 0)
                            dmeta:set_string("resident_name", "")
                            dmeta:set_string("infotext", S("Housing Deed (Companion Deed Only)"))
                            local sid = dmeta:get_string("settlement_id")
                            if sid and sid ~= "" then
                                eg_settlers.db.unregister_resident(sid, self.home_pos)
                            end
                        else
                            -- Bed: clear bed-specific metadata
                            eg_settlers.clear_bed_assignment(self.home_pos)
                        end
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

                    -- Give contract to player
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
                    -- Admin delete for non-settler NPCs
                    if minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then
                        self.object:remove()
                        minetest.chat_send_player(name, "[eg_settlers] Trader removed safely.")
                        return
                    end
                end
            else
                -- Not sneaking (normal interaction)
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
