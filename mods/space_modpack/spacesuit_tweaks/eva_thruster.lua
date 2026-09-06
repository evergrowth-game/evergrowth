-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster for zero-gravity space maneuvering

local S = minetest.get_translator("spacesuit_tweaks")

-- Register EVA Thruster Tool
minetest.register_tool("spacesuit_tweaks:eva_thruster", {
	description = S("EVA RCS Thruster Pack\nZero-g Maneuvering Unit\n[Space]: Forward / Ascent Thrust\n[Shift]: Retro-Brake Dampener\n[WASD]: Vector Translation\nRequires Compressed Air or Hydrogen in inventory"),
	inventory_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	wield_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	stack_max = 1,
	groups = {tool = 1},

	on_use = function(itemstack, user, pointed_thing)
		-- Quick manual burst forward
		if not user or not user:is_player() then return itemstack end
		local ppos = user:get_pos()
		if not ppos or ppos.y < 1000 then
			minetest.chat_send_player(user:get_player_name(), "EVA RCS Thrusters only operate in zero-gravity / orbital altitudes (Y >= 1000m).")
			return itemstack
		end
		return itemstack
	end,
})

-- Propellant Helper: drains small units from inventory air bottles or hydrogen canisters
local function consume_propellant(player, itemstack, amount)
	local inv = player:get_inventory()
	if not inv then return true end

	-- 1. Check for air bottles
	local air_list = inv:get_list("main")
	for i, stack in ipairs(air_list) do
		if stack:get_name() == "spacesuit:airbottle" then
			local wear = stack:get_wear() + (amount * 200)
			if wear >= 65535 then
				inv:set_stack("main", i, ItemStack(""))
			else
				stack:set_wear(wear)
				inv:set_stack("main", i, stack)
			end
			return true
		elseif stack:get_name():find("hydrogen") or stack:get_name():find("fuel_canister") then
			local wear = stack:get_wear() + (amount * 150)
			if wear >= 65535 then
				inv:set_stack("main", i, ItemStack(""))
			else
				stack:set_wear(wear)
				inv:set_stack("main", i, stack)
			end
			return true
		end
	end

	-- 2. Fallback: Emergency onboard reserve (wears the tool itself)
	if itemstack then
		itemstack:add_wear(amount * 50)
		return true
	end

	return false
end

-- Sound throttling
local last_sound_time = {}

local function play_thruster_sound(playername, pos)
	local now = minetest.get_us_time()
	if not last_sound_time[playername] or (now - last_sound_time[playername]) > 350000 then
		last_sound_time[playername] = now
		minetest.sound_play("default_cool_lava", {
			pos = pos,
			gain = 0.35,
			pitch = 1.6,
			max_hear_distance = 15,
		})
	end
end

-- Particle emission for RCS gas puffs
local function spawn_rcs_particles(pos, dir)
	local pdir = vector.multiply(dir, -1.5)
	minetest.add_particlespawner({
		amount = 4,
		time = 0.05,
		minpos = vector.subtract(pos, {x = 0.2, y = 0.5, z = 0.2}),
		maxpos = vector.add(pos, {x = 0.2, y = 0.2, z = 0.2}),
		minvel = vector.subtract(pdir, {x = 0.5, y = 0.5, z = 0.5}),
		maxvel = vector.add(pdir, {x = 0.5, y = 0.5, z = 0.5}),
		minexptime = 0.1,
		maxexptime = 0.3,
		minsize = 0.5,
		maxsize = 1.5,
		texture = "smoke_puff.png^[colorize:#cceeff:120",
		glow = 5,
	})
end

-- Globalstep Physics Loop for EVA Maneuvering
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()

		-- Only active in space / vacuum (Y >= 1000)
		if ppos and ppos.y >= 1000 then
			local wielded = player:get_wielded_item()
			local has_thruster = wielded:get_name() == "spacesuit_tweaks:eva_thruster"

			if has_thruster then
				local ctrl = player:get_player_control()
				local pname = player:get_player_name()

				-- 1. Retro-Braking Dampeners (Hold Shift / Sneak)
				if ctrl.sneak then
					local vel = player:get_velocity()
					if vel and (math.abs(vel.x) > 0.05 or math.abs(vel.y) > 0.05 or math.abs(vel.z) > 0.05) then
						local damp = math.max(0, 1 - (4.0 * dtime))
						local new_vel = vector.multiply(vel, damp)
						player:set_velocity(new_vel)
						play_thruster_sound(pname, ppos)
						spawn_rcs_particles(ppos, vector.normalize(vel))
						consume_propellant(player, wielded, 1)
						player:set_wielded_item(wielded)
					end

				-- 2. Forward / Upward Thrust (Space / Jump)
				elseif ctrl.jump then
					local look_dir = player:get_look_dir()
					local impulse = vector.multiply(look_dir, 14.0 * dtime)
					player:add_velocity(impulse)
					play_thruster_sound(pname, ppos)
					spawn_rcs_particles(ppos, look_dir)
					consume_propellant(player, wielded, 2)
					player:set_wielded_item(wielded)

				-- 3. Directional WASD Vector Translation
				elseif ctrl.up or ctrl.down or ctrl.left or ctrl.right then
					local yaw = player:get_look_horizontal()
					local fwd = {x = -math.sin(yaw), y = 0, z = math.cos(yaw)}
					local right = {x = math.cos(yaw), y = 0, z = math.sin(yaw)}

					local move_dir = {x = 0, y = 0, z = 0}
					if ctrl.up then move_dir = vector.add(move_dir, fwd) end
					if ctrl.down then move_dir = vector.subtract(move_dir, fwd) end
					if ctrl.right then move_dir = vector.add(move_dir, right) end
					if ctrl.left then move_dir = vector.subtract(move_dir, right) end

					if vector.length(move_dir) > 0 then
						local norm_dir = vector.normalize(move_dir)
						local impulse = vector.multiply(norm_dir, 10.0 * dtime)
						player:add_velocity(impulse)
						play_thruster_sound(pname, ppos)
						spawn_rcs_particles(ppos, norm_dir)
						consume_propellant(player, wielded, 1)
						player:set_wielded_item(wielded)
					end
				end
			end
		end
	end
end)
