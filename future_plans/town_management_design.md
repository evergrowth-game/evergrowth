# Evergrowth Villages: Town Management & Satiation System

This document outlines the technical implementation for the **Town Ledger** and the **NPC Satiation (Hunger)** system. This system introduces a recurring maintenance cost for villagers, preventing them from being "free labor" and encouraging agricultural development.

## 1. The Town Ledger Node (`evergrowth_villages:town_ledger`)

The Ledger acts as the heart of a settlement. It tracks the local population and manages the food supply for all villagers within its radius.

### Mechanics:
*   **Registration:** When placed, it establishes a "Town Center" point.
*   **Inventory (The Granary):** A 4x4 or 8x4 inventory slot that only accepts items from the `group:food` category.
*   **Node Timer:** Every 1200 seconds (one in-game day), the ledger triggers a "Consumption Tick":
    1.  **Count Deeds:** Scans a 100-block radius for occupied `evergrowth_villages:housing_deed` nodes.
    2.  **Calculate Demand:** Each villager requires **4 Satiation Points** per day (standardized to a loaf of bread).
    3.  **Process Food:** The Ledger scans its inventory and "eats" items to fulfill the total point demand.
        *   It reads the satiation value from the `farming.registered_foods` table or the item's `on_use` effect.
        *   *Example:* A `farming:bread` (5 points) satisfies one villager with 1 point left over. A `farming:garlic` (1 point) requires 4 units to satisfy one villager.
    4.  **Update State:** 
        *   If the point demand is met: `meta:set_int("satiated", 1)`.
        *   If the inventory runs dry before the demand is met: `meta:set_int("satiated", 0)`.
*   **Metadata State:**
    *   `satiated = 1`: The town is well-fed.
    *   `satiated = 0`: The town is starving.
    *   `population`: Current count of residents.
    *   `reserve_points`: Any leftover satiation points carried over to the next day.

### UI (Formspec):
*   Displays the Town Name (Editable).
*   Displays the current Population.
*   Status Indicator: "Satiated" (Green) or "Starving" (Red).
*   Estimated Time: "Food will last for approximately X more days."

---

## 2. NPC Satiation Logic

Villagers are no longer independent entities; their willingness to participate in the economy is tied to the state of the town.

### Trade Blocking:
The `on_rightclick` behavior in `npc_behavior.lua` is modified to include a satiation check:
1.  When a player right-clicks a villager to trade, the NPC searches for the nearest `evergrowth_villages:town_ledger` within 100 blocks.
2.  If **no ledger** is found, or if the ledger's metadata is `satiated = 0`:
    *   The NPC refuses to open the trade formspec.
    *   Displays a chat message: *"<Name> looks at you with hollow eyes: 'The town is starving... I have nothing to trade.'"*
3.  If the ledger is found and `satiated = 1`, the trade proceeds normally.

---

## 3. Balancing & Gameplay Impact

*   **Automation Sink:** Players who use Techage or other automation mods to generate vast amounts of resources now have a "sink" for that wealth: they must produce enough food to keep their workforce operational.
*   **Settlement Growth:** As the town grows, the food requirement increases linearly, forcing the player to expand their farms or trade for food from other sources.
*   **Centralized Management:** Instead of feeding 20 NPCs individually, the player manages one central "Granary" (the Ledger), making the management task feel like a high-level "Mayor" role rather than a tedious chore.
