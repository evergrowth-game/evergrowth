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

## Phase 2: Settler Infrastructure, Job Blocks & Unified Contracts
*Overhauling villager housing, workstation nodes, environment validation, population caps, and contract consolidation. For full technical specs, see [settler_infrastructure_design.md](settler_infrastructure_design.md).*

5. **Job Block Workstations:**
   * Replace generic Housing Deeds with 18 profession-specific Workstation Nodes (Job Blocks) that occupy physical 3D space in workshops.
   * Housing Deeds are retained exclusively for Companion NPCs; Job Blocks replace Housing Deeds in their entirety for all villager professions, functioning identically as tethering nodes.
6. **Unified Hiring Contract:**
   * Replace 18 per-profession contract items with a single `eg_settlers:hiring_contract`.
   * Contracts are placed directly on Job Blocks to derive the profession; free-standing spawning is removed.
7. **Environmental Validation Checks:**
   * Validate surrounding infrastructure (e.g. soil for farmers, furnaces for smiths) before contracts accept placement.
8. **Population Cap & Progression Tiers:**
   * Enforce `Population Cap = Registered Job Blocks` (no bed tracking required).
   * Implement town progression tiers (Outpost, Hamlet, Village) tied to infrastructure nodes (Ledger, Granary, Depot, Ward Stone, Job Board).

## Phase 3: Settlement Integrity & Security
*Systems to protect the town from griefers and provide transparency to the owner.*

9. **Incident Logging (Graveyard):** 
   * Implement a persistent log in the settlement database to track settler deaths.
   * Cache the `puncher` in `on_punch` and determine the cause of death in `on_die` (player, mob, or environment). 
   * Add an interface to the Town Ledger for the owner to review this log. *(Note: Advanced Unburied Remains & Shade mechanics are detailed in [settler_death_mechanic.md](settler_death_mechanic.md) as a future add-on).*
10. **Proportional Justice System (NPC Damage Deterrence):**
    * Track damage dealt by players and apply consequences based on severity (Accident vs. Assault vs. Murder).
    * **Guard Retaliation (Alarm System):** Implement a distress call in `on_punch` that overrides the vision limits of nearby guards, alerting them to attack the offender.
    * **Reputation Penalty:** Persistently log criminals in the database, causing traders to refuse service permanently or temporarily.
11. **Build Protection Integration:** 
    * Override `minetest.is_protected(pos, name)` to make the Town Ledger a massive protection block, blocking unauthorized building/digging within the town's radius.
    * Ensure deeds/job blocks can only be placed if the player has permission (hooking into `areas` or `protector` mods).

## Phase 4: Quality of Life & Usability
*Improving the player experience for town planning.*

12. **Visual Boundary Markers:** 
    * Introduce a "Surveyor's Tool" to temporarily highlight the town's invisible 200-block N/S/E/W borders. 
    * Use non-colliding, temporary visual entities (like Techage marker cubes) to avoid particle lag.

## Phase 5: Advanced Logistics & Trade Hubs
*Complex, modular systems for inter-town trading. These explicitly require the Phase 1 Ownership system to prevent griefing.*

13. **Modular Trade Hubs:** 
    * Implement a multi-block "Trade Post" structure centered around a "Trade Desk". 
    * Shipping capacity is determined by building physical "Cargo Crate" nodes around it.
14. **Dockmaster's Ledger:** 
    * A static interaction node for managing trade routes (bulk player logistics or passive export for gold lumps) without relying on wandering NPCs.
15. **Containerized Physical Loading:** 
    * Allow players to pack goods into "Shipping Crate" nodes and place them on a "Loading Bay". 
    * When a shipment departs, the physical crate nodes are removed from the world.
16. **Visual Trade Vehicles:** 
    * Spawn non-loaded-chunk-dependent visual Caravan or Ship entities that navigate along player-placed "Trade Roads" or "Channel Buoys".
    * Dynamically attach individual cargo container models to the base vehicle using `set_attach()` to visually represent the load capacity.
