-- Backwards compatibility with the sickles mod

local sickles_items = {
	"moss",
	"moss_purple",
	"moss_blue",
	"moss_yellow",
	"moss_block",
	"moss_block_purple",
	"moss_block_blue",
	"moss_block_yellow",
	"petals",
	"scythe_bronze",
	"scythe_steel",
	"sickle_bronze",
	"sickle_gold",
	"sickle_steel",
}

for _, item in pairs(sickles_items) do
	core.register_alias_force("sickles:" .. item, "farmtools:" .. item)
end
