-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster with player_monoids Dynamic Vectoring

local S = minetest.get_translator("spacesuit_tweaks")

local MONOID_SPEED = "spacesuit_tweaks_eva_speed"
local MONOID_GRAVITY = "spacesuit_tweaks_eva_gravity"

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

-- Sound and control state tracking
local player_sound_handles = {} -- pname -> sound_handle
local last_warn_time = {}
local prev_player_controls = {} -- pname -> table of keys {jump, sneak, up, down, left, right}

local function start_thruster_sound(player)
	local pname = player:get_player_name()
	if not player_sound_handles[pname] then
		local handle = minetest.sound_play("spacesuit_eva_thruster_loop", {
			object = player,
			gain = 0.15,
			pitch = 1.0,
			loop = true,
			max_hear_distance = 12,
		})
		player_sound_handles[pname] = handle or true
	end
end

local function stop_thruster_sound(playername)
	if player_sound_handles[playername] then
		if type(player_sound_handles[playername]) ~= "boolean" then
			minetest.sound_stop(player_sound_handles[playername])
		end
		player_sound_handles[playername] = nil
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

		local look_dir = user:get_look_dir()
		local boost_vel = vector.multiply(look_dir, 14.0)
		user:add_velocity(boost_vel)

		minetest.sound_play("default_cool_lava", {
			pos = ppos,
			gain = 0.25,
			pitch = 1.8,
			max_hear_distance = 12,
		})
		spawn_rcs_particles(ppos, look_dir)
		return itemstack
	end,

	-- Right-Click / Secondary Use: Refuel propellant tank from inventory
	on_place = function(itemstack, placer, pointed_thing)
		if not placer or not placer:is_player() then return itemstack end
		if itemstack:get_wear() == 0 then
			minetest.chat_send_player(placer:get_player_name(), "[EVA Thruster] Propellant tank is already full (100%).")
			return itemstack
		end
		try_refuel_from_inv(placer, itemstack, true)
		return itemstack
	end,

	on_secondary_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then return itemstack end
		if itemstack:get_wear() == 0 then
			minetest.chat_send_player(user:get_player_name(), "[EVA Thruster] Propellant tank is already full (100%).")
			return itemstack
		end
		try_refuel_from_inv(user, itemstack, true)
		return itemstack
	end,
})

-- Player thruster tracking state
local player_thrust_state = {} -- pname -> "up" | "down" | "neutral" | nil
local player_speed_active = {}

local function cleanup_player(player)
	local pname = player:get_player_name()
	stop_thruster_sound(pname)
	if prev_player_controls[pname] then
		prev_player_controls[pname] = nil
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

-- Globalstep Loop for handheld dynamic thrust vectoring
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
					local prev = prev_player_controls[pname] or {}

					-- Detect 0 -> 1 keypress transitions
					local new_press = (ctrl.jump and not prev.jump) or
						(ctrl.sneak and not prev.sneak) or
						(ctrl.up and not prev.up) or
						(ctrl.down and not prev.down) or
						(ctrl.left and not prev.left) or
						(ctrl.right and not prev.right)

					local is_moving = ctrl.jump or ctrl.sneak or ctrl.up or ctrl.down or ctrl.left or ctrl.right

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
								-- Controlled upward acceleration (counteracts descent / climbs)
								player_monoids.gravity:add_change(player, -1.2, MONOID_GRAVITY)
							elseif target_state == "down" then
								-- Gentle controlled downward descent (safe landing, no hard slams)
								player_monoids.gravity:add_change(player, 0.7, MONOID_GRAVITY)
							else
								-- Neutral: restore base low space gravity
								player_monoids.gravity:del_change(player, MONOID_GRAVITY)
							end
						end
					end

					-- Audio, particles, and propellant consumption
					if is_moving then
						start_thruster_sound(player)

						local should_trigger = new_press or step_effects
						if should_trigger then
							local particle_dir = {x = 0, y = 0, z = 0}
							local yaw = player:get_look_horizontal()

							if ctrl.jump then
								particle_dir.y = particle_dir.y + 1
							end
							if ctrl.sneak then
								particle_dir.y = particle_dir.y - 1
							end

							if ctrl.up then
								particle_dir.x = particle_dir.x - math.sin(yaw)
								particle_dir.z = particle_dir.z + math.cos(yaw)
							elseif ctrl.down then
								particle_dir.x = particle_dir.x + math.sin(yaw)
								particle_dir.z = particle_dir.z - math.cos(yaw)
							end

							if ctrl.left then
								particle_dir.x = particle_dir.x - math.cos(yaw)
								particle_dir.z = particle_dir.z - math.sin(yaw)
							elseif ctrl.right then
								particle_dir.x = particle_dir.x + math.cos(yaw)
								particle_dir.z = particle_dir.z + math.sin(yaw)
							end

							if vector.length(particle_dir) > 0 then
								spawn_rcs_particles(ppos, vector.normalize(particle_dir))
							end
							if step_effects or new_press then
								consume_propellant(player, wielded, 1)
								player:set_wielded_item(wielded)
							end
						end
					else
						stop_thruster_sound(pname)
					end

					-- Save current control state for transition detection
					prev_player_controls[pname] = {
						jump = ctrl.jump,
						sneak = ctrl.sneak,
						up = ctrl.up,
						down = ctrl.down,
						left = ctrl.left,
						right = ctrl.right,
					}
				else
					cleanup_player(player)
				end
			else
				cleanup_player(player)
			end
		else
			cleanup_player(player)
		end
	end
end)

-- Prevent fatal zero-g fall damage impact in orbit (Y >= 1000m)
if minetest.register_on_player_hpchange then
	minetest.register_on_player_hpchange(function(player, hp_change, reason)
		if hp_change < 0 and reason and reason.type == "fall" then
			local pos = player:get_pos()
			if pos and pos.y >= 1000 then
				return 0
			end
		end
		return hp_change
	end, true)
end

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	cleanup_player(player)
	last_warn_time[pname] = nil
end)
