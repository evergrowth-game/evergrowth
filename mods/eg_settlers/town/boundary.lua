--[[
    Evergrowth Settlers - Settlement Visual Boundary Markers
    =======================================================
    Registers the boundary marker entity and helper functions to display
    settlement radius borders when punching or interacting with the Town Ledger.
]]--

local S = minetest.get_translator("eg_settlers")

eg_settlers = eg_settlers or {}
eg_settlers.active_boundary_markers = eg_settlers.active_boundary_markers or {}

-- Register non-colliding glowing boundary marker entity
minetest.register_entity("eg_settlers:boundary_marker", {
    physical = false,
    collisionbox = {0, 0, 0, 0, 0, 0},
    pointable = false,
    visual = "upright_sprite",
    textures = {"default_paper.png^[multiply:#00FFFF"},
    glow = 14,
    visual_size = {x = 1.5, y = 4.0},
    static_save = false,

    on_activate = function(self, staticdata, dtime_s)
        self.timer = 0
    end,

    on_step = function(self, dtime)
        self.timer = (self.timer or 0) + dtime
        if self.timer >= 60.0 then
            self.object:remove()
        end
    end,
})

-- Helper to clear boundary markers for a given player name
function eg_settlers.clear_boundary_markers(player_name)
    local active = eg_settlers.active_boundary_markers[player_name]
    if active then
        if active.entities then
            for _, obj in ipairs(active.entities) do
                if obj and obj:get_pos() then
                    obj:remove()
                end
            end
        end
        eg_settlers.active_boundary_markers[player_name] = nil
        return true
    end
    return false
end

-- Helper to find ground level for a given (x, z) starting around ledger_y
local function find_ground_y(x, start_y, z)
    local search_top = start_y + 30
    local search_bottom = start_y - 30

    for y = search_top, search_bottom, -1 do
        local pos = {x = x, y = y, z = z}
        local node = minetest.get_node_or_nil(pos)
        if node and node.name ~= "air" and node.name ~= "ignore" then
            local def = minetest.registered_nodes[node.name]
            if def and def.walkable then
                return y + 0.5
            end
        end
    end
    return start_y + 0.5
end

-- Toggle visual boundary markers for a settlement
function eg_settlers.toggle_boundary_markers(player, settlement_id, ledger_pos)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()

    -- If markers are already active for this player
    local existing = eg_settlers.active_boundary_markers[name]
    if existing then
        local same_settlement = (existing.settlement_id == settlement_id)
        eg_settlers.clear_boundary_markers(name)
        if same_settlement then
            minetest.chat_send_player(name, minetest.colorize("#00FFFF", S("[eg_settlers] Settlement boundary markers toggled OFF.")))
            return
        end
    end

    local s = eg_settlers.db.get_settlement(settlement_id)
    local town_name = s and s.name or S("Settlement")
    local radius = 200

    local entities = {}
    -- Calculate 8 perimeter points at 45-degree intervals
    for i = 0, 7 do
        local angle = i * (math.pi / 4)
        local dx = math.floor(radius * math.cos(angle) + 0.5)
        local dz = math.floor(radius * math.sin(angle) + 0.5)
        local target_x = ledger_pos.x + dx
        local target_z = ledger_pos.z + dz
        local target_y = find_ground_y(target_x, ledger_pos.y, target_z)

        local marker = minetest.add_entity({x = target_x, y = target_y + 1.5, z = target_z}, "eg_settlers:boundary_marker")
        if marker then
            table.insert(entities, marker)
        end
    end

    -- Add center marker at Ledger location
    local center_marker = minetest.add_entity({x = ledger_pos.x, y = ledger_pos.y + 1.5, z = ledger_pos.z}, "eg_settlers:boundary_marker")
    if center_marker then
        table.insert(entities, center_marker)
    end

    eg_settlers.active_boundary_markers[name] = {
        settlement_id = settlement_id,
        entities = entities,
    }

    minetest.chat_send_player(name, minetest.colorize("#00FFFF",
        S("[eg_settlers] Displaying boundary markers for '@1' (Radius: 200 blocks). Punch Ledger again or click Boundaries button to clear.", town_name)))
end

-- Clear active markers on player leave
minetest.register_on_leaveplayer(function(player)
    if player and player:is_player() then
        eg_settlers.clear_boundary_markers(player:get_player_name())
    end
end)
