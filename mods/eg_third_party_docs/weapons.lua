-- eg_third_party_docs/weapons.lua
-- Comprehensive in-game documentation for bweapons modpack tools, ammo, and guides.

local S = minetest.get_translator("eg_third_party_docs")

-- ==========================================
-- 1. Knowledge Base Category: Weapons & Combat
-- ==========================================
if minetest.get_modpath("bweapons_api") or minetest.get_modpath("bweapons_bows_pack") or minetest.get_modpath("bweapons_firearms_pack") or minetest.get_modpath("bweapons_hitech_pack") or minetest.get_modpath("bweapons_magic_pack") or minetest.get_modpath("bweapons_utility_pack") then

	doc.add_category("weapons_guide", {
		name = "Weapons & Combat",
		description = "Guides for archery, firearms, hi-tech energy weapons, magic staves, and utility gear.",
		build_formspec = doc.entry_builders.text,
	})

	doc.add_entry("weapons_guide", "overview", {
		name = "Combat Overview & Mechanics",
		data = "Evergrowth features several tiers and classes of ranged and energetic weaponry:\n\n" ..
			"• Bows & Crossbows: Reliable projectile weapons utilizing craftable arrows and bolts.\n" ..
			"• Firearms: Fast ballistic weapons requiring specific ammunition (pistol rounds, shotgun shells, rifle rounds, or grenades). Firearms can be repaired at a blacksmith's anvil.\n" ..
			"• Hi-Tech Energy Weapons: Directed-energy weapons (Lasers, Particle Guns, Plasma Guns, Railguns). These do not use conventional bullets (except rail slugs) and run on internal charge. They cannot be repaired on an anvil and must be recharged with Techage Batteries.\n" ..
			"• Magic Tomes & Staves: Arcane implements that draw directly upon the player's Mana pool or enchanted Februm crystals.\n" ..
			"• Utility Equipment: Specialized tools like the Torch Bow for lighting caves from a distance.",
	})

	doc.add_entry("weapons_guide", "bows", {
		name = "Archery & Crossbows",
		data = "Archery weapons provide silent, long-range capabilities with high ammunition recovery:\n\n" ..
			"• Wooden Bow: Fires wooden arrows with an arced trajectory. Good for early-game hunting and defense.\n" ..
			"• Crossbow: High-tension steel crossbow that fires heavy bolts with high velocity, flat trajectory, and superior damage.\n\n" ..
			"Ammunition:\n" ..
			"• Wooden Arrows: Used by the Wooden Bow. Fired arrows have a chance to drop on hit for retrieval.\n" ..
			"• Crossbow Bolts: Heavy quarrels for the Crossbow with high impact velocity and recovery rate.\n\n" ..
			"Maintenance: Both bows and crossbows can be repaired on a blacksmith's anvil.",
	})

	doc.add_entry("weapons_guide", "firearms", {
		name = "Conventional Firearms",
		data = "Firearms deliver instantaneous hitscan or ballistic explosive damage:\n\n" ..
			"• Pistol: Rapid-fire sidearm for close-to-medium range combat. Uses Pistol Rounds.\n" ..
			"• Pump-Action Shotgun: Discharges a spread of 5 pellets per blast for high close-range stopping power. Uses Shotgun Shells.\n" ..
			"• Double-Barreled Shotgun: Fires a massive 10-pellet burst (consuming 2 shells per shot) with extreme close-range spread and damage.\n" ..
			"• Rifle: Precision long-range rifle capable of penetrating through multiple targets. Deals high damage over long distances. Uses Rifle Rounds.\n" ..
			"• Grenade Launcher: Lobs explosive canisters that detonate on impact with area-of-effect blast damage. Uses Grenades.\n\n" ..
			"Ammunition & Maintenance:\n" ..
			"Each firearm requires its specific ammunition in the player's inventory. All conventional firearms can be repaired on a blacksmith's anvil with a hammer.",
	})

	doc.add_entry("weapons_guide", "hitech", {
		name = "Hi-Tech & Energy Weaponry",
		data = "High-tech weapons utilize advanced directed-energy and magnetic acceleration technologies:\n\n" ..
			"• Laser Gun: Emits an instantaneous, high-precision laser beam with pin-point accuracy over a 100-meter range. Holds 128 shots per battery charge.\n" ..
			"• Particle Gun: Rapidly projects bursts of energized subatomic particles. Holds 64 shots per charge.\n" ..
			"• Plasma Gun: Fires superheated ionized plasma bolts with explosive impact. Holds 32 shots per charge.\n" ..
			"• Railgun: Electromagnetic accelerator that propels high-density Railgun Slugs at extreme velocity. Requires both electrical charge and physical Railgun Slugs.\n" ..
			"• Missile Launcher: Fires guided rocket-propelled missiles that produce large explosions on impact. Uses physical Missiles.\n\n" ..
			"Recharging & Maintenance:\n" ..
			"Energy weapons CANNOT be repaired on an anvil. Instead, they are recharged with Techage Batteries (techage:ta4_battery):\n" ..
			"1. In-Hand Quick Reload: Hold the weapon and right-click (or sneak + right-click) with a Battery in your inventory. Consumes 1 Battery and fully restores weapon charge.\n" ..
			"2. Crafting Table: Place the worn energy weapon and a Battery into any crafting grid to restore it to full charge.",
	})

	doc.add_entry("weapons_guide", "magic", {
		name = "Magic Tomes & Staves",
		data = "Arcane combat gear harnesses elemental magic through tomes and enchanted staves:\n\n" ..
			"• Spell Tomes (Fireball, Ice Shard, Electrosphere): Channel pure elemental energy directly from the caster. Consumes player Mana per cast and suffers zero durability wear.\n" ..
			"• Arcane Staves (Fireball, Ice Shard, Electrosphere): Focus and amplify spellcasting, drastically reducing player Mana consumption per cast in exchange for staff durability.\n\n" ..
			"Maintenance:\n" ..
			"Arcane Staves cannot be repaired on a standard anvil. To repair a staff, combine it with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	})

	doc.add_entry("weapons_guide", "utility", {
		name = "Utility Equipment",
		data = "• Torch Bow: Specialized exploration gear that launches lit torches across great distances and across chasms. When a torch projectile strikes a wall, ceiling, or floor, it mounts a torch directly onto the surface.\n" ..
			"Uses standard Torches (default:torch) from the player's inventory as ammunition.",
	})
end

-- ==========================================
-- 2. Item Encyclopedia Documentation (doc_items)
-- ==========================================
local item_docs = {
	-- Bows
	["bweapons_bows_pack:wooden_bow"] = {
		longdesc = "A traditional wooden ranged weapon crafted from timber and string. Ideal for hunting and early-game combat.",
		usagehelp = "Requires Wooden Arrows (bweapons_bows_pack:arrow) in your inventory. Left-click to shoot. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_bows_pack:crossbow"] = {
		longdesc = "A heavy mechanical crossbow crafted with steel reinforcement. Fires bolts with high velocity, flat trajectory, and high stopping power.",
		usagehelp = "Requires Crossbow Bolts (bweapons_bows_pack:bolt) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_bows_pack:arrow"] = {
		longdesc = "Standard wooden arrow with flint tip and fletching, designed as ammunition for wooden bows. Fired arrows have a chance to be retrieved upon impact.",
	},
	["bweapons_bows_pack:bolt"] = {
		longdesc = "Dense steel-tipped quarrel engineered as ammunition for heavy crossbows. Features high impact damage and high recovery rate.",
	},

	-- Firearms
	["bweapons_firearms_pack:pistol"] = {
		longdesc = "A compact semi-automatic firearm designed for rapid short-to-medium range combat.",
		usagehelp = "Requires Pistol Rounds (bweapons_firearms_pack:pistol_round) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:shotgun"] = {
		longdesc = "A pump-action shotgun that discharges a spread of 5 heavy pellets per blast. Inflicts devastating close-range damage.",
		usagehelp = "Requires Shotgun Shells (bweapons_firearms_pack:shotgun_shell) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:double_barrel"] = {
		longdesc = "A break-action double-barreled shotgun. Fires a massive 10-pellet burst consuming 2 shells simultaneously, dealing severe point-blank damage.",
		usagehelp = "Requires Shotgun Shells (bweapons_firearms_pack:shotgun_shell) in your inventory (uses 2 shells per shot). Left-click to fire. Can be repaired on an anvil.",
	},
	["bweapons_firearms_pack:rifle"] = {
		longdesc = "A high-precision long-range rifle capable of penetrating through multiple targets. Deals extreme damage over long distances.",
		usagehelp = "Requires Rifle Rounds (bweapons_firearms_pack:rifle_round) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:grenade_launcher"] = {
		longdesc = "A heavy ordnance launcher that lobs explosive canisters in an arced trajectory, detonating on impact with area-of-effect blast damage.",
		usagehelp = "Requires Grenades (bweapons_firearms_pack:grenade) in your inventory. Left-click to launch. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:pistol_round"] = {
		longdesc = "Standard brass-cased ammunition cartridge designed for pistols.",
	},
	["bweapons_firearms_pack:shotgun_shell"] = {
		longdesc = "Heavy-gauge shotgun cartridge loaded with lead pellets and gunpowder.",
	},
	["bweapons_firearms_pack:rifle_round"] = {
		longdesc = "High-velocity jacketed rifle round engineered for high-precision rifles.",
	},
	["bweapons_firearms_pack:grenade"] = {
		longdesc = "Heavy explosive propellant canister designed for grenade launchers.",
	},

	-- Hi-Tech
	["bweapons_hitech_pack:laser_gun"] = {
		longdesc = "A directed-energy weapon emitting a high-intensity focused laser beam. Deals 15 damage per shot with pin-point accuracy over a 100-meter range. Operates on internal electrical charge (128 shots capacity). Cannot be repaired on an anvil.",
		usagehelp = "Left-click to fire. When depleted or worn, hold the weapon and right-click (or sneak + right-click) with a Battery (techage:ta4_battery) in your inventory, or combine them on a crafting table to fully recharge.",
	},
	["bweapons_hitech_pack:particle_gun"] = {
		longdesc = "A rapid-cadence energy projector that accelerates charged subatomic particles into high-speed beams (64 shots capacity). Cannot be repaired on an anvil.",
		usagehelp = "Left-click to fire rapid particle bursts. To recharge, right-click with a Battery (techage:ta4_battery) in inventory or combine on a crafting table.",
	},
	["bweapons_hitech_pack:plasma_gun"] = {
		longdesc = "A heavy energy projector that discharges bolts of superheated ionized plasma with area impact (32 shots capacity). Cannot be repaired on an anvil.",
		usagehelp = "Left-click to fire. To recharge, right-click with a Battery (techage:ta4_battery) in inventory or combine on a crafting table.",
	},
	["bweapons_hitech_pack:rail_gun"] = {
		longdesc = "An advanced electromagnetic railgun that accelerates magnetic slugs to hyper-velocity over extreme distances. Requires both battery power and physical Railgun Slugs. Cannot be repaired on an anvil.",
		usagehelp = "Requires Railgun Slugs (bweapons_hitech_pack:rail_slug) in inventory to fire. Left-click to shoot. To recharge electrical power, right-click with a Battery (techage:ta4_battery) in inventory or combine on a crafting table.",
	},
	["bweapons_hitech_pack:missile_launcher"] = {
		longdesc = "A heavy tactical missile launcher that fires guided rocket-propelled missiles with destructive explosion radius.",
		usagehelp = "Requires Missiles (bweapons_hitech_pack:missile) in your inventory. Left-click to launch.",
	},
	["bweapons_hitech_pack:rail_slug"] = {
		longdesc = "Heavy dense alloy slug engineered for electromagnetic railgun acceleration.",
	},
	["bweapons_hitech_pack:missile"] = {
		longdesc = "Self-propelled explosive missile fitted with a warhead and stabilization fins.",
	},

	-- Magic
	["bweapons_magic_pack:tome_fireball"] = {
		longdesc = "An arcane spellbook that channels incandescent fireballs that explode and ignite surfaces on impact. Suffers no durability wear.",
		usagehelp = "Consumes 35 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:tome_iceshard"] = {
		longdesc = "An arcane spellbook that conjures razor-sharp glacial shards that freeze and pierce targets. Suffers no durability wear.",
		usagehelp = "Consumes 25 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:tome_electrosphere"] = {
		longdesc = "An arcane spellbook that conjures volatile spheres of lightning plasma that shock targets. Suffers no durability wear.",
		usagehelp = "Consumes 40 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:staff_fireball"] = {
		longdesc = "An enchanted wooden staff that focuses fire magic. Casts explosive fireballs at reduced mana cost (10 Mana per cast) while consuming staff durability (32 uses).",
		usagehelp = "Left-click to cast (consumes 10 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},
	["bweapons_magic_pack:staff_iceshard"] = {
		longdesc = "An enchanted wooden staff that focuses cryomancy. Casts piercing ice shards at reduced mana cost (10 Mana per cast) while consuming staff durability (48 uses).",
		usagehelp = "Left-click to cast (consumes 10 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},
	["bweapons_magic_pack:staff_electrosphere"] = {
		longdesc = "An enchanted wooden staff that focuses lightning magic. Casts electrical spheres at reduced mana cost (15 Mana per cast) while consuming staff durability (24 uses).",
		usagehelp = "Left-click to cast (consumes 15 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},

	-- Utility
	["bweapons_utility_pack:torch_bow"] = {
		longdesc = "A specialized exploration tool designed for lighting caves and chasms from distance. Fired torches automatically mount onto wall, floor, or ceiling blocks on impact.",
		usagehelp = "Requires Torches (default:torch) in your inventory. Left-click to launch torches across distances.",
	},
}

-- Apply doc_items fields on loaded items
minetest.register_on_mods_loaded(function()
	for itemname, doc_data in pairs(item_docs) do
		if minetest.registered_items[itemname] then
			minetest.override_item(itemname, {
				_doc_items_longdesc = doc_data.longdesc,
				_doc_items_usagehelp = doc_data.usagehelp,
			})
		end
	end
end)
