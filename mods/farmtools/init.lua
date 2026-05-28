local modpath = core.get_modpath(core.get_current_modname())

---@diagnostic disable-next-line: lowercase-global
farmtools = {}
farmtools.i18n = core.get_translator("farmtools")

-- load code related to scythes, rakes and sickles
dofile(modpath .. "/lib/scythes.lua")
dofile(modpath .. "/lib/rakes.lua")
dofile(modpath .. "/lib/sickles.lua")

-- shadow the original sickles mod if it is enabled
dofile(modpath .. "/lib/fork.lua")

-- register tools
dofile(modpath .. "/lib/tools.lua")

-- register moss and flower petals and ensure compatibility with other mods
dofile(modpath .. "/lib/moss.lua")
dofile(modpath .. "/lib/compatibility.lua")

-- finally register nodes that are cuttable/trimmable by sickles
dofile(modpath .. "/lib/cuttables.lua")
