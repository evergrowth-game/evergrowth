local S = minetest.get_translator("farming_tweaks")

minetest.register_on_mods_loaded(function()
	if minetest.registered_items["farming:kitkat"] then
		minetest.override_item("farming:kitkat", {
			description = S("Chocolate Wafer Bar"),
		})
	end
end)
