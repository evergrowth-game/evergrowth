local mod_mcl_farming = core.get_modpath("mcl_farming") ~= nil
local mod_mcl_tools = core.get_modpath("mcl_tools") ~= nil
local is_voxelibre = mod_mcl_tools and (mcl_tools == nil)
local S = farmtools.i18n

local get_node_pointer = function(pos)
	return {
		under = { x = pos.x, y = pos.y, z = pos.z },
		above = { x = pos.x, y = pos.y + 1, z = pos.z },
	}
end

local get_item_group = function(def, group)
	if def == nil or def.groups == nil or def.groups[group] == nil then
		return 0
	end
	return def.groups[group]
end

local rake_on_use_single_node = function(user, node_ptr)
	-- this function is based on the farming.hoe_on_use from the minetest_game by Luanti
	-- see: https://github.com/luanti-org/minetest_game/blob/master/mods/farming/hoes.lua
	-- original code is licensed under LGPL-2.1

	-- this functions returns a boolean value, that indicates whether it was
	-- able to replace the specified node with soil
	local under = core.get_node(node_ptr.under)
	local p = { x = node_ptr.under.x, y = node_ptr.under.y + 1, z = node_ptr.under.z }
	local above = core.get_node(p)

	-- fail if any of the nodes is not registered
	if not core.registered_nodes[under.name] then
		return false
	end
	if not core.registered_nodes[above.name] then
		return false
	end

	-- check if the node above the pointed thing is air
	-- if it isn't, exit the function and return false
	if above.name ~= "air" then
		return false
	end

	-- check if pointing at soil
	-- fail if the player isn't pointing at soil
	if core.get_item_group(under.name, "soil") ~= 1 then
		return false
	end

	-- check if (wet) soil defined
	local regN = core.registered_nodes
	if mod_mcl_farming then
		if get_item_group(regN[under.name], "cultivatable") == 0 then
			return false
		end
	elseif regN[under.name].soil == nil or regN[under.name].soil.wet == nil or regN[under.name].soil.dry == nil then
		return false
	end

	local player_name = user and user:get_player_name() or ""

	if core.is_protected(node_ptr.under, player_name) then
		core.record_protection_violation(under, player_name)
		return false
	end
	if core.is_protected(node_ptr.above, player_name) then
		core.record_protection_violation(above, player_name)
		return false
	end

	-- turn the node into soil and play sound
	if mod_mcl_farming then
		if is_voxelibre then
			-- voxelibre mcl_farming does not set nodes' _on_hoe_place, so we have to
			-- simulate a hoe tool that then uses its on_place function.
			local temp_hoe = ItemStack("mcl_farming:hoe_wood")
			core.registered_tools["mcl_farming:hoe_wood"].on_place(temp_hoe, user, node_ptr)
		else
			-- mineclonia
			if regN[under.name]._on_hoe_place ~= nil then
				regN[under.name]._on_hoe_place(nil, nil, node_ptr)
			end
		end
	else
		core.set_node(node_ptr.under, { name = regN[under.name].soil.dry })
	end
	return true
end

farmtools.rake_on_use = function(itemstack, user, pointed_thing, uses)
	-- this function is based on the farming.hoe_on_use from the minetest_game by Luanti
	-- see: https://github.com/luanti-org/minetest_game/blob/master/mods/farming/hoes.lua
	-- original code is licensed under LGPL-2.1
	local pt = pointed_thing

	-- check if pointing at a node
	if not pt then
		return
	end
	if pt.type ~= "node" then
		return
	end

	-- first we check whether the user can use the rake on the pointed node
	-- if they can't, we won't go any further
	-- note that the function that we call here WILL replace the current node with soil if it
	-- can do so. It will then return a boolean value indicating whether it was able to do so.
	if not rake_on_use_single_node(user, pointed_thing) then
		return
	end

	-- this will be required for wearing tools depending on the number of nodes turned into soil
	local total_nodes_changed = 1

	local itemdef = itemstack:get_definition()
	-- the rake group allows us to specify how big the area to turn into soil should be
	-- if rake = 2, then the area is a 3x3 area
	-- if rake = 3, then the area is a 5x5 area
	-- and so on...
	-- this does not correspond to the actual level of the rake.
	-- TL;DR: the value of the rake group = level of the rake + 1
	local range = (get_item_group(itemdef, "rake") or 1) - 1

	-- we define the area that will be turned into soil
	local pos = pt.under
	if range > 0 then
		local pos1 = vector.add(pos, { x = -range, y = 0, z = -range })
		local pos2 = vector.add(pos, { x = range, y = 0, z = range })
		local positions = core.find_nodes_in_area(pos1, pos2, "group:soil")
		for _, check_pos in ipairs(positions) do
			if pos ~= check_pos then
				local node_ptr = get_node_pointer(check_pos)
				local success = rake_on_use_single_node(user, node_ptr)
				-- if node was replaced, we increment the count of processed nodes by 1.
				if success then
					total_nodes_changed = total_nodes_changed + 1
				end
			end
		end
	end

	core.sound_play("default_dig_crumbly", { pos = pt.under, gain = 0.3 }, true)

	local player_name = user and user:get_player_name() or ""

	if not core.is_creative_enabled(player_name) then
		-- wear tool
		-- here we use the value of total_nodes_changed to make the rake break faster the more
		-- nodes were processed
		if mod_mcl_farming then
			itemstack:add_wear_by_uses(get_item_group(itemdef, "rake_uses") / total_nodes_changed)
		else
			itemstack:add_wear_by_uses(uses / total_nodes_changed)
		end
		-- tool break sound
		if itemstack:get_count() == 0 and itemdef.sound and itemdef.sound.breaks then
			core.sound_play(itemdef.sound.breaks, { pos = pt.above, gain = 0.5 }, true)
		end
	end
	return itemstack
end

-- Register new rakes
-- This is highly based on the register_hoe function of the farming mod.
farmtools.register_rake = function(name, def)
	-- Check for : prefix (register new rakes in your mod's namespace)
	if name:sub(1, 1) ~= ":" then
		name = ":" .. name
	end

	-- Check def table
	if def.description == nil then
		def.description = S("Rake")
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = 90
	end
	if def.level == nil then
		def.level = 1
	end
	-- support the definition providing groups, primarily for enchantability for voxelibre
	local groups = { hoe = 1, rake = def.level + 1 }
	if def.groups then
		for k, v in pairs(def.groups) do
			groups[k] = v
		end
	end

	-- Register the tool
	core.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		on_use = function(itemstack, user, pointed_thing)
			return farmtools.rake_on_use(itemstack, user, pointed_thing, def.max_uses)
		end,
		groups = groups,
		sound = { breaks = "default_tool_breaks" },
	})

	-- Register its recipe
	if def.recipe then
		core.register_craft({
			output = name:sub(2),
			recipe = def.recipe,
		})
	elseif def.material then
		core.register_craft({
			output = name:sub(2),
			recipe = {
				{ def.material, def.material, def.material },
				{ def.material, "group:stick", def.material },
				{ "", "group:stick", "" },
			},
		})
	end
end
