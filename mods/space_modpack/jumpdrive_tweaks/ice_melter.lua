-- jumpdrive_tweaks/ice_melter.lua
-- Starship Thermal Ice Melter & Liquefier for In-Situ Propellant Refining

local S = minetest.get_translator("jumpdrive_tweaks")
local M = minetest.get_meta

local has_techage = minetest.get_modpath("techage")
local has_networks = minetest.get_modpath("networks")

if not has_techage or not has_networks then return end

local Cable = techage.ElectricCable
local Pipe = techage.LiquidPipe
local power = networks.power
local liquid = networks.liquid

local CYCLE_TIME = 2
local STANDBY_TICKS = 3
local PWR_NEEDED = 12
local CAPACITY = 200
local TURNOFF_THRESHOLD = "40%"

-- Conversion table: solid ice item -> liquid water units
local ICE_CONVERSIONS = {
	["other_worlds_tweaks:comet_ice"] = 10,
	["default:ice"] = 5,
	["default:snowblock"] = 2,
	["default:snow"] = 1,
}

local function evaluate_percent(s)
	return (tonumber(s:sub(1, -2)) or 0) / 100
end

local function get_formspec(self, pos, nvm)
	local water_amount = (nvm.liquid and nvm.liquid.amount) or 0
	local arrow = "image[4.5,1.3;1,1;techage_form_arrow_bg.png^[transformR270]"
	if techage.is_running(nvm) then
		arrow = "image[4.5,1.3;1,1;techage_form_arrow_fg.png^[transformR270]"
	end

	local hotbar_bg = default.get_hotbar_bg and default.get_hotbar_bg(0, 4.85) or ""

	return "size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"box[0,-0.1;7.8,0.5;#252830]" ..
		"label[0.2,-0.1;" .. minetest.colorize("#00ffff", S("Starship Thermal Ice Melter")) .. "]" ..
		techage.wrench_tooltip(7.4, -0.1) ..
		techage.formspec_power_bar(pos, 0.2, 0.7, S("Electricity"), nvm.taken or 0, PWR_NEEDED) ..
		"label[3.0,0.8;" .. S("Ice Feedstock") .. "]" ..
		"list[context;src;3.2,1.3;1,1;]" ..
		arrow ..
		"image_button[3.2,2.7;1,1;" .. self:get_state_button_image(nvm) .. ";state_button;]" ..
		"tooltip[3.2,2.7;1,1;" .. self:get_state_tooltip(nvm) .. "]" ..
		"label[4.3,3.0;" .. (techage.is_running(nvm) and minetest.colorize("#00ff99", S("ACTIVE")) or minetest.colorize("#ffaa00", S("STANDBY"))) .. "]" ..
		"box[5.6,0.7;2.2,3.3;#10141a]" ..
		"label[5.8,0.9;" .. minetest.colorize("#70a1ff", S("Water Tank")) .. "]" ..
		"label[5.8,1.5;" .. minetest.colorize("#00ffcc", S("Buffer Output:")) .. "]" ..
		"label[5.8,1.9;" .. minetest.colorize("#ffffff", string.format("%d / %d", water_amount, CAPACITY)) .. "]" ..
		"label[5.8,2.3;" .. minetest.colorize("#ffffff", S("units")) .. "]" ..
		"label[5.8,2.9;" .. minetest.colorize("#8899aa", S("Pipes: Right (R)")) .. "]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[context;src]" ..
		"listring[current_player;main]" ..
		hotbar_bg
end

local function can_start(pos, nvm, state)
	nvm.liquid = nvm.liquid or {}
	nvm.liquid.amount = nvm.liquid.amount or 0

	if nvm.liquid.amount >= CAPACITY then
		return S("Water tank full")
	end

	local inv = M(pos):get_inventory()
	local stack = inv:get_stack("src", 1)
	if stack:is_empty() then
		return S("No ice in hopper")
	end

	local item_name = stack:get_name()
	if not ICE_CONVERSIONS[item_name] then
		return S("Invalid item (requires ice)")
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
end

local State = techage.NodeStates:new({
	node_name_passive = "jumpdrive_tweaks:ice_melter",
	node_name_active = "jumpdrive_tweaks:ice_melter_active",
	cycle_time = CYCLE_TIME,
	standby_ticks = STANDBY_TICKS,
	formspec_func = get_formspec,
	infotext_name = S("Starship Thermal Ice Melter"),
	can_start = can_start,
	start_node = start_node,
	stop_node = stop_node,
})

-- Processes ice liquefaction
local function process_melting(pos, nvm)
	nvm.liquid = nvm.liquid or {}
	nvm.liquid.amount = nvm.liquid.amount or 0

	local inv = M(pos):get_inventory()
	local stack = inv:get_stack("src", 1)
	if stack:is_empty() then return end

	local item_name = stack:get_name()
	local yield = ICE_CONVERSIONS[item_name]
	if not yield then return end

	if nvm.liquid.amount + yield <= CAPACITY then
		stack:take_item(1)
		inv:set_stack("src", 1, stack)
		nvm.liquid.amount = nvm.liquid.amount + yield
		nvm.liquid.name = "techage:water"
	end
end

local function push_water(pos, meta, nvm)
	if nvm.liquid and (nvm.liquid.amount or 0) > 0 then
		local out_dir = meta:get_int("out_dir")
		if out_dir == 0 then
			local node = minetest.get_node(pos)
			out_dir = techage.side_to_outdir("R", node.param2)
			meta:set_int("out_dir", out_dir)
		end
		local to_push = math.min(nvm.liquid.amount, 50)
		local leftover = liquid.put(pos, Pipe, out_dir, "techage:water", to_push)
		nvm.liquid.amount = nvm.liquid.amount - (to_push - leftover)
		if nvm.liquid.amount == 0 then
			nvm.liquid.name = nil
		end
	end
end

-- Automatic node timer loop
local function node_timer(pos, elapsed)
	local meta = M(pos)
	local nvm = techage.get_nvm(pos)
	nvm.liquid = nvm.liquid or {}
	nvm.liquid.amount = nvm.liquid.amount or 0

	-- 1. Push any stored water out to connected pipes/tanks first to free up buffer space
	push_water(pos, meta, nvm)

	local inv = meta:get_inventory()
	local stack = inv:get_stack("src", 1)
	local item_name = stack:get_name()
	local yield = ICE_CONVERSIONS[item_name]

	if stack:is_empty() then
		nvm.taken = 0
		State:standby(pos, nvm, S("No ice in hopper"))
	elseif not yield then
		nvm.taken = 0
		State:standby(pos, nvm, S("Invalid item (requires ice)"))
	elseif nvm.liquid.amount + yield > CAPACITY then
		nvm.taken = 0
		State:blocked(pos, nvm, S("Water tank full"))
	else
		local in_dir = meta:get_int("in_dir")
		if in_dir == 0 then
			local node = minetest.get_node(pos)
			in_dir = techage.side_to_outdir("L", node.param2)
			meta:set_int("in_dir", in_dir)
		end

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
				process_melting(pos, nvm)
				State:keep_running(pos, nvm, 1)
				-- Push newly melted water out immediately
				push_water(pos, meta, nvm)
			end
		elseif curr_load == 0 then
			nvm.taken = 0
			State:nopower(pos, nvm)
		else
			nvm.taken = 0
			State:standby(pos, nvm, S("Turnoff point reached"))
		end
	end

	if techage.is_activeformspec(pos) then
		meta:set_string("formspec", get_formspec(State, pos, nvm))
	end
	return true
end

local function on_receive_fields(pos, formname, fields, player)
	if minetest.is_protected(pos, player:get_player_name()) then return end
	local nvm = techage.get_nvm(pos)
	push_water(pos, M(pos), nvm)
	techage.set_activeformspec(pos, player)
	State:state_button_event(pos, nvm, fields)
	M(pos):set_string("formspec", get_formspec(State, pos, nvm))
end

local function on_rightclick(pos, node, clicker)
	local nvm = techage.get_nvm(pos)
	push_water(pos, M(pos), nvm)
	techage.set_activeformspec(pos, clicker)
	M(pos):set_string("formspec", get_formspec(State, pos, nvm))
end

local function after_place_node(pos)
	local nvm = techage.get_nvm(pos)
	nvm.running = false
	local number = techage.add_node(pos, "jumpdrive_tweaks:ice_melter")
	State:node_init(pos, nvm, number)
	
	local inv = M(pos):get_inventory()
	inv:set_size("src", 1)

	local node = minetest.get_node(pos)
	M(pos):set_int("in_dir", techage.side_to_outdir("L", node.param2))
	M(pos):set_int("out_dir", techage.side_to_outdir("R", node.param2))
	M(pos):set_string("reduction", "100%")
	M(pos):set_string("turnoff", TURNOFF_THRESHOLD)

	Pipe:after_place_node(pos)
	Cable:after_place_node(pos)
end

local function after_dig_node(pos, oldnode, oldmetadata, digger)
	Pipe:after_dig_node(pos)
	Cable:after_dig_node(pos)
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then return 0 end
	if listname == "src" and ICE_CONVERSIONS[stack:get_name()] then
		return stack:get_count()
	end
	return 0
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then return 0 end
	return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	if minetest.is_protected(pos, player:get_player_name()) then return 0 end
	return count
end

local tool_config = {
	{
		type = "const",
		name = "needed",
		label = S("Maximum power consumption [ku]"),
		tooltip = S("Thermal liquefier power consumption"),
		value = PWR_NEEDED,
	},
	{
		type = "dropdown",
		choices = "20%,40%,60%,80%,100%",
		name = "reduction",
		label = S("Current limitation"),
		tooltip = S("Configurable value for heating rate"),
		default = "100%",
	},
	{
		type = "dropdown",
		choices = "0%,20%,40%,60%,80%,98%",
		name = "turnoff",
		label = S("Turnoff point"),
		tooltip = S("Storage cutoff threshold"),
		default = TURNOFF_THRESHOLD,
	},
}

-- 1. Passive Node
minetest.register_node("jumpdrive_tweaks:ice_melter", {
	description = S("Starship Thermal Ice Melter"),
	tiles = {
		"jumpdrive_ice_melter_top.png",
		"jumpdrive_ice_melter_side.png",
		"jumpdrive_ice_melter_right.png",
		"jumpdrive_ice_melter_left.png",
		"jumpdrive_ice_melter_side.png",
		"jumpdrive_ice_melter_front.png",
	},
	groups = {cracky = 1, jumpdrive_ship_part = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),

	can_dig = function(pos, player)
		local player_name = player and player:get_player_name() or ""
		if minetest.is_protected(pos, player_name) then return false end
		local inv = M(pos):get_inventory()
		local nvm = techage.get_nvm(pos)
		local liquid_empty = not nvm.liquid or (nvm.liquid.amount or 0) <= 0
		return inv:is_empty("src") and liquid_empty
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	after_place_node = after_place_node,
	after_dig_node = after_dig_node,
	on_punch = liquid.on_punch,
	on_receive_fields = on_receive_fields,
	on_timer = node_timer,
	on_rightclick = on_rightclick,
	on_rotate = screwdriver and screwdriver.disallow or nil,
	ta3_formspec = tool_config,
})

-- 2. Active Node (Glowing thermal core)
minetest.register_node("jumpdrive_tweaks:ice_melter_active", {
	description = S("Starship Thermal Ice Melter"),
	tiles = {
		"jumpdrive_ice_melter_top.png",
		"jumpdrive_ice_melter_side.png",
		"jumpdrive_ice_melter_right.png",
		"jumpdrive_ice_melter_left.png",
		"jumpdrive_ice_melter_side.png",
		"jumpdrive_ice_melter_front_active.png",
	},
	groups = {cracky = 1, jumpdrive_ship_part = 1, not_in_creative_inventory = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	light_source = 6,
	is_ground_content = false,
	diggable = false,
	sounds = default.node_sound_metal_defaults(),

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	on_receive_fields = on_receive_fields,
	on_punch = liquid.on_punch,
	on_timer = node_timer,
	on_rightclick = on_rightclick,
	on_rotate = screwdriver and screwdriver.disallow or nil,
	ta3_formspec = tool_config,
})

-- 3. Liquid Tank registration (Water Output on Right Face)
local liquid_def = {
	capa = CAPACITY,
	peek = function(pos)
		local nvm = techage.get_nvm(pos)
		return liquid.srv_peek(nvm)
	end,
	put = function(pos, indir, name, amount)
		-- Reject liquid input (this node only produces water from solid ice)
		return amount
	end,
	take = function(pos, indir, name, amount)
		local nvm = techage.get_nvm(pos)
		amount, name = liquid.srv_take(nvm, name, amount)
		if techage.is_activeformspec(pos) then
			M(pos):set_string("formspec", get_formspec(State, pos, nvm))
		end
		return amount, name
	end,
	untake = function(pos, indir, name, amount)
		if name ~= "techage:water" then
			return amount
		end
		local nvm = techage.get_nvm(pos)
		local leftover = liquid.srv_put(nvm, name, amount, CAPACITY)
		if techage.is_activeformspec(pos) then
			M(pos):set_string("formspec", get_formspec(State, pos, nvm))
		end
		return leftover
	end,
}

liquid.register_nodes({"jumpdrive_tweaks:ice_melter", "jumpdrive_tweaks:ice_melter_active"}, Pipe, "tank", {"R"}, liquid_def)
power.register_nodes({"jumpdrive_tweaks:ice_melter", "jumpdrive_tweaks:ice_melter_active"}, Cable, "con", {"L"})

-- 4. TechAge Hopper/Pusher item transport integration
techage.register_node({"jumpdrive_tweaks:ice_melter", "jumpdrive_tweaks:ice_melter_active"}, {
	on_inv_request = function(pos, in_dir, access_type)
		if access_type == "pull" then
			return nil
		end
		local meta = minetest.get_meta(pos)
		return meta:get_inventory(), "src"
	end,
	on_push_item = function(pos, in_dir, stack)
		if not ICE_CONVERSIONS[stack:get_name()] then
			return stack
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return techage.put_items(inv, "src", stack)
	end,
	on_pull_item = function(pos, in_dir, num, item_name)
		return ItemStack("")
	end,
	on_recv_message = function(pos, src, topic, payload)
		local nvm = techage.get_nvm(pos)
		if topic == "load" then
			return techage.power.percent(CAPACITY, (nvm.liquid and nvm.liquid.amount) or 0)
		elseif topic == "delivered" then
			return -math.floor((nvm.taken or 0) + 0.5)
		else
			return State:on_receive_message(pos, topic, payload)
		end
	end,
	on_node_load = function(pos, node)
		State:on_node_load(pos)
		local meta = M(pos)
		if not meta:contains("reduction") then
			meta:set_string("reduction", "100%")
			meta:set_string("turnoff", TURNOFF_THRESHOLD)
		end
		if meta:get_int("in_dir") == 0 then
			meta:set_int("in_dir", techage.side_to_outdir("L", node.param2))
		end
		if meta:get_int("out_dir") == 0 then
			meta:set_int("out_dir", techage.side_to_outdir("R", node.param2))
		end
	end,
})

