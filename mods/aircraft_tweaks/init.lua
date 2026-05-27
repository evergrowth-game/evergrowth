-- Aircraft Tweaks
-- Dynamically adjusts lateral drag to fix slipping on ice feeling when taxiing.

local function apply_lateral_drag_fix(entity_name)
    local def = minetest.registered_entities[entity_name]
    if def then
        local old_on_step = def.on_step
        def.on_step = function(self, dtime, moveresult)
            -- Apply dynamic lateral drag on ground vs in air
            if self.isonground then
                self._later_drag_factor = 15.0
            else
                self._later_drag_factor = 2.0 -- restore to default for aerodynamics
            end
            
            -- Call the original step function
            if old_on_step then
                old_on_step(self, dtime, moveresult)
            end
        end
        minetest.log("action", "[aircraft_tweaks] Applied lateral drag fix to " .. entity_name)
    end
end

minetest.register_on_mods_loaded(function()
    if minetest.get_modpath("supercub") then
        apply_lateral_drag_fix("supercub:supercub")
    end
    
    if minetest.get_modpath("hidroplane") then
        apply_lateral_drag_fix("hidroplane:hidro")
    end

    if minetest.get_modpath("pa28") then
        apply_lateral_drag_fix("pa28:pa28")
    end
end)
