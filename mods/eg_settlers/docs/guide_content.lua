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
		title = "3. Housing Deeds & Tethers",
		text = "Housing Deeds act as tethers for your settlers. Once a deed is placed, you must use a Contract on it to assign a resident. \n\nSettlers follow a strict day/night schedule. During the day, they will wander the town. At night, they will return to their deed. If a settler goes missing or dies, their deed can be cleared by Sneak+Right-Clicking it with an empty hand."
	},
	{
		id = "contracts",
		title = "4. Contracts, Professions & Companions",
		text = "Settlers are recruited using Contracts. Different contracts provide different professions, such as Farmers, Miners, and Roboticists, and each offers unique trade opportunities.\n\nRelocation: You can relocate a settler by Sneak+Right-Clicking one that is bound to a deed, which will create a unique Relocation Contract for that specific settler.\n\nCompanions are a completely different type of NPC that are purely ornamental and do not trade. You can customize a companion's appearance using the Wardrobe Wand."
	},
	{
		id = "jobs",
		title = "5. Job Board & Passive Income",
		text = "The Job Board offers daily quests. \n\nAdditionally, your professional settlers generate passive income based on their professions. A Farmer will produce crops, while a Miner produces ores. These resources are automatically deposited into the Town Depot every in-game day. Check the Depot regularly to claim your town's production!"
	},
	{
		id = "defenses",
		title = "6. Town Defenses",
		text = "Towns can be defended by recruiting Guards. Guards are a unique profession that have a larger patrol radius of 45 blocks and stay awake all night to fight monsters. \n\nAdditionally, the Sentinel Ward Stone is a magical defense structure. Once placed, it emits an aura that automatically detects and deals 10 damage to any hostile within a 15-block radius every second."
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
