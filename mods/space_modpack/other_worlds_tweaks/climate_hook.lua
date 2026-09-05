-- other_worlds_tweaks/climate_hook.lua
-- Suppress climate weather, precipitation, and wind loops above Y >= 2000
-- and seamlessly integrate space skyboxes with climate_api sky merger.

local SPACE_ALTITUDE_THRESHOLD = 2000

local spaceskybox = {
	"sky_pos_z.png",
	"sky_neg_z.png^[transformR180",
	"sky_neg_y.png^[transformR270",
	"sky_pos_y.png^[transformR270",
	"sky_pos_x.png^[transformR270",
	"sky_neg_x.png^[transformR90"
}

local redskybox = {
	"sky_pos_z.png^[colorize:#99000050",
	"sky_neg_z.png^[transformR180^[colorize:#99000050",
	"sky_neg_y.png^[transformR270^[colorize:#99000050",
	"sky_pos_y.png^[transformR270^[colorize:#99000050",
	"sky_pos_x.png^[transformR270^[colorize:#99000050",
	"sky_neg_x.png^[transformR90^[colorize:#99000050"
}

local darkskybox = {
	"sky_pos_z.png^[colorize:#00005070",
	"sky_neg_z.png^[transformR180^[colorize:#00005070",
	"sky_neg_y.png^[transformR270^[colorize:#00005070",
	"sky_pos_y.png^[transformR270^[colorize:#00005070",
	"sky_pos_x.png^[transformR270^[colorize:#00005070",
	"sky_neg_x.png^[transformR90^[colorize:#00005070"
}

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

-- Track player skybox states
local player_realm_state = {}

local function get_realm(y)
	if y >= 7000 then
		return "blackness"
	elseif y >= 6000 then
		return "redsky"
	elseif y >= 5000 then
		return "space"
	else
		return "earth"
	end
end

local function apply_space_skybox(player, realm)
	local playername = player:get_player_name()
	local has_climate_sky = climate_api and climate_api.skybox and climate_api.skybox.add

	if realm == "earth" then
		if has_climate_sky then
			climate_api.skybox.remove(playername, "other_worlds")
			climate_api.skybox.update(playername)
		else
			player:set_sky({type = "regular", clouds = true})
			player:set_clouds({density = 0.4, thickness = 16})
			player:set_moon({visible = true})
			player:set_stars({visible = true})
			player:set_sun({visible = true, scale = 1.0, sunrise_visible = true})
		end
		return
	end

	local textures, sun_scale, show_stars
	if realm == "blackness" then
		textures = darkskybox
		sun_scale = 0.1
		show_stars = true
	elseif realm == "redsky" then
		textures = redskybox
		sun_scale = 0.5
		show_stars = false
	else -- space
		textures = spaceskybox
		sun_scale = 1.0
		show_stars = false
	end

	if has_climate_sky then
		climate_api.skybox.add(playername, "other_worlds", {
			priority = 100,
			sky_data = {
				type = "skybox",
				textures = textures,
				clouds = false,
				base_color = "#000000"
			},
			cloud_data = {
				density = 0,
				thickness = 0
			},
			sun_data = {
				visible = true,
				scale = sun_scale,
				sunrise_visible = false
			},
			moon_data = {
				visible = false
			},
			star_data = {
				visible = show_stars,
				count = show_stars and 2000 or 0,
				scale = 1
			},
			light_data = {
				shadow_intensity = 0.8,
				saturation = 1.0
			}
		})
		climate_api.skybox.update(playername)
	else
		player:set_sky({
			type = "skybox",
			textures = textures,
			clouds = false,
			base_color = "#000000"
		})
		player:set_clouds({density = 0, thickness = 0})
		player:set_moon({visible = false})
		player:set_stars({visible = show_stars, count = show_stars and 2000 or 0})
		player:set_sun({visible = true, scale = sun_scale, sunrise_visible = false})
	end
end

-- Skybox state sync loop
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 1.0 then return end
	timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:get_pos()
		if pos then
			local current_realm = get_realm(pos.y)
			if player_realm_state[name] ~= current_realm then
				player_realm_state[name] = current_realm
				apply_space_skybox(player, current_realm)
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	player_realm_state[player:get_player_name()] = nil
end)

