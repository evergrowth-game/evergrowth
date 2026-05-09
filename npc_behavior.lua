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

local base_trader = minetest.registered_entities["mobs_npc:trader"]
if base_trader then
    local old_on_step = base_trader.on_step
    base_trader.on_step = function(self, dtime)
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
                    
                    -- 2. Engagement Logic (Villagers Only)
                    if self.is_villager and visible then
                        local current_time = minetest.get_timeofday() * 24000
                        local is_night = current_time > 18500 or current_time < 4500
                        
                        -- Defensive check: verify Deed still exists at home_pos
                        if self.home_pos then
                            local deed_node = minetest.get_node(self.home_pos)
                            if deed_node.name ~= "evergrowth_villages:housing_deed" then
                                self.home_pos = nil
                            end
                        end
                        
                        -- Schedule: Nighttime return home, Daytime wander
                        if is_night then
                            if self.order ~= "stand" then
                                -- We need to go home
                                if self.home_pos then
                                    local dist_home = vector.distance(pos, self.home_pos)
                                    if dist_home > 3 then
                                        self.order = "stand" -- Interrupt wander
                                        self:go_to(self.home_pos)
                                    else
                                        -- Arrived
                                        self.order = "stand"
                                        self:set_animation("stand")
                                        self:set_velocity(0)
                                    end
                                else
                                    -- Fallback if home_pos is missing
                                    self.order = "stand"
                                end
                            end
                        else
                            -- Daytime
                            if self.order == "stand" then
                                self.order = "wander"
                            end
                            
                            -- Anti-Wander check (Tether)
                            if self.home_pos then
                                if vector.distance(pos, self.home_pos) > 22 then
                                    self.order = "stand" -- Interrupt wander to go back
                                    self:go_to(self.home_pos)
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

    local old_on_rightclick = base_trader.on_rightclick
    base_trader.on_rightclick = function(self, clicker)
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
                        deed_meta:set_string("infotext", S("Housing Deed (Vacant)"))
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
