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
- [x] **Dual Tethering (Job Block + Bed Node)**
  - [x] Add Bed node (`group:bed`) unassigned scanner in `api/settlement.lua`.
  - [x] Update `hiring_contract` `on_place` to verify unassigned bed availability and store both `job_pos` and `home_pos` metadata.
  - [x] Update `npc_behavior.lua` day/night cycle: daytime active at `job_pos` (06:00–18:00), nighttime standing shelter at `home_pos` bed (18:00–06:00).
- [x] **Town Ledger Starter Kit**
  - [x] Update `town_ledger.lua` `after_place_node` to award `1x job_block_farmer` + `1x hiring_contract` directly to placer inventory (dropping if full).
- [x] **Job Board Procurement Hub (No 3x3 Grid Recipes)**
  - [x] Add Workstations tab to `job_board.lua` formspec to purchase 18 Job Blocks for gold.
  - [x] Adapt Contracts tab in `job_board.lua` to dispense `hiring_contract` for gold.
- [x] **Job Block Registration & Workstation Nodes**
  - [x] Implement `town/job_blocks.lua` helper and register 18 job blocks.
  - [x] Job blocks replace Housing Deeds for all 18 villager professions, functioning as workstation nodes.
  - [x] Spun off Companion NPCs and wallmounted Companion Plaques into dedicated standalone mod `eg_companions`.
  - [x] Store `occupied`, `resident_name`, `profession`, `settlement_id`, `job_pos`, `home_pos` metadata.
- [x] **Unified Hiring Contract**
  - [x] Replace 18 contract craftitems with single `eg_settlers:hiring_contract`.
  - [x] Update `on_place` to derive profession from target job block, verify bed, and check environment.
  - [x] Update `contract_villager_relocation` to target job blocks.
  - [x] Register item aliases in `api/aliases.lua` for backward compatibility.
  - [x] Deprecate `housing_deed` on_rightclick message for villagers.
  - [x] Update `docs/guide_content.lua`.
- [x] **Environmental Validation Checks**
  - [x] Implement `validate_job_block_environment(pos, profession)` in `api/settlement.lua`.
  - [x] Enforce environmental requirements before contract placement.
- [x] **Population Cap & Town Progression Tiers**
  - [x] Enforce `Population Cap = Registered Job Blocks` (requiring assigned beds).
  - [x] Implement Town Progression Tiers (Outpost, Hamlet, Village) tied to infrastructure nodes.


## Phase 3: Settlement Integrity & Security
- [x] **Incident Logging (Graveyard)**
  - [x] Implement a persistent log in the settlement database to track settler deaths.
  - [x] Cache the `puncher` in `on_punch` and determine the cause of death in `on_die` (player, mob, or environment).
  - [x] Add an interface to the Town Ledger for the owner to review this log. *(Unburied Remains / Shade mechanics deferred to future add-on).*
- [x] **Proportional Justice System (NPC Damage Deterrence)**
  - [x] Track damage dealt by players and apply consequences based on severity (Accident vs. Assault vs. Murder).
  - [x] **Guard Retaliation (Alarm System):** Implement distress call in `on_punch` to override guards' vision limits.
  - [x] **Reputation Penalty:** Persistently log criminals in the database, causing traders to refuse service.
- [x] **Build Protection Integration**
  - [x] Override `minetest.is_protected(pos, name)` to make the Town Ledger act as a protection block within the town radius.
  - [x] Hook housing deeds / job blocks checks into `areas` or `protector` mods to ensure valid placement permissions.

## Phase 4: Construct Defenders & Guard Expansion
- [x] **Humanoid Guard Shift Expansion:** Day/Night alternating shifts and alarm wakeups implemented in `eg_settlers`.
- [x] **Construct Companions (`eg_constructs`):** Mobile expedition companions (Clay Golem & Combat Drone) spun off into dedicated standalone mod `eg_constructs` with 16-slot pack inventories, player following, and raider crowd control.

## Phase 5: NPC Daily Schedules & Pathfinding ([npc_schedules_design.md](npc_schedules_design.md))
- [x] **Pathfinding Engine Wrapper (`navigate_to`)**
  - [x] Implement `eg_settlers.navigate_to(self, target_pos)` wrapping `core.find_path(..., "A*_noprefetch")`.
  - [x] Implement pre-pathing and waypoint door/gate detection and auto-open/close logic via `doors.get(pos)`.
  - [x] Add 10-second stuck timer with safe teleport fallback (`eg_settlers.safe_teleport`).
  - [x] Add valid floor destination validation (`eg_settlers.is_valid_floor` & `get_walkable_goal`) and anti-stacking.
  - [x] Add liquid hazard avoidance and safe local wander fallback when paths are blocked.
- [x] **Daily Schedule State Machine**
  - [x] Work shift active state at assigned Workstation / Job Block (06:00–17:30).
  - [x] Evening town square gathering around Job Board civic hub (17:30–19:00).
  - [x] Nighttime sleep state (19:00–06:00) at assigned Bed node (with alternating Day/Night Guard shifts).
- [x] **Bed Sleeping Posture & Physics Freeze**
  - [x] Adjust sleeping entity position offset to mattress elevation `bed_pos.y + 0.12` and longitudinal alignment along bed `facedir`.
  - [x] Set 90° pitch rotation (`{x = math.pi/2, y = yaw, z = 0}`), disable physical collisions, and freeze mob AI loops during sleep.
  - [x] Apply slowed-down 6 FPS idle animation for calm breathing effect.

## Phase 6: Settler Death Management & Remains ([settler_death_mechanic.md](settler_death_mechanic.md))
- [ ] **Incident Logging & Graveyard UI**
  - [ ] Persistent 25-entry rolling log in `settlement_db.lua` recording killer (Player, Mob, Environment), timestamp, and location.
  - [ ] Town Ledger Graveyard tab interface to inspect casualties and remains coordinates.
- [ ] **Unburied Remains & Burial Nodes**
  - [ ] Drop temporary `eg_settlers:remains` node on settler death with 5-minute timer before Shade spawn.
  - [ ] Simple earth burial (right-clicking dirt with remains to consume without metadata).
  - [ ] Register `eg_settlers:headstone` individual tombstone node.
  - [ ] Register `eg_settlers:crypt` multi-block vault structure (up to 20 remains).
  - [ ] Campfire/Pyre cremation support (`new_campfire` integration).


