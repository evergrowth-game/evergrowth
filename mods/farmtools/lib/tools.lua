local is_farming_redo = core.get_modpath("farming") ~= nil and farming ~= nil and farming.mod == "redo"
local mod_moreores = core.get_modpath("moreores") ~= nil
local mod_mcl_core = core.get_modpath("mcl_core") ~= nil
local mod_mcl_tools = core.get_modpath("mcl_tools") ~= nil
local is_voxelibre = mod_mcl_tools and (mcl_tools == nil)
local mod_mcl_emerald_stuff = core.get_modpath("mcl_emerald_stuff") ~= nil

local S = farmtools.i18n

if mod_mcl_core then
	-- do not depend on mcl_copper_stuff. Just add this regardless.
	core.register_tool("farmtools:sickle_copper", {
		description = S("Copper Sickle"),
		inventory_image = "sickles_sickle_bronze.png",
		tool_capabilities = {
			full_punch_interval = 0.8,
			max_drop_level = 1,
			groupcaps = {
				snappy = { times = { [1] = 2.75, [2] = 1.30, [3] = 0.375 }, uses = 100, maxlevel = 2 },
			},
			damage_groups = { fleshy = 3 },
			punch_attack_uses = 100,
		},
		range = 6,
		_mcl_uses = 200,
		groups = { sickle = 1, sickle_uses = 200, enchantability = 5, tool = 1 },
		sound = { breaks = "default_tool_breaks" },
	})

	core.register_craft({
		output = "farmtools:sickle_copper",
		recipe = {
			{ "mcl_copper:copper_ingot", "" },
			{ "", "mcl_copper:copper_ingot" },
			{ "group:stick", "" },
		},
	})

	core.register_tool("farmtools:scythe_copper", {
		description = S("Copper Scythe"),
		_doc_items_longdesc = "Works only on completely grown crops, or as a weapon.",
		inventory_image = "sickles_scythe_bronze.png",
		tool_capabilities = {
			full_punch_interval = 1.2,
			damage_groups = { fleshy = 5 },
			punch_attack_uses = 200,
		},
		range = 12,
		on_use = farmtools.scythe_on_use,
		_mcl_uses = 150,
		--groups = { scythe = 2, scythe_uses = 100},
		groups = { enchantability = 9, tool = 1, scythe = 2, scythe_uses = 150 },
		sound = { breaks = "default_tool_breaks" },
		_mcl_toollike_wield = true,
		_mcl_diggroups = {},
	})

	core.register_craft({
		output = "farmtools:scythe_copper",
		recipe = {
			{ "", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
			{ "mcl_copper:copper_ingot", "", "group:stick" },
			{ "", "", "group:stick" },
		},
	})

	core.register_tool("farmtools:rake_copper", {
		description = S("Copper Rake"),
		_doc_items_longdesc = "Works as a hoe on a small radius, to prepare dirt for farming.",
		inventory_image = "farmtools_rake_bronze.png",
		tool_capabilities = {
			full_punch_interval = 1.2,
			damage_groups = { fleshy = 4 },
			punch_attack_uses = 200,
		},
		range = 12,
		on_use = farmtools.rake_on_use,
		_mcl_uses = 550,
		groups = { enchantability = 9, tool = 1, rake = 2, rake_uses = 550 },
		sound = { breaks = "default_tool_breaks" },
		_mcl_toollike_wield = true,
		_mcl_diggroups = {},
	})

	core.register_craft({
		output = "farmtools:rake_copper",
		recipe = {
			{ "mcl_copper:copper_ingot", "mcl_copper:copper_ingot", "mcl_copper:copper_ingot" },
			{ "mcl_copper:copper_ingot", "group:stick", "mcl_copper:copper_ingot" },
			{ "", "group:stick", "" },
		},
	})

	-- begin emerald tools
	if mod_mcl_emerald_stuff then
		core.register_tool("farmtools:sickle_emerald", {
			description = S("Emerald Sickle"),
			inventory_image = "farmtools_sickle_emerald.png",
			tool_capabilities = {
				full_punch_interval = 0.8,
				max_drop_level = 1,
				groupcaps = {
					snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 350, maxlevel = 3 },
				},
				damage_groups = { fleshy = 4 },
				punch_attack_uses = 350,
			},
			range = 6,
			_mcl_uses = 350,
			groups = { sickle = 1, sickle_uses = 350, enchantability = 11, tool = 1 },
			sound = { breaks = "default_tool_breaks" },
		})

		core.register_craft({
			output = "farmtools:sickle_emerald",
			recipe = {
				{ "mcl_core:emerald", "" },
				{ "", "mcl_core:emerald" },
				{ "group:stick", "" },
			},
		})

		core.register_tool("farmtools:scythe_emerald", {
			description = S("Emerald Scythe"),
			_doc_items_longdesc = "Works only on completely grown crops, or as a weapon.",
			inventory_image = "farmtools_scythe_emerald.png",
			tool_capabilities = {
				full_punch_interval = 1.2,
				damage_groups = { fleshy = 5 },
				punch_attack_uses = 600,
			},
			range = 12,
			on_use = farmtools.scythe_on_use,
			_mcl_uses = 600,
			groups = { enchantability = 12, tool = 1, scythe = 2, scythe_uses = 600 },
			sound = { breaks = "default_tool_breaks" },
			_mcl_toollike_wield = true,
			_mcl_diggroups = {},
		})

		core.register_craft({
			output = "farmtools:scythe_emerald",
			recipe = {
				{ "", "mcl_core:emerald", "mcl_core:emerald" },
				{ "mcl_core:emerald", "", "group:stick" },
				{ "", "", "group:stick" },
			},
		})

		core.register_tool("farmtools:rake_emerald", {
			description = S("Emerald Rake"),
			_doc_items_longdesc = "Works as a hoe on a small radius, to prepare dirt for farming.",
			inventory_image = "farmtools_rake_emerald.png",
			tool_capabilities = {
				full_punch_interval = 1.2,
				damage_groups = { fleshy = 5 },
				punch_attack_uses = 600,
			},
			range = 12,
			on_use = farmtools.rake_on_use,
			_mcl_uses = 950,
			groups = { enchantability = 12, tool = 1, rake = 2, rake_uses = 950 },
			sound = { breaks = "default_tool_breaks" },
			_mcl_toollike_wield = true,
			_mcl_diggroups = {},
		})

		core.register_craft({
			output = "farmtools:rake_emerald",
			recipe = {
				{ "mcl_core:emerald", "mcl_core:emerald", "mcl_core:emerald" },
				{ "mcl_core:emerald", "group:stick", "mcl_core:emerald" },
				{ "", "group:stick", "" },
			},
		})
	end
	-- end emerald stuff

	if mod_mcl_tools then
		if is_voxelibre then
			-- voxelibre does not have a nice add_to_sets(), and we cannot just use the base definitions for MTG.
			farmtools.register_scythe("farmtools:scythe_iron", {
				description = S("Iron Scythe"),
				inventory_image = "sickles_scythe_steel.png",
				level = 1,
				max_uses = 500,
				material = "mcl_core:iron_ingot",
				_mcl_toollike_wield = true,
				groups = { enchantability = 9, tool = 1, scythe = 2, scythe_uses = 150 },
			})

			farmtools.register_scythe("farmtools:scythe_diamond", {
				description = S("Diamond Scythe"),
				inventory_image = "farmtools_scythe_diamond.png",
				level = 1,
				max_uses = 850,
				material = "mcl_core:diamond",
				groups = { enchantability = 12, tool = 1, scythe = 2, scythe_uses = 850 },
			})

			farmtools.register_rake("farmtools:rake_iron", {
				description = S("Iron Rake"),
				inventory_image = "farmtools_rake_steel.png",
				max_uses = 500,
				level = 1,
				material = "mcl_core:iron_ingot",
				groups = { enchantability = 10, tool = 1, rake = 2, rake_uses = 500 },
			})

			farmtools.register_rake("farmtools:rake_diamond", {
				description = S("Diamond Rake"),
				inventory_image = "farmtools_rake_diamond.png",
				max_uses = 850,
				level = 1,
				material = "mcl_core:diamond",
				groups = { enchantability = 12, tool = 1, rake = 2, rake_uses = 850 },
			})

			farmtools.register_sickle("farmtools:sickle_iron", {
				description = S("Iron Sickle"),
				inventory_image = "sickles_sickle_steel.png",
				max_uses = 300,
				material = "mcl_core:iron_ingot",
				damage_groups = { fleshy = 3 },
				groupcaps = {
					snappy = { times = { [1] = 2.5, [2] = 1.20, [3] = 0.35 }, uses = 150, maxlevel = 2 },
				},
				groups = { enchantability = 7, tool = 1, sickle = 1, sickle_uses = 300 },
			})

			farmtools.register_sickle("farmtools:sickle_gold", {
				description = S("Golden Sickle"),
				inventory_image = "sickles_sickle_gold.png",
				max_uses = 160,
				material = "mcl_core:gold_ingot",
				damage_groups = { fleshy = 2 },
				groupcaps = {
					snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 80, maxlevel = 3 },
				},
				groups = { enchantability = 11, tool = 1, sickle = 1, sickle_uses = 160 },
			})

			farmtools.register_sickle("farmtools:sickle_diamond", {
				description = S("Diamond Sickle"),
				inventory_image = "farmtools_sickle_diamond.png",
				max_uses = 400,
				material = "mcl_core:diamond",
				damage_groups = { fleshy = 4 },
				groupcaps = {
					snappy = { times = { [1] = 1.75, [2] = 0.8, [3] = 0.25 }, uses = 200, maxlevel = 3 },
				},
				groups = { enchantability = 11, tool = 1, sickle = 1, sickle_uses = 300 },
			})
		else -- if is_voxelibre
			-- mineclonia api
			mcl_tools.add_to_sets("sickle", {
				longdesc = S("Cut complete grains (e.g., wheat) down to growth level 3 immediately when harvesting."),
				usagehelp = "When you harvest a fully-grown grain, it will get replanted to level 3, so you do not have to replant and also do not have to wait from a freshly planted seed.",
				groups = {},
				diggroups = {},
				craft_shapes = {
					{
						{ "material", "" },
						{ "", "material" },
						{ "group:stick", "" },
					},
				},
			}, {
				["iron"] = {
					description = S("Iron sickle"),
					inventory_image = "sickles_sickle_steel.png",
					tool_capabilities = {
						full_punch_interval = 0.8,
						max_drop_level = 1,
						groupcaps = {
							snappy = { times = { [1] = 2.5, [2] = 1.20, [3] = 0.35 }, uses = 150, maxlevel = 2 },
						},
						damage_groups = { fleshy = 3 },
						-- this is ignored by mineclonia because mcl already scales punch-uses of different materials.
						-- i.e., iron is strong, and gold is very weak
						punch_attack_uses = 150,
					},
					_mcl_uses = 300,
					-- use half enchantability from mcl_tools/lib/tools.lua
					groups = { enchantability = 7, tool = 1, sickle = 1, sickle_uses = 300 },
				},
				["gold"] = {
					description = S("Gold sickle"),
					inventory_image = "sickles_sickle_gold.png",
					tool_capabilities = {
						full_punch_interval = 0.8,
						max_drop_level = 1,
						groupcaps = {
							snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 80, maxlevel = 3 },
						},
						damage_groups = { fleshy = 2 },
						punch_attack_uses = 80,
					},
					_mcl_uses = 160,
					groups = { enchantability = 11, tool = 1, sickle = 1, sickle_uses = 160 },
				},
				["diamond"] = {
					description = S("Diamond sickle"),
					inventory_image = "farmtools_sickle_diamond.png",
					tool_capabilities = {
						full_punch_interval = 0.8,
						max_drop_level = 1,
						groupcaps = {
							snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 300, maxlevel = 3 },
						},
						damage_groups = { fleshy = 4 },
						punch_attack_uses = 300,
					},
					_mcl_uses = 300,
					groups = { enchantability = 11, tool = 1, sickle = 1, sickle_uses = 300 },
					_mcl_upgradable = true,
					_mcl_upgrade_item = "farmtools:sickle_netherite"
				},
				["netherite"] = {
					description = S("Netherite sickle"),
					inventory_image = "farmtools_sickle_netherite.png",
					tool_capabilities = {
						full_punch_interval = 0.8,
						max_drop_level = 1,
						groupcaps = {
							snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 400, maxlevel = 3 },
						},
						damage_groups = { fleshy = 5 },
						punch_attack_uses = 400,
					},
					_mcl_uses = 400,
					groups = { enchantability = 11, tool = 1, sickle = 1, sickle_uses = 400 },
				},
			}, {
				range = 6,
				sound = { breaks = "default_tool_breaks" },
			})

			mcl_tools.add_to_sets("rake", {
				logdesc = S("Prepares ground for farming, in a larger radius than a hoe."),
				usagehelp = "Use on the center of the 3x3 block. It will turn the same-elevation dirt into farming soil in that 3x3 square.",
				groups = {},
				diggroups = {},
				craft_shapes = {
					{
						{ "material", "material", "material" },
						{ "material", "group:stick", "material" },
						{ "", "group:stick", "" },
					},
				},
			}, {
				["iron"] = {
					description = S("Iron rake"),
					inventory_image = "farmtools_rake_steel.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 4 },
						punch_attack_uses = 300,
					},
					_mcl_uses = 500,
					-- 2/3 of full iron set enchantability
					groups = { enchantability = 10, tool = 1, rake = 2, rake_uses = 500 },
				},
				["diamond"] = {
					description = S("Diamond rake"),
					inventory_image = "farmtools_rake_diamond.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 5 },
						punch_attack_uses = 500,
					},
					_mcl_uses = 850,
					groups = { enchantability = 12, tool = 1, rake = 2, rake_uses = 850 },
					_mcl_upgradable = true,
					_mcl_upgrade_item = "farmtools:rake_netherite"
				},
				["netherite"] = {
					description = S("Netherite rake"),
					inventory_image = "farmtools_rake_netherite.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 6 },
						punch_attack_uses = 550,
					},
					_mcl_uses = 1100,
					groups = { enchantability = 12, tool = 1, rake = 2, rake_uses = 1100 },
				},
			}, {
				on_use = farmtools.rake_on_use,
				sound = { breaks = "default_tool_breaks" },
			})

			mcl_tools.add_to_sets("scythe", {
				longdesc = S("Works only on completely grown crops, or as a weapon."),
				usagehelp = "Works in a small radius (a total of 3x3 grid) around the targeted crop node. Will replant the crop automatically if it harvests the crop.",
				groups = {},
				diggroups = {},
				craft_shapes = {
					{
						{ "", "material", "material" },
						{ "material", "", "mcl_core:stick" },
						{ "", "", "mcl_core:stick" },
					},
				},
			}, {
				["iron"] = {
					description = S("Iron scythe"),
					inventory_image = "sickles_scythe_steel.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 5 },
						punch_attack_uses = 300,
					},
					_mcl_uses = 150,
					-- 2/3 of full iron set enchantability
					groups = { enchantability = 10, tool = 1, scythe = 2, scythe_uses = 150 },
				},
				["diamond"] = {
					description = S("Diamond scythe"),
					inventory_image = "farmtools_scythe_diamond.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 5 },
						punch_attack_uses = 500,
					},
					_mcl_uses = 500,
					groups = { enchantability = 12, tool = 1, scythe = 2, scythe_uses = 500 },
					_mcl_upgradable = true,
					_mcl_upgrade_item = "farmtools:scythe_netherite"
				},
				["netherite"] = {
					description = S("Netherite scythe"),
					inventory_image = "farmtools_scythe_netherite.png",
					tool_capabilities = {
						full_punch_interval = 1.2,
						damage_groups = { fleshy = 6 },
						punch_attack_uses = 650,
					},
					_mcl_uses = 650,
					groups = { enchantability = 12, tool = 1, scythe = 2, scythe_uses = 650 },
				},
				-- if mcl_copper_stuff used mcl_tools.register_set then we could put this here, but it does not.
				-- it just adds individual tools directly.
				--[[
		,["copper"] = {
			description = S("Copper scythe"),
			inventory_image = "sickles_scythe_bronze.png",
			tool_capabilities = {
				full_punch_interval = 1.2,
				damage_groups = { fleshy = 5 },
				punch_attack_uses = 200
			},
		}
		--]]
				-- Gold scythe is not implemented in MTG or mineclonia. Gold does not make sense to use in a scythe.
			}, {
				range = 12,
				on_use = farmtools.scythe_on_use,
				sound = { breaks = "default_tool_breaks" },
			})
		end -- for mineclonia api
	end -- for mcl_tools
else -- for minetest_game
	farmtools.register_scythe("farmtools:scythe_steel", {
		description = S("Steel Scythe"),
		inventory_image = "sickles_scythe_steel.png",
		level = 1,
		max_uses = 500,
		material = "default:steel_ingot",
	})

	farmtools.register_scythe("farmtools:scythe_diamond", {
		description = S("Diamond Scythe"),
		inventory_image = "farmtools_scythe_diamond.png",
		level = 1,
		max_uses = 850,
		material = "default:diamond",
	})

	-- register rakes
	--
	farmtools.register_rake("farmtools:rake_steel", {
		description = S("Steel Rake"),
		inventory_image = "farmtools_rake_steel.png",
		max_uses = 500,
		level = 1,
		material = "default:steel_ingot",
	})

	farmtools.register_rake("farmtools:rake_bronze", {
		description = S("Bronze Rake"),
		inventory_image = "farmtools_rake_bronze.png",
		max_uses = 250,
		level = 1,
		material = "default:bronze_ingot",
	})

	farmtools.register_rake("farmtools:rake_diamond", {
		description = S("Diamond Rake"),
		inventory_image = "farmtools_rake_diamond.png",
		max_uses = 850,
		level = 1,
		material = "default:diamond",
	})

	-- register sickles

	farmtools.register_sickle("farmtools:sickle_bronze", {
		description = S("Bronze Sickle"),
		inventory_image = "sickles_sickle_bronze.png",
		max_uses = 200,
		material = "default:bronze_ingot",
		damage_groups = { fleshy = 3 },
		groupcaps = {
			snappy = { times = { [1] = 2.75, [2] = 1.30, [3] = 0.375 }, uses = 100, maxlevel = 2 },
		},
	})

	farmtools.register_sickle("farmtools:sickle_steel", {
		description = S("Steel Sickle"),
		inventory_image = "sickles_sickle_steel.png",
		max_uses = 300,
		material = "default:steel_ingot",
		damage_groups = { fleshy = 3 },
		groupcaps = {
			snappy = { times = { [1] = 2.5, [2] = 1.20, [3] = 0.35 }, uses = 150, maxlevel = 2 },
		},
	})

	farmtools.register_sickle("farmtools:sickle_gold", {
		description = S("Golden Sickle"),
		inventory_image = "sickles_sickle_gold.png",
		max_uses = 160,
		material = "default:gold_ingot",
		damage_groups = { fleshy = 2 },
		groupcaps = {
			snappy = { times = { [1] = 2.0, [2] = 1.00, [3] = 0.35 }, uses = 80, maxlevel = 3 },
		},
	})

	farmtools.register_sickle("farmtools:sickle_diamond", {
		description = S("Diamond Sickle"),
		inventory_image = "farmtools_sickle_diamond.png",
		max_uses = 400,
		material = "default:diamond",
		damage_groups = { fleshy = 4 },
		groupcaps = {
			snappy = { times = { [1] = 1.75, [2] = 0.8, [3] = 0.25 }, uses = 200, maxlevel = 3 },
		},
	})

	-- register mithril tools
	if mod_moreores then
		farmtools.register_scythe("farmtools:scythe_mithril", {
			description = S("Mithril Scythe"),
			inventory_image = "farmtools_scythe_mithril.png",
			level = 1,
			max_uses = 850,
			material = "moreores:mithril_ingot",
		})
		farmtools.register_rake("farmtools:rake_mithril", {
			description = S("Mithril Rake"),
			inventory_image = "farmtools_rake_mithril.png",
			max_uses = 850,
			level = 1,
			material = "moreores:mithril_ingot",
		})
		farmtools.register_sickle("farmtools:sickle_mithril", {
			description = S("Mithril Sickle"),
			inventory_image = "farmtools_sickle_mithril.png",
			max_uses = 400,
			material = "moreores:mithril_ingot",
			damage_groups = { fleshy = 4 },
			groupcaps = {
				snappy = { times = { [1] = 1.6, [2] = 0.5, [3] = 0.15 }, uses = 200, maxlevel = 3 },
			},
		})
	end

	if is_farming_redo then -- needs to be inside the MTG condition
		-- softly disable mithril scythe to prevent confusion
		core.override_item("farming:scythe_mithril", {
			groups = { not_in_creative_inventory = 1 },
		})
		core.clear_craft({
			output = "farming:scythe_mithril",
		})
	end
end
