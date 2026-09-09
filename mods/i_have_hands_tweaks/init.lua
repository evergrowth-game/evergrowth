-- mods/i_have_hands_tweaks/init.lua
-- Fixes space vacuum placement, nil vector crashes, and altitude bounds in i_have_hands

local data_storage = core.get_mod_storage()
local blacklist = { "shulker", "bedrock" }
local RayDistance = 4
local to_animate = {}
local player_hud_id = {}
local carrying_inv = {}

-- Dynamically unregister legacy i_have_hands globalstep and on_dieplayer
if minetest.registered_globalsteps then
	for i = #minetest.registered_globalsteps, 1, -1 do
		local fn = minetest.registered_globalsteps[i]
		local info = debug.getinfo(fn, "S")
		if info and info.source and (info.source:find("i_have_hands/init%.lua") or info.source:find("i_have_hands[/\\]init%.lua")) then
			table.remove(minetest.registered_globalsteps, i)
		end
	end
end

if minetest.registered_on_dieplayers then
	for i = #minetest.registered_on_dieplayers, 1, -1 do
		local fn = minetest.registered_on_dieplayers[i]
		local info = debug.getinfo(fn, "S")
		if info and info.source and (info.source:find("i_have_hands/init%.lua") or info.source:find("i_have_hands[/\\]init%.lua")) then
			table.remove(minetest.registered_on_dieplayers, i)
		end
	end
end

local function is_empty_or_buildable(pos)
	if not pos then return false end
	local node = core.get_node(pos)
	if node.name == "air" or node.name == "vacuum:vacuum" or node.name == "asteroid:atmos" or node.name == "ignore" then
		return true
	end
	local def = core.registered_nodes[node.name]
	if def and (def.buildable_to or def.drawtype == "airlike" or (def.liquidtype and def.liquidtype ~= "none")) then
		return true
	end
	return false
end

local function find_empty_position(pos, radius)
	if not pos then return nil end
	radius = radius or 3

	for r = 0, radius do
		for a = 0, 360, 30 do
			local dx = math.floor(r * math.cos(math.rad(a)) + 0.5)
			local dz = math.floor(r * math.sin(math.rad(a)) + 0.5)
			for dy = 0, 2 do
				local check_pos = { x = pos.x + dx, y = pos.y + dy, z = pos.z + dz }
				if is_empty_or_buildable(check_pos) then
					return check_pos
				end
			end
			for dy = -1, -2, -1 do
				local check_pos = { x = pos.x + dx, y = pos.y + dy, z = pos.z + dz }
				if is_empty_or_buildable(check_pos) then
					return check_pos
				end
			end
		end
	end

	return { x = math.floor(pos.x + 0.5), y = math.floor(pos.y + 0.5), z = math.floor(pos.z + 0.5) }
end

local function quantize_direction(yaw)
	local angle = math.deg(yaw or 0) % 360
	if angle < 45 or angle >= 315 then
		return math.rad(0)
	elseif angle >= 45 and angle < 135 then
		return math.rad(90)
	elseif angle >= 135 and angle < 225 then
		return math.rad(180)
	else
		return math.rad(270)
	end
end

local function placeDown(placer, rot, obj, above, frame, held_item_name)
	if not obj or not obj:get_luaentity() then return end
	if not above then
		above = placer and placer:get_pos()
	end
	if not above then return end
	above = vector.round(above)

	if placer and placer.set_bone_override then
		placer:set_bone_override("Arm_Right",
			{ rotation = { absolute = false, interpolation = 0, vec = { x = 0, y = 0, z = 0 } } })
		placer:set_bone_override("Arm_Left",
			{ rotation = { absolute = false, interpolation = 0, vec = { x = 0, y = 0, z = 0 } } })
	end
	table.insert(to_animate,
		{ player = placer, rot = rot or 0, obj = obj, pos = above, frame = frame or 0, item = held_item_name })
end

local function animatePlace()
	for i = #to_animate, 1, -1 do
		local v = to_animate[i]
		if not v.pos or not v.obj or not v.obj:get_luaentity() then
			if v.obj then v.obj:remove() end
			if v.ghost then v.ghost:remove() end
			table.remove(to_animate, i)
		else
			if v.frame == 0 then
				v.obj:set_detach()
				v.obj:set_yaw(v.rot or 0)
				local obj_rot = v.obj:get_rotation() or { x = 0, y = 0, z = 0 }
				v.obj:set_properties({ visual_size = { x = 0.65, y = 0.65, z = 0.65 } })

				local ghost = core.add_entity(v.pos, "i_have_hands:ghost")
				if ghost then
					ghost:set_rotation({ x = obj_rot.x, y = obj_rot.y + math.rad(-90), z = obj_rot.z })
					v.obj:set_attach(ghost, "BONE", vector.new(0, 0, 0), vector.new(0, -90, 0))
					ghost:set_animation({ x = 0.40, y = 160 }, 4, 0, false)
					v["ghost"] = ghost
				end
				core.sound_play({ name = "i_have_hands_pickup_node" }, { pos = v.pos, pitch = math.random(7, 12) / 10, gain = 1 }, true)
			end

			if v.frame == 5 then
				local luaent = v.obj:get_luaentity()
				local found_meta = luaent and luaent.initial_pos and data_storage:get_string(luaent.initial_pos) or ""
				if luaent and luaent.initial_pos then
					data_storage:set_string(luaent.initial_pos, "")
				end
				core.set_node(v.pos, { name = v.item, param2 = core.dir_to_fourdir(core.yaw_to_dir(v.rot or 0)) })
				core.sound_play({ name = "i_have_hands_place_down_node" }, { pos = v.pos, pitch = math.random(7, 12) / 10, gain = 1 }, true)
				local node_def = core.registered_nodes[v.item]
				local node_sound = node_def and node_def.sounds and node_def.sounds.place and node_def.sounds.place.name
				if node_sound ~= nil then
					core.sound_play({ name = node_sound }, { pos = v.pos, gain = 1 }, true)
				end
				core.get_node_timer(v.pos):start(1.0)
				local meta = core.get_meta(v.pos)

				if found_meta ~= "" then
					local parsed = core.deserialize(found_meta)
					if parsed and parsed["data"] then
						local node_containers = {}
						for k, val in pairs(parsed["data"]) do
							local found_container = {}
							for container, container_items in pairs(val) do
								local found_inv = {}
								if type(container_items) == "string" then
									found_container[container] = container_items
								else
									for slot, item in pairs(container_items) do
										found_inv[slot] = item
									end
									found_container[container] = found_inv
								end
							end
							node_containers[k] = found_container
						end
						meta:from_table(node_containers)
					end
				end

				if meta:get_int("xp") > 0 then
					meta:set_int("xp", 0)
				end

				if core.get_modpath("drawers") and drawers then
					drawers.spawn_visuals(v.pos)
				end
				if core.get_modpath("pipeworks") and pipeworks then
					pipeworks.after_place(v.pos)
				end
				if string.find(v.item, "mcl_armor_stand") then
					if core.get_modpath("mcl_armor_stand") and core.get_modpath("mcl_armor") and mcl_armor then
						for _, obj in ipairs(minetest.get_objects_inside_radius(v.pos, 0)) do
							local luaentity = obj:get_luaentity()
							if luaentity and luaentity.name == "mcl_armor_stand:armor_entity" then
								mcl_armor.update(luaentity.object)
							end
						end
					end
				end
			end

			v.frame = v.frame + 1
			if v.frame >= 10 then
				if v.obj then v.obj:remove() end
				if v.ghost then v.ghost:remove() end
				v.obj = nil
				table.remove(to_animate, i)
			end
		end
	end
end

local function checkProtection(pos, user)
	if not pos or not user then
		return true
	end
	local protected = core.is_protected(pos, user:get_player_name())
	local meta = core.get_meta(pos)
	local owner = ""
	if meta and meta.get_string then
		owner = meta:get_string("owner")
	end
	local player_name = user:get_player_name()
	if owner ~= "" and owner ~= player_name then
		core.chat_send_player(player_name, core.colorize("pink", "You are not the owner."))
		return true
	end
	if protected then
		core.chat_send_player(player_name, core.colorize("pink", "This is protected"))
		return true
	end
	return false
end

local function isInventory(meta)
	if Allow_all == true then return true end
	if meta == nil then return false end
	local count = 0
	for _, _ in pairs(meta:to_table().inventory) do
		count = count + 1
	end
	return count >= 1
end

local function isBlacklisted(pos)
	local nodename = core.get_node(pos).name
	for _, v in ipairs(blacklist) do
		if utils and utils.StringContains and utils.StringContains(nodename, v) then
			return true
		end
	end
	return false
end

local function isHolding(player)
	for _, obj in ipairs(player:get_children()) do
		local luaent = obj:get_luaentity()
		if luaent and luaent.name == "i_have_hands:held" then
			return true
		end
	end
	return false
end

local function getPlayerHud(player_name)
	for _, ph in ipairs(player_hud_id) do
		if ph.player_name == player_name then
			return ph.player_hud
		end
	end
	return nil
end

local function getPlayerFromPlayerHuds(player_name)
	for _, ph in ipairs(player_hud_id) do
		if ph.player_name == player_name then
			return ph
		end
	end
	return nil
end

local function removePlayerHud(player)
	local hud_id = getPlayerHud(player:get_player_name())
	if hud_id ~= nil then
		player:hud_remove(hud_id)
		for index, ph in ipairs(player_hud_id) do
			if ph.player_name == player:get_player_name() then
				table.remove(player_hud_id, index)
			end
		end
	end
end

local function raycast()
	local players = core.get_connected_players()
	for _, p in ipairs(players) do
		local eye_height = p:get_properties().eye_height or 1.5
		local player_look_dir = p:get_look_dir()
		local ppos = p:get_pos()
		if ppos and player_look_dir then
			local pos = vector.add(ppos, player_look_dir)
			local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
			local new_pos = vector.add(vector.multiply(player_look_dir, RayDistance), player_pos)
			local raycast_result = core.raycast(player_pos, new_pos, false, false):next()
			if isHolding(p) then
				removePlayerHud(p)
			elseif raycast_result and raycast_result.under then
				if isBlacklisted(raycast_result.under) or p:get_wielded_item():get_name() ~= "" then
					removePlayerHud(p)
				elseif isInventory(core.get_meta(raycast_result.under)) then
					local hud_id = getPlayerHud(p:get_player_name())
					local player_with_hud = getPlayerFromPlayerHuds(p:get_player_name())
					if player_with_hud == nil then
						table.insert(player_hud_id, {
							player_name = p:get_player_name(),
							player_hud = hud_id,
							hud_delay = 6,
							chest_location = raycast_result.under
						})
					else
						if player_with_hud.hud_delay == 0 and hud_id == nil then
							hud_id = p:hud_add({
								type = "text",
								position = { x = 0.5, y = 0.6 },
								direction = 0,
								name = "ihh",
								scale = { x = 1, y = 1 },
								text = "carry: crouch & interact",
								number = "0xFFFFFF",
								z_index = 0,
							})
							player_with_hud.player_hud = hud_id
						end
						if player_with_hud.chest_location ~= raycast_result.under then
							removePlayerHud(p)
						end
					end
				else
					removePlayerHud(p)
				end
			else
				removePlayerHud(p)
			end
		end
	end
end

local function hotbarSlotNotEmpty()
	local players = core.get_connected_players()
	for _, p in ipairs(players) do
		if p:get_wielded_item():get_name() ~= "" then
			for _, obj in ipairs(p:get_children()) do
				local luaent = obj:get_luaentity()
				if luaent and luaent.name == "i_have_hands:held" then
					local props = obj:get_properties()
					local item_name = props and props.wield_item
					local held_item_name = item_name and core.registered_nodes[item_name] and core.registered_nodes[item_name].name or item_name
					if held_item_name then
						placeDown(p, 0, obj, find_empty_position(p:get_pos(), 10), 0, held_item_name)
					end
				end
			end
		end
	end
end

local function tickHudDelay()
	for _, h in pairs(player_hud_id) do
		if h.hud_delay > 0 then
			h.hud_delay = h.hud_delay - 1
		end
	end
end

local function getCarryingIndicatorId(player_name)
	for c_i, c_v in ipairs(carrying_inv) do
		if c_v.player_name == player_name then
			return c_i
		end
	end
	return nil
end

local function carryingIndicator()
	local players = core.get_connected_players()
	for _, p in ipairs(players) do
		local player_name = p:get_player_name()
		local is_carying = false
		for _, value in ipairs(p:get_children()) do
			local luaent = value:get_luaentity()
			if luaent and luaent.name == "i_have_hands:held" then
				is_carying = true
			end
		end
		if is_carying then
			if getCarryingIndicatorId(player_name) == nil then
				local hud_id = p:hud_add({
					type = "image",
					position = { x = 0.5, y = 0.6 },
					direction = 0,
					name = "ihh_carry",
					scale = { x = 4.5, y = 4.5 },
					text = "i_have_hands_indicator.png^[opacity:115",
					number = "0xFFFFFF",
					z_index = 0,
				})
				table.insert(carrying_inv, { player_name = player_name, hud_id = hud_id })
			end
		else
			local hud_index = getCarryingIndicatorId(player_name)
			if hud_index ~= nil then
				p:hud_remove(carrying_inv[hud_index].hud_id)
				table.remove(carrying_inv, hud_index)
			end
		end
	end
end

local function hands(itemstack, placer, pointed_thing)
	if not placer or not pointed_thing then return itemstack end
	local sneak = placer.get_player_control and placer:get_player_control()["sneak"]
	if not sneak then return itemstack end

	local contains = false
	if #placer:get_children() > 0 then
		for _, obj in ipairs(placer:get_children()) do
			local luaent = obj:get_luaentity()
			if luaent and luaent.name == "i_have_hands:held" then
				local above = pointed_thing.above
				if above and checkProtection(above, placer) == false then
					contains = true
					local try_inside = pointed_thing.under and core.registered_nodes[core.get_node(pointed_thing.under).name]
					if not is_empty_or_buildable(above) then
						return itemstack
					end
					if #core.get_objects_inside_radius(above, 0.5) > 0 then
						return itemstack
					end
					if try_inside and try_inside.buildable_to == true then
						above = pointed_thing.under
					end

					local props = obj:get_properties()
					local item_name = props and props.wield_item
					local held_item_name = item_name and core.registered_nodes[item_name] and core.registered_nodes[item_name].name or item_name
					if held_item_name then
						local rot = quantize_direction(placer:get_look_horizontal())
						placeDown(placer, rot, obj, above, 0, held_item_name)
					end
				end
			end
		end
	end

	if not contains and pointed_thing.under then
		if isBlacklisted(pointed_thing.under) or checkProtection(pointed_thing.under, placer) then
			return itemstack
		end
		local meta = core.get_meta(pointed_thing.under)
		if not isInventory(meta) then
			return itemstack
		end

		if placer:get_wielded_item():get_name() == "" then
			local rot = quantize_direction(placer:get_look_horizontal())
			local obj = core.add_entity(placer:get_pos(), "i_have_hands:held")
			if obj then
				local under_node = core.get_node(pointed_thing.under)
				obj:set_properties({ wield_item = under_node.name })
				obj:set_attach(placer, "Arm_Right", vector.new(0, 5.5, 0), vector.new(0, 0, 0))

				if placer.set_bone_override then
					placer:set_bone_override("Arm_Right",
						{ rotation = { absolute = true, interpolation = 0, vec = { x = 0, y = 0, z = math.rad(-90) } } })
					placer:set_bone_override("Arm_Left",
						{ rotation = { absolute = true, interpolation = 0, vec = { x = 0, y = 0, z = math.rad(90) } } })
				end

				local node_containers = {}
				for i, v in pairs(meta:to_table()) do
					local found_container = {}
					for container, container_items in pairs(v) do
						local found_inv = {}
						if type(container_items) == "string" then
							found_container[container] = container_items
						else
							for slot, item in pairs(container_items) do
								found_inv[slot] = item:to_string()
							end
							found_container[container] = found_inv
						end
					end
					node_containers[i] = found_container
				end
				local full_data = { node = under_node, data = node_containers }
				local pos_str = vector.to_string(obj:get_pos() or pointed_thing.under)
				data_storage:set_string(pos_str, core.serialize(full_data))
				if obj:get_luaentity() then
					obj:get_luaentity().initial_pos = pos_str
				end

				if string.find(under_node.name, "aom_storage") or string.find(under_node.name, "mcl_armor_stand") then
					core.swap_node(pointed_thing.under, core.registered_nodes["air"])
				else
					core.remove_node(pointed_thing.under)
				end

				core.sound_play({ name = "i_have_hands_pickup_node" },
					{ pos = pointed_thing.under, pitch = math.random(7, 12) / 10, gain = 1 }, true)
				if core.get_modpath("pipeworks") and pipeworks then
					pipeworks.after_place(pointed_thing.under)
				end
			end
		end
	end

	return itemstack
end

-- Override empty hand on_place
local orig_hand_on_place = core.registered_items[""] and core.registered_items[""].on_place
core.override_item("", {
	on_place = function(itemstack, placer, pointed_thing)
		if orig_hand_on_place then
			itemstack = orig_hand_on_place(itemstack, placer, pointed_thing)
		end
		return hands(itemstack, placer, pointed_thing)
	end,
})

-- Hardened globalstep
local tick = 0
minetest.register_globalstep(function(dtime)
	tick = tick + (dtime or 0)
	if tick > 2 then
		animatePlace()
		raycast()
		hotbarSlotNotEmpty()
		tickHudDelay()
		carryingIndicator()
		tick = 0
	end
end)

minetest.register_on_dieplayer(function(ObjectRef, reason)
	if ObjectRef and #ObjectRef:get_children() > 0 then
		for _, obj in ipairs(ObjectRef:get_children()) do
			local luaent = obj:get_luaentity()
			if luaent and luaent.name == "i_have_hands:held" then
				local props = obj:get_properties()
				local item_name = props and props.wield_item
				local held_item_name = item_name and core.registered_nodes[item_name] and core.registered_nodes[item_name].name or item_name
				if held_item_name then
					placeDown(ObjectRef, 0, obj, find_empty_position(ObjectRef:get_pos(), 10), 0, held_item_name)
				end
			end
		end
	end
end)

i_have_hands_tweaks = {
	find_empty_position = find_empty_position,
	is_empty_or_buildable = is_empty_or_buildable,
	placeDown = placeDown,
	animatePlace = animatePlace,
	to_animate = to_animate,
}
