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
eg_constructs.active_inventories = {}

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
            minetest.chat_send_player(pname, S("[eg_constructs] @1 is now following you.", construct_label))
        else
            self.order = "stand"
            self.following = nil
            minetest.chat_send_player(pname, S("[eg_constructs] @1 is now holding position.", construct_label))
        end
        return false -- Prevent dealing damage
    end

    -- Owner normal punch: immune to friendly fire
    if is_owner then
        return false
    end

    return true
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
    end
    -- Salvage chance
    if math.random(1, 2) == 1 then
        minetest.add_item(pos, core_name)
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

    do_custom = function(self, dtime)
        -- Keep detached inventory synced in memory
        if not self.construct_id then
            self.construct_id = math.random(100000, 999999)
        end
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        eg_constructs.get_detached_inv(inv_name, self.owner, self.stored_inventory)

        -- Re-bind follow target if owner is online
        if self.order == "follow" and (not self.following or not self.following:get_pos()) and self.owner and self.owner ~= "" then
            self.following = minetest.get_player_by_name(self.owner)
        end
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
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
        if self.owner_id then
            local shooter_ent = nil
            if type(self.owner_id) == "userdata" and self.owner_id.get_luaentity then
                shooter_ent = self.owner_id:get_luaentity()
            elseif type(self.owner_id) == "table" then
                shooter_ent = self.owner_id
            elseif type(self.owner_id) == "string" and self.owner_id == pname then
                return
            end

            if shooter_ent and shooter_ent.owner and shooter_ent.owner == pname then
                return
            end
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
    shoot_offset = 0.0,
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
    view_range = 30,
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
        if not self.construct_id then
            self.construct_id = math.random(100000, 999999)
        end
        local inv_name = "eg_construct_" .. tostring(self.construct_id)
        eg_constructs.get_detached_inv(inv_name, self.owner, self.stored_inventory)

        -- Re-bind follow target if owner is online
        if self.order == "follow" and (not self.following or not self.following:get_pos()) and self.owner and self.owner ~= "" then
            self.following = minetest.get_player_by_name(self.owner)
        end
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
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
