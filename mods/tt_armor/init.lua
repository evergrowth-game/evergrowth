local S = minetest.get_translator(minetest.get_current_modname())

local function physics_recalculation(value)
	local new_value = math.floor(value * 100)

	if new_value > 0 then
		new_value = "+" .. new_value
	end

	return new_value
end

tt.register_snippet(function(itemstring)
	local def = minetest.registered_items[itemstring]
	local desc
	local armor_heal = def.groups.armor_heal
	local armor_use = def.groups.armor_use
	local armor_fire = def.groups.armor_fire
	local armor_water = def.groups.armor_water
	local armor_feather = def.groups.armor_feather
	local physics_speed = def.groups.physics_speed
	local physics_gravity = def.groups.physics_gravity
	local physics_jump = def.groups.physics_jump

	if def.armor_groups then
		desc = S("Armor")

		if armor_heal then
			desc = desc .. "\n" .. S("Protection: @1%", math.floor(armor_heal))
		end

		if armor_use then
			desc = desc .. "\n" .. S("Strength: @1", math.floor(65535 / armor_use))
		end

		if armor_fire then
			desc = desc .. "\n" .. S("Fire: @1", armor_fire)
		end

		if armor_water then
			desc = desc .. "\n" .. S("Water protection")
		end

		if armor_feather then
			desc = desc .. "\n" .. S("Fall protection")
		end

		if physics_speed then
			desc = desc .. "\n" .. S("Speed: @1%", physics_recalculation(physics_speed))
		end

		if physics_gravity then
			desc = desc .. "\n" .. S("Gravity: @1%", physics_recalculation(physics_gravity))
		end

		if physics_jump then
			desc = desc .. "\n" .. S("Jump: @1%", physics_recalculation(physics_jump))
		end

		if def.damage_groups then
			desc = desc .. "\n" .. S("Protected groups:")

			for key, value in pairs(def.damage_groups) do
				desc = desc .. "\n- " .. key ..": " .. value
			end
		end
	end

	return desc
end)
