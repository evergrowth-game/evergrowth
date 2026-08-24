-- eg_constructs/docs/guide_content.lua
-- In-game documentation for Evergrowth Constructs.

local chapters = {
	{
		id = "overview",
		title = "Constructs Overview",
		text = "Constructs are autonomous mechanical allies manufactured and deployed from portable Core items. They serve as combat defenders and mobile pack mules."
	},
	{
		id = "types",
		title = "Construct Types",
		text = "• Clay Golem:\nHeavy frontline melee combatant and pack mule. High health pool and heavy knockback attacks. Crafted using Clay, Gold Ingots, and Stone.\n\n• Combat Drone:\nHigh-mobility ranged mechanical unit. Discharges laser projectiles at targeted hostiles. Crafted using Steel Ingots, Mese Crystal Fragments, and Copper Ingots."
	},
	{
		id = "operation",
		title = "Cores & Inventory Persistence",
		text = "• Deployment:\nRight-click the ground with a Golem Core or Combat Drone Core to deploy the unit.\n\n• Stance Controls:\nRight-click the deployed construct to open its pack inventory. Sneak+Punch to cycle between Follow and Hold stances.\n\n• Recalling & Inventory Persistence:\nSneak+Right-Click an owned construct with an empty hand to recall it into its Core item. Any items stored inside the construct's pack inventory are preserved inside the Core and restored upon redeployment."
	},
}

-- ==========================================
-- Integration with Wuzzy's `doc`
-- ==========================================
if minetest.get_modpath("doc") then
	doc.add_category("eg_constructs_guide", {
		name = "Evergrowth Constructs",
		description = "Guide to crafting, deploying, and operating mechanical constructs.",
		build_formspec = doc.entry_builders.text,
	})

	for _, chapter in ipairs(chapters) do
		doc.add_entry("eg_constructs_guide", chapter.id, {
			name = chapter.title,
			data = chapter.text,
		})
	end
end

-- ==========================================
-- Integration with `guidebooks`
-- ==========================================
if minetest.get_modpath("guidebooks") then
	guideBooks.Common.register_guideBook("eg_constructs:constructs_guide", {
		description_short = "Construct's Guide",
		description_long = "A guide on manufacturing and commanding mechanical constructs.",
		style = {
			page = { textcolor = "black" }
		}
	})

	guideBooks.Common.register_section("eg_constructs:constructs_guide", "chapters", {
		description = "Chapters",
		hidden = false,
		master = false,
	})

	for i, chapter in ipairs(chapters) do
		guideBooks.Common.register_page("eg_constructs:constructs_guide", "chapters", i, {
			text1 = chapter.title .. "\n\n" .. chapter.text,
		})
	end
end
