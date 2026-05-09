# Village Expansion Plan

## Goal
Enrich village variety by adding 3 new building types with corresponding professions, utilizing the full range of [recovered_trades.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/recovered_trades.lua).

## User Review Required
> [!NOTE]
> We are adding "Innkeeper", "Lumberjack", and "Miner" professions. The Miner's hut might look a bit odd on flat ground (it usually wants a hillside), so we'll design it as a "Mining Office" or "Ore Store" style building.

## Proposed Changes

### 1. New Structures ([structures.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/evergrowth_villages/structures.lua))
*   **Tavern (Inn)**: A larger 10x10 or 12x10 building.
    *   Features: `default:fence_wood`+`xdecor:cushion` (Tables), `xdecor:chair`, `xdecor:barrel`, `xdecor:cabinet`.
    *   Spawner: `spawn_innkeeper`.
*   **Lumberjack's Hut**: A rustic wooden cabin.
    *   Features: Log piles (wood nodes oriented), tree stumps outside, `xdecor:workbench`.
    *   Spawner: `spawn_lumberjack`.
*   **Miner's Shack**: A rough stone building.
    *   Features: `xdecor:enderchest` (secure storage), ore blocks, `xdecor:lantern`.
    *   Spawner: `spawn_miner`.
*   **Library** (Bonus): A variant of the Merchant house.
    *   Features: `default:bookshelf` (xdecor doesn't have a specific bookcase node, just `empty_shelf`/`multishelf`). 
    *   Spawner: `spawn_librarian` (Variant of Merchant trade).
*   **Mage Tower**: A small tower (cobble/stonebrick) with "magic" decor (`xdecor:enchantment_table` - wait, checking if this exists. [enchanting.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/xdecor/src/enchanting.lua) exists in `src`).
    *   Spawner: `spawn_mage`.
    *   Trades: `magic_materials` items (runes, crystals) and [bweapons_magic_pack](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/bweapons_modpack_custom/bweapons_magic_pack) weapons (tomes, staffs).

### 2. Trade Updates ([init.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/xdecor/init.lua))
*   Import full trade tables from [recovered_trades.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/recovered_trades.lua) logic (or define them inline if better for control).
*   Add localized trade definitions for:
    *   **Innkeeper**: Sells food/drink, buys farming goods.
    *   **Lumberjack**: Sells wood/saplings/axes, buys food.
    *   **Miner**: Sells ores/cobble, buys picks/food.
    *   **Librarian**: Sells books/paper/glass, buys gems.
    *   **Mage**: Sells magical tomes, staves, and runes.

### 3. Generation Logic ([init.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/xdecor/init.lua))
*   Update `building_deck` to include new buildings.
*   **Weighting**:
    *   Tavern: 1 per village (High priority).
    *   Library: 1 per village (Medium priority).
    *   Mage Tower: 1 per village (Low priority, rare).
    *   Lumberjack/Miner: Random filler (Medium priority).

### 4. Debug Tools
*   **Village Locator**: Implement a command `/locate_village`.
    *   **Logic**: It tracks the **latest generated village** in a global variable during `on_generated`.
    *   **Note**: It only finds villages generated *after* the mod is reloaded. It cannot find old ones.



## Verification Plan
1.  Generate new villages.
2.  Check for presence of new buildings.
3.  Right-click new NPCs to verify trade lists are correct.
