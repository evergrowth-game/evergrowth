local mod_stairs = core.get_modpath("stairs")
local mod_walls = core.get_modpath("walls")
local mod_farming = core.get_modpath("farming") ~= nil
local mod_footprints = core.get_modpath("footprints") ~= nil
local mod_nature = core.get_modpath("nature_classic") ~= nil
local mod_moretrees = core.get_modpath("moretrees") ~= nil
local mod_woodsoils = core.get_modpath("woodsoils") ~= nil
local mod_grains = core.get_modpath("grains") ~= nil
local mod_cucina_vegana = core.get_modpath("cucina_vegana") ~= nil
local mod_caverealms = core.get_modpath("caverealms") ~= nil
local mod_df_mapitems = core.get_modpath("df_mapitems") ~= nil
local mod_df_primordial_items = core.get_modpath("df_primordial_items") ~= nil
local mod_ethereal = core.get_modpath("ethereal") ~= nil
local mod_gloopblocks = core.get_modpath("gloopblocks") ~= nil
local mod_underch = core.get_modpath("underch") ~= nil
local mod_mcl_core = core.get_modpath("mcl_core") ~= nil
local mod_mcl_walls = core.get_modpath("mcl_walls") ~= nil
local mod_mcl_stairs = core.get_modpath("mcl_stairs") ~= nil
local mod_mcl_farming = core.get_modpath("mcl_farming") ~= nil

local function register_mcl_cuttable_range(nodename, base, item, number)
	for i = 0, number do
		farmtools.register_cuttable(nodename .. "_" .. i, base .. "_" .. i, item)
	end
end

if mod_mcl_core then
	farmtools.register_cuttable("mcl_core:dirt_with_grass", "mcl_core:dirt", "mcl_flowers:double_grass")
	farmtools.register_cuttable("mcl_core:mossycobble", "mcl_core:cobble", "sickles:moss")
	farmtools.register_cuttable("mcl_core:stonebrickmossy", "mcl_core:stonebrick", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_stonebrickmossy", "mcl_stairs:stair_stonebrick", "sickles:moss")
	farmtools.register_cuttable(
		"mcl_stairs:stair_stonebrickmossy_inner",
		"mcl_stairs:stair_stonebrick_inner",
		"sickles:moss"
	)
	farmtools.register_cuttable(
		"mcl_stairs:stair_stonebrickmossy_outer",
		"mcl_stairs:stair_stonebrick_outer",
		"sickles:moss"
	)
	farmtools.register_cuttable("mcl_stairs:slab_stonebrickmossy", "mcl_stairs:slab_stonebrick", "sickles:moss")
	farmtools.register_cuttable(
		"mcl_stairs:slab_stonebrickmossy_double",
		"mcl_stairs:slab_stonebrick_double",
		"sickles:moss"
	)
	farmtools.register_cuttable("mcl_stairs:slab_stonebrickmossy_top", "mcl_stairs:slab_stonebrick_top", "sickles:moss")
else -- default
	farmtools.register_cuttable("default:dirt_with_grass", "default:dirt", "default:grass_1")
	farmtools.register_cuttable("default:dirt_with_dry_grass", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("default:dry_dirt_with_dry_grass", "default:dry_dirt", "default:dry_grass_1")
	farmtools.register_cuttable("default:dirt_with_rainforest_litter", "default:dirt", "default:junglegrass")
	farmtools.register_cuttable("default:dirt_with_coniferous_litter", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("default:permafrost_with_moss", "default:permafrost", "sickles:moss")
	farmtools.register_cuttable("default:mossycobble", "default:cobble", "sickles:moss")
end

if mod_mcl_walls then
	farmtools.register_cuttable("mcl_walls:mossycobble", "mcl_walls:cobble", "sickles:moss")
	register_mcl_cuttable_range("mcl_walls:mossycobble", "mcl_walls:cobble", "sickles:moss", 21)
	farmtools.register_cuttable("mcl_walls:stonebrickmossy", "mcl_walls:stonebrick", "sickles:moss")
	register_mcl_cuttable_range("mcl_walls:stonebrickmossy", "mcl_walls:stonebrickmossy", "sickles:moss", 21)
end
if mod_walls then
	farmtools.register_cuttable("walls:mossycobble", "walls:cobble", "sickles:moss")
end

if mod_mcl_stairs then
	farmtools.register_cuttable("mcl_stairs:slab_mossycobble", "mcl_stairs:slab_cobble", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:slab_mossycobble_double", "mcl_stairs:slab_cobble_double", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:slab_mossycobble_top", "mcl_stairs:slab_cobble_top", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_mossycobble", "mcl_stairs:stair_cobble", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_mossycobble_inner", "mcl_stairs:stair_cobble_inner", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_mossycobble_outer", "mcl_stairs:stair_cobble_outer", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_inner_mossycobble", "mcl_stairs:stair_inner_cobble", "sickles:moss")
	farmtools.register_cuttable("mcl_stairs:stair_outer_mossycobble", "mcl_stairs:stair_outer_cobble", "sickles:moss")
end
if mod_stairs then
	farmtools.register_cuttable("stairs:slab_mossycobble", "stairs:slab_cobble", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_mossycobble", "stairs:stair_cobble", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_inner_mossycobble", "stairs:stair_inner_cobble", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_outer_mossycobble", "stairs:stair_outer_cobble", "farmtools:moss")
end

if mod_footprints then
	farmtools.register_cuttable("footprints:dirt_with_dry_grass", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("footprints:dry_dirt_with_dry_grass", "default:dry_dirt", "default:dry_grass_1")
	farmtools.register_cuttable("footprints:dirt_with_rainforest_litter", "default:dirt", "default:junglegrass")
	farmtools.register_cuttable("footprints:dirt_with_coniferous_litter", "default:dirt", "default:dry_grass_1")
end

if mod_nature and not mod_moretrees then
	farmtools.register_cuttable("nature:blossom", "default:leaves", "farmtools:petals")
end

if mod_moretrees then
	farmtools.register_cuttable("moretrees:apple_blossoms", "moretrees:apple_tree_leaves", "farmtools:petals")
end

if mod_woodsoils then
	farmtools.register_cuttable("woodsoils:dirt_with_leaves_1", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("woodsoils:dirt_with_leaves_2", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("woodsoils:grass_with_leaves_1", "default:dirt", "default:dry_grass_1")
	farmtools.register_cuttable("woodsoils:grass_with_leaves_2", "default:dirt", "default:dry_grass_1")
end

if mod_mcl_farming then
	farmtools.register_trimmable("mcl_farming:wheat", "mcl_farming:wheat_2")
	-- one does not use a sickle for beetroots, pumpkins, or melons
end
if mod_farming then
	farmtools.register_trimmable("farming:wheat_8", "farming:wheat_2")
end

if mod_farming and farming ~= nil and farming.mod == "redo" then
	farmtools.register_trimmable("farming:rye_8", "farming:rye_2")
	farmtools.register_trimmable("farming:oat_8", "farming:oat_2")
	farmtools.register_trimmable("farming:barley_7", "farming:barley_2")
	farmtools.register_trimmable("farming:rice_8", "farming:rice_2")
end

if mod_grains then
	farmtools.register_trimmable("grains:rye_8", "grains:rye_2")
	farmtools.register_trimmable("grains:oat_8", "grains:oat_2")
	farmtools.register_trimmable("grains:barley_8", "grains:barley_2")
	farmtools.register_trimmable("grains:rice_8", "grains:rice_2")
end

if mod_cucina_vegana then
	farmtools.register_trimmable("cucina_vegana:rice_6", "cucina_vegana:rice_2")
end

if mod_caverealms then
	farmtools.register_cuttable("caverealms:stone_with_moss", "default:cobble", "farmtools:moss")
	farmtools.register_cuttable("caverealms:stone_with_lichen", "default:cobble", "farmtools:moss_purple")
	farmtools.register_cuttable("caverealms:stone_with_algae", "default:cobble", "farmtools:moss_yellow")
end

if mod_df_mapitems then
	farmtools.register_cuttable("df_mapitems:dirt_with_cave_moss", "default:cobble", "farmtools:moss_blue")
	farmtools.register_cuttable("df_mapitems:cobble_with_floor_fungus", "default:cobble", "farmtools:moss_yellow")
	farmtools.register_cuttable("df_mapitems:cobble_with_floor_fungus_fine", "default:cobble", "farmtools:moss_yellow")
	farmtools.register_cuttable("df_mapitems:ice_with_hoar_moss", "default:ice", "farmtools:moss_blue")
end

if mod_df_primordial_items then
	farmtools.register_cuttable(
		"df_primordial_items:dirt_with_mycelium",
		"default:dirt",
		"df_primordial_items:fungal_grass_1"
	)
	farmtools.register_cuttable(
		"df_primordial_items:jungle_tree_mossy",
		"df_primordial_items:jungle_tree",
		"farmtools:moss"
	)
	farmtools.register_cuttable(
		"df_primordial_items:jungle_tree_glowing",
		"df_primordial_items:jungle_tree",
		"df_primordial_items:mushroom_gills_glowing"
	)
	farmtools.register_cuttable(
		"df_primordial_items:dirt_with_jungle_grass",
		"default:dirt",
		"df_primordial_items:jungle_grass_1"
	)
end

if mod_ethereal then
	farmtools.register_cuttable("ethereal:bamboo_dirt", "default:dirt", "default:grass_1")
	farmtools.register_cuttable("ethereal:cold_dirt", "default:dirt", "default:grass_1")
	farmtools.register_cuttable("ethereal:crystal_dirt", "default:dirt", "ethereal:crystalgrass")
	farmtools.register_cuttable("ethereal:fiery_dirt", "default:dirt", "ethereal:dry_shrub")
	farmtools.register_cuttable("ethereal:gray_dirt", "default:dirt", "ethereal:snowygrass")
	farmtools.register_cuttable("ethereal:grove_dirt", "default:dirt", "farmtools:moss")
	farmtools.register_cuttable("ethereal:jungle_dirt", "default:dirt", "default:junglegrass")
	farmtools.register_cuttable("ethereal:mushroom_dirt", "default:dirt", "flowers:mushroom_red")
	farmtools.register_cuttable("ethereal:prairie_dirt", "default:dirt", "farmtools:petals")
end

if mod_gloopblocks then
	farmtools.register_cuttable("gloopblocks:stone_brick_mossy", "default:stonebrick", "farmtools:moss")
	farmtools.register_cuttable("gloopblocks:stone_mossy", "default:stone", "farmtools:moss")
	farmtools.register_cuttable("gloopblocks:cobble_road_mossy", "gloopblocks:cobble_road", "farmtools:moss")
end

if mod_gloopblocks and mod_stairs then
	farmtools.register_cuttable("stairs:stair_stone_mossy", "stairs:stair_stone", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_inner_stone_mossy", "stairs:stair_inner_stone", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_outer_stone_mossy", "stairs:stair_outer_stone", "farmtools:moss")
	farmtools.register_cuttable("stairs:slab_stone_mossy", "stairs:slab_stone", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_stone_brick_mossy", "stairs:stair_stonebrick", "farmtools:moss")
	farmtools.register_cuttable(
		"stairs:stair_inner_stone_brick_mossy",
		"stairs:stair_inner_stonebrick",
		"farmtools:moss"
	)
	farmtools.register_cuttable(
		"stairs:stair_outer_stone_brick_mossy",
		"stairs:stair_outer_stonebrick",
		"farmtools:moss"
	)
	farmtools.register_cuttable("stairs:slab_stone_brick_mossy", "stairs:slab_stonebrick", "farmtools:moss")
	farmtools.register_cuttable("stairs:stair_cobble_road_mossy", "stairs:stair_cobble_road", "farmtools:moss")
	farmtools.register_cuttable(
		"stairs:stair_inner_cobble_road_mossy",
		"stairs:stair_inner_cobble_road",
		"farmtools:moss"
	)
	farmtools.register_cuttable(
		"stairs:stair_outer_cobble_road_mossy",
		"stairs:stair_outer_cobble_road",
		"farmtools:moss"
	)
	farmtools.register_cuttable("stairs:slab_cobble_road_mossy", "stairs:slab_cobble_road", "farmtools:moss")
end

if mod_underch then
	farmtools.register_cuttable("underch:mossy_dirt", "default:dirt", "farmtools:moss")
	farmtools.register_cuttable("underch:mossy_gravel", "default:gravel", "farmtools:moss")
end
