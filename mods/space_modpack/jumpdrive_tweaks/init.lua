-- jumpdrive_tweaks/init.lua

local modpath = minetest.get_modpath("jumpdrive_tweaks")

dofile(modpath .. "/nodes_fuel.lua")
dofile(modpath .. "/techage_pipe.lua")
dofile(modpath .. "/ship_tracker.lua")
dofile(modpath .. "/terrain_filter.lua")
dofile(modpath .. "/validator.lua")
dofile(modpath .. "/decouple.lua")
dofile(modpath .. "/beacon.lua")
dofile(modpath .. "/ice_melter.lua")
dofile(modpath .. "/crafts.lua")
dofile(modpath .. "/formspec.lua")

minetest.log("action", "[jumpdrive_tweaks] Loaded Techage fuel tanks, ports, thermal ice melter, validator, terrain filter, crafts, decoupling hooks, ship beacon/tether, and diegetic flight computer UI.")


