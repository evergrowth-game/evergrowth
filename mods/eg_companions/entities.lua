--[[
    Evergrowth Companions - Entities & Spawning
    ===========================================
    Defines the `eg_companions:companion` mob entity with appearance customization,
    relocation contract serialization, and dual-tether metadata persistence.
]]--

local S = minetest.get_translator("eg_companions")

eg_companions.male_skins = {"mobs_npc.png", "mobs_npc3.png", "mobs_npc5.png", "mobs_trader2.png"}
eg_companions.female_skins = {"mobs_npc2.png", "mobs_npc4.png", "mobs_npc6.png", "mobs_trader4.png"}

local female_names = {
    "Alice", "Beth", "Catherine", "Diana", "Elena", "Fiona", "Grace", "Hannah",
    "Isabel", "Julia", "Kara", "Lily", "Maria", "Nora", "Olivia", "Penny",
    "Quinn", "Rachel", "Sarah", "Tara", "Uma", "Violet", "Wendy", "Yara", "Zoe",
    "Agatha", "Beatrice", "Clara", "Dorothy", "Edith", "Flora", "Gertrude"
}

local male_names = {
    "Arthur", "Ben", "Charles", "David", "Edward", "Frank", "George", "Henry",
    "Isaac", "Jack", "Kevin", "Leo", "Michael", "Nathan", "Oscar", "Peter",
    "Quincy", "Robert", "Sam", "Thomas", "Ulysses", "Victor", "William", "Xavier",
    "Alfred", "Barnaby", "Cecil", "Desmond", "Edwin", "Fletcher", "Gerald"
}

mobs:register_mob("eg_companions:companion", {
    description = S("Companion"),
    type = "npc",
    passive = false,
    damage = 3,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_npcs = false,
    attack_players = false,
    owner_loyal = true,
    pathfinding = true,
    hp_min = 20,
    hp_max = 20,
    armor = 100,
    collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
    visual = "mesh",
    mesh = "mobs_character.b3d",
    drawtype = "front",
    textures = {
        {"mobs_npc.png"},
    },
    makes_footstep_sound = true,
    walk_velocity = 2,
    run_velocity = 3,
    walk_chance = 10,
    order = "wander",
    fear_height = 3,
    water_damage = 0,
    lava_damage = 4,
    light_damage = 0,
    suffocation = 0,
    animation = {
        speed_normal = 30, speed_run = 30,
        stand_start = 0, stand_end = 79,
        walk_start = 168, walk_end = 187,
        run_start = 168, run_end = 187,
        punch_start = 189, punch_end = 198,
    },


    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if puncher and puncher:is_player() then
            local wielded = puncher:get_wielded_item()
            if wielded and wielded:get_name() == "eg_companions:wardrobe_wand" then
                local is_owner = (self.owner == "" or self.owner == puncher:get_player_name() or minetest.is_singleplayer() or minetest.check_player_privs(puncher:get_player_name(), {server=true}))
                if is_owner then
                    local skins = self.is_female and eg_companions.female_skins or eg_companions.male_skins
                    self.companion_skin_index = (self.companion_skin_index or 1) + 1
                    if self.companion_skin_index > #skins then
                        self.companion_skin_index = 1
                    end
                    self.base_texture = { skins[self.companion_skin_index] }
                    self.textures = self.base_texture
                    self.object:set_properties({textures = self.base_texture})
                    minetest.sound_play("default_dig_snappy", {pos = self.object:get_pos(), gain = 1.0}, true)
                else
                    minetest.chat_send_player(puncher:get_player_name(), S("You do not own this companion."))
                end
                return true
            end
        end
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end
        local pname = clicker:get_player_name()

        if self._sleeping then
            minetest.chat_send_player(pname, S("This companion is sleeping."))
            return
        end

        local is_owner = (self.owner == "" or self.owner == pname or minetest.is_singleplayer() or minetest.check_player_privs(pname, {server=true}))

        -- 1. Sneak + Right-Click: Relocate Companion into Contract
        if clicker:get_player_control().sneak then
            if not is_owner then
                minetest.chat_send_player(pname, S("You cannot relocate a companion that does not belong to you."))
                return
            end

            local stack = ItemStack("eg_companions:contract_relocation")
            local meta = stack:get_meta()
            local companion_name = self.game_name or self.nametag or "Companion"
            meta:set_string("companion_nametag", companion_name)
            meta:set_int("companion_skin_index", self.companion_skin_index or 1)
            meta:set_int("companion_is_female", self.is_female and 1 or 0)
            meta:set_string("companion_owner", self.owner or pname)
            meta:set_int("companion_health", self.health or 20)

            local gender_str = self.is_female and S("Female") or S("Male")
            meta:set_string("description", S("Companion Relocation Contract") .. "\n" ..
                S("Name: ") .. companion_name .. "\n" ..
                S("Gender: ") .. gender_str .. "\n" ..
                S("Owner: ") .. (self.owner or pname))

            local inv = clicker:get_inventory()
            if inv:room_for_item("main", stack) then
                inv:add_item("main", stack)
            else
                minetest.add_item(clicker:get_pos(), stack)
            end

            -- Clear Companion Plaque metadata
            if self.plaque_pos then
                minetest.load_area(self.plaque_pos, self.plaque_pos)
                local pnode = minetest.get_node(self.plaque_pos)
                if pnode.name == "eg_companions:companion_plaque" or pnode.name == "eg_settlers:housing_deed" then
                    local pmeta = minetest.get_meta(self.plaque_pos)
                    pmeta:set_int("occupied", 0)
                    pmeta:set_string("resident_name", "")
                    pmeta:set_string("bed_pos", "")
                    pmeta:set_string("infotext", S("Companion Plaque (Vacant)"))
                end
            end

            -- Clear Bed metadata
            if self.bed_pos then
                minetest.load_area(self.bed_pos, self.bed_pos)
                local bmeta = minetest.get_meta(self.bed_pos)
                bmeta:set_string("assigned_companion", "")
            end

            self.object:remove()
            minetest.chat_send_player(pname, S("[eg_companions] Companion returned to a Relocation Contract."))
            return
        end

        -- 2. Feed to heal
        if mobs:feed_tame(self, clicker, 8, true, true) then return end

        -- 3. Friendly Chatter
        local lines = {
            S("Hello @1! Welcome home.", pname),
            S("It's nice to see you, @1.", pname),
            S("Everything is quiet and peaceful here."),
            S("What a lovely day!"),
        }
        local msg = lines[math.random(#lines)]
        minetest.chat_send_player(pname, "<" .. (self.game_name or "Companion") .. "> " .. msg)
    end,
})

-- Intercept entity-level on_step to lock sleep pose, freeze mobs_redo physics, and handle distance culling
local base_companion = minetest.registered_entities["eg_companions:companion"]
if base_companion then
    -- Suppress mobs_redo health-colored nametag updates to prevent distance culling overrides
    base_companion.update_tag = function(self, newname) end

    local old_on_step = base_companion.on_step
    base_companion.on_step = function(self, dtime, moveresult)
        if self._sleeping then
            eg_companions.on_step(self, dtime)

            if self._sleep_pos then
                self.object:set_pos(self._sleep_pos)
            end
            if self._sleep_yaw then
                self.object:set_rotation({x = math.pi / 2, y = self._sleep_yaw, z = 0})
            end
            self.object:set_velocity({x = 0, y = 0, z = 0})
            self.object:set_acceleration({x = 0, y = 0, z = 0})
            self.order = "stand"

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
                local cur_p = self.object:get_pos()
                if cur_p then
                    self.object:set_pos({x = cur_p.x, y = cur_p.y + 0.6, z = cur_p.z})
                end
                self.object:set_acceleration({x = 0, y = -9.81, z = 0})
                self.order = "wander"
                self:set_animation("stand")
            end
            return
        end

        if old_on_step then
            old_on_step(self, dtime, moveresult)
        end

        -- Run custom companion logic after old_on_step so distance culling cannot be overwritten
        eg_companions.on_step(self, dtime)
    end
end

function eg_companions.spawn_companion(pos, is_female, owner, plaque_pos, bed_pos, override_data)
    pos = {x = math.floor(pos.x + 0.5), y = math.floor(pos.y + 0.5), z = math.floor(pos.z + 0.5)}
    override_data = override_data or {}

    local obj = minetest.add_entity(pos, "eg_companions:companion")
    if not obj then return nil end

    local ent = obj:get_luaentity()
    if not ent then return nil end

    ent.is_female = is_female
    ent.companion_skin_index = override_data.skin_index or 1
    ent.owner = owner or ""
    ent.plaque_pos = plaque_pos
    ent.bed_pos = bed_pos
    ent.is_companion = true
    ent.is_evergrowth_companion = true

    local skins = is_female and eg_companions.female_skins or eg_companions.male_skins
    ent.base_texture = { skins[ent.companion_skin_index] or skins[1] }
    ent.textures = ent.base_texture

    local name_list = is_female and female_names or male_names
    local name = name_list[math.random(#name_list)]
    local ntag = (override_data.nametag and override_data.nametag ~= "") and override_data.nametag or (name .. " the Companion")

    ent.nametag = ntag
    ent.game_name = ntag
    ent._nametag = nil

    obj:set_properties({
        textures = ent.base_texture,
        nametag = ent.nametag,
        nametag_color = "#FFFFFF",
        nametag_bgcolor = {r = 0, g = 0, b = 0, a = 140},
    })

    if override_data.health and override_data.health > 0 then
        ent.health = override_data.health
        obj:set_hp(ent.health)
    end

    minetest.log("action", "[eg_companions] Spawned " .. (is_female and "Female" or "Male") .. " Companion '" .. ntag .. "' at " .. minetest.pos_to_string(pos))
    return ntag
end
