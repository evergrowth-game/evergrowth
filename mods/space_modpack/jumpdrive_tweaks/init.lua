-- jumpdrive_tweaks/init.lua

local modpath = minetest.get_modpath("jumpdrive_tweaks")

dofile(modpath .. "/nodes_fuel.lua")
dofile(modpath .. "/techage_pipe.lua")
dofile(modpath .. "/validator.lua")
dofile(modpath .. "/terrain_filter.lua")
dofile(modpath .. "/decouple.lua")
dofile(modpath .. "/beacon.lua")
dofile(modpath .. "/crafts.lua")

minetest.log("action", "[jumpdrive_tweaks] Loaded Techage fuel tanks, ports, validator, terrain filter, crafts, decoupling hooks, and ship beacon/tether.")


