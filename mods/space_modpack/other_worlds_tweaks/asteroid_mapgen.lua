-- other_worlds_tweaks/asteroid_mapgen.lua
-- Overhauls space asteroid and comet resource distribution with rich, balanced ores and exotic materials.

local XMIN = -33000
local XMAX = 33000
local ZMIN = -33000
local ZMAX = 33000

local ASCOT = 1.0   -- Large asteroid / comet nucleus noise threshold
local SASCOT = 1.0  -- Small asteroid / comet nucleus noise threshold
local STOT = 0.125  -- Asteroid stone threshold (solid core)
local COBT = 0.05   -- Asteroid cobble threshold
local GRAT = 0.02   -- Asteroid gravel threshold
local ICET = 0.05   -- Comet ice threshold
local ATMOT = -0.2  -- Comet atmosphere threshold
local FISTS = 0.01  -- Fissure noise threshold
local FISEXP = 0.3  -- Fissure expansion rate
local ORECHA = 6    -- Ore chance: 1 in 6 stone nodes is a valuable ore block (abundant yield)

local random = math.random
local floor = math.floor
local abs = math.abs

local np_large = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 128, z = 256},
	seed = -83928935,
	octaves = 5,
	persist = 0.6
}

local np_fissure = {
	offset = 0,
	scale = 1,
	spread = {x = 64, y = 64, z = 64},
	seed = -188881,
	octaves = 4,
	persist = 0.5
}

local np_small = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 64, z = 128},
	seed = 1000760700090,
	octaves = 4,
	persist = 0.6
}

local np_ores = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 128, z = 128},
	seed = -70242,
	octaves = 1,
	persist = 0.5
}

local np_latmos = {
	offset = 0,
	scale = 1,
	spread = {x = 256, y = 128, z = 256},
	seed = -83928935,
	octaves = 3,
	persist = 0.6
}

local np_satmos = {
	offset = 0,
	scale = 1,
	spread = {x = 128, y = 64, z = 128},
	seed = 1000760700090,
	octaves = 2,
	persist = 0.6
}

-- Content IDs
local c_air = minetest.get_content_id("air")
local c_atmos = minetest.get_content_id("asteroid:atmos")
local c_stone = minetest.get_content_id("asteroid:stone")
local c_cobble = minetest.get_content_id("asteroid:cobble")
local c_gravel = minetest.get_content_id("asteroid:gravel")
local c_dust = minetest.get_content_id("asteroid:dust")
local c_snowblock = minetest.get_content_id("default:snowblock")

-- Rich Ores & Volatiles
local c_rich_diamond = minetest.get_content_id("other_worlds_tweaks:rich_diamond_ore")
local c_rich_mese = minetest.get_content_id("other_worlds_tweaks:rich_mese_ore")
local c_rich_gold = minetest.get_content_id("other_worlds_tweaks:rich_gold_ore")
local c_rich_copper = minetest.get_content_id("other_worlds_tweaks:rich_copper_ore")
local c_rich_tin = minetest.get_content_id("other_worlds_tweaks:rich_tin_ore")
local c_rich_coal = minetest.get_content_id("other_worlds_tweaks:rich_coal_ore")
local c_rich_iron = minetest.get_content_id("other_worlds_tweaks:rich_iron_ore")
local c_comet_ice = minetest.get_content_id("other_worlds_tweaks:comet_ice")

-- Magic Materials & TechAge integration
local has_magic = minetest.get_modpath("magic_materials")
local c_egerum = has_magic and minetest.get_content_id("magic_materials:stone_with_egerum") or c_rich_diamond
local c_februm = has_magic and minetest.get_content_id("magic_materials:stone_with_februm") or c_rich_mese

local has_techage = minetest.get_modpath("techage")
local c_baborium = has_techage and minetest.get_content_id("techage:stone_with_baborium") or c_rich_diamond

-- Redsky specific
local c_redstone = minetest.get_content_id("asteroid:redstone")
local c_redgravel = minetest.get_content_id("asteroid:redgravel")
local c_reddust = minetest.get_content_id("asteroid:reddust")

-- Specialized Ore Selectors for Space Tiers
local function select_space_ore()
	local roll = random(1, 100)
	if roll <= 18 then
		return c_rich_diamond
	elseif roll <= 34 then
		return c_rich_mese
	elseif roll <= 48 then
		return c_rich_gold
	elseif roll <= 62 then
		return (random(1, 2) == 1) and c_egerum or c_februm
	elseif roll <= 78 then
		return c_rich_copper
	elseif roll <= 90 then
		return c_rich_tin
	elseif roll <= 96 then
		return c_rich_iron
	else
		return c_rich_coal
	end
end

local function select_redsky_ore()
	local roll = random(1, 100)
	if roll <= 25 then
		return c_baborium
	elseif roll <= 50 then
		return c_rich_iron
	elseif roll <= 70 then
		return c_rich_gold
	elseif roll <= 85 then
		return c_rich_copper
	else
		return c_rich_tin
	end
end

local function select_deep_space_ore()
	local roll = random(1, 100)
	if roll <= 30 then
		return c_baborium
	elseif roll <= 55 then
		return c_rich_diamond
	elseif roll <= 80 then
		return c_rich_mese
	else
		return c_rich_gold
	end
end

-- Core generator function for space, redsky, and deep space layers
local function generate_asteroid_chunk(minp, maxp, seed, layer_type, ymin, ymax)
	if minp.x < XMIN or maxp.x > XMAX
	or minp.y < ymin or maxp.y > ymax
	or minp.z < ZMIN or maxp.z > ZMAX then
		return
	end

	local x0, y0, z0 = minp.x, minp.y, minp.z
	local x1, y1, z1 = maxp.x, maxp.y, maxp.z

	local sidelen = x1 - x0 + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minpos = {x = x0, y = y0, z = z0}

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()

	local nvals1 = minetest.get_perlin_map(np_large, chulens):get_3d_map_flat(minpos)
	local nvals3 = minetest.get_perlin_map(np_fissure, chulens):get_3d_map_flat(minpos)
	local nvals4 = minetest.get_perlin_map(np_small, chulens):get_3d_map_flat(minpos)
	local nvals6 = minetest.get_perlin_map(np_latmos, chulens):get_3d_map_flat(minpos)
	local nvals7 = minetest.get_perlin_map(np_satmos, chulens):get_3d_map_flat(minpos)

	local ni = 1
	local noise1abs, noise4abs, comet, noise1dep, noise4dep, vi

	local is_redsky = (layer_type == "redsky")
	local is_deep = (layer_type == "blackness")

	local stone_id = is_redsky and c_redstone or c_stone
	local cobble_id = is_redsky and c_air or c_cobble
	local gravel_id = is_redsky and c_redgravel or c_gravel
	local dust_id = is_redsky and c_reddust or c_dust

	-- Thresholds: deep space asteroids are rarer and larger
	local ascot = is_deep and 1.12 or ASCOT
	local sascot = is_deep and 1.12 or SASCOT
	local ore_chance = is_deep and 4 or ORECHA

	local select_ore_func
	if is_deep then
		select_ore_func = select_deep_space_ore
	elseif is_redsky then
		select_ore_func = select_redsky_ore
	else
		select_ore_func = select_space_ore
	end

	for z = z0, z1 do
	for y = y0, y1 do
		vi = area:index(x0, y, z)
		for x = x0, x1 do
			noise1abs = abs(nvals1[ni])
			noise4abs = abs(nvals4[ni])
			comet = false

			if nvals6[ni] < -(ascot + ATMOT)
			or (nvals7[ni] < -(sascot + ATMOT) and nvals1[ni] < ascot) then
				comet = true
			end

			if noise1abs > ascot or noise4abs > sascot then
				noise1dep = noise1abs - ascot
				if abs(nvals3[ni]) > FISTS + noise1dep * FISEXP then
					noise4dep = noise4abs - sascot

					if not comet or (comet and (noise1dep > random() + ICET or noise4dep > random() + ICET)) then
						if noise1dep >= STOT or noise4dep >= STOT then
							-- Solid Core: Rich multi-ore generation
							if random(ore_chance) == 1 then
								data[vi] = select_ore_func()
							else
								data[vi] = stone_id
							end
						elseif noise1dep >= COBT or noise4dep >= COBT then
							data[vi] = cobble_id
						elseif noise1dep >= GRAT or noise4dep >= GRAT then
							data[vi] = gravel_id
						else
							data[vi] = dust_id
						end
					else
						-- Comet Volatiles: Rich comet ice for water and propellant
						if noise1dep >= ICET or noise4dep >= ICET then
							data[vi] = c_comet_ice
						else
							data[vi] = c_snowblock
						end
					end
				elseif comet then
					data[vi] = c_atmos
				end
			elseif comet then
				data[vi] = c_atmos
			end

			ni = ni + 1
			vi = vi + 1
		end
	end
	end

	vm:set_data(data)
	vm:write_to_map()
end

-- Unregister old upstream other_worlds mapgen functions
for i = #minetest.registered_on_generateds, 1, -1 do
	local info = debug.getinfo(minetest.registered_on_generateds[i], "S")
	if info and info.source and (info.source:find("other_worlds/space_asteroids.lua") or info.source:find("other_worlds/redsky_asteroids.lua") or info.source:find("other_worlds/asteroid_layer_helpers.lua")) then
		table.remove(minetest.registered_on_generateds, i)
	end
end

-- Register Space Asteroid generator (Y = 5000 to 5999)
minetest.register_on_generated(function(minp, maxp, seed)
	local ymin = otherworlds.settings.space_asteroids.YMIN or 5000
	local ymax = otherworlds.settings.space_asteroids.YMAX or 5999
	generate_asteroid_chunk(minp, maxp, seed, "space", ymin, ymax)
end)

-- Register Redsky / Mars generator (Y = 6000 to 6999)
minetest.register_on_generated(function(minp, maxp, seed)
	local ymin = otherworlds.settings.redsky_asteroids.YMIN or 6000
	local ymax = otherworlds.settings.redsky_asteroids.YMAX or 6999
	generate_asteroid_chunk(minp, maxp, seed, "redsky", ymin, ymax)
end)

-- Register Deep Space Primordial Mega-Asteroid generator (Y = 7000 to 31000)
minetest.register_on_generated(function(minp, maxp, seed)
	local ymin = otherworlds.settings.blackness.YMIN or 7000
	local ymax = otherworlds.settings.blackness.YMAX or 31000
	generate_asteroid_chunk(minp, maxp, seed, "blackness", ymin, ymax)
end)

minetest.log("action", "[other_worlds_tweaks] Registered overhauled high-yield space, mars, and deep space asteroid & comet mapgen.")
