# Evergrowth Villages: Town Management & Satiation System

This document outlines the technical implementation for the **Town Ledger** and the **NPC Satiation (Hunger)** system. This system introduces a recurring maintenance cost for villagers, preventing them from being "free labor" and encouraging agricultural development.

---

## 1. The Town Ledger Node (`eg_settlers:town_ledger`)

The Ledger acts as the heart of a settlement. It tracks the local population and manages the food supply for all villagers within its radius using a centralized world-file database instead of node metadata or high-overhead spatial searches.

### Mechanics:

*   **Global Registration Pattern (Anti-Lag / Anti-Unload):**
    *   To prevent sync failures in unloaded MapBlocks, the system uses a persistent, in-memory Lua database saved to the world directory (`minetest.get_worldpath() .. "/evergrowth_settlements.conf"`).
    *   When a Ledger is placed, it registers its coordinates and a unique `settlement_id` in the world database.
    *   Villagers and their `Housing Deeds` register themselves directly to their parent `settlement_id` in the world database.
    *   If a Deed is dug or relocated, it unregisters itself from the central database, guaranteeing no "ghost residents" or registry corruption even if the Ledger block is unloaded.

*   **Tether Constraints & Ledger Overlap:**
    *   Deeds can only register to the nearest Ledger within a 100-block radius.
    *   Deeds store their linked `settlement_id` in their own metadata and in the world database.

*   **Centralized Consumption Timer (Anti-Pause):**
    *   Daily consumption ticks are managed globally (e.g., via `minetest.register_globalstep` or a daily server tick) using `minetest.get_gametime()`.
    *   This prevents node timer freezes in unloaded mapblocks while avoiding instant catch-up penalties when players return to a frozen chunk.
*   **Town Granary Node (`eg_settlers:town_granary`):**
    *   A separate, physical node linked to the nearest Ledger via the `settlement_id`.
    *   It contains an inventory grid where the player deposits food items.
    *   Items placed in the Granary are immediately **consumed and converted** into `reserve_points` stored in the world database using the `allow_metadata_inventory_put` callbacks, clearing the slots instantly.
    *   This separation ensures the globalstep timer can deduct points from the centralized database without needing the Ledger or Granary mapblocks to be loaded.

    *   **Food Value Hierarchy:**
        *   *Layer A:* Explicit values from a load-time registration intercept of `minetest.item_eat`.
        *   *Layer B:* Fallback check for `farming.registered_foods[item_name]`.
        *   *Layer C:* Fallback to `1 point` per item if the item belongs to `group:food`.

    *   **Process Food Demand (runs each globalstep day-tick):**
        1.  **Count Residents:** Reads the registered resident count for the `settlement_id` from the world database.
        2.  **Calculate Demand:** Each villager requires **4 Satiation Points** per in-game day.
        3.  **Deduct:** Subtract total demand from `reserve_points` in the world database.
        4.  **Update Central State:** 
            *   If `reserve_points >= 0`: Set settlement status to `satiated = 1`.
            *   If `reserve_points < 0`: Set to `satiated = 0` (starving). Clamp `reserve_points` to `0`.

### Town Ledger UI (Formspec):
*   Displays the Town Name (editable) and an option to Disband the town.
*   Displays the current Population (registered deeds count).
*   Status Indicator: "Well-Fed" (green) or "Starving" (red).
*   Displays the full Roster of residents (name, profession, and coordinates).

### Town Granary UI (Formspec):
*   Current Reserve: Shows total `reserve_points` stored.
*   Estimated Time: "Food will last for approximately X more days" based on `reserve_points` and daily demand.
*   Granary Slots: An inventory grid where the player deposits food items (converted to points on insertion).

---

## 2. NPC Satiation Logic

Villagers are no longer independent entities; their willingness to participate in the economy is tied directly to the state of the town Ledger.

### Trade Blocking:
The `on_rightclick` behavior in `npc_behavior.lua` is modified to include a satiation check:
1.  When a player right-clicks a villager to trade, the NPC queries the world database using their home Deed's `settlement_id`.
2.  If **no Ledger is linked**, or if the database states the settlement's status is `satiated = 0` (starving):
    *   The NPC refuses to open the trade interface.
    *   Displays a localized chat message: *"<Name> looks at you with hollow eyes: 'The town is starving... I have nothing to trade.'"*
3.  If the Ledger status is `satiated = 1`, the trade proceeds normally.

---

## 3. Town Depot (Passive Income)

The **Town Dropbox (`eg_settlers:town_depot`)** serves as a centralized collection point for the town's production.

*   **Mechanics:**
    *   Linked to the nearest Ledger via the `settlement_id`.
    *   Once per in-game day, it queries the centralized world database to check if the town is satiated (`satiated = 1`).
    *   If satiated, it generates passive income items based on the professions of all registered residents (e.g., Farmers generate wheat, Miners generate coal) and deposits them into its inventory.
    *   If the town is starving, no items are generated.

---

## 4. Balancing & Gameplay Impact

*   **Automation Sink:** Players who use Techage or other automation mods to generate vast amounts of resources now have a "sink" for that wealth: they must produce enough food to keep their workforce operational.
*   **Settlement Growth:** As the town grows, the food requirement increases linearly, forcing the player to expand their farms or trade for food from other sources.
*   **Centralized Management:** Instead of feeding 20 NPCs individually, the player manages one central "Granary" (the Ledger), making the management task feel like a high-level "Mayor" role rather than a tedious chore.

---

## 5. Settler Healing & Medkit (`eg_settlers:medkit`)

*   **Item & Recipe:**
    *   Craftitem: `eg_settlers:medkit` with custom icon `eg_settlers_medkit.png`.
    *   Shapeless recipe: 1x Leather (`mobs:leather`), 2x Cotton (`farming:cotton`), 1x Magic Root (`magic_materials:magic_root`).
*   **Interaction & `on_rightclick` Interception:**
    *   Registers `minetest.register_on_mods_loaded` hook wrapping `on_rightclick` on `mobs_npc:trader`, `mobs_npc:npc`, and `eg_settlers:*` entities.
    *   Right-clicking an injured settler or companion executes `eg_settlers.use_medkit_on_entity()` to instantly restore maximum health (`self.health` and `object:set_hp()`), play green particle spawner and audio effects, and consume 1 medkit stack.
    *   Intercepts and returns `true` before calling original `on_rightclick`, preventing the trader or dialogue interface from opening.

