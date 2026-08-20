local S = minetest.get_translator("eg_settlers")

local WARD_RADIUS = 15
local WARD_DAMAGE = 10
local WARD_INTERVAL = 1.0

minetest.register_node("eg_settlers:ward_stone", {
    description = S("Ward Stone"),
    tiles = {
        "default_obsidian.png^magic_materials_light_rune.png",
        "default_obsidian.png",
        "default_obsidian.png",
        "default_obsidian.png",
        "default_obsidian.png",
        "default_obsidian.png"
    },
    groups = {cracky = 1, level = 2},
    light_source = 8,
    paramtype = "light",
    is_ground_content = false,
    on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
        timer:start(WARD_INTERVAL)
    end,
    on_timer = function(pos, elapsed)
        local objects = minetest.get_objects_inside_radius(pos, WARD_RADIUS)
        local particle_emitted = false

        for _, obj in ipairs(objects) do
            local lua_ent = obj:get_luaentity()
            if lua_ent then
                -- Check if the entity is a monster (mobs_redo standard)
                if lua_ent.type == "monster" or (lua_ent.groups and lua_ent.groups.monster) then
                    -- Deal damage
                    obj:punch(obj, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = WARD_DAMAGE},
                    }, nil)

                    -- Emit a little visual feedback at the monster's location
                    if not particle_emitted then
                        local m_pos = obj:get_pos()
                        if m_pos then
                            minetest.add_particlespawner({
                                amount = 5,
                                time = 0.5,
                                minpos = vector.add(m_pos, {x=-0.5, y=0, z=-0.5}),
                                maxpos = vector.add(m_pos, {x=0.5, y=1, z=0.5}),
                                minvel = {x=-1, y=1, z=-1},
                                maxvel = {x=1, y=2, z=1},
                                minacc = {x=0, y=1, z=0},
                                maxacc = {x=0, y=2, z=0},
                                minexptime = 0.5,
                                maxexptime = 1.5,
                                minsize = 1,
                                maxsize = 2,
                                texture = "magic_materials_light_rune.png", -- using rune as a spark
                                glow = 10
                            })
                            particle_emitted = true
                        end
                    end
                end
            end
        end
        return true -- Keep timer running
    end,
})

minetest.register_craft({
    output = "eg_settlers:ward_stone",
    recipe = {
        {"magic_materials:enchanted_rune"},
        {"default:obsidian"}
    }
})
