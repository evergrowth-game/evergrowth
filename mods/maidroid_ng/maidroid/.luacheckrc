max_line_length = false
quiet = 1

globals = {
	"maidroid",
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn", "insert_all"}},

	-- Luanti
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- deps
	"core",
	"default",
	"farming",
	"pipeworks",
	"dye",
	"entity_keys",
	"petz",
	"kitz",
	"cucina_vegana",
	"better_farming",
	"pdisc",
	"pie",
}
