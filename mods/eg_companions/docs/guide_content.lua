-- eg_companions/docs/guide_content.lua
-- In-game documentation for Evergrowth Companions.

local chapters = {
	{
		id = "plaque_and_hiring",
		title = "Companion Plaques & Recruitment",
		text = "Companions are domestic NPCs residing in your home. They require a wallmounted Companion Plaque and an assigned Player Bed within 50 blocks.\n\nPlacement & Hiring:\n1. Place a Companion Plaque on a wall inside your house.\n2. Claim a bed by sleeping in it to designate it as your Player Bed.\n3. Place a Hiring Contract onto the Plaque to assign a companion."
	},
	{
		id = "daily_routine",
		title = "Daily Routine & Sleep",
		text = "Companions follow a household routine:\n\n• Daytime (06:00–19:00):\nCompanions wander within a 16-block radius of their Companion Plaque.\n\n• Nighttime (19:00–06:00):\nCompanions sleep in their assigned bed. While sleeping, they lie down and refuse conversation until morning."
	},
	{
		id = "care_and_customization",
		title = "Care, Outfits & Relocation",
		text = "• Conversation & Healing:\nRight-click your companion to talk. Right-click with food items to heal them.\n\n• Outfits:\nHit your companion with a Wardrobe Wand (eg_companions:wardrobe_wand) to cycle through clothing styles.\n\n• Relocation:\nSneak+Right-Click an owned companion with an empty hand to package them into a Relocation Contract, allowing them to be moved to a new Plaque."
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
