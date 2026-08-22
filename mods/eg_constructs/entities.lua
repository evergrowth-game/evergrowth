--[[
    Evergrowth Constructs - Entities
    ===============================
    Defines commandable Clay Golem and Automaton companions.
    Features:
    - 16-slot detached pack inventory for loot hauling
    - Follow and Hold Position command toggling
    - Combat support against monsters and raiders
    - AOE ground slam crowd control (Clay Golem)
    - Item serialization on recall into Core items
    - Inventory drop safeguard on death
]]--

local S = minetest.get_translator("eg_constructs")

eg_constructs = eg_constructs or {}

-- Helper to get or create detached inventory for construct
function eg_constructs.get_detached_inv(inv_name, owner_name, initial_items)
    local inv = minetest.get_inventory({type = "detached", name = inv_name})
    if not inv then
        inv = minetest.create_detached_inventory(inv_name, {
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                if not player then return 0 end
                local pname = player:get_player_name()
                if owner_name and owner_name ~= "" and pname ~= owner_name and not minetest.check_player_privs(pname, {server=true}) and not minetest.is_singleplayer() then
                    return 0
                end
                return count
            end,
            allow_put = function(inv, listname, index, stack, player)
                if not player then return 0 end
                local pname = player:get_player_name()
                if owner_name and owner_name ~= "" and pname ~= owner_name and not minetest.check_player_privs(pname, {server=true}) and not minetest.is_singleplayer() then
                    return 0
                end
                return stack:get_count()
            end,
            allow_take = function(inv, listname, index, stack, player)
                if not player then return 0 end
                local pname = player:get_player_name()
                if owner_name and owner_name ~= "" and pname ~= owner_name and not minetest.check_player_privs(pname, {server=true}) and not minetest.is_singleplayer() then
                    return 0
                end
                return stack:get_count()
            end,
        })
        inv:set_size("main", 16)
        if initial_items then
            for idx, item_str in ipairs(initial_items) do
                if idx <= 16 and item_str and item_str ~= "" then
                    inv:set_stack("main", idx, ItemStack(item_str))
                end
            end
        end
    end
    return inv
end

-- Helper to export inventory to list of item strings
function eg_constructs.serialize_inventory(inv_name)
    local items = {}
    local inv = minetest.get_inventory({type = "detached", name = inv_name})
    if inv then
        for i = 1, 16 do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                items[i] = stack:to_string()
            else
                items[i] = ""
            end
        end
    end
    return items
end

-- Helper to check if inventory has any items
function eg_constructs.count_stored_items(items)
    if not items then return 0 end
    local count = 0
    for _, item_str in pairs(items) do
        if item_str and item_str ~= "" then
            count = count + 1
        end
    end
    return count
end

-- Open companion pack inventory formspec
local function open_pack_formspec(player, inv_name, title)
    local formspec = "formspec_version[4]" ..
        "size[10.5,8.0]" ..
        "box[0,0;10.5,8.0;#181A20]" ..
        "label[0.5,0.6;" .. minetest.colorize("#FFAA00", minetest.formspec_escape(title)) .. "]" ..
        "list[detached:" .. inv_name .. ";main;0.5,1.0;8,2;]" ..
        "label[0.5,3.2;" .. minetest.colorize("#AAAAAA", S("Player Inventory")) .. "]" ..
        "list[current_player;main;0.5,3.6;8,4;]" ..
        "listring[detached:" .. inv_name .. ";main]" ..
        "listring[current_player;main]"
    minetest.show_formspec(player:get_player_name(), "eg_constructs:pack_" .. inv_name, formspec)
end

-- Common companion interaction handler
local function handle_companion_rightclick(self, clicker, core_item_name, display_title)
    if not clicker or not clicker:is_player() then return end
    local pname = clicker:get_player_name()
    local is_owner = (self.owner == "" or self.owner == pname or minetest.check_player_privs(pname, {server=true}) or minetest.is_singleplayer())

    if not is_owner then
        minetest.chat_send_player(pname, S("[eg_constructs] This construct belongs to @1.", self.owner or S("another player")))
        return
    end

    local inv_name = "eg_construct_" .. tostring(self.construct_id)
    local inv = eg_constructs.get_detached_inv(inv_name, self.owner, self.stored_inventory)

    -- Sneak + Right-Click: Recall construct into Core item
    if clicker:get_player_control().sneak then
        local items = eg_constructs.serialize_inventory(inv_name)
        local core_stack = ItemStack(core_item_name .. " 1")
        local item_count = eg_constructs.count_stored_items(items)

        if item_count > 0 then
            local meta = core_stack:get_meta()
            meta:set_string("stored_inventory", minetest.serialize(items))
            local base_desc = (core_item_name == "eg_constructs:golem_core") and S("Golem Core") or S("Combat Drone Core")
            meta:set_string("description", base_desc .. " (" .. S("@1 items stored", item_count) .. ")")
        end

        local pinv = clicker:get_inventory()
        if pinv:room_for_item("main", core_stack) then
            pinv:add_item("main", core_stack)
        else
            minetest.add_item(self.object:get_pos(), core_stack)
        end

        -- Clear detached inventory contents on recall
        if inv then
            inv:set_list("main", {})
        end

        minetest.sound_play("default_place_node_metal", {pos = self.object:get_pos(), gain = 1.0}, true)
        minetest.chat_send_player(pname, S("[eg_constructs] Construct packed into core."))
        self.object:remove()
        return
    end

    -- Normal Right-Click: Open Pack Inventory
    open_pack_formspec(clicker, inv_name, display_title .. " - " .. S("Pack Inventory"))
end

-- Common punch handler for command toggling
local function handle_companion_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, construct_label)
    if not puncher or not puncher:is_player() then return false end
    local pname = puncher:get_player_name()
    local is_owner = (self.owner == "" or self.owner == pname or minetest.check_player_privs(pname, {server=true}) or minetest.is_singleplayer())

    -- Owner Sneak+Punch toggles Follow vs Hold Position
    if is_owner and puncher:get_player_control().sneak then
        if self.order == "stand" then
            self.order = "follow"
            self.following = puncher
            self.state = "walk"
            minetest.chat_send_player(pname, S("[eg_constructs] @1 is now following you.", construct_label))
        else
            self.order = "stand"
            self.following = nil
            self.state = "stand"
            self:set_velocity(0)
            self:set_animation("stand")
            minetest.chat_send_player(pname, S("[eg_constructs] @1 is now holding position.", construct_label))
        end
        return true -- Halts further damage processing in mobs_redo
    end

    -- Owner normal punch: immune to friendly fire
    if is_owner then
        return true -- Cancels friendly fire damage from owner
    end

    return false -- Allows hostile mobs and non-owners to deal damage
end

-- Common death handler: drop pack inventory contents
local function handle_companion_death(self, pos, core_name)
    local inv_name = "eg_construct_" .. tostring(self.construct_id)
    local inv = minetest.get_inventory({type = "detached", name = inv_name})
    if inv then
        for i = 1, 16 do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                minetest.add_item(pos, stack)
            end
        end
        inv:set_list("main", {})
    end
    -- Salvage chance
    if math.random(1, 2) == 1 then
        minetest.add_item(pos, core_name)
    end
end

-- AOE Ground Slam for Clay Golem crowd control
local SLAM_RADIUS = 4.5
local SLAM_DAMAGE = 12

local function perform_golem_ground_slam(self)
    local pos = self.object:get_pos()
    if not pos then return end

    -- Pause locomotion for 0.6s so the slam animation completes without interruption
    self.pause_timer = 0.6
    self:set_velocity(0)

    -- Accelerated attack animation (30 fps)
    self.object:set_animation({x = 36, y = 48}, 30, 0, false)

    -- Forward pitch tilt towards ground (~23 degrees)
    self:set_pitch(0.40)
    self.pitch_reset_timer = 0.45

    -- Heavy impact sound effects
    minetest.sound_play("default_dig_cracky", {pos = pos, gain = 1.4, max_hear_distance = 25}, true)
    minetest.sound_play("mobs_dungeonmaster", {pos = pos, gain = 1.0, pitch = 0.65, max_hear_distance = 25}, true)

    -- 1. Expanding Ground Dust Shockwave (smoke ring)
    minetest.add_particlespawner({
        amount = 50,
        time = 0.25,
        minpos = {x = pos.x - 0.5, y = pos.y + 0.15, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.4, z = pos.z + 0.5},
        minvel = {x = -4.5, y = 1.0, z = -4.5},
        maxvel = {x = 4.5, y = 2.8, z = 4.5},
        minacc = {x = 0, y = -0.5, z = 0},
        maxacc = {x = 0, y = -1.5, z = 0},
        minexptime = 0.6,
        maxexptime = 1.2,
        minsize = 3,
        maxsize = 6,
        texture = "tnt_smoke.png",
        glow = 2,
    })

    -- 2. Earthen Clay Debris (rock bursts)
    minetest.add_particlespawner({
        amount = 35,
        time = 0.2,
        minpos = {x = pos.x - 0.4, y = pos.y + 0.2, z = pos.z - 0.4},
        maxpos = {x = pos.x + 0.4, y = pos.y + 0.5, z = pos.z + 0.4},
        minvel = {x = -3.5, y = 2.5, z = -3.5},
        maxvel = {x = 3.5, y = 4.5, z = 3.5},
        minacc = {x = 0, y = -8.0, z = 0},
        maxacc = {x = 0, y = -10.0, z = 0},
        minexptime = 0.5,
        maxexptime = 1.0,
        minsize = 2,
        maxsize = 4,
        texture = "default_clay.png",
    })

    -- Find and affect nearby targets
    local objects = minetest.get_objects_inside_radius(pos, SLAM_RADIUS)
    for _, obj in ipairs(objects) do
        if obj and obj ~= self.object then
            local is_target = false
            local obj_pos = obj:get_pos()

            if obj:is_player() then
                local pname = obj:get_player_name()
                if self.owner and self.owner ~= "" and pname == self.owner then
                    is_target = false
                elseif minetest.settings:get_bool("enable_pvp") ~= false then
                    is_target = true
                end
            else
                local ent = obj:get_luaentity()
                if ent and ent.name ~= (self.name or "eg_constructs:golem_clay") then
                    -- Don't harm companions with the same owner
                    if self.owner and self.owner ~= "" and ent.owner == self.owner then
                        is_target = false
                    -- Don't harm friendly NPC settlers unless they are attacking players
                    elseif ent.type == "npc" and not ent.attack_players then
                        is_target = false
                    -- Target monsters, raiders, or hostile entities
                    elseif ent.type == "monster" or (ent.attack_type and ent.damage and ent.damage > 0) then
                        is_target = true
                    end
                end
            end

            if is_target and obj_pos then
                -- Calculate outward knockback vector
                local dir = vector.direction(pos, obj_pos)
                if dir.x == 0 and dir.z == 0 then
                    dir = {x = (math.random() - 0.5) * 2, y = 0.5, z = (math.random() - 0.5) * 2}
                end

                -- Deal AoE damage
                obj:punch(self.object, 1.0, {
                    full_punch_interval = 0.5,
                    damage_groups = {fleshy = SLAM_DAMAGE},
                }, dir)

                -- Apply strong vertical launch and radial knockback
                local kb_vel = {
                    x = dir.x * 4.8,
                    y = 4.2,
                    z = dir.z * 4.8
                }
                obj:add_velocity(kb_vel)

                -- Force hostile mob aggro onto the golem (tank taunt)
                local ent = obj:get_luaentity()
                if ent and ent.state then
                    ent.attack = self.object
                    ent.state = "attack"
                end
            end
        end
    end
end

-- 1. CLAY GOLEM
mobs:register_mob("eg_constructs:golem_clay", {
    description = S("Clay Golem"),
    type = "npc",
    passive = false,
    damage = 12,
    attack_type = "dogfight",
    attack_monsters = true,
    attack_npcs = false,
    attack_players = false,
    owner_loyal = true,
    pathfinding = true,
    hp_min = 120,
    hp_max = 120,
    armor = 70,
    collisionbox = {-0.5, -1.01, -0.5, 0.5, 1.6, 0.5},
    visual_size = {x = 1, y = 1},
    visual = "mesh",
    mesh = "mobs_dungeon_master.b3d",
    textures = {
        {"eg_constructs_golem_clay.png"}
    },
    makes_footstep_sound = true,
    sounds = {
        random = "mobs_dungeonmaster",
        attack = "mobs_dungeonmaster",
    },
    walk_velocity = 1.2,
    run_velocity = 2.0,
    jump = true,
    jump_height = 4,
    stepheight = 1.1,
    view_range = 25,
    fear_height = 4,
    water_damage = 0,
    lava_damage = 2,
    light_damage = 0,
    order = "follow",
    animation = {
        speed_normal = 15,
        speed_run = 15,
        stand_start = 0,
        stand_end = 19,
        walk_start = 20,
        walk_end = 35,
        run_start = 20,
        run_end = 35,
        punch_start = 36,
        punch_end = 48,
    },

    custom_attack = function(self, p)
        self.attack_count = (self.attack_count or 0) + 1
        self.slam_cooldown = self.slam_cooldown or 0

        -- Ground slam triggers on engagement, every 3rd melee strike, or if 5s cooldown elapsed
        if self.attack_count == 1 or self.attack_count % 3 == 0 or self.slam_cooldown >= 5.0 then
            perform_golem_ground_slam(self)
            self.slam_cooldown = 0
            return false -- Handled via custom AoE slam
        end
        return true -- Standard single target punch
    end,

    do_custom = function(self, dtime)
        -- Reset forward pitch tilt after slam strike finishes
        if self.pitch_reset_timer then
            self.pitch_reset_timer = self.pitch_reset_timer - dtime
            if self.pitch_reset_timer <= 0 then
                self:set_pitch(0)
                self.pitch_reset_timer = nil
            end
        end

        -- Re-bind follow target if owner is online
        if self.order == "follow" and (not self.following or not self.following:get_pos()) and self.owner and self.owner ~= "" then
            self.following = minetest.get_player_by_name(self.owner)
        end

        -- Track combat cooldown timer
        self.slam_cooldown = (self.slam_cooldown or 0) + dtime
    end,

    do_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        return handle_companion_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, S("Clay Golem"))
    end,

    on_rightclick = function(self, clicker)
        handle_companion_rightclick(self, clicker, "eg_constructs:golem_core", S("Clay Golem"))
    end,

    on_die = function(self, pos)
        handle_companion_death(self, pos, "eg_constructs:golem_core")
    end,

    on_activate = function(self, staticdata, dtime_s)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.owner = data.owner
                self.order = data.order or "follow"
                self.construct_id = data.construct_id or math.random(100000, 999999)
                self.stored_inventory = data.stored_inventory
                if data.health and data.health > 0 then
                    self.health = data.health
                    self.object:set_hp(data.health)
                end
            end
        end
        if not self.construct_id then
            self.construct_id = math.random(100000, 999999)
        end
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        eg_constructs.get_detached_inv(inv_name, self.owner, self.stored_inventory)
    end,

    get_staticdata = function(self)
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        local items = eg_constructs.serialize_inventory(inv_name)
        return minetest.serialize({
            owner = self.owner,
            order = self.order,
            construct_id = self.construct_id,
            stored_inventory = items,
            health = self.health or self.object:get_hp(),
        })
    end,
})

-- Projectile for Combat Drone ranged attack
local LASER_DAMAGE = 8

mobs:register_arrow("eg_constructs:laser_bolt", {
    visual = "sprite",
    visual_size = {x = 0.5, y = 0.5},
    textures = {"default_mese_crystal_fragment.png"},
    velocity = 18,
    glow = 14,
    tail = 1,
    tail_texture = "default_mese_crystal_fragment.png",
    tail_size = 3,
    expire = 0.1,

    hit_player = function(self, player)
        if not player or not player:is_player() then return end
        local pname = player:get_player_name()

        -- Check if shooter construct belongs to this player (immune to own drone's fire)
        local shooter_owner = nil
        if self.owner_id then
            if type(self.owner_id) == "userdata" and self.owner_id.get_luaentity then
                local shooter_ent = self.owner_id:get_luaentity()
                shooter_owner = shooter_ent and shooter_ent.owner
            elseif type(self.owner_id) == "table" then
                shooter_owner = self.owner_id.owner
            elseif type(self.owner_id) == "string" then
                shooter_owner = self.owner_id
            end
        end

        if shooter_owner and shooter_owner == pname then
            return
        end

        -- Respect server PvP toggle for other players
        if minetest.settings:get_bool("enable_pvp") == false then
            return
        end

        player:punch(self.object, 1.0, {
            full_punch_interval = 0.5,
            damage_groups = {fleshy = LASER_DAMAGE},
        }, nil)
    end,

    hit_mob = function(self, mob)
        if not mob then return end
        local target_ent = mob:get_luaentity()
        if target_ent then
            local shooter_owner = nil
            if self.owner_id then
                if type(self.owner_id) == "userdata" and self.owner_id.get_luaentity then
                    local shooter_ent = self.owner_id:get_luaentity()
                    shooter_owner = shooter_ent and shooter_ent.owner
                elseif type(self.owner_id) == "table" then
                    shooter_owner = self.owner_id.owner
                elseif type(self.owner_id) == "string" then
                    shooter_owner = self.owner_id
                end
            end

            -- Prevent friendly fire with companions belonging to same owner
            if shooter_owner and shooter_owner ~= "" and target_ent.owner == shooter_owner then
                return
            end

            -- Prevent hitting friendly NPC settlers / neutral town folk
            if target_ent.type == "npc" and not target_ent.attack_players then
                return
            end
        end

        mob:punch(self.object, 1.0, {
            full_punch_interval = 0.5,
            damage_groups = {fleshy = LASER_DAMAGE},
        }, nil)
    end,

    hit_object = function(self, obj)
        if not obj then return end
        obj:punch(self.object, 1.0, {
            full_punch_interval = 0.5,
            damage_groups = {fleshy = LASER_DAMAGE},
        }, nil)
    end,

    hit_node = function(self, pos, node)
    end,
})

-- 2. COMBAT DRONE
mobs:register_mob("eg_constructs:combat_drone", {
    description = S("Combat Drone"),
    type = "npc",
    passive = false,
    damage = 7,
    attack_type = "dogshoot",
    arrow = "eg_constructs:laser_bolt",
    shoot_interval = 1.0,
    shoot_offset = 1.2,
    reach = 2.5,
    attack_monsters = true,
    attack_npcs = false,
    attack_players = false,
    owner_loyal = true,
    pathfinding = true,
    hp_min = 80,
    hp_max = 80,
    armor = 80,
    collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
    visual = "mesh",
    mesh = "mobs_character.b3d",
    textures = {
        {"eg_constructs_combat_drone.png"}
    },
    makes_footstep_sound = true,
    sounds = {},
    walk_velocity = 1.8,
    run_velocity = 3.0,
    jump = true,
    jump_height = 4,
    stepheight = 1.1,
    view_range = 16,
    fear_height = 4,
    water_damage = 0,
    lava_damage = 3,
    light_damage = 0,
    order = "follow",
    animation = {
        speed_normal = 30,
        speed_run = 30,
        stand_start = 0,
        stand_end = 79,
        walk_start = 168,
        walk_end = 187,
        run_start = 168,
        run_end = 187,
        punch_start = 189,
        punch_end = 198,
        shoot_start = 189,
        shoot_end = 198,
    },

    do_custom = function(self, dtime)
        -- Re-bind follow target if owner is online
        if self.order == "follow" and (not self.following or not self.following:get_pos()) and self.owner and self.owner ~= "" then
            self.following = minetest.get_player_by_name(self.owner)
        end
    end,

    do_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        return handle_companion_punch(self, puncher, time_from_last_punch, tool_capabilities, dir, S("Combat Drone"))
    end,

    on_rightclick = function(self, clicker)
        handle_companion_rightclick(self, clicker, "eg_constructs:combat_drone_core", S("Combat Drone"))
    end,

    on_die = function(self, pos)
        handle_companion_death(self, pos, "eg_constructs:combat_drone_core")
    end,

    on_activate = function(self, staticdata, dtime_s)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.owner = data.owner
                self.order = data.order or "follow"
                self.construct_id = data.construct_id or math.random(100000, 999999)
                self.stored_inventory = data.stored_inventory
                if data.health and data.health > 0 then
                    self.health = data.health
                    self.object:set_hp(data.health)
                end
            end
        end
        if not self.construct_id then
            self.construct_id = math.random(100000, 999999)
        end
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        eg_constructs.get_detached_inv(inv_name, self.owner, self.stored_inventory)
    end,

    get_staticdata = function(self)
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        local items = eg_constructs.serialize_inventory(inv_name)
        return minetest.serialize({
            owner = self.owner,
            order = self.order,
            construct_id = self.construct_id,
            stored_inventory = items,
            health = self.health or self.object:get_hp(),
        })
    end,
})

-- Aliases for Automaton compatibility
minetest.register_alias("eg_constructs:automaton", "eg_constructs:combat_drone")
