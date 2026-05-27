-- Forecast Command
-- Predicts future weather trends by peeking at the Perlin noise values

-- Parameters copied from climate_api/lib/world.lua to match the simulation
local WIND_SCALE = 2
local HEAT_SCALE = 0.3
local HUMIDITY_SCALE = 1
local HUMIDITY_TIMESCALE = 1

local pn_heat = {
	offset = 1,
	scale = HEAT_SCALE,
	spread = {x = 400, y = 400, z = 400},
	seed = 235896,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2
}

local pn_humidity = {
	offset = 1,
	scale = HUMIDITY_SCALE,
	spread = {x = 150, y = 150, z = 150},
	seed = 8374061,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2,
	flags = "noeased"
}

-- Re-create the noise objects locally (Lazy initialization)
local nobj_heat
local nobj_humidity

local pn_wind_speed_x = {
	offset = 0,
	scale = WIND_SCALE,
	spread = {x = 600, y = 600, z = 600},
	seed = 31441,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2
}

local BASE_TIME = 0.2	-- Default time spread multiplier (world.lua L2)

local pn_wind_speed_z = {
	offset = 0,
	scale = WIND_SCALE,
	spread = {x = 600, y = 600, z = 600},
	seed = 938402,
	octaves = 2,
	persist = 0.5,
	lacunarity = 2
}

local nobj_wind_x
local nobj_wind_z

local function sigmoid(value, max, growth, midpoint)
	return max / (1 + math.exp(-growth * (value - midpoint)))
end

-- Helper functions from api_utility.lua
local function rangelim(value, min, max)
	return math.min(math.max(value, min), max)
end

local function normalized_cycle(value)
	return math.cos((2 * value + 1) * math.pi) / 2 + 0.5
end

-- Helper to interpret values
local function get_season_desc(val)
	if val > 0.3 then return minetest.colorize("#ffdd44", "Summer Heat") -- Bright Gold
	elseif val > 0 then return minetest.colorize("#aaffaa", "Mild / Spring") -- Mint Green
	elseif val > -0.3 then return minetest.colorize("#88ccff", "Cool / Autumn") -- Sky Blue
	else return minetest.colorize("#ffffff", "Deep Winter") end -- White (clean contrast)
end

local function get_humidity_desc(val)
	if val > 1.2 then return minetest.colorize("#6699ff", "Storm Surge") -- Light Royal Blue
	elseif val > 0.8 then return minetest.colorize("#99bbff", "Wet / Rainy") -- Periwinkle
	elseif val > 0.4 then return minetest.colorize("#eeeeee", "Average Humidity") -- Light Grey
	else return minetest.colorize("#ffffaa", "Dry Spell") end -- Pale Yellow
end

local function get_wind_desc(val)
	if val > 5 then return minetest.colorize("#ff8888", "Gale Force")
	elseif val > 3 then return minetest.colorize("#ffaaff", "Windy")
	elseif val > 1 then return minetest.colorize("#ffffff", "Breezy")
	else return "" end
end

minetest.register_chatcommand("forecast", {
	description = "Predict upcoming weather changes",
	func = function(name)
		-- Lazy init
		nobj_heat = nobj_heat or minetest.get_perlin(pn_heat)
		nobj_humidity = nobj_humidity or minetest.get_perlin(pn_humidity)
		nobj_wind_x = nobj_wind_x or minetest.get_perlin(pn_wind_speed_x)
		nobj_wind_z = nobj_wind_z or minetest.get_perlin(pn_wind_speed_z)

		local player = minetest.get_player_by_name(name)
		if not player then return end
		local ppos = player:get_pos()
		local gametime = minetest.get_gametime()
		
		-- 24000 ticks = 1 day. minetest.get_timeofday() returns 0-1. 
		local timeofday = math.floor(minetest.get_timeofday() * 24000)
		local hour = math.floor(timeofday / 1000)
		local minute = math.floor((timeofday % 1000) / 16.6)
		local timestamp = string.format("%02d:%02d", hour, minute)
		
		local speed = tonumber(minetest.settings:get("climate_api_time_spread")) or 1
		local time = math.floor(gametime * BASE_TIME * speed)
		
		-- Current Values
		local cur_heat_noise = nobj_heat:get_2d({x = time, y = 0})
		local cur_humid_noise = nobj_humidity:get_2d({x = time * HUMIDITY_TIMESCALE, y = 0})
		
		-- Build Report
		local msg = minetest.colorize("#ffaaff", "Weather Forecast ("..timestamp..")") .. "\n"
		msg = msg .. get_season_desc(cur_heat_noise) .. " · " .. get_humidity_desc(cur_humid_noise) .. "\n"

		-- FIND TRANSITIONS
		local change_found = false
		for m = 1, 15 do
			local future_t = math.floor((gametime + (m * 60)) * BASE_TIME * speed)
			local fut_heat = nobj_heat:get_2d({x = future_t, y = 0})
			local fut_humid = nobj_humidity:get_2d({x = future_t * HUMIDITY_TIMESCALE, y = 0})
			
			if cur_humid_noise > 0.8 and fut_humid <= 0.8 then
				msg = msg .. minetest.colorize("#ffff88", "Rain stopping in " .. m .. " min") .. "\n"
				change_found = true
				break
			elseif cur_humid_noise <= 0.8 and fut_humid > 0.8 then
				msg = msg .. minetest.colorize("#8888ff", "Rain starting in " .. m .. " min") .. "\n"
				change_found = true
				break
			elseif cur_heat_noise <= -0.3 and fut_heat > -0.3 then
				msg = msg .. minetest.colorize("#aaffaa", "Deep freeze ending in " .. m .. " min") .. "\n"
				change_found = true
				break
			end
		end

		if not change_found then
			msg = msg .. "No major changes in the next 15 min\n"
		end

		-- LOCAL IMPACT CALCULATION
		-- Formulas copied from climate_api/lib/environment.lua
		local base_heat = tonumber(minetest.settings:get("climate_api_heat_base")) or 50
		local base_humid = tonumber(minetest.settings:get("climate_api_humidity_base")) or 50
		
		local biome_data = minetest.get_biome_data(ppos)
		local biome_heat = biome_data.heat
		local biome_humid = biome_data.humidity
		local biome_name = minetest.get_biome_name(biome_data.biome)
		
		-- Heat Calc
		local height = rangelim((-ppos.y + 10) / 15, -10, 10)
		local time_factor = normalized_cycle(minetest.get_timeofday()) * 0.6 + 0.7
		local local_heat = base_heat + ((biome_heat + height) * time_factor * cur_heat_noise)
		
		-- Humidity Calc
		local local_humid = base_humid + ((biome_humid * 0.7 + 40 * 0.3) * cur_humid_noise)

		-- Wind Calc
		local wx = nobj_wind_x:get_2d({x = time, y = 0})
		local wz = nobj_wind_z:get_2d({x = time, y = 0})
		local height_mod = sigmoid(ppos.y, 2, 0.02, 1)
		local local_wind = math.sqrt(wx*wx + wz*wz) * height_mod

		-- Local Impact Report
		msg = msg .. minetest.colorize("#ffaaff", "Local Conditions") .. "\n"
		
		-- Interpret Local Heat
		local local_temp_desc = ""
		if local_heat > 80 then local_temp_desc = minetest.colorize("#ff8800", "Hot")
		elseif local_heat > 35 then local_temp_desc = minetest.colorize("#aaffaa", "Temperate")
		else local_temp_desc = minetest.colorize("#88ccff", "Freezing") end
		
		msg = msg .. local_temp_desc
		
		-- Add Wind Desc
		local wind_desc = get_wind_desc(local_wind)
		if wind_desc ~= "" then
			msg = msg .. " · " .. wind_desc
		end
		
		-- Interpret Local Weather
		-- Sandstorm: Desert Biome + Wind > 3
		local is_desert = string.find(biome_name, "desert")
		
		if is_desert and local_wind > 3 and local_humid > 50 then
			msg = msg .. minetest.colorize("#ffaa00", " · Sandstorm Likely")
		elseif local_humid > 50 and local_heat > 35 and local_heat <= 90 then
			-- Standard Rain (capped at 90F for user realism request)
			msg = msg .. minetest.colorize("#8888ff", " · Rain Likely")
		elseif local_heat <= 35 and local_humid > 50 then
			msg = msg .. minetest.colorize("#ffffff", " · Snow Likely")
		else
			msg = msg .. minetest.colorize("#ffff88", " · Clear Sky")
		end

		minetest.chat_send_player(name, msg)
	end
})
