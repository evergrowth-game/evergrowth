# Tech Defenses: Sentry Turret & Surveillance Spotlight

This document specifies the technical design, engine implementation, and asset pipeline for automated tech-based defenses in `eg_settlers` as alternatives and complements to the magical Ward Stone.

---

## 1. Context & Design Goals

The **Ward Stone** provides omnidirectional magical aura defense (dealing 10 damage to hostiles within 15 blocks every second). For tech-oriented settlements, players need non-magical defensive infrastructure that:
1. Fulfills the town defense infrastructure requirement (satisfying Tier 3 Village progression in `settlement_db.lua` alongside or in place of the Ward Stone).
2. Introduces line-of-sight kinetic defense with ammo/maintenance considerations.
3. Integrates with the existing settler Guard alarm system.

---

## 2. Automated Sentry Turret (`eg_settlers:sentry_turret`)

### 2.1 Overview & Role
* **Role:** High-damage, single-target perimeter defense.
* **Range:** 25 blocks (requires clear line-of-sight).
* **Firing Rate:** 1 shot every 0.75 seconds.
* **Damage:** 15 fleshy damage per hit.

### 2.2 Dual-Component Architecture
Because static nodes cannot freely rotate in 3D, the sentry uses a **Base Node + Child Entity** pattern:

```
[Sentry Base Node] (Placed in world, stores ammo inventory)
        │
        └── Spawns on construct ──> [Turret Head Entity]
                                          │
                                          ├── Rotates Pitch & Yaw (set_rotation)
                                          ├── Raycast Line-of-Sight Check
                                          ├── Hitscan Damage Application
                                          └── Muzzle Flash & Tracer Particles
```

1. **Base Node (`eg_settlers:sentry_turret`):**
   * Solid nodebox / `.obj` base (heavy tripod or mounting plate).
   * Node metadata inventory: 1–4 slots for ammunition (e.g. `default:steel_ingot`, bullets, or copper cartridges).
   * `on_construct`: Spawns the turret head entity at `pos + vector.new(0, 0.5, 0)` and records the entity in node metadata.
   * `on_destruct`: Removes the associated head entity.
   * `can_dig`: Prevents digging while ammo is inside or if non-owner.

2. **Head Entity (`eg_settlers:sentry_head`):**
   * Non-solid, non-pushable Lua entity with `.obj` mesh (swivel mount + dual barrels + ammo canister).
   * Handled via `on_step(dtime)` or triggered via the base `node_timer`.

### 2.3 Targeting & 3D Aiming Logic
* **Scan:** Scans nearby objects using `minetest.get_objects_inside_radius(pos, 25)`.
* **Filter:** Targets objects where `lua_ent.type == "monster"` or `lua_ent._cmi_is_mob`.
* **Line-of-Sight:** Validates clear trajectory using `minetest.raycast(muzzle_pos, mob_pos, true, false):next()`.
* **Aiming Vector:** Calculates Euler angles and applies rotational transform directly without skeletal rigging:
  ```lua
  local dir = vector.direction(muzzle_pos, target_pos)
  local yaw = math.atan2(-dir.x, dir.z)
  local pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z))
  self.object:set_rotation({x = pitch, y = yaw, z = 0})
  ```

### 2.4 Firing & Ammo Consumption
* Checks base node inventory for ammo stack:
  * If ammo exists: Decrements stack by 1.
  * If empty: Clicks dry and emits a warning spark particle.
* **Hitscan Damage:** Calls `target:punch(self.object, 1.0, {damage_groups = {fleshy = 15}})` immediately upon line-of-sight confirmation.
* **Visual / Audio Effects:**
  * Muzzle flash particle spawner at barrel offset.
  * Rapid high-velocity tracer particle line from muzzle to target point.
  * Gunshot sound: `minetest.sound_play("eg_settlers_turret_fire", {pos = pos, gain = 0.8, max_hear_distance = 30})`.

---

## 3. Surveillance Spotlight (`eg_settlers:surveillance_spotlight`)

### 3.1 Overview & Role
* **Role:** Long-range early warning, target illumination, and Guard response coordinator.
* **Range:** 35 blocks (matches Guard distress alarm radius).
* **Operation:** Operates during night hours (`time_of_day > 18500` or `< 4500`).

### 3.2 Idle & Active Behavior
* **Idle Scanning:** When no hostiles are present, slowly oscillates yaw across a 90° arc:
  ```lua
  local sweep_yaw = math.sin(minetest.get_gametime() * 1.0) * 0.75 + base_yaw
  self.object:set_rotation({x = -0.2, y = sweep_yaw, z = 0})
  ```
* **Target Lock:** When a hostile mob is detected within 35 blocks and has clear line-of-sight:
  1. Locks pitch and yaw directly onto the monster.
  2. Dispatches a spatial alert to all settlement guards within 35 blocks:
     ```lua
     for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 35)) do
         local ent = obj:get_luaentity()
         if ent and ent.is_villager and ent.evergrowth_profession == "guard" then
             ent.attack = target_obj
             ent.state = "attack"
         end
     end
     ```
  3. Paints the target with a glowing illumination aura (particles / light level).

### 3.3 Dynamic Lighting in Engine
To create illumination without hardware dynamic volumetric lights:
1. **Light Cone Mesh:** Translucent inverted-normal `.obj` cone with an additive glowing texture attached to the spotlight head entity.
2. **Projected Ground Light:** Performs a raycast forward from the spotlight head to the first solid surface. Places an invisible, non-walkable `airlike` light node (`light_source = 14`, similar to `airutils:light`). Reverts the previous light node to `air` whenever the spotlight rotates or shuts down.

---

## 4. Asset Pipeline & Modeling

### 4.1 Zero-Skeletal Rigging Architecture
Neither device requires Blender bone animation, rigging, or `.b3d` keyframes. All mechanical articulation is driven via programmatic Lua `set_rotation` calls on static `.obj` meshes.

### 4.2 Required Models & Textures

| Asset | Type | File Name | Description |
| :--- | :--- | :--- | :--- |
| **Turret Base** | Node Mesh | `eg_settlers_turret_base.obj` | Heavy tripod mount with bolted metal plates |
| **Turret Head** | Entity Mesh | `eg_settlers_turret_head.obj` | Dual barrels, swivel yoke, and ammo drum |
| **Spotlight Base** | Node Mesh | `eg_settlers_spotlight_base.obj` | Swivel bracket stand |
| **Spotlight Head** | Entity Mesh | `eg_settlers_spotlight_head.obj` | Lamp canister with front glass lens |
| **Light Beam Cone** | Entity Mesh | `eg_settlers_light_cone.obj` | Translucent cone attached to lamp face |
| **Textures** | 16x16 / 32x32 PNG | Standard Minetest textures | `default_steel_block.png`, `default_copper_block.png`, `default_glass.png` |

### 4.3 Procedural Generation
Models can be generated using the existing Python geometry script pattern ([generate_job_block_models.py](file:///Users/Aresh/Desktop/Projects/evergrowth/mods/eg_settlers/models/generate_job_block_models.py)), producing voxel-accurate `.obj` files with pre-calculated UV coordinates matching base textures.

---

## 5. Settlement Progression & Recipe Integration

### 5.1 Infrastructure Tier Requirements
In [settler_infrastructure_design.md](file:///Users/Aresh/Desktop/Projects/evergrowth/mods/eg_settlers/future_plans/settler_infrastructure_design.md), update Tier 3 (Village) infrastructure checks in `settlement_db.lua` to accept tech defense alternatives:
* **Tier 3 Requirement:** `eg_settlers:town_depot` + `eg_settlers:job_board` + (`eg_settlers:ward_stone` OR `eg_settlers:sentry_turret`).

### 5.2 Crafting Recipes
* **Sentry Turret:**
  ```lua
  minetest.register_craft({
      output = "eg_settlers:sentry_turret",
      recipe = {
          {"default:steel_ingot", "default:copper_ingot", "default:steel_ingot"},
          {"", "default:steelblock", ""},
          {"default:steel_ingot", "default:obsidian", "default:steel_ingot"},
      }
  })
  ```
* **Surveillance Spotlight:**
  ```lua
  minetest.register_craft({
      output = "eg_settlers:surveillance_spotlight",
      recipe = {
          {"default:steel_ingot", "default:glass", "default:steel_ingot"},
          {"default:copper_ingot", "default:torch", "default:copper_ingot"},
          {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
      }
  })
  ```
