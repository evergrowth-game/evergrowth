# Evergrowth Settlers: Master Development Priorities

This document consolidates all planned features, multiplayer fixes, and infrastructure ideas into a single, logically ordered priority list. Features are organized by dependency, with core foundational systems prioritized first.

## Phase 1: Core Multiplayer Foundation
*These are critical prerequisites for a secure multiplayer environment and advanced features like Trade Hubs.*

1. **Database Refactoring & Legacy Migration (Ownership):** 
   * Update `settlement_db.lua` to store an `owner` string and an `associates` list. 
   * Add a mechanism in the Town Ledger to transfer ownership and manage authorized players.
   * Add a migration hook during database load to assign ownership of unowned legacy settlements to the local host player.
2. **Formspec & Interface Protection:** 
   * Enforce ownership checks in the Ledger and Job Board formspecs.
   * Restrict destructive actions like 'Disband' strictly to the primary owner.
3. **Inventory & Node Protection:** 
   * Add `allow_metadata_inventory_take` and `allow_metadata_inventory_put` callbacks to the **Job Board** and **Town Depot** so only authorized players can access them.
   * Add explicit `can_dig` callbacks to all town infrastructure nodes (Ledger, Depot, Granary, Job Board, Housing Deeds) restricting removal strictly to authorized players, removing the "sneak to break" bypass on the Ledger.
   * Add `on_blast` callbacks to all infrastructure nodes to make them immune to TNT and explosion griefing.
4. **NPC Interaction Security:** 
   * Change the NPC removal/relocation logic to check if the player is the owner or an associate of the town, rather than checking for admin privileges.

## Phase 2: Settlement Integrity & Security
*Systems to protect the town from griefers and provide transparency to the owner.*

5. **Incident Logging (Graveyard):** 
   * Implement a persistent log in the settlement database to track settler deaths.
   * Cache the `puncher` in `on_punch` and determine the cause of death in `on_die` (player, mob, or environment). 
   * Add an interface to the Town Ledger for the owner to review this log.
6. **Proportional Justice System (NPC Damage Deterrence):**
   * Track damage dealt by players and apply consequences based on severity (Accident vs. Assault vs. Murder).
   * **Guard Retaliation (Alarm System):** Implement a distress call in `on_punch` that overrides the vision limits of nearby guards, alerting them to attack the offender.
   * **Reputation Penalty:** Persistently log criminals in the database, causing traders to refuse service permanently or temporarily.
7. **Build Protection Integration:** 
   * Override `minetest.is_protected(pos, name)` to make the Town Ledger a massive protection block, blocking unauthorized building/digging within the town's radius.
   * Ensure deeds can only be placed if the player has permission (hooking into `areas` or `protector` mods).

## Phase 3: Quality of Life & Usability
*Improving the player experience for town planning.*

8. **Visual Boundary Markers:** 
   * Introduce a "Surveyor's Tool" to temporarily highlight the town's invisible 200-block N/S/E/W borders. 
   * Use non-colliding, temporary visual entities (like Techage marker cubes) to avoid particle lag.

## Phase 4: Advanced Logistics & Trade Hubs
*Complex, modular systems for inter-town trading. These explicitly require the Phase 1 Ownership system to prevent griefing.*

9. **Modular Trade Hubs:** 
   * Implement a multi-block "Trade Post" structure centered around a "Trade Desk". 
   * Shipping capacity is determined by building physical "Cargo Crate" nodes around it.
10. **Dockmaster's Ledger:** 
    * A static interaction node for managing trade routes (bulk player logistics or passive export for gold lumps) without relying on wandering NPCs.
11. **Containerized Physical Loading:** 
    * Allow players to pack goods into "Shipping Crate" nodes and place them on a "Loading Bay". 
    * When a shipment departs, the physical crate nodes are removed from the world.
12. **Visual Trade Vehicles:** 
    * Spawn non-loaded-chunk-dependent visual Caravan or Ship entities that navigate along player-placed "Trade Roads" or "Channel Buoys".
    * Dynamically attach individual cargo container models to the base vehicle using `set_attach()` to visually represent the load capacity.
