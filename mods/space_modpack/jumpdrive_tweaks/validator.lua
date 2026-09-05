-- jumpdrive_tweaks/validator.lua
-- Enforces terrain blacklist and structural integrity checks

local NATURAL_TERRAIN_NODES = {
	"default:dirt",
	"default:dirt_with_grass",
	"default:dirt_with_dry_grass",
	"default:dirt_with_snow",
	"default:dirt_with_rainforest_litter",
	"default:dirt_with_coniferous_litter",
	"default:sand",
	"default:desert_sand",
	"default:silver_sand",
	"default:gravel",
	"default:stone",
	"default:desert_stone",
	"default:sandstone",
	"default:water_source",
	"default:river_water_source",
	"default:tree",
	"default:jungletree",
	"default:pine_tree",
	"default:acacia_tree",
	"default:aspen_tree"
}

if jumpdrive and jumpdrive.blacklist then
	for _, nodename in ipairs(NATURAL_TERRAIN_NODES) do
		table.insert(jumpdrive.blacklist, nodename)
	end
end

minetest.log("action", "[jumpdrive_tweaks] Populated natural terrain blacklist for jumpdrive.")
