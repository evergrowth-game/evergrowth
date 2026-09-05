-- other_worlds_tweaks/climate_hook.lua
-- Suppress climate weather, precipitation, and wind loops above Y >= 2000

local SPACE_ALTITUDE_THRESHOLD = 2000

minetest.register_on_mods_loaded(function()
	if climate_mod and climate_mod.trigger then
		local old_get_position_env = climate_mod.trigger.get_position_environment
		if old_get_position_env then
			climate_mod.trigger.get_position_environment = function(pos)
				local env = old_get_position_env(pos)
				if pos and pos.y >= SPACE_ALTITUDE_THRESHOLD then
					env.precipitation = 0
					env.temperature = 0
					env.humidity = 0
					env.wind = 0
					env.sheltered = true
					env.light = 15
				end
				return env
			end
		end

		local old_get_player_env = climate_mod.trigger.get_player_environment
		if old_get_player_env then
			climate_mod.trigger.get_player_environment = function(player)
				local env = old_get_player_env(player)
				if env then
					local ppos = player:get_pos()
					if ppos and ppos.y >= SPACE_ALTITUDE_THRESHOLD then
						env.precipitation = 0
						env.temperature = 0
						env.humidity = 0
						env.wind = 0
						env.sheltered = true
						env.light = 15
					end
				end
				return env
			end
		end
	end
end)
