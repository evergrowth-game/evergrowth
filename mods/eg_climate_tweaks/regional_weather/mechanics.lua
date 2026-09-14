local hardy_crops = {
	"farming:wheat",
	"farming:barley",
	"farming:rye",
	"farming:oat",
	"farming:carrot",
	"farming:onion",
	"farming:garlic",
	"farming:beetroot",
	"farming:cabbage",
	"farming:spinach",
	"farming:lettuce",
	"farming:parsley",
	"farming:peas"
}

-- Add frost resistance to hardy crops
minetest.register_on_mods_loaded(function()
	local count = 0
	for name, def in pairs(minetest.registered_nodes) do
		for _, crop in ipairs(hardy_crops) do
			-- Match exact name OR name with stage suffix (e.g., farming:carrot_3)
			if name == crop or name:sub(1, #crop + 1) == crop .. "_" then
				local groups = table.copy(def.groups or {})
				groups.frost_resistance = 1
				minetest.override_item(name, {groups = groups})
				count = count + 1
				break
			end
		end
	end
	minetest.log("action", "[Regional Weather] Added frost resistance to " .. count .. " crop nodes.")
end)

-- Chat command to list hardy crops (Dynamic List)
minetest.register_chatcommand("hardy_crops", {
	description = "List all crops that are resistant to frost and snow damage",
	func = function(name)
		local crop_list = ""
		for _, crop in ipairs(hardy_crops) do
			-- Clean up name: remove "farming:" and capitalize
			local clean_name = crop:gsub("farming:", ""):gsub("^%l", string.upper)
			crop_list = crop_list .. clean_name .. ", "
		end
		-- Remove trailing comma
		crop_list = crop_list:sub(1, -3)

		local msg = minetest.colorize("#77ff77", "The following crops are Frost Resistant and will survive the winter:") .. "\n"
		msg = msg .. minetest.colorize("#ffffff", crop_list)
		minetest.chat_send_player(name, msg)
	end
})
