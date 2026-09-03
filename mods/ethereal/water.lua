
local S = core.get_translator("ethereal")
local get_node = core.get_node

-- Thin Ice

local math_random = math.random

core.register_node("ethereal:thin_ice", {
	description = S("Thin Ice"),
	tiles = {"default_ice.png^[opacity:80"},
	inventory_image = "default_ice.png^[opacity:80",
	wield_image = "default_ice.png^[opacity:80",
	use_texture_alpha = "blend",
	is_ground_content = false,
	paramtype = "light",
	drawtype = "nodebox",
	drop = {},
	node_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}},
	groups = {cracky = 3, crumbly = 3, cools_lava = 1, slippery = 3},
	sounds = default.node_sound_glass_defaults(),

	on_walk_over = function(pos, node, player)

		if math_random(13) == 1 then -- ice breaks if player unlucky

			core.sound_play("default_ice_dug",
					{pos = pos, gain = 0.5, pitch = 1.4, max_hear_distance = 5}, true)

			core.remove_node(pos)
		end
	end
})

-- Ice Brick

core.register_node("ethereal:icebrick", {
	description = S("Ice Brick"),
	tiles = {"ethereal_brick_ice.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {cracky = 3, puts_out_fire = 1, cools_lava = 1, slippery = 3},
	sounds = default.node_sound_glass_defaults()
})

core.register_craft({
	output = "ethereal:icebrick 4",
	recipe = {
		{"default:ice", "default:ice"},
		{"default:ice", "default:ice"}
	}
})

-- Snow Brick

core.register_node("ethereal:snowbrick", {
	description = S("Snow Brick"),
	tiles = {"ethereal_brick_snow.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {crumbly = 3, puts_out_fire = 1, cools_lava = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
		dug = {name = "default_snow_footstep", gain = 0.2},
		dig = {name = "default_snow_footstep", gain = 0.2}
	})
})

core.register_craft({
	output = "ethereal:snowbrick 4",
	recipe = {
		{"default:snowblock", "default:snowblock"},
		{"default:snowblock", "default:snowblock"}
	}
})

-- If Crystal Spike or Snowblock near Water, change Water to Ice

core.register_abm({
	label = "Ethereal freeze water",
	nodenames = {"ethereal:crystal_spike", "default:snowblock", "ethereal:snowbrick"},
	neighbors = {"default:water_source", "default:river_water_source"},
	interval = 17,
	chance = 10,
	catch_up = false,

	action = function(pos, node)

		local near = core.find_node_near(pos, 1,
				{"default:water_source", "default:river_water_source"})

		if near then
			core.swap_node(near, {name = "default:ice"})
		end
	end
})

core.register_abm({
	label = "Ethereal thin ice",
	nodenames = {"default:snow"},
	neighbors = {"default:water_source", "default:river_water_source"},
	interval = 16,
	chance =  8,
	catch_up = false,

	action = function(pos, node)

		local near = core.find_node_near(pos, 1,
				{"default:water_source", "default:river_water_source"})

		if near then

			near.y = near.y + 1

			if get_node(near).name == "air" then
				core.swap_node(near, {name = "ethereal:thin_ice"})
			end
		end
	end
})

-- If Heat Source near Ice or Snow then melt.

local melts = {
	["default:ice"] = "source",
	["default:snowblock"] = "source",
	["ethereal:icebrick"] = "source",
	["ethereal:snowbrick"] = "source",
	["default:snow"] = "flowing",
	["ethereal:thin_ice"] = "flowing",
	["default:dirt_with_snow"] = "default:dirt_with_grass"
}

core.register_abm({
	label = "Ethereal melt snow/ice",
	nodenames = {
		"default:ice", "default:snowblock", "default:snow", "ethereal:thin_ice",
		"default:dirt_with_snow", "ethereal:snowbrick", "ethereal:icebrick"
	},
	neighbors = {
		"fire:basic_flame", "default:lava_source", "default:lava_flowing",
		"default:furnace_active", "default:torch", "default:torch_wall",
		"default:torch_ceiling", "fire:permanent_flame"
	},
	interval = 7,
	chance = 4,
	catch_up = false,

	action = function(pos, node)

		local ret = melts[node.name] ; if not ret then return end
		local new_node

		if #ret < 8 then

			local water = pos.y > 2 and "default:river_water" or "default:water"

			new_node = water .. "_" .. ret
		else
			new_node = ret
		end

		core.swap_node(pos, {name = new_node})

		ethereal.check_falling(pos)
	end
})


-- If Water Source near Dry Dirt, change to normal Dirt

local dry_to_wet = {
	["ethereal:dry_dirt"] = "default:dirt",
	["default:dry_dirt"] = "default:dirt",
	["default:dirt_with_dry_grass"] = "default:dirt_with_grass",
	["default:dry_dirt_with_dry_grass"] = "default:dirt_with_dry_grass",
}

core.register_abm({
	label = "Ethereal wet dry dirt",
	nodenames = {
		"ethereal:dry_dirt", "default:dirt_with_dry_grass",
		"default:dry_dirt", "default:dry_dirt_with_dry_grass"
	},
	neighbors = {"group:water"},
	interval = 15,
	chance = 3,
	catch_up = false,

	action = function(pos, node)

		local new = dry_to_wet[node.name]

		if new then core.swap_node(pos, {name = new}) end
	end
})

-- when enabled, override torches so they drop when touching water

if ethereal.torchdrop and not core.get_modpath("real_torch") then

	local function on_flood(pos, oldnode, newnode)

		core.add_item(pos, ItemStack("default:torch"))

		local def = core.registered_items[newnode.name]

		if def and def.groups and def.groups.water and def.groups.water > 0 then

			core.sound_play("default_cool_lava",
					{pos = pos, max_hear_distance = 10, gain = 0.1}, true)
		end

		return false -- remove node
	end

	local function torch_override(name)
		core.override_item("default:" .. name, {on_flood = on_flood})
	end

	torch_override("torch")
	torch_override("torch_wall")
	torch_override("torch_ceiling")
end

-- magical water

minetest.register_node("ethereal:magical_water", {
	description = S("Magical Water"),
	drawtype = "liquid",
	tiles = {
		{
			name = "default_river_water_source_animated.png^[brighten",
			backface_culling = false,
			animation = {
				type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0,
			}
		},
		{
			name = "default_river_water_source_animated.png^[brighten",
			backface_culling = true,
			animation = {
				type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0,
			}
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1, damage_per_second = -1,
	liquidtype = "source",
	liquid_alternative_flowing = "ethereal:magical_water",
	liquid_alternative_source = "ethereal:magical_water",
	liquid_viscosity = 1,
	liquid_renewable = false,
	liquid_range = 0,
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	groups = {water = 3, liquid = 3, cools_lava = 1, not_in_creative_inventory = 1},
	sounds = default.node_sound_water_defaults(),
})
