
-- Load support for intllib.
local path = minetest.get_modpath(minetest.get_current_modname()) .. "/"

local S = minetest.get_translator and minetest.get_translator("raiders") or
		dofile(path .. "intllib.lua")

mobs.intllib = S

-- Load Raiders and support
dofile(path .. "bootynode.lua")
dofile(path .. "plunderercrossbow.lua")
dofile(path .. "pirate.lua")
dofile(path .. "plundererstick.lua")
dofile(path .. "plundererflask.lua")
dofile(path .. "spawnbooty.lua")

print (S("[MOD] Raiders loaded"))
