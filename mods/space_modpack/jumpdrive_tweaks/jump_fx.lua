-- jumpdrive_tweaks/jump_fx.lua
-- Audiovisual and physical feedback system for hyperjumps

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

-- Calculate distance-scaled spool duration
function jumpdrive_tweaks.get_spool_duration(distance)
	if not distance or distance <= 1000 then
		return 0.8
	elseif distance <= 5000 then
		return 1.2
	else
		return 1.5
	end
end

-- Get all connected players within ship bounding volume
function jumpdrive_tweaks.get_ship_passengers(min_pos, max_pos)
	local passengers = {}
	if not min_pos or not min_pos.x or not min_pos.y or not min_pos.z
	   or not max_pos or not max_pos.x or not max_pos.y or not max_pos.z
	   or not minetest.get_connected_players then
		return passengers
	end

	for _, player in ipairs(minetest.get_connected_players()) do
		if player:is_player() then
			local ppos = player:get_pos()
			if ppos and ppos.x >= (min_pos.x - 1.5) and ppos.x <= (max_pos.x + 1.5)
			   and ppos.y >= (min_pos.y - 1.5) and ppos.y <= (max_pos.y + 1.5)
			   and ppos.z >= (min_pos.z - 1.5) and ppos.z <= (max_pos.z + 1.5) then
				table.insert(passengers, player)
			end
		end
	end
	return passengers
end

-- Start pre-jump spool audio and ambient HUD glow on passengers
function jumpdrive_tweaks.start_spool_fx(source_pos, distance, ship_scan)
	if not ship_scan or not ship_scan.min_pos or not ship_scan.min_pos.x
	   or not ship_scan.max_pos or not ship_scan.max_pos.x then
		return nil
	end

	local spool_time = jumpdrive_tweaks.get_spool_duration(distance)
	local fx_handle = {
		sound_handles = {},
		hud_entries = {},
		spool_time = spool_time,
		active = true,
	}

	-- Play rising spool audio positionally for external observers
	if minetest.sound_play then
		local ext_h = minetest.sound_play("jumpdrive_spool", {
			pos = source_pos,
			max_hear_distance = 60,
			gain = 0.60,
		})
		if ext_h then table.insert(fx_handle.sound_handles, ext_h) end
	end

	-- Apply ambient screen glow HUD and direct audio to passengers
	local passengers = jumpdrive_tweaks.get_ship_passengers(ship_scan.min_pos, ship_scan.max_pos)
	for _, player in ipairs(passengers) do
		local pname = player:get_player_name()
		if pname then
			if player.hud_add then
				local hud_id = player:hud_add({
					hud_elem_type = "image",
					position = {x = 0.5, y = 0.5},
					scale = {x = -100, y = -100},
					text = "jumpdrive_warp_glow.png",
					alignment = {x = 0, y = 0},
					offset = {x = 0, y = 0},
				})
				table.insert(fx_handle.hud_entries, {player_name = pname, hud_id = hud_id})
			end
			if minetest.sound_play then
				local p_h = minetest.sound_play("jumpdrive_spool", {
					to_player = pname,
					gain = 0.80,
				})
				if p_h then table.insert(fx_handle.sound_handles, p_h) end
			end
		end
	end

	return fx_handle
end

-- Cancel and clean up spool FX if a jump is aborted
function jumpdrive_tweaks.abort_spool_fx(fx_handle)
	if not fx_handle or not fx_handle.active then return end
	fx_handle.active = false

	if minetest.sound_stop and fx_handle.sound_handles then
		for _, sh in ipairs(fx_handle.sound_handles) do
			minetest.sound_stop(sh)
		end
		fx_handle.sound_handles = {}
	end

	for _, entry in ipairs(fx_handle.hud_entries) do
		local player = minetest.get_player_by_name and minetest.get_player_by_name(entry.player_name)
		if player and player:is_player() and player.hud_remove then
			player:hud_remove(entry.hud_id)
		end
	end
	fx_handle.hud_entries = {}
end

-- Spawn planar expanding shockwave ring strictly OUTSIDE the ship hull
function jumpdrive_tweaks.spawn_external_shockwave(center, min_pos, max_pos)
	if not minetest.add_particle or not center or not center.x or not center.y or not center.z
	   or not min_pos or not min_pos.x or not min_pos.z
	   or not max_pos or not max_pos.x or not max_pos.z then
		return
	end

	local dx = math.max(1, (max_pos.x - min_pos.x) / 2)
	local dz = math.max(1, (max_pos.z - min_pos.z) / 2)
	local r = math.max(dx, dz) + 2.5
	local cy = center.y

	local count = 48
	for i = 1, count do
		local angle = (i / count) * 2 * math.pi
		local rx = math.cos(angle)
		local rz = math.sin(angle)
		local px = center.x + rx * r
		local pz = center.z + rz * r
		local speed = 8.0

		minetest.add_particle({
			pos = {x = px, y = cy, z = pz},
			velocity = {x = rx * speed, y = 0, z = rz * speed},
			acceleration = {x = -rx * speed * 0.4, y = 0, z = -rz * speed * 0.4},
			expirationtime = 1.2,
			size = 4.0,
			texture = "jumpdrive_warp_particle.png",
			glow = 14,
		})
	end
end

-- Trigger discontinuity rupture audio, emergence shockwave, and cooling decay
function jumpdrive_tweaks.on_jump_discontinuity(source_pos, target_pos, ship_scan, delta_vector, fx_handle)
	if not ship_scan or not ship_scan.min_pos or not ship_scan.min_pos.x
	   or not ship_scan.max_pos or not ship_scan.max_pos.x
	   or not delta_vector or not delta_vector.x then
		return
	end

	local target_min = vector.add(ship_scan.min_pos, delta_vector)
	local target_max = vector.add(ship_scan.max_pos, delta_vector)
	local passengers = jumpdrive_tweaks.get_ship_passengers(target_min, target_max)

	-- Collect all target player names (from destination scan + spool handle)
	local target_players = {}
	for _, p in ipairs(passengers) do
		local name = p:get_player_name()
		if name and name ~= "" then target_players[name] = true end
	end
	if fx_handle and fx_handle.hud_entries then
		for _, entry in ipairs(fx_handle.hud_entries) do
			if entry.player_name and entry.player_name ~= "" then
				target_players[entry.player_name] = true
			end
		end
	end

	-- 1. Rupture sound at destination (positional and direct to passengers)
	if minetest.sound_play then
		minetest.sound_play("jumpdrive_rupture", {
			pos = target_pos,
			max_hear_distance = 75,
			gain = 0.75,
		})
		for pname, _ in pairs(target_players) do
			minetest.sound_play("jumpdrive_rupture", {
				to_player = pname,
				gain = 0.85,
			})
		end

		-- Soft cooldown spin-down audio
		if minetest.after then
			minetest.after(0.25, function()
				minetest.sound_play("jumpdrive_cooldown", {
					pos = target_pos,
					max_hear_distance = 45,
					gain = 0.35,
				})
				for pname, _ in pairs(target_players) do
					minetest.sound_play("jumpdrive_cooldown", {
						to_player = pname,
						gain = 0.40,
					})
				end
			end)
		end
	end

	-- 2. Fade out and remove ambient screen glow HUD
	if fx_handle and fx_handle.hud_entries then
		local function clear_huds()
			for _, entry in ipairs(fx_handle.hud_entries) do
				local player = minetest.get_player_by_name and minetest.get_player_by_name(entry.player_name)
				if player and player:is_player() and player.hud_remove then
					player:hud_remove(entry.hud_id)
				end
			end
			fx_handle.hud_entries = {}
			fx_handle.active = false
		end

		if minetest.after then
			minetest.after(0.5, clear_huds)
		else
			clear_huds()
		end
	end

	-- 3. External shockwave ring strictly around destination perimeter
	local target_min = vector.add(ship_scan.min_pos, delta_vector)
	local target_max = vector.add(ship_scan.max_pos, delta_vector)
	local target_center = {
		x = (target_min.x + target_max.x) / 2,
		y = (target_min.y + target_max.y) / 2,
		z = (target_min.z + target_max.z) / 2,
	}
	jumpdrive_tweaks.spawn_external_shockwave(target_center, target_min, target_max)

	-- 4. Exterior cooling steam vapor around external fuel tanks
	if minetest.add_particlespawner and ship_scan.fuel_tanks then
		for _, tpos in ipairs(ship_scan.fuel_tanks) do
			local moved_tpos = vector.add(tpos, delta_vector)
			minetest.add_particlespawner({
				amount = 8,
				time = 1.2,
				minpos = {x = moved_tpos.x - 0.3, y = moved_tpos.y + 0.4, z = moved_tpos.z - 0.3},
				maxpos = {x = moved_tpos.x + 0.3, y = moved_tpos.y + 0.8, z = moved_tpos.z + 0.3},
				minvel = {x = -0.15, y = 0.3, z = -0.15},
				maxvel = {x = 0.15, y = 0.6, z = 0.15},
				minexptime = 0.5,
				maxexptime = 1.0,
				minsize = 0.8,
				maxsize = 2.0,
				texture = "bubble.png",
				glow = 2,
			})
		end
	end

	-- 5. Sparse residual electrical sparks along outer vessel hull
	if minetest.add_particlespawner then
		minetest.add_particlespawner({
			amount = 18,
			time = 1.5,
			minpos = target_min,
			maxpos = target_max,
			minvel = {x = -0.4, y = -0.4, z = -0.4},
			maxvel = {x = 0.4, y = 0.4, z = 0.4},
			minexptime = 0.15,
			maxexptime = 0.4,
			minsize = 0.6,
			maxsize = 1.4,
			texture = "spark.png",
			glow = 8,
		})
	end
end
