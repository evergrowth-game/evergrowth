--[[
    Evergrowth Settlers - Settlement Visual Boundary Box
    ===================================================
    Registers the boundary nodebox and display entity to render a 3D cyan
    wireframe box outlining the 200-block settlement protection territory
    when punching or interacting with the Town Ledger.
]]--

local S = minetest.get_translator("eg_settlers")

eg_settlers = eg_settlers or {}
eg_settlers.active_boundary_markers = eg_settlers.active_boundary_markers or {}

local radius = 200

-- Register nodebox node used for the wielditem entity visual box
minetest.register_node("eg_settlers:boundary_node", {
    tiles = {"protector_display.png^[colorize:#00FFFF:200"},
    use_texture_alpha = "clip",
    walkable = false,
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-(radius + 0.55), -(radius + 0.55), -(radius + 0.55), -(radius + 0.45), (radius + 0.55), (radius + 0.55)}, -- West side
            {-(radius + 0.55), -(radius + 0.55), (radius + 0.45), (radius + 0.55), (radius + 0.55), (radius + 0.55)},  -- North side
            {(radius + 0.45), -(radius + 0.55), -(radius + 0.55), (radius + 0.55), (radius + 0.55), (radius + 0.55)},  -- East side
            {-(radius + 0.55), -(radius + 0.55), -(radius + 0.55), (radius + 0.55), (radius + 0.55), -(radius + 0.45)}, -- South side
            {-(radius + 0.55), (radius + 0.45), -(radius + 0.55), (radius + 0.55), (radius + 0.55), (radius + 0.55)},  -- Top
            {-(radius + 0.55), -(radius + 0.55), -(radius + 0.55), (radius + 0.55), -(radius + 0.45), (radius + 0.55)}, -- Bottom
        }
    },
    selection_box = {type = "regular"},
    paramtype = "light",
    groups = {not_in_creative_inventory = 1},
    drop = "",
    on_blast = function() end
})

-- Entity that renders the boundary nodebox as a wielditem
minetest.register_entity("eg_settlers:boundary_display", {
    initial_properties = {
        physical = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
        visual = "wielditem",
        visual_size = {x = 0.67, y = 0.67},
        textures = {"eg_settlers:boundary_node"},
        glow = 14,
    },
    timer = 0,
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer >= 30.0 then
            self.object:remove()
        end
    end
})

-- Helper to clear active boundary display for a player
function eg_settlers.clear_boundary_markers(player_name)
    local active = eg_settlers.active_boundary_markers[player_name]
    if active then
        if active.obj and active.obj:get_pos() then
            active.obj:remove()
        end
        eg_settlers.active_boundary_markers[player_name] = nil
        return true
    end
    return false
end

-- Toggle visual boundary box for a settlement
function eg_settlers.toggle_boundary_markers(player, settlement_id, ledger_pos)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()

    -- Toggle OFF if already active
    local existing = eg_settlers.active_boundary_markers[name]
    if existing then
        local same_settlement = (existing.settlement_id == settlement_id)
        eg_settlers.clear_boundary_markers(name)
        if same_settlement then
            minetest.chat_send_player(name, minetest.colorize("#00FFFF",
                S("[eg_settlers] Settlement boundary visualization toggled OFF.")))
            return
        end
    end

    local s = eg_settlers.db.get_settlement(settlement_id)
    local town_name = s and s.name or S("Settlement")

    -- Spawn the boundary display entity centered at the Town Ledger pos
    local obj = minetest.add_entity({x = ledger_pos.x, y = ledger_pos.y, z = ledger_pos.z}, "eg_settlers:boundary_display")
    if obj then
        eg_settlers.active_boundary_markers[name] = {
            settlement_id = settlement_id,
            obj = obj,
        }
        minetest.chat_send_player(name, minetest.colorize("#00FFFF",
            S("[eg_settlers] Displaying boundary box for '@1' (Radius: 200 blocks). Punch Ledger again or click Boundaries button to clear.", town_name)))
    end
end

-- Clear active boundary display when player logs off
minetest.register_on_leaveplayer(function(player)
    if player and player:is_player() then
        eg_settlers.clear_boundary_markers(player:get_player_name())
    end
end)
