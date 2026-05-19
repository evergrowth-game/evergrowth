# Evergrowth Villages: Town Management & Satiation System

This document outlines the technical implementation for the **Town Ledger** and the **NPC Satiation (Hunger)** system. This system introduces a recurring maintenance cost for villagers, preventing them from being "free labor" and encouraging agricultural development.

---

## 1. The Town Ledger Node (`evergrowth_villages:town_ledger`)

The Ledger acts as the heart of a settlement. It tracks the local population and manages the food supply for all villagers within its radius using a lag-free **Registration** pattern instead of high-overhead area scans.

### Mechanics:

*   **Registration Pattern (Anti-Lag / Anti-Unload):**
    *   To prevent performance-destroying spatial searches (`find_nodes_in_area`), villagers and their `Housing Deeds` register themselves directly with the nearest Ledger upon recruitment or relocation.
    *   The Ledger stores a list of coordinates of its registered deeds in its `nodemeta` (node metadata).
    *   If a Deed is dug or relocated, it unregisters itself from its parent Ledger's metadata.

*   **Tether Constraints & Ledger Overlap:**
    *   Deeds can only register to the nearest Ledger within a 100-block radius.
    *   A Deed stores its parent Ledger's coordinate in its own metadata to ensure strict, unambiguous tethering.

*   **Node Timer & Catch-Up (Anti-Pause):**
    *   Every 1200 seconds (one in-game day), the Ledger triggers a "Consumption Tick".
    *   **Gametime Timestamping:** The Ledger stores the timestamp of its last tick via `minetest.get_gametime()`. If a mapblock unloads and pauses the timer, the next tick calculates the elapsed days that were missed and consumes the appropriate catch-up amount of food in bulk.
    *   **Process Food Demand:**
        1.  **Count Residents:** Reads the number of currently active/registered Deeds from its metadata list.
        2.  **Calculate Demand:** Each villager requires **4 Satiation Points** per in-game day (standardized to a loaf of bread).
        3.  **Process Food Hierarchy:** The Ledger pulls items from its granary inventory. Food points are calculated using the following fallback lookup hierarchy:
            *   *Layer A:* Check `farming.registered_foods[item_name]` for explicit satiation values.
            *   *Layer B:* Look up `minetest.registered_items[item_name]` and inspect `on_use` properties for health/food ratios.
            *   *Layer C:* Fall back to `1 point` per item if the item belongs to `group:food`.
            *   *Example:* A `farming:bread` (5 points) satisfies one villager with 1 leftover point carried over to `reserve_points`. A `farming:garlic` (1 point) requires 4 units to satisfy one villager.
        4.  **Update State:** 
            *   If demand is fully met: `meta:set_int("satiated", 1)`.
            *   If inventory runs dry before demand is met: `meta:set_int("satiated", 0)`.

*   **Metadata State:**
    *   `satiated`: `1` (well-fed) or `0` (starving).
    *   `population`: Integer count of registered residents.
    *   `reserve_points`: Carry-over satiation points (e.g. if a 5-point bread satisfies a 4-point demand, the leftover 1 point is stored here for the next day).
    *   `last_tick`: Standard `minetest.get_gametime()` timestamp of the last consumption check.

### UI (Formspec):
*   Displays the Town Name (Editable).
*   Displays the current Population (registered deeds count).
*   Status Indicator: "Satiated" (Green) or "Starving" (Red).
*   Estimated Time: "Food will last for approximately X more days" based on granary counts and daily demand.

---

## 2. NPC Satiation Logic

Villagers are no longer independent entities; their willingness to participate in the economy is tied directly to the state of the town Ledger.

### Trade Blocking:
The `on_rightclick` behavior in `npc_behavior.lua` is modified to include a satiation check:
1.  When a player right-clicks a villager to trade, the NPC checks the parent Ledger position stored in their home Deed's metadata.
2.  If **no Ledger is linked**, or if the Ledger's metadata states `satiated = 0`:
    *   The NPC refuses to open the trade interface.
    *   Displays a localized chat message: *"<Name> looks at you with hollow eyes: 'The town is starving... I have nothing to trade.'"*
3.  If the Ledger is found and `satiated = 1`, the trade proceeds normally.

---

## 3. Balancing & Gameplay Impact

*   **Automation Sink:** Players who use Techage or other automation mods to generate vast amounts of resources now have a "sink" for that wealth: they must produce enough food to keep their workforce operational.
*   **Settlement Growth:** As the town grows, the food requirement increases linearly, forcing the player to expand their farms or trade for food from other sources.
*   **Centralized Management:** Instead of feeding 20 NPCs individually, the player manages one central "Granary" (the Ledger), making the management task feel like a high-level "Mayor" role rather than a tedious chore.
