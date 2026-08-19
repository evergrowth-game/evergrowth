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
- **Anchor Node:** **Golem Pedestal** (`eg_settlers:golem_pedestal`) — A carved rune/terracotta base defining the golem's home coordinate.
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

---

## 4. Deferred: Alarm & Emergency Wake-up

**Status:** Deferred until pathfinding improvements are implemented.

### Concept
Off-duty guards wake up and engage hostiles if an alarm triggers or hostiles enter a settlement.

### Dependency
Current pathfinding cannot navigate closed doors or multi-story structures reliably. Implementing wake behavior before door-capable navigation causes entities to get stuck in walls or require teleportation.
