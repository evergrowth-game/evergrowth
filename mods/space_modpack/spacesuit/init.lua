spacesuit = {
	armor_use = tonumber(core.settings:get("spacesuit.armor_use")) or 70,
}

local MP = core.get_modpath("spacesuit")

dofile(MP.."/suit.lua")
dofile(MP.."/crafts.lua")

local space_enabled = minetest.settings:get_bool("enable_space", true)
if space_enabled then
	dofile(MP.."/hud.lua")
	dofile(MP.."/drowning.lua")
end

