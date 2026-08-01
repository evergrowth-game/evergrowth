# Evergrowth Settlers Development TODO List

This TODO list tracks the status of all planned features from the [Master Development Priorities](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/eg_settlers/future_plans/master_priority_list.md).

## Phase 1: Core Multiplayer Foundation (Complete)
- [x] **Database Refactoring & Legacy Migration (Ownership)**
  - [x] Update [settlement_db.lua](file:///Users/Aresh/Library/Application%20Support/minetest/games/evergrowth/mods/eg_settlers/api/settlement_db.lua) to store `owner` string and `associates` list.
  - [x] Add Access Control tab to Town Ledger to transfer ownership and manage authorized players.
  - [x] Add migration hook during database load to assign ownership of unowned legacy settlements to the host player.
- [x] **Formspec & Interface Protection**
  - [x] Enforce ownership checks in Ledger and Job Board formspecs.
  - [x] Restrict destructive actions like 'Disband' strictly to the primary owner.
- [x] **Inventory & Node Protection**
  - [x] Add `allow_metadata_inventory_take/put/move` callbacks to Job Board and Town Depot.
  - [x] Add explicit `can_dig` callbacks to Ledger, Depot, Granary, Job Board, and Housing Deeds.
  - [x] Add `on_blast` callbacks to all town infrastructure nodes.
- [x] **NPC Interaction Security**
  - [x] Restrict villager relocation/removal to town owners and associates.

## Phase 2: Settlement Integrity & Security
- [ ] **Incident Logging (Graveyard)**
  - [ ] Implement a persistent log in the settlement database to track settler deaths.
  - [ ] Cache the `puncher` in `on_punch` and determine the cause of death in `on_die` (player, mob, or environment).
  - [ ] Add an interface to the Town Ledger for the owner to review this log.
- [ ] **Proportional Justice System (NPC Damage Deterrence)**
  - [ ] Track damage dealt by players and apply consequences based on severity (Accident vs. Assault vs. Murder).
  - [ ] **Guard Retaliation (Alarm System):** Implement distress call in `on_punch` to override guards' vision limits.
  - [ ] **Reputation Penalty:** Persistently log criminals in the database, causing traders to refuse service.
- [ ] **Build Protection Integration**
  - [ ] Override `minetest.is_protected(pos, name)` to make the Town Ledger act as a protection block within the town radius.
  - [ ] Hook housing deeds checks into `areas` or `protector` mods to ensure valid placement permissions.

## Phase 3: Quality of Life & Usability
- [ ] **Visual Boundary Markers**
  - [ ] Introduce a "Surveyor's Tool" to temporarily highlight town borders.
  - [ ] Use non-colliding visual entities to avoid particle lag.

## Phase 4: Advanced Logistics & Trade Hubs
- [ ] **Modular Trade Hubs**
  - [ ] Implement multi-block "Trade Post" structure centered around a "Trade Desk".
  - [ ] Determine shipping capacity via physical "Cargo Crate" nodes built around the Trade Post.
- [ ] **Dockmaster's Ledger**
  - [ ] Implement a static interaction node for managing trade routes without wandering NPCs.
- [ ] **Containerized Physical Loading**
  - [ ] Allow players to pack goods into "Shipping Crate" nodes placed on a "Loading Bay" that are removed when the shipment departs.
- [ ] **Visual Trade Vehicles**
  - [ ] Spawn non-loaded-chunk-dependent visual Caravan or Ship entities navigating along player-placed "Trade Roads" or "Channel Buoys".
  - [ ] Dynamically attach cargo container models using `set_attach()`.
