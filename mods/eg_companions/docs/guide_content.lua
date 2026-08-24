-- eg_companions/docs/guide_content.lua
-- In-game documentation for Evergrowth Companions.

local chapters = {
	{
		id = "overview",
		title = "1. Companion Hiring & Contracts",
		text = "Companions are humanoid combat allies hired through Hiring Contracts purchased at settlement Job Boards or local taverns.\n\nOnce hired, companions bind to the player who recruited them, providing combat assistance and mobile storage."
	},
	{
		id = "orders",
		title = "2. Command Stances & Inventory",
		text = "Companions can be commanded in the field:\n\n• Follow Stance:\nCompanion follows close behind the player, engaging hostile targets that attack or are attacked by the player.\n\n• Guard Stance:\nCompanion holds their current position and engages any hostiles entering their defensive perimeter.\n\n• Free Roam:\nCompanion wanders locally near their assigned Companion Plaque.\n\n• Pack Inventory:\nRight-click a companion to access their portable pack inventory for field item storage."
	},
	{
		id = "sleep",
		title = "3. Bed Tethering & Sleep Cycles",
		text = "Companions follow a daily routine:\n\n• Daytime (06:00–19:00):\nActive duty, following orders or guarding their designated post.\n\n• Night Sleep (19:00–06:00):\nCompanions navigate to their assigned player bed to rest. While sleeping, companions lie down and play a resting animation. They refuse trade and dialogue interactions until morning."
	},
}

-- ==========================================
-- Integration with Wuzzy's `doc`
-- ==========================================
if minetest.get_modpath("doc") then
	doc.add_category("eg_companions_guide", {
		name = "Evergrowth Companions",
		description = "Guide to hiring, commanding, and managing companions.",
		build_formspec = doc.entry_builders.text,
	})

	for _, chapter in ipairs(chapters) do
		doc.add_entry("eg_companions_guide", chapter.id, {
			name = chapter.title,
			data = chapter.text,
		})
	end
end

-- ==========================================
-- Integration with `guidebooks`
-- ==========================================
if minetest.get_modpath("guidebooks") then
	guideBooks.Common.register_guideBook("eg_companions:companions_guide", {
		description_short = "Companion's Guide",
		description_long = "A guide on hiring and commanding Evergrowth Companions.",
		style = {
			page = { textcolor = "black" }
		}
	})

	guideBooks.Common.register_section("eg_companions:companions_guide", "chapters", {
		description = "Chapters",
		hidden = false,
		master = false,
	})

	for i, chapter in ipairs(chapters) do
		guideBooks.Common.register_page("eg_companions:companions_guide", "chapters", i, {
			text1 = chapter.title .. "\n\n" .. chapter.text,
		})
	end
end
