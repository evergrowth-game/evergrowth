-- spacesuit_tweaks/eva_thruster.lua
-- Handheld EVA Reaction Control System (RCS) Thruster with Client-Authoritative Physics

local S = minetest.get_translator("spacesuit_tweaks")

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
	description = S("EVA RCS Thruster Pack\nZero-g Maneuvering Unit\n[Hold Space]: Steady Vertical Ascent\n[Hold Shift]: Steady Vertical Descent\n[WASD]: Horizontal Vector Glide\n[Release Keys]: Stationary Zero-G Hover\n[Left-Click]: Instant Forward Boost Surge\nRequires Compressed Air or Hydrogen in inventory"),
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

-- Track player state
local player_states = {} -- playername -> {active = bool, last_gravity = num, last_speed = num}

-- Globalstep Physics Loop using Client-Authoritative Physics Overrides
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local ppos = player:get_pos()
		local pname = player:get_player_name()

		if not player_states[pname] then
			player_states[pname] = {active = false}
		end
		local st = player_states[pname]

		-- Only active in space / vacuum (Y >= 1000)
		if ppos and ppos.y >= 1000 then
			local wielded = player:get_wielded_item()
			local has_thruster = wielded:get_name() == "spacesuit_tweaks:eva_thruster"

			if has_thruster then
				st.active = true
				local ctrl = player:get_player_control()

				local target_gravity = 0.0
				local target_speed = 1.6
				local is_moving = false
				local particle_dir = {x = 0, y = 0, z = 0}

				if ctrl.jump then
					-- Inverted gravity to smoothly and cleanly climb upward on client
					target_gravity = -0.65
					is_moving = true
					particle_dir.y = 1
				elseif ctrl.sneak then
					-- Positive gravity for descent
					target_gravity = 0.65
					is_moving = true
					particle_dir.y = -1
				else
					-- Stable stationary zero-g hover
					target_gravity = 0.0
				end

				if ctrl.up or ctrl.down or ctrl.left or ctrl.right then
					is_moving = true
					target_speed = 2.0
					local yaw = player:get_look_horizontal()
					if ctrl.up then
						particle_dir.x = -math.sin(yaw)
						particle_dir.z = math.cos(yaw)
					elseif ctrl.down then
						particle_dir.x = math.sin(yaw)
						particle_dir.z = -math.cos(yaw)
					end
				end

				-- Apply physics override if changed
				if st.last_gravity ~= target_gravity or st.last_speed ~= target_speed then
					st.last_gravity = target_gravity
					st.last_speed = target_speed
					player:set_physics_override({
						gravity = target_gravity,
						speed = target_speed,
						jump = 1.0,
					})
				end

				-- Sound, particles, and fuel consumption when actively thrusting
				if is_moving then
					play_thruster_sound(pname, ppos)
					if vector.length(particle_dir) > 0 then
						spawn_rcs_particles(ppos, vector.normalize(particle_dir))
					end
					consume_propellant(player, wielded, 1)
					player:set_wielded_item(wielded)
				end
			else
				-- Restore space physics when not holding thruster
				if st.active then
					st.active = false
					st.last_gravity = 0.35
					st.last_speed = 1.0
					player:set_physics_override({
						gravity = 0.35,
						speed = 1.0,
						jump = 1.0,
					})
				end
			end
		else
			-- Restore normal planetary physics below space
			if st.active then
				st.active = false
				st.last_gravity = 1.0
				st.last_speed = 1.0
				player:set_physics_override({
					gravity = 1.0,
					speed = 1.0,
					jump = 1.0,
				})
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	player_states[player:get_player_name()] = nil
end)
