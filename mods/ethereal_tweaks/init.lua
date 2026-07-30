local heat_sources = {
	"xdecor:lantern",
	"xdecor:lantern_hanging",
	"xdecor:candle",
	"xdecor:iron_lightbox",
	"xdecor:wooden_lightbox",
	"xdecor:wooden2_lightbox",
	"techage:lightblock",
	"techage:ta4_signallamp_2x",
	"techage:ta4_signallamp_4x",
	"techage:furnace_firebox_on",
	"techage:furnace_heater_on",
	"techage:rotor_signal_lamp_on",
	"techage:lighter_burn",
	"techage:coal_lighter_burn",
}

minetest.register_on_mods_loaded(function()
	for _, abm in ipairs(core.registered_abms) do
		if abm.label == "Ethereal melt snow/ice" then
			for _, source in ipairs(heat_sources) do
				table.insert(abm.neighbors, source)
			end
			break
		end
	end
end)
