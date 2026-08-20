# Evergrowth Villages: NPC Daily Schedules, Job Blocks & Pathfinding

This document outlines the technical implementation for the **daily schedule state machine**, **inter-settler scheduled visits**, and the lightweight **`navigate_to` pathfinding wrapper** that powers NPC movement between locations.

---

## 1. Pathfinding: The `navigate_to` Wrapper

All scheduled movement (work, social, home) is powered by a single reusable function that wraps the engine's C++ A* pathfinder (`core.find_path`). This replaces the current instant-teleport and dumb-walk-to-tether behaviors with obstacle-aware navigation and safe teleport fallbacks.

### Why Not Use `go_to()` / `smart_mobs()`?

The existing mobs_redo pathfinding (`smart_mobs` in `api.lua:1440`) only fires during combat (`state == "attack"`). The `go_to(pos)` helper abuses this by spawning a phantom entity and "attacking" it — causing NPCs to run at combat speed, risking target-switching if an enemy appears, and leaving state resets that freeze non-combat entities. We need a clean, schedule-driven alternative.

### Architecture

`eg_settlers.navigate_to(self, target_pos)` is called **once** when an NPC transitions between schedule phases (e.g., commute $\rightarrow$ work). It is NOT called every tick.

```
navigate_to(self, target_pos)
│
├── 1. Is NPC already within 2 blocks of target?
│   └── YES → Skip. Set state to arrived.
│
├── 2. Does NPC have line_of_sight to target? (core.line_of_sight with eye offset)
│   └── YES → Direct walk (yaw_to_pos + set_velocity).
│
├── 3. Pre-pathing Door Check:
│   └── Scan and open any closed door within 1.5 blocks of NPC via doors.get(pos):open()
│       (Ensures A* pathfinder is not blocked when starting inside closed bedrooms)
│
├── 4. Call core.find_path(npc_pos, target_pos, ...)
│   ├── Path found → Store in self._nav_waypoints. Begin waypoint walk.
│   └── Path NOT found → Fallback safe teleport (eg_settlers.safe_teleport).
│
└── 5. Waypoint following runs in on_step(self, dtime):
    ├── Check for closed doors within 1.5 blocks ahead and auto-open (doors.get(pos):open())
    ├── Track opened doors in self._nav_opened_doors and close once NPC is 2+ blocks away
    ├── Distance to current waypoint < 0.8 → pop waypoint, yaw to next
    ├── All waypoints consumed → arrived
    └── Stuck timer > 10s with no progress → fallback safe teleport (eg_settlers.safe_teleport)
```

### Parameters for `core.find_path`

| Parameter | Value | Rationale |
|---|---|---|
| `searchdistance` | 25 | Covers settlement tether radius. Keeps CPU cost low. |
| `max_jump` | 1 | Standard step/jump height. |
| `max_drop` | 3 | Allows walking down slopes and staircases. |
| `algorithm` | `"A*_noprefetch"` | Engine default. Fastest for short settlement paths. |

### Door Interaction & Obstacle Resolution

Standard `core.find_path` treats closed door nodes (`group:door`) as solid (`walkable = true`). Calling `find_path` while inside a closed residence will return `nil` if the exit door is shut.

In the Minetest Game `doors` mod, all door state variants (`_a`, `_b`, `_c`, `_d`) define `walkable = true`. Therefore, inspecting node definition flags (`def.walkable`) cannot distinguish open vs. closed doors. Door state must be checked and manipulated using the official `doors.get(pos)` API:

1. **Pre-Pathing Door Open:** In `navigate_to()`, before executing `core.find_path()`, scan 1.5 blocks around the NPC. If `doors.get(pos)` returns a door where `not door:state()`, call `door:open()` and track the position in `self._nav_opened_doors`.
2. **Proximity Auto-Opener in Waypoint Loop:** While following waypoints in `on_step`, scan 1.5 blocks around the NPC. If a nearby door is closed (`not door:state()`), call `door:open()` and append to `self._nav_opened_doors`.
3. **Door Closure:** On each `on_step`, iterate `self._nav_opened_doors`. If the NPC is $\ge 2.0$ blocks away from an opened door, call `door:close()` and remove it from the tracking list.

### Implementation: New Entity Fields

| Field | Type | Persisted? | Purpose |
|---|---|---|---|
| `self._nav_waypoints` | `table` or `nil` | No (runtime only) | Current A* waypoint list |
| `self._nav_target` | `vector` or `nil` | No | Final destination |
| `self._nav_stuck_timer` | `number` | No | Elapsed seconds without position change |
| `self._nav_last_pos` | `vector` or `nil` | No | Position at last tick check |
| `self._nav_state` | `string` or `nil` | No | `"walking"`, `"arrived"`, or `nil` |
| `self._nav_opened_doors`| `table` or `nil` | No | List of door positions opened to close behind NPC |

### Safe Teleport Helper (`eg_settlers.safe_teleport`)

Refactor the existing inline bed/job teleportation offset loop into a reusable helper in `npc_behavior.lua`:

```lua
function eg_settlers.safe_teleport(self, target_pos)
    if not target_pos then return false end
    local dest = {x = target_pos.x, y = target_pos.y + 0.5, z = target_pos.z}
    local offsets = {
        {x=0, y=0.5, z=0}, {x=0, y=1.0, z=0},
        {x=0, y=0.5, z=1}, {x=0, y=0.5, z=-1},
        {x=1, y=0.5, z=0}, {x=-1, y=0.5, z=0},
        {x=0, y=-0.5, z=1}, {x=0, y=-0.5, z=-1},
        {x=1, y=-0.5, z=0}, {x=-1, y=-0.5, z=0},
    }
    for _, off in ipairs(offsets) do
        local test_pos = {x = target_pos.x + off.x, y = target_pos.y + off.y, z = target_pos.z + off.z}
        local test_head = {x = test_pos.x, y = test_pos.y + 1, z = test_pos.z}
        local node1 = minetest.get_node(test_pos)
        local node2 = minetest.get_node(test_head)
        local def1 = minetest.registered_nodes[node1.name]
        local def2 = minetest.registered_nodes[node2.name]
        if def1 and not def1.walkable and def2 and not def2.walkable then
            dest = test_pos
            break
        end
    end
    self.object:set_pos(dest)
    return true
end
```

### Waypoint Following (in `on_step`)

Runs inside the behavior loop in `npc_behavior.lua` when `self._nav_waypoints ~= nil`:

```lua
if self._nav_waypoints and #self._nav_waypoints > 0 then
    local wp = self._nav_waypoints[1]
    local dist_to_wp = vector.distance(pos, wp)

    -- Proximity door opener
    local door_nodes = minetest.find_nodes_in_area(
        vector.subtract(pos, {x=1.5, y=0.5, z=1.5}),
        vector.add(pos, {x=1.5, y=1.5, z=1.5}),
        {"group:door"}
    )
    for _, dpos in ipairs(door_nodes) do
        local door = doors.get(dpos)
        if door and not door:state() then
            door:open()
            self._nav_opened_doors = self._nav_opened_doors or {}
            table.insert(self._nav_opened_doors, dpos)
        end
    end

    -- Close doors left behind
    if self._nav_opened_doors then
        for i = #self._nav_opened_doors, 1, -1 do
            local dpos = self._nav_opened_doors[i]
            if vector.distance(pos, dpos) >= 2.0 then
                local door = doors.get(dpos)
                if door and door:state() then
                    door:close()
                end
                table.remove(self._nav_opened_doors, i)
            end
        end
    end

    if dist_to_wp < 0.8 then
        table.remove(self._nav_waypoints, 1)
        if #self._nav_waypoints == 0 then
            self._nav_waypoints = nil
            self._nav_state = "arrived"
            self.order = "stand"
            self:set_velocity(0)
            self:set_animation("stand")
        else
            self:yaw_to_pos(self._nav_waypoints[1])
            self:set_velocity(self.walk_velocity)
            self:set_animation("walk")
        end
    else
        self:yaw_to_pos(wp)
        self:set_velocity(self.walk_velocity)
        self:set_animation("walk")
    end

    -- Stuck detection (accumulates real frame delta time)
    self._nav_stuck_timer = (self._nav_stuck_timer or 0) + dtime
    local last = self._nav_last_pos or pos
    if vector.distance(pos, last) < 0.3 then
        if self._nav_stuck_timer > 10.0 then
            -- Fallback teleport with safety offsets
            eg_settlers.safe_teleport(self, self._nav_target)
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
    return
end
```

---

## 2. Job Block & Home Anchor Architecture

Settlers bind to two physical anchor points in the world:

1. **`self.job_pos` (Job Block):** A profession-specific workstation node (`eg_settlers:job_block_<profession>`) registered in `town/job_blocks.lua`. Bound when the player places a Hiring Contract (`eg_settlers:hiring_contract`) on the block. Persisted on the entity instance, in the job block node metadata, and in `eg_settlers.db` (`residents[key].pos`).
2. **`self.home_pos` (Bed):** A bed node (`group:bed`) within settlement bounds. Bound during hiring or auto-discovered if homeless. Persisted on the entity instance, in the bed node metadata, and in the job block node metadata (`job_meta:get_string("home_pos")`).

---

## 3. Daily Schedule State Machine

The binary day/night check in `npc_behavior.lua` is replaced with a multi-phase schedule driven by `minetest.get_timeofday() * 24000`.

### Schedule Definition

```lua
local SCHEDULES = {
    default = {
        {start = 0,     stop = 4500,  phase = "sleep",   target = "home_pos"},
        {start = 4500,  stop = 5500,  phase = "commute", target = "job_pos"},
        {start = 5500,  stop = 11000, phase = "work",    target = "job_pos"},
        {start = 11000, stop = 12500, phase = "wander",  target = nil},
        {start = 12500, stop = 17000, phase = "work",    target = "job_pos"},
        {start = 17000, stop = 18500, phase = "social",  target = nil},
        {start = 18500, stop = 24000, phase = "sleep",   target = "home_pos"},
    },
    guard_day = {
        {start = 0,     stop = 4500,  phase = "sleep",   target = "home_pos"},
        {start = 4500,  stop = 18500, phase = "patrol",  target = nil},
        {start = 18500, stop = 24000, phase = "sleep",   target = "home_pos"},
    },
    guard_night = {
        {start = 0,     stop = 6500,  phase = "patrol",  target = nil},
        {start = 6500,  stop = 16500, phase = "sleep",   target = "home_pos"},
        {start = 16500, stop = 24000, phase = "patrol",  target = nil},
    },
}
```

### Phase Behaviors

| Phase | Movement | State | Animation | Duration |
|---|---|---|---|---|
| `sleep` | Navigate to `home_pos` bed | `order = "stand"` | `"stand"` | Night (18500–4500) for standard villagers |
| `commute` | Navigate to `job_pos` | `order = "walk"` | `"walk"` | Dawn (4500–5500) |
| `work` | Stay at `job_pos` | `order = "stand"` | `"stand"` | Morning (5500–11000) & Afternoon (12500–17000) |
| `wander` | Midday break / supply-chain visits | `order = "wander"` | varies | Midday (11000–12500) |
| `social` | Tavern / Library visits | `order = "stand"` | `"stand"` | Dusk (17000–18500) |
| `patrol` | Patrol within extended tether | `order = "wander"` | varies | Guards only (split by day/night shift) |

### Staggered Schedule Shifts (CPU Spike Mitigation)

To prevent all villagers in a settlement from invoking `core.find_path` on the exact same server step during global phase boundaries (e.g. exactly at `4500` dawn commute), each NPC generates an in-memory jitter offset on initialization:

```lua
self._schedule_jitter = self._schedule_jitter or math.random(-200, 200)
local effective_time = (minetest.get_timeofday() * 24000 + self._schedule_jitter) % 24000
```

This distributes pathfinding and navigation across a ~20-second window, keeping step times smooth even in large towns.

### MapBlock / Chunk Activation Fast Catch-Up (`on_activate`)

When a player re-enters an area after several in-game hours, entities reactivate via `on_activate(self, staticdata, dtime)`. Attempting pathfinding over large time jumps causes NPCs to walk to outdated locations or navigate across newly loaded geometry.

In `base_entity.on_activate`:
```lua
if self.is_villager and dtime > 0 then
    local current_time = (minetest.get_timeofday() * 24000 + (self._schedule_jitter or 0)) % 24000
    local schedule_key = "default"
    if self.evergrowth_profession == "guard" then
        schedule_key = (self.guard_shift == "night") and "guard_night" or "guard_day"
    else
        schedule_key = self.evergrowth_profession or "default"
    end
    local schedule = SCHEDULES[schedule_key] or SCHEDULES.default
    
    for _, entry in ipairs(schedule) do
        if current_time >= entry.start and current_time < entry.stop then
            self._current_phase = entry.phase
            local target_pos = entry.target and self[entry.target]
            if target_pos then
                eg_settlers.safe_teleport(self, target_pos)
            end
            break
        end
    end
    self._nav_waypoints = nil
    self._nav_state = "arrived"
end
```

### Phase Transition Execution

`self._current_phase` tracks the active phase. On each 1-second behavior tick:

```lua
local current_time = (minetest.get_timeofday() * 24000 + (self._schedule_jitter or 0)) % 24000
local schedule_key = "default"
if self.evergrowth_profession == "guard" then
    schedule_key = (self.guard_shift == "night") and "guard_night" or "guard_day"
else
    schedule_key = self.evergrowth_profession or "default"
end
local schedule = SCHEDULES[schedule_key] or SCHEDULES.default
local new_entry = nil

for _, entry in ipairs(schedule) do
    if current_time >= entry.start and current_time < entry.stop then
        new_entry = entry
        break
    end
end

if new_entry and new_entry.phase ~= self._current_phase then
    self._current_phase = new_entry.phase
    
    if new_entry.phase == "wander" then
        -- Check for midday supply-chain visit target (50% internal roll)
        local visit_pos = eg_settlers.get_supply_chain_target(self)
        if visit_pos then
            eg_settlers.navigate_to(self, visit_pos)
        else
            self.order = "wander"
        end
    elseif new_entry.phase == "social" then
        -- Check for library or tavern visit target (internal roll & distribution)
        local visit_pos = eg_settlers.get_social_target(self)
        if visit_pos then
            eg_settlers.navigate_to(self, visit_pos)
        else
            self.order = "wander"
        end
    elseif new_entry.target then
        local target_pos = self[new_entry.target]
        if target_pos then
            eg_settlers.navigate_to(self, target_pos)
        else
            self.order = "wander"
        end
    end
end
```

---

## 4. Congregation & Scheduled Visits

During `wander` (midday) and `social` (evening) phases, settlers can navigate to other villagers' job blocks (`eg_settlers:job_block_<prof>`).

### 4.1 Evening Brewer (Tavern) Visits (`17000 - 18500`)

A random subset of all settlers (e.g., 50% chance) visits the Brewer's workstation (`eg_settlers:job_block_brewer`) during the evening social window. Settlers who fail the roll remain in their local area wandering near their job block or residence.

```lua
function eg_settlers.get_tavern_target(self)
    -- Random subset roll: 50% chance to socialize at the Brewer's workstation
    if math.random(100) > 50 then return nil end

    local brewer_blocks = minetest.find_nodes_in_area(
        vector.subtract(self.object:get_pos(), {x=50, y=10, z=50}),
        vector.add(self.object:get_pos(), {x=50, y=10, z=50}),
        {"eg_settlers:job_block_brewer"}
    )
    if #brewer_blocks > 0 then
        local base = brewer_blocks[1]
        return {x = base.x + math.random(-2, 2), y = base.y, z = base.z + math.random(-2, 2)}
    end
    return nil
end
```

### 4.2 Midday Supply-Chain Visits (`11000 - 12500`)

Upstream resource gatherers have a random chance (e.g., 50%) to visit downstream processors during the lunch break.

| Settler Profession | Target Workstation Node | Narrative Action |
|---|---|---|
| **Miner** | `eg_settlers:job_block_smith` | Delivers ores to forge |
| **Lumberjack** | `eg_settlers:job_block_carpenter` | Delivers timber to workshop |
| **Farmer** | `eg_settlers:job_block_brewer` or `eg_settlers:job_block_rancher` | Delivers grains/crops |
| **Gunsmith** | `eg_settlers:job_block_smith` | Confers at anvil |
| **Technologist** | `eg_settlers:job_block_roboticist` or `eg_settlers:job_block_automobile_mechanic` | Reviews machinery |
| **Fisher** | `eg_settlers:job_block_brewer` | Delivers fish to kitchen |

```lua
local SUPPLY_CHAIN_MAP = {
    miner = "eg_settlers:job_block_smith",
    lumberjack = "eg_settlers:job_block_carpenter",
    farmer = "eg_settlers:job_block_brewer",
    gunsmith = "eg_settlers:job_block_smith",
    technologist = "eg_settlers:job_block_roboticist",
    fisher = "eg_settlers:job_block_brewer",
}

function eg_settlers.get_supply_chain_target(self)
    -- Random subset roll: 50% chance to visit partner
    if math.random(100) > 50 then return nil end

    local target_node = SUPPLY_CHAIN_MAP[self.evergrowth_profession]
    if not target_node then return nil end

    local nodes = minetest.find_nodes_in_area(
        vector.subtract(self.object:get_pos(), {x=50, y=10, z=50}),
        vector.add(self.object:get_pos(), {x=50, y=10, z=50}),
        {target_node}
    )
    if #nodes > 0 then
        local base = nodes[1]
        return {x = base.x + math.random(-1, 1), y = base.y, z = base.z + math.random(-1, 1)}
    end
    return nil
end
```

### 4.3 Educated Profession Social Distribution (Library vs. Brewer)

Educated and technical professions (`mage`, `technologist`, `roboticist`) do not exclusively visit the library. During the evening social phase, their destination is distributed as follows:
- **40% Chance:** Visit the Librarian's job block (`eg_settlers:job_block_librarian`).
- **35% Chance:** Visit the Brewer's job block (`eg_settlers:job_block_brewer`).
- **25% Chance:** Stay and wander near their own workstation/home.

```lua
local LIBRARY_VISITORS = {
    mage = true,
    technologist = true,
    roboticist = true,
}

function eg_settlers.get_social_target(self)
    local prof = self.evergrowth_profession
    local roll = math.random(100)

    if LIBRARY_VISITORS[prof] then
        if roll <= 40 then
            -- 40% chance: Visit Library
            local nodes = minetest.find_nodes_in_area(
                vector.subtract(self.object:get_pos(), {x=50, y=10, z=50}),
                vector.add(self.object:get_pos(), {x=50, y=10, z=50}),
                {"eg_settlers:job_block_librarian"}
            )
            if #nodes > 0 then
                local base = nodes[1]
                return {x = base.x + math.random(-2, 2), y = base.y, z = base.z + math.random(-2, 2)}
            end
        elseif roll <= 75 then
            -- 35% chance: Visit Brewer
            return eg_settlers.get_tavern_target(self)
        end
        -- Remaining 25%: Wander locally
        return nil
    end

    -- Non-educated professions check standard Brewer target
    return eg_settlers.get_tavern_target(self)
end
```

---

## 5. File Changes Summary

| File | Change |
|---|---|
| `npc_behavior.lua` | Replace binary day/night branch with schedule state machine. Add waypoint-following, door auto-opener, and `eg_settlers.safe_teleport()` to `on_step`. Add `navigate_to()` function. |
| `town/job_blocks.lua` | No schema changes. Existing `eg_settlers:job_block_<prof>` nodes serve as navigation targets. |
| `town/contracts.lua` | No changes. Existing hiring contract flow already binds `self.job_pos` and `self.home_pos`. |

### Estimated Scope

| Component | New Lines (approx) |
|---|---|
| `navigate_to()` + `safe_teleport()` + waypoint following + door opener | ~130-150 |
| Schedule state machine (supporting guard shifts) | ~70-90 |
| Visit resolution functions (tavern, supply chain, library) | ~40-50 |
| **Total** | **~240-290** |

---

## 6. Implementation Order

1. **`navigate_to` wrapper + `safe_teleport` helper + waypoint following + door opener:** Implement in `npc_behavior.lua` and test navigating between bed and job block without teleporting.
2. **Schedule state machine:** Replace day/night check with multi-phase table (`sleep`, `commute`, `work`, `wander`, `social`) and guard shift routing.
3. **Scheduled visits integration:** Wire up supply-chain, library, and tavern lookups during `wander` and `social` phase transitions.
4. **Tuning & verification:** Verify timing transitions and stuck teleport fallback reliability across diverse village layouts.
