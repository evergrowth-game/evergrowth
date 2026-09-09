local SPACE_ALTITUDE_THRESHOLD = 1000

-- Dynamically unregister legacy other_worlds skybox globalstep so other_worlds remains unmodified
if minetest.registered_globalsteps then
	for i = #minetest.registered_globalsteps, 1, -1 do
		local fn = minetest.registered_globalsteps[i]
		local info = debug.getinfo(fn, "S")
		if info and info.source and (info.source:find("other_worlds/skybox%.lua") or info.source:find("other_worlds[/\\]skybox%.lua")) then
			table.remove(minetest.registered_globalsteps, i)
		end
	end
end

local function make_space_skybox(earth_texture, colorize)
	local neg_y = earth_texture
	if colorize then
		neg_y = neg_y .. "^[colorize:" .. colorize
		return {
			"sky_pos_z.png^[colorize:" .. colorize,
			neg_y,
			"sky_neg_y.png^[transformR270^[colorize:" .. colorize,
			"sky_pos_y.png^[transformR270^[colorize:" .. colorize,
			"sky_pos_x.png^[transformR270^[colorize:" .. colorize,
			"sky_neg_x.png^[transformR90^[colorize:" .. colorize
		}
	end
	return {
		"sky_pos_z.png",
		neg_y,
		"sky_neg_y.png^[transformR270",
		"sky_pos_y.png^[transformR270",
		"sky_pos_x.png^[transformR270",
		"sky_neg_x.png^[transformR90"
	}
end

local skyboxes = {
	space_low = make_space_skybox("space_earth_low.png"),
	space_mid = make_space_skybox("space_earth_mid.png"),
	space_high = make_space_skybox("space_earth_high.png"),
	redsky = make_space_skybox("space_earth_mars.png", "#99000050"),
	blackness = make_space_skybox("space_earth_deep.png", "#00005070"),
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
	if y >= 8000 then
		return "blackness"
	elseif y >= 6000 then
		return "redsky"
	elseif y >= 4500 then
		return "space_high"
	elseif y >= 2500 then
		return "space_mid"
	elseif y >= 1000 then
		return "space_low"
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

	local textures = skyboxes[realm] or skyboxes.space_low
	local sun_scale = 1.0
	local show_stars = false

	if realm == "blackness" then
		sun_scale = 0.1
	elseif realm == "redsky" then
		sun_scale = 0.5
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
	if timer < 0.5 then return end
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

minetest.register_on_joinplayer(function(player)
	local pos = player:get_pos()
	if pos then
		local realm = get_realm(pos.y)
		player_realm_state[player:get_player_name()] = realm
		apply_space_skybox(player, realm)
	end
end)

minetest.register_on_leaveplayer(function(player)
	player_realm_state[player:get_player_name()] = nil
end)

other_worlds_tweaks_climate = {
	get_realm = get_realm,
	apply_space_skybox = apply_space_skybox,
	skyboxes = skyboxes,
	player_realm_state = player_realm_state,
}


