-- this file contains the code that is used by sickles
local mod_mcl_farming = core.get_modpath("mcl_farming") ~= nil

local MAX_ITEM_WEAR = 65535
local DEFAULT_SICKLE_USES = 120

local S = farmtools.i18n

local function get_wielded_item(player)
	-- this function returns the item that the given player is currently holding
	if not core.is_player(player) then
		return
	end
	return player:get_wielded_item()
end

local function get_item_group(def, group)
	if def == nil or def.groups == nil or def.groups[group] == nil then
		return 0
	end
	return def.groups[group]
end

function farmtools.register_cuttable(nodename, base, item)
	-- this function is used for registering items that can be cut with the sickle

	-- first ensure that the give node is actually a registered node
	-- fail otherwise
	local def = core.registered_nodes[nodename]
	if def == nil then
		return
	end

	-- save the default handler of the node when punched
	-- if no handler exists, we save the default Luanti handler
	local default_handler = def.on_punch or core.node_punch

	-- now we override the handler of the node when punched
	-- i.e. the function below will be called every time a node with this name gets punched
	core.override_item(nodename, {
		on_punch = function(pos, node, puncher, pointed_thing)
			-- first we want to ensure that the user is holding a sickle
			local itemstack = get_wielded_item(puncher)

			-- I have no idea if this is possible, but we need to check against nil value
			if itemstack == nil then
				return
			end

			-- if the user is not holding a sickle when punching the node, we won't continue any
			-- futher. instead, we return the default handler that we previously saved.
			-- i.e. the sickle-behavior won't be used
			local itemdef = itemstack:get_definition()
			local level = get_item_group(itemdef, "sickle")
			if level < 1 then
				return default_handler(pos, node, puncher, pointed_thing)
			end

			-- get the name of the player who punched the node
			local pname = puncher:get_player_name()

			-- if the player isn't available to edit the node that was punched,
			-- report the violation and then exit the function
			if core.is_protected(pos, pname) then
				core.record_protection_violation(pos, pname)
				return
			end

			-- give the player the item that is supposed to be returned when the sickle is
			-- used on the given node
			if mod_mcl_farming and item == "sickles:moss" then
				-- for some reason mineclonia does not want to drop moss, so just add to player inventory
				local invref = puncher:get_inventory()
				if invref:room_for_item("main", item) then
					invref:add_item("main", item)
				end
			else
				core.handle_node_drops(pos, { item }, puncher)
			end
			-- replace the node by the node that should be in its place after the sickle is used
			core.after(0, function()
				core.swap_node(pos, { name = base, param2 = node.param2 })
			end)

			-- wear out the sickle if the player is not in creative mode
			if not core.is_creative_enabled(pname) then
				local max_uses = get_item_group(itemdef, "sickle_uses") or DEFAULT_SICKLE_USES
				itemstack:add_wear(math.ceil(MAX_ITEM_WEAR / (max_uses - 1)))
				if itemstack:get_count() == 0 and itemdef.sound and itemdef.sound.breaks then
					core.sound_play(itemdef.sound.breaks, { pos = pos, gain = 0.5 })
				end
				-- finally we set the current wielded item of the player to the sickle used for
				-- punching the node.
				-- I have no idea why we need to do this, but I believe that the original author of the
				-- mod put this here for a reason.
				puncher:set_wielded_item(itemstack)
			end
		end,
	})
end

function farmtools.register_trimmable(node, base)
	-- this function is used for registering items that can be trimmed with the sickle

	-- first ensure that the give node is actually a registered node
	-- fail otherwise
	local def = core.registered_nodes[node]
	if def == nil then
		return
	end

	-- save the default handler of the node when dug
	-- if no handler exists, we save the default Luanti handler
	local handler = def.after_dig_node

	-- now we override the handler of the node when dug
	-- i.e. the function below will be called every time a node with this name gets dug
	core.override_item(node, {
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			-- first we want to ensure that the user is holding a sickle
			local itemstack = get_wielded_item(digger)

			-- I have no idea if this is possible, but we need to check against nil value
			if itemstack == nil then
				return
			end

			-- if the user is not holding a sickle when digging the node, we won't continue any
			-- futher. instead, we return the default handler that we previously saved.
			-- i.e. the sickle-behavior won't be used
			local itemdef = itemstack:get_definition()
			local level = get_item_group(itemdef, "sickle")
			if level < 1 then
				if handler ~= nil then
					return handler(pos, oldnode, oldmetadata, digger)
				else
					return
				end
			end

			-- we save the param2 property of the node that was just dug with the sickle
			local param2 = core.registered_nodes[base].place_param2
			-- and we replace it with the node that is supposed to be in place on the node after
			-- it is trimmed by a sickle
			core.set_node(pos, { name = base, param2 = param2 })
		end,
	})
end

farmtools.register_sickle = function(name, def)
	-- this function is used for registering new scythes in the easiest way possible

	-- register new scythes in your mod's namespace
	if name:sub(1, 1) ~= ":" then
		name = ":" .. name
	end

	-- check definition table
	if def.description == nil then
		def.description = S("Sickle")
	end
	if def.inventory_image == nil then
		def.inventory_image = "unknown_item.png"
	end
	if def.max_uses == nil then
		def.max_uses = DEFAULT_SICKLE_USES
	end
	if def.groupcaps == nil then
		def.groupcaps = {
			snappy = {
				times = {
					[1] = 2.75,
					[2] = 1.30,
					[3] = 0.375,
					uses = def.max_uses / 2,
					maxlevel = 2,
				},
			},
		}
	end
	if def.damage_groups == nil then
		def.damage_groups = { fleshy = 3 }
	end
	-- support the definition providing groups, primarily for enchantability for voxelibre
	local groups = { sickle = 1, sickle_uses = def.max_uses }
	if def.groups then
		for k, v in pairs(def.groups) do
			groups[k] = v
		end
	end

	-- now register the tool through the Luanti API
	--
	core.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		tool_capabilities = {
			full_punch_interval = 0.8,
			max_drop_level = 1,
			groupcaps = def.groupcaps,
			damage_groups = def.damage_groups,
			punch_attack_uses = def.max_uses / 2,
		},
		range = 6,
		groups = groups,
		sound = { breaks = "default_tool_breaks" },
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
				{ def.material, "" },
				{ "", def.material },
				{ "group:stick", "" },
			},
		})
	end
end
