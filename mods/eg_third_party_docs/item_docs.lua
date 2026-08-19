-- eg_third_party_docs/item_docs.lua
-- Item Encyclopedia (doc_items) definitions for tools, weapons, magic items, and ordnance.

local item_docs = {
	-- ==========================================
	-- 1. Bows & Crossbows (bweapons_bows_pack)
	-- ==========================================
	["bweapons_bows_pack:wooden_bow"] = {
		longdesc = "A traditional wooden ranged weapon crafted from timber and string. Fires arrows in an arced trajectory.",
		usagehelp = "Requires Wooden Arrows (bweapons_bows_pack:arrow) in your inventory. Left-click to shoot. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_bows_pack:crossbow"] = {
		longdesc = "A heavy mechanical crossbow with steel reinforcement. Fires high-velocity bolts along a flat trajectory with strong impact force.",
		usagehelp = "Requires Crossbow Bolts (bweapons_bows_pack:bolt) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_bows_pack:arrow"] = {
		longdesc = "Standard wooden arrow with flint tip and fletching, designed as ammunition for wooden bows. Fired arrows have a chance to be retrieved from the ground upon impact.",
	},
	["bweapons_bows_pack:bolt"] = {
		longdesc = "Dense steel-tipped quarrel engineered as ammunition for heavy crossbows. Features high impact velocity and a high recovery rate.",
	},

	-- ==========================================
	-- 2. Firearms & Ordnance (bweapons_firearms_pack)
	-- ==========================================
	["bweapons_firearms_pack:pistol"] = {
		longdesc = "A compact semi-automatic firearm designed for rapid short-to-medium range combat.",
		usagehelp = "Requires Pistol Rounds (bweapons_firearms_pack:pistol_round) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:shotgun"] = {
		longdesc = "A pump-action shotgun that discharges a spread of 5 heavy pellets per blast. Inflicts high close-range stopping power.",
		usagehelp = "Requires Shotgun Shells (bweapons_firearms_pack:shotgun_shell) in your inventory. Left-click to fire. Can be repaired on a blacksmith's anvil.",
	},
	["bweapons_firearms_pack:double_barrel"] = {
		longdesc = "A break-action double-barreled shotgun. Fires a massive 10-pellet burst consuming 2 shells simultaneously, dealing severe point-blank damage with wide spread.",
		usagehelp = "Requires Shotgun Shells (bweapons_firearms_pack:shotgun_shell) in your inventory (consumes 2 shells per shot). Left-click to fire. Can be repaired on an anvil.",
	},
	["bweapons_firearms_pack:rifle"] = {
		longdesc = "A high-precision long-range hunting rifle capable of penetrating through multiple targets. Deals high damage over long distances.",
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
		longdesc = "High-velocity jacketed rifle round engineered for precision rifles.",
	},
	["bweapons_firearms_pack:grenade"] = {
		longdesc = "Explosive propellant canister designed for grenade launchers.",
	},

	-- ==========================================
	-- 3. Hi-Tech Energy Weapons (bweapons_hitech_pack)
	-- ==========================================
	["bweapons_hitech_pack:laser_gun"] = {
		longdesc = "A directed-energy weapon emitting a focused laser beam with pin-point accuracy over a 100-meter range. Operates on internal electrical charge (128 shots capacity).",
		usagehelp = "Left-click to fire. When discharged, hold the weapon and right-click (or sneak + right-click) with a Battery (techage:ta4_battery) in your inventory, or combine them in any crafting grid to fully recharge.",
	},
	["bweapons_hitech_pack:particle_gun"] = {
		longdesc = "A rapid-cadence energy projector that accelerates charged subatomic particles into high-speed pulses (64 shots capacity).",
		usagehelp = "Left-click to fire rapid particle bursts. To recharge, right-click with a Battery (techage:ta4_battery) in inventory or combine in any crafting grid.",
	},
	["bweapons_hitech_pack:plasma_gun"] = {
		longdesc = "A heavy energy projector that discharges bolts of superheated ionized plasma with area impact (32 shots capacity).",
		usagehelp = "Left-click to fire. To recharge, right-click with a Battery (techage:ta4_battery) in inventory or combine in any crafting grid.",
	},
	["bweapons_hitech_pack:rail_gun"] = {
		longdesc = "An advanced electromagnetic railgun that accelerates magnetic slugs to hyper-velocity over extreme distances. Requires both battery power and physical Railgun Slugs.",
		usagehelp = "Requires Railgun Slugs (bweapons_hitech_pack:rail_slug) in inventory to fire. Left-click to shoot. To recharge electrical power, right-click with a Battery (techage:ta4_battery) in inventory or combine in any crafting grid.",
	},
	["bweapons_hitech_pack:missile_launcher"] = {
		longdesc = "A heavy tactical missile launcher that fires guided rocket-propelled missiles with a destructive explosion radius.",
		usagehelp = "Requires Missiles (bweapons_hitech_pack:missile) in your inventory. Left-click to launch.",
	},
	["bweapons_hitech_pack:rail_slug"] = {
		longdesc = "Heavy dense alloy slug engineered for electromagnetic railgun acceleration.",
	},
	["bweapons_hitech_pack:missile"] = {
		longdesc = "Self-propelled explosive missile fitted with a warhead and stabilization fins.",
	},

	-- ==========================================
	-- 4. Magic Combat Tomes & Staves (bweapons_magic_pack)
	-- ==========================================
	["bweapons_magic_pack:tome_fireball"] = {
		longdesc = "An arcane spellbook that channels incandescent fireballs that explode and ignite surfaces on impact. Consumes player Mana with zero durability wear.",
		usagehelp = "Consumes 35 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:tome_iceshard"] = {
		longdesc = "An arcane spellbook that conjures razor-sharp glacial shards that freeze and pierce targets. Consumes player Mana with zero durability wear.",
		usagehelp = "Consumes 25 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:tome_electrosphere"] = {
		longdesc = "An arcane spellbook that conjures volatile spheres of lightning plasma that shock targets. Consumes player Mana with zero durability wear.",
		usagehelp = "Consumes 40 Mana per cast. Left-click to cast.",
	},
	["bweapons_magic_pack:staff_fireball"] = {
		longdesc = "An enchanted wooden staff that focuses fire magic. Casts explosive fireballs at a low mana cost (10 Mana per cast) while consuming staff durability (32 uses).",
		usagehelp = "Left-click to cast (consumes 10 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},
	["bweapons_magic_pack:staff_iceshard"] = {
		longdesc = "An enchanted wooden staff that focuses cryomancy. Casts piercing ice shards at a low mana cost (10 Mana per cast) while consuming staff durability (48 uses).",
		usagehelp = "Left-click to cast (consumes 10 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},
	["bweapons_magic_pack:staff_electrosphere"] = {
		longdesc = "An enchanted wooden staff that focuses lightning magic. Casts electrical spheres at a low mana cost (15 Mana per cast) while consuming staff durability (24 uses).",
		usagehelp = "Left-click to cast (consumes 15 Mana). To repair, combine with a Februm Crystal (magic_materials:februm_crystal) in any crafting grid.",
	},

	-- ==========================================
	-- 5. Utility Gear (bweapons_utility_pack & torch_bomb)
	-- ==========================================
	["bweapons_utility_pack:torch_bow"] = {
		longdesc = "A specialized exploration tool designed for lighting caves and chasms from distance. Fired torches automatically mount onto wall, floor, or ceiling blocks on impact.",
		usagehelp = "Requires Torches (default:torch) in your inventory. Left-click to launch torches across distances.",
	},
	["torch_bomb:grenade"] = {
		longdesc = "A compact throwable canister that detonates on impact, scattering 12 torches across surrounding surfaces to light up dark caverns.",
		usagehelp = "Right-click while holding to throw. Deploys torches upon hitting a solid block.",
	},
	["torch_bomb:bomb"] = {
		longdesc = "A placeable explosive block that detonates to mount 42 torches across surrounding cave walls and ceilings.",
		usagehelp = "Place in the world and ignite with flint and steel, fire, or TNT triggers.",
	},
	["torch_bomb:mega_bomb"] = {
		longdesc = "A heavy placeable explosive block that deploys 162 torches across an expansive radius.",
		usagehelp = "Place in the world and ignite with flint and steel, fire, or TNT triggers.",
	},
	["torch_bomb:rocket"] = {
		longdesc = "A ground-launched pyrotechnic rocket that ascends into the air and disperses torches across high cavern ceilings.",
		usagehelp = "Place on the ground and right-click to adjust the fuse timer, then ignite.",
	},

	-- ==========================================
	-- 6. Utility Spellbooks & Staves (gadgets_magic)
	-- ==========================================
	["gadgets_magic:spellbook_flight"] = {
		longdesc = "An arcane manual containing levitation incantations. Propels the caster upward into the air with a sustained velocity boost.",
		usagehelp = "Consumes 25 Mana. Left-click while holding to launch into the air.",
	},
	["gadgets_magic:spellbook_blink"] = {
		longdesc = "An arcane manual of spatial distortion. Instantly teleports the caster to the targeted position in sight.",
		usagehelp = "Consumes 30 Mana. Left-click while pointing at a target location to teleport.",
	},
	["gadgets_magic:spellbook_earth"] = {
		longdesc = "An arcane manual of transmutation. Converts earth and stone blocks into altered geological states.",
		usagehelp = "Consumes 35 Mana. Left-click on targeted terrain nodes to transmute.",
	},
	["gadgets_magic:spellbook_light"] = {
		longdesc = "An arcane manual of illumination. Conjures a stationary sphere of pure light at the targeted position.",
		usagehelp = "Consumes 15 Mana. Left-click to place a light sphere.",
	},
	["gadgets_magic:staff_druid"] = {
		longdesc = "A nature-infused wooden staff capable of revitalizing barren stone into living soil and wild flora. Transmutes Stone → Cobble → Gravel → Sand → Dirt → Grass.",
		usagehelp = "Left-click on stone, dirt, or soil nodes to advance their geological state and sprout wild plants. Repaired with a Februm Crystal (magic_materials:februm_crystal).",
	},
	["gadgets_magic:staff_earth"] = {
		longdesc = "A heavy earth-shaping staff that excavates rock and soil in a 3×3 radius.",
		usagehelp = "Left-click on minable blocks to excavate a 3×3 area. Repaired with a Februm Crystal (magic_materials:februm_crystal).",
	},

	-- ==========================================
	-- 7. Consumables & Reagents
	-- ==========================================
	["gadgets_consumables:potion_mana"] = {
		longdesc = "A crystalline flask filled with shimmering blue mana essence.",
		usagehelp = "Right-click while holding to drink. Instantly restores +15 Mana and grants temporary mana regeneration.",
	},
	["magic_materials:februm_crystal"] = {
		longdesc = "A dense fire-attuned crystal used as a catalyst in enchanting and for repairing magical staves on a crafting table.",
	},
	["magic_materials:aerum_crystal"] = {
		longdesc = "A light air-attuned elemental crystal used in forging magical accessories and spellbooks.",
	},
	["magic_materials:aquam_crystal"] = {
		longdesc = "A water-attuned elemental crystal used in magical crafting recipes.",
	},
	["magic_materials:terram_crystal"] = {
		longdesc = "An earth-attuned elemental crystal used for geological staves and defensive runes.",
	},
	["magic_materials:ignis_crystal"] = {
		longdesc = "A fiery elemental crystal used for pyromantic tomes and offensive weaponry.",
	},

	-- ==========================================
	-- 8. Survival Tools
	-- ==========================================
	["death_compass:compass"] = {
		longdesc = "A specialized compass calibrated to point directly toward the coordinates of your last death location.",
		usagehelp = "Hold in hand or keep in inventory to follow the needle toward your lost items.",
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
