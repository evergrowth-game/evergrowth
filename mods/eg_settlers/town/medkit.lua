local S = minetest.get_translator("eg_settlers")

minetest.register_craftitem("eg_settlers:medkit", {
	description = S("Field Medkit") .. "\n" .. S("Right-click a settler or companion to heal them to full health."),
	inventory_image = "default_paper.png^[colorize:#E6DFD3:255^(default_paper.png^[colorize:#794E24:255^[resize:16x3)^(default_paper.png^[colorize:#00C844:255^[resize:8x2)^(default_paper.png^[colorize:#00C844:255^[resize:2x8)",
	on_use = function(itemstack, user, pointed_thing)
		if not pointed_thing or pointed_thing.type ~= "object" then
			return itemstack
		end

		local target = pointed_thing.ref
		if not target then
			return itemstack
		end

		local target_pos = target:get_pos()
		if not target_pos then
			return itemstack
		end

		local lua_ent = target:get_luaentity()
		local is_villager = lua_ent and lua_ent.is_villager
		local is_companion = lua_ent and lua_ent.is_companion

		if not (is_villager or is_companion) then
			return itemstack
		end

		local hp = target:get_hp()
		local max_hp = target:get_properties().hp_max
		if not max_hp or max_hp <= 0 then
			max_hp = lua_ent and lua_ent.hp_max or 20
		end

		if hp < max_hp then
			target:set_hp(max_hp)

			minetest.add_particlespawner({
				amount = 12,
				time = 0.5,
				minpos = {x = target_pos.x - 0.4, y = target_pos.y + 0.2, z = target_pos.z - 0.4},
				maxpos = {x = target_pos.x + 0.4, y = target_pos.y + 1.6, z = target_pos.z + 0.4},
				minvel = {x = -0.2, y = 0.5, z = -0.2},
				maxvel = {x = 0.2, y = 1.2, z = 0.2},
				minexptime = 0.8,
				maxexptime = 1.5,
				minsize = 1.5,
				maxsize = 2.5,
				texture = "bubble.png^[colorize:#00FF00:200",
			})

			minetest.sound_play("default_cool_lava", {
				pos = target_pos,
				gain = 0.8,
				max_hear_distance = 16,
			}, true)

			if user and not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
		end

		return itemstack
	end,
})

minetest.register_craft({
	type = "shapeless",
	output = "eg_settlers:medkit",
	recipe = {
		"mobs:leather",
		"farming:cotton",
		"farming:cotton",
		"magic_materials:magic_root",
	},
})
