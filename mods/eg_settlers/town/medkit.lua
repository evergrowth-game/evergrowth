local S = minetest.get_translator("eg_settlers")

eg_settlers = eg_settlers or {}

function eg_settlers.use_medkit_on_entity(self_or_obj, clicker, itemstack)
	if not self_or_obj then
		return false
	end

	local lua_ent, target_obj
	if self_or_obj.get_luaentity then
		target_obj = self_or_obj
		lua_ent = target_obj:get_luaentity()
	else
		lua_ent = self_or_obj
		target_obj = lua_ent and lua_ent.object
	end

	if not target_obj then
		return false
	end

	local is_villager = lua_ent and (lua_ent.is_villager or lua_ent.is_settler)
	local is_companion = lua_ent and (lua_ent.is_companion or lua_ent.is_evergrowth_companion)
	local is_npc = lua_ent and (lua_ent.type == "npc" or (lua_ent.name and lua_ent.name:find("mobs_npc:")))

	if not (is_villager or is_companion or is_npc) then
		return false
	end

	local hp = (lua_ent and lua_ent.health) or target_obj:get_hp()
	local max_hp = (lua_ent and lua_ent.hp_max) or target_obj:get_properties().hp_max
	if not max_hp or max_hp <= 0 then
		max_hp = 20
	end

	if hp < max_hp then
		if lua_ent then
			lua_ent.health = max_hp
		end
		target_obj:set_hp(max_hp)

		local target_pos = target_obj:get_pos()
		if target_pos then
			minetest.add_particlespawner({
				amount = 16,
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
		end

		if clicker and clicker:is_player() then
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
				clicker:set_wielded_item(itemstack)
			end
		end
		return true
	else
		if clicker and clicker:is_player() then
			minetest.chat_send_player(clicker:get_player_name(), S("Target is already at full health."))
		end
		return true
	end
end

minetest.register_craftitem("eg_settlers:medkit", {
	description = S("Field Medkit") .. "\n" .. S("Right-click a settler or companion to heal them to full health."),
	inventory_image = "eg_settlers_medkit.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing and pointed_thing.type == "object" then
			local target = pointed_thing.ref
			if target and eg_settlers.use_medkit_on_entity(target, user, itemstack) then
				return itemstack
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

minetest.register_on_mods_loaded(function()
	for name, entity in pairs(minetest.registered_entities) do
		if entity.type == "npc" or name:find("mobs_npc:") or name:find("eg_settlers:") then
			local old_on_rightclick = entity.on_rightclick
			entity.on_rightclick = function(self, clicker)
				if clicker and clicker:is_player() then
					local item = clicker:get_wielded_item()
					if item and item:get_name() == "eg_settlers:medkit" then
						if eg_settlers.use_medkit_on_entity(self, clicker, item) then
							return
						end
					end
				end
				if old_on_rightclick then
					return old_on_rightclick(self, clicker)
				end
			end
		end
	end
end)

