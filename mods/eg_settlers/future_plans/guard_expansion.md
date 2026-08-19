# Guard Shifts & Town Defense

This document specifies the design for settler guard shift rotations, deferred wake mechanics, and non-sleeping defenders (Golems and Automata/Robots).

---

## 1. Context

Settler guards currently operate 24/7, which is unrealistic. However, having all guards sleep at night leaves settlements unprotected during peak mob activity.

The proposed plan splits town defense into:
1. **Humanoid Settler Guards (Planned Shift System):** Automatic alternating day/night shifts using standard beds.
2. **Construct Defenders (Proposed Future NPCs):** Golems and Automata/Robots that do not sleep, eat, or require beds.

---

## 2. Planned Guard Shift System

### Assignment
- Guard contracts are spawner items without a formspec UI. Shift assignment will be automated upon placement.
- When placing a guard contract on `eg_settlers:job_block_guard`, the shift will alternate based on the settlement's guard count:
  - **Odd count:** Day Shift
  - **Even count:** Night Shift
- Guards will require standard beds (`group:bed` or housing deeds) and use the existing bed assignment routines.

### Proposed Schedule

| Shift | Duty Window | Sleep Window | Behavior |
| :--- | :--- | :--- | :--- |
| **Day Guard** | `4500` to `18500` | `18500` to `4500` | Stands at assigned bed during sleep window |
| **Night Guard** | `16500` to `6500` | `6500` to `16500` | Stands at assigned bed during sleep window |

Both shifts overlap between `16500`–`18500` (dusk) and `4500`–`6500` (dawn).

### Planned Persistence
- Add `self.guard_shift = "day"` or `"night"` to the guard entity table, saved via staticdata.

---

## 3. Proposed Construct Defenders (Golems & Automata)

Proposed non-biological entities to provide continuous 24/7 defense without beds, food, or employment slots in the town census. Instead of using civilian Guard Armory Stands (`job_block_guard`), constructs bind to dedicated **Anchor Nodes**.

### 3.1 Clay Golem (`eg_settlers:golem_clay`)
- **Role:** Heavy blunt defender. High HP, slow movement, knockback attacks.
- **Attributes:** HP 120, Speed 1.5, Damage 6.
- **Requirements:** No bed (`self.home_pos = nil`), no food satiation checks.
- **Model Options:**
  - `mobs_dungeon_master.b3d` (Reuses the broad, hulking Land Guard silhouette).
  - `mobs_stone_monster.b3d` (Alternative rocky/earthen golem mesh).
- **Texture Design:**
  - Traditional molded clay texture (`eg_settlers_golem_clay.png`): unadorned terracotta/clay surface with simple carved facial features and earthen shading.
- **Anchor Node:** **Golem Pedestal** (`eg_settlers:golem_pedestal`) — A carved clay/terracotta base defining the golem's home coordinate.
- **Tether:** 30-node patrol radius centered on its Golem Pedestal.
- **Activation:** Crafted Golem Core item used on a placed Golem Pedestal to spawn the entity.

### 3.2 Automaton / Robot (`eg_settlers:automaton`)
- **Role:** Sentry defense. Compatible with `techage` integration.
- **Attributes:** HP 80, Speed 2.5, Damage 5.
- **Requirements:** No bed, no food satiation checks.
- **Anchor Node:** **Automaton Station** (`eg_settlers:automaton_station`) — A steel/copper mounting pad defining the sentry's home coordinate.
- **Tether:** 35-node patrol radius centered on its Automaton Station.
- **Activation:** Crafted Automaton Core item inserted into a placed Automaton Station.
- **Textures:** Texture options are located in [`../../../research/automata/`](file:///Users/Aresh/Desktop/Projects/evergrowth/research/automata) (`character_735.png`, `character_2293.png`).

### 3.3 Relocation & Removal
- **Anchor Node Mining:** Digging a Golem Pedestal or Automaton Station removes the bound entity and drops both the anchor node and its activation core.
- **Direct Relocation:** Shift + Right-Clicking an active construct returns its core item to the player's inventory and despawns the entity, freeing the anchor node.

### 3.4 Crafting & Materials
- **Golem Pedestal (`eg_settlers:golem_pedestal`):** `default:clay` (x4), `default:stone` (x4).
- **Golem Core (`eg_settlers:golem_core`):** `default:clay` (x4), `default:gold_lump` (x2), `dye:red` (x1).
- **Automaton Station (`eg_settlers:automaton_station`):** `default:steel_ingot` (x4), `default:copper_ingot` (x2), `techage` steel plate / component (if available).
- **Automaton Core (`eg_settlers:automaton_core`):** `default:steel_ingot` (x4), `default:copper_ingot` (x2), `default:mese_crystal_fragment` (x2).

### 3.5 Settlement DB & Town Ledger Integration
- **Census Exemption:** Constructs do not occupy villager population slots, housing deeds, or bed assignments.
- **Defense Score:** Each active construct registers under the settlement's defense rating in `api/settlement_db.lua`, adding to the town's security power displayed on the Town Ledger.

### 3.6 Targeting & Aggro Rules
- **Hostile Mobs:** Engages all `type = "monster"` entities within view range.
- **Criminals:** Engages players with active assault/murder records in the local settlement database.
- **Friendlies:** Ignores non-criminal players, passive mobs, and civilian settlers. Cannot be damaged by friendly non-criminal players.

---

## 4. Deferred: Alarm & Emergency Wake-up

**Status:** Deferred until pathfinding improvements are implemented.

### Concept
Off-duty guards wake up and engage hostiles if an alarm triggers or hostiles enter a settlement.

### Dependency
Current pathfinding cannot navigate closed doors or multi-story structures reliably. Implementing wake behavior before door-capable navigation causes entities to get stuck in walls or require teleportation.
