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
		text = "The Town Ledger is the heart of your settlement. It tracks your total population and the village's food supply. \n\nThe Town Granary is a separate block with an inventory, and accepts food items to store and distribute to settlers. Settlers consume food over time. If the Granary runs out of food, your town will begin to starve, and settlers will refuse to trade with you until it is restocked."
	},
	{
		id = "housing",
		title = "3. Workstations & Bed Tethering",
		text = "Settlers require both a Workstation (Job Block) and a Bed inside town bounds. \n\nSettlers follow a dual-tether schedule: during daytime (06:00–18:00) they work near their assigned Job Block workstation. At night (18:00–06:00), they return to their assigned bed for indoor shelter. Sleeping in a bed designates it as a Player Bed, reserving it from settler assignments."
	},
	{
		id = "contracts",
		title = "4. Hiring Contracts, Workstations & Companions",
		text = "Settlers are recruited using the unified Hiring Contract placed directly onto a Workstation Node (Job Block). Job Blocks and Hiring Contracts can be purchased at the Job Board for Gold Lumps. \n\nEnvironmental Requirements: Workstations must be placed near required infrastructure (e.g. wet soil for farmers, furnaces for smiths, bookshelves for librarians) before accepting a contract.\n\nRelocation: You can relocate a settler by Sneak+Right-Clicking them, generating a Relocation Contract to place on a new Workstation.\n\nCompanions are ornamental NPCs assigned using Companion Contracts on Housing Deeds."
	},

	{
		id = "jobs",
		title = "5. Job Board & Passive Income",
		text = "The Job Board offers daily quests. \n\nAdditionally, your professional settlers generate passive income based on their professions. A Farmer will produce crops, while a Miner produces ores. These resources are automatically deposited into the Town Depot every in-game day. Check the Depot regularly to claim your town's production!"
	},
	{
		id = "defenses",
		title = "6. Town Defenses & Healing",
		text = "Towns can be defended by recruiting Guards. Guards are a unique profession that have a larger patrol radius of 45 blocks and stay awake all night to fight monsters. \n\nAdditionally, the Sentinel Ward Stone is a magical defense structure. Once placed, it emits an aura that automatically detects and deals 10 damage to any hostile within a 15-block radius every second. \n\nTo heal injured settlers or companions, right-click them with a Medkit (shapeless craft: 1 Leather, 2 Cotton, 1 Magic Root) to instantly restore them to full health."
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
