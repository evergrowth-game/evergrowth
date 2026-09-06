-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster with player_monoids 6-DOF Zero-G Flight

local S = minetest.get_translator("spacesuit_tweaks")

local MONOID_FLY = "spacesuit_tweaks_eva_fly"
local MONOID_SPEED = "spacesuit_tweaks_eva_speed"
local MONOID_GRAVITY = "spacesuit_tweaks_eva_gravity"

-- Propellant Helper: drains small units from inventory air bottles or hydrogen canisters
local function consume_propellant(player, itemstack, amount)
	local inv = player:get_inventory()
	if not inv then return true end

	-- 1. Check for air bottles
	local air_list = inv:get_list("main")
	for i, stack in ipairs(air_list) do
		if stack:get_name() == "spacesuit:airbottle" then
			local wear = stack:get_wear() + (amount * 100)
			if wear >= 65535 then
				inv:set_stack("main", i, ItemStack(""))
			else
				stack:set_wear(wear)
				inv:set_stack("main", i, stack)
			end
			return true
		elseif stack:get_name():find("hydrogen") or stack:get_name():find("fuel_canister") then
			local wear = stack:get_wear() + (amount * 70)
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
		itemstack:add_wear(amount * 20)
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
	description = S("EVA RCS Thruster Pack\nZero-g Maneuvering Unit\n[Hold Space]: Steady Vertical Ascent\n[Hold Shift]: Steady Vertical Descent\n[WASD]: 3D Vector Translation\n[Release Keys]: Inertial Dampening / Stationary Hover\n[Left-Click]: Instant Forward Boost Surge\nRequires Compressed Air or Hydrogen in inventory"),
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
		local boost_vel = vector.multiply(look_dir, 14.0)
		user:add_velocity(boost_vel)

		play_thruster_sound(pname, ppos)
		spawn_rcs_particles(ppos, look_dir)
		consume_propellant(user, itemstack, 4)
		return itemstack
	end,
})

-- Player flight tracking state
local active_eva_players = {}

local function enable_eva_flight(player)
	local pname = player:get_player_name()
	if active_eva_players[pname] then return end
	active_eva_players[pname] = true

	if player_monoids then
		if player_monoids.fly then
			player_monoids.fly:add_change(player, true, MONOID_FLY)
		end
		if player_monoids.speed then
			player_monoids.speed:add_change(player, 1.4, MONOID_SPEED)
		end
		if player_monoids.gravity then
			player_monoids.gravity:add_change(player, 0, MONOID_GRAVITY)
		end
	else
		player:set_physics_override({
			gravity = 0.0,
			speed = 1.4,
		})
	end
end

local function disable_eva_flight(player)
	local pname = player:get_player_name()
	if not active_eva_players[pname] then return end
	active_eva_players[pname] = nil

	if player_monoids then
		if player_monoids.fly then
			player_monoids.fly:del_change(player, MONOID_FLY)
		end
		if player_monoids.speed then
			player_monoids.speed:del_change(player, MONOID_SPEED)
		end
		if player_monoids.gravity then
			player_monoids.gravity:del_change(player, MONOID_GRAVITY)
		end
	else
		player:set_physics_override({
			gravity = 1.0,
			speed = 1.0,
		})
	end
end

-- Globalstep Loop for propellant consumption, effects, and flight mode management
local effect_timer = 0
minetest.register_globalstep(function(dtime)
	effect_timer = effect_timer + dtime
	local step_effects = (effect_timer >= 0.1)
	if step_effects then
		effect_timer = 0
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local pname = player:get_player_name()

		if ppos and ppos.y >= 1000 then
			local wielded = player:get_wielded_item()
			if wielded:get_name() == "spacesuit_tweaks:eva_thruster" then
				enable_eva_flight(player)

				if step_effects then
					local ctrl = player:get_player_control()
					local is_moving = ctrl.jump or ctrl.sneak or ctrl.up or ctrl.down or ctrl.left or ctrl.right

					if is_moving then
						local particle_dir = {x = 0, y = 0, z = 0}
						local yaw = player:get_look_horizontal()

						if ctrl.jump then
							particle_dir.y = 1
						elseif ctrl.sneak then
							particle_dir.y = -1
						end

						if ctrl.up then
							particle_dir.x = -math.sin(yaw)
							particle_dir.z = math.cos(yaw)
						elseif ctrl.down then
							particle_dir.x = math.sin(yaw)
							particle_dir.z = -math.cos(yaw)
						end

						play_thruster_sound(pname, ppos)
						if vector.length(particle_dir) > 0 then
							spawn_rcs_particles(ppos, vector.normalize(particle_dir))
						end
						consume_propellant(player, wielded, 1)
						player:set_wielded_item(wielded)
					end
				end
			else
				disable_eva_flight(player)
			end
		else
			disable_eva_flight(player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	disable_eva_flight(player)
	last_sound_time[player:get_player_name()] = nil
end)
