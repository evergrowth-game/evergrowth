-- eg_third_party_docs/init.lua

local S = minetest.get_translator("eg_third_party_docs")

-- Only proceed if the core 'doc' mod is present (should be guaranteed by mod.conf)
if not minetest.get_modpath("doc") then
	return
end

-- ==========================================
-- 1. Farming Redo
-- ==========================================
if minetest.get_modpath("farming") then
	doc.add_category("farming_guide", {
		name = "Farming Guide",
		description = "Learn how to grow crops, prepare soil, and cook advanced recipes.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("farming_guide", "basics", {
		name = "Farming Basics",
		data = "To start farming, craft a hoe and use it on dirt or grass to turn it into soil. Crops require wet soil to grow. Soil becomes wet automatically if there is a water source block within 3 blocks. Without nearby water, the soil will dry out and crops will stop growing.",
	})
end

-- ==========================================
-- 2. Mobs Redo
-- ==========================================
if minetest.get_modpath("mobs_animal") or minetest.get_modpath("mobs_monster") then
	doc.add_category("mobs_guide", {
		name = "Creatures & Monsters",
		description = "Information on the various creatures that inhabit the world.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("mobs_guide", "taming", {
		name = "Taming & Breeding",
		data = "Specific passive animals (like cows, sheep, and chickens) can be tamed by feeding them their preferred food (such as wheat for cows and sheep, or seeds for chickens). Once tamed, feeding two of the same animal will breed them.",
	})
end

-- ==========================================
-- 3. Vehicles & Transport
-- ==========================================
if minetest.get_modpath("airutils") or minetest.get_modpath("nautilus") or minetest.get_modpath("automobiles_pck") or minetest.get_modpath("supercub") then
	doc.add_category("vehicles_guide", {
		name = "Vehicles & Transport",
		description = "Learn how to operate cars, planes, and submarines.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("vehicles_guide", "controls", {
		name = "Vehicle Controls",
		data = "Cars, planes, helicopters, and submarines use Forward/Backward (W/S) for throttle, and Left/Right (A/D) to steer. For aircraft and submarines, use Jump (Space) to ascend/surface and Sneak (Shift) to descend/submerge.",
	})
end

-- ==========================================
-- 4. Magic & Enchanting
-- ==========================================
if minetest.get_modpath("magic_materials") or minetest.get_modpath("x_enchanting") or minetest.get_modpath("mana") or minetest.get_modpath("bweapons") then
	doc.add_category("magic_guide", {
		name = "Magic & Enchanting",
		description = "Harness arcane energies and enchant your tools.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("magic_guide", "enchanting", {
		name = "The Arcane Arts",
		data = "Magic in Evergrowth encompasses both enchanting and combat. The Enchanting Table (powered by surrounding bookshelves and trade crystals) applies buffs to tools. Separately, magic weapons (like the Magic Wand or Fire Staff) utilize Mana and Magic Materials to cast spells and deal damage.",
	})
end

-- ==========================================
-- 5. Techage
-- ==========================================
if minetest.get_modpath("techage_modpack") then
	doc.add_category("techage_guide", {
		name = "Techage Manuals",
		description = "Industrial machines, power routing, and automation.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("techage_guide", "overview", {
		name = "Getting Started with Techage",
		data = "Techage is a massive industrial mod. You can browse the Encyclopedia to learn how to craft and use its individual machines, generate and route power, and automate production.",
	})
end
