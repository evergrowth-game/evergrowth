-- eg_settlers/docs/guide_content.lua

local chapters = {
	{
		id = "intro",
		title = "1. Introduction to Settlements",
		text = "Welcome to Evergrowth Settlements. This guide covers building and managing a settlement, resource economies, hiring specialized settlers, and town defense."
	},
	{
		id = "ledger",
		title = "2. Town Ledger & Granary",
		text = "The Town Ledger tracks your population, resident roster, settlement tier, and food supply. Access Control allows managing authorized players, while Incidents & Justice tracks villager casualties and enables paying restitution fines directly from inventory.\n\nThe Town Granary stores and distributes food to settlers. Settlers consume food over time. If the Granary runs out of food, the town enters starvation, and settlers will refuse trade until food is restocked."
	},
	{
		id = "housing",
		title = "3. Workstations & Schedules",
		text = "Settlers require both an assigned Workstation (Job Block) and a Bed located within settlement territory.\n\nDaily Schedule:\n• Work Shift (06:00–17:30): Settlers work and wander within a 16-block radius of their assigned Workstation.\n• Evening Gathering (17:30–19:00): Settlers gather and wander in the town square around the Job Board (or Town Ledger).\n• Sleep Shift (19:00–06:00): Settlers sleep in their assigned bed. Sleeping settlers refuse trading and interactions until morning.\n\nBed Ownership:\nSleeping in a bed designates it as a Player Bed, reserving it from settler assignments."
	},
	{
		id = "contracts",
		title = "4. Hiring Contracts & Workstations",
		text = "Settlers are recruited by placing a Hiring Contract onto a Workstation Node (Job Block). Workstations (18 professions) and Hiring Contracts are purchased at the Job Board using Gold Lumps.\n\nEnvironmental Requirements: Workstations must be placed near required infrastructure (e.g., wet soil for farmers, furnaces for smiths, bookshelves for librarians) before contract placement.\n\nRelocation: Sneak+Right-Click a settler to generate a Relocation Contract, which can be placed onto a new Workstation."
	},
	{
		id = "jobs",
		title = "5. Job Board & Passive Income",
		text = "The Job Board offers daily bounties alongside contract and workstation procurement.\n\nSettlers generate daily passive resources based on their profession (e.g., Farmers produce crops, Miners produce ores). These items are deposited into the Town Depot every in-game day when the town is satiated. Access the Depot to claim your town's production."
	},
	{
		id = "defenses",
		title = "6. Town Defenses & Medical Care",
		text = "Guards defend settlements against hostiles. Guards have 50 HP, a 45-block patrol radius around their Armory Stand, and respond to a 35-block distress alarm whenever villagers take damage.\n\nGuard Shift Rotations:\nGuards alternate between Day Shift and Night Shift upon contract placement:\n• Day Guards: On duty from 06:00 to 19:00. Sleep from 19:00 to 06:00.\n• Night Guards: On duty from 17:30 to 06:30. Sleep from 06:30 to 17:30.\n• Shift Overlaps: Guard shifts overlap at Dawn (06:00–06:30) and Dusk (17:30–19:00) for continuous coverage.\n\nCombat Response:\nOff-duty sleeping guards immediately wake to engage enemies if attacked or if the town distress alarm triggers.\n\nMagical & Medical Defenses:\nThe Ward Stone emits an aura dealing 10 damage to hostiles within 15 blocks every second. Right-click injured settlers or guards with a Medkit (craft: 1 Leather, 2 Cotton, 1 Magic Root) to restore full health."
	},
	{
		id = "justice",
		title = "7. Law, Justice & Territory Protection",
		text = "Territory Protection:\nTown Ledgers enforce build protection across a 100-block radius, securing settlement structures against unauthorized building or digging.\n\nLaw Enforcement:\nStriking villagers is a crime. Minor tool/hand hits (< 4 HP) issue a warning. Repeated hits or heavy weapon damage trigger Assault fines (50 Gold Lumps). Killing a villager incurs a Murder fine (200 Gold Lumps).\n\nConsequences:\nMerchants refuse trade with wanted players until fines are settled at the Town Ledger or the record decays (-1 assault severity per 6 in-game days)."
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
