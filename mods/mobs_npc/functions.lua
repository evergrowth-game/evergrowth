
-- translation and mod check

local S = core.get_translator("mobs_npc")
local mcl = core.get_modpath("mcl_core") ~= nil
local def = core.get_modpath("default") ~= nil

-- show random message from list

mobs_npc.npc_talk =  function(self, player, message_list)

	local name = player:get_player_name() or ""
	local messages = message_list or self.messages or {"??"}

	if messages then

		local msg = messages[math.random(#messages)]

		core.chat_send_player(name, "<" .. (self.nametag or "") .. "> " .. msg)
	end
end

-- drop random item from list

mobs_npc.drop_trade = function(self, player, item, item_list)

	local w_inv = player:get_wielded_item()

	if item ~= w_inv:get_name() then return end

	if not mobs.is_creative(player:get_player_name()) then
		w_inv:take_item()
		player:set_wielded_item(w_inv)
	end

	local drop_item = item_list[math.random(#item_list)]
	local drop, chance = drop_item, 1

	if type(drop_item) == "table" then
		drop, chance = drop_item[1], drop_item[2] or 1
	end

	if not core.registered_items[drop] or math.random(chance) > 1 then
		drop = mcl and "mcl_core:clay_lump" or "default:clay_lump"
	end

	local obj = core.add_item(self.object:get_pos(), {name = drop})
	local dir = player:get_look_dir()

	obj:set_velocity({x = -dir.x, y = 1.5, z = -dir.z})

	return true
end

-- check for simple_dialogs mod and setup

local context = {}

mobs_npc.useDialogs = "N"

core.register_on_leaveplayer(function(player)
	context[player:get_player_name()] = nil
end)

if core.get_modpath("simple_dialogs") then

	mobs_npc.useDialogs = "Y"

	simple_dialogs.register_varloader(function(npcself, playername)
		simple_dialogs.save_dialog_var(npcself, "NPCNAME", npcself.nametag, playername)
		simple_dialogs.save_dialog_var(npcself, "STATE", npcself.state, playername)
		simple_dialogs.save_dialog_var(npcself, "FOOD", npcself.food, playername)
		simple_dialogs.save_dialog_var(npcself, "HEALTH", npcself.health, playername)
		simple_dialogs.save_dialog_var(npcself, "owner", npcself.owner, playername)
	end)

	simple_dialogs.register_hook(function(npcself, playername,hook)

		if hook.func == "TELEPORT" then

			if npcself.owner then

				--check to see if the player has 'bring' teleport privliges
				local player_privs = core.get_player_privs(npcself.owner)

				if player_privs["bring"] then

					--validate x,y,z coords
					if hook.parm and hook.parmcount and hook.parmcount > 2 then

						local pos = {
							x = tonumber(hook.parm[1]),
							y = tonumber(hook.parm[2]),
							z = tonumber(hook.parm[3])
						}

						if pos.x and pos.y and pos.z
						and pos.x > -31500 and pos.x < 31500
						and pos.y > -31500 and pos.y < 31500
						and pos.z > -31500 and pos.z < 31500 then

							local player = core.get_player_by_name(playername)

							if player then
								player:set_pos(pos) end
						end
					end
				end
			end
			return "EXIT"
		end
	end)
end

-- Kilarin's formspec functions

function mobs_npc.get_controls_formspec(name, self)

	self.id = set_npc_id(self) -- make sure id is set

	local npcId = self.id
	local orderArray = {wander = 1, stand = 2, follow = 3}
	local currentorderidx = orderArray[self.order] or 1

	-- Make npc controls formspec
	local text = "NPC Controls"
	local size = mobs_npc.useDialogs == "Y" and "size[15,10]" or "size[3.85,2.8]"
	local formspec = {
		size,
		"label[0.375,0.5;", core.formspec_escape(text), "]",
		"dropdown[0.375,1.25; 3,0.6;ordermode;wander,stand,follow;", currentorderidx, "]",
		"button[0.375,2;3,0.8;exit;Exit]"
	}

	if mobs_npc.useDialogs == "Y" then
		simple_dialogs.add_dialog_control_to_formspec(name, self, formspec, 0.375, 3.4)
	end

	--store npc id in local context so we can use it when the form is returned
	context[name] = npcId

	return table.concat(formspec, "")
end

-- receive and do orders given through form

core.register_on_player_receive_fields(function(player, formname, fields)

	local pname = player:get_player_name()

	if formname ~= "mobs_npc:controls" then
		context[pname] = nil ; return
	end

	local npcId = context[pname] --get the npc id from local context
	local npcself = get_npcself_from_id(npcId)

	if not npcself then return end

	if fields["exit"] then

		core.close_formspec(pname, "mobs_npc:controls")

	elseif fields["ordermode"] then

		local pname = player:get_player_name()

		npcself.order = fields["ordermode"]

		if npcself.order == "wander" then
--			core.chat_send_player(pname, S("NPC will wander."))
		elseif npcself.order == "follow" then
--			core.chat_send_player(pname, S("NPC will follow you."))
		elseif npcself.order == "stand" then
--			core.chat_send_player(pname, S("NPC stands still."))

			npcself.state = "stand"
			npcself.attack = nil
			npcself:set_animation("stand")
			npcself:set_velocity(0)
		end
	end

	if mobs_npc.useDialogs == "Y" then
		simple_dialogs.process_simple_dialog_control_fields(pname, npcself, fields)
	end
end)

-- check if npc has id set otherwise create one

function set_npc_id(npcself)

	if not npcself.id then
		npcself.id = (math.random(1, 1000) * math.random(1, 10000))
			.. npcself.name .. (math.random(1, 1000) ^ 2)
	end

	return npcself.id
end

--this function finds an npcself in the luaentities list given an npcId

function get_npcself_from_id(npcId)

	if not npcId then return end

	for k, v in pairs(core.luaentities) do

		if v.object and v.id == npcId then
			return v
		end
	end
end

--This code comes almost exclusively from the trader and inventory of mobf, by Sapier.
--The copyright notice below is from mobf:
-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file inventory.lua
--! @brief component containing mob inventory related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-02
--
--! @defgroup Inventory Inventory subcomponent
--! @brief Component handling mob inventory
--! @ingroup framework_int
--! @{
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

-- Trades are saved in entity metadata so they always stay the same after
-- initially being chosen.  Also the formspec uses item image buttons instead of
-- inventory slots.  New trade generation by TenPlus1 using Fischer-Yates shuffle.

local function add_goods(self, race)

	local items = race.items
	local item_count = #items
	local trader_pool_size = math.min(10, item_count)

	self.trades = {}

	if not items or item_count == 0 then return end

	-- found the Fisher-Yates shuffle handy to randomize everything

	local indices = {}

	for i = 1, item_count do
		indices[i] = i
	end

	for i = item_count, 2, -1 do

		local j = math.random(1, i)

		indices[i], indices[j] = indices[j], indices[i]
	end

	local trade_index = 1

	for i = 1, trader_pool_size do

		local item = items[ indices[i] ]
		local name, price, rarity = item[1], item[2], item[3]

		-- make sure first 3 items always appear on list, then random chance it
		local can_add = trade_index <= 3 or math.random(100) > rarity

		if can_add then

			self.trades[trade_index] = {name, price}

			trade_index = trade_index + 1
		end
	end
end

function mobs_npc.shop_trade(self, clicker, race)

	self.id = set_npc_id(self) -- make sure id is set

	if not self.game_name then

		self.game_name = tostring(race.names[math.random(1, #race.names)])
		self.nametag = S("Trader @1", self.game_name)
		self.object:set_properties({nametag = self.nametag, nametag_color = "#00FF00"})
	end

	if not self.trades then
		add_goods(self, race)
	end

	local player = clicker:get_player_name() or ""

	core.chat_send_player(player,
		S("[NPC] <Trader @1> Hello, @2, have a look at my wares.",
		self.game_name, player))

	-- Make formspec trade list
	local formspec_trade_list = ""
	local x, y

	for i = 1, 10 do

		if self.trades[i] and self.trades[i] ~= "" then

			if i < 6 then
				x = mcl and 1 or 0.5
				y = i - 0.5
			else
				x = mcl and 5 or 4.5
				y = i - 5.5
			end

			formspec_trade_list = formspec_trade_list
			.. "item_image_button[".. x ..",".. y ..";1,1;"
				.. self.trades[i][2] .. ";prices#".. i .."#".. self.id ..";]"
			.. "item_image_button[".. x + 2 ..",".. y ..";1,1;"
				.. self.trades[i][1] .. ";goods#".. i .."#".. self.id ..";]"
			.. "image[".. x + 1 ..",".. y ..";1,1;gui_arrow_blank.png]"
		end
	end

	local bg = mcl and mcl_vars.gui_bg_img or default.gui_bg_img or ""
	local sl = mcl and mcl_vars.gui_slots or default.gui_slots or ""
	local lc = mcl and "listcolors[#9d9d9d;#FFF7;#474747]" or ""

	core.show_formspec(player, "mobs_npc:trade", "size[" .. (mcl and 9 or 8) .. ",10]"
		.. bg
		.. sl
		.. "label[0.5,-0.1;" .. S("Trader @1's stock:", self.game_name) .. "]"
		.. formspec_trade_list
		.. lc
		.. "list[current_player;main;0,6;" .. (mcl and 9 or 8) .. ",4;]"
	)
end


core.register_on_player_receive_fields(function(player, formname, fields)

	if formname ~= "mobs_npc:trade" then return end

	if fields then

		local trade = ""

		for k, v in pairs(fields) do
			trade = tostring(k)
		end

		local id = trade:split("#")[3]
		local self = nil

		if id ~= nil then

			for k, v in pairs(core.luaentities) do

				if v.object and v.id == id then
					self = v ; break
				end
			end
		end

		if self then

			local trade_number = tonumber(trade:split("#")[2])

			if trade_number and self.trades[trade_number] then

				local price = self.trades[trade_number][2]
				local goods = self.trades[trade_number][1]
				local inv = player:get_inventory()

				if inv:contains_item("main", price) then

					inv:remove_item("main", price)

					local leftover = inv:add_item("main", goods)

					if leftover:get_count() > 0 then

						-- drop item(s) in front of player
						local droppos = player:get_pos()
						local dir = player:get_look_dir()

						droppos.x = droppos.x + dir.x
						droppos.z = droppos.z + dir.z

						core.add_item(droppos, leftover)
					end
				end
			end
		end
	end
end)
