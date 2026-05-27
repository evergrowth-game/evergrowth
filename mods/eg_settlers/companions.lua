--[[
    Evergrowth Villages - Companion NPC Logic
    =========================================
    This module stores the skin lists for companion NPCs and overrides the base
    `mobs_npc:npc` entity to implement custom interactions, such as changing outfits
    using the Wardrobe Wand.
]]--

local companion_male_skins = {"mobs_npc.png", "mobs_npc3.png", "mobs_npc5.png", "mobs_trader2.png"}
local companion_female_skins = {"mobs_npc2.png", "mobs_npc4.png", "mobs_npc6.png", "mobs_trader4.png"}

-- Export for spawners.lua
eg_settlers.companion_male_skins = companion_male_skins
eg_settlers.companion_female_skins = companion_female_skins

local base_npc = minetest.registered_entities["mobs_npc:npc"]
if base_npc then
    local old_on_step = base_npc.on_step
    base_npc.on_step = function(self, dtime)
        if old_on_step then old_on_step(self, dtime) end
        if self.evergrowth_nametag_mode then
            if not self.game_name and self.nametag and self.nametag ~= "" then
                self.game_name = self.nametag
            end
            self._nametag_timer = (self._nametag_timer or 0) + dtime
            if self._nametag_timer > 1.0 then
                self._nametag_timer = 0
                if self.game_name then
                    local pos = self.object:get_pos()
                    if not pos then return end
                    local limit = 20
                    local visible = false
                    local players = minetest.get_connected_players()
                    for _, player in ipairs(players) do
                        if vector.distance(pos, player:get_pos()) <= limit then
                            visible = true
                            break
                        end
                    end
                    local current_nametag = self.object:get_properties().nametag
                    if visible and current_nametag == "" then
                         self.object:set_properties({nametag = self.game_name})
                    elseif not visible and current_nametag ~= "" then
                         self.object:set_properties({nametag = ""})
                    end
                end
            end
        end
    end

    local old_on_punch = base_npc.on_punch
    base_npc.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if puncher and puncher:is_player() then
            local wielded = puncher:get_wielded_item()
            if wielded and wielded:get_name() == "eg_settlers:wardrobe_wand" then
                if self.is_evergrowth_companion then
                    local skins = self.companion_is_female and companion_female_skins or companion_male_skins
                    self.companion_skin_index = (self.companion_skin_index or 1) + 1
                    if self.companion_skin_index > #skins then
                        self.companion_skin_index = 1
                    end
                    self.base_texture = { skins[self.companion_skin_index] }
                    self.textures = self.base_texture
                    self.object:set_properties({textures = self.base_texture})
                    minetest.sound_play("default_dig_snappy", {pos = self.object:get_pos(), gain = 1.0}, true)
                else
                    minetest.chat_send_player(puncher:get_player_name(), "This outfit wand only works on Evergrowth Companions.")
                end
                return
            end
        end
        if old_on_punch then
            return old_on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
        end
    end

    local old_on_rightclick = base_npc.on_rightclick
    base_npc.on_rightclick = function(self, clicker)
        if clicker and clicker:is_player() and clicker:get_player_control().sneak then
            if self.is_evergrowth_companion then
                local name = clicker:get_player_name()
                if minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then
                    local stack = ItemStack("eg_settlers:contract_companion_relocation")
                    local meta = stack:get_meta()
                    meta:set_string("companion_nametag", self.game_name or self.nametag or "")
                    meta:set_int("companion_skin_index", self.companion_skin_index or 1)
                    meta:set_int("companion_is_female", self.companion_is_female and 1 or 0)
                    meta:set_string("companion_owner", self.owner or "")
                    meta:set_int("companion_health", self.health or 20)
                    
                    local desc = stack:get_definition().description
                    local desc_name = self.game_name or self.nametag
                    if desc_name and desc_name ~= "" then
                        meta:set_string("description", desc .. "\n(" .. desc_name .. ")")
                    end
                    
                    local inv = clicker:get_inventory()
                    if inv:room_for_item("main", stack) then
                        inv:add_item("main", stack)
                    else
                        minetest.add_item(clicker:get_pos(), stack)
                    end
                    
                    self.object:remove()
                    minetest.chat_send_player(name, "[eg_settlers] Companion returned to a Relocation Contract.")
                    return
                end
            end
        end
        if old_on_rightclick then
            return old_on_rightclick(self, clicker)
        end
    end
end
