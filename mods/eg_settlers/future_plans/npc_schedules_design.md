# Evergrowth Villages: NPC Daily Schedules, Job Blocks & Pathfinding

This document outlines the technical implementation for the **daily schedule state machine**, **inter-settler scheduled visits**, **bed sleeping mechanics**, and the **`navigate_to` pathfinding wrapper** that powers NPC movement between locations.

---

## 1. Pathfinding: The `navigate_to` Wrapper

All scheduled movement (work, social, home) is powered by a reusable function that resolves walkable destination positions, pre-opens doors, invokes the engine's C++ A* pathfinder (`core.find_path`), and manages obstacle-aware waypoint following with safe teleport fallbacks.

### Why Not Use `go_to()` / `smart_mobs()`?

The existing mobs_redo pathfinding (`smart_mobs` in `api.lua:1440`) only fires during combat (`state == "attack"`). The `go_to(pos)` helper abuses this by spawning a phantom entity and "attacking" it — causing NPCs to run at combat speed, risking target-switching if an enemy appears, and leaving state resets that freeze non-combat entities. We need a clean, schedule-driven alternative.

### Architecture

`eg_settlers.navigate_to(self, target_pos)` is called **once** when an NPC transitions between schedule phases (e.g., commute $\rightarrow$ work). It is NOT called every tick.

```
navigate_to(self, target_pos)
│
├── 1. Resolve Walkable Goal:
│   └── Call eg_settlers.get_walkable_goal(target_pos, self.object)
│       - Scans horizontal adjacent positions for valid solid floor (rejecting glass, window sills, fences, walls)
│       - Verifies body & head space are non-solid air/passable nodes
│       - Verifies candidate is not already occupied by another entity (anti-stacking)
│
├── 2. Is NPC already within 1.5 blocks of goal?
│   └── YES → Set self._nav_state = "arrived", self._nav_waypoints = nil, self.order = "stand", velocity = 0.
│
├── 3. Pre-pathing Door & Gate Check:
│   ├── Scan within 10 blocks around start_pos and goal_pos for {"group:door", "group:gate"}
│   └── Open closed doors via doors.get(pos):open() and track in self._nav_opened_doors
│       (Ensures closed doors and fence gates do not present solid impassable blocks to A*)
│
├── 4. Indoor Exit Waypointing:
│   └── If NPC is inside an enclosed room and target is outdoors, detect nearest exit doorway
│       and prepend it as the first intermediate waypoint to prevent walking into windows/walls.
│
├── 5. Emerge MapBlocks & Call core.find_path(start_pos, goal_pos, 100, 1, 3, "A*_noprefetch"):
│   ├── minetest.load_area(start_pos, goal_pos) ensures terrain across water/bridges is in memory.
│   ├── Path found → Store in self._nav_waypoints. Reset stuck timers. Begin waypoint walk.
│   └── Path NOT found → Fallback to doorway/directional waypoint with 10s stuck teleport fallback.
│
└── 6. Waypoint following runs in on_step(self, dtime):
    ├── Interrupt check: If entity enters combat/flee state, clear _nav_waypoints and return
    ├── Sleeping check: If self._sleeping, lock velocity = 0, lock bed rotation, bypass mobs_redo loops
    ├── Throttled Door Check (every 0.5s): Auto-open upcoming doors/gates & auto-close doors left behind (>= 2.0 blocks)
    ├── Liquid & Hazard Avoidance: Halt forward motion if next step is liquid (water)
    ├── Elevation Step Assist: Apply jump impulse if next waypoint elevation is > 0.5 blocks higher
    ├── Distance to current waypoint < 0.8 → pop waypoint, reset stuck timer, yaw to next
    ├── All waypoints consumed → arrived (self.order = "stand", velocity = 0, animation = "stand")
    └── Stuck timer (accumulated via 1.0s window displacement check) > 10s → fallback safe teleport
```

### Parameters for `core.find_path`

| Parameter | Value | Rationale |
|---|---|---|
| `searchdistance` | 100 | Accommodates circuitous town paths across bridges, docks, and around water bodies. |
| `max_jump` | 1 | Standard step/jump height (supplemented by stepheight 1.1 and vertical impulse in Lua). |
| `max_drop` | 3 | Allows walking down slopes, stairs, and dock gangways. |
| `algorithm` | `"A*_noprefetch"` | Engine default. Fast search over loaded settlement MapBlocks. |

---

### Critical Engine Limitations & Town Geometry Strategy

1. **Air Raycasts (`core.line_of_sight`) Must Not Be Used for Ground Walking:**
   - 3D air raycasts test for collision between head coordinates. Because the space above water, drops, and fences is open air, `line_of_sight` returns `true` across impassable hazards. Direct line-of-sight shortcuts must not bypass A* ground pathfinding.
2. **Solid Destination Rejection:**
   - Workstations (`job_pos`) and beds (`home_pos`) are solid blocks (`walkable = true`). `core.find_path` immediately fails if destination coordinates are solid. `get_walkable_goal` must resolve a valid standing air coordinate on solid floor adjacent to the target node.
3. **Discrete 1x1x1 Cube Representation in C++:**
   - Minetest's C++ pathfinder treats nodebox slabs, stairs, fence railings, and closed doors as solid cubes. Egress from buildings requires opening doors/gates prior to running `find_path` and setting door waypoints for indoor-to-outdoor transitions.

---

### Valid Floor & Goal Resolution (`get_walkable_goal`)

Window sills, glass panes, fence tops, and thin wall recesses must not be selected as standing destinations:

```lua
function eg_settlers.is_valid_floor(node_name)
    if not node_name or node_name == "air" or node_name == "ignore" then return false end
    local def = minetest.registered_nodes[node_name]
    if not def or not def.walkable then return false end
    if def.drawtype == "glasslike" or def.drawtype == "glasslike_framed" or def.drawtype == "nodebox" or def.drawtype == "fencelike" then
        if node_name:find("glass") or node_name:find("pane") or node_name:find("fence") or node_name:find("wall") or node_name:find("window") then
            return false
        end
    end
    if def.groups and (def.groups.fence or def.groups.wall or def.groups.pane or def.groups.window) then
        return false
    end
    if node_name:find("fence") or node_name:find("window") or node_name:find("pane") or node_name:find("wall") or node_name:find("glass") then
        return false
    end
    return true
end

function eg_settlers.get_walkable_goal(target_pos, exclude_obj)
    if not target_pos then return nil end
    local rounded = {
        x = math.floor(target_pos.x + 0.5),
        y = math.floor(target_pos.y + 0.5),
        z = math.floor(target_pos.z + 0.5)
    }
    
    local offsets = {
        {x=0, y=0, z=1}, {x=0, y=0, z=-1},
        {x=1, y=0, z=0}, {x=-1, y=0, z=0},
        {x=1, y=0, z=1}, {x=-1, y=0, z=1},
        {x=1, y=0, z=-1}, {x=-1, y=0, z=-1},
        {x=0, y=1, z=1}, {x=0, y=1, z=-1},
        {x=1, y=1, z=0}, {x=-1, y=1, z=0},
        {x=0, y=-1, z=1}, {x=0, y=-1, z=-1},
        {x=1, y=-1, z=0}, {x=-1, y=-1, z=0},
    }

    local best_fallback = nil

    for _, off in ipairs(offsets) do
        local candidate = {x = rounded.x + off.x, y = rounded.y + off.y, z = rounded.z + off.z}
        local node_body = minetest.get_node(candidate)
        local node_head = minetest.get_node({x = candidate.x, y = candidate.y + 1, z = candidate.z})
        local node_floor = minetest.get_node({x = candidate.x, y = candidate.y - 1, z = candidate.z})
        
        local def_body = minetest.registered_nodes[node_body.name]
        local def_head = minetest.registered_nodes[node_head.name]

        if def_body and not def_body.walkable and
           def_head and not def_head.walkable and
           eg_settlers.is_valid_floor(node_floor.name) then
            
            -- Anti-stacking: check entity occupancy
            local objs = minetest.get_objects_inside_radius(candidate, 0.7)
            local occupied = false
            for _, obj in ipairs(objs) do
                if obj ~= exclude_obj and not obj:is_player() then
                    occupied = true
                    break
                end
            end

            if not occupied then
                return candidate
            elseif not best_fallback then
                best_fallback = candidate
            end
        end
    end

    return best_fallback or target_pos
end
```

---

### Door Interaction & Obstacle Resolution

In Minetest Game, door nodes define `walkable = true` when closed. When opened via `door:open()`, the doorway node is cleared to `air` (`walkable = false`), allowing passage.

1. **Pre-Pathing Door & Gate Open:** In `navigate_to()`, scan 10 blocks around `start_pos` and `goal_pos` for `group:door` and `group:gate`. Open all closed doors and append positions to `self._nav_opened_doors`.
2. **Doorway-First Intermediate Waypoint:** When navigating from indoors to outdoors, set the nearest exit doorway as waypoint 1.
3. **Throttled Proximity Auto-Opener:** While following waypoints in `on_step`, scan a 2.5m box around the NPC every 0.5 seconds to open any unopened doors/gates along the path.
4. **Throttled Door Closure:** Every 0.5 seconds, iterate `self._nav_opened_doors`. When the NPC is $\ge 2.0$ blocks away from an opened door, call `door:close()` and remove it from tracking.

---

### Implementation: Entity Runtime Fields

| Field | Type | Persisted? | Purpose |
|---|---|---|---|
| `self._nav_waypoints` | `table` or `nil` | No (runtime only) | Current A* waypoint list |
| `self._nav_target` | `vector` or `nil` | No | Final destination |
| `self._nav_stuck_timer` | `number` | No | Elapsed seconds without displacement progress |
| `self._nav_pos_check_timer` | `number` | No | Periodic accumulator for 1-second position checks |
| `self._nav_door_timer` | `number` | No | Periodic accumulator (0.5s) for door open/close checks |
| `self._nav_last_pos` | `vector` or `nil` | No | Position at last 1-second check interval |
| `self._nav_state` | `string` or `nil` | No | `"walking"`, `"arrived"`, or `nil` |
| `self._nav_opened_doors`| `table` or `nil` | No | List of door positions opened to close behind NPC |
| `self._sleeping` | `boolean` or `nil` | No | True when lying down in bed |
| `self._sleep_pos` | `vector` or `nil` | No | Exact mattress coordinate for sleep lock |
| `self._sleep_yaw` | `number` or `nil` | No | Exact yaw angle aligned with bed axis |

---

## 2. Bed Sleeping Mechanics & Geometry

### 2.1 Mattress Surface Alignment

A standard Minetest bed is 0.3125 nodes high. The entity's origin is at its physical center. When rotated 90° into lying posture (`set_rotation({x = math.pi/2, y = yaw, z = 0})`), the vertical resting elevation must be set to `bed_pos.y - 0.15` to sit flush on the mattress without hovering or clipping through the floor.

### 2.2 Longitudinal Bed Alignment

Beds consist of two nodes: `bed_bottom` (foot) and `bed_top` (head/pillow) oriented by `facedir`:

```lua
local is_top = bed_node.name:find("_top") ~= nil
local param2 = (bed_node.param2 or 0) % 4
local yaw = 0
if param2 == 1 then
    yaw = math.pi / 2
elseif param2 == 3 then
    yaw = -math.pi / 2
elseif param2 == 0 then
    yaw = math.pi
else
    yaw = 0
end
local dir = minetest.facedir_to_dir(param2)
local offset_mult = is_top and -0.4 or 0.4
local sleep_pos = {
    x = bed_pos.x + dir.x * offset_mult,
    y = bed_pos.y - 0.15,
    z = bed_pos.z + dir.z * offset_mult
}
```

### 2.3 Physics & AI Freeze While Sleeping

To prevent entities from fidgeting, rotating randomly, or being pushed around while asleep:
- When `self._sleeping == true`, `on_step` locks velocity and acceleration to `{x=0, y=0, z=0}` and locks rotation to `{x = math.pi/2, y = yaw, z = 0}`.
- `on_step` returns early during sleep, completely bypassing `mobs_redo`'s internal state machine and idle wander routines.
- Every 1.0 second, the entity checks time of day; when the schedule exits the `sleep` phase, it clears `self._sleeping`, restores rotation to upright `{x=0, y=yaw, z=0}`, raises position by +0.6 blocks, and begins the morning commute.

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

| Phase | Movement | State | Posture | Duration |
|---|---|---|---|---|
| `sleep` | Navigate to `home_pos` bed | `order = "stand"` | Lying (pitch 90° on mattress) | Night (18500–4500) |
| `commute` | Navigate to `job_pos` | `order = "walk"` | Upright walking | Dawn (4500–5500) |
| `work` | Stationed at `job_pos` | `order = "stand"` | Upright standing | Morning (5500–11000) & Afternoon (12500–17000) |
| `wander` | Midday break / supply-chain visits | `order = "wander"` | Upright walking | Midday (11000–12500) |
| `social` | Tavern / Library visits | `order = "stand"` | Upright standing | Dusk (17000–18500) |
| `patrol` | Patrol within 45-node tether | `order = "wander"` | Upright walking | Guard shifts |

---

## 4. Congregation & Scheduled Visits

During `wander` (midday) and `social` (evening) phases, settlers navigate to other villagers' job blocks (`eg_settlers:job_block_<prof>`).

To avoid full-world voxel queries, targets are looked up directly from `eg_settlers.db` resident records. Destination positions are offset and validated against entity occupancy to prevent vertical entity stacking.

### Helper: Database Job Block Lookup

```lua
function eg_settlers.find_profession_job_block(self, target_profession)
    local pos = self.object:get_pos()
    if not pos then return nil end

    local sid = eg_settlers.db.find_nearest_settlement(pos, 200)
    if sid then
        local residents = eg_settlers.db.get_residents(sid)
        local candidates = {}
        for pos_str, res in pairs(residents) do
            if res.profession == target_profession then
                local x, y, z = pos_str:match("^(%-?%d+%.?%d*),(%-?%d+%.?%d*),(%-?%d+%.?%d*)$")
                local bpos = (x and y and z) and {x = tonumber(x), y = tonumber(y), z = tonumber(z)} or minetest.string_to_pos(pos_str)
                if bpos then
                    table.insert(candidates, bpos)
                end
            end
        end
        if #candidates > 0 then
            return candidates[math.random(#candidates)]
        end
    end

    return nil
end
```

### 4.1 Evening Brewer (Tavern) Visits (`17000 - 18500`)

Settlers have an independent 50% chance to visit the Brewer's workstation (`eg_settlers:job_block_brewer`) during the evening social window.

### 4.2 Midday Supply-Chain Visits (`11000 - 12500`)

Upstream resource gatherers have a 50% chance to visit downstream processors during the lunch break.

| Settler Profession | Target Profession | Narrative Action |
|---|---|---|
| **Miner** | `smith` | Delivers ores to forge |
| **Lumberjack** | `carpenter` | Delivers timber to workshop |
| **Farmer** | `brewer` | Delivers grains/crops |
| **Gunsmith** | `smith` | Confers at anvil |
| **Technologist** | `roboticist` | Reviews machinery |
| **Fisher** | `brewer` | Delivers fish to kitchen |

### 4.3 Educated Profession Social Distribution (Library vs. Brewer)

Educated and technical professions (`mage`, `technologist`, `roboticist`) distribute during the evening social phase:
- **40% Chance:** Visit the Librarian's job block (`eg_settlers:job_block_librarian`).
- **35% Chance:** Visit the Brewer's job block (`eg_settlers:job_block_brewer`).
- **25% Chance:** Stay and wander near their own workstation/home.

---

## 5. Summary of Key Architectural Decisions

1. **Pre-resolved Floor Stand Positions:** `get_walkable_goal` ensures A* receives a valid air block on solid floor rather than rejecting solid workstations/beds.
2. **Door & Gate Automation:** Doors near start and destination are opened prior to pathfinding; doors are automatically opened within 2.5m and closed $\ge 2.0$m behind NPCs.
3. **No Direct Air Shortcuts:** Removed `core.line_of_sight` direct walking to prevent entities from walking into water, drop-offs, and fences.
4. **Bed Sleeping Posture & Freeze:** Entity position snaps to mattress height `bed_pos.y - 0.15` with 90° pitch rotation along `facedir`, with `mobs_redo` loops bypassed until morning.
5. **Anti-Stacking Entity Dispersion:** Congregation destinations check occupancy radius to disperse NPCs around shared counters and workstations.
