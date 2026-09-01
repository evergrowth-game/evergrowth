-- Lightning Strike Magic Tome (Tome of Thunder)

local function summon_lightning_strike(pos, user)
	local player_name = user and user:get_player_name() or ""

	-- Protection check
	if minetest.is_protected(pos, player_name) then
		if player_name ~= "" then
			minetest.record_protection_violation(pos, player_name)
		end
		return false
	end

	-- Check for open sky above (at least 30 nodes line of sight)
	local sky_target = {x = pos.x, y = pos.y + 35, z = pos.z}
	local has_sky_clearance = minetest.line_of_sight(
		{x = pos.x, y = pos.y + 1, z = pos.z},
		sky_target,
		1
	)
	if not has_sky_clearance then
		if player_name ~= "" then
			minetest.chat_send_player(player_name, "The lightning strike cannot penetrate solid cover above.")
		end
		return false
	end

	local lightning_size = 50

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

	-- Thunder audio
	minetest.sound_play("lightning_thunder", {
		pos = pos,
		gain = 5.0,
		max_hear_distance = 128,
	})

	-- Flash sky for nearby players
	local nearby_players = minetest.get_connected_players()
	for _, p in ipairs(nearby_players) do
		local p_pos = p:get_pos()
		if p_pos and vector.distance(p_pos, pos) < 80 then
			local sky_info = {}
			sky_info.bgcolor, sky_info.type, sky_info.textures = p:get_sky()
			p:set_sky(0xffffff, "plain", {})
			minetest.after(0.2, function()
				if p and p:is_player() then
					p:set_sky(sky_info.bgcolor, sky_info.type, sky_info.textures)
				end
			end)
		end
	end

	-- Area damage and knockback to entities inside radius
	local blast_radius = 4.5
	local objects = minetest.get_objects_inside_radius(pos, blast_radius)
	for _, obj in ipairs(objects) do
		if obj ~= user then
			local obj_pos = obj:get_pos()
			if obj_pos then
				local dist = math.max(1, vector.distance(pos, obj_pos))
				local damage = math.floor(14 * (1 - (dist / (blast_radius + 1))))
				if damage < 4 then damage = 4 end

				obj:punch(user or obj, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = {fleshy = damage},
				}, nil)

				-- Radial knockback
				local dir = vector.direction(pos, obj_pos)
				dir.y = 0.4
				if obj.add_velocity then
					obj:add_velocity(vector.multiply(dir, 7))
				elseif obj.set_velocity then
					local cur_vel = obj:get_velocity() or {x = 0, y = 0, z = 0}
					obj:set_velocity(vector.add(cur_vel, vector.multiply(dir, 7)))
				end
			end
		end
	end

	-- Ground ignition (temporary flame)
	local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
	if minetest.get_node(flame_pos).name == "air" and not minetest.is_protected(flame_pos, player_name) then
		if minetest.registered_nodes["lightning:dying_flame"] then
			minetest.set_node(flame_pos, {name = "lightning:dying_flame"})
		end
	end

	return true
end

gadgets.register_gadget({
	name = "gadgets_tweaks:tome_thunder",
	description = "Tome of Thunder",
	texture = "gadgets_tweaks_tome_thunder.png",
	mana_per_use = 150,
	use_sound = "gadgets_magic_spell_cast",
	use_sound_gain = 1.0,

	custom_wear = true,
	custom_on_use = function(itemstack, user, pointed_thing)
		if not user then return end

		local max_range = 50
		local eye_offset = user:get_properties().eye_height or 1.625
		local user_pos = user:get_pos()
		local eye_pos = {x = user_pos.x, y = user_pos.y + eye_offset, z = user_pos.z}
		local look_dir = user:get_look_dir()
		local end_pos = vector.add(eye_pos, vector.multiply(look_dir, max_range))

		local target_pos = nil

		-- Raycast targeting
		local ray = minetest.raycast(eye_pos, end_pos, true, false)
		for hit in ray do
			if hit.type == "object" and hit.ref ~= user then
				local obj_pos = hit.ref:get_pos()
				if obj_pos then
					target_pos = vector.round(obj_pos)
					break
				end
			elseif hit.type == "node" then
				target_pos = hit.under
				break
			end
		end

		-- Fallback to pointed_thing if raycast missed
		if not target_pos and pointed_thing then
			if pointed_thing.type == "node" then
				target_pos = minetest.get_pointed_thing_position(pointed_thing, false)
			elseif pointed_thing.type == "object" and pointed_thing.ref ~= user then
				local obj_pos = pointed_thing.ref:get_pos()
				if obj_pos then
					target_pos = vector.round(obj_pos)
				end
			end
		end

		if not target_pos then
			return
		end

		local struck = summon_lightning_strike(target_pos, user)
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
