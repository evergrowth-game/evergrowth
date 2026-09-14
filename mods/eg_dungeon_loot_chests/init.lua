-- Alias original loot chest nodes to raiders:bootynode
-- This ensures that ruined_structures schematics place bootynodes

minetest.register_alias("dungeon_loot_chests:loot_chest", "raiders:bootynode")
minetest.register_alias("dungeon_loot_chests:ice_loot_chest", "raiders:bootynode")
minetest.register_alias("dungeon_loot_chests:sandstone_loot_chest", "raiders:bootynode")
minetest.register_alias("dungeon_loot_chests:desert_loot_chest", "raiders:bootynode")

minetest.log("action", "[dungeon_loot_chests] Dummy mod loaded with aliases to raiders:bootynode")
