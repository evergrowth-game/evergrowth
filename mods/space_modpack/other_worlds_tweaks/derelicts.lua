-- other_worlds_tweaks/derelicts.lua
-- Procedural generation of abandoned space derelicts (probes, shuttles, research modules)
-- Built 100% with existing in-game nodes and items.

local derelicts = {}
other_worlds_tweaks_derelicts = derelicts

local random = math.random
local floor = math.floor

-- Content IDs (resolved on load)
local c_air
local c_vacuum
local c_ignore
local c_steelblock
local c_bronzeblock
local c_copperblock
local c_obsidian_glass
local c_chest_ta3
local c_chest_ta4
local c_solar_module
local c_solar_carrier
local c_electrolyzer
local c_fuel_tank
local c_beacon

local function init_content_ids()
	c_air = minetest.get_content_id("air")
	c_vacuum = minetest.get_content_id("vacuum:vacuum")
	c_ignore = minetest.get_content_id("ignore")
	c_steelblock = minetest.get_content_id("default:steelblock")
	c_bronzeblock = minetest.get_content_id("default:bronzeblock")
	c_copperblock = minetest.get_content_id("default:copperblock")
	c_obsidian_glass = minetest.get_content_id("default:obsidian_glass")

	local has_techage = minetest.get_modpath("techage") ~= nil
	local has_jumpdrive = minetest.get_modpath("jumpdrive_tweaks") ~= nil

	local default_chest_id = minetest.registered_nodes["default:chest"]
		and minetest.get_content_id("default:chest") or c_steelblock

	c_chest_ta3 = (has_techage and minetest.registered_nodes["techage:chest_ta3"])
		and minetest.get_content_id("techage:chest_ta3") or default_chest_id

	c_chest_ta4 = (has_techage and minetest.registered_nodes["techage:chest_ta4"])
		and minetest.get_content_id("techage:chest_ta4") or c_chest_ta3

	c_solar_module = (has_techage and minetest.registered_nodes["techage:ta4_solar_module"])
		and minetest.get_content_id("techage:ta4_solar_module") or c_steelblock

	c_solar_carrier = (has_techage and minetest.registered_nodes["techage:ta4_solar_carrier"])
		and minetest.get_content_id("techage:ta4_solar_carrier") or c_steelblock

	c_electrolyzer = (has_techage and minetest.registered_nodes["techage:ta4_electrolyzer"])
		and minetest.get_content_id("techage:ta4_electrolyzer") or c_steelblock

	c_fuel_tank = (has_jumpdrive and minetest.registered_nodes["jumpdrive_tweaks:fuel_tank"])
		and minetest.get_content_id("jumpdrive_tweaks:fuel_tank") or c_steelblock

	c_beacon = (has_jumpdrive and minetest.registered_nodes["jumpdrive_tweaks:beacon"])
		and minetest.get_content_id("jumpdrive_tweaks:beacon") or c_copperblock

	c_dirt = (minetest.registered_nodes and minetest.registered_nodes["default:dirt"])
		and minetest.get_content_id("default:dirt") or c_steelblock

	c_dirt_with_grass = (minetest.registered_nodes and minetest.registered_nodes["default:dirt_with_grass"])
		and minetest.get_content_id("default:dirt_with_grass") or c_dirt
end

-- -------------------------------------------------------------------------
-- 1. SCHEMATIC DEFINITIONS (Relative 3D coordinates: dx, dy, dz, content_id, param2, is_chest, chest_tier)
-- -------------------------------------------------------------------------

local function get_probe_schematic()
	if not c_air then init_content_ids() end
	-- Adrift Science Probe (~5x4x5)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- Central chassis
	add(0, 0, 0, c_steelblock)
	add(0, 0, 1, c_steelblock)
	add(0, 0, -1, c_steelblock)
	add(0, 1, 0, c_copperblock)        -- Antenna base
	add(0, 2, 0, c_copperblock)        -- Antenna spire
	add(0, 0, 2, c_obsidian_glass)     -- Sensor lens

	-- Solar wings (flat TA4 solar modules)
	add(1, 0, 0, c_solar_module)
	add(2, 0, 0, c_solar_module)
	add(-1, 0, 0, c_solar_module)
	add(-2, 0, 0, c_solar_module)

	-- Salvage container (accessible on top-deck aft chassis)
	add(0, 1, -1, c_chest_ta3, 0, true, "probe")

	return {
		name = "probe",
		size = {x = 5, y = 4, z = 5},
		radius = 3,
		nodes = nodes
	}
end
derelicts.get_probe_schematic = get_probe_schematic

local function get_shuttle_schematic()
	if not c_air then init_content_ids() end
	-- Abandoned Fuel Shuttle (~5x4x7)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- Fuselage bottom floor (-2 to +2 X, -2 to +3 Z)
	for x = -1, 1 do
		for z = -2, 2 do
			add(x, 0, z, c_steelblock)
		end
	end

	-- Cockpit nose
	add(0, 0, 3, c_bronzeblock)
	add(0, 1, 3, c_obsidian_glass)
	add(0, 1, 2, c_obsidian_glass)

	-- Sidewalls & Bulkheads
	for z = -2, 1 do
		add(-1, 1, z, c_steelblock)
		add(1, 1, z, c_steelblock)
		add(-1, 2, z, c_steelblock)
		add(1, 2, z, c_steelblock)
	end

	-- Roof
	for x = -1, 1 do
		for z = -1, 1 do
			add(x, 3, z, c_steelblock)
		end
	end
	add(0, 3, 2, c_obsidian_glass)

	-- Fuel Pods on flanking sides
	add(-2, 0, 0, c_fuel_tank)
	add(-2, 1, 0, c_fuel_tank)
	add(2, 0, 0, c_fuel_tank)
	add(2, 1, 0, c_fuel_tank)

	-- Rear Thruster Assembly
	add(0, 1, -3, c_bronzeblock)
	add(0, 0, -3, c_copperblock)
	add(0, 2, -3, c_copperblock)

	-- Interior Cargo Storage
	add(0, 1, 0, c_chest_ta3, 0, true, "shuttle")
	add(0, 1, -1, c_chest_ta3, 0, true, "shuttle")

	return {
		name = "shuttle",
		size = {x = 5, y = 4, z = 7},
		radius = 4,
		nodes = nodes
	}
end
derelicts.get_shuttle_schematic = get_shuttle_schematic

local function get_lab_schematic()
	if not c_air then init_content_ids() end
	-- Wrecked Orbital Research Station & Laboratory (~17x8x17, radius 10)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Octagonal Main Research Module (X in [-3, 3], Z in [-3, 3], Y in [0, 4])
	for x = -3, 3 do
		for z = -3, 3 do
			local is_corner = (math.abs(x) == 3 and math.abs(z) == 3)
			if not is_corner then
				-- Floor deck (Y = 0) and Roof (Y = 4)
				add(x, 0, z, c_steelblock)
				if math.abs(x) <= 1 and math.abs(z) <= 1 then
					add(x, 4, z, c_obsidian_glass) -- Observation cupola
				else
					add(x, 4, z, c_steelblock)
				end

				-- Perimeter walls (Y = 1 to 3)
				local is_edge = (math.abs(x) == 3 or math.abs(z) == 3 or (math.abs(x) == 2 and math.abs(z) == 2))
				if is_edge then
					for y = 1, 3 do
						if (z == 3 and math.abs(x) <= 1) then
							-- Forward airlock portal
							if y == 3 then add(x, y, z, c_bronzeblock) end
						elseif (x == 0 or z == 0) and (y == 2) then
							add(x, y, z, c_obsidian_glass) -- Viewport window
						else
							add(x, y, z, (y == 2) and c_bronzeblock or c_steelblock)
						end
					end
				end
			end
		end
	end

	-- 2. Interior Research Equipment & Consoles (Y = 1 to 2, X in [-2, 2], Z in [-2, 2])
	add(0, 1, 0, c_electrolyzer) -- Central life support & sample analyzer
	add(0, 2, 0, c_copperblock)
	add(-2, 1, 0, c_fuel_tank)
	add(-2, 2, 0, c_fuel_tank)
	add(2, 1, 0, c_copperblock) -- Data server rack
	add(2, 2, 0, c_copperblock)
	add(0, 1, -2, c_copperblock)

	-- Salvage Research Storage Lockers
	add(-2, 1, -2, c_chest_ta4, 0, true, "lab")
	add(2, 1, -2, c_chest_ta4, 0, true, "lab")
	add(2, 1, 2, c_chest_ta3, 0, true, "shuttle")

	-- 3. Twin Extended East-West Solar Wings (X = +/- 4 to +/- 8, Y = 2)
	-- East (+X) Wing: Carrier beam at Z=0 (p2=1), Solar modules at Z=+1 (p2=0) and Z=-1 (p2=2)
	for x = 4, 8 do
		add(x, 2, 0, c_solar_carrier, 1) -- Rotated 90 deg along X-axis
		add(x, 2, 1, c_solar_module, 0)  -- Flat 1x2 panel extending +Z
		add(x, 2, -1, c_solar_module, 2) -- Flat 1x2 panel extending -Z
	end
	-- West (-X) Wing: Carrier beam at Z=0 (p2=1), Solar modules at Z=+1 (p2=0) and Z=-1 (p2=2)
	for x = -8, -4 do
		add(x, 2, 0, c_solar_carrier, 1) -- Rotated 90 deg along X-axis
		add(x, 2, 1, c_solar_module, 0)  -- Flat 1x2 panel extending +Z
		add(x, 2, -1, c_solar_module, 2) -- Flat 1x2 panel extending -Z
	end

	-- 4. Communication Mast & Active Beacon (Y = 5 to 6)
	add(0, 5, 0, c_copperblock)
	add(0, 6, 0, c_beacon, 0, true, "lab_beacon")

	return {
		name = "lab",
		size = {x = 17, y = 8, z = 17},
		radius = 10,
		nodes = nodes
	}
end
derelicts.get_lab_schematic = get_lab_schematic

local function get_freighter_schematic()
	if not c_air then init_content_ids() end
	-- Heavy Capital Container Freighter (~21x14x39, radius 20)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Main Keel Spine & Lower Hull Floor (Y = 0, X in [-8, 8], Z = -16 to 16)
	for z = -16, 16 do
		local width = (z >= 12) and 3 or ((z >= 10) and 5 or ((z <= -12) and 6 or 8))
		for x = -width, width do
			add(x, 0, z, c_steelblock)
		end
	end

	-- 2. Armored Heavy Bow & Forward Docking Prow (Z = 11 to 18)
	for z = 11, 18 do
		local span = (z >= 17) and 1 or ((z >= 15) and 2 or ((z >= 13) and 3 or 4))
		for x = -span, span do
			for y = 1, 4 do
				if z == 18 and x == 0 and (y == 1 or y == 2) then
					-- Forward docking airlock opening
				elseif z == 18 or math.abs(x) == span then
					add(x, y, z, (z >= 16 and (y == 2 or y == 3)) and c_obsidian_glass or c_bronzeblock)
				end
			end
			add(x, 5, z, (z >= 15) and c_obsidian_glass or c_steelblock)
		end
	end
	add(0, 1, 14, c_electrolyzer) -- Forward life support

	-- 3. Central Keel Gantry Catwalk (X in [-1, 1], Z = -8 to 11)
	-- Deck is flush at Y = 0; Y = 1 to 4 is open 4-block high vertical walking space
	for z = -8, 11 do
		-- Overhead gantry crane rails and observation skylights at Y = 5
		add(-1, 5, z, c_steelblock)
		add(1, 5, z, c_steelblock)
		add(0, 5, z, c_obsidian_glass)
	end

	-- Structural Gantry Archways along the Catwalk (Z = -8, -4, 0, 4, 8, 11)
	for _, az in ipairs({-8, -4, 0, 4, 8, 11}) do
		for y = 1, 4 do
			add(-2, y, az, c_bronzeblock)
			add(2, y, az, c_bronzeblock)
		end
		add(-1, 4, az, c_bronzeblock)
		add(1, 4, az, c_bronzeblock)
		add(0, 4, az, c_copperblock)
	end

	-- 4. Four Massive Industrial Walk-In Cargo Bays with 3-Block High Bulkhead Doorways
	-- Forward Port Bay (Z = 3 to 9, X = -7 to -3): Bronze Heavy Freight Containers
	-- Bulkhead doorway into central catwalk is open at X = -2, Y in [1, 3], Z in [5, 6]
	for z = 3, 9 do
		for x = -7, -3 do
			if x == -7 or z == 3 or z == 9 then
				for y = 1, 4 do
					if (z == 6 and (y == 2 or y == 3)) or (x == -7 and (z == 5 or z == 7) and (y == 2 or y == 3)) then
						add(x, y, z, c_obsidian_glass)
					else
						add(x, y, z, c_bronzeblock)
					end
				end
			end
			add(x, 5, z, c_steelblock) -- Bay roof
		end
	end
	add(-5, 1, 6, c_chest_ta4, 0, true, "lab")
	add(-4, 1, 5, c_chest_ta3, 0, true, "shuttle")
	add(-6, 1, 5, c_bronzeblock)
	add(-6, 2, 5, c_bronzeblock)
	add(-6, 1, 7, c_fuel_tank)
	add(-6, 2, 7, c_fuel_tank)

	-- Forward Starboard Bay (Z = 3 to 9, X = 3 to 7): Copper Refined Materials Containers
	-- Bulkhead doorway into central catwalk is open at X = 2, Y in [1, 3], Z in [5, 6]
	for z = 3, 9 do
		for x = 3, 7 do
			if x == 7 or z == 3 or z == 9 then
				for y = 1, 4 do
					if (z == 6 and (y == 2 or y == 3)) or (x == 7 and (z == 5 or z == 7) and (y == 2 or y == 3)) then
						add(x, y, z, c_obsidian_glass)
					else
						add(x, y, z, c_copperblock)
					end
				end
			end
			add(x, 5, z, c_steelblock) -- Bay roof
		end
	end
	add(5, 1, 6, c_chest_ta4, 0, true, "lab")
	add(4, 1, 5, c_chest_ta3, 0, true, "shuttle")
	add(6, 1, 5, c_copperblock)
	add(6, 2, 5, c_copperblock)
	add(6, 1, 7, c_fuel_tank)
	add(6, 2, 7, c_fuel_tank)

	-- Mid Port Bay (Z = -5 to 1, X = -7 to -3): Steel Machinery Containers
	-- Bulkhead doorway into central catwalk is open at X = -2, Y in [1, 3], Z in [-3, -2]
	for z = -5, 1 do
		for x = -7, -3 do
			if x == -7 or z == -5 or z == 1 then
				for y = 1, 4 do
					if (z == -2 and (y == 2 or y == 3)) or (x == -7 and (z == -3 or z == -1) and (y == 2 or y == 3)) then
						add(x, y, z, c_obsidian_glass)
					else
						add(x, y, z, c_steelblock)
					end
				end
			end
			add(x, 5, z, c_steelblock)
		end
	end
	add(-5, 1, -2, c_chest_ta4, 0, true, "lab")
	add(-4, 1, -3, c_chest_ta3, 0, true, "shuttle")
	add(-6, 1, -3, c_steelblock)
	add(-6, 2, -3, c_steelblock)

	-- Mid Starboard Bay (Z = -5 to 1, X = 3 to 7): Hazardous Fuel Cell Racks
	-- Bulkhead doorway into central catwalk is open at X = 2, Y in [1, 3], Z in [-3, -2]
	for z = -5, 1 do
		for x = 3, 7 do
			if x == 7 or z == -5 or z == 1 then
				for y = 1, 4 do
					if (z == -2 and (y == 2 or y == 3)) or (x == 7 and (z == -3 or z == -1) and (y == 2 or y == 3)) then
						add(x, y, z, c_obsidian_glass)
					else
						add(x, y, z, c_steelblock)
					end
				end
			end
			add(x, 5, z, c_steelblock)
		end
	end
	add(5, 1, -2, c_chest_ta4, 0, true, "lab")
	add(4, 1, -3, c_chest_ta3, 0, true, "shuttle")
	add(5, 1, -1, c_fuel_tank)
	add(5, 2, -1, c_fuel_tank)
	add(6, 1, -1, c_fuel_tank)
	add(6, 2, -1, c_fuel_tank)

	-- 5. Elevated 3-Story Bridge Superstructure (Z = -5 to -1, Y = 6 to 13)
	for z = -5, -1 do
		for x = -3, 3 do
			for y = 6, 9 do
				if y == 6 or y == 9 or math.abs(x) == 3 or z == -5 or z == -1 then
					if y == 8 and (z == -1 or math.abs(x) == 3) then
						add(x, y, z, c_obsidian_glass) -- Panoramic bridge viewport
					else
						add(x, y, z, c_steelblock)
					end
				end
			end
		end
	end
	-- Bridge interior console
	add(0, 7, -3, c_copperblock)
	add(0, 7, -2, c_electrolyzer)
	add(1, 7, -3, c_chest_ta4, 0, true, "lab")

	-- Armored Communications Spire & Active Distress Beacon (Y = 10 to 13)
	for y = 10, 12 do
		add(0, y, -3, c_copperblock)
	end
	add(0, 10, -2, c_bronzeblock)
	add(0, 10, -4, c_bronzeblock)
	add(1, 10, -3, c_bronzeblock)
	add(-1, 10, -3, c_bronzeblock)
	add(0, 13, -3, c_beacon, 0, true, "freighter_beacon")

	-- 6. Quad Heavy Fusion Propulsion Block (Z = -6 to -18)
	-- Main Engine Housing (Z = -6 to -16, X in [-7, 7], Y in [0, 5])
	for z = -16, -6 do
		for x = -7, 7 do
			for y = 1, 5 do
				if math.abs(x) == 7 or y == 5 or z == -16 then
					add(x, y, z, c_steelblock)
				end
			end
		end
	end

	-- Central Heavy Fusion Reactor Core inside engine bay (Z = -9 to -13)
	for z = -13, -9 do
		add(0, 1, z, c_electrolyzer)
		add(0, 2, z, c_copperblock)
		add(-1, 1, z, c_fuel_tank)
		add(1, 1, z, c_fuel_tank)
		add(-1, 2, z, c_fuel_tank)
		add(1, 2, z, c_fuel_tank)
	end

	-- Quad Heavy Thruster Exhaust Bells at Z = -17 and -18
	local thruster_positions = {-6, -2, 2, 6}
	for _, tx in ipairs(thruster_positions) do
		for y = 1, 3 do
			for x = tx - 1, tx + 1 do
				if x == tx and y == 2 then
					add(x, y, -17, c_copperblock) -- Exhaust core
					add(x, y, -18, c_copperblock)
				else
					add(x, y, -17, c_bronzeblock) -- Engine cowling rim
					add(x, y, -18, c_bronzeblock)
				end
			end
		end
	end

	return {
		name = "freighter",
		size = {x = 21, y = 14, z = 39},
		radius = 20,
		nodes = nodes
	}
end
derelicts.get_freighter_schematic = get_freighter_schematic

local function get_power_satellite_schematic()
	if not c_air then init_content_ids() end
	-- Heavy Orbital Power Station & Solar Array (~29x8x29, radius 15)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Octagonal Core Station Hub (X in [-3, 3], Z in [-3, 3], Y in [0, 3])
	for x = -3, 3 do
		for z = -3, 3 do
			local is_corner = (math.abs(x) == 3 and math.abs(z) == 3)
			if not is_corner then
				add(x, 0, z, c_steelblock)
				add(x, 3, z, (math.abs(x) <= 1 and math.abs(z) <= 1) and c_copperblock or c_steelblock)

				local is_edge = (math.abs(x) == 3 or math.abs(z) == 3 or (math.abs(x) == 2 and math.abs(z) == 2))
				if is_edge then
					for y = 1, 2 do
						if (x == 0 or z == 0) then
							add(x, y, z, c_obsidian_glass)
						else
							add(x, y, z, (y == 2) and c_bronzeblock or c_steelblock)
						end
					end
				end
			end
		end
	end

	-- Interior Station Power Systems (Y = 1 and 2, X in [-2, 2], Z in [-2, 2])
	add(0, 1, 0, c_electrolyzer)
	add(0, 2, 0, c_copperblock)
	add(1, 1, 0, c_fuel_tank)
	add(-1, 1, 0, c_fuel_tank)
	add(0, 1, 1, c_fuel_tank)
	add(0, 1, -1, c_fuel_tank)
	add(1, 2, 0, c_copperblock)
	add(-1, 2, 0, c_copperblock)
	add(0, 2, 1, c_copperblock)
	add(0, 2, -1, c_copperblock)

	-- 2. Four Expansive Photovoltaic Array Wings (East, West, North, South extending to 14)
	-- East (+X) Wing: Dual carrier lines at Z = -2 and Z = +2 (p2=1)
	for x = 4, 14 do
		-- North spar of East wing (Z = 2)
		add(x, 2, 2, c_solar_carrier, 1)
		add(x, 2, 3, c_solar_module, 0) -- Extends +Z
		add(x, 2, 1, c_solar_module, 2) -- Extends -Z
		-- South spar of East wing (Z = -2)
		add(x, 2, -2, c_solar_carrier, 1)
		add(x, 2, -1, c_solar_module, 0) -- Extends +Z
		add(x, 2, -3, c_solar_module, 2) -- Extends -Z
	end

	-- West (-X) Wing: Dual carrier lines at Z = -2 and Z = +2 (p2=1)
	for x = -14, -4 do
		-- North spar of West wing (Z = 2)
		add(x, 2, 2, c_solar_carrier, 1)
		add(x, 2, 3, c_solar_module, 0) -- Extends +Z
		add(x, 2, 1, c_solar_module, 2) -- Extends -Z
		-- South spar of West wing (Z = -2)
		add(x, 2, -2, c_solar_carrier, 1)
		add(x, 2, -1, c_solar_module, 0) -- Extends +Z
		add(x, 2, -3, c_solar_module, 2) -- Extends -Z
	end

	-- North (+Z) Wing: Dual carrier lines at X = -2 and X = +2 (p2=0)
	for z = 4, 14 do
		-- East spar of North wing (X = 2)
		add(2, 2, z, c_solar_carrier, 0)
		add(3, 2, z, c_solar_module, 3) -- Extends +X
		add(1, 2, z, c_solar_module, 1) -- Extends -X
		-- West spar of North wing (X = -2)
		add(-2, 2, z, c_solar_carrier, 0)
		add(-1, 2, z, c_solar_module, 3) -- Extends +X
		add(-3, 2, z, c_solar_module, 1) -- Extends -X
	end

	-- South (-Z) Wing: Dual carrier lines at X = -2 and X = +2 (p2=0)
	for z = -14, -4 do
		-- East spar of South wing (X = 2)
		add(2, 2, z, c_solar_carrier, 0)
		add(3, 2, z, c_solar_module, 3) -- Extends +X
		add(1, 2, z, c_solar_module, 1) -- Extends -X
		-- West spar of South wing (X = -2)
		add(-2, 2, z, c_solar_carrier, 0)
		add(-1, 2, z, c_solar_module, 3) -- Extends +X
		add(-3, 2, z, c_solar_module, 1) -- Extends -X
	end

	-- 3. High-Gain Transmission Spire & Active Beacon (Y = 4 to 7)
	for y = 4, 6 do
		add(0, y, 0, (y == 5) and c_bronzeblock or c_copperblock)
	end
	add(1, 4, 0, c_bronzeblock)
	add(-1, 4, 0, c_bronzeblock)
	add(0, 4, 1, c_bronzeblock)
	add(0, 4, -1, c_bronzeblock)
	add(0, 7, 0, c_beacon, 0, true, "power_satellite_beacon")

	-- 4. Salvage Capacitors & High-Tech Storage
	add(1, 1, 1, c_chest_ta4, 0, true, "lab")
	add(-1, 1, -1, c_chest_ta3, 0, true, "shuttle")
	add(-1, 1, 1, c_chest_ta4, 0, true, "lab")

	return {
		name = "power_satellite",
		size = {x = 29, y = 8, z = 29},
		radius = 15,
		nodes = nodes
	}
end
derelicts.get_power_satellite_schematic = get_power_satellite_schematic

local function get_mining_rig_schematic()
	if not c_air then init_content_ids() end
	-- Heavy Industrial Asteroid Mining Platform (~13x11x32, radius 17)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Double-Deck Industrial Gantry Spine (Z = -9 to 9)
	for z = -9, 9 do
		-- Lower deck floor (Y = 0)
		for x = -2, 2 do
			add(x, 0, z, c_steelblock)
		end
		-- Upper catwalk deck (Y = 4)
		for x = -2, 2 do
			if math.abs(x) == 2 or z % 3 == 0 then
				add(x, 4, z, c_steelblock)
			else
				add(x, 4, z, c_obsidian_glass) -- Transparent walkway grating
			end
		end
		-- Heavy Structural Gantry Columns at Z = -9, -6, -3, 0, 3, 6, 9
		if z % 3 == 0 then
			for y = 1, 3 do
				add(-2, y, z, c_bronzeblock)
				add(2, y, z, c_bronzeblock)
			end
			-- Transverse arch headers
			add(-1, 3, z, c_bronzeblock)
			add(1, 3, z, c_bronzeblock)
			add(0, 3, z, c_copperblock)
		end
	end

	-- 2. Chamfered Ore Refinery Silos (Port: X = -6..-3, Starboard: X = 3..6, Z = -5 to 3)
	for _, side in ipairs({-1, 1}) do
		local x_inner = side * 3
		local x_outer = side * 6
		local x_min = (side == -1) and x_outer or x_inner
		local x_max = (side == -1) and x_inner or x_outer

		for z = -5, 3 do
			for x = x_min, x_max do
				-- Bevel outer corners to create cylindrical silo profile
				local is_corner = (x == x_outer and (z == -5 or z == 3))
				if not is_corner then
					add(x, 0, z, c_steelblock)
					add(x, 3, z, c_steelblock)
					if x == x_outer or z == -5 or z == 3 or (x == x_outer - side and (z == -5 or z == 3)) then
						for y = 1, 2 do
							add(x, y, z, (z == -1 or z == 0) and c_obsidian_glass or c_steelblock)
						end
					end
				end
			end
		end

		-- Slurry storage tanks & Centrifuges inside silos
		add(side * 4, 1, -3, c_fuel_tank)
		add(side * 4, 2, -3, c_fuel_tank)
		add(side * 5, 1, -3, c_fuel_tank)
		add(side * 5, 2, -3, c_fuel_tank)
		add(side * 4, 1, 1, c_electrolyzer)
		add(side * 5, 1, 1, c_copperblock)

		-- External industrial copper pipe manifolds connecting silos to central spine
		for y = 1, 2 do
			add(side * 3, y, -1, c_copperblock)
			add(side * 3, y, 1, c_copperblock)
		end
	end

	-- 3. Extended Articulated Hydraulic Drill Boom (Z = 10 to 17)
	-- Boom Gantry Neck (Z = 10 to 12)
	for z = 10, 12 do
		for x = -1, 1 do
			add(x, 1, z, c_bronzeblock)
			add(x, 2, z, c_steelblock)
		end
		add(0, 3, z, c_copperblock) -- High-pressure conduit
	end

	-- Hydraulic Piston Rams (Z = 13 to 14)
	for z = 13, 14 do
		add(0, 1, z, c_steelblock)
		add(0, 2, z, c_copperblock)
		add(-1, 1, z, c_bronzeblock)
		add(1, 1, z, c_bronzeblock)
	end

	-- Rotating Drill Head & Cutter Teeth (Z = 15 to 17)
	for x = -1, 1 do
		for y = 0, 2 do
			add(x, y, 15, c_bronzeblock)
		end
	end
	add(0, 1, 15, c_copperblock)

	-- Staggered Cutter Teeth at Z = 16 and 17
	add(-1, 0, 16, c_copperblock)
	add(1, 0, 16, c_copperblock)
	add(-1, 2, 16, c_copperblock)
	add(1, 2, 16, c_copperblock)
	add(0, 1, 16, c_bronzeblock)
	add(0, 1, 17, c_copperblock) -- Induction spike tip

	-- 4. Elevated Crane Operator Cab & Dorsal Beacon Spire (Y = 5 to 10, Z = 0 to 2)
	for x = -1, 1 do
		for z = 0, 2 do
			add(x, 5, z, c_steelblock)
			add(x, 7, z, c_steelblock)
			if math.abs(x) == 1 or z == 2 then
				add(x, 6, z, c_obsidian_glass) -- Panoramic control window
			else
				add(x, 6, z, c_steelblock)
			end
		end
	end
	-- Beacon Spire atop Cab
	add(0, 8, 1, c_copperblock)
	add(0, 9, 1, c_bronzeblock)
	add(0, 10, 1, c_beacon, 0, true, "mining_rig_beacon")

	-- 5. Aft Power Plant & Dual Recessed Thrusters (Z = -10 to -14)
	for z = -13, -10 do
		for x = -2, 2 do
			for y = 0, 2 do
				add(x, y, z, c_steelblock)
			end
		end
	end
	-- Recessed Thruster Nozzles at Z = -14
	for _, side in ipairs({-1, 1}) do
		add(side * 1, 1, -14, c_copperblock) -- Exhaust core
		add(side * 1, 0, -14, c_bronzeblock) -- Cowling
		add(side * 1, 2, -14, c_bronzeblock)
		add(side * 2, 1, -14, c_bronzeblock)
		add(0, 1, -14, c_bronzeblock)
	end

	-- 6. Salvage Storage Containers
	add(-4, 1, 2, c_chest_ta3, 0, true, "shuttle")
	add(4, 1, 2, c_chest_ta4, 0, true, "lab")
	add(0, 1, -6, c_chest_ta4, 0, true, "lab")

	return {
		name = "mining_rig",
		size = {x = 13, y = 11, z = 32},
		radius = 17,
		nodes = nodes
	}
end
derelicts.get_mining_rig_schematic = get_mining_rig_schematic

local function get_corvette_schematic()
	if not c_air then init_content_ids() end
	-- Escort Corvette / Heavy Interceptor (~13x5x17, radius 9)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Lower Hull / Belly Armor Plating (Y = 0)
	-- Central fuselage belly (Z = -6 to 5, X = -2 to 2)
	for z = -6, 5 do
		for x = -2, 2 do
			add(x, 0, z, c_steelblock)
		end
	end
	-- Tapered nose belly (Z = 6 to 8)
	add(-1, 0, 6, c_steelblock)
	add(0, 0, 6, c_steelblock)
	add(1, 0, 6, c_steelblock)
	add(0, 0, 7, c_steelblock)

	-- 2. Swept Armored Delta Wings (Y = 0 and Y = 1)
	for z = -5, 3 do
		local span = (z >= 3) and 3 or ((z == 2) and 4 or ((z == 1) and 5 or 6))
		for x = -span, span do
			if math.abs(x) >= 3 then
				add(x, 0, z, c_steelblock)
				add(x, 1, z, (math.abs(x) == span or z == -5) and c_bronzeblock or c_steelblock)
			end
		end
	end

	-- 3. Twin Wingtip Kinetic Railgun Cannons (X = +/- 5 and +/- 6, Z = 2 to 6, Y = 1)
	for _, kx in ipairs({-5, 5}) do
		for z = 2, 5 do
			add(kx, 1, z, c_copperblock)
		end
		add(kx, 1, 6, c_bronzeblock) -- Muzzle brake
	end

	-- 4. Fuselage Side Armor Walls (Y = 1 and Y = 2)
	for z = -6, 2 do
		for y = 1, 2 do
			add(-2, y, z, c_steelblock)
			add(2, y, z, c_steelblock)
		end
	end

	-- 5. Cockpit Enclosure & Armored Obsidian Glass Canopy (Z = 3 to 5)
	for z = 3, 4 do
		add(-2, 1, z, c_bronzeblock)
		add(2, 1, z, c_bronzeblock)
		add(-2, 2, z, c_obsidian_glass)
		add(2, 2, z, c_obsidian_glass)
		for x = -1, 1 do
			add(x, 3, z, c_obsidian_glass)
		end
	end
	-- Forward Windshield & Cockpit Frame (Z = 5)
	add(0, 1, 5, c_obsidian_glass)
	add(0, 2, 5, c_obsidian_glass)
	add(-1, 1, 5, c_bronzeblock)
	add(1, 1, 5, c_bronzeblock)
	add(-1, 2, 5, c_bronzeblock)
	add(1, 2, 5, c_bronzeblock)
	add(0, 3, 5, c_obsidian_glass)
	add(-1, 3, 5, c_bronzeblock)
	add(1, 3, 5, c_bronzeblock)

	-- Reinforced Ramming Prow Nose (Z = 6 to 8)
	add(0, 1, 6, c_bronzeblock)
	add(0, 2, 6, c_bronzeblock)
	add(-1, 1, 6, c_steelblock)
	add(1, 1, 6, c_steelblock)
	add(0, 1, 7, c_bronzeblock)
	add(0, 2, 7, c_bronzeblock)
	add(0, 1, 8, c_copperblock)

	-- 6. Upper Fuselage Armored Roof (Y = 3)
	for z = -6, 2 do
		for x = -2, 2 do
			if math.abs(x) == 2 then
				add(x, 3, z, c_steelblock)
			elseif x == 0 then
				add(x, 3, z, c_bronzeblock)
			else
				add(x, 3, z, c_steelblock)
			end
		end
	end

	-- 7. Dorsal Ridge & Active Distress Beacon (Y = 4)
	for z = -4, 0 do
		add(0, 4, z, c_copperblock)
	end
	add(0, 4, -1, c_beacon, 0, true, "corvette_beacon")

	-- 8. Twin Heavy Aft Thruster Nacelles (X = -4..-2 and 2..4, Z = -6 to -8)
	for _, side in ipairs({-1, 1}) do
		local x_min = (side == -1) and -4 or 2
		local x_max = (side == -1) and -2 or 4
		for z = -8, -6 do
			for x = x_min, x_max do
				for y = 0, 2 do
					if z == -8 then
						if x == side * 3 and y == 1 then
							add(x, y, z, c_copperblock) -- Thruster exhaust nozzle
						else
							add(x, y, z, c_bronzeblock) -- Engine cowling rim
						end
					else
						add(x, y, z, c_steelblock)
					end
				end
			end
		end
		add(side * 3, 2, -7, c_copperblock)
	end

	-- 9. Walk-In Interior Cabin & Engineering Core (Y = 1 and 2, X in [-1, 1])
	-- Central aisle (X = 0, Y in [1, 2]) is completely clear for unobstructed walking from Z = -5 to 4
	-- Side Equipment in Wall Alcoves at X = -1 and X = 1
	add(1, 1, 2, c_electrolyzer) -- Life support on starboard wall
	add(-1, 1, 2, c_copperblock)  -- Avionics on port wall
	add(-1, 1, -2, c_fuel_tank)  -- Port fuel cell
	add(1, 1, -2, c_fuel_tank)   -- Starboard fuel cell
	add(-1, 2, -2, c_fuel_tank)
	add(1, 2, -2, c_fuel_tank)

	-- Overhead & Aft Reactor Conduits (leaving walking space open at X = 0, Y in [1, 2])
	add(0, 3, -3, c_copperblock) -- Overhead power conduit
	add(0, 0, -3, c_copperblock) -- Under-floor conduit
	add(0, 1, -6, c_copperblock) -- Aft bulkhead core
	add(0, 2, -6, c_copperblock)

	-- Accessible Salvage Containers
	add(-1, 1, 0, c_chest_ta3, 0, true, "shuttle")
	add(1, 1, 0, c_chest_ta4, 0, true, "lab")
	add(-1, 1, -4, c_chest_ta4, 0, true, "lab")

	return {
		name = "corvette",
		size = {x = 13, y = 5, z = 17},
		radius = 9,
		nodes = nodes
	}
end
derelicts.get_corvette_schematic = get_corvette_schematic

local function get_cryo_barge_schematic()
	if not c_air then init_content_ids() end
	-- Heavy Stasis Transport / Cryo-Barge (~19x9x33, radius 18)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Main Central Fuselage & 3-Block Wide Walk-in Spine Corridor (X in [-2, 2], Z = -11 to 11)
	for z = -11, 11 do
		-- Floor deck (Y = 0) and Roof (Y = 5)
		for x = -2, 2 do
			add(x, 0, z, c_steelblock)
			add(x, 5, z, (z % 3 == 0) and c_bronzeblock or c_steelblock)
		end

		-- Corridor outer walls at X = -2 and X = +2 (Y = 1 to 4)
		-- Leave wide open 3-block doorways at Z in [pz-1, pz+1] for each of the 6 stasis pods
		local is_pod_zone = (math.abs(z - (-7)) <= 1 or math.abs(z - 0) <= 1 or math.abs(z - 7) <= 1)
		if not is_pod_zone then
			for y = 1, 4 do
				if (y == 2 or y == 3) and (z % 2 == 0) then
					add(-2, y, z, c_obsidian_glass)
					add(2, y, z, c_obsidian_glass)
				else
					add(-2, y, z, c_steelblock)
					add(2, y, z, c_steelblock)
				end
			end
		end
	end

	-- Structural Bulkhead Arch Ribs along the Corridor (Z = -9, -6, -3, 0, 3, 6, 9)
	for _, rz in ipairs({-9, -6, -3, 0, 3, 6, 9}) do
		for y = 1, 4 do
			add(-2, y, rz, c_bronzeblock)
			add(2, y, rz, c_bronzeblock)
		end
		add(-1, 4, rz, c_bronzeblock)
		add(1, 4, rz, c_bronzeblock)
		add(0, 4, rz, c_copperblock)
	end

	-- External Dorsal and Ventral Cryogenic Coolant Conduits
	for z = -10, 10 do
		add(0, -1, z, c_copperblock) -- Ventral liquid nitrogen line
		add(0, 6, z, (z % 2 == 0) and c_copperblock or c_bronzeblock) -- Dorsal distribution manifold
	end

	-- 2. Six Spacious 5x5 Stasis Nacelles on Pylon Standoffs (3 Port, 3 Starboard at Z = -7, 0, 7)
	for _, pz in ipairs({-7, 0, 7}) do
		for _, side in ipairs({-1, 1}) do
			local x_inner = side * 4
			local x_outer = side * 8
			local x_min = (side == -1) and x_outer or x_inner
			local x_max = (side == -1) and x_inner or x_outer

			-- Wide Pylon Walkway at X = side * 3
			for z = pz - 1, pz + 1 do
				add(side * 3, 0, z, c_steelblock)
				add(side * 3, 5, z, c_bronzeblock)
			end
			for y = 1, 4 do
				add(side * 3, y, pz - 2, c_steelblock)
				add(side * 3, y, pz + 2, c_steelblock)
			end
			-- Coolant branch into pylon
			add(side * 3, 6, pz, c_copperblock)

			-- Spacious 5x5 Nacelle Pod Chamber (X = side * 4 to side * 8, Z = pz - 2 to pz + 2)
			for z = pz - 2, pz + 2 do
				for x = x_min, x_max do
					local is_corner = (x == x_outer and (z == pz - 2 or z == pz + 2))
					if not is_corner then
						add(x, 0, z, c_steelblock) -- Pod floor
						add(x, 5, z, c_steelblock) -- Pod ceiling
						if x == x_outer or z == pz - 2 or z == pz + 2 then
							for y = 1, 4 do
								if (y == 2 or y == 3) and (x == x_outer or (z == pz and x ~= x_inner)) then
									add(x, y, z, c_obsidian_glass) -- Panoramic viewports
								else
									add(x, y, z, c_steelblock)
								end
							end
						end
					end
				end
			end

			-- Walk-in Cryo-Stasis Chamber Interior
			local pod_x = side * 6
			add(pod_x, 1, pz, c_obsidian_glass) -- Transparent stasis capsule
			add(pod_x, 2, pz, c_obsidian_glass)
			add(pod_x, 3, pz, c_obsidian_glass)
			add(pod_x, 0, pz, c_copperblock)    -- Cryo base pedestal
			add(pod_x, 4, pz, c_bronzeblock)    -- Stasis cap manifold
			add(pod_x + side, 1, pz, c_electrolyzer) -- Life support console
			add(pod_x + side, 2, pz, c_fuel_tank)
			add(pod_x + side, 3, pz, c_fuel_tank)
		end
	end

	-- 3. Tapered Forward Navigation Bridge (Z = 12 to 16)
	for z = 12, 13 do
		for x = -3, 3 do
			add(x, 0, z, c_steelblock)
			add(x, 5, z, c_steelblock)
			if math.abs(x) == 3 then
				for y = 1, 4 do add(x, y, z, (y == 2 or y == 3) and c_obsidian_glass or c_steelblock) end
			end
		end
	end
	for x = -2, 2 do
		add(x, 0, 14, c_steelblock)
		add(x, 5, 14, c_bronzeblock)
		for y = 1, 4 do add(x, y, 14, (y == 2 or y == 3) and c_obsidian_glass or c_steelblock) end
	end
	for x = -1, 1 do
		add(x, 0, 15, c_steelblock)
		add(x, 4, 15, c_bronzeblock)
		for y = 1, 3 do add(x, y, 15, c_obsidian_glass) end
	end
	add(0, 1, 16, c_copperblock) -- Forward sensor needle
	add(0, 1, 11, c_electrolyzer) -- Forward life support

	-- 4. Twin Heavy Sub-Light Propulsion Nacelles (X = -6..-3 and 3..6, Z = -12 to -16)
	for _, side in ipairs({-1, 1}) do
		local x_min = (side == -1) and -6 or 3
		local x_max = (side == -1) and -3 or 6
		for z = -15, -12 do
			for x = x_min, x_max do
				for y = 0, 4 do
					add(x, y, z, c_steelblock)
				end
			end
		end
		-- Dual recessed thruster bells at Z = -16
		for y = 1, 3 do
			add(side * 4, y, -16, c_copperblock)
			add(side * 5, y, -16, c_copperblock)
			add(side * 3, y, -16, c_bronzeblock)
			add(side * 6, y, -16, c_bronzeblock)
		end
		add(side * 4, 0, -16, c_bronzeblock)
		add(side * 5, 0, -16, c_bronzeblock)
		add(side * 4, 4, -16, c_bronzeblock)
		add(side * 5, 4, -16, c_bronzeblock)
	end
	-- Aft fuel reservoirs inside spine
	add(-1, 1, -9, c_fuel_tank)
	add(1, 1, -9, c_fuel_tank)
	add(-1, 2, -9, c_fuel_tank)
	add(1, 2, -9, c_fuel_tank)

	-- 5. Salvage Containers in Stasis Nacelles & Bridge
	add(-7, 1, 7, c_chest_ta4, 0, true, "lab")
	add(7, 1, 7, c_chest_ta4, 0, true, "lab")
	add(-7, 1, 0, c_chest_ta3, 0, true, "shuttle")
	add(7, 1, 0, c_chest_ta3, 0, true, "shuttle")
	add(-7, 1, -7, c_chest_ta4, 0, true, "lab")
	add(7, 1, -7, c_chest_ta4, 0, true, "lab")

	-- 6. Dorsal Mast & Active Navigation Beacon (Y = 6 to 7)
	add(0, 6, 0, c_copperblock)
	add(0, 7, 0, c_beacon, 0, true, "cryo_barge_beacon")

	return {
		name = "cryo_barge",
		size = {x = 19, y = 9, z = 33},
		radius = 18,
		nodes = nodes
	}
end
derelicts.get_cryo_barge_schematic = get_cryo_barge_schematic

local function get_biodome_schematic()
	if not c_air then init_content_ids() end
	-- Heavy Orbital Bio-Dome & Greenhouse Station (~17x10x19, radius 10)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Base Circular Deck Floor (X in [-8, 8], Z in [-8, 8], Y = 0)
	for x = -8, 8 do
		for z = -8, 8 do
			if (x * x + z * z) <= 65 then
				add(x, 0, z, c_steelblock)
			end
		end
	end

	-- 2. Four Large Terraced Planter Quadrants with Soil & Grass
	for _, qx in ipairs({-4, 4}) do
		for _, qz in ipairs({-4, 4}) do
			for dx = -2, 2 do
				for dz = -2, 2 do
					local px = qx + dx
					local pz = qz + dz
					if (px * px + pz * pz) <= 55 then
						if math.abs(dx) == 2 or math.abs(dz) == 2 then
							add(px, 1, pz, c_steelblock) -- Retaining planter rim
						else
							add(px, 1, pz, (qx > 0) and c_dirt_with_grass or c_dirt)
						end
					end
				end
			end
		end
	end

	-- 3. Central Irrigation, Hydroponic Aeration & Power Tower (X = 0, Z = 0)
	add(0, 1, 0, c_electrolyzer)
	add(0, 1, 1, c_fuel_tank)
	add(0, 1, -1, c_fuel_tank)
	add(1, 1, 0, c_fuel_tank)
	add(-1, 1, 0, c_fuel_tank)
	for y = 2, 5 do
		add(0, y, 0, c_copperblock)
		add(1, y, 0, (y == 3) and c_bronzeblock or c_copperblock)
		add(-1, y, 0, (y == 3) and c_bronzeblock or c_copperblock)
		add(0, y, 1, (y == 3) and c_bronzeblock or c_copperblock)
		add(0, y, -1, (y == 3) and c_bronzeblock or c_copperblock)
	end

	-- 4. Hemispherical Geodesic Obsidian Glass Canopy (Y = 1 to 8)
	for y = 1, 8 do
		local r_sq = 65 - (y * y * 0.95)
		for x = -8, 8 do
			for z = -8, 8 do
				local dist_sq = x * x + z * z
				if dist_sq <= r_sq and dist_sq >= (r_sq - 9.0) then
					-- Leave open passage for the forward airlock at Z >= 6, X = 0, Y in [1, 2]
					local is_airlock_opening = (x == 0 and (y == 1 or y == 2) and z >= 6)
					if not is_airlock_opening then
						if x == 0 or z == 0 or math.abs(x) == math.abs(z) then
							add(x, y, z, c_steelblock) -- Reinforced structural geodesic ribs
						else
							add(x, y, z, c_obsidian_glass)
						end
					end
				end
			end
		end
	end

	-- 5. Forward Walk-In Airlock Portal Collar (Z = 7 to 9, X in [-1, 1])
	for z = 7, 9 do
		add(0, 0, z, c_steelblock) -- Airlock floor
		add(-1, 0, z, c_steelblock)
		add(1, 0, z, c_steelblock)
		add(0, 3, z, c_bronzeblock) -- Airlock ceiling
		add(-1, 3, z, c_steelblock)
		add(1, 3, z, c_steelblock)
		for y = 1, 2 do
			add(-1, y, z, c_steelblock)
			add(1, y, z, c_steelblock)
		end
	end
	-- Outer airlock collar framing arch at Z = 9
	add(0, 3, 9, c_copperblock)

	-- 6. Mezzanine Storage Lockers & Botanical Caches
	add(1, 1, 3, c_chest_ta4, 0, true, "biodome")
	add(-1, 1, 3, c_chest_ta3, 0, true, "biodome")
	add(1, 1, -3, c_chest_ta4, 0, true, "biodome")
	add(-1, 1, -3, c_chest_ta3, 0, true, "biodome")

	-- 7. Distress Beacon atop geodesic dome apex
	add(0, 9, 0, c_beacon, 0, true, "biodome_beacon")

	return {
		name = "biodome",
		size = {x = 17, y = 10, z = 19},
		radius = 10,
		nodes = nodes
	}
end
derelicts.get_biodome_schematic = get_biodome_schematic

derelicts.schematics = {
	probe = get_probe_schematic,
	shuttle = get_shuttle_schematic,
	lab = get_lab_schematic,
	freighter = get_freighter_schematic,
	power_satellite = get_power_satellite_schematic,
	mining_rig = get_mining_rig_schematic,
	corvette = get_corvette_schematic,
	cryo_barge = get_cryo_barge_schematic,
	biodome = get_biodome_schematic,
}

-- Beacon titles lookup (without DISTRESS tag)
derelicts.beacon_titles = {
	freighter_beacon = "Derelict Heavy Freighter",
	power_satellite_beacon = "Derelict Solar Array",
	mining_rig_beacon = "Derelict Mining Rig",
	corvette_beacon = "Derelict Corvette",
	cryo_barge_beacon = "Derelict Cryo-Barge",
	lab_beacon = "Derelict Research Station",
	biodome_beacon = "Derelict Bio-Dome",
}

-- -------------------------------------------------------------------------
-- 2. LOOT POPULATION ENGINE
-- -------------------------------------------------------------------------

-- Helper function to roll from a weighted pool
local function roll_loot_pool(pool, count)
	local picked = {}
	if not pool or #pool == 0 or count <= 0 then return picked end

	local total_weight = 0
	for _, entry in ipairs(pool) do
		total_weight = total_weight + (entry.weight or 10)
	end

	for _ = 1, count do
		local roll = random(1, total_weight)
		local acc = 0
		for _, entry in ipairs(pool) do
			acc = acc + (entry.weight or 10)
			if roll <= acc then
				local qty = (entry.min and entry.max) and random(entry.min, entry.max) or 1
				if entry.is_tool then
					for _ = 1, qty do
						table.insert(picked, entry.item)
					end
				else
					table.insert(picked, entry.item .. " " .. qty)
				end
				break
			end
		end
	end
	return picked
end

function derelicts.populate_chest(pos, tier)
	local meta = minetest.get_meta(pos)
	if not meta then return end

	local inv = meta:get_inventory()
	if not inv then return end

	-- Initialize inventory capacity & UI formspec
	local inv_size
	local formspec
	local infotext

	local bg = (default and default.gui_bg) or ""
	local bg_img = (default and default.gui_bg_img) or ""
	local slots = (default and default.gui_slots) or ""

	if tier == "lab" then
		inv_size = 50
		infotext = "Derelict Laboratory Storage"
		formspec = "size[10,9]" .. bg .. bg_img .. slots ..
			"list[context;main;0,0;10,5;]" ..
			"list[current_player;main;1,5.3;8,4;]" ..
			"listring[context;main]" ..
			"listring[current_player;main]"
	elseif tier == "biodome" then
		inv_size = 40
		infotext = "Derelict Bio-Dome Storage"
		formspec = "size[10,8]" .. bg .. bg_img .. slots ..
			"list[context;main;0,0;10,4;]" ..
			"list[current_player;main;1,4.3;8,4;]" ..
			"listring[context;main]" ..
			"listring[current_player;main]"
	elseif tier == "shuttle" then
		inv_size = 40
		infotext = "Derelict Shuttle Cargo"
		formspec = "size[10,8]" .. bg .. bg_img .. slots ..
			"list[context;main;0,0;10,4;]" ..
			"list[current_player;main;1,4.3;8,4;]" ..
			"listring[context;main]" ..
			"listring[current_player;main]"
	else -- probe
		inv_size = 32
		infotext = "Derelict Probe Cache"
		formspec = "size[8,8]" .. bg .. bg_img .. slots ..
			"list[context;main;0,0.3;8,4;]" ..
			"list[current_player;main;0,4.85;8,1;]" ..
			"list[current_player;main;0,6.08;8,3;8]" ..
			"listring[context;main]" ..
			"listring[current_player;main]"
	end

	inv:set_size("main", inv_size)
	if tier == "lab" or tier == "biodome" then
		inv:set_size("conf", 50)
	end
	meta:set_string("infotext", infotext)
	meta:set_string("formspec", formspec)
	meta:set_int("public", 1)

	local has_techage = minetest.get_modpath("techage") ~= nil
	local has_airtanks = minetest.get_modpath("airtanks") ~= nil
	local has_vacuum = minetest.get_modpath("vacuum") ~= nil

	local items = {}

	if tier == "probe" then
		-- Guaranteed life support/basic consumable
		if has_airtanks and random(1, 4) == 1 then
			table.insert(items, "airtanks:steel_tank")
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(1, 3))
		end

		local probe_pool = {
			{item = "default:steel_ingot", weight = 25, min = 2, max = 6},
			{item = "default:copper_ingot", weight = 20, min = 2, max = 5},
			{item = "default:gold_ingot", weight = 10, min = 1, max = 3},
			{item = "default:mese_crystal", weight = 10, min = 1, max = 2},
		}
		if has_techage then
			table.insert(probe_pool, {item = "techage:ta4_wlanchip", weight = 20, min = 1, max = 2})
			table.insert(probe_pool, {item = "techage:aluminum", weight = 20, min = 2, max = 5})
			table.insert(probe_pool, {item = "techage:ta4_solar_module", weight = 15, min = 1, max = 2})
			table.insert(probe_pool, {item = "techage:ta3_cylinder_small", weight = 15, min = 1, max = 3})
		end

		local rolls = roll_loot_pool(probe_pool, random(3, 5))
		for _, it in ipairs(rolls) do table.insert(items, it) end

	elseif tier == "biodome" then
		-- Guaranteed seeds, soil, and air supply
		if has_airtanks then
			table.insert(items, "airtanks:steel_tank")
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(3, 6))
		end
		table.insert(items, "default:dirt " .. random(4, 8))

		local biodome_pool = {
			{item = "farming:seed_wheat", weight = 25, min = 3, max = 8},
			{item = "farming:seed_cotton", weight = 20, min = 2, max = 6},
			{item = "default:sapling", weight = 20, min = 1, max = 4},
			{item = "default:apple", weight = 20, min = 3, max = 8},
			{item = "default:steel_ingot", weight = 15, min = 2, max = 5},
			{item = "default:copper_ingot", weight = 15, min = 2, max = 4},
			{item = "default:gold_ingot", weight = 10, min = 1, max = 3},
		}
		if has_techage then
			table.insert(biodome_pool, {item = "techage:ta4_wlanchip", weight = 15, min = 1, max = 3})
			table.insert(biodome_pool, {item = "techage:cylinder_small_hydrogen", weight = 15, min = 1, max = 3})
		end

		local rolls = roll_loot_pool(biodome_pool, random(4, 7))
		for _, it in ipairs(rolls) do table.insert(items, it) end

	elseif tier == "shuttle" then
		-- Guaranteed propellant canister
		if has_techage then
			table.insert(items, "techage:cylinder_small_hydrogen " .. random(2, 4))
		end
		if has_airtanks then
			table.insert(items, "airtanks:steel_tank")
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(2, 4))
		end

		local shuttle_pool = {
			{item = "default:gold_ingot", weight = 20, min = 2, max = 5},
			{item = "default:bronze_ingot", weight = 20, min = 3, max = 8},
			{item = "default:steel_ingot", weight = 20, min = 4, max = 8},
			{item = "default:mese_crystal", weight = 15, min = 1, max = 3},
			{item = "default:diamond", weight = 10, min = 1, max = 2},
		}
		if has_techage then
			table.insert(shuttle_pool, {item = "techage:steelmat", weight = 25, min = 2, max = 6})
			table.insert(shuttle_pool, {item = "techage:aluminum", weight = 20, min = 2, max = 5})
			table.insert(shuttle_pool, {item = "techage:ta3_cylinder_small", weight = 20, min = 2, max = 4})
			table.insert(shuttle_pool, {item = "techage:cylinder_small_hydrogen", weight = 20, min = 1, max = 3})
			table.insert(shuttle_pool, {item = "techage:ta4_carbon_fiber", weight = 10, min = 1, max = 3})
		end

		local rolls = roll_loot_pool(shuttle_pool, random(4, 7))
		for _, it in ipairs(rolls) do table.insert(items, it) end

	elseif tier == "lab" then
		-- Guaranteed high-tech / propellant items
		if has_techage then
			table.insert(items, "techage:ta4_carbon_fiber " .. random(2, 4))
			table.insert(items, "techage:cylinder_small_hydrogen " .. random(3, 5))
		end
		if has_airtanks then
			table.insert(items, "airtanks:steel_tank")
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(3, 6))
		end

		local lab_pool = {
			{item = "default:diamond", weight = 20, min = 2, max = 5},
			{item = "default:mese_crystal", weight = 25, min = 3, max = 6},
			{item = "default:gold_ingot", weight = 20, min = 4, max = 8},
		}
		if has_techage then
			table.insert(lab_pool, {item = "techage:ta4_wlanchip", weight = 25, min = 2, max = 4})
			table.insert(lab_pool, {item = "techage:ta4_carbon_fiber", weight = 20, min = 2, max = 5})
			table.insert(lab_pool, {item = "techage:steelmat", weight = 20, min = 4, max = 8})
			table.insert(lab_pool, {item = "techage:aluminum", weight = 15, min = 4, max = 8})
			table.insert(lab_pool, {item = "techage:ta4_solar_module", weight = 15, min = 1, max = 3})
			table.insert(lab_pool, {item = "techage:cylinder_small_hydrogen", weight = 20, min = 2, max = 4})
		end
		if has_airtanks then
			table.insert(lab_pool, {item = "airtanks:steel_tank", weight = 15, min = 1, max = 1, is_tool = true})
		end

		local rolls = roll_loot_pool(lab_pool, random(5, 8))
		for _, it in ipairs(rolls) do table.insert(items, it) end
	end

	-- Populate inventory slots randomly with bounded search
	for _, itemstring in ipairs(items) do
		local slot = random(1, inv_size)
		local attempts = 0
		while attempts < inv_size and not inv:get_stack("main", slot):is_empty() do
			slot = (slot % inv_size) + 1
			attempts = attempts + 1
		end
		if attempts < inv_size then
			inv:set_stack("main", slot, ItemStack(itemstring))
		end
	end
end

-- -------------------------------------------------------------------------
-- 3. ROTATION & PLACEMENT ENGINE
-- -------------------------------------------------------------------------

local function rotate_offset(dx, dy, dz, rot)
	if rot == 1 then
		return dz, dy, -dx
	elseif rot == 2 then
		return -dx, dy, -dz
	elseif rot == 3 then
		return -dz, dy, dx
	end
	return dx, dy, dz
end

local function rotate_param2(p2, rot)
	-- For 4-way facedir nodes
	return (p2 + rot) % 4
end

local function apply_damage_and_debris(nodes, radius)
	if not radius or radius < 4 or not nodes then
		return nodes
	end

	-- Number of breach craters based on scale
	local breach_count = (radius >= 17) and random(2, 3) or ((radius >= 9) and 2 or 1)
	local breaches = {}

	for _ = 1, breach_count do
		-- Pick a breach point on outer hull / wing / engine
		local theta = random() * math.pi * 2
		local r_dist = radius * (0.40 + random() * 0.45)
		local bx = floor(math.cos(theta) * r_dist)
		local bz = floor(math.sin(theta) * r_dist)
		local by = random(0, 3)
		local brad = 2.5 + random() * 1.5 -- Blast radius 2.5 - 4.0m
		table.insert(breaches, {x = bx, y = by, z = bz, r = brad, r_sq = brad * brad})
	end

	local damaged_nodes = {}

	for _, n in ipairs(nodes) do
		-- 1. CRITICAL NODE IMMUNITY: Never destroy chests, beacons, or distress beacons
		if n.is_chest or (n.tier and n.tier:find("beacon")) or (c_beacon and n.cid == c_beacon) then
			table.insert(damaged_nodes, {dx = n.dx, dy = n.dy, dz = n.dz, cid = n.cid, param2 = n.param2, is_chest = n.is_chest, tier = n.tier})
		-- 2. MAIN WALKING FLOOR IMMUNITY: Preserve central aisle floor at Y=0, X=0
		elseif n.dy == 0 and n.dx == 0 then
			table.insert(damaged_nodes, {dx = n.dx, dy = n.dy, dz = n.dz, cid = n.cid, param2 = n.param2, is_chest = n.is_chest, tier = n.tier})
		else
			local in_breach = false
			local near_breach = false

			for _, b in ipairs(breaches) do
				local dx = n.dx - b.x
				local dy = n.dy - b.y
				local dz = n.dz - b.z
				local d_sq = dx * dx + dy * dy + dz * dz

				-- Ragged blast crater falloff
				if d_sq <= b.r_sq then
					local ratio = d_sq / b.r_sq
					if ratio < 0.70 or random() < 0.80 then
						in_breach = true
						break
					end
				elseif d_sq <= (b.r + 1.2) * (b.r + 1.2) then
					near_breach = true
				end
			end

			if not in_breach then
				local cid = n.cid
				-- Scorched / exposed wiring degradation on breach edges
				if near_breach and random() < 0.30 and cid == c_steelblock then
					cid = (random() < 0.5) and c_copperblock or c_bronzeblock
				end
				table.insert(damaged_nodes, {dx = n.dx, dy = n.dy, dz = n.dz, cid = cid, param2 = n.param2, is_chest = n.is_chest, tier = n.tier})
			end
		end
	end

	-- 3. ADRIFT DEBRIS FRAGMENTS (3 to 6 per breach floating into open space)
	for _, b in ipairs(breaches) do
		local frag_count = random(3, 6)
		for _ = 1, frag_count do
			local f_angle = random() * math.pi * 2
			local f_dist = b.r + random(2, 6)
			local fx = floor(b.x + math.cos(f_angle) * f_dist)
			local fz = floor(b.z + math.sin(f_angle) * f_dist)
			local fy = floor(b.y + random(-1, 2))
			local fcid = (random() < 0.6) and c_steelblock or ((random() < 0.5) and c_copperblock or c_bronzeblock)
			table.insert(damaged_nodes, {dx = fx, dy = fy, dz = fz, cid = fcid, param2 = 0})
		end
	end

	return damaged_nodes
end
derelicts.apply_damage_and_debris = apply_damage_and_debris

function derelicts.place_schematic(center, schematic, rot, data, param2_data, area)
	local chests = {}
	local placement_nodes = apply_damage_and_debris(schematic.nodes, schematic.radius)
	for _, n in ipairs(placement_nodes) do
		local rx, ry, rz = rotate_offset(n.dx, n.dy, n.dz, rot)
		local wx = center.x + rx
		local wy = center.y + ry
		local wz = center.z + rz

		if area:containsi(wx, wy, wz) then
			local vi = area:index(wx, wy, wz)
			data[vi] = n.cid
			if param2_data then
				param2_data[vi] = rotate_param2(n.param2, rot)
			end
			if n.is_chest then
				table.insert(chests, {pos = {x = wx, y = wy, z = wz}, tier = n.tier})
			end
		end
	end
	return chests
end

-- -------------------------------------------------------------------------
-- 4. MAPGEN INTEGRATION & CLEARANCE CHECKS
-- -------------------------------------------------------------------------

function derelicts.generate_in_chunk(minp, maxp, data, vm_or_param2, area, layer_type)
	if not c_air then
		init_content_ids()
	end

	-- Spatial Sector Spacing: Ensure at most 1 derelict per 160x160m horizontal sector
	-- Each sector is 2x2 mapblock chunks (chunks are 80x80)
	local sector_x = floor(minp.x / 160)
	local sector_z = floor(minp.z / 160)
	local chunk_in_sector_x = floor((minp.x - sector_x * 160) / 80)
	local chunk_in_sector_z = floor((minp.z - sector_z * 160) / 80)

	-- Hash sector coordinates to select one active chunk in the 2x2 sector
	local hash_seed = math.abs(sector_x * 73856093 + sector_z * 19349663)
	local active_chunk_idx = hash_seed % 4
	local current_chunk_idx = (chunk_in_sector_x % 2) + (chunk_in_sector_z % 2) * 2
	if current_chunk_idx ~= active_chunk_idx then
		return {}
	end

	-- Altitude-banded natural spawn rate & archetype weighting
	-- Low Orbit (space / Y < 5000): base 6. Probes (35%), Shuttles (25%), Solar Satellites (20%), Labs (10%), Corvettes (10%)
	-- Mars Orbit (redsky / 6000 <= Y < 7000): base 12. Mining Rigs (25%), Labs (20%), Shuttles (20%), Solar Satellites (15%), Cryo-Barges (10%), Corvettes (10%)
	-- Deep Space (blackness / Y >= 7000): base 25. Freighters (25%), Cryo-Barges (25%), Mining Rigs (20%), Corvettes (15%), Labs (15%)
	local base_divider
	local archetypes
	if layer_type == "blackness" then
		base_divider = 25
		archetypes = {
			get_freighter_schematic, get_freighter_schematic, get_freighter_schematic, get_freighter_schematic,
			get_cryo_barge_schematic, get_cryo_barge_schematic, get_cryo_barge_schematic, get_cryo_barge_schematic,
			get_mining_rig_schematic, get_mining_rig_schematic, get_mining_rig_schematic, get_mining_rig_schematic,
			get_corvette_schematic, get_corvette_schematic, get_corvette_schematic,
			get_biodome_schematic, get_biodome_schematic, get_biodome_schematic,
			get_lab_schematic, get_lab_schematic,
		}
	elseif layer_type == "redsky" then
		base_divider = 12
		archetypes = {
			get_mining_rig_schematic, get_mining_rig_schematic, get_mining_rig_schematic, get_mining_rig_schematic,
			get_biodome_schematic, get_biodome_schematic, get_biodome_schematic,
			get_lab_schematic, get_lab_schematic, get_lab_schematic,
			get_shuttle_schematic, get_shuttle_schematic, get_shuttle_schematic,
			get_power_satellite_schematic, get_power_satellite_schematic, get_power_satellite_schematic,
			get_cryo_barge_schematic, get_cryo_barge_schematic,
			get_corvette_schematic, get_corvette_schematic,
		}
	else -- space / low orbit
		base_divider = 6
		archetypes = {
			get_probe_schematic, get_probe_schematic, get_probe_schematic, get_probe_schematic, get_probe_schematic, get_probe_schematic,
			get_shuttle_schematic, get_shuttle_schematic, get_shuttle_schematic, get_shuttle_schematic,
			get_power_satellite_schematic, get_power_satellite_schematic, get_power_satellite_schematic,
			get_biodome_schematic, get_biodome_schematic,
			get_lab_schematic, get_lab_schematic,
			get_corvette_schematic, get_corvette_schematic,
		}
	end

	-- Server setting multiplier override if configured
	if minetest.settings and minetest.settings.get then
		local custom_rate = tonumber(minetest.settings:get("space_derelict_spawn_rate"))
		if custom_rate and custom_rate > 0 then
			base_divider = math.max(1, floor(base_divider * (custom_rate / 45)))
		end
	end
	base_divider = math.max(1, base_divider)

	if random(1, base_divider) ~= 1 then
		return {}
	end

	local schematic_fn = archetypes[random(1, #archetypes)]
	local schematic = schematic_fn()
	local rot = random(0, 3)
	local margin = schematic.radius + 2

	-- Boundary guard: chunk dimensions must accommodate the schematic margin
	if (minp.x + margin) >= (maxp.x - margin) or
	   (minp.y + margin) >= (maxp.y - margin) or
	   (minp.z + margin) >= (maxp.z - margin) then
		return {}
	end

	-- Random center point safely inside chunk boundaries
	local cx = random(minp.x + margin, maxp.x - margin)
	local cy = random(minp.y + margin, maxp.y - margin)
	local cz = random(minp.z + margin, maxp.z - margin)
	local center = {x = cx, y = cy, z = cz}

	-- Clearance check: ensure we don't spawn inside a solid asteroid core
	local solid_count = 0
	local total_samples = 0
	for dx = -schematic.radius, schematic.radius, 2 do
		for dy = -schematic.radius, schematic.radius, 2 do
			for dz = -schematic.radius, schematic.radius, 2 do
				local wx = cx + dx
				local wy = cy + dy
				local wz = cz + dz
				if area:containsi(wx, wy, wz) then
					local vi = area:index(wx, wy, wz)
					total_samples = total_samples + 1
					local cid = data[vi]
					if cid ~= c_air and cid ~= c_vacuum and cid ~= c_ignore then
						solid_count = solid_count + 1
					end
				end
			end
		end
	end

	-- Allow spawning in open vacuum or near edges (<= 25% solid nodes in bounding box)
	if total_samples > 0 and (solid_count / total_samples) > 0.25 then
		return {}
	end

	-- Lazily resolve param2 buffer: either passed table or fetched from VoxelManip object
	local param2_data = nil
	local is_vm = type(vm_or_param2) == "userdata" or (type(vm_or_param2) == "table" and vm_or_param2.get_param2_data ~= nil)
	if is_vm then
		param2_data = vm_or_param2:get_param2_data()
	elseif type(vm_or_param2) == "table" then
		param2_data = vm_or_param2
	end

	-- Place schematic into voxel data
	local chests = derelicts.place_schematic(center, schematic, rot, data, param2_data, area)

	-- If VoxelManip was passed, commit param2 buffer back
	if is_vm and param2_data and vm_or_param2.set_param2_data then
		vm_or_param2:set_param2_data(param2_data)
	end

	return chests
end

-- -------------------------------------------------------------------------
-- 5. ON-DEMAND SUBSPACE DISTRESS SCANNER & RANDOMIZED DERELICT EMERGENCE
-- -------------------------------------------------------------------------

function derelicts.scan_and_spawn_distress(player)
	if not player or not player.get_pos then return false end
	local pos = player:get_pos()
	local name = player:get_player_name()

	if pos.y < 1000 then
		minetest.chat_send_player(name, "[Subspace Scanner] Signal blocked by planetary atmosphere. Must be in orbital space (Y >= 1,000).")
		return false
	end

	-- Pick random coordinates 350-500m away in deep space (Y >= 8000)
	local angle = random() * math.pi * 2
	local dist = random(350, 500)
	local tx = floor(pos.x + math.cos(angle) * dist)
	local tz = floor(pos.z + math.sin(angle) * dist)
	local ty = random(8000, 9500)
	local target_pos = {x = tx, y = ty, z = tz}

	-- Pool of summonable capital & deep space derelicts
	local summon_pool = {
		get_freighter_schematic,
		get_cryo_barge_schematic,
		get_mining_rig_schematic,
		get_corvette_schematic,
		get_power_satellite_schematic,
		get_biodome_schematic,
		get_lab_schematic,
	}
	local selected_fn = summon_pool[random(1, #summon_pool)]
	local schematic = selected_fn()

	local margin = schematic.radius + 3
	local p1 = {x = tx - margin, y = ty - margin, z = tz - margin}
	local p2 = {x = tx + margin, y = ty + margin, z = tz + margin}

	minetest.chat_send_player(name, string.format("[Subspace Scanner] Detected faint emergency distress signal at (%d, %d, %d). Triangulating...", tx, ty, tz))
	if minetest.sound_play then
		minetest.sound_play("techage_ping", {to_player = name, gain = 1.0})
	end

	if minetest.emerge_area then
		minetest.emerge_area(p1, p2, function(blockpos, action, calls_remaining, param)
			if (minetest.EMERGE_CANCELLED and action == minetest.EMERGE_CANCELLED) or
			   (minetest.EMERGE_ERRORED and action == minetest.EMERGE_ERRORED) then
				return
			end
			if calls_remaining == 0 then
				local rot = random(0, 3)
				local beacon_label = "Derelict Vessel"
				local beacon_registered = false
				local placement_nodes = apply_damage_and_debris(schematic.nodes, schematic.radius)

				for _, n in ipairs(placement_nodes) do
					local rx, ry, rz = rotate_offset(n.dx, n.dy, n.dz, rot)
					local wpos = {x = target_pos.x + rx, y = target_pos.y + ry, z = target_pos.z + rz}
					local nodename = minetest.get_name_from_content_id(n.cid)
					local p2 = rotate_param2(n.param2 or 0, rot)
					if nodename and nodename ~= "air" and nodename ~= "ignore" then
						minetest.set_node(wpos, {name = nodename, param2 = p2})
						if n.is_chest then
							if n.tier and (n.tier:find("_beacon") or derelicts.beacon_titles[n.tier]) then
								local title = derelicts.beacon_titles[n.tier] or "Derelict Spacecraft"
								beacon_label = title
								local bmeta = minetest.get_meta(wpos)
								bmeta:set_string("ship_name", title)
								bmeta:set_string("owner", "")
								bmeta:set_string("infotext", "Navigation Beacon: [" .. title .. "]")
								if jumpdrive_tweaks and jumpdrive_tweaks.register_external_beacon then
									jumpdrive_tweaks.register_external_beacon(wpos, title, "")
								end
								beacon_registered = true
							else
								derelicts.populate_chest(wpos, n.tier)
							end
						end
					end
				end

				if not beacon_registered then
					local bpos = {x = target_pos.x, y = target_pos.y + (schematic.radius or 5), z = target_pos.z}
					minetest.set_node(bpos, {name = "jumpdrive_tweaks:beacon"})
					local bmeta = minetest.get_meta(bpos)
					bmeta:set_string("ship_name", beacon_label)
					bmeta:set_string("owner", "")
					bmeta:set_string("infotext", "Navigation Beacon: [" .. beacon_label .. "]")
					if jumpdrive_tweaks and jumpdrive_tweaks.register_external_beacon then
						jumpdrive_tweaks.register_external_beacon(bpos, beacon_label, "")
					end
				end

				minetest.chat_send_player(name, string.format("[Subspace Scanner] Signal locked! 3D distress waypoint registered for %s at (%d, %d, %d).", beacon_label, tx, ty, tz))
			end
		end)
	end

	return true, target_pos
end

derelicts.scan_and_spawn_freighter = derelicts.scan_and_spawn_distress

return derelicts
