# Evergrowth Villages: NPC Daily Schedules, Job Blocks & Pathfinding

This document outlines the technical implementation for **Workplace Deeds** (job blocks), a **daily schedule state machine**, **social congregation**, and the lightweight **`navigate_to` pathfinding wrapper** that powers NPC movement between locations.

---

## 1. Pathfinding: The `navigate_to` Wrapper

All scheduled movement (work, social, home) is powered by a single reusable function that wraps the engine's C++ A* pathfinder (`core.find_path`). This replaces the current teleport-to-home and dumb-walk-to-tether behaviors with real obstacle-aware navigation, plus a teleport fallback for edge cases.

### Why Not Use `go_to()` / `smart_mobs()`?

The existing mobs_redo pathfinding (`smart_mobs` in `api.lua:1440`) only fires during combat (`state == "attack"`). The `go_to(pos)` helper abuses this by spawning a phantom entity and "attacking" it — but this causes NPCs to run at combat speed, risks target-switching if a real enemy appears, and creates ephemeral entities. We need a clean, schedule-driven alternative.

### Architecture

A new function, `eg_settlers.navigate_to(self, target_pos)`, is called **once** when an NPC transitions between schedule phases (e.g., wander → work). It is NOT called every tick.

```
navigate_to(self, target_pos)
│
├── 1. Is NPC already within 2 blocks of target?
│   └── YES → Skip. Set state to arrived.
│
├── 2. Does NPC have line_of_sight to target? (core.line_of_sight)
│   └── YES → Dumb-walk (yaw_to_pos + set_velocity). No A* needed.
│
├── 3. Call core.find_path(npc_pos, target_pos, ...)
│   ├── Path found → Store in self._nav_waypoints. Begin waypoint walk.
│   └── Path NOT found → Teleport to target (fallback).
│
└── 4. Waypoint following runs in on_step:
    ├── Each tick: check distance to current waypoint
    ├── Within 0.6 blocks → pop waypoint, yaw to next
    ├── All waypoints consumed → arrived
    └── Stuck timer > 10s with no progress → teleport (fallback)
```

### Parameters for `core.find_path`

| Parameter | Value | Rationale |
|---|---|---|
| `searchdistance` | 25 | Covers tether radius (14 for civilians, 45 for guards). Keep small to limit CPU. |
| `max_jump` | 1 | Villages are mostly flat. NPCs shouldn't parkour. |
| `max_drop` | 3 | Allow walking down short stairways / slopes. |
| `algorithm` | `"A*_noprefetch"` | Default engine algorithm. Fastest for short paths. |

### Performance Budget

Pathfinding calls happen **only on schedule transitions**, not every tick:

*   **Per NPC per game-day:** ~4-6 `find_path` calls (home→work, work→wander, wander→work, work→social, social→home).
*   **15 NPCs:** ~60-90 calls per game-day, spread across real-time hours.
*   **Cost per call:** Negligible at `searchdistance=25` in open village terrain. Engine A* runs in C++.

The expensive scenario — maze-like geometry with no valid path — is handled by the teleport fallback, which kills the search instantly.

### Enabling Pathfinding on Traders

Currently `mobs_npc:trader` has `pathfinding = false` ([trader.lua:70](../../../mobs_npc/trader.lua)). This must be set to `true` (or `1`) at spawn time inside `spawn_trader()`:

```lua
ent.pathfinding = 1
```

This enables the `self.path` data structure that mobs_redo initializes on activation (`api.lua:2890`). Our wrapper doesn't use `smart_mobs` directly, but we need `self.path` to exist for compatibility.

### Implementation: New Fields on NPC Entity

| Field | Type | Persisted? | Purpose |
|---|---|---|---|
| `self._nav_waypoints` | `table` or `nil` | No (runtime only) | Current A* waypoint list being followed |
| `self._nav_target` | `vector` or `nil` | No | Final destination of current navigation |
| `self._nav_stuck_timer` | `number` | No | Seconds since last meaningful movement |
| `self._nav_last_pos` | `vector` or `nil` | No | Position at last stuck-check |
| `self._nav_state` | `string` or `nil` | No | `"walking"`, `"arrived"`, or `nil` |

### Implementation: Waypoint Following (in `on_step`)

The following logic runs inside the existing `_behavior_timer > 1.0` check in `npc_behavior.lua`, gated on `self._nav_waypoints ~= nil`:

```lua
-- Waypoint following (runs every behavior tick, ~1s)
if self._nav_waypoints and #self._nav_waypoints > 0 then
    local wp = self._nav_waypoints[1]
    local dist_to_wp = vector.distance(pos, wp)

    if dist_to_wp < 1.5 then
        -- Reached waypoint, advance to next
        table.remove(self._nav_waypoints, 1)

        if #self._nav_waypoints == 0 then
            -- Arrived at destination
            self._nav_waypoints = nil
            self._nav_state = "arrived"
            self.order = "stand"
            self:set_velocity(0)
            self:set_animation("stand")
        else
            -- Face next waypoint
            self:yaw_to_pos(self._nav_waypoints[1])
            self:set_velocity(self.walk_velocity)
            self:set_animation("walk")
        end
    else
        -- Still walking toward current waypoint
        self:yaw_to_pos(wp)
        self:set_velocity(self.walk_velocity)
        self:set_animation("walk")
    end

    -- Stuck detection
    self._nav_stuck_timer = (self._nav_stuck_timer or 0) + 1.0
    local last = self._nav_last_pos or pos
    if vector.distance(pos, last) < 0.3 then
        if self._nav_stuck_timer > 10 then
            -- Stuck too long, teleport to final destination
            self.object:set_pos(self._nav_target)
            self._nav_waypoints = nil
            self._nav_state = "arrived"
            self._nav_stuck_timer = 0
            self.order = "stand"
            self:set_velocity(0)
            self:set_animation("stand")
        end
    else
        self._nav_stuck_timer = 0
    end
    self._nav_last_pos = {x = pos.x, y = pos.y, z = pos.z}

    -- Suppress normal wander/tether while navigating
    return
end
```

### Fallback Hierarchy

1. **Line-of-sight clear** → dumb walk (cheapest)
2. **A\* path found** → waypoint walk (normal case)
3. **A\* returns nil** → immediate teleport
4. **A\* path found but NPC stuck >10s** → teleport to destination

---

## 2. Workplace Deeds (Job Blocks)

### Concept

A **Workplace Deed** is a placeable node that designates a block as the work location for a specific profession. It is structurally analogous to the Housing Deed — a wall-mounted sign the player places inside a workshop, forge, tavern, etc.

When a villager NPC is assigned a workplace (via a contract-on-deed interaction, or an auto-assignment system), their `work_pos` field is set to the Workplace Deed's coordinates. The NPC then navigates there during work hours.

### Node Registration

```lua
minetest.register_node("eg_settlers:workplace_deed", {
    description = S("Workplace Deed"),
    drawtype = "nodebox",
    tiles = {"default_sign_wall_steel.png^[multiply:#4A90D9"},  -- Blue tint
    inventory_image = "default_sign_steel.png^[multiply:#4A90D9",
    -- ... (same nodebox as housing_deed) ...
    groups = {choppy = 2, dig_immediate = 2, attached_node = 1},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("occupied", 0)
        meta:set_string("profession", "")
        meta:set_string("worker_name", "")
        meta:set_string("infotext", S("Workplace Deed (Vacant)"))
    end,

    -- Same can_dig / on_rightclick pattern as housing_deed
})
```

### Alternative: Profession-Mapped Existing Blocks

Instead of (or in addition to) a dedicated Workplace Deed node, NPCs could be assigned to path toward existing profession-relevant nodes:

| Profession | Target Node(s) | Group |
|---|---|---|
| Smith | `default:furnace`, `anvil:anvil` | `group:evergrowth_workplace_smith` |
| Brewer | `wine:wine_barrel` | `group:evergrowth_workplace_brewer` |
| Farmer | `farming:soil_wet` (any) | `group:evergrowth_workplace_farmer` |
| Librarian | `default:bookshelf` | `group:evergrowth_workplace_librarian` |
| Mage | `x_enchanting:table` | `group:evergrowth_workplace_mage` |
| Miner | `default:stone_with_coal` (nearest) | N/A (uses find_node_near) |

This approach uses `minetest.find_node_near(home_pos, radius, target_nodes)` to auto-discover work targets without the player needing to place a deed. It is more immersive but less controllable.

**Recommended approach:** Use explicit **Workplace Deeds** as the primary system (player places them intentionally), with the auto-discovery as a future enhancement.

### NPC Entity Fields

| Field | Type | Persisted? | Purpose |
|---|---|---|---|
| `self.work_pos` | `vector` or `nil` | Yes (staticdata) | Assigned workplace coordinates |
| `self.social_pos` | `vector` or `nil` | Yes (staticdata) | Cached tavern/gathering coordinates |

These must be added to the entity's `get_staticdata` and `on_activate` serialization, alongside the existing `home_pos`.

### Assignment Flow

Uses the same contract-on-deed pattern as Housing Deeds:

1. Player crafts a Workplace Deed (recipe: `default:paper` + `dye:blue`).
2. Player places it inside a building (e.g., the forge).
3. Player right-clicks the deed while holding a Blacksmith's Contract (or the NPC's Relocation Contract).
4. The deed's metadata stores the assigned profession and worker name.
5. The NPC's `work_pos` is set to the deed's coordinates.

**Alternatively**, for simpler initial implementation: the NPC auto-discovers the nearest Workplace Deed matching their profession within the tether radius, using `minetest.find_nodes_in_area()` on a slow timer (~60s).

---

## 3. Daily Schedule State Machine

### Overview

The current binary day/night check in `npc_behavior.lua` (lines 74-140) is replaced with a multi-phase schedule driven by `minetest.get_timeofday() * 24000`.

### Schedule Definition

```lua
local SCHEDULES = {
    default = {
        {start = 0,     stop = 4500,  phase = "sleep",   target = "home_pos"},
        {start = 4500,  stop = 5500,  phase = "commute", target = "work_pos"},
        {start = 5500,  stop = 11000, phase = "work",    target = "work_pos"},
        {start = 11000, stop = 12500, phase = "wander",  target = nil},
        {start = 12500, stop = 17000, phase = "work",    target = "work_pos"},
        {start = 17000, stop = 18500, phase = "social",  target = "social_pos"},
        {start = 18500, stop = 24000, phase = "sleep",   target = "home_pos"},
    },
    guard = {
        {start = 0,     stop = 6000,  phase = "sleep",   target = "home_pos"},
        {start = 6000,  stop = 18000, phase = "patrol",  target = nil},
        {start = 18000, stop = 24000, phase = "patrol",  target = nil},
    },
}
```

### Phase Behaviors

| Phase | Movement | NPC State | Animation | Duration |
|---|---|---|---|---|
| `sleep` | Navigate to `home_pos`, stand still | `order = "stand"` | `"stand"` | Night hours |
| `commute` | Navigate to `work_pos` | `order = "walk"` | `"walk"` | ~1000 ticks (~1 min real) |
| `work` | Stand at `work_pos` | `order = "stand"` | `"stand"` | Morning + afternoon |
| `wander` | Free roam within tether | `order = "wander"` | varies | Lunch break |
| `social` | Navigate to `social_pos` | `order = "stand"` | `"stand"` | Evening |
| `patrol` | Wander with extended tether | `order = "wander"` | varies | Guards only |

### Phase Transition Logic

A new field `self._current_phase` tracks which schedule phase the NPC is in. On each behavior tick (~1s), the scheduler checks if the current game time has moved past the current phase's `stop` boundary. If so:

1. Look up the new phase from the schedule table.
2. If the new phase has a `target` field:
   a. Resolve the target position (e.g., `self[entry.target]`).
   b. Call `eg_settlers.navigate_to(self, target_pos)`.
3. If the new phase is `"wander"`, set `self.order = "wander"` and clear navigation.
4. Update `self._current_phase`.

**Key principle:** `navigate_to` is called exactly **once** per phase transition, not every tick. The waypoint-following in `on_step` handles the actual movement.

### Graceful Degradation

If an NPC has no `work_pos` assigned, work phases fall back to `"wander"`. If no `social_pos` is found, social phases fall back to `"wander"`. The NPC always has `home_pos` (set at Housing Deed assignment), so sleep is always valid.

```lua
local target_field = schedule_entry.target
local target_pos = target_field and self[target_field] or nil

if not target_pos then
    -- No destination assigned for this phase, just wander
    self.order = "wander"
else
    eg_settlers.navigate_to(self, target_pos)
end
```

---

## 4. Social Congregation (Tavern System)

### Concept

During the `social` phase (evening), a percentage of village NPCs navigate to a shared gathering point — typically the tavern (brewer's workplace) or a town square node.

### Social Node Discovery

Each NPC discovers their `social_pos` using a periodic scan (not every tick — once per game day, or on phase transition):

```lua
-- Find nearest social gathering node within tether range
local social_nodes = minetest.find_nodes_in_area(
    vector.subtract(home_pos, {x=50, y=10, z=50}),
    vector.add(home_pos, {x=50, y=10, z=50}),
    {"eg_settlers:workplace_deed"}  -- filter for brewer's workplace
)
```

The result is cached in `self.social_pos` and persisted in staticdata. It only needs to be recalculated if the node is destroyed or moved.

### Gathering Behavior

Not all NPCs go to the tavern every night. A random roll determines participation:

```lua
if phase == "social" then
    if math.random(100) <= 70 then  -- 70% chance to socialize
        local offset = {
            x = math.random(-3, 3),
            y = 0,
            z = math.random(-3, 3)
        }
        local gather_pos = vector.add(self.social_pos, offset)
        eg_settlers.navigate_to(self, gather_pos)
    else
        self.order = "wander"  -- Stay home tonight
    end
end
```

The random offset prevents NPCs from stacking on top of each other at the social node.

### Social Node Types

| Node | Who Gathers | When |
|---|---|---|
| Brewer's Workplace (Tavern) | All professions | Evening social phase |
| Town Ledger / Job Board | All professions | Could add a "morning meeting" phase |
| Church / Temple (future) | All professions | Specific day of the week? |

---

## 5. Staticdata Persistence

The following fields must survive entity unload/reload. They are added to the mobs_redo serialization cycle. Since mobs_redo auto-serializes all fields on the entity table that are basic types (string, number, table of basic types), **these should persist automatically** as long as they are set directly on `self`:

*   `self.work_pos` — `{x=N, y=N, z=N}` or `nil`
*   `self.social_pos` — `{x=N, y=N, z=N}` or `nil`
*   `self._current_phase` — `string` (schedule phase name)

**Verification required:** Confirm that mobs_redo's `get_staticdata` / `on_activate` round-trips these fields. If not, they must be explicitly added to the serialization in `npc_behavior.lua`'s `on_activate` override.

Navigation state (`_nav_waypoints`, `_nav_stuck_timer`, etc.) is intentionally NOT persisted. When an NPC reloads, the scheduler immediately evaluates the current game time and transitions to the correct phase, re-triggering `navigate_to` if needed.

---

## 6. File Changes Summary

| File | Change |
|---|---|
| `npc_behavior.lua` | Replace day/night branch with schedule state machine. Add waypoint-following logic to `on_step`. Add `navigate_to()` function. |
| `settlement.lua` | Register `workplace_deed` node (or new file `workplace.lua`). |
| `spawners.lua` | Set `ent.pathfinding = 1` on all spawned traders. Add `work_pos` to `spawn_trader` override_data. |
| `contracts.lua` | Support contract-on-workplace-deed interaction for assigning workers. |
| `init.lua` | Load new `workplace.lua` if separated out. |
| `trades.lua` | No changes. |

### Estimated Scope

| Component | New Lines (approx) |
|---|---|
| `navigate_to()` + waypoint following | ~100-120 |
| Schedule state machine (replacing day/night) | ~60-80 |
| Workplace Deed node + crafting | ~60-80 |
| Social congregation logic | ~30-40 |
| Contract-on-workplace interaction | ~40-50 |
| Staticdata verification / fixes | ~10-20 |
| **Total** | **~300-390** |

---

## 7. Implementation Order

1. **`navigate_to` wrapper + waypoint following** — Foundation for everything else. Can be tested immediately by replacing the existing tether-walk and night-teleport with `navigate_to(self, self.home_pos)`.
2. **Schedule state machine** — Replace binary day/night with multi-phase. Initially all non-sleep phases just wander (no `work_pos` yet).
3. **Workplace Deed node** — Register the node, add `work_pos` to NPC entity, wire up assignment.
4. **Work phase integration** — Schedule's work phases now call `navigate_to(self, self.work_pos)`.
5. **Social congregation** — Add social node discovery, random participation, crowd offset.
6. **Polish** — Tune timing, add chat barks ("Time for a drink!", "Back to the forge."), particle effects on arrival.
