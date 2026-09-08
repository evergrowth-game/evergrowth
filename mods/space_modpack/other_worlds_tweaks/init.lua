-- other_worlds_tweaks/init.lua

local modpath = minetest.get_modpath("other_worlds_tweaks")

dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/gravity.lua")
dofile(modpath .. "/climate_hook.lua")
dofile(modpath .. "/derelicts.lua")
dofile(modpath .. "/asteroid_mapgen.lua")
dofile(modpath .. "/solar_hook.lua")
dofile(modpath .. "/electrolyzer_hook.lua")

local function trigger_scanner(itemstack, user, pointed_thing)
	if not user or (user.is_player and not user:is_player()) then return itemstack end
	if other_worlds_tweaks_derelicts and other_worlds_tweaks_derelicts.scan_and_spawn_freighter then
		local success = other_worlds_tweaks_derelicts.scan_and_spawn_freighter(user)
		if success then
			itemstack:take_item()
			return itemstack
		end
	end
	return itemstack
end

-- Register Subspace Distress Scanner
minetest.register_craftitem("other_worlds_tweaks:derelict_scanner", {
	description = "Subspace Distress Scanner\n" ..
		"Right-click in orbital space (Y >= 1,000) to scan for and navigate to abandoned deep space capital freighters.",
	inventory_image = "jumpdrive_warpdevice.png^[colorize:#a855f7:140",
	stack_max = 16,
	on_place = trigger_scanner,
	on_secondary_use = trigger_scanner,
})

-- Crafting Recipes
local has_techage = minetest.get_modpath("techage") ~= nil
if has_techage then
	minetest.register_craft({
		output = "other_worlds_tweaks:derelict_scanner",
		recipe = {
			{"techage:ta4_wlanchip", "default:gold_ingot", "techage:ta4_wlanchip"},
			{"default:copper_ingot", "techage:cylinder_small_hydrogen", "default:copper_ingot"},
			{"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"}
		}
	})
else
	minetest.register_craft({
		output = "other_worlds_tweaks:derelict_scanner",
		recipe = {
			{"default:mese_crystal", "default:gold_ingot", "default:mese_crystal"},
			{"default:copper_ingot", "default:diamond", "default:copper_ingot"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
		}
	})
end

minetest.log("action", "[other_worlds_tweaks] Loaded space worldgen tweaks, rich ores, gravity monoids, climate hooks, asteroid mapgen, space derelicts, subspace distress scanner, orbital solar power, and water-fed electrolyzer ISRU hook.")

