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
        -- Disables active jumping to prevent them from vaulting over fences, while stepheight (1.1) still allows walking up steps/slabs
        base_entity.jump_height = 0
        
        local old_on_die = base_entity.on_die
        base_entity.on_die = function(self, pos)
            if self.is_villager then
                if self.home_pos then
                    minetest.load_area(self.home_pos, self.home_pos)
                    local bed_meta = minetest.get_meta(self.home_pos)
                    if bed_meta then
                        local owner = bed_meta:get_string("owner")
                        if owner == "" or string.sub(owner, 1, 10) ~= "Player Bed" then
                            bed_meta:set_string("assigned_settler", "")
                            eg_settlers.update_bed_infotext(self.home_pos)
                        end
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
                        
                        -- Defensive check: verify Job Block / Deed still exists
                        if self.job_pos then
                            local jnode = minetest.get_node(self.job_pos)
                            if jnode.name ~= "ignore" and minetest.get_item_group(jnode.name, "job_block") == 0 and jnode.name ~= "eg_settlers:housing_deed" then
                                self.job_pos = nil
                            end
                        end

                        if self.home_pos then
                            local hnode = minetest.get_node(self.home_pos)
                            if hnode.name ~= "ignore" and minetest.get_item_group(hnode.name, "bed") == 0 and hnode.name ~= "eg_settlers:housing_deed" then
                                self.home_pos = nil
                            end
                        end
                        
                        -- Schedule: Nighttime return home bed shelter, Daytime active at job workstation
                        if is_night then
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

        if self.base_texture then
            self.object:set_properties({textures = self.base_texture})
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

                    -- Mark old Job Block as vacant and Bed as unassigned
                    if self.home_pos then
                        minetest.load_area(self.home_pos, self.home_pos)
                        local bed_meta = minetest.get_meta(self.home_pos)
                        if bed_meta then
                            local owner = bed_meta:get_string("owner")
                            if owner == "" or string.sub(owner, 1, 10) ~= "Player Bed" then
                                bed_meta:set_string("assigned_settler", "")
                                eg_settlers.update_bed_infotext(self.home_pos)
                            end
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
                    local can_trade = false
                    if self.home_pos then
                        local deed_meta = minetest.get_meta(self.home_pos)
                        local sid = deed_meta:get_string("settlement_id")
                        if sid and sid ~= "" then
                            local settlement = eg_settlers.db.get_settlement(sid)
                            if settlement and settlement.satiated == 1 then
                                can_trade = true
                            end
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
