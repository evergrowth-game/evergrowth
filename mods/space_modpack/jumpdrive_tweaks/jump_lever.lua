-- jumpdrive_tweaks/jump_lever.lua
-- Tactile Quick-Jump Lever for rapid non-GUI starship translation

local S = minetest.get_translator("jumpdrive_tweaks")

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local function reset_lever(pos)
	local node = minetest.get_node(pos)
	if node.name == "jumpdrive_tweaks:jump_lever_on" then
		minetest.swap_node(pos, {name = "jumpdrive_tweaks:jump_lever", param2 = node.param2})
	end
end

local function trigger_jump_lever(pos, player)
	if not player or not player:is_player() then return end
	local playername = player:get_player_name()

	if minetest.is_protected(pos, playername) then
		minetest.chat_send_player(playername, "Jump lever is protected!")
		return
	end

	local engine_pos, err = jumpdrive_tweaks.find_connected_engine(pos)
	if not engine_pos then
		minetest.sound_play("techage_button", {pos = pos, gain = 0.7, max_hear_distance = 15})
		minetest.chat_send_player(playername, "[Jump Lever] " .. (err or "No Jump Core connected to ship backbone."))
		return
	end

	if minetest.is_protected(engine_pos, playername) then
		minetest.sound_play("techage_button", {pos = pos, gain = 0.7, max_hear_distance = 15})
		minetest.chat_send_player(playername, "[Jump Lever] Connected Jump Core is protected!")
		return
	end

	local node = minetest.get_node(pos)
	-- Engage the lever physically
	minetest.swap_node(pos, {name = "jumpdrive_tweaks:jump_lever_on", param2 = node.param2})
	local timer = minetest.get_node_timer(pos)
	if timer then timer:start(2.0) end

	-- Play tactile engagement sound
	minetest.sound_play("techage_button", {pos = pos, gain = 1.0, max_hear_distance = 25})

	-- Pre-calculate target translation delta BEFORE jump executes and wipes old metadata
	local target_pos = jumpdrive.get_meta_pos(engine_pos)
	local delta = vector.subtract(target_pos, engine_pos)

	-- Execute the jump
	local ok, res = jumpdrive.execute_jump(engine_pos, player)
	local is_emerging = not ok and type(res) == "string" and res:find("emergence initiated")

	if ok or is_emerging then
		if is_emerging then
			minetest.chat_send_player(playername, "[Navigation] " .. tostring(res))
		end
		-- Automatic reset after jump translation completes
		minetest.after(0.5, function()
			local new_pos = vector.add(pos, delta)
			local current_node = minetest.get_node(new_pos)
			if current_node.name == "jumpdrive_tweaks:jump_lever_on" then
				minetest.swap_node(new_pos, {name = "jumpdrive_tweaks:jump_lever", param2 = current_node.param2})
			else
				reset_lever(pos)
			end
		end)
	else
		-- Abort feedback: play warning tone and reset lever back immediately
		minetest.sound_play("techage_booster", {pos = pos, gain = 0.8, max_hear_distance = 30})
		minetest.chat_send_player(playername, "[Jump Aborted] " .. tostring(res))
		minetest.after(0.3, function()
			reset_lever(pos)
		end)
	end
end

-- 1. Disengaged State (Upright handle)
minetest.register_node("jumpdrive_tweaks:jump_lever", {
	description = S("Tactile Quick-Jump Lever"),
	drawtype = "mesh",
	mesh = "jumpdrive_jump_lever_off.obj",
	tiles = {
		"jumpdrive_jump_lever_base.png",
		"jumpdrive_jump_lever_handle.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {
		dig_immediate = 2,
		jumpdrive_ship_part = 1,
	},
	selection_box = { type = "fixed", fixed = {-0.25, -0.35, 0.12, 0.25, 0.48, 0.5} },
	collision_box = { type = "fixed", fixed = {-0.25, -0.35, 0.12, 0.25, 0.48, 0.5} },
	sounds = default.node_sound_metal_defaults(),

	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		trigger_jump_lever(pos, clicker)
		return itemstack
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher or not puncher:is_player() then return end
		local wielded = puncher:get_wielded_item()
		if wielded and not wielded:is_empty() then return end
		trigger_jump_lever(pos, puncher)
	end,
})

-- 2. Engaged State (Pulled forward handle)
minetest.register_node("jumpdrive_tweaks:jump_lever_on", {
	description = S("Tactile Quick-Jump Lever (Engaged)"),
	drawtype = "mesh",
	mesh = "jumpdrive_jump_lever_on.obj",
	tiles = {
		"jumpdrive_jump_lever_base.png",
		"jumpdrive_jump_lever_handle.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "jumpdrive_tweaks:jump_lever",
	is_ground_content = false,
	groups = {
		dig_immediate = 2,
		jumpdrive_ship_part = 1,
		not_in_creative_inventory = 1,
	},
	selection_box = { type = "fixed", fixed = {-0.25, -0.35, -0.22, 0.25, 0.35, 0.5} },
	collision_box = { type = "fixed", fixed = {-0.25, -0.35, -0.22, 0.25, 0.35, 0.5} },
	sounds = default.node_sound_metal_defaults(),

	on_timer = function(pos)
		reset_lever(pos)
		return false
	end,
})

minetest.log("action", "[jumpdrive_tweaks] Loaded Tactile Quick-Jump Lever.")
