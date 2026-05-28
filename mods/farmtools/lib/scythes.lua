-- this file contains the code that is used by scythes

local is_farming_redo = core.get_modpath("farming") ~= nil and farming ~= nil and farming.mod == "redo"
local mod_mcl_farming = core.get_modpath("mcl_farming") ~= nil
local is_voxelibre = mod_mcl_tools and (mcl_tools == nil)
local S = farmtools.i18n

local DEFAULT_SCYTHE_USES = 90

local farming_redo_exceptions = {
	-- this is the list of plants that don't drop their seeds when harvested
	-- instead, the player normally has to craft the seeds from the item dropped during harvesting
	-- however, this causes a problem with scythes, since they require the player to have the seeds
	-- in the inventory to replant the plant after harvesting.
	-- the approach taken here is to automatically craft the seeds from the item when no seed is
	-- available.
	-- for that, we need the list below
	["farming:garlic_clove"] = { { item = "farming:garlic", seeds_in_item = 8 } },
	["farming:seed_sunflower"] = { { item = "farming:sunflower", seeds_in_item = 5 } },
	["farming:peppercorn"] = {
		{ item = "farming:pepper", seeds_in_item = 1 },
		{ item = "farming:pepper_red", seeds_in_item = 1 },
		{ item = "farming:pepper_yellow", seeds_in_item = 1 },
	},
	["farming:pumpkin_slice"] = { { item = "farming:pumpkin_8", seeds_in_item = 4 } },
	["farming:melon_slice"] = { { item = "farming:melon_8", seeds_in_item = 4 } },
}

local item_craftable_to_seeds_in_inv = function(seeds, invref)
	-- this function should run when seeds required to replant the harvested plant are
	-- not available in the player inventory
	-- it checks whether an item from the inventory can be crafted into the required seeds and
	-- returns the item name along the number of seeds that can be crafted from it if it is the case

	if is_farming_redo and farming_redo_exceptions[seeds] ~= nil then
		for _, def in pairs(farming_redo_exceptions[seeds]) do
			if invref:contains_item("main", def) then
				return def
			end
		end
		return nil
	end
end

local get_item_group = function(def, group)
	if def == nil or def.groups == nil or def.groups[group] == nil then
		return 0
	end
	return def.groups[group]
end

local get_plant_definition = function(plant)
	-- this function returns the plant definition from the farming API

	-- x_farming has its own API
	-- if the plant is registered in the x_farming API, we return its definition
	local modname = plant:split(":")[1] or ""
	if modname == "x_farming" then
		-- note that we do not check whether x_farming is enabled,
		-- because if there is an item whose modname is x_farming,
		-- it means that the mod is enabled.
		-- if this is incorrect or may lead to bugs, please let me know :)
		local name = plant:split(":")[2] or ""
		local pname = name:gsub("(.*)_.*$", "%1")
		return x_farming.registered_plants[pname]
	end

	-- next we need to check whether the farming API is provided by the default
	-- farming mod or by the Farming Redo version
	if is_farming_redo then
		-- if we are using Farming Redo, we need to iterate through the registered plants
		-- to check if the given plant is registered. if it is, we return its definition
		for _, data in pairs(farming.registered_plants) do
			if data.crop == plant then
				return data
			end
		end
	end

	-- if no definition was found previously, we try to see whether the plant can be found
	-- through the farming API (without checking whether it is the one from the default farming mod
	-- or the Redo mod, since the latter is fully compatible with the default one).
	-- if a plant is found, we return its definition
	if farming ~= nil and farming.registered_plants[plant] ~= nil then
		return farming.registered_plants[plant]
	end

	-- finally, if no definition was found as of yet, we try one last time to see if the plant was
	-- registered without its mod name, and return the result.
	-- if no plant is found, the result will be nil.
	local name = plant:split(":")[2] or ""
	local pname = name:gsub("(.*)_.*$", "%1")
	if mod_mcl_farming then
		return mcl_farming.plant_lists["plant_" .. pname]
	end
	if farming ~= nil then
		return farming.registered_plants[pname]
	else
		return ""
	end
end

local get_seed_name = function(plant)
	-- this function returns the plant's seeds using various methods
	-- it should be executed only IF WE KNOW that the plant exists
	-- (i.e. the function get_plant_definition returned a value that is different from nil)

	-- TODO: maybe we could optimize this function by passing the plant definition directly,
	-- instead of having to use the API two times.

	-- if Farming Redo is enabled, we can use its API to find the seeds
	-- (as long as the plant was registered through the farming API)
	-- if we find one, we return the seed name
	if is_farming_redo then
		for _, data in pairs(farming.registered_plants) do
			if data.crop == plant then
				return data.seed
			end
		end
	end
	if mod_mcl_farming then
		local orig_plant = plant
		local seeds = plant
		local this_seeds = core.registered_craftitems[seeds]
		-- technically this is for other mods too but it covers mineclonia
		local suffixes = { "_seeds", "_seed", "_item", "" }
		local continue = true
		local x = 0
		while this_seeds == nil and continue do
			for i, suffix in ipairs(suffixes) do
				seeds = plant .. suffix
				this_seeds = core.registered_craftitems[seeds]
				if this_seeds ~= nil then
					-- return plain text name of item
					return seeds
				end
				x = x + 1
				if x == 1 then
					-- strip "_plant" and try again
					plant = plant:gsub("_plant.*$", "")
				elseif x > 2 then
					continue = false
				end
			end
		end
		-- if we get here, there is no seed we could find.
		core.log("warning", "No mcl-based seeds calculated for item " .. orig_plant)
	end

	-- if no plant was found previously, we try to see whether the plant can be found
	-- through the farming API (without checking whether it is the one from the default farming mod
	-- or the Redo mod, since the latter is fully compatible with the default one).
	-- if a plant is found and if its definition contains a "seed" property, we return its seed name
	if farming.registered_plants[plant] ~= nil and farming.registered_plants[plant].seed ~= nil then
		return farming.registered_plants[plant].seed
	end

	-- finally, if no plant was found as of yet, we return an item named exactly like the plant,
	-- but with "seed_" appended right before the plant name
	local mod = plant:split(":")[1]
	local name = plant:split(":")[2]
	local pname = name:gsub("(.*)_.*$", "%1")
	return mod .. ":seed_" .. pname
end

local harvest_and_replant = function(pos, user)
	-- this is the function used to harvest and replant a single node using the scythe
	-- it returns a boolean value that indicates whether it was able to harvest (and hopefully replant)
	-- the node at a given position

	local playername = user:get_player_name()
	local node = core.get_node(pos)
	local node_id = node.name:gsub("(.*)_.*$", "%1")
	if mod_mcl_farming then
		node_id = node.name
	end

	-- try to get a plant definition for the given node
	-- if none is found, we will exit this function and return false
	local plantdef = get_plant_definition(node_id)
	if plantdef == nil then
		return false
	end

	-- try to guess current stage of the plant from its node ID
	local stage = tonumber(node.name:gsub(".*_(.*)$", "%1") or 0)
	-- if either:
	-- - the definition does not contain a "steps" property to indicate how many stages the plant goes through when maturing
	-- - the current stage of the plant couldn't be detected from the node ID
	-- we exit the function by returning false
	if mod_mcl_farming then
		if plantdef.full_grown == nil then
			return false
		elseif plantdef.full_grown == node_id then
		else
			return false
		end
	else
		-- now we test the current stage of the plant against its total number of steps
		-- if the value of "stage" is lower than "steps", it means that the plant isn't yet ready for harvesting
		-- thus, we exit this function and return false
		if plantdef.steps == nil or stage == nil or stage < plantdef.steps then
			return false
		end
	end

	-- if the node is protected or the given user isn't allowed to break it,
	-- we record the violation attempt and return false
	if core.is_protected(pos, playername) then
		core.record_protection_violation(pos, playername)
		return false
	end

	-- otherwise we can go ahead and break the plant, while playing a nice sound
	core.node_dig(pos, node, user)
	core.sound_play("default_dig_snappy", { pos = pos, gain = 0.5, max_hear_distance = 8 }, true)

	-- once the plant is broken, we need to replant it
	core.after(0, function()
		-- this function replants the plant after is is harvested
		-- it also takes care of removing the correct amount of seeds from the player inventory

		local invref = user:get_inventory()
		local seeds = get_seed_name(node_id)

		-- this is required to prevent trellis and bean poles duplication
		if is_farming_redo then
			if node_id == "farming:grapes" then
				if invref:contains_item("main", "farming:trellis") then
					invref:remove_item("main", "farming:trellis")
				end
			elseif node_id == "farming:beanpole" then
				if invref:contains_item("main", "farming:beanpole") then
					invref:remove_item("main", "farming:beanpole")
				end
			end
		end

		-- if seeds are not present in the inventory, and if no item from the inventory can be
		-- crafted into the seeds, we won't go further. it means that we cannot replant the plant
		local item_in_inv = item_craftable_to_seeds_in_inv(seeds, invref)
		if (not mod_mcl_farming) and (core.get_node(pos).name ~= "air" or not invref:contains_item("main", seeds)) then
			if item_in_inv == nil then
				return true
			end
		end

		-- we will only remove seeds from the player inventory if they are not in creative mod
		if not core.is_creative_enabled(playername) and not mod_mcl_farming then
			if not invref:contains_item("main", seeds) and item_in_inv ~= nil then
				-- if no seed is found in the inventory but an item from the inventory can be crafted
				-- into the seeds:
				-- first remove one of these items from the inventory
				invref:remove_item("main", item_in_inv.item)
				-- then add the number of seeds normally returned by the craft, less one (because we
				-- use one to replant the plant)
				local stack = ItemStack(seeds .. " " .. item_in_inv.seeds_in_item)
				invref:add_item("main", stack)
			else
				-- if seeds are already present in the inventory, then just remove one of them
				-- from the inventory
				invref:remove_item("main", seeds)
			end
		end

		-- finally, we need to replant the crop
		-- it is a bit different, depending on the version of the farming mod used.
		-- TODO: the behavior of this code depends on whether Farming Redo is used, but
		-- not on the mod that provides the plant. If the plant is from x_farming, the behavior
		-- will be different if Farming Redo is enabled and if it is disabled.
		if is_farming_redo then
			-- plant first crop for farming redo
			local crop_name = node_id .. "_1"
			local crop_def = core.registered_nodes[crop_name]
			if crop_def == nil then
				return
			end
			core.set_node(pos, { name = crop_name, param2 = crop_def.place_param2 })
		else
			if mod_mcl_farming then
				-- plant seeds for Mineclonia farming
				-- try level 0
				local level1 = node_id .. "_0"
				local crop_def = core.registered_nodes[level1]
				if crop_def == nil then
					level1 = node_id .. "_1"
					crop_def = core.registered_nodes[level1]
				end
				-- keep the same paramtype2 = "meshoptions" from lua_api.md
				core.set_node(pos, { name = level1, param2 = node.param2 })
				-- need to remove seed afterwards for Mineclonia, because it dropped seeds
				-- and not immediately placed them in player inventory. 2 seconds
				-- ought to be enough for the player to walk over the seeds.
				core.after(2, function()
					if not core.is_creative_enabled(playername) then
						invref:remove_item("main", { name = seeds, count = 1 })
					end
				end)
			else
				-- plant seeds for MTG farming
				core.set_node(pos, { name = seeds, param2 = 1 })
			end
			-- timer values taken from farming mod (see tick function in api.lua)
			core.get_node_timer(pos):start(math.random(166, 286))
		end
	end)
	-- finally, we return true, because we were able to harvest (and hopefully replant the crop)
	return true
end

farmtools.scythe_on_use = function(itemstack, user, pointed_thing, uses)
	-- this function is called when the scythe is used on a node

	-- if the scythe is used when the player isn't pointing at anything, we won't do anything
	if pointed_thing == nil then
		return
	end

	-- if pointing at an object/entity, punch it with the scythe
	local itemdef = itemstack:get_definition()
	if pointed_thing.type == "object" then
		local tool_capabilities = itemstack:get_tool_capabilities()
		local meta = itemstack:get_meta()
		local last_punch = meta:get_float("last_punch") or 0
		local now = core.get_gametime()
		meta:set_float("last_punch", now)
		pointed_thing.ref:punch(user, now - last_punch, tool_capabilities)
	end

	-- if pointing at something other than a node, don't go further
	if pointed_thing.type ~= "node" then
		return
	end

	-- the scythe group allows us to specify how big the area to harvest should be
	-- if scythe = 2, then the area is a 3x3 area
	-- if scythe = 3, then the area is a 5x5 area
	-- and so on...
	-- this does not correspond to the actual level of the scythe,
	-- unfortunately we need to keep it this way because doing otherwise would break compatibility with
	-- mods that are using the scythe group as provided by the original sickles mod
	-- in short: the value of the scythe group = level of the scythe + 1
	local range = (get_item_group(itemdef, "scythe") or 1) - 1

	-- TODO: is all of the code below really supposed to be executed when pointed_thing.type == "object"?
	-- if not, we should maybe wrap this in an if pointed_thing.type == "node" condition

	-- get the position of the node that the user is pointing at
	local pos = pointed_thing.under

	-- try to harvest (and replant) the node
	local harvested = harvest_and_replant(pos, user)

	-- if it couldn't be harvested, we won't go any further
	if not harvested then
		return
	end

	-- this will be required for wearing tools depending on the number of nodes harvested
	local total_nodes_changed = 1

	-- otherwise we harvest and replant the adjacent nodes within the range specified in the item definition
	if range > 0 then
		local pos1 = vector.add(pos, { x = -range, y = 0, z = -range })
		local pos2 = vector.add(pos, { x = range, y = 0, z = range })
		local positions = core.find_nodes_in_area(pos1, pos2, "group:plant")
		for _, check_pos in ipairs(positions) do
			if pos ~= check_pos then
				if harvest_and_replant(check_pos, user) then
					total_nodes_changed = total_nodes_changed + 1
				end
			end
		end
	end

	-- wear out tools if the player is not in creative mode
	local playername = user and user:get_player_name() or ""
	if not core.is_creative_enabled(playername) then
		if mod_mcl_farming then
			local calc_uses = get_item_group(itemdef, "scythe_uses")
			-- if mineclonia
			if not is_voxelibre then
				calc_uses = mcl_util.calculate_durability(itemstack) or calc_uses
			end
			itemstack:add_wear_by_uses(calc_uses / total_nodes_changed)
		else
			itemstack:add_wear_by_uses(uses / total_nodes_changed)
		end
	end

	-- finally return the worn out scythe
	return itemstack
end

farmtools.register_scythe = function(name, def)
	-- this function is used for registering new scythes in the easiest way possible

	-- register new scythes in your mod's namespace
	if name:sub(1, 1) ~= ":" then
		name = ":" .. name
	end

	-- check definition table
	if def.description == nil then
		def.description = S("Scythe")
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = DEFAULT_SCYTHE_USES
	end
	if def.level == nil then
		def.level = 1
	end
	-- support the definition providing groups, primarily for enchantability for voxelibre
	local groups = { scythe = def.level + 1 }
	if def.groups then
		for k, v in pairs(def.groups) do
			groups[k] = v
		end
	end

	-- now register the tool through the Luanti API
	core.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		tool_capabilities = {
			full_punch_interval = 1.2,
			damage_groups = { fleshy = 5 },
			punch_attack_uses = def.max_uses * 2,
		},
		range = 12,
		on_use = function(itemstack, user, pointed_thing)
			return farmtools.scythe_on_use(itemstack, user, pointed_thing, def.max_uses)
		end,
		groups = groups,
		sound = { breaks = "default_tool_breaks" },
		_mcl_uses = groups["scythe_uses"] or def.max_uses,
	})

	-- now register recipe
	if def.recipe then
		core.register_craft({
			output = name:sub(2),
			recipe = def.recipe,
		})
	elseif def.material then
		core.register_craft({
			output = name:sub(2),
			recipe = {
				{ "", def.material, def.material },
				{ def.material, "", "group:stick" },
				{ "", "", "group:stick" },
			},
		})
	end
end
