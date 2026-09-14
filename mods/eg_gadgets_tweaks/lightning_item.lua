-- Lightning Strike Magic Tome (Tome of Thunder)

local active_sky_flashes = {}
local user_cooldowns = {}
local COOLDOWN_US = 500000 -- 0.5s in microseconds

local function get_top_parent(obj)
	local parent = obj and obj:get_attach()
	while parent do
		local next_parent = parent:get_attach()
		if not next_parent then return parent end
		parent = next_parent
	end
	return parent
end

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	active_sky_flashes[name] = nil
	user_cooldowns[name] = nil
end)

local function summon_lightning_strike(pos, user, user_vehicle)
	local player_name = user and user:get_player_name() or ""
	if user_vehicle == nil and user then
		user_vehicle = get_top_parent(user) or user:get_attach()
	end

	-- Protection check
	if minetest.is_protected(pos, player_name) then
		if player_name ~= "" then
			minetest.record_protection_violation(pos, player_name)
		end
		return false
	end

	-- Scan vertical column above target for obstructions
	-- Ignores soft foliage/permeable nodes (leaves, flora, liquids, non-walkable)
	-- If exactly 1 solid block is in the path (e.g. thin roof), the lightning breaks through it.
	-- If 2 or more solid blocks obstruct, the strike is blocked.
	minetest.load_area({x = pos.x, y = pos.y + 1, z = pos.z}, {x = pos.x, y = pos.y + 35, z = pos.z})

	local obstructing_blocks = {}
	for dy = 1, 35 do
		local check_pos = {x = pos.x, y = pos.y + dy, z = pos.z}
		local node = minetest.get_node(check_pos)
		local node_name = node.name

		if node_name == "ignore" then
			-- Unloaded/unemerged chunk: treat as solid cover
			table.insert(obstructing_blocks, check_pos)
			if #obstructing_blocks > 1 then
				break
			end
		elseif node_name ~= "air" then
			local def = minetest.registered_nodes[node_name]
			local is_permeable = false
			if def then
				if not def.walkable or def.buildable_to then
					is_permeable = true
				elseif minetest.get_item_group(node_name, "leaves") > 0
					or minetest.get_item_group(node_name, "flora") > 0
					or minetest.get_item_group(node_name, "plant") > 0
					or minetest.get_item_group(node_name, "liquid") > 0
					or minetest.get_item_group(node_name, "snowy") > 0 then
					is_permeable = true
				end
			end

			if not is_permeable then
				table.insert(obstructing_blocks, check_pos)
				if #obstructing_blocks > 1 then
					break
				end
			end
		end
	end

	if #obstructing_blocks > 1 then
		if player_name ~= "" then
			minetest.chat_send_player(player_name, "The lightning strike cannot penetrate solid cover above.")
		end
		return false
	elseif #obstructing_blocks == 1 then
		local roof_pos = obstructing_blocks[1]
		if minetest.is_protected(roof_pos, player_name) then
			if player_name ~= "" then
				minetest.record_protection_violation(roof_pos, player_name)
				minetest.chat_send_player(player_name, "The lightning strike is blocked by protected cover above.")
			end
			return false
		end

		local broken_node = minetest.get_node(roof_pos)
		local def = minetest.registered_nodes[broken_node.name]
		if not def or def.diggable == false or minetest.get_item_group(broken_node.name, "immortal") > 0 then
			if player_name ~= "" then
				minetest.chat_send_player(player_name, "The lightning strike cannot penetrate indestructible cover.")
			end
			return false
		end

		if def.can_dig and not def.can_dig(roof_pos, user) then
			if player_name ~= "" then
				minetest.chat_send_player(player_name, "The lightning strike cannot penetrate secure container cover.")
			end
			return false
		end

		-- Break through the single thin roof block
		minetest.dig_node(roof_pos)
		local tiles = def.tiles
		local tile = tiles and tiles[1]
		if type(tile) == "table" then
			tile = tile.name
		end
		if type(tile) ~= "string" or tile == "" then
			tile = "tnt_smoke.png"
		end

		minetest.add_particlespawner({
			amount = 20,
			time = 0.1,
			minpos = {x = roof_pos.x - 0.4, y = roof_pos.y - 0.4, z = roof_pos.z - 0.4},
			maxpos = {x = roof_pos.x + 0.4, y = roof_pos.y + 0.4, z = roof_pos.z + 0.4},
			minvel = {x = -3, y = 1, z = -3},
			maxvel = {x = 3, y = 4, z = 3},
			minacc = {x = 0, y = -9.81, z = 0},
			maxacc = {x = 0, y = -9.81, z = 0},
			minexptime = 0.4,
			maxexptime = 0.8,
			minsize = 1,
			maxsize = 3,
			texture = tile,
		})
	end

	local lightning_size = 110

	-- Spawn vertical lightning particle
	minetest.add_particlespawner({
		amount = 1,
		time = 0.25,
		minpos = {x = pos.x, y = pos.y + (lightning_size / 2) + 0.5, z = pos.z},
		maxpos = {x = pos.x, y = pos.y + (lightning_size / 2) + 0.5, z = pos.z},
		minvel = {x = 0, y = 0, z = 0},
		maxvel = {x = 0, y = 0, z = 0},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 0.25,
		maxexptime = 0.25,
		minsize = lightning_size * 10,
		maxsize = lightning_size * 10,
		collisiondetection = false,
		vertical = true,
		texture = "lightning_lightning_" .. math.random(1, 3) .. ".png",
		glow = 14,
	})

	-- Impact ground sparks
	minetest.add_particlespawner({
		amount = 40,
		time = 0.1,
		minpos = {x = pos.x - 0.5, y = pos.y, z = pos.z - 0.5},
		maxpos = {x = pos.x + 0.5, y = pos.y + 1.5, z = pos.z + 0.5},
		minvel = {x = -4, y = 2, z = -4},
		maxvel = {x = 4, y = 7, z = 4},
		minacc = {x = 0, y = -9.81, z = 0},
		maxacc = {x = 0, y = -9.81, z = 0},
		minexptime = 0.5,
		maxexptime = 1.5,
		minsize = 2,
		maxsize = 4,
		glow = 14,
		texture = "magic_materials_arcanite_dust.png",
	})

	-- Expanding shockwave smoke ring
	minetest.add_particlespawner({
		amount = 28,
		time = 0.1,
		minpos = {x = pos.x - 0.5, y = pos.y + 0.1, z = pos.z - 0.5},
		maxpos = {x = pos.x + 0.5, y = pos.y + 0.3, z = pos.z + 0.5},
		minvel = {x = -7, y = 0.2, z = -7},
		maxvel = {x = 7, y = 1.0, z = 7},
		minacc = {x = 0, y = -1, z = 0},
		maxacc = {x = 0, y = -1, z = 0},
		minexptime = 0.4,
		maxexptime = 0.7,
		minsize = 2,
		maxsize = 4,
		collisiondetection = true,
		texture = "tnt_smoke.png",
	})

	-- Thunder audio
	minetest.sound_play("lightning_thunder", {
		pos = pos,
		gain = 2.0,
		max_hear_distance = 500,
	})

	-- Flash sky for nearby players without race conditions
	for _, p in ipairs(minetest.get_connected_players()) do
		local p_pos = p:get_pos()
		if p_pos and vector.distance(p_pos, pos) < 80 then
			local name = p:get_player_name()
			local now = minetest.get_us_time()
			if not active_sky_flashes[name] then
				local sky_table = p:get_sky(true)
				if type(sky_table) == "table" then
					active_sky_flashes[name] = {sky = sky_table, is_table = true, expire_us = now + 200000}
				else
					local bgcolor, sky_type, textures, clouds = p:get_sky()
					active_sky_flashes[name] = {
						sky = {bgcolor, sky_type, textures, clouds},
						is_table = false,
						expire_us = now + 200000,
					}
				end
				p:set_sky(0xffffff, "plain", {})
			else
				active_sky_flashes[name].expire_us = now + 200000
			end

			local function check_and_restore_sky()
				local state = active_sky_flashes[name]
				if not state then return end
				local remaining_s = (state.expire_us - minetest.get_us_time()) / 1000000
				if remaining_s <= 0.02 then
					local player = minetest.get_player_by_name(name)
					if player then
						if state.is_table then
							player:set_sky(state.sky)
						else
							local unpack_fn = table.unpack or unpack
							player:set_sky(unpack_fn(state.sky))
						end
					end
					active_sky_flashes[name] = nil
				else
					minetest.after(math.max(0.05, remaining_s), check_and_restore_sky)
				end
			end

			minetest.after(0.2, check_and_restore_sky)
		end
	end

	-- Area damage and knockback to entities inside radius
	local blast_radius = 5.5
	local objects = minetest.get_objects_inside_radius(pos, blast_radius)
	for _, obj in ipairs(objects) do
		if obj ~= user and obj ~= user_vehicle and obj:get_hp() > 0 then
			local is_player = obj:is_player()
			local luaobj = obj:get_luaentity()
			if is_player or (luaobj and luaobj.name ~= "__builtin:item" and obj:get_attach() == nil) then
				local obj_pos = obj:get_pos()
				if obj_pos then
					local dist = math.max(0, vector.distance(pos, obj_pos))
					local damage = math.floor(24 * (1 - (dist / (blast_radius + 1))))
					if damage < 6 then damage = 6 end

					obj:punch(user or obj, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = {fleshy = damage},
					}, nil)

					-- Radial knockback with low vertical stagger
					local dx = obj_pos.x - pos.x
					local dz = obj_pos.z - pos.z
					local h_dist = math.sqrt(dx * dx + dz * dz)

					local dir_x, dir_z
					if h_dist < 0.1 then
						local angle = math.random() * 2 * math.pi
						dir_x = math.cos(angle)
						dir_z = math.sin(angle)
					else
						dir_x = dx / h_dist
						dir_z = dz / h_dist
					end

					local push_speed = math.floor(10 * (1 - (dist / (blast_radius + 1))))
					if push_speed < 3 then push_speed = 3 end

					-- Low vertical hop (1.5 - 2.0 nodes), heavy horizontal push
					local vel_x = dir_x * push_speed
					local vel_z = dir_z * push_speed
					local vel_y = 2.0

					if obj.add_velocity then
						obj:add_velocity({x = vel_x, y = vel_y, z = vel_z})
					elseif obj.set_velocity then
						local cur_vel = obj:get_velocity() or {x = 0, y = 0, z = 0}
						obj:set_velocity({
							x = cur_vel.x + vel_x,
							y = math.max(cur_vel.y, vel_y),
							z = cur_vel.z + vel_z,
						})
					end
				end
			end
		end
	end

	-- Single temporary surface flame at strike point (unless liquid)
	if minetest.registered_nodes["lightning:dying_flame"] then
		for dy = 1, -1, -1 do
			local ground = {x = pos.x, y = pos.y + dy, z = pos.z}
			local above = {x = pos.x, y = pos.y + dy + 1, z = pos.z}
			local gnode = minetest.get_node(ground).name
			local anode = minetest.get_node(above).name
			if anode == "air" and gnode ~= "air" and gnode ~= "ignore" then
				if minetest.get_item_group(gnode, "liquid") == 0 then
					if not minetest.is_protected(above, player_name) then
						minetest.set_node(above, {name = "lightning:dying_flame"})
					end
				end
				break
			end
		end
	end

	return true
end

gadgets.register_gadget({
	name = "gadgets_tweaks:tome_thunder",
	description = "Tome of Thunder",
	texture = "gadgets_tweaks_tome_thunder.png",
	mana_per_use = minetest.get_modpath("mana") and 150 or nil,

	custom_wear = true,
	custom_on_use = function(itemstack, user, pointed_thing)
		if not user then return end

		local player_name = user:get_player_name()
		local now = minetest.get_us_time()
		if player_name ~= "" and user_cooldowns[player_name] and (now - user_cooldowns[player_name]) < COOLDOWN_US then
			return
		end

		local user_vehicle = get_top_parent(user) or user:get_attach()
		local max_range = 50
		local eye_offset = user:get_properties().eye_height or 1.625
		local user_pos = user:get_pos()
		if not user_pos then return end
		local eye_pos = {x = user_pos.x, y = user_pos.y + eye_offset, z = user_pos.z}
		local look_dir = user:get_look_dir()
		local end_pos = vector.add(eye_pos, vector.multiply(look_dir, max_range))

		local target_pos = nil

		-- Raycast targeting (objects = true, liquids = true)
		local ray = minetest.raycast(eye_pos, end_pos, true, true)
		for hit in ray do
			if hit.type == "object" and hit.ref ~= user and hit.ref ~= user_vehicle then
				if hit.ref:get_attach() ~= user and hit.ref:get_attach() ~= user_vehicle then
					local obj_pos = hit.ref:get_pos()
					if obj_pos then
						target_pos = vector.round(obj_pos)
						break
					end
				end
			elseif hit.type == "node" then
				local node = minetest.get_node(hit.under)
				local def = minetest.registered_nodes[node.name]
				if def and (def.walkable or minetest.get_item_group(node.name, "liquid") > 0) then
					target_pos = hit.under
					break
				end
			end
		end

		-- Fallback to pointed_thing if raycast missed
		if not target_pos and pointed_thing then
			if pointed_thing.type == "node" then
				target_pos = minetest.get_pointed_thing_position(pointed_thing, false)
			elseif pointed_thing.type == "object" and pointed_thing.ref ~= user and pointed_thing.ref ~= user_vehicle then
				if pointed_thing.ref:get_attach() ~= user and pointed_thing.ref:get_attach() ~= user_vehicle then
					local obj_pos = pointed_thing.ref:get_pos()
					if obj_pos then
						target_pos = vector.round(obj_pos)
					end
				end
			end
		end

		if not target_pos then
			return
		end

		if player_name ~= "" then
			user_cooldowns[player_name] = now
		end

		local struck = summon_lightning_strike(target_pos, user, user_vehicle)
		if struck then
			return true
		end
	end,

	recipe = {
		{
			{"", "magic_materials:storm_rune", ""},
			{"", "magic_materials:enchanted_book", ""},
			{"", "magic_materials:energy_rune", ""}
		},
	},
})
