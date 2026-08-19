-- eg_third_party_docs/init.lua
-- Centralized in-game documentation and guide manuals for Evergrowth.

local S = minetest.get_translator("eg_third_party_docs")

-- Only proceed if the core 'doc' mod is present
if not minetest.get_modpath("doc") then
	return
end

-- ==========================================
-- 1. Unified Category: Gameplay Guides
-- ==========================================
doc.add_category("gameplay_guides", {
	name = "Gameplay Guides",
	description = "Comprehensive guides covering magic, combat, survival, vehicles, farming, and industrial technology in Evergrowth.",
	build_formspec = doc.entry_builders.text,
})

-- Chapter 1: Magic & Mana
doc.add_entry("gameplay_guides", "magic", {
	name = "1. Magic & Mana System",
	data = "Magic in Evergrowth is powered by player Mana, arcane spellbooks, elemental staves, and alchemical potions:\n\n" ..
		"• Mana Pool & HUD:\n" ..
		"Each player possesses a Mana pool displayed on the blue HUD bar (200 base maximum), which naturally regenerates at +1 Mana every 0.2 seconds.\n\n" ..
		"• Utility Spellbooks (gadgets_magic):\n" ..
		"Spellbooks channel specific incantations directly from your mana pool:\n" ..
		"  - Spellbook of Flight (25 Mana): Launches the caster upward with a sustained velocity boost.\n" ..
		"  - Spellbook of Blink (30 Mana): Instantly teleports the caster to the targeted position in sight.\n" ..
		"  - Spellbook of Earth (35 Mana): Transmutes and shapes targeted geological blocks.\n" ..
		"  - Spellbook of Light (15 Mana): Conjures a glowing orb of stationary light.\n\n" ..
		"• Elemental Staves (gadgets_magic & bweapons_magic_pack):\n" ..
		"  - Druid's Staff: Transmutes stone and soil through geological stages (Stone → Cobble → Gravel → Sand → Dirt → Grass) and sprouts wild flora.\n" ..
		"  - Staff of Earth: Instantly excavates minable blocks in a 3×3 radius.\n" ..
		"  - Combat Staves (Fireball, Ice Shard, Electrosphere): Cast elemental combat spells at reduced mana costs (10–15 Mana) using staff durability.\n" ..
		"  - Maintenance: Magical staves can be repaired by combining them with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.\n\n" ..
		"• Combat Spell Tomes (bweapons_magic_pack):\n" ..
		"Fireball, Ice Shard, and Electrosphere Tomes channel raw combat magic directly from player Mana (25–40 Mana per cast) with zero item durability wear.\n\n" ..
		"• Consumables & Reagents:\n" ..
		"  - Mana Potions: Instantly restore +15 Mana and grant a temporary mana regeneration boost.\n" ..
		"  - Elemental Crystals: Februm, Aerum, Aquam, Terram, and Ignis crystals forged with runes to create magical gear.",
})

-- Chapter 2: Enchanting & Disenchanting
doc.add_entry("gameplay_guides", "enchanting", {
	name = "2. Enchanting & Disenchanting",
	data = "Tools, weapons, and armor can be imbued with powerful enchantments via x_enchanting:\n\n" ..
		"• The Enchanting Table:\n" ..
		"Place the tool you wish to enchant into the table's item slot and insert Mese Crystals (default:mese_crystal) into the trade slot as currency.\n\n" ..
		"• Bookshelf Surrounding Placement:\n" ..
		"Surrounding the Enchanting Table with Bookshelves (default:bookshelf) increases the power and tier of available enchantments. To unlock maximum level 30 enchantments, place up to 15 bookshelves within a 2-block horizontal and vertical radius of the table.\n\n" ..
		"• The Grindstone:\n" ..
		"Place any enchanted item into a Grindstone to strip its enchantments and restore the item to its unenchanted base state.",
})

-- Chapter 3: Combat & Weaponry
doc.add_entry("gameplay_guides", "combat", {
	name = "3. Combat & Weaponry",
	data = "Evergrowth features several specialized tiers of combat gear and ranged weaponry:\n\n" ..
		"• Archery:\n" ..
		"  - Wooden Bow: Fires wooden arrows along an arced trajectory. Arrows have a chance to be retrieved from the ground after impact.\n" ..
		"  - Crossbow: Steel-reinforced crossbow firing high-velocity bolts along a flat trajectory with strong impact damage.\n" ..
		"  - Maintenance: Bows and crossbows are repaired at a blacksmith's anvil.\n\n" ..
		"• Conventional Firearms:\n" ..
		"Deliver instantaneous hitscan or explosive ballistic damage using specific ammunition cartridges:\n" ..
		"  - Handgun (Pistol): Rapid-fire sidearm using Pistol Rounds.\n" ..
		"  - Pump-Action Shotgun: Discharges a spread of 5 heavy pellets per blast using Shotgun Shells.\n" ..
		"  - Double-Barreled Shotgun: Fires a massive 10-pellet burst consuming 2 Shotgun Shells simultaneously for severe close-range damage.\n" ..
		"  - Hunting Rifle: Long-range precision rifle capable of penetrating through multiple targets using Rifle Rounds.\n" ..
		"  - Grenade Launcher: Lobs explosive canisters that detonate on impact using Grenades.\n" ..
		"  - Maintenance: Conventional firearms are repaired with a hammer at a blacksmith's anvil.\n\n" ..
		"• Hi-Tech Energy Weapons:\n" ..
		"Advanced directed-energy weapons (Laser Gun, Particle Gun, Plasma Gun, Railgun, Missile Launcher):\n" ..
		"  - Firing: Energy beams and bolts consume internal battery capacity (32–128 shots). Railguns also require Railgun Slugs; Missile Launchers fire rocket Missiles.\n" ..
		"  - Battery Recharging: Energy weapons are recharged using Techage Batteries (techage:ta4_battery). Either hold the weapon and right-click (or sneak + right-click) with a Battery in your inventory, or combine them in any crafting grid.\n\n" ..
		"• Torch Ordnance (torch_bomb & bweapons_utility_pack):\n" ..
		"Tools designed to illuminate distant caverns and walls:\n" ..
		"  - Torch Bow: Shoots torches that mount onto distant walls, floors, or ceilings.\n" ..
		"  - Torch Grenade: Throwable canister scattering 12 torches across impacted surfaces.\n" ..
		"  - Torch Bombs & Mega Bombs: Placeable explosive blocks scattering 42 or 162 torches.\n" ..
		"  - Torch Rockets: Placeable rockets with adjustable fuse timers that ascend to light cavern ceilings.",
})

-- Chapter 4: Survival & Armor
doc.add_entry("gameplay_guides", "survival", {
	name = "4. Survival & Armor",
	data = "Surviving the wilderness requires managing health, nutrition, and protective gear:\n\n" ..
		"• Armor & Damage Absorption (3d_armor):\n" ..
		"Equip Helmets, Chestplates, Leggings, Boots, and Shields across various tiers (Wood, Cactus, Steel, Bronze, Diamond, Gold, Crystal, and Nether). The armor HUD bar displays your total damage absorption percentage.\n\n" ..
		"• Hunger & Nutrition (hbhunger):\n" ..
		"Performing physical activities depletes the hunger bar. Consuming cooked foods restores hunger points and saturation. If hunger fully depletes, the player begins taking continuous starvation damage.\n\n" ..
		"• Underwater Diving Air Tanks (airtanks):\n" ..
		"Equipping Single, Double, or Triple compressed air tanks allows extended breathing underwater for subterranean diving and marine exploration.\n\n" ..
		"• Death Compass (death_compass):\n" ..
		"When respawning after death, the Death Compass needle points directly toward the coordinates of your last death site to assist in recovering lost equipment.",
})

-- Chapter 5: Vehicles & Transport
doc.add_entry("gameplay_guides", "vehicles", {
	name = "5. Vehicles & Transport",
	data = "Evergrowth provides automobiles, aircraft, watercraft, and rapid transit networks:\n\n" ..
		"• Automobiles (automobiles_pck):\n" ..
		"Available in 9 distinct models: Beetle, Dune Buggy, Catrelle, Coupe, DeLorean, Motorcycle, Roadster, Trans Am, and Vespa. Controls: W (gas), S (brake/reverse), A/D (steer).\n\n" ..
		"• Aircraft (airutils, supercub, pa28, hidroplane, heli):\n" ..
		"Includes the Piper Super Cub, Piper Cherokee PA-28, Hidroplane (Seaplane), and Helicopter. Controls: W/S (throttle/pitch), A/D (roll/yaw), Space (ascend/takeoff), Shift (descend).\n\n" ..
		"• Watercraft (motorboat, nautilus):\n" ..
		"Motorboats provide high-speed surface travel, while Nautilus Submarines allow deep underwater exploration using Space/Shift to surface and submerge.\n\n" ..
		"• Engine Fuels:\n" ..
		"Motorized vehicles can be refueled using either Biofuel (biofuel:biofuel, biofuel:fuel_can) or Techage Gasoline (techage:ta3_canister_gasoline, techage:ta3_barrel_gasoline).\n\n" ..
		"• Elevators & Teleportation:\n" ..
		"  - Travelnet Elevators: Multistory elevators and automatic sliding elevator doors.\n" ..
		"  - Telemosaic: Keyed teleportation beacons for routing between distant stations.",
})

-- Chapter 6: Farming & Agriculture
doc.add_entry("gameplay_guides", "farming", {
	name = "6. Farming & Agriculture",
	data = "Cultivating crops sustains settlements and provides ingredients for cooking and biofuels:\n\n" ..
		"• Soil Preparation & Hydration (farming):\n" ..
		"Use a hoe to till dirt or grass into farm soil. Soil requires a water source within 3 blocks horizontally to remain hydrated. Without water, soil dries out and crops stop growing.\n\n" ..
		"• Specialized Farm Tools (farmtools):\n" ..
		"  - Sickles: Rapidly clear weeds, wild grasses, and overgrown vegetation.\n" ..
		"  - Scythes: Harvest large areas of fully mature crops simultaneously in a single swing.\n" ..
		"  - Rakes: Till soil across an expanded radius for rapid field preparation.\n\n" ..
		"• Fertilizer (bonemeal):\n" ..
		"Applying bonemeal directly onto growing crops accelerates their growth stages to reach maturity faster.",
})

-- Chapter 7: Animals & Wildlife
doc.add_entry("gameplay_guides", "animals", {
	name = "7. Animals & Wildlife",
	data = "Creatures inhabit diverse biomes across the world:\n\n" ..
		"• Animal Taming & Breeding (mobs_animal):\n" ..
		"Passive animals can be tamed by feeding them their preferred food:\n" ..
		"  - Cows & Sheep: Wheat\n" ..
		"  - Chickens: Seeds\n" ..
		"  - Horses: Wheat and Apples (saddles enable riding)\n" ..
		"Feeding a tamed pair of the same species initiates breeding to produce offspring.\n\n" ..
		"• Hostile Threats (mobs_monster):\n" ..
		"Hostile monsters spawn in dark subterranean caverns and across the surface during nighttime.\n\n" ..
		"• Raiders (raiders):\n" ..
		"Hostile plunderers stationed defensively to protect loot caches (booty nodes) located in and around ruined structures.",
})

-- Chapter 8: Industrial Technology
doc.add_entry("gameplay_guides", "techage", {
	name = "8. Techage Industrial Stages",
	data = "Techage introduces 5 progressive developmental stages of industrial machinery and automation:\n\n" ..
		"• TA1: Iron Age:\n" ..
		"Early manual and mechanical processing: Coal burners, gravel sieves, hammers, hoppers, and basic ore smelting.\n\n" ..
		"• TA2: Steam Age:\n" ..
		"Mechanical power generation: Steam boilers, engines, and drive axles that mechanically power early ore crushers and machinery.\n\n" ..
		"• TA3: Oil Age:\n" ..
		"Fossil fuels and early electricity: Oil drills, distillation towers (producing bitumen, fuel oil, naphtha, gasoline, and gas), generators, electrical wiring, and oil railways.\n\n" ..
		"• TA4: Present:\n" ..
		"Electronics and renewable energy: Wind generators, solar panels, high-voltage transformers, battery storage buffers, silicon wafers, and programmable logic controllers.\n\n" ..
		"• TA5: Future:\n" ..
		"Advanced technologies: Baborium alloy processing, spatial teleportation, and artificial intelligence automation.",
})

-- ==========================================
-- 2. Item Encyclopedia Overrides (doc_items)
-- ==========================================
dofile(minetest.get_modpath("eg_third_party_docs") .. "/item_docs.lua")
