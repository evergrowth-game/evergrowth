# Settler Infrastructure & Workstation Design

This document outlines proposals and technical designs to address settler density, housing realism, and infrastructure requirements in `eg_settlers`.

---

## 1. Problem Statement

Under the current implementation:
* **Zero Spatial Footprint**: A Housing Deed (`eg_settlers:housing_deed`) is a wallmounted sign node costing 1 paper and 1 black dye. Up to 20 deeds can be attached to walls inside a single $3\times3$ dirt hut.
* **Zero Workplace Validation**: Contracts check only `under_node.name == "eg_settlers:housing_deed"`. They do not verify whether suitable fields, furnaces, water bodies, or beds exist.
* **Trivial Acquisition**: Players can craft spawner contracts on a crafting grid for minimal resources, leading to trivialized town growth.

---

## 2. Core Proposals

### A. Profession Workstations (Job Blocks)
Replace generic Housing Deeds with profession-specific **Workstation Nodes** (Job Blocks) for all 18 villager professions. Job blocks function identically to Housing Deeds as tethering nodes, requiring a spawner contract to be applied directly to a workstation node to assign and tether a villager.

*(Note: `eg_settlers:housing_deed` is retained exclusively for Companion NPCs).*

Each profession will have a dedicated custom job block registered within `eg_settlers`. Instead of redundantly duplicating functional workbenches (like anvils or furnaces), these nodes will be administrative or planning stations conceptually similar to the `town_ledger`:

* **Farmer**: `eg_settlers:job_block_farmer` (Seed Silo)
  * **Design**: A narrow, tall cylindrical hopper nodebox (~0.6×1×0.6).
  * **Textures**: Reuses `default_wood.png` with a custom grain top texture.
* **Blacksmith**: `eg_settlers:job_block_smith` (Quenching Trough)
  * **Design**: A half-height rectangular basin (~1×0.5×1) representing the water trough used to cool hot metal.
  * **Textures**: `default_stone_brick.png` for the basin walls, `default_water.png` for the top face.
* **Carpenter**: `eg_settlers:job_block_carpenter` (Drafting Table)
  * **Design**: A slanted drafting surface on a trestle (~1×0.8×1), angled top sub-box.
  * **Textures**: Reuses `default_wood.png` and `default_steel_block.png`.
* **Librarian**: `eg_settlers:job_block_librarian` (Town Archive)
  * **Design**: A tall, vertical filing cabinet nodebox (~0.7×1×0.5).
  * **Textures**: Reuses `default_wood.png` with paper filing drawer decals.
* **Mage**: `eg_settlers:job_block_mage` (Ward Pedestal)
  * **Design**: A narrow stone column nodebox (~0.4×1×0.4) with a wider top slab sub-box for the focal stone.
  * **Textures**: `default_obsidian.png` for the column, custom glowing rune texture for the top face.
* **Brewer**: `eg_settlers:job_block_brewer` (Fermentation Cask)
  * **Design**: A horizontal barrel nodebox (~1×0.8×0.8) resting on two small wooden rail sub-boxes.
  * **Textures**: Reuses `default_wood.png` with custom metal banding on the end faces.
* **Miner**: `eg_settlers:job_block_miner` (Ore Cart)
  * **Design**: A U-shaped minecart nodebox (~1×0.6×0.6) — a flat base with raised walls on three sides and an open front.
  * **Textures**: `default_steel_block.png` for the cart body, `default_cobble.png` visible as ore fill on the top face.
* **Merchant**: `eg_settlers:job_block_merchant` (Merchant's Counter)
  * **Design**: A wide, half-height counter slab (~1×0.5×1) — a simple flat-topped service block.
  * **Textures**: `default_wood.png` with a custom coin/ledger decal on the top face.
* **Guard**: `eg_settlers:job_block_guard` (Watchtower Beacon)
  * **Design**: A narrow post (~0.3×1×0.3) topped with a wider lantern sub-box (~0.5×0.3×0.5).
  * **Textures**: `default_wood.png` for the post, custom lantern/flame texture for the top box. Emits light (light_source = 10).
* **Rancher**: `eg_settlers:job_block_rancher` (Feed Trough)
  * **Design**: A low, wide rectangular trough nodebox (~1×0.4×0.6).
  * **Textures**: Reuses `default_wood.png` filled with a wheat/hay texture on the top face.
* **Fisher**: `eg_settlers:job_block_fisher` (Fish Barrel)
  * **Design**: An upright open-top barrel nodebox (~0.6×0.8×0.6) — distinguished from the Brewer's horizontal cask by orientation and height.
  * **Textures**: `default_wood.png` with custom fish texture visible on the top face.
* **Lumberjack**: `eg_settlers:job_block_lumberjack` (Chopping Stump)
  * **Design**: A truncated log nodebox (~0.8×0.6×0.8) — a short, wide cylinder shape.
  * **Textures**: Reuses `default_tree_top.png` (with axe mark decal) and `default_tree.png` for the bark.
* **Technologist**: `eg_settlers:job_block_technologist` (Server Rack)
  * **Design**: A tall, narrow metallic casing (~0.6×1×0.4).
  * **Textures**: `default_steel_block.png` for the casing, with blinking indicator light decals on the front face.
* **Gunsmith**: `eg_settlers:job_block_gunsmith` (Ordnance Locker)
  * **Design**: A full-cube reinforced strongbox (~1×1×1).
  * **Textures**: `default_steel_block.png` with heavy bolt/hinge decals and a dark green military tint.
* **Automobile Mechanic**: `eg_settlers:job_block_automobile_mechanic` (Rolling Tool Chest)
  * **Design**: A heavy metal cabinet nodebox (~0.8×0.9×0.6) with 4 small wheel caster sub-boxes at the base and a flat top tray holding modeled tool handles.
  * **Textures**: Painted cherry red metal texture (`eg_settlers_toolchest_auto.png`) with black drawer handle lines and metallic caster wheels.
* **Aircraft Mechanic**: `eg_settlers:job_block_aircraft_mechanic` (Fuel Canister Rack)
  * **Design**: A wide, low shelf nodebox (~1×0.6×0.6) with two small canister sub-boxes stacked on top.
  * **Textures**: `default_steel_block.png` for the shelf, aviation grey canisters with yellow warning labels.
* **Nautical Mechanic**: `eg_settlers:job_block_nautical_mechanic` (Anchor Chain Post)
  * **Design**: A short, thick cylindrical post (~0.5×0.7×0.5) with a wider base slab.
  * **Textures**: `default_steel_block.png` with rust patina and rope/chain texture wrapping the sides.
* **Roboticist**: `eg_settlers:job_block_roboticist` (Charging Alcove)
  * **Design**: A metallic docking station (~0.8×1×0.8) — a recessed frame nodebox with an open front face.
  * **Textures**: Reuses `default_copper_block.png` and `default_steel_block.png`.

**Impact**: These new nodes occupy physical 3D space in the world and use distinct nodebox meshes and textures. This forces players to construct actual working spaces (smithies, libraries, workshops) around these core nodes, rather than pasting generic paper deeds onto any wall.

---

### B. Environmental Validation Checks
When placing a contract or during daily `town_ledger` processing, require the Job Block to validate its surrounding environment within a radius $R$:

| Profession | Required Surrounding Infrastructure | Radius ($R$) |
| :--- | :--- | :--- |
| **Farmer** | $\ge 8$ wet soil (`farming:soil_wet`) or crop nodes | 5 blocks |
| **Blacksmith** | $\ge 1$ furnace (`default:furnace` / `default:furnace_active`) or anvil | 3 blocks |
| **Carpenter** | $\ge 4$ wooden plank or tree nodes (`group:wood` / `group:tree`) | 4 blocks |
| **Librarian** | $\ge 4$ bookshelf nodes (`default:bookshelf`) | 4 blocks |
| **Mage** | $\ge 2$ bookshelf or magical nodes (`default:bookshelf` / `xdecor:enchantment_table`) | 5 blocks |
| **Brewer** | $\ge 2$ barrel nodes (`wine:wine_barrel`) | 4 blocks |
| **Miner** | $\ge 4$ stone or ore nodes (`group:stone`) | 5 blocks |
| **Merchant** | $\ge 2$ chest nodes (`group:chest`) | 4 blocks |
| **Guard** | $\ge 1$ armor stand or weapon rack node (`3d_armor:armor_stand`) | 5 blocks |
| **Rancher** | $\ge 4$ fence nodes (`group:fence`) or straw nodes (`farming:straw`) | 5 blocks |
| **Fisher** | $\ge 8$ water nodes (`group:water`) and/or $\ge 1$ barrel node (`xdecor:barrel`) | 5 blocks |
| **Lumberjack** | $\ge 4$ tree trunk nodes (`group:tree`) | 8 blocks |
| **Technologist** | $\ge 2$ power/cable or Techage nodes (`group:techage` / `techage:electric_cableS`) | 5 blocks |
| **Gunsmith** | $\ge 1$ steel block (`default:steelblock`) or furnace (`default:furnace`) | 4 blocks |
| **Automobile Mechanic** | $\ge 1$ steel block (`default:steelblock`) or chest (`group:chest`) | 6 blocks |
| **Aircraft Mechanic** | $\ge 1$ wind indicator (`airutils:wind`), biofuel distiller (`biofuel:biofuel_distiller`), PAPI light (`airutils:papi`), or steel block (`default:steelblock`) | 6 blocks |
| **Nautical Mechanic** | $\ge 4$ water nodes (`group:water` / `default:water_source` / `default:river_water_source`) | 6 blocks |
| **Roboticist** | $\ge 2$ copper blocks (`default:copperblock`), gold blocks (`default:goldblock`), or Techage nodes (`group:techage` / `techage:ta4_icta_controller`) | 5 blocks |

If validation fails, the NPC refuses to trade/work or the contract placement fails.

---

### C. Workplace Capacity System
Settlement worker capacity is determined directly by physical Job Block placement:
* **Workplace Capacity**: Every villager resident requires 1 registered Job Block node.
* **Settlement Population Cap Formula**:
  $$\text{Population Cap} = \text{Registered Job Blocks}$$

Max capacity limits are further governed by Town Progression Tiers (Section D).

---

### D. Town Population Tiers on Town Ledger
Introduce population caps tied to Town Ledger tiers or town infrastructure progression in `settlement_db.lua`:

* **Tier 1 (Outpost)**: Max 3 residents. Requires `eg_settlers:town_ledger`.
* **Tier 2 (Hamlet)**: Max 8 residents. Requires `eg_settlers:town_granary`.
* **Tier 3 (Village)**: Max 20 residents. Requires `eg_settlers:town_depot` + `eg_settlers:ward_stone` + `eg_settlers:job_board`.

---

### E. Job Board Recruitment Shift
Shift contract acquisition primarily to the `job_board.lua` recruitment tab (costing `default:gold_lump`), or adjust contract recipes to require mid-tier town materials (e.g., Ink & Quill, Wax Seal, Gold Ingot) instead of basic craft items.

---

### F. Unified Hiring Contract
Replace the 18 per-profession contract items (`eg_settlers:contract_guard`, `eg_settlers:contract_farmer`, etc.) with a single generic **Hiring Contract** item: `eg_settlers:hiring_contract`.

#### Behavior
* The Hiring Contract can **only** be placed on a Job Block node (`eg_settlers:job_block_<profession>`). Free-standing (untethered) spawning is removed entirely.
* When placed on a job block, the contract reads the target node's registered name to derive the profession (e.g., `eg_settlers:job_block_smith` → `"smith"`).
* The spawned NPC is tethered to the job block the same way current contracts tether to Housing Deeds, with the job block storing `occupied`, `resident_name`, `profession`, and `settlement_id` metadata.

#### Recipe
A single mid-tier recipe replaces all 18 trivial `paper + <item>` recipes:
```
default:paper + default:gold_ingot → eg_settlers:hiring_contract
```

#### Job Board Integration
The Job Board's Contracts tab (`job_board.lua`, tab 2) currently dispenses per-profession contract items (`eg_settlers:contract_<id>`). Under the unified model, the Job Board dispenses `eg_settlers:hiring_contract` regardless of the selected seeker — the profession is determined at placement time by the target job block, not at acquisition time.

#### Items NOT Modified
* **Companion Contracts** (`contract_companion_male`, `contract_companion_female`, `contract_companion_relocation`) — these are a separate mechanic and remain unchanged.
* **Villager Relocation Contract** (`contract_villager_relocation`) — remains unchanged; its `on_place` target check will be updated from `housing_deed` to job block nodes.

#### Migration & Backward Compatibility
* Register aliases mapping all 18 old `eg_settlers:contract_<profession>` item names to `eg_settlers:hiring_contract` so existing items in player inventories convert automatically.
* Update legacy aliases in `api/aliases.lua` for the `evergrowth_villages:contract_*` → `eg_settlers:hiring_contract` path.
* The `housing_deed` node remains registered (existing worlds may have them placed), but new contracts no longer target it. Its `on_rightclick` handler will inform players that deeds are deprecated and direct them to use Job Blocks.

---

## 3. Phased Implementation Roadmap

### Phase 1 — Job Block Nodes & Unified Contract
**Goal**: Replace per-profession contracts with a single Hiring Contract and introduce Job Block workstation nodes as the sole contract target.

#### 1.1 Job Block Registration Helper
* Create `town/job_blocks.lua` with a `register_job_block(name, def)` helper function that handles common boilerplate (nodebox, groups, metadata init, `on_construct`, `can_dig`, `on_blast`, `allow_metadata_inventory_*` callbacks).
* Register all profession-specific job blocks as listed in Section 2.A using this helper.
* Each job block stores metadata: `occupied` (int), `resident_name` (string), `profession` (string), `settlement_id` (string).

#### 1.2 Unified Hiring Contract
* In `town/contracts.lua`:
  * Remove the `register_contract()` helper and all 18 `register_contract(...)` calls.
  * Register a single `eg_settlers:hiring_contract` craftitem.
  * `on_place` handler: validate the target node matches `^eg_settlers:job_block_(.+)$`, extract the profession capture group, check `occupied` metadata, call `eg_settlers.spawn_trader()`, and update the job block's metadata.
  * Remove the free-standing (untethered) spawn path entirely.
  * Register a single craft recipe: `default:paper` + `default:gold_ingot` → `eg_settlers:hiring_contract`.
* Companion contracts and wardrobe wand registrations remain unchanged in this file.

#### 1.3 Villager Relocation Contract Update
* Update `contract_villager_relocation`'s `on_place` to accept job block nodes as targets (in addition to or instead of `housing_deed`).

#### 1.4 Job Board Adaptation
* In `job_board.lua`:
  * Change the Contracts tab to dispense `eg_settlers:hiring_contract` instead of per-profession contract items.
  * Simplify the `seeker_professions` table — it can retain profession names and costs for display, but the dispensed item is always `hiring_contract`.
  * Update the formspec to show a generic contract icon instead of per-profession icons.

#### 1.5 Aliases & Migration
* In `api/aliases.lua`: add aliases from all 18 old `eg_settlers:contract_<profession>` names → `eg_settlers:hiring_contract`.
* Update `evergrowth_villages:contract_*` aliases similarly.

#### 1.6 Housing Deed Deprecation
* `housing_deed` node remains registered for backward compatibility but its `on_rightclick` handler is updated to inform players it is deprecated.
* The `on_rightclick` contract-matching logic in `api/settlement.lua` (line 109) is updated to reflect the new `hiring_contract` item name if needed.

#### 1.7 NPC Behavior Updates
* In `npc/npc_behavior.lua`: update references that check for `housing_deed` as the tether target node. NPCs should now pathfind to and validate against their assigned job block position.
* The relocation sneak+right-click handler (line 268) continues to produce `contract_villager_relocation` — no change needed.

#### 1.8 Guide Content Update
* Update `docs/guide_content.lua` to reflect the new workflow: Job Blocks → Hiring Contract → NPC spawns.

---

### Phase 2 — Environmental Validation Checks
**Goal**: Require job blocks to validate surrounding infrastructure before accepting a contract.

#### 2.1 Validation Utility
* Add `eg_settlers.validate_job_block_environment(pos, profession)` in `api/settlement.lua`.
* Implements the radius scan and node-count checks from the table in Section 2.B.
* Returns `true/false` and a failure reason string.

#### 2.2 Contract Placement Gate
* Call the validation utility inside the Hiring Contract's `on_place` handler. If validation fails, send a chat message explaining what infrastructure is missing and abort placement.

#### 2.3 Periodic Re-validation (Optional)
* During the daily `town_ledger` processing cycle, optionally re-check job block environments. If a job block's environment degrades below the threshold, mark the resident as "idle" or "unsatisfied" in the settlement database.

---

### Phase 3 — Population Cap & Town Progression Tiers
**Goal**: Enforce job-block-based population caps and infrastructure-gated town tiers.

#### 3.1 Population Cap Enforcement
* In `town/town_ledger.lua`, enforce `Population Cap = Registered Job Blocks` (capped by town tier).
* The Hiring Contract's `on_place` checks the cap before allowing a new resident.

#### 3.2 Town Population Tiers
* Implement the tier system from Section 2.D in `settlement_db.lua`.
* Town Ledger formspec displays current tier and requirements for the next tier.
* Enforce tier-specific population caps (Outpost: 3, Hamlet: 8, Village: 20).

---

### Phase 4 — Polish & Integration
**Goal**: Final cleanup, testing, and UI refinements.

#### 4.1 Town Ledger Resident Display
* Update the Town Ledger's resident list to show job block position and profession sourced from the job block metadata rather than from old deed metadata.

#### 4.2 Housing Deed Removal Path
* Provide a migration tool or LBM that converts existing occupied Housing Deeds into the nearest unoccupied Job Block of the matching profession (if one exists within settlement radius), preserving the resident's tether.

#### 4.3 Crafting Guide Cleanup
* Verify that the 18 old contract items no longer appear in any crafting guide mod (unified_inventory, craftguide, etc.) — aliases should handle this, but test explicitly.

#### 4.4 Testing
* Verify contract placement on each job block type spawns the correct profession.
* Verify environmental validation rejects placement when infrastructure is missing.
* Verify population cap enforcement.
* Verify old contract items in player inventories alias correctly to `hiring_contract`.
* Verify companion and relocation contracts are unaffected.
