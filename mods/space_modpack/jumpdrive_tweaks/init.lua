-- jumpdrive_tweaks/init.lua

local modpath = minetest.get_modpath("jumpdrive_tweaks")

dofile(modpath .. "/nodes_fuel.lua")
dofile(modpath .. "/techage_pipe.lua")
dofile(modpath .. "/validator.lua")
dofile(modpath .. "/decouple.lua")

minetest.log("action", "[jumpdrive_tweaks] Loaded Techage fuel tanks, ports, validator, and decoupling hooks.")
