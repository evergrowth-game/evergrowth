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

local function get_lab_schematic()
	if not c_air then init_content_ids() end
	-- Wrecked Orbital Research Module (~7x5x9)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- Main Module Floor (-2 to 2 X, -3 to 3 Z)
	for x = -2, 2 do
		for z = -3, 3 do
			add(x, 0, z, c_steelblock)
		end
	end

	-- Outer Walls with breaches and windows
	for z = -3, 3 do
		-- Left wall
		add(-2, 1, z, c_steelblock)
		add(-2, 2, z, (z == 0 or z == 1) and c_obsidian_glass or c_steelblock)
		add(-2, 3, z, c_steelblock)

		-- Right wall
		add(2, 1, z, c_steelblock)
		add(2, 2, z, (z == -1 or z == 0) and c_obsidian_glass or c_steelblock)
		add(2, 3, z, c_steelblock)
	end

	-- Front and Aft Endcaps
	for x = -1, 1 do
		add(x, 1, 4, c_bronzeblock)
		add(x, 2, 4, c_obsidian_glass)
		add(x, 3, 4, c_bronzeblock)

		-- Rear bulkhead (with breach at x = 0)
		if x ~= 0 then
			add(x, 1, -4, c_steelblock)
		end
		add(x, 2, -4, c_steelblock)
		add(x, 3, -4, c_steelblock)
	end

	-- Roof & Observation Cupola
	for x = -2, 2 do
		for z = -3, 3 do
			if math.abs(x) <= 1 and math.abs(z) <= 1 then
				add(x, 4, z, c_obsidian_glass) -- Skyward viewing cupola
			else
				add(x, 4, z, c_steelblock)
			end
		end
	end

	-- Machinery Installations (Electrolyzer & Solar Wings)
	add(-3, 2, 0, c_solar_carrier)
	add(3, 2, 0, c_solar_carrier)
	add(1, 1, 2, c_electrolyzer)
	add(-1, 1, 2, c_fuel_tank)

	-- High-Tier Secure Storage
	add(1, 1, -1, c_chest_ta4, 0, true, "lab")
	add(-1, 1, -1, c_chest_ta4, 0, true, "lab")

	return {
		name = "lab",
		size = {x = 7, y = 5, z = 9},
		radius = 5,
		nodes = nodes
	}
end

local function get_freighter_schematic()
	if not c_air then init_content_ids() end
	-- Derelict Heavy Capital Freighter (~15x9x25, radius 13)
	local nodes = {}
	local function add(dx, dy, dz, cid, p2, is_chest, tier)
		table.insert(nodes, {dx = dx, dy = dy, dz = dz, cid = cid, param2 = p2 or 0, is_chest = is_chest, tier = tier})
	end

	-- 1. Main Deck Floor and Upper Ceiling (-4 to 4 X, -10 to 10 Z)
	for z = -10, 10 do
		local width = (z >= 8) and 2 or ((z <= -8) and 3 or 4)
		for x = -width, width do
			add(x, 0, z, c_steelblock)
			add(x, 4, z, (math.abs(x) == width or z == 10 or z == -10) and c_steelblock or c_obsidian_glass)
		end
	end

	-- 2. Outer Hull Walls & Armor Plating
	for z = -10, 10 do
		local width = (z >= 8) and 2 or ((z <= -8) and 3 or 4)
		for y = 1, 3 do
			-- Hull breaches on flank (z == 2 or z == -4)
			if not ((z == 2 or z == -4) and y >= 2) then
				add(-width, y, z, c_steelblock)
				add(width, y, z, c_steelblock)
			end
		end
	end

	-- 3. Command Bridge (Z = 8 to 11, X = -2 to 2)
	for x = -1, 1 do
		add(x, 1, 11, c_bronzeblock)
		add(x, 2, 11, c_obsidian_glass)
		add(x, 3, 11, c_obsidian_glass)
	end
	add(0, 1, 9, c_solar_carrier)
	add(1, 1, 8, c_chest_ta4, 0, true, "lab")

	-- 4. Cargo Holds & Storage Bays (Z = 0 to 7)
	-- Left Bay
	add(-2, 1, 4, c_chest_ta3, 0, true, "shuttle")
	add(-2, 1, 5, c_chest_ta4, 0, true, "lab")
	add(-3, 1, 3, c_fuel_tank)
	add(-3, 2, 3, c_fuel_tank)

	-- Right Bay
	add(2, 1, 4, c_chest_ta3, 0, true, "shuttle")
	add(2, 1, 5, c_chest_ta4, 0, true, "shuttle")
	add(3, 1, 3, c_fuel_tank)
	add(3, 2, 3, c_fuel_tank)

	-- 5. Engineering & Reactor Core (Z = -2 to -7)
	for x = -2, 2 do
		for y = 1, 3 do
			if math.abs(x) == 2 then
				add(x, y, -2, c_steelblock)
				add(x, y, -7, c_steelblock)
			end
		end
	end
	add(0, 1, -5, c_electrolyzer)
	add(0, 2, -5, c_copperblock)
	add(1, 1, -5, c_fuel_tank)
	add(-1, 1, -5, c_fuel_tank)
	add(0, 1, -4, c_chest_ta4, 0, true, "lab")
	add(0, 1, -6, c_chest_ta4, 0, true, "lab")

	-- 6. Rear Twin Thruster Nacelles (X = -5 and +5, Z = -8 to -12)
	for _, sx in ipairs({-5, 5}) do
		for z = -12, -8 do
			for y = 0, 2 do
				add(sx, y, z, c_steelblock)
			end
		end
		add(sx, 1, -13, c_copperblock)
		add(sx, 1, -14, c_bronzeblock)
		add(sx, 1, -8, c_fuel_tank)
	end

	-- 7. Command Spire & Active Distress Beacon (0, 6, 0)
	add(0, 5, 0, c_copperblock)
	add(0, 6, 0, c_beacon, 0, true, "freighter_beacon")

	return {
		name = "freighter",
		size = {x = 15, y = 9, z = 25},
		radius = 13,
		nodes = nodes
	}
end
derelicts.get_freighter_schematic = get_freighter_schematic

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
	if tier == "lab" then
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

function derelicts.place_schematic(center, schematic, rot, data, param2_data, area)
	local chests = {}
	for _, n in ipairs(schematic.nodes) do
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
	-- Low Orbit (space / Y < 5000): base 6 (effective 1-in-24 chunks, ~4.2%). Probes (70%), Shuttles (30%)
	-- Mars Orbit (redsky / 6000 <= Y < 7000): base 12 (effective 1-in-48 chunks, ~2.1%). Probes (50%), Shuttles (50%)
	-- Deep Space (blackness / Y >= 7000): base 25 (effective 1-in-100 chunks, ~1.0%). Labs (80%), Shuttles (20%)
	local base_divider
	local archetypes
	if layer_type == "blackness" then
		base_divider = 25
		archetypes = {get_lab_schematic(), get_lab_schematic(), get_lab_schematic(), get_lab_schematic(), get_shuttle_schematic()}
	elseif layer_type == "redsky" then
		base_divider = 12
		archetypes = {get_probe_schematic(), get_shuttle_schematic()}
	else -- space / low orbit
		base_divider = 6
		archetypes = {get_probe_schematic(), get_probe_schematic(), get_probe_schematic(), get_shuttle_schematic()}
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

	local schematic = archetypes[random(1, #archetypes)]
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
-- 5. ON-DEMAND SUBSPACE DISTRESS SCANNER & FREIGHTER EMERGENCE
-- -------------------------------------------------------------------------

function derelicts.scan_and_spawn_freighter(player)
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

	minetest.chat_send_player(name, string.format("[Subspace Scanner] Detected faint emergency distress signal at (%d, %d, %d). Triangulating...", tx, ty, tz))
	if minetest.sound_play then
		minetest.sound_play("techage_ping", {to_player = name, gain = 1.0})
	end

	local p1 = {x = tx - 16, y = ty - 10, z = tz - 16}
	local p2 = {x = tx + 16, y = ty + 10, z = tz + 16}

	if minetest.emerge_area then
		minetest.emerge_area(p1, p2, function(blockpos, action, calls_remaining, param)
			if (minetest.EMERGE_CANCELLED and action == minetest.EMERGE_CANCELLED) or
			   (minetest.EMERGE_ERRORED and action == minetest.EMERGE_ERRORED) then
				return
			end
			if calls_remaining == 0 then
				local vm = minetest.get_voxel_manip(p1, p2)
				local emin, emax = vm:get_emerged_area()
				local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
				local data = vm:get_data()
				local param2_data = vm:get_param2_data()

				local schematic = get_freighter_schematic()
				local rot = random(0, 3)
				local chests = derelicts.place_schematic(target_pos, schematic, rot, data, param2_data, area)

				vm:set_data(data)
				vm:set_param2_data(param2_data)
				vm:write_to_map()
				vm:update_map()

				for _, c in ipairs(chests) do
					if c.tier == "freighter_beacon" then
						local bmeta = minetest.get_meta(c.pos)
						bmeta:set_string("ship_name", "Derelict Heavy Freighter [DISTRESS]")
						bmeta:set_string("owner", "")
						bmeta:set_string("infotext", "Navigation Beacon: [Derelict Heavy Freighter [DISTRESS]]")
						if jumpdrive_tweaks and jumpdrive_tweaks.register_external_beacon then
							jumpdrive_tweaks.register_external_beacon(c.pos, "Derelict Heavy Freighter [DISTRESS]", "")
						end
					else
						derelicts.populate_chest(c.pos, c.tier)
					end
				end

				minetest.chat_send_player(name, string.format("[Subspace Scanner] Signal locked! 3D distress waypoint registered at (%d, %d, %d).", tx, ty, tz))
			end
		end)
	end

	return true, target_pos
end

return derelicts
