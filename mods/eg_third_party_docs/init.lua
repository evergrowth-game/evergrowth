-- eg_third_party_docs/init.lua
-- Centralized, structured in-game documentation manuals for Evergrowth.

local S = minetest.get_translator("eg_third_party_docs")

if not minetest.get_modpath("doc") then
	return
end

-- ==========================================
-- 1. CATEGORY: Combat & Arsenal
-- ==========================================
doc.add_category("combat", {
	name = "Combat & Arsenal",
	description = "Comprehensive guide to archery, conventional firearms, hi-tech directed-energy weapons, and torch ordnance.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("combat", "archery", {
	name = "Archery & Crossbows",
	data = {
		text = "Archery provides silent, reusable projectile combat:\n\n" ..
			"• Wooden Bow:\n" ..
			"Fires standard wooden arrows in an arced trajectory. Arrows have a high probability of dropping on the ground upon hitting a target or surface, allowing them to be retrieved.\n\n" ..
			"• Crossbow:\n" ..
			"A heavy mechanical crossbow with high tensile strength. Fires bolts at high velocity along a flat trajectory, dealing heavy impact damage.\n\n" ..
			"• Maintenance & Repairs:\n" ..
			"Bows and crossbows take wear with each shot and can be repaired using a hammer on a blacksmith's anvil.",
		images = {
			{ image = "bweapons_bows_pack:wooden_bow", imagetype = "item", caption = "Wooden Bow" },
			{ image = "bweapons_bows_pack:arrow", imagetype = "item", caption = "Wooden Arrow" },
			{ image = "bweapons_bows_pack:crossbow", imagetype = "item", caption = "Crossbow" },
			{ image = "bweapons_bows_pack:bolt", imagetype = "item", caption = "Crossbow Bolt" },
		},
	},
})

doc.add_entry("combat", "firearms", {
	name = "Conventional Firearms",
	data = {
		text = "Conventional firearms deliver instantaneous kinetic or explosive ballistic damage using specialized ammunition cartridges:\n\n" ..
			"• Handgun (Pistol):\n" ..
			"A compact semi-automatic sidearm loaded with Pistol Rounds. Excellent for rapid mid-range defense.\n\n" ..
			"• Pump-Action Shotgun:\n" ..
			"Discharges a spread of 5 heavy pellets per blast using Shotgun Shells. Highly effective for stopping close-range attackers.\n\n" ..
			"• Double-Barreled Shotgun:\n" ..
			"Consumes 2 Shotgun Shells simultaneously to unleash a devastating 10-pellet burst with wide spread at point-blank range.\n\n" ..
			"• Hunting Rifle:\n" ..
			"A high-precision long-range rifle using Rifle Rounds. Projectiles pierce through multiple consecutive targets.\n\n" ..
			"• Grenade Launcher:\n" ..
			"Lobs explosive canisters in an arced trajectory using Grenades, dealing area-of-effect blast damage on impact.\n\n" ..
			"• Maintenance:\n" ..
			"Conventional firearms can be repaired on a blacksmith's anvil.",
		images = {
			{ image = "bweapons_firearms_pack:pistol", imagetype = "item", caption = "Handgun" },
			{ image = "bweapons_firearms_pack:shotgun", imagetype = "item", caption = "Pump-Action Shotgun" },
			{ image = "bweapons_firearms_pack:double_barrel", imagetype = "item", caption = "Double-Barreled Shotgun" },
			{ image = "bweapons_firearms_pack:rifle", imagetype = "item", caption = "Hunting Rifle" },
			{ image = "bweapons_firearms_pack:grenade_launcher", imagetype = "item", caption = "Grenade Launcher" },
		},
	},
})

doc.add_entry("combat", "energy_weapons", {
	name = "Hi-Tech Energy Weapons",
	data = {
		text = "Advanced directed-energy and electromagnetic weaponry powered by electrical battery cells:\n\n" ..
			"• Weapon Types:\n" ..
			"  - Laser Gun: Pin-point continuous beam weapon with a 100-meter range (128 shots capacity).\n" ..
			"  - Particle Gun: Rapid-fire projector accelerating charged subatomic particles (64 shots capacity).\n" ..
			"  - Plasma Gun: Heavy projector discharging area-impact bolts of superheated ionized gas (32 shots capacity).\n" ..
			"  - Railgun: Electromagnetic accelerator firing high-velocity Railgun Slugs over extreme distances.\n" ..
			"  - Missile Launcher: Heavy tactical launcher firing self-propelled explosive Missiles.\n\n" ..
			"• Battery Recharging:\n" ..
			"Energy weapons operate on internal electrical charge. To recharge a depleted weapon, hold the weapon and right-click (or sneak + right-click) with a Battery in your inventory, or place them together in any crafting grid.",
		images = {
			{ image = "bweapons_hitech_pack:laser_gun", imagetype = "item", caption = "Laser Gun" },
			{ image = "bweapons_hitech_pack:particle_gun", imagetype = "item", caption = "Particle Gun" },
			{ image = "bweapons_hitech_pack:plasma_gun", imagetype = "item", caption = "Plasma Gun" },
			{ image = "bweapons_hitech_pack:rail_gun", imagetype = "item", caption = "Railgun" },
			{ image = "bweapons_hitech_pack:missile_launcher", imagetype = "item", caption = "Missile Launcher" },
			{ image = "techage:ta4_battery", imagetype = "item", caption = "Techage Battery" },
		},
	},
})

doc.add_entry("combat", "torch_ordnance", {
	name = "Torch Ordnance & Illumination",
	data = {
		text = "Specialized ordnance engineered to illuminate expansive underground chasms and dark cave networks from safety:\n\n" ..
			"• Torch Grenade:\n" ..
			"A compact throwable canister that detonates upon impact, mounting 12 torches across surrounding surfaces.\n\n" ..
			"• Torch Bomb & Mega Torch Bomb:\n" ..
			"Placeable explosive blocks. When ignited with flint and steel, fire, or redstone triggers, they disperse 42 (Bomb) or 162 (Mega Bomb) torches across large caverns.\n\n" ..
			"• Torch Rocket:\n" ..
			"A ground-launched pyrotechnic rocket. Right-click to set its fuse timer; when ignited, it ascends vertically to illuminate high ceilings.\n\n" ..
			"• Torch Crossbow & Utility Bow:\n" ..
			"Handheld ranged tools that fire torches directly onto targeted surfaces across long distances.",
		images = {
			{ image = "torch_bomb:grenade", imagetype = "item", caption = "Torch Grenade" },
			{ image = "torch_bomb:bomb", imagetype = "item", caption = "Torch Bomb" },
			{ image = "torch_bomb:mega_bomb", imagetype = "item", caption = "Mega Torch Bomb" },
			{ image = "torch_bomb:rocket", imagetype = "item", caption = "Torch Rocket" },
		},
	},
})

-- ==========================================
-- 2. CATEGORY: Magic & Enchantment
-- ==========================================
doc.add_category("magic", {
	name = "Magic & Enchantment",
	description = "Guide to mana reserves, utility spellbooks, elemental staves, arcane tomes, alchemy, and enchanting.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("magic", "mana_pool", {
	name = "Mana & Core Mechanics",
	data = {
		text = "All magical incantations and staves draw from the player's personal mana reserves:\n\n" ..
			"• Mana Reserve & HUD:\n" ..
			"Mana is displayed on the blue HUD bar above your health. Each player begins with a maximum capacity of 200 Mana.\n\n" ..
			"• Natural Regeneration:\n" ..
			"Mana naturally regenerates at a steady rate of +1 Mana every 0.2 seconds (+5 Mana per second). Consuming Mana Potions accelerates this regeneration rate.",
		images = {
			{ image = "mana_icon.png", imagetype = "image", caption = "Mana Reserve" },
			{ image = "gadgets_consumables:potion_mana", imagetype = "item", caption = "Mana Potion" },
		},
	},
})

doc.add_entry("magic", "spellbooks", {
	name = "Utility Spellbooks",
	data = {
		text = "Spellbooks channel direct magical effects from your mana reserves with zero durability wear:\n\n" ..
			"• Spellbook of Flight (25 Mana):\n" ..
			"Propels the caster into the air with a sustained upward velocity boost, ideal for scaling cliffs or escaping danger.\n\n" ..
			"• Spellbook of Blink (30 Mana):\n" ..
			"Instantly teleports the caster to the targeted surface within line of sight.\n\n" ..
			"• Spellbook of Earth (35 Mana):\n" ..
			"Transmutes targeted stone and geological blocks into altered states.\n\n" ..
			"• Spellbook of Light (15 Mana):\n" ..
			"Conjures a permanent glowing orb of pure light at the targeted position to illuminate dark caverns.",
		images = {
			{ image = "gadgets_magic:spellbook_flight", imagetype = "item", caption = "Spellbook of Flight" },
			{ image = "gadgets_magic:spellbook_blink", imagetype = "item", caption = "Spellbook of Blink" },
			{ image = "gadgets_magic:spellbook_earth", imagetype = "item", caption = "Spellbook of Earth" },
			{ image = "gadgets_magic:spellbook_light", imagetype = "item", caption = "Spellbook of Light" },
		},
	},
})

doc.add_entry("magic", "staves", {
	name = "Elemental & Utility Staves",
	data = {
		text = "Staves focus magical energy into terrain alteration and low-cost spellcasting:\n\n" ..
			"• Druid's Staff:\n" ..
			"Revitalizes barren ground by advancing blocks through geological stages (Stone → Cobble → Gravel → Sand → Dirt → Grass) and sprouting wild flora.\n\n" ..
			"• Staff of Earth:\n" ..
			"Excavates stone, ore, and soil in a 3×3 cube radius in a single cast.\n\n" ..
			"• Combat Staves (Fireball, Ice Shard, Electrosphere):\n" ..
			"Cast elemental offensive spells at reduced mana costs (10–15 Mana) using staff durability.\n\n" ..
			"• Staff Maintenance:\n" ..
			"Combine any damaged staff with a Februm Crystal in any crafting grid to restore its durability.",
		images = {
			{ image = "gadgets_magic:staff_druid", imagetype = "item", caption = "Druid's Staff" },
			{ image = "gadgets_magic:staff_earth", imagetype = "item", caption = "Staff of Earth" },
			{ image = "bweapons_magic_pack:staff_fireball", imagetype = "item", caption = "Staff of Fireball" },
			{ image = "magic_materials:februm_crystal", imagetype = "item", caption = "Februm Crystal" },
		},
	},
})

doc.add_entry("magic", "tomes", {
	name = "Arcane Combat Tomes",
	data = {
		text = "Spell tomes channel concentrated offensive elemental spells directly from player Mana with zero item wear:\n\n" ..
			"• Tome of Fireball (35 Mana):\n" ..
			"Launches an explosive sphere of fire that detonates on impact, burning targets and igniting flammable surfaces.\n\n" ..
			"• Tome of Ice Shard (25 Mana):\n" ..
			"Fires piercing glacial spikes that damage and slow enemies.\n\n" ..
			"• Tome of Electrosphere (40 Mana):\n" ..
			"Conjures a volatile lightning orb that shocks targets with heavy electrical damage.",
		images = {
			{ image = "bweapons_magic_pack:tome_fireball", imagetype = "item", caption = "Tome of Fireball" },
			{ image = "bweapons_magic_pack:tome_iceshard", imagetype = "item", caption = "Tome of Ice Shard" },
			{ image = "bweapons_magic_pack:tome_electrosphere", imagetype = "item", caption = "Tome of Electrosphere" },
		},
	},
})

doc.add_entry("magic", "enchanting", {
	name = "Enchanting & Grindstones",
	data = {
		text = "Enhance tools, weapons, and armor with magical attributes:\n\n" ..
			"• Enchanting Table:\n" ..
			"Place the item you wish to enchant into the table's slot, and insert Mese Crystals (default:mese_crystal) as currency to pay the enchantment cost.\n\n" ..
			"• Bookshelf Surrounding Placement:\n" ..
			"Surround the Enchanting Table with Bookshelves (default:bookshelf) to increase available enchantment levels. To unlock maximum level 30 enchantments, place up to 15 bookshelves within a 2-block radius.\n\n" ..
			"• The Grindstone:\n" ..
			"Place any enchanted item into a Grindstone to strip its enchantments and return the item to its clean base state.",
		images = {
			{ image = "x_enchanting:enchantment_table", imagetype = "item", caption = "Enchanting Table" },
			{ image = "default:bookshelf", imagetype = "item", caption = "Bookshelf" },
			{ image = "default:mese_crystal", imagetype = "item", caption = "Mese Crystal" },
			{ image = "x_enchanting:grindstone", imagetype = "item", caption = "Grindstone" },
		},
	},
})

-- ==========================================
-- 3. CATEGORY: Survival & Health
-- ==========================================
doc.add_category("survival", {
	name = "Survival & Health",
	description = "Guide to armor sets, hunger and nutrition, diving gear, and death recovery.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("survival", "armor", {
	name = "Armor & Protection",
	data = {
		text = "Equipping protective armor mitigates incoming physical and projectile damage:\n\n" ..
			"• Armor Slots & Materials:\n" ..
			"Equip Helmets, Chestplates, Leggings, Boots, and Shields crafted from Wood, Cactus, Steel, Bronze, Diamond, Gold, Crystal, and Nether.\n\n" ..
			"• Damage Absorption:\n" ..
			"The armor HUD bar indicates your total damage absorption percentage. Armor degrades as it absorbs hits and can be repaired at an anvil.",
		images = {
			{ image = "3d_armor:helmet_steel", imagetype = "item", caption = "Steel Helmet" },
			{ image = "3d_armor:chestplate_steel", imagetype = "item", caption = "Steel Chestplate" },
			{ image = "3d_armor:leggings_steel", imagetype = "item", caption = "Steel Leggings" },
			{ image = "3d_armor:boots_steel", imagetype = "item", caption = "Steel Boots" },
			{ image = "3d_armor:shield_steel", imagetype = "item", caption = "Steel Shield" },
		},
	},
})

doc.add_entry("survival", "hunger", {
	name = "Hunger & Nutrition",
	data = {
		text = "Managing your stamina and nutrition is vital for wilderness survival:\n\n" ..
			"• Hunger Bar & Saturation:\n" ..
			"Physical activities (running, mining, fighting) deplete your hunger bar. Eating cooked foods restores hunger points and saturation.\n\n" ..
			"• Starvation Damage:\n" ..
			"If your hunger bar fully depletes to zero, your character will begin suffering continuous starvation damage until food is consumed.",
		images = {
			{ image = "farming:bread", imagetype = "item", caption = "Bread" },
			{ image = "mobs:meat", imagetype = "item", caption = "Cooked Meat" },
		},
	},
})

doc.add_entry("survival", "diving", {
	name = "Diving & Marine Gear",
	data = {
		text = "Subterranean lakes and ocean trenches require specialized diving equipment:\n\n" ..
			"• Compressed Air Tanks:\n" ..
			"Equip Single, Double, or Triple steel air tanks to extend your underwater breathing supply for prolonged marine exploration.\n\n" ..
			"• Air Compressor:\n" ..
			"Use an air compressor machine to refill depleted air tanks with breathable air.",
		images = {
			{ image = "airtanks:steel_tank", imagetype = "item", caption = "Air Tank" },
			{ image = "airtanks:compressor", imagetype = "item", caption = "Compressor" },
		},
	},
})

doc.add_entry("survival", "death_compass", {
	name = "Death Recovery",
	data = {
		text = "Recovering equipment after death:\n\n" ..
			"• Death Compass:\n" ..
			"Upon respawning after death, holding a Death Compass will cause its needle to point directly toward the exact coordinates of your last death site, helping you retrieve lost items.",
		images = {
			{ image = "death_compass:compass", imagetype = "item", caption = "Death Compass" },
		},
	},
})

-- ==========================================
-- 4. CATEGORY: Vehicles & Travel
-- ==========================================
doc.add_category("vehicles", {
	name = "Vehicles & Travel",
	description = "Guide to driving automobiles, flying aircraft, sailing watercraft, refueling, and transit networks.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("vehicles", "controls_fuel", {
	name = "Controls & Engine Fueling",
	data = {
		text = "Motorized vehicles share unified driving mechanics and fuel sources:\n\n" ..
			"• Vehicle Controls:\n" ..
			"  - W: Accelerate / Throttle Forward\n" ..
			"  - S: Brake / Reverse\n" ..
			"  - A / D: Steer Left / Right\n" ..
			"  - Space: Ascend (Planes/Helicopters) or Surface (Submarines)\n" ..
			"  - Shift (Sneak): Descend / Submerge\n\n" ..
			"• Accepted Fuels:\n" ..
			"Engines accept Biofuel (biofuel:biofuel, biofuel:fuel_can) or Techage Gasoline (techage:ta3_canister_gasoline, techage:ta3_barrel_gasoline). Right-click the vehicle with fuel in hand to refuel.",
		images = {
			{ image = "biofuel:fuel_can", imagetype = "item", caption = "Biofuel Canister" },
			{ image = "techage:ta3_canister_gasoline", imagetype = "item", caption = "Techage Gasoline" },
		},
	},
})

doc.add_entry("vehicles", "automobiles", {
	name = "Automobiles",
	data = {
		text = "Evergrowth features 9 distinct motor vehicle models for overland travel:\n\n" ..
			"• Available Models:\n" ..
			"  - Roadster: Classic open-top high-speed cruiser.\n" ..
			"  - Dune Buggy: Off-road vehicle built for rough terrain.\n" ..
			"  - Catrelle: Durable utility vehicle with ample trunk storage.\n" ..
			"  - Coupe: Balanced everyday passenger vehicle.\n" ..
			"  - DeLorean: Iconic high-performance vehicle.\n" ..
			"  - Motorcycle & Vespa: Agile two-wheeled transport for narrow paths.\n" ..
			"  - Trans Am: High-torque muscle car.\n" ..
			"  - Beetle: Compact vintage city car.",
		images = {
			{ image = "automobiles_roadster:roadster", imagetype = "item", caption = "Roadster" },
			{ image = "automobiles_trans_am:trans_am", imagetype = "item", caption = "Trans Am" },
			{ image = "automobiles_beetle:beetle", imagetype = "item", caption = "Beetle" },
			{ image = "automobiles_delorean:delorean", imagetype = "item", caption = "DeLorean" },
		},
	},
})

doc.add_entry("vehicles", "aircraft", {
	name = "Aircraft & Flight",
	data = {
		text = "Aviation allows rapid aerial navigation over long distances:\n\n" ..
			"• Piper Super Cub:\n" ..
			"A versatile bush plane capable of short takeoff and landing on rough wilderness airstrips.\n\n" ..
			"• Piper Cherokee PA-28:\n" ..
			"A reliable low-wing four-seater aircraft built for stable long-distance transit.\n\n" ..
			"• Hidroplane (Seaplane):\n" ..
			"Fitted with pontoons for taking off and landing on ocean and lake surfaces.\n\n" ..
			"• Helicopter:\n" ..
			"Vertical takeoff and landing aircraft capable of hovering in place.",
		images = {
			{ image = "supercub:supercub", imagetype = "item", caption = "Super Cub" },
			{ image = "pa28:pa28", imagetype = "item", caption = "PA-28 Cherokee" },
			{ image = "hidroplane:hidroplane", imagetype = "item", caption = "Hidroplane" },
			{ image = "heli:heli", imagetype = "item", caption = "Helicopter" },
		},
	},
})

doc.add_entry("vehicles", "watercraft", {
	name = "Watercraft & Diving",
	data = {
		text = "Watercraft provide marine navigation and deep-sea exploration:\n\n" ..
			"• Motorboat:\n" ..
			"High-speed engine-driven boat for skimming across rivers and oceans.\n\n" ..
			"• Nautilus Submarine:\n" ..
			"Advanced submersible vessel. Use Space and Shift to control dive depth and surface safely.",
		images = {
			{ image = "motorboat:boat", imagetype = "item", caption = "Motorboat" },
			{ image = "nautilus:nautilus", imagetype = "item", caption = "Nautilus Submarine" },
		},
	},
})

doc.add_entry("vehicles", "elevators_teleport", {
	name = "Elevators & Teleportation",
	data = {
		text = "Stationary transit networks for vertical and long-distance travel:\n\n" ..
			"• Travelnet Elevators:\n" ..
			"Multistory elevator cabins that move vertically between designated floors with automated sliding elevator doors.\n\n" ..
			"• Telemosaic Teleportation:\n" ..
			"Point-to-point instantaneous transit using keyed Telemosaic beacons placed at distant settlement hubs.",
		images = {
			{ image = "travelnet:elevator", imagetype = "item", caption = "Elevator" },
			{ image = "telemosaic:key", imagetype = "item", caption = "Telemosaic Key" },
		},
	},
})

-- ==========================================
-- 5. CATEGORY: Farming & Wildlife
-- ==========================================
doc.add_category("farming_wildlife", {
	name = "Farming & Wildlife",
	description = "Guide to agriculture, specialized farm tools, animal husbandry, and defensive combat.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("farming_wildlife", "soil_crops", {
	name = "Soil Hydration & Crops",
	data = {
		text = "Cultivating crops provides food for settlements and cooking:\n\n" ..
			"• Soil Tilling:\n" ..
			"Use a hoe to till grass or dirt into farm soil. Soil requires a water source within 3 blocks horizontally to remain hydrated. Unwatered soil will dry out into standard dirt.\n\n" ..
			"• Fertilizer:\n" ..
			"Apply Bonemeal to growing crops to immediately accelerate their growth to harvest maturity.",
		images = {
			{ image = "default:hoe_steel", imagetype = "item", caption = "Steel Hoe" },
			{ image = "bonemeal:bonemeal", imagetype = "item", caption = "Bonemeal" },
			{ image = "farming:wheat", imagetype = "item", caption = "Wheat" },
		},
	},
})

doc.add_entry("farming_wildlife", "farmtools", {
	name = "Specialized Farm Tools",
	data = {
		text = "Specialized tools significantly improve agricultural productivity:\n\n" ..
			"• Sickles:\n" ..
			"Quickly clear wild grass, weeds, and underbrush without damaging soil.\n\n" ..
			"• Scythes:\n" ..
			"Wide-area harvesting tool. Swings across large crop fields to harvest all fully mature crops simultaneously in a single strike.\n\n" ..
			"• Rakes:\n" ..
			"Tills large circular plots of soil at once for rapid farmland expansion.",
		images = {
			{ image = "farmtools:sickle_steel", imagetype = "item", caption = "Steel Sickle" },
			{ image = "farmtools:scythe_steel", imagetype = "item", caption = "Steel Scythe" },
		},
	},
})

doc.add_entry("farming_wildlife", "animals", {
	name = "Animal Husbandry",
	data = {
		text = "Taming and breeding livestock sustains your settlement's food and material reserves:\n\n" ..
			"• Taming Foods:\n" ..
			"  - Cows & Sheep: Feed Wheat to tame.\n" ..
			"  - Chickens: Feed Seeds to tame.\n" ..
			"  - Horses: Feed Wheat or Apples to tame (place a Saddle to ride).\n\n" ..
			"• Breeding Pairs:\n" ..
			"Feeding a tamed pair of the same species will initiate breeding and produce offspring.",
		images = {
			{ image = "farming:wheat", imagetype = "item", caption = "Wheat" },
			{ image = "farming:seed_wheat", imagetype = "item", caption = "Wheat Seed" },
			{ image = "default:apple", imagetype = "item", caption = "Apple" },
			{ image = "mobs:saddle", imagetype = "item", caption = "Saddle" },
		},
	},
})

doc.add_entry("farming_wildlife", "threats_raiders", {
	name = "Hostile Threats & Raiders",
	data = {
		text = "Dangers of the wilderness:\n\n" ..
			"• Nighttime Monsters:\n" ..
			"Hostile monsters spawn in dark subterranean caverns and across the surface under low light levels at night.\n\n" ..
			"• Raider Plunderers:\n" ..
			"Hostile raiders are stationed as stationary guardians around valuable loot caches located in and around ancient ruins.",
		images = {
			{ image = "raiders:bootynode", imagetype = "item", caption = "Ruin Booty Node" },
		},
	},
})

-- ==========================================
-- 6. CATEGORY: Industry & Automation
-- ==========================================
doc.add_category("techage_industry", {
	name = "Industry & Automation",
	description = "Comprehensive guide to Techage technological stages (TA1–TA5), electrical power grids, and factory automation.",
	build_formspec = doc.entry_builders.text_and_gallery,
})

doc.add_entry("techage_industry", "techage_stages", {
	name = "Techage Developmental Stages",
	data = {
		text = "Techage advances through 5 progressive technological eras:\n\n" ..
			"• TA1: Iron Age:\n" ..
			"Early mechanical processing: Coal burners, gravel sieves, hammers, hoppers, and basic ore smelting.\n\n" ..
			"• TA2: Steam Age:\n" ..
			"Mechanical power: Steam boilers, engines, and drive axles that mechanically power early ore crushers and machinery.\n\n" ..
			"• TA3: Oil Age:\n" ..
			"Fossil fuels and electricity: Oil extraction, distillation towers (producing bitumen, fuel oil, naphtha, gasoline, and gas), generators, electrical wiring, and oil transport railways.\n\n" ..
			"• TA4: Present:\n" ..
			"Electronics and renewables: Wind generators, solar panels, high-voltage transformers, battery storage buffers, silicon wafers, and programmable logic controllers.\n\n" ..
			"• TA5: Future:\n" ..
			"Advanced technology: Baborium alloy processing, spatial teleportation, and artificial intelligence automation.",
		images = {
			{ image = "techage:ta4_battery", imagetype = "item", caption = "TA4 Battery" },
		},
	},
})

doc.add_entry("techage_industry", "power_grids", {
	name = "Power Grids & Distribution",
	data = {
		text = "Managing electricity across industrial plants:\n\n" ..
			"• Generators & Consumers:\n" ..
			"Power is generated by steam turbines, oil generators, wind turbines, and solar arrays. Machines draw active power from the grid.\n\n" ..
			"• Battery Storage Buffers:\n" ..
			"Industrial battery banks store excess power during peak generation and buffer power fluctuations under heavy machinery loads.\n\n" ..
			"• Transformers:\n" ..
			"Couple multiple sub-networks and regulate voltage distribution across large factories.",
		images = {
			{ image = "techage:ta4_battery", imagetype = "item", caption = "Battery Storage" },
		},
	},
})

-- ==========================================
-- 7. CATEGORY ORDERING
-- ==========================================
minetest.register_on_mods_loaded(function()
	doc.set_category_order({
		-- Column 1: Core Player Guides
		"basics",
		"survival",
		"farming_wildlife",
		"combat",
		"magic",
		"vehicles",
		"eg_settlers_guide",

		-- Column 2: Advanced, Industry & Encyclopedia
		"techage_industry",
		"minecart",
		"signs_bot",
		"castle_gates",
		"nodes",
		"tools",
		"craftitems",
		"advanced",
	})
end)

-- ==========================================
-- 8. ITEM ENCYCLOPEDIA OVERRIDES
-- ==========================================
dofile(minetest.get_modpath("eg_third_party_docs") .. "/item_docs.lua")

