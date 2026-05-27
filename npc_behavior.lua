--[[
    Evergrowth Villages - NPC Behavior & Engagement
    ===============================================
    This module overrides the `on_step` function of the base `mobs_npc:trader` 
    entity. It implements a player-distance check to selectively show or hide 
    nametags, reducing screen clutter when the player is far away.
    
    If the entity possesses the `is_villager` flag (spawned naturally in a village),
    it also injects dynamic engagement behaviors:
    - Look at nearby players (yaw_to_pos)
    - Day/Night schedules (return home to sleep)
    - Atmospheric greetings
]]--

local S = minetest.get_translator("evergrowth_villages")

local target_entities = {"mobs_npc:trader", "mobs_npc:npc"}
for _, entity_name in ipairs(target_entities) do
    local base_entity = minetest.registered_entities[entity_name]
    if base_entity then
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
                    
                    -- 2. Schedule & Engagement Logic (Villagers Only)
                    if self.is_villager then
                        local current_time = minetest.get_timeofday() * 24000
                        local is_night = (current_time > 18500 or current_time < 4500) and self.evergrowth_profession ~= "guard"
                        
                        -- Defensive check: verify Deed still exists at home_pos
                        if self.home_pos then
                            local deed_node = minetest.get_node(self.home_pos)
                            if deed_node.name ~= "ignore" and deed_node.name ~= "evergrowth_villages:housing_deed" then
                                self.home_pos = nil
                            end
                        end
                        
                        -- Schedule: Nighttime return home, Daytime wander
                        if is_night then
                            if self.home_pos then
                                local dist_home = vector.distance(pos, self.home_pos)
                                if dist_home > 3 then
                                    -- Teleport directly in front of deed to avoid geometry issues
                                    local dest = {x = self.home_pos.x, y = self.home_pos.y, z = self.home_pos.z}
                                    local face = 0
                                    
                                    local node = minetest.get_node(self.home_pos)
                                    if node and node.param2 then face = node.param2 end
                                    
                                    if face == 0 then dest.z = dest.z - 1
                                    elseif face == 1 then dest.x = dest.x - 1
                                    elseif face == 2 then dest.z = dest.z + 1
                                    elseif face == 3 then dest.x = dest.x + 1
                                    else dest.z = dest.z - 1 end
                                    
                                    self.object:set_pos(dest)
                                    self.order = "stand"
                                    if self.stop_attack then self:stop_attack() end
                                    self:set_animation("stand")
                                    self:set_velocity(0)
                                else
                                    -- Arrived
                                    if self.order ~= "stand" then
                                        self.order = "stand"
                                        if self.stop_attack then self:stop_attack() end
                                        self:set_animation("stand")
                                        self:set_velocity(0)
                                    end
                                end
                            else
                                -- Fallback if home_pos is missing
                                self.order = "stand"
                            end
                        else
                            -- Daytime
                            if self.order == "stand" or self.order == "go_home" then
                                self.order = "wander"
                            end
                            
                            -- Anti-Wander check (Tether)
                            if self.home_pos then
                                local tether_radius = (self.evergrowth_profession == "guard") and 45 or 14
                                if vector.distance(pos, self.home_pos) > tether_radius then
                                    -- Force walk directly back to tether (bypassing limits)
                                    self.order = "go_home"
                                    self.state = "walk"
                                    self:yaw_to_pos(self.home_pos)
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
        if clicker and clicker:is_player() and clicker:get_player_control().sneak then
            local name = clicker:get_player_name()

            if self.is_villager then
                -- Relocation: create a contract item with this NPC's data
                local contract = ItemStack("evergrowth_villages:contract_villager_relocation")
                local meta = contract:get_meta()
                meta:set_string("resident_name", self.nametag or self.game_name or "Villager")
                meta:set_string("profession", self.evergrowth_profession or "merchant")
                meta:set_string("texture", (self.base_texture and self.base_texture[1]) or "mobs_trader.png")
                meta:set_int("health", self.health or 20)

                -- Mark old Deed as vacant
                if self.home_pos then
                    local deed_node = minetest.get_node(self.home_pos)
                    if deed_node.name == "evergrowth_villages:housing_deed" then
                        local deed_meta = minetest.get_meta(self.home_pos)
                        deed_meta:set_int("occupied", 0)
                        deed_meta:set_string("resident_name", "")
                        deed_meta:set_string("infotext", S("Housing Deed (Vacant) - Use a Contract here"))
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
                minetest.chat_send_player(name, S("[evergrowth_villages] Villager relocated to contract."))
                return
            else
                -- Admin delete for non-villager NPCs
                if minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then
                    self.object:remove()
                    minetest.chat_send_player(name, "[evergrowth_villages] Trader removed safely.")
                    return
                end
            end
        end
        if old_on_rightclick then
            return old_on_rightclick(self, clicker)
        end
    end
    end
end
