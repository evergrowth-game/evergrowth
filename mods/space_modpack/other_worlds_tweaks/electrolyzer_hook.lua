-- other_worlds_tweaks/electrolyzer_hook.lua
-- Integrates TechAge TA4 Electrolyzer with water pipe feedstock & orbital ISRU physics

local has_techage = minetest.get_modpath("techage")
local has_networks = minetest.get_modpath("networks")

if not has_techage or not has_networks then return end

local M = minetest.get_meta
local S = techage.S or minetest.get_translator("other_worlds_tweaks")
local Cable = techage.ElectricCable
local Pipe = techage.LiquidPipe
local power = networks.power
local liquid = networks.liquid

local PWR_NEEDED = 35
local PWR_UNITS_PER_HYDROGEN_ITEM = 80
local CAPACITY_H2 = 200
local CAPACITY_WATER = 200
local WATER_PER_HYDROGEN = 1

local function evaluate_percent(s)
	return (tonumber(s:sub(1, -2)) or 0) / 100
end

local function get_electrolyzer_formspec(self, pos, nvm)
	local h2_amount = (nvm.liquid and nvm.liquid.amount) or 0
	local water_amount = nvm.water_amount or 0
	local arrow = "image[2.7,1.3;1,1;techage_form_arrow_bg.png^[transformR270]"
	if techage.is_running(nvm) then
		arrow = "image[2.7,1.3;1,1;techage_form_arrow_fg.png^[transformR270]"
	end

	local hotbar_bg = default.get_hotbar_bg and default.get_hotbar_bg(0, 4.85) or ""

	return "size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"box[0,-0.1;7.8,0.5;#252830]" ..
		"label[0.2,-0.1;" .. minetest.colorize("#00ffff", S("TA4 Space Electrolyzer (ISRU)")) .. "]" ..
		techage.wrench_tooltip(7.4, -0.1) ..
		techage.formspec_power_bar(pos, 0.2, 0.7, S("Electricity"), nvm.taken or 0, PWR_NEEDED) ..
		arrow ..
		"image_button[2.7,2.7;1,1;" .. self:get_state_button_image(nvm) .. ";state_button;]" ..
		"tooltip[2.7,2.7;1,1;" .. self:get_state_tooltip(nvm) .. "]" ..
		"box[4.0,0.7;3.8,1.5;#10141a]" ..
		"label[4.2,0.9;" .. minetest.colorize("#70a1ff", S("Water Feedstock (Back Port B):")) .. "]" ..
		"label[4.2,1.4;" .. minetest.colorize("#ffffff", string.format("%d / %d units", water_amount, CAPACITY_WATER)) .. "]" ..
		"box[4.0,2.5;3.8,1.5;#10141a]" ..
		"label[4.2,2.7;" .. minetest.colorize("#00ffcc", S("Hydrogen Gas (Right Port R):")) .. "]" ..
		"label[4.2,3.2;" .. minetest.colorize("#ffffff", string.format("%d / %d units", h2_amount, CAPACITY_H2)) .. "]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[current_player;main]" ..
		hotbar_bg
end

local function can_start(pos, nvm, state)
	nvm.liquid = nvm.liquid or {}
	nvm.liquid.amount = nvm.liquid.amount or 0

	if nvm.liquid.amount >= CAPACITY_H2 then
		return S("Storage full")
	end
	if pos.y >= 1000 and (nvm.water_amount or 0) < WATER_PER_HYDROGEN then
		return S("No water feedstock")
	end
	return true
end

local function start_node(pos, nvm, state)
	nvm.taken = 0
	nvm.reduction = evaluate_percent(M(pos):get_string("reduction"))
	nvm.turnoff = evaluate_percent(M(pos):get_string("turnoff"))
end

local function stop_node(pos, nvm, state)
	nvm.taken = 0
	nvm.running = nil
end

local State = techage.NodeStates:new({
	node_name_passive = "techage:ta4_electrolyzer",
	node_name_active = "techage:ta4_electrolyzer_on",
	cycle_time = 2,
	standby_ticks = 3,
	formspec_func = get_electrolyzer_formspec,
	infotext_name = S("TA4 Electrolyzer"),
	can_start = can_start,
	start_node = start_node,
	stop_node = stop_node,
})

-- Generator reaction: consumes electrical power units and water feedstock
local function generating_with_water(pos, nvm)
	nvm.num_pwr_units = nvm.num_pwr_units or 0
	nvm.water_amount = nvm.water_amount or 0
	nvm.liquid = nvm.liquid or {}
	nvm.liquid.amount = nvm.liquid.amount or 0

	if (nvm.taken or 0) > 0 then
		nvm.num_pwr_units = nvm.num_pwr_units + (nvm.taken or 0)
		if nvm.num_pwr_units >= PWR_UNITS_PER_HYDROGEN_ITEM then
			-- Check water consumption
			if pos.y >= 1000 or nvm.water_amount > 0 then
				if nvm.water_amount >= WATER_PER_HYDROGEN then
					nvm.water_amount = nvm.water_amount - WATER_PER_HYDROGEN
					nvm.liquid.amount = nvm.liquid.amount + 1
					nvm.liquid.name = "techage:hydrogen"
					nvm.num_pwr_units = nvm.num_pwr_units - PWR_UNITS_PER_HYDROGEN_ITEM
				end
			else
				-- Terrestrial baseline without water pipes
				nvm.liquid.amount = nvm.liquid.amount + 1
				nvm.liquid.name = "techage:hydrogen"
				nvm.num_pwr_units = nvm.num_pwr_units - PWR_UNITS_PER_HYDROGEN_ITEM
			end
		end
	end
end

-- Hook NodeStates, timer, tiles, and dual-liquid network
local def_passive = minetest.registered_nodes["techage:ta4_electrolyzer"]
local def_active = minetest.registered_nodes["techage:ta4_electrolyzer_on"]
if def_passive and def_active then

	-- 1. Update node tiles to display square pipe intake on the back face
	local new_tiles_passive = {
		"techage_filling_ta4.png^techage_frame_ta4_top.png^techage_appl_arrow.png",
		"techage_filling_ta4.png^techage_frame_ta4.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_pipe.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_electric.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_pipe.png", -- Back face now shows water intake port
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_electrolyzer.png^techage_appl_ctrl_unit.png",
	}

	local new_tiles_active = {
		"techage_filling_ta4.png^techage_frame_ta4_top.png^techage_appl_arrow.png",
		"techage_filling_ta4.png^techage_frame_ta4.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_pipe.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_electric.png",
		"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_hole_pipe.png", -- Back face
		{
			name = "techage_filling4_ta4.png^techage_frame4_ta4.png^techage_appl_electrolyzer4.png^techage_appl_ctrl_unit4.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.8,
			},
		},
	}

	-- 2. Timer override for water validation
	local function custom_electrolyzer_timer(pos, elapsed)
		local meta = M(pos)
		local nvm = techage.get_nvm(pos)
		nvm.liquid = nvm.liquid or {}
		nvm.liquid.amount = nvm.liquid.amount or 0
		nvm.water_amount = nvm.water_amount or 0

		-- In orbit, strictly enforce water presence
		if pos.y >= 1000 and nvm.water_amount < WATER_PER_HYDROGEN then
			nvm.taken = 0
			State:standby(pos, nvm, S("No water feedstock (connect back pipe)"))
			if techage.is_activeformspec(pos) then
				meta:set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
			end
			return true
		end

		if nvm.liquid.amount < CAPACITY_H2 then
			local in_dir = meta:get_int("in_dir")
			local curr_load = power.get_storage_load(pos, Cable, in_dir, 1)
			if curr_load > (nvm.turnoff or 0) then
				local to_be_taken = PWR_NEEDED * (nvm.reduction or 1)
				nvm.taken = power.consume_power(pos, Cable, in_dir, to_be_taken) or 0
				local running = techage.is_running(nvm)
				if not running and nvm.taken == to_be_taken then
					State:start(pos, nvm)
				elseif running and nvm.taken < to_be_taken then
					State:nopower(pos, nvm)
				elseif running then
					generating_with_water(pos, nvm)
					State:keep_running(pos, nvm, 1)
				end
			elseif curr_load == 0 then
				nvm.taken = 0
				State:nopower(pos, nvm)
			else
				nvm.taken = 0
				State:standby(pos, nvm, S("Turnoff point reached"))
			end
		else
			nvm.taken = 0
			State:blocked(pos, nvm, S("Hydrogen storage full"))
		end

		if techage.is_activeformspec(pos) then
			meta:set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
		end
		return true
	end

	local function on_receive_fields(pos, formname, fields, player)
		if minetest.is_protected(pos, player:get_player_name()) then return end
		local nvm = techage.get_nvm(pos)
		techage.set_activeformspec(pos, player)
		State:state_button_event(pos, nvm, fields)
		M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
	end

	local function on_rightclick(pos, node, clicker)
		local nvm = techage.get_nvm(pos)
		techage.set_activeformspec(pos, clicker)
		M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
	end

	local function custom_can_dig(pos, player)
		local player_name = player and player:get_player_name() or ""
		if minetest.is_protected(pos, player_name) then return false end
		local nvm = techage.get_nvm(pos)
		local h2_empty = not nvm.liquid or (nvm.liquid.amount or 0) <= 0
		local water_empty = not nvm.water_amount or nvm.water_amount <= 0
		return h2_empty and water_empty
	end

	local orig_def = minetest.registered_nodes["techage:ta4_electrolyzer"]
	local orig_after_place = orig_def and orig_def.after_place_node

	minetest.override_item("techage:ta4_electrolyzer", {
		tiles = new_tiles_passive,
		on_timer = custom_electrolyzer_timer,
		on_receive_fields = on_receive_fields,
		on_rightclick = on_rightclick,
		can_dig = custom_can_dig,
		after_place_node = function(pos, ...)
			if orig_after_place then
				orig_after_place(pos, ...)
			end
			local nvm = techage.get_nvm(pos)
			M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
		end,
	})

	minetest.override_item("techage:ta4_electrolyzer_on", {
		tiles = new_tiles_active,
		on_timer = custom_electrolyzer_timer,
		on_receive_fields = on_receive_fields,
		on_rightclick = on_rightclick,
	})

	-- 3. Dual-Port Liquid Network Integration (Right: H2 output, Back: Water input)
	local dual_liquid_def = {
		capa = CAPACITY_H2,
		peek = function(pos, indir)
			local nvm = techage.get_nvm(pos)
			local node = minetest.get_node(pos)
			local back_dir = techage.side_to_indir("B", node.param2)
			if indir == back_dir then
				return (nvm.water_amount and nvm.water_amount > 0) and "techage:water" or nil
			end
			local right_dir = techage.side_to_indir("R", node.param2)
			if not indir or indir == right_dir then
				return liquid.srv_peek(nvm)
			end
			return nil
		end,
		put = function(pos, indir, name, amount)
			local node = minetest.get_node(pos)
			local back_dir = techage.side_to_indir("B", node.param2)
			if indir == back_dir then
				-- Accept any water variant and store as canonical water units
				if name == "techage:water" or name == "techage:river_water" or name == "default:water_source" then
					local nvm = techage.get_nvm(pos)
					nvm.water_amount = nvm.water_amount or 0
					local space = CAPACITY_WATER - nvm.water_amount
					local to_add = math.min(space, amount)
					nvm.water_amount = nvm.water_amount + to_add
					if techage.is_activeformspec(pos) then
						M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
					end
					return amount - to_add
				end
			end
			return amount
		end,
		take = function(pos, indir, name, amount)
			local node = minetest.get_node(pos)
			local right_dir = techage.side_to_indir("R", node.param2)
			if indir == right_dir then
				local nvm = techage.get_nvm(pos)
				amount, name = liquid.srv_take(nvm, name, amount)
				if techage.is_activeformspec(pos) then
					M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
				end
				return amount, name
			end
			return 0, name
		end,
		untake = function(pos, indir, name, amount)
			local node = minetest.get_node(pos)
			local right_dir = techage.side_to_indir("R", node.param2)
			if indir == right_dir then
				if name ~= "techage:hydrogen" then
					return amount
				end
				local nvm = techage.get_nvm(pos)
				local leftover = liquid.srv_put(nvm, name, amount, CAPACITY_H2)
				if techage.is_activeformspec(pos) then
					M(pos):set_string("formspec", get_electrolyzer_formspec(State, pos, nvm))
				end
				return leftover
			end
			return amount
		end,
	}

	liquid.register_nodes({"techage:ta4_electrolyzer", "techage:ta4_electrolyzer_on"}, Pipe, "tank", {"R", "B"}, dual_liquid_def)
end

minetest.log("action", "[other_worlds_tweaks] Loaded TechAge water-fed electrolyzer ISRU compatibility hook.")
