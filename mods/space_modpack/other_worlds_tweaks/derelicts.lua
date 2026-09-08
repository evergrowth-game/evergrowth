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
local c_solar_minicell
local c_solar_carrier
local c_electrolyzer
local c_fuel_tank

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

	c_solar_minicell = (has_techage and minetest.registered_nodes["techage:ta4_solar_minicell"])
		and minetest.get_content_id("techage:ta4_solar_minicell") or c_steelblock

	c_solar_carrier = (has_techage and minetest.registered_nodes["techage:ta4_solar_carrier"])
		and minetest.get_content_id("techage:ta4_solar_carrier") or c_steelblock

	c_electrolyzer = (has_techage and minetest.registered_nodes["techage:ta4_electrolyzer"])
		and minetest.get_content_id("techage:ta4_electrolyzer") or c_steelblock

	c_fuel_tank = (has_jumpdrive and minetest.registered_nodes["jumpdrive_tweaks:fuel_tank"])
		and minetest.get_content_id("jumpdrive_tweaks:fuel_tank") or c_steelblock
end

-- -------------------------------------------------------------------------
-- 1. SCHEMATIC DEFINITIONS (Relative 3D coordinates: dx, dy, dz, content_id, param2, is_chest, chest_tier)
-- -------------------------------------------------------------------------

local function get_probe_schematic()
	if not c_air then init_content_ids() end
	-- Adrift Science Probe (~3x3x5)
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

	-- Solar wings
	add(1, 0, 0, c_solar_minicell)
	add(2, 0, 0, c_solar_minicell)
	add(-1, 0, 0, c_solar_minicell)
	add(-2, 0, 0, c_solar_minicell)

	-- Salvage container (underside)
	add(0, -1, 0, c_chest_ta3, 0, true, "probe")

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

-- -------------------------------------------------------------------------
-- 2. LOOT POPULATION ENGINE
-- -------------------------------------------------------------------------

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
		-- Probe loot: Electronic parts, small circuits, solar cells, air
		if has_techage then
			table.insert(items, "techage:ta4_wlanchip " .. random(1, 2))
			table.insert(items, "techage:aluminum " .. random(2, 5))
			table.insert(items, "techage:ta4_solar_minicell " .. random(1, 2))
		else
			table.insert(items, "default:copper_ingot " .. random(3, 6))
			table.insert(items, "default:mese_crystal " .. random(1, 2))
		end
		if has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(1, 2))
		end
		table.insert(items, "default:steel_ingot " .. random(2, 6))

	elseif tier == "shuttle" then
		-- Shuttle loot: Fuel canisters, cylinders, structural alloys, breathing air
		if has_techage then
			table.insert(items, "techage:cylinder_small_hydrogen " .. random(2, 4))
			table.insert(items, "techage:ta3_cylinder_small " .. random(2, 5))
			table.insert(items, "techage:steelmat " .. random(2, 6))
			table.insert(items, "techage:aluminum " .. random(2, 4))
		end
		if has_airtanks then
			for _ = 1, random(1, 2) do
				table.insert(items, "airtanks:steel_tank")
			end
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(2, 4))
		end
		table.insert(items, "default:gold_ingot " .. random(2, 5))
		table.insert(items, "default:bronze_ingot " .. random(4, 8))

	elseif tier == "lab" then
		-- Lab loot: High-tech components, carbon fiber, gems, high-capacity propellant
		if has_techage then
			table.insert(items, "techage:ta4_carbon_fiber " .. random(2, 4))
			table.insert(items, "techage:ta4_wlanchip " .. random(2, 3))
			table.insert(items, "techage:cylinder_small_hydrogen " .. random(3, 6))
			table.insert(items, "techage:steelmat " .. random(4, 8))
			table.insert(items, "techage:ta4_solar_minicell " .. random(2, 4))
		end
		if has_airtanks then
			for _ = 1, 2 do
				table.insert(items, "airtanks:steel_tank")
			end
		elseif has_vacuum then
			table.insert(items, "vacuum:air_bottle " .. random(3, 6))
		end
		table.insert(items, "default:diamond " .. random(2, 4))
		table.insert(items, "default:mese_crystal " .. random(3, 6))
		table.insert(items, "default:gold_ingot " .. random(4, 8))
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

	-- Spawn frequency roll per chunk
	-- Space: 1 in 12 (~8.3%)
	-- Redsky: 1 in 16 (~6.2%)
	-- Deep Space: 1 in 10 (~10.0%)
	local spawn_chance = (layer_type == "blackness") and 10 or ((layer_type == "redsky") and 16 or 12)
	if random(1, spawn_chance) ~= 1 then
		return {}
	end

	-- Select archetype based on layer
	local archetypes = {get_probe_schematic(), get_shuttle_schematic()}
	if layer_type == "blackness" or random(1, 3) == 1 then
		table.insert(archetypes, get_lab_schematic())
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

return derelicts
