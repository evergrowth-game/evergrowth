-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster for zero-gravity space maneuvering

local S = minetest.get_translator("spacesuit_tweaks")

-- Propellant Helper: drains small units from inventory air bottles or hydrogen canisters
local function consume_propellant(player, itemstack, amount)
	local inv = player:get_inventory()
	if not inv then return true end

	-- 1. Check for air bottles
	local air_list = inv:get_list("main")
	for i, stack in ipairs(air_list) do
		if stack:get_name() == "spacesuit:airbottle" then
			local wear = stack:get_wear() + (amount * 180)
			if wear >= 65535 then
				inv:set_stack("main", i, ItemStack(""))
			else
				stack:set_wear(wear)
				inv:set_stack("main", i, stack)
			end
			return true
		elseif stack:get_name():find("hydrogen") or stack:get_name():find("fuel_canister") then
			local wear = stack:get_wear() + (amount * 120)
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
		itemstack:add_wear(amount * 40)
		return true
	end

	return false
end

-- Sound throttling
local last_sound_time = {}

local function play_thruster_sound(playername, pos)
	local now = minetest.get_us_time()
	if not last_sound_time[playername] or (now - last_sound_time[playername]) > 300000 then
		last_sound_time[playername] = now
		minetest.sound_play("default_cool_lava", {
			pos = pos,
			gain = 0.4,
			pitch = 1.6,
			max_hear_distance = 20,
		})
	end
end

-- Particle emission for RCS gas puffs
local function spawn_rcs_particles(pos, dir)
	local pdir = vector.multiply(dir, -2.0)
	minetest.add_particlespawner({
		amount = 6,
		time = 0.05,
		minpos = vector.subtract(pos, {x = 0.2, y = 0.6, z = 0.2}),
		maxpos = vector.add(pos, {x = 0.2, y = 0.2, z = 0.2}),
		minvel = vector.subtract(pdir, {x = 0.5, y = 0.5, z = 0.5}),
		maxvel = vector.add(pdir, {x = 0.5, y = 0.5, z = 0.5}),
		minexptime = 0.1,
		maxexptime = 0.3,
		minsize = 0.8,
		maxsize = 1.8,
		texture = "smoke_puff.png^[colorize:#cceeff:120",
		glow = 5,
	})
end

-- Register EVA Thruster Tool
minetest.register_tool("spacesuit_tweaks:eva_thruster", {
	description = S("EVA RCS Thruster Pack\nZero-g Maneuvering Unit\n[Hold Space]: Ascent / Forward Propulsion\n[Hold Shift]: Descent / Inertial Retro-Brake\n[WASD]: Translation Bursts\n[Left-Click]: Instant Boost Surge\n[Right-Click]: Emergency Full-Stop Brake\nRequires Compressed Air or Hydrogen in inventory"),
	inventory_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	wield_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	stack_max = 1,
	groups = {tool = 1},

	-- Left-Click: Instant forward boost burst
	on_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return itemstack end
		local ppos = user:get_pos()
		local pname = user:get_player_name()

		if not ppos or ppos.y < 1000 then
			minetest.chat_send_player(pname, "EVA RCS Thrusters only operate in zero-gravity / orbital altitudes (Y >= 1000m).")
			return itemstack
		end

		local look_dir = user:get_look_dir()
		local boost_vel = vector.multiply(look_dir, 12.0)
		user:add_velocity(boost_vel)

		play_thruster_sound(pname, ppos)
		spawn_rcs_particles(ppos, look_dir)
		consume_propellant(user, itemstack, 5)
		return itemstack
	end,

	-- Right-Click on air: Emergency full-stop brake
	on_secondary_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return itemstack end
		local ppos = user:get_pos()
		if ppos and ppos.y >= 1000 then
			user:set_velocity({x = 0, y = 0, z = 0})
			play_thruster_sound(user:get_player_name(), ppos)
			spawn_rcs_particles(ppos, {x = 0, y = 1, z = 0})
			consume_propellant(user, itemstack, 3)
		end
		return itemstack
	end,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type == "nothing" or pointed_thing.type == "node" then
			if placer and placer:is_player() then
				local ppos = placer:get_pos()
				if ppos and ppos.y >= 1000 then
					placer:set_velocity({x = 0, y = 0, z = 0})
					play_thruster_sound(placer:get_player_name(), ppos)
					spawn_rcs_particles(ppos, {x = 0, y = 1, z = 0})
					consume_propellant(placer, itemstack, 3)
					return itemstack
				end
			end
		end
		return itemstack
	end,
})

-- Track players currently holding thruster to zero-out gravity
local active_eva_players = {}

local EVA_GRAV_MONOID = "spacesuit_tweaks_eva_gravity"

-- Globalstep Physics Loop for EVA Maneuvering
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local pname = player:get_player_name()

		-- Only active in space / vacuum (Y >= 1000)
		if ppos and ppos.y >= 1000 then
			local wielded = player:get_wielded_item()
			local has_thruster = wielded:get_name() == "spacesuit_tweaks:eva_thruster"

			if has_thruster then
				if not active_eva_players[pname] then
					active_eva_players[pname] = true
					if player_monoids and player_monoids.gravity then
						player_monoids.gravity:add_change(player, 0.0, EVA_GRAV_MONOID)
					else
						player:set_physics_override({gravity = 0.0})
					end
				end

				local ctrl = player:get_player_control()

				-- 1. Ascent / Forward Propulsion (Hold Space / Jump)
				if ctrl.jump then
					local look_dir = player:get_look_dir()
					-- Direct vertical upward thrust plus forward component
					local thrust = {
						x = look_dir.x * 12.0 * dtime,
						y = (math.max(look_dir.y, 0.6)) * 18.0 * dtime,
						z = look_dir.z * 12.0 * dtime
					}
					player:add_velocity(thrust)
					play_thruster_sound(pname, ppos)
					spawn_rcs_particles(ppos, {x = look_dir.x, y = 1, z = look_dir.z})
					consume_propellant(player, wielded, 2)
					player:set_wielded_item(wielded)

				-- 2. Descent / Retro-Braking (Hold Shift / Sneak)
				elseif ctrl.sneak then
					local vel = player:get_velocity() or {x = 0, y = 0, z = 0}
					-- Dampen horizontal velocity and apply steady downward descent
					local new_vx = vel.x * math.max(0, 1 - (4.0 * dtime))
					local new_vz = vel.z * math.max(0, 1 - (4.0 * dtime))
					local new_vy = math.max(-6.0, vel.y - (12.0 * dtime))
					player:set_velocity({x = new_vx, y = new_vy, z = new_vz})
					play_thruster_sound(pname, ppos)
					spawn_rcs_particles(ppos, {x = 0, y = -1, z = 0})
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
						local impulse = vector.multiply(norm_dir, 14.0 * dtime)
						player:add_velocity(impulse)
						play_thruster_sound(pname, ppos)
						spawn_rcs_particles(ppos, norm_dir)
						consume_propellant(player, wielded, 1)
						player:set_wielded_item(wielded)
					end
				end
			else
				if active_eva_players[pname] then
					active_eva_players[pname] = nil
					if player_monoids and player_monoids.gravity then
						player_monoids.gravity:del_change(player, EVA_GRAV_MONOID)
					else
						player:set_physics_override({gravity = 0.35})
					end
				end
			end
		else
			if active_eva_players[pname] then
				active_eva_players[pname] = nil
				if player_monoids and player_monoids.gravity then
					player_monoids.gravity:del_change(player, EVA_GRAV_MONOID)
				else
					player:set_physics_override({gravity = 1.0})
				end
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	active_eva_players[pname] = nil
	if player_monoids and player_monoids.gravity then
		player_monoids.gravity:del_change(player, EVA_GRAV_MONOID)
	end
end)
