-- eg_settlers/docs/guide_content.lua

local chapters = {
	{
		id = "intro",
		title = "1. Introduction to Settlements",
		text = "Welcome to Evergrowth Settlements. This guide will teach you how to build a thriving, self-sustaining settlement. You will manage resources, recruit specialized settlers, and protect your town from external threats."
	},
	{
		id = "ledger",
		title = "2. The Town Ledger & Granary",
		text = "The Town Ledger is the heart of your settlement. It tracks your population, resident roster, settlement tier, and food supply. Access Control allows managing authorized players, while Incidents & Justice tracks villager deaths and allows paying restitution fines directly from inventory.\n\nThe Town Granary accepts food items to store and distribute to settlers. Settlers consume food over time. If the Granary runs out of food, your town will begin to starve, and settlers will refuse to trade until it is restocked."
	},
	{
		id = "housing",
		title = "3. Workstations & Bed Tethering",
		text = "Settlers require both a Workstation (Job Block) and a Bed inside town bounds.\n\nSettlers follow a dual-tether schedule: during daytime (06:00–18:00) they work near their assigned Job Block workstation. At night (18:00–06:00), they return to their assigned bed for indoor shelter. Sleeping in a bed designates it as a Player Bed, reserving it from settler assignments."
	},
	{
		id = "contracts",
		title = "4. Hiring Contracts, Workstations & Companions",
		text = "Settlers are recruited using the unified Hiring Contract placed directly onto a Workstation Node (Job Block). Job Blocks (18 professions) and Hiring Contracts are purchased at the Job Board using Gold Lumps directly from your inventory, featuring interactive 3D item previews.\n\nEnvironmental Requirements: Workstations must be placed near required infrastructure (e.g., wet soil for farmers, furnaces for smiths, bookshelves for librarians) before contract placement.\n\nRelocation: Relocate a settler by Sneak+Right-Clicking them, generating a Relocation Contract to place on a new Workstation.\n\nCompanions are ornamental NPCs assigned using Companion Contracts on Housing Deeds."
	},
	{
		id = "jobs",
		title = "5. Job Board & Passive Income",
		text = "The Job Board offers daily bounties alongside contract and workstation procurement.\n\nProfessional settlers generate daily passive income based on their professions (e.g., Farmers produce crops, Miners produce ores). These resources are automatically deposited into the Town Depot every in-game day when the town is well-fed. Check the Depot regularly to claim your town's production!"
	},
	{
		id = "defenses",
		title = "6. Town Defenses & Medical Care",
		text = "Towns can be defended by recruiting Guards. Guards feature 50 HP, a 45-block patrol radius around their Armory Stand, and respond to a 35-block distress alarm whenever villagers take damage.\n\nGuard Shift Rotations:\nGuards automatically alternate between Day Shift and Night Shift upon contract placement, ensuring 24/7 coverage.\n- Day Guards: On duty from 04:30 to 18:30 (4500–18500). Off-duty/sleeping at their assigned bed from 18:30 to 04:30.\n- Night Guards: On duty from 16:30 to 06:30 (16500–6500). Off-duty/sleeping at their assigned bed from 06:30 to 16:30.\n- Shift Overlaps: A 2-hour double-guard overlap occurs at Dawn (04:30–06:30) and Dusk (16:30–18:30) for seamless shift handoffs.\n\nDeferred Wake & Response:\nOff-duty sleeping guards immediately wake to engage enemies if attacked or if an assault triggers the town distress alarm, returning to shelter only after combat concludes.\n\nMagical & Medical Defenses:\nThe Sentinel Ward Stone emits an aura dealing 10 damage to hostiles within 15 blocks every second. To heal injured settlers or guards, right-click them with a Medkit (shapeless craft: 1 Leather, 2 Cotton, 1 Magic Root) to instantly restore them to full health."
	},
	{
		id = "justice",
		title = "7. Law, Justice & Territory Protection",
		text = "Territory Protection:\nTown Ledgers enforce territory build protection across a 100-block radius, securing settlement structures against unauthorized building or digging.\n\nLaw & Misclick Protection:\nStriking villagers is a crime. Bare-hand or tool misclicks (< 4 HP) issue a chat warning without fines. However, repeated light strikes (2 strikes or >= 4 HP cumulative damage) or heavy weapon hits incur an Assault crime (50 Gold Lump restitution fine). Killing a villager incurs a Murder crime (200 Gold Lump fine).\n\nConsequences & Decay:\nMerchants refuse trade with wanted players until fines are paid at the Town Ledger or the record decays (-1 assault severity per 6 in-game days). Town Ledger UI and trade refusal messages display live decay time estimates."
	},
}

-- ==========================================
-- Integration with Wuzzy's `doc`
-- ==========================================
if minetest.get_modpath("doc") then
	doc.add_category("eg_settlers_guide", {
		name = "Evergrowth Settlements",
		description = "A complete guide to building and managing a settlement.",
		build_formspec = doc.entry_builders.text,
	})

	for _, chapter in ipairs(chapters) do
		doc.add_entry("eg_settlers_guide", chapter.id, {
			name = chapter.title,
			data = chapter.text,
		})
	end
end

-- ==========================================
-- Integration with `guidebooks`
-- ==========================================
if minetest.get_modpath("guidebooks") then
	guideBooks.Common.register_guideBook("eg_settlers:settlers_guide", {
		description_short = "Settler's Guide",
		description_long = "A comprehensive guide on managing Evergrowth Settlements.",
		style = {
			page = { textcolor = "black" }
		}
	})

	-- In guidebooks, we need a section first
	guideBooks.Common.register_section("eg_settlers:settlers_guide", "chapters", {
		description = "Chapters",
		hidden = false,
		master = false,
	})

	-- Now register a page for each chapter
	for i, chapter in ipairs(chapters) do
		guideBooks.Common.register_page("eg_settlers:settlers_guide", "chapters", i, {
			text1 = chapter.title .. "\n\n" .. chapter.text,
		})
	end
end
