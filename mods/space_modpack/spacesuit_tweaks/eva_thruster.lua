-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster with Flight Assist & Inertial Dampening

local S = minetest.get_translator("spacesuit_tweaks")

-- Propellant Helper: drains small units from inventory air bottles or hydrogen canisters
local function consume_propellant(player, itemstack, amount)
	local inv = player:get_inventory()
	if not inv then return true end

	-- 1. Check for air bottles
	local air_list = inv:get_list("main")
	for i, stack in ipairs(air_list) do
		if stack:get_name() == "spacesuit:airbottle" then
			local wear = stack:get_wear() + (amount * 120)
			if wear >= 65535 then
				inv:set_stack("main", i, ItemStack(""))
			else
				stack:set_wear(wear)
				inv:set_stack("main", i, stack)
			end
			return true
		elseif stack:get_name():find("hydrogen") or stack:get_name():find("fuel_canister") then
			local wear = stack:get_wear() + (amount * 80)
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
		itemstack:add_wear(amount * 25)
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
		minpos = vector.subtract(pos, {x = 0.2, y = 0.6, z = 0.2}),
		maxpos = vector.add(pos, {x = 0.2, y = 0.2, z = 0.2}),
		minvel = vector.subtract(pdir, {x = 0.4, y = 0.4, z = 0.4}),
		maxvel = vector.add(pdir, {x = 0.4, y = 0.4, z = 0.4}),
		minexptime = 0.1,
		maxexptime = 0.3,
		minsize = 0.6,
		maxsize = 1.4,
		texture = "smoke_puff.png^[colorize:#cceeff:120",
		glow = 5,
	})
end

-- Register EVA Thruster Tool
minetest.register_tool("spacesuit_tweaks:eva_thruster", {
	description = S("EVA RCS Thruster Pack\nZero-g Flight Maneuvering Unit\n[Hold Space]: Steady Ascent\n[Hold Shift]: Steady Descent\n[WASD]: Directional Flight\n[Release Keys]: Active Hover / Inertial Dampener\n[Left-Click]: Instant Boost Surge\nRequires Compressed Air or Hydrogen in inventory"),
	inventory_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	wield_image = "default_tool_steelpick.png^[colorize:#00ffff:90",
	stack_max = 1,
	groups = {tool = 1},

	-- Left-Click: Instant forward boost surge
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
		user:set_velocity(boost_vel)

		play_thruster_sound(pname, ppos)
		spawn_rcs_particles(ppos, look_dir)
		consume_propellant(user, itemstack, 4)
		return itemstack
	end,
})

-- Track players currently holding thruster to zero-out gravity
local active_eva_players = {}
local EVA_GRAV_MONOID = "spacesuit_tweaks_eva_gravity"

local CLIMB_SPEED = 6.5     -- m/s upward climb
local DESCENT_SPEED = 6.5   -- m/s downward descent
local HORIZ_SPEED = 8.0     -- m/s horizontal flight speed
local BRAKE_DAMPING = 5.0   -- speed of coming to complete stop when keys are released

-- Globalstep Physics Loop for EVA Maneuvering with Flight Assist
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local pname = player:get_player_name()

		-- Only active in space / vacuum (Y >= 1000)
		if ppos and ppos.y >= 1000 then
			local wielded = player:get_wielded_item()
			local has_thruster = wielded:get_name() == "spacesuit_tweaks:eva_thruster"

			if has_thruster then
				-- Zero-out passive world gravity while holding thruster
				if not active_eva_players[pname] then
					active_eva_players[pname] = true
					if player_monoids and player_monoids.gravity then
						player_monoids.gravity:add_change(player, 0.0, EVA_GRAV_MONOID)
					else
						player:set_physics_override({gravity = 0.0})
					end
				end

				local ctrl = player:get_player_control()
				local target_vx = 0
				local target_vy = 0
				local target_vz = 0
				local is_thrusting = false

				-- 1. Vertical axis control
				if ctrl.jump then
					target_vy = CLIMB_SPEED
					is_thrusting = true
				elseif ctrl.sneak then
					target_vy = -DESCENT_SPEED
					is_thrusting = true
				else
					target_vy = 0
				end

				-- 2. Horizontal axis control (WASD relative to view yaw)
				if ctrl.up or ctrl.down or ctrl.left or ctrl.right then
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
						target_vx = norm_dir.x * HORIZ_SPEED
						target_vz = norm_dir.z * HORIZ_SPEED
						is_thrusting = true
					end
				end

				-- 3. Compute smooth velocity transition with active inertial dampening
				local cur_vel = player:get_velocity() or {x = 0, y = 0, z = 0}
				local target_vel = {x = target_vx, y = target_vy, z = target_vz}

				-- Acceleration / Braking blending
				local blend = math.min(1.0, BRAKE_DAMPING * dtime)
				local new_vel = {
					x = cur_vel.x + (target_vel.x - cur_vel.x) * blend,
					y = cur_vel.y + (target_vel.y - cur_vel.y) * blend,
					z = cur_vel.z + (target_vel.z - cur_vel.z) * blend,
				}

				-- Snap to 0 if very small to prevent endless micro-drift
				if not is_thrusting then
					if math.abs(new_vel.x) < 0.1 then new_vel.x = 0 end
					if math.abs(new_vel.y) < 0.1 then new_vel.y = 0 end
					if math.abs(new_vel.z) < 0.1 then new_vel.z = 0 end
				end

				player:set_velocity(new_vel)

				-- Audio, particles, and fuel drain when actively holding keys
				if is_thrusting then
					play_thruster_sound(pname, ppos)
					local thrust_dir = vector.normalize(target_vel)
					if vector.length(thrust_dir) > 0 then
						spawn_rcs_particles(ppos, thrust_dir)
					end
					consume_propellant(player, wielded, 1)
					player:set_wielded_item(wielded)
				end
			else
				-- Restoring normal space gravity when thruster is not wielded
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
