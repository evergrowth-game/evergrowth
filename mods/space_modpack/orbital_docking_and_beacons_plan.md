# Orbital Station Docking Clamps & Public Navigation Beacons

## 1. Overview & User Story
Players construct spaceships and stationary orbital outposts (space stations). This system enables ships to:
1. **Discover & Navigate to Stations:** Station owners publish coordinates via **Public Navigation Beacons**, allowing any pilot to select the station from their Bridge Navigation Console and plot standoff jump coordinates without in-world HUD clutter.
2. **Dock & Undock Seamlessly:** Ships physically couple to stations via **Docking Clamps** and open interior non-wood airlock doors to walk across without EVA spacewalks.
3. **Depart Cleanly:** When a docked ship executes a jump, the scanner boundary halts at the clamp interface, migrating only the spacecraft and leaving the station intact at its orbital coordinates.
4. **Centralized Security & Commercial Vending:** Station owners configure global docking permissions and metered fuel/power vending from their central console.

---

## 2. Technical Architecture & File Organization

### 2.1 File Map
- **`mods/space_modpack/jumpdrive_tweaks/beacon.lua`**: Public broadcast flag, formspec toggle, metadata persistence, and HUD exclusion for third parties.
- **`mods/space_modpack/jumpdrive_tweaks/bridge_console.lua`**: Destination dropdown sorting (displaying `[Public]` beacons) and central docking policy management tab.
- **`mods/space_modpack/jumpdrive_tweaks/nodes_docking.lua`**: Node registration for `jumpdrive_tweaks:docking_clamp` (and `jumpdrive_tweaks:docking_clamp_locked`), facedir handling, coupling state machines, and sound triggers.
- **`mods/space_modpack/jumpdrive_tweaks/validator.lua`**: Scanner contact-plane termination logic in `scan_spacecraft`.
- **`mods/space_modpack/jumpdrive_tweaks/init.lua`**: Module inclusion for `nodes_docking.lua`.
- **`tests/space_modpack/test_docking_clamps.lua`**: Dedicated automated test suite covering scanner isolation, clamp states, permissions, and vending transactions.

---

## 3. Detailed Specifications

### 3.1 Public Navigation Beacons

#### Metadata Schema
- **`meta:set_string("is_public", "true" | "false")`** (Default: `"false"`)
- Stored in `active_beacons` storage table:
  ```lua
  active_beacons[key] = {
      pos = {x = pos.x, y = pos.y, z = pos.z},
      owner = owner_name,
      name = beacon_name,
      is_public = (is_public_bool == true)
  }
  ```

#### Formspec Updates (`jumpdrive_tweaks/beacon.lua`)
- Add checkbox to beacon configuration:
  ```lua
  "checkbox[0.8,2.3;is_public;Public Broadcast (Visible to all ship consoles);" .. (is_public and "true" or "false") .. "]"
  ```

#### HUD Filtering Rule
- In `beacon.lua` globalstep:
  - Personal 3D waypoint HUD is displayed **only** if `bdata.owner == player_name` or if tracking an unowned procedural derelict distress beacon.
  - Public beacons (`bdata.is_public == true`) placed by other players are **excluded** from generating in-world 3D HUD waypoints on third-party screens.

#### Console Navigation List (`jumpdrive_tweaks/bridge_console.lua`)
- In `jumpdrive_tweaks.get_valid_sorted_beacons()`:
  - Return all beacons owned by the pilot, plus all beacons where `binfo.is_public == true`.
  - Format public beacons with `[Public Station: <name>] @ (<x>, <y>, <z>)`.

---

### 3.2 Orbital Station Docking Clamps (`jumpdrive_tweaks:docking_clamp`)

#### Node Registration Details
- **Item Name:** `jumpdrive_tweaks:docking_clamp` (Uncoupled) / `jumpdrive_tweaks:docking_clamp_locked` (Coupled)
- **Groups:** `{cracky = 2, jumpdrive_node = 1, techage_connect = 1, docking_clamp = 1}`
- **Paramtype2:** `"facedir"` (where the front face is the magnetic coupling plane pointing into the docking corridor).
- **Drawtype & Mesh/Nodebox:** Nodebox frame featuring perimeter magnetic latches, status lights, and a central 1x2 gangway clearance.
- **Tiles:**
  - Uncoupled: `jumpdrive_docking_clamp_top.png`, `jumpdrive_docking_clamp_side.png`, `jumpdrive_docking_clamp_face_amber.png`
  - Locked: `jumpdrive_docking_clamp_top.png`, `jumpdrive_docking_clamp_side.png`, `jumpdrive_docking_clamp_face_green.png`

#### Crafting Recipe
```lua
minetest.register_craft({
    output = "jumpdrive_tweaks:docking_clamp 2",
    recipe = {
        {"default:steelblock", "default:mese_crystal", "default:steelblock"},
        {"default:steelblock", "default:copper_ingot",  "default:steelblock"},
        {"default:steelblock", "default:mese_crystal", "default:steelblock"},
    }
})
```

#### Scanner Boundary Logic (`validator.lua`)
In `jumpdrive_tweaks.scan_spacecraft(engine_pos, max_radius)`:

When evaluating neighbor positions `npos` from current node `cpos`:
```lua
local current_node = minetest.get_node(cpos)
if current_node.name:find("jumpdrive_tweaks:docking_clamp") then
    local dir = minetest.facedir_to_dir(current_node.param2)
    local contact_pos = vector.add(cpos, dir)

    -- If the neighbor being evaluated lies directly along the clamp's outward contact face
    if vector.equals(npos, contact_pos) then
        local neighbor_node = minetest.get_node(npos)
        if neighbor_node.name:find("jumpdrive_tweaks:docking_clamp") then
            -- HALT SCANNER PROPAGATION: Do not add neighbor clamp or traverse beyond it
            goto skip_neighbor
        end
    end
end
```

#### Airlock Corridor & Door Rules
- Players place standard non-wood doors (e.g., `doors:door_steel`, `doors:door_glass`) directly behind the clamp inside the cabin.
- Doors anchor to the floor of their respective craft (ship door on ship floor, station door on station floor).
- External hull clearance: ships and stations must contact **only** at their `docking_clamp` interface nodes.

---

### 3.3 Centralized Security & Commercial Vending

#### Central Policy Storage (`bridge_console.lua` / `beacon.lua`)
Stored on the craft's primary control node (e.g., station beacon or bridge console):
- `meta:set_string("dock_policy", "private" | "whitelist" | "vending")` (Default: `"private"`)
- `meta:set_string("dock_whitelist", "player1,player2,player3")`
- `meta:set_string("vending_price_item", "default:steel_ingot")` (Item required for vending)
- `meta:set_int("vending_fuel_units_per_item", 2000)` (Hydrogen units per payment item)
- `meta:set_int("vending_power_units_per_item", 5000)` (TechAge EU per payment item)

#### Policy Enforcement Rules
1. **Private Mode:**
   - On right-click clamp or approach: checks `minetest.is_protected(clamp_pos, player_name)`.
   - If player has no protection rights: clamps refuse to lock, and no utility pass-through occurs.
2. **Whitelist Mode:**
   - Checks if `player_name` exists in `dock_whitelist`. If permitted: locks clamps and enables full power/fuel transfer.
3. **Public Vending Mode:**
   - Anyone can lock clamps.
   - Clamp formspec displays a vending interface:
     - Shows available fuel/power reserves.
     - Deposit slot for payment item (`vending_price_item`).
     - "Dispense Fuel" / "Recharge Batteries" action button.
     - Transfers strictly the purchased quantity into the docked vessel's tanks/batteries, then cuts flow.

---

## 4. Implementation Phases

### Phase 1: Public Navigation Beacons (~1h)
1. Add `is_public` toggle to `jumpdrive_tweaks/beacon.lua` formspec and metadata storage.
2. Update HUD loop to skip public beacons for third parties.
3. Update `get_valid_sorted_beacons` in `bridge_console.lua` to include public stations with `[Public]` prefix.
4. Unit tests in `tests/space_modpack/test_ship_tracker.lua`.

### Phase 2: Docking Clamp Node & Scanner Insulation (~1.5h)
1. Create `mods/space_modpack/jumpdrive_tweaks/nodes_docking.lua` and register `jumpdrive_tweaks:docking_clamp`.
2. Implement contact-plane scanner termination in `validator.lua`.
3. Create `tests/space_modpack/test_docking_clamps.lua` verifying clean vessel separation on jump.

### Phase 3: Centralized Security, Vending & Resource Bridging (~2h)
1. Add "Docking Security" configuration tab to `bridge_console.lua`.
2. Implement TechAge pass-through connection handlers on `docking_clamp` with automatic detachment on jump/undock.
3. Implement metered vending transaction logic and payment slot handling.
4. Unit tests for security rejection, vending transactions, and cable detachment.
