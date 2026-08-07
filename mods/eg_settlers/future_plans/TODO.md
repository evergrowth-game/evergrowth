# Evergrowth Settlers Development TODO List

This TODO list tracks the status of all planned features from the [Master Development Priorities](master_priority_list.md).

## Phase 1: Core Multiplayer Foundation (Complete)
- [x] **Database Refactoring & Legacy Migration (Ownership)**
  - [x] Update [settlement_db.lua](../api/settlement_db.lua) to store `owner` string and `associates` list.
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

## Phase 2: Settler Infrastructure, Job Blocks & Unified Contracts
- [ ] **Job Block Registration & Workstation Nodes**
  - [ ] Implement `town/job_blocks.lua` helper and register 18 job blocks.
  - [ ] Job blocks replace Housing Deeds for all 18 villager professions, functioning identically as tethering nodes.
  - [ ] Retain `housing_deed` exclusively for Companion NPCs (`contract_companion_male`, etc.).
  - [ ] Store `occupied`, `resident_name`, `profession`, `settlement_id` metadata.
- [ ] **Unified Hiring Contract**
  - [ ] Replace 18 contract craftitems with single `eg_settlers:hiring_contract`.
  - [ ] Update `on_place` to derive profession from target job block.
  - [ ] Update `contract_villager_relocation` to target job blocks.
  - [ ] Adapt `job_board.lua` Contracts tab to dispense `hiring_contract`.
  - [ ] Register item aliases in `api/aliases.lua` for backward compatibility.
  - [ ] Deprecate `housing_deed` on_rightclick message for villagers and update NPC pathfinding to job blocks.
  - [ ] Update `docs/guide_content.lua`.
- [ ] **Environmental Validation Checks**
  - [ ] Implement `validate_job_block_environment(pos, profession)` in `api/settlement.lua`.
  - [ ] Enforce environmental requirements before contract placement.
- [ ] **Population Cap & Town Progression Tiers**
  - [ ] Enforce `Population Cap = Registered Job Blocks` in `town_ledger.lua` (no bed tracking).
  - [ ] Implement Town Progression Tiers (Outpost, Hamlet, Village) tied to infrastructure nodes.

## Phase 3: Settlement Integrity & Security
- [ ] **Incident Logging (Graveyard)**
  - [ ] Implement a persistent log in the settlement database to track settler deaths.
  - [ ] Cache the `puncher` in `on_punch` and determine the cause of death in `on_die` (player, mob, or environment).
  - [ ] Add an interface to the Town Ledger for the owner to review this log. *(Unburied Remains / Shade mechanics deferred to future add-on).*
- [ ] **Proportional Justice System (NPC Damage Deterrence)**
  - [ ] Track damage dealt by players and apply consequences based on severity (Accident vs. Assault vs. Murder).
  - [ ] **Guard Retaliation (Alarm System):** Implement distress call in `on_punch` to override guards' vision limits.
  - [ ] **Reputation Penalty:** Persistently log criminals in the database, causing traders to refuse service.
- [ ] **Build Protection Integration**
  - [ ] Override `minetest.is_protected(pos, name)` to make the Town Ledger act as a protection block within the town radius.
  - [ ] Hook housing deeds / job blocks checks into `areas` or `protector` mods to ensure valid placement permissions.

## Phase 4: Quality of Life & Usability
- [ ] **Visual Boundary Markers**
  - [ ] Introduce a "Surveyor's Tool" to temporarily highlight town borders.
  - [ ] Use non-colliding visual entities to avoid particle lag.

## Phase 5: Advanced Logistics & Trade Hubs
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
