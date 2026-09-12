-- jumpdrive_tweaks/init.lua

local modpath = minetest.get_modpath("jumpdrive_tweaks")

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

dofile(modpath .. "/nodes_fuel.lua")
dofile(modpath .. "/techage_pipe.lua")
dofile(modpath .. "/ship_tracker.lua")
dofile(modpath .. "/techage_compat.lua")
dofile(modpath .. "/terrain_filter.lua")
dofile(modpath .. "/jump_fx.lua")
dofile(modpath .. "/validator.lua")
dofile(modpath .. "/decouple.lua")
dofile(modpath .. "/beacon.lua")
dofile(modpath .. "/ice_melter.lua")
dofile(modpath .. "/rangefinder.lua")
dofile(modpath .. "/crafts.lua")
dofile(modpath .. "/formspec.lua")
dofile(modpath .. "/bridge_console.lua")
dofile(modpath .. "/jump_lever.lua")

minetest.log("action", "[jumpdrive_tweaks] Loaded Techage fuel tanks, ports, thermal ice melter, validator, terrain filter, rangefinder, crafts, decoupling hooks, ship beacon/tether, bridge navigation console, quick-jump lever, and hyperjump FX.")


