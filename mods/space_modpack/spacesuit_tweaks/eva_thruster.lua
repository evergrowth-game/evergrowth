-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster with player_monoids Dynamic Gravity Vectoring
-- and Hands-Free Inertial Station-Keeping for Spacewalk Construction

local S = minetest.get_translator("spacesuit_tweaks")

local MONOID_SPEED = "spacesuit_tweaks_eva_speed"
local MONOID_GRAVITY = "spacesuit_tweaks_eva_gravity"
local MONOID_LOCK_GRAVITY = "spacesuit_tweaks_station_lock_gravity"
local MONOID_LOCK_SPEED = "spacesuit_tweaks_station_lock_speed"
local MONOID_LOCK_JUMP = "spacesuit_tweaks_station_lock_jump"

-- Propellant definition registry (Compressed Air Only)
spacesuit_tweaks = spacesuit_tweaks or {}
spacesuit_tweaks.PROPELLANTS = {
	-- Vacuum Air Bottles
	["vacuum:air_bottle"] = {
		empty = "vessels:steel_bottle",
		label = "Compressed Air Bottle",
	},
	-- Airtanks
	["airtanks:steel_tank"] = {
		is_tank = true,
		empty = "airtanks:empty_steel_tank",
		label = "Steel Air Tank",
	},
	["airtanks:steel_tank_2"] = {
		is_tank = true,
		empty = "airtanks:empty_steel_tank_2",
		label = "Twin Steel Air Tank",
	},
	["airtanks:steel_tank_3"] = {
		is_tank = true,
		empty = "airtanks:empty_steel_tank_3",
		label = "Triple Steel Air Tank",
	},
	["airtanks:carbon_tank"] = {
		is_tank = true,
		empty = "airtanks:empty_carbon_tank",
		label = "Carbon Air Tank",
	},
	["airtanks:carbon_tank_2"] = {
		is_tank = true,
		empty = "airtanks:empty_carbon_tank_2",
		label = "Twin Carbon Air Tank",
	},
	["airtanks:carbon_tank_3"] = {
		is_tank = true,
		empty = "airtanks:empty_carbon_tank_3",
		label = "Triple Carbon Air Tank",
	},
	["airtanks:bronze_tank"] = {
		is_tank = true,
		empty = "airtanks:empty_bronze_tank",
		label = "Bronze Air Tank",
	},
	["airtanks:bronze_tank_2"] = {
		is_tank = true,
		empty = "airtanks:empty_bronze_tank_2",
		label = "Twin Bronze Air Tank",
	},
	["airtanks:bronze_tank_3"] = {
		is_tank = true,
		empty = "airtanks:empty_bronze_tank_3",
		label = "Triple Bronze Air Tank",
	},
}

-- Station-keeping tracking state: pname -> locked_pos vector
local player_station_lock = {}
spacesuit_tweaks.player_station_lock = player_station_lock

-- Sound throttling
local last_sound_time = {}
local last_warn_time = {}

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

local function play_refuel_sound(pos)
	minetest.sound_play("default_cool_lava", {
		pos = pos,
		gain = 0.5,
		pitch = 1.1,
		max_hear_distance = 15,
	})
end

local function play_lock_sound(pos)
	minetest.sound_play("default_cool_lava", {
		pos = pos,
		gain = 0.45,
		pitch = 1.8,
		max_hear_distance = 10,
	})
end

local function play_unlock_sound(pos)
	minetest.sound_play("default_cool_lava", {
		pos = pos,
		gain = 0.3,
		pitch = 1.3,
		max_hear_distance = 10,
	})
end

local function warn_depleted(pname)
	local now = minetest.get_us_time()
	if not last_warn_time[pname] or (now - last_warn_time[pname]) > 4000000 then
		last_warn_time[pname] = now
		minetest.chat_send_player(pname, "[EVA Thruster] Propellant depleted! Right-click or craft with an Air Bottle or Air Tank to refuel.")
	end
end

-- Refuel helper: drains 1 propellant item from inventory and restores thruster wear to 0
local function try_refuel_from_inv(player, itemstack, manual)
	local inv = player:get_inventory()
	if not inv then return false end

	for i = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		if stack and not stack:is_empty() then
			local sname = stack:get_name()
			local pinfo = spacesuit_tweaks.PROPELLANTS[sname]

			if pinfo then
				local pname = player:get_player_name()
				local pos = player:get_pos()
				if pinfo.is_tank then
					-- Airtanks tool: check if tank has air left (wear < 65000)
					if stack:get_wear() < 65000 then
						stack:set_wear(65535)
						if pinfo.empty and minetest.registered_items[pinfo.empty] then
							inv:set_stack("main", i, ItemStack(pinfo.empty))
						else
							inv:set_stack("main", i, ItemStack(""))
						end
						itemstack:set_wear(0)
						if pos then play_refuel_sound(pos) end
						minetest.chat_send_player(pname, "[EVA Thruster] Refueled to 100% capacity using " .. (pinfo.label or sname) .. ".")
						return true
					end
				else
					-- Craftitem container (Air bottle)
					stack:take_item(1)
					inv:set_stack("main", i, stack)
					if pinfo.empty and minetest.registered_items[pinfo.empty] then
						local leftover = inv:add_item("main", ItemStack(pinfo.empty))
						if leftover and not leftover:is_empty() and pos then
							minetest.add_item(pos, leftover)
						end
					end
					itemstack:set_wear(0)
					if pos then play_refuel_sound(pos) end
					minetest.chat_send_player(pname, "[EVA Thruster] Refueled to 100% capacity using " .. (pinfo.label or sname) .. ".")
					return true
				end
			end
		end
	end

	if manual then
		local pname = player:get_player_name()
		minetest.chat_send_player(pname, "[EVA Thruster] No propellant found in inventory. (Requires Air Bottle or Air Tank).")
	end
	return false
end

-- Propellant Helper: drains small units from thruster wear; auto-refuels from inventory when depleted
local function consume_propellant(player, itemstack, amount)
	if not itemstack then return false end
	local cur_wear = itemstack:get_wear()
	local new_wear = cur_wear + (amount * 35)

	if new_wear >= 65534 then
		-- Try auto-refueling from inventory
		local refueled = try_refuel_from_inv(player, itemstack, false)
		if refueled then
			return true
		end
		-- Depleted and no fuel in inventory: clamp wear at 65534 so item is never destroyed
		itemstack:set_wear(65534)
		warn_depleted(player:get_player_name())
		return false
	else
		itemstack:set_wear(new_wear)
		return true
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

-- Refuel & Station-Keeping Action Handler
local function handle_thruster_action(itemstack, user)
	if not user or not user:is_player() then return itemstack end
	local pname = user:get_player_name()
	local ppos = user:get_pos()
	local ctrl = user:get_player_control()

	if ctrl and ctrl.sneak then
		-- Sneak + Right-Click: Toggle Inertial Station-Keeping Lock
		if not ppos or ppos.y < 1000 then
			minetest.chat_send_player(pname, "[EVA Thruster] Inertial Station-Keeping only operates in zero-gravity orbital space (Y >= 1000m).")
			return itemstack
		end

		if player_station_lock[pname] then
			-- Disengage Station-Keeping Lock
			player_station_lock[pname] = nil
			if player_monoids then
				if player_monoids.gravity then
					player_monoids.gravity:del_change(user, MONOID_LOCK_GRAVITY)
				end
				if player_monoids.speed then
					player_monoids.speed:del_change(user, MONOID_LOCK_SPEED)
				end
				if player_monoids.jump then
					player_monoids.jump:del_change(user, MONOID_LOCK_JUMP)
				end
			end
			play_unlock_sound(ppos)
			minetest.chat_send_player(pname, "[EVA Thruster] Inertial Station-Keeping: DISENGAGED. (Free-float active)")
		else
			-- Engage Station-Keeping Lock (snap velocity and lock coordinates)
			player_station_lock[pname] = {x = ppos.x, y = ppos.y, z = ppos.z}
			local v = user:get_velocity()
			if v then
				user:add_velocity({x = -v.x, y = -v.y, z = -v.z})
			end
			user:set_velocity({x = 0, y = 0, z = 0})
			user:set_pos(ppos)
			if player_monoids then
				if player_monoids.gravity then
					player_monoids.gravity:add_change(user, 0, MONOID_LOCK_GRAVITY)
				end
				if player_monoids.speed then
					player_monoids.speed:add_change(user, 0, MONOID_LOCK_SPEED)
				end
				if player_monoids.jump then
					player_monoids.jump:add_change(user, 0, MONOID_LOCK_JUMP)
				end
			end
			play_lock_sound(ppos)
			minetest.chat_send_player(pname, "[EVA Thruster] Inertial Station-Keeping: LOCKED. (Stationary anchor active)")
		end
		return itemstack
	else
		-- Standard Right-Click: Refuel propellant tank from inventory
		if itemstack:get_wear() == 0 then
			minetest.chat_send_player(pname, "[EVA Thruster] Propellant tank is already full (100%).")
			return itemstack
		end
		try_refuel_from_inv(user, itemstack, true)
		return itemstack
	end
end

-- Register EVA Thruster Tool
minetest.register_tool("spacesuit_tweaks:eva_thruster", {
	description = S("EVA RCS Thruster Pack"),
	inventory_image = "spacesuit_eva_thruster.png",
	wield_image = "spacesuit_eva_thruster.png",
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

		if not consume_propellant(user, itemstack, 6) then
			return itemstack
		end

		-- Disengage station lock if boosting
		if player_station_lock[pname] then
			player_station_lock[pname] = nil
			if player_monoids then
				if player_monoids.gravity then
					player_monoids.gravity:del_change(user, MONOID_LOCK_GRAVITY)
				end
				if player_monoids.speed then
					player_monoids.speed:del_change(user, MONOID_LOCK_SPEED)
				end
				if player_monoids.jump then
					player_monoids.jump:del_change(user, MONOID_LOCK_JUMP)
				end
			end
		end

		local look_dir = user:get_look_dir()
		local boost_vel = vector.multiply(look_dir, 14.0)
		user:add_velocity(boost_vel)

		play_thruster_sound(pname, ppos)
		spawn_rcs_particles(ppos, look_dir)
		return itemstack
	end,

	-- Right-Click: Refuel (Sneak + Right-Click: Toggle Station-Keeping Lock)
	on_place = function(itemstack, placer, pointed_thing)
		return handle_thruster_action(itemstack, placer)
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		return handle_thruster_action(itemstack, user)
	end,
})

-- Player thruster tracking state
local player_thrust_state = {} -- pname -> "up" | "down" | "neutral" | nil
local player_speed_active = {}

local function cleanup_player(player)
	local pname = player:get_player_name()
	if player_station_lock[pname] then
		player_station_lock[pname] = nil
		if player_monoids then
			if player_monoids.gravity then
				player_monoids.gravity:del_change(player, MONOID_LOCK_GRAVITY)
			end
			if player_monoids.speed then
				player_monoids.speed:del_change(player, MONOID_LOCK_SPEED)
			end
			if player_monoids.jump then
				player_monoids.jump:del_change(player, MONOID_LOCK_JUMP)
			end
		end
	end
	if player_thrust_state[pname] then
		player_thrust_state[pname] = nil
		if player_monoids and player_monoids.gravity then
			player_monoids.gravity:del_change(player, MONOID_GRAVITY)
		end
	end
	if player_speed_active[pname] then
		player_speed_active[pname] = nil
		if player_monoids and player_monoids.speed then
			player_monoids.speed:del_change(player, MONOID_SPEED)
		end
	end
end

-- Globalstep Loop for station-keeping lock and dynamic thrust vectoring
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
			-- 1. Hands-free Station-Keeping Lock Handler (active regardless of wielded item)
			if player_station_lock[pname] then
				local lock_pos = player_station_lock[pname]
				-- Maintain zero-physics overrides to prevent all drift and client momentum
				if player_monoids then
					if player_monoids.gravity then
						player_monoids.gravity:add_change(player, 0, MONOID_LOCK_GRAVITY)
					end
					if player_monoids.speed then
						player_monoids.speed:add_change(player, 0, MONOID_LOCK_SPEED)
					end
					if player_monoids.jump then
						player_monoids.jump:add_change(player, 0, MONOID_LOCK_JUMP)
					end
				end

				local vel = player:get_velocity()
				if vel and (math.abs(vel.x) > 0.001 or math.abs(vel.y) > 0.001 or math.abs(vel.z) > 0.001) then
					player:add_velocity({x = -vel.x, y = -vel.y, z = -vel.z})
					player:set_velocity({x = 0, y = 0, z = 0})
				end
				local dist = vector.distance and vector.distance(ppos, lock_pos) or vector.length(vector.subtract(ppos, lock_pos))
				if dist > 0.02 then
					player:set_pos(lock_pos)
				end
			end

			-- 2. Handheld EVA Thruster Dynamic Vectoring
			local wielded = player:get_wielded_item()
			if wielded:get_name() == "spacesuit_tweaks:eva_thruster" and not player_station_lock[pname] then
				local has_propellant = (wielded:get_wear() < 65534)
				if not has_propellant then
					-- Check if auto-refuel is possible before shutting off thrust
					has_propellant = try_refuel_from_inv(player, wielded, false)
					if has_propellant then
						player:set_wielded_item(wielded)
					end
				end

				if has_propellant then
					-- Enable speed multiplier for space maneuvering
					if not player_speed_active[pname] then
						player_speed_active[pname] = true
						if player_monoids and player_monoids.speed then
							player_monoids.speed:add_change(player, 1.6, MONOID_SPEED)
						end
					end

					local ctrl = player:get_player_control()
					local target_state = "neutral"

					if ctrl.jump then
						target_state = "up"
					elseif ctrl.sneak then
						target_state = "down"
					end

					-- Update gravity monoid if thrust state changed
					if player_thrust_state[pname] ~= target_state then
						player_thrust_state[pname] = target_state
						if player_monoids and player_monoids.gravity then
							if target_state == "up" then
								-- Invert gravity to produce upward acceleration (decelerating fall and climbing)
								player_monoids.gravity:add_change(player, -3.5, MONOID_GRAVITY)
							elseif target_state == "down" then
								-- Increase downward gravity for rapid descent
								player_monoids.gravity:add_change(player, 3.0, MONOID_GRAVITY)
							else
								-- Neutral: restore base low space gravity
								player_monoids.gravity:del_change(player, MONOID_GRAVITY)
							end
						end
					end

					-- Audio, particles, and propellant consumption
					if step_effects then
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
					if player_thrust_state[pname] then
						player_thrust_state[pname] = nil
						if player_monoids and player_monoids.gravity then
							player_monoids.gravity:del_change(player, MONOID_GRAVITY)
						end
					end
					if player_speed_active[pname] then
						player_speed_active[pname] = nil
						if player_monoids and player_monoids.speed then
							player_monoids.speed:del_change(player, MONOID_SPEED)
						end
					end
				end
			else
				-- Wielding other item: keep station-keeping lock if active, clean up thruster-only speed/vectoring
				if player_thrust_state[pname] then
					player_thrust_state[pname] = nil
					if player_monoids and player_monoids.gravity and not player_station_lock[pname] then
						player_monoids.gravity:del_change(player, MONOID_GRAVITY)
					end
				end
				if player_speed_active[pname] then
					player_speed_active[pname] = nil
					if player_monoids and player_monoids.speed and not player_station_lock[pname] then
						player_monoids.speed:del_change(player, MONOID_SPEED)
					end
				end
			end
		else
			cleanup_player(player)
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	cleanup_player(player)
	last_sound_time[player:get_player_name()] = nil
	last_warn_time[player:get_player_name()] = nil
end)
