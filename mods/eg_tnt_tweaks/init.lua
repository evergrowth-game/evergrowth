-- TNT Tweaks for Evergrowth
-- Integrates player attribution into TNT explosions so settlement and area protection can verify authorized player actions.

tnt_tweaks = {}
tnt_tweaks.current_igniter = nil

-- Wrap tnt.boom to capture and propagate the triggering player name
local orig_tnt_boom = tnt.boom
function tnt.boom(pos, def)
    def = def or {}
    local meta = minetest.get_meta(pos)
    local owner = (def.owner and def.owner ~= "") and def.owner
        or (bweapons and bweapons.current_shooter and bweapons.current_shooter ~= "" and bweapons.current_shooter)
        or (tnt_tweaks.current_igniter and tnt_tweaks.current_igniter ~= "" and tnt_tweaks.current_igniter)
        or (meta and meta:get_string("owner"))
        or ""

    if owner ~= "" and meta and meta:get_string("owner") == "" then
        meta:set_string("owner", owner)
    end

    return orig_tnt_boom(pos, def)
end

-- Override tnt:tnt to record player ownership upon ignition
minetest.register_on_mods_loaded(function()
    local tnt_def = minetest.registered_nodes["tnt:tnt"]
    if tnt_def then
        local orig_on_punch = tnt_def.on_punch
        local orig_on_ignite = tnt_def.on_ignite

        minetest.override_item("tnt:tnt", {
            on_punch = function(pos, node, puncher)
                if puncher and minetest.is_player(puncher) and puncher:get_wielded_item():get_name() == "default:torch" then
                    local meta = minetest.get_meta(pos)
                    meta:set_string("owner", puncher:get_player_name())
                end
                if orig_on_punch then
                    return orig_on_punch(pos, node, puncher)
                end
            end,
            on_ignite = function(pos, igniter)
                if igniter and minetest.is_player(igniter) then
                    local meta = minetest.get_meta(pos)
                    meta:set_string("owner", igniter:get_player_name())
                end
                if orig_on_ignite then
                    return orig_on_ignite(pos, igniter)
                end
            end,
        })
    end

    -- Hook torch_bomb projectile entities if loaded
    if minetest.get_modpath("torch_bomb") then
        for name, entity_def in pairs(minetest.registered_entities) do
            if name:match("^torch_bomb:") and entity_def.on_step then
                local orig_on_step = entity_def.on_step
                entity_def.on_step = function(self, dtime)
                    local p_name = self.player_name
                        or (minetest.is_player(self.owner) and self.owner:get_player_name())
                        or ""
                    tnt_tweaks.current_igniter = p_name
                    local res = orig_on_step(self, dtime)
                    tnt_tweaks.current_igniter = nil
                    return res
                end
            end
        end
    end
end)
