--[[

	Signs Bot
	=========

	Copyright (C) 2019-2021 Joachim Stolberg

	GPLv3
	See LICENSE.txt for more information

	Signs Bot: Ingame Documentation (Integrated into Industry & Automation manual)

]]--

local S = signs_bot.S

signs_bot.doc = {}

if not minetest.get_modpath("doc") then
	return
end

local start_doc = table.concat({
	S("After you have placed the Signs Bot Box, you can start the bot by means of the 'On' button in the box menu."),
	S("If the bot returns to its box right away, you will likely need to charge it with electrical energy (techage) first."),
	S("The bot then runs straight up until it reaches an obstacle (a step with two or more blocks up or down or a sign.)"),
	S("If the bot first reaches a sign it will execute the commands on the sign."),
	S("If the command(s) on the sign is e.g. 'turn_around', the bot turns and goes back."),
	S("In this case, the bot reaches his box again and turns off."),
	"",
	S("The Signs Bot Box has an inventory with 6 stacks for signs and 8 stacks for other items (to be placed/dug by the bot)."),
	S("This inventory simulates the bot internal inventory."),
	S("That means you will only have access to the inventory if the bot is turned off ('sitting' in his box)."),
}, "\n")

local control_doc = table.concat({
	S("You simply control the direction of the bot by means of the 'turn left' and 'turn right' signs (signs with the arrow)."),
	S("The bot can run over steps (one block up/down). But there are also commands to move the bot up and down."),
	"",
	S("It is not necessary to mark a way back to the box."),
	S("With the command 'turn_off' the bot will turn off and be back in his box from every position."),
	S("The same applies if you turn off the bot by the box menu."),
	S("If the bot reaches a sign from the wrong direction (from back or sides) the sign will be ignored."),
	S("The bot will walk over."),
	"",
	S("All predefined signs have a menu with a list of the bot commands."),
	S("These signs can't be changed, but you can craft and program your own signs."),
	S("For this you have to use the 'command' sign."),
	S("This sign has an edit field for your commands and a help page with all available commands."),
	S("The help page has a copy button to simplify the programming."),
	"",
	S("Also for your own signs it is important to know:"),
	S("After the execution of the last command of the sign, the bot falls back into its default behaviour and runs in its taken direction."),
	"",
	S("A standard job for the bot is to move items from one chest to another"),
	S("(chest or node with a chest like inventory)."),
	S("This can be done by means of the two signs 'take item' and 'add item'."),
	S("These signs have to be placed on top of chest nodes."),
}, "\n")

local sensor_doc = table.concat({
	S("In addition to the signs the bot can be controlled by means of sensors."),
	S("Sensors like the Bot Sensor have two states: on and off."),
	S("If the Bot Sensor detects a bot it will switch to the state 'on' and"),
	S("sends a signal to a connected block, called an actuator."),
	"",
	S("Sensors are:"),
	S("- Bot Sensor: Sends a signal when the robot passes by"),
	S("- Node Sensor: Sends a signal when it detects any node"),
	S("- Crop Sensor: Sends a signal when, for example wheat is fully grown"),
	S("- Bot Chest: Sends a signal depending on the chest state (empty, full)"),
	"",
	S("Actuators are:"),
	S("- Signs Bot Box: Can turn the bot off and on"),
	S("- Control Unit: Can be used to exchange the sign to lead the bot"),
	"",
	S("Additional sensors and actuator can be added by other mods."),
}, "\n")

local tool_doc = table.concat({
	S("To send a signal from a sensor to an actuator, the sensor has to be connected (paired) with actuator."),
	S("To connect sensor and actuator, the Sensor Connection Tool has to be used."),
	S("Simply click with the tool on both blocks and the sensor will be connected with the actuator."),
	S("A successful connection is indicated by a ping/pong noise."),
	"",
	S("Before you connect sensor with actuator, take care that the actuator is in the requested state."),
	S("For example: If you want to start the Bot with a sensor, connect the sensor with the Bot Box,"),
	S("when the Bot is in the state 'on'. Otherwise the sensor signal will stop the Bot,"),
	S("instead of starting it."),
}, "\n")

local inventory_doc = table.concat({
	S("The following applies to all commands that are used to place items in the bot inventory, like:"),
	"",
	S("- take_item <num> <slot>"),
	S("- pickup_items <slot>"),
	S("- trash_sign <slot>"),
	S("- harvest <slot>"),
	S("- dig_front <slot> <lvl>"),
	S("- dig_left <slot> <lvl>"),
	S("- dig_right <slot> <lvl>"),
	S("- dig_below <slot> <lvl>"),
	S("- dig_above <slot> <lvl>"),
	"",
	S("If no slot or slot 0 was specified with the command (case A), all 8 slots of the bot inventory "),
	S("are checked one after the other. If a slot was specified (case B), only this slot is checked."),
	S("In both cases the following applies: If the slot is preconfigured and fits the item, "),
	S("or if the slot is not configured and empty, or is only partially filled with the item type "),
	S("(which should be added), then the items are added."),
	S("If not all items can be added, the remaining slots will be tried out in case A."),
	S("Anything that could not be added to your own inventory goes back."),
	"",
	S("The following applies to all commands that are used to take items from the bot inventory, like:"),
	"",
	S("- add_item <num> <slot>"),
	"",
	S("It doesn't matter whether a slot is configured or not. The bot takes the first stack that "),
	S("it can find from its own inventory and tries to use it."),
	S("If a slot is specified, it only takes this, if no slot has been specified, it checks all of "),
	S("them one after the other, starting from slot 1 until it finds something."),
	S("If the number found is smaller than requested, he tries to take the rest out of any slot."),
}, "\n")

minetest.register_on_mods_loaded(function()
	if not doc.get_category_definition("techage_industry") then
		return
	end

	doc.add_entry("techage_industry", "signs_bot_overview", {
		name = "Signs Bot: Getting Started",
		data = {
			text = start_doc,
			images = {
				{ image = "signs_bot:box", imagetype = "item", caption = "Signs Bot Box" },
			},
		},
	})

	doc.add_entry("techage_industry", "signs_bot_control", {
		name = "Signs Bot: Programming & Signs",
		data = {
			text = control_doc,
			images = {
				{ image = "signs_bot:sign_command", imagetype = "item", caption = "Command Sign" },
				{ image = "signs_bot:sign_right", imagetype = "item", caption = "Turn Right" },
				{ image = "signs_bot:sign_left", imagetype = "item", caption = "Turn Left" },
			},
		},
	})

	doc.add_entry("techage_industry", "signs_bot_sensors", {
		name = "Signs Bot: Sensors & Actuators",
		data = {
			text = sensor_doc .. "\n\n" .. tool_doc,
			images = {
				{ image = "signs_bot:sensor_tool", imagetype = "item", caption = "Connection Tool" },
				{ image = "signs_bot:bot_sensor", imagetype = "item", caption = "Bot Sensor" },
			},
		},
	})

	doc.add_entry("techage_industry", "signs_bot_inventory", {
		name = "Signs Bot: Inventory Logic",
		data = {
			text = inventory_doc,
			images = {
				{ image = "signs_bot:box", imagetype = "item", caption = "Signs Bot Box" },
			},
		},
	})
end)
