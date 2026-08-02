# Settler Death Management & Unburied Remains Feature Spec

This document details the planned design for settler death tracking, incident logging, and the "Unburied Remains" gameplay mechanic.

## Overview
When a settler dies, rather than disappearing silently or dropping generic loot, their death triggers a two-part system:
1. **Incident Log (Graveyard DB):** Records death metadata in the settlement database and exposes it via the Town Ledger UI.
2. **Unburied Remains & Burial Mechanic:** Places a temporary node at the death location. Players collect the remains and dispose of them via headstones, crypts, pyres, composting, or direct earth burial. If left undisturbed for 5 minutes, a hostile **Shade** spawns from the site.

---

## Technical Specifications

### 1. Incident & Killer Tracking (`npc/npc_behavior.lua` & `api/settlement_db.lua`)
- **Attacker Caching (`on_punch`):** `mobs_redo` does not pass the killer object to `on_die`. In `on_punch`, cache `self.last_puncher = puncher` and `self.last_punch_time = os.time()`.
- **Cause Determination (`on_die`):** Inspect `self.last_puncher` to determine if the death was caused by a Player, Mob, or Environment (lava/drowning/fall).
- **Data Schema:** Each town stores a `death_log` array in its database record:
  ```lua
  {
    id = "death_1722550000",
    settler_name = "Arthur",
    profession = "Miner",
    skin = "male_miner.png",
    pos = {x = 102, y = 5, z = -40},
    cause = "Killed by mob", -- "Player", "Mob", or "Environment"
    killer = "mobs_monster:dirt_monster",
    timestamp = 1722550000,
    status = "Unburied" -- "Unburied", "Buried", "Cremated", "Composted", or "Shaded"
  }
  ```
- **Database Log Archiving (Cap = 25):** 
  - `settlement_db.lua` caps the detailed `death_log` array at the **last 25 active deaths** to prevent database and UI formspec bloat.
  - Older entries beyond 25 auto-archive into an aggregate counter: `historical_fallen_count`.
- **Town Ledger Interface (Graveyard Tab):** Displays a scrollable log of the 25 most recent settler deaths, cause of death, burial status, coordinates of unburied remains, and total historical mortality statistics.

---

### 2. Unburied Remains & Burial Options (`nodes/remains.lua`, `nodes/headstone.lua`, `nodes/crypt.lua`)
- **Solid Ground Placement:** `on_die` verifies `pos`. If `pos` is air/liquid, it steps downward to find the nearest solid node (`walkable = true`) before calling `minetest.set_node`.
- **Node Metadata:** Stores `town_id`, `death_id`, `settler_name`, `profession`, `skin`, and `death_timestamp = os.time()`.
- **Nodetimer (5 Minutes):** Starts a 300-second `nodetimer` upon placement to give ample time after combat.
- **Collection (`on_dig` on Remains Node):** 
  - Digging `eg_settlers:remains` at the death site clears the node and drops `bones:bones` with item metadata (`settler_name`, `profession`, `death_id`, `town_id`).

#### Disposal & Burial Methods

1. **Simple Earth Burial (Universal Tradition - Zero Metadata):**
   - Right-clicking any soil block (`default:dirt`, `default:dirt_with_grass`) while holding `bones:bones` consumes the item.
   - Updates `status = "Buried"` in `api/settlement_db.lua` and permanently cancels the Shade spawn.
   - The soil block receives zero node metadata or infotext, remaining 100% standard, mineable, and reusable terrain.
2. **Individual Headstone (`eg_settlers:headstone`):**
   - Single-settler tombstone node (drawtype `nodebox` using stone and `bones_front.png` overlays).
   - Right-clicking with `bones:bones` stores settler metadata, sets an in-game epitaph (`Here lies <name>`), updates DB `status = "Buried"`, and cancels the Shade spawn.
   - Digging a buried headstone returns the node to inventory without reverting DB status (safe graveyard relocation).
3. **Multi-Block Crypt Vault (`eg_settlers:crypt`):**
   - A multi-block structure built in graveyards to store up to **20 settler remains** in a realistic, space-efficient vault.
   - Right-clicking accepts `bones:bones` and appends the settler to the Crypt roster.
4. **Pyre Cremation (`new_campfire` Integration):**
   - Players right-click a campfire / pyre (`new_campfire`) while holding `bones:bones`.
   - Consumes the remains, ignites the fire animation, produces `bonemeal:bonemeal` / ash, and updates DB `status = "Cremated"` to permanently prevent the Shade.
5. **Agricultural Composting (`compost` Mod Integration):**
   - Placing `bones:bones` into a compost bin (`techage_modpack/compost`).
   - Converts the remains into organic fertilizer / soil over time, updating DB `status = "Composted"` to permanently prevent the Shade.

---

### 3. Settler Shade Entity (`npc/shade.lua`)
- **Mob Framework:** Registered via `mobs:register_mob("eg_settlers:shade", ...)` with `type = "monster"`, using the standard `mobs_character.b3d` mesh.
- **Dynamic Identity & Texture Modifiers:** Re-uses the dead settler's specific skin texture with Minetest engine texture modifiers applied upon spawning:
  ```lua
  -- Darkened / Desaturated Shade Texture (Preserves clothing & skin identity)
  local shade_texture = original_skin .. "^[multiply:#556655^[colorize:#112211:80"
  ```
- **Instantiation Helper (`eg_settlers.spawn_shade(pos, data)`):**
  - Spawns `"eg_settlers:shade"`.
  - Sets `object:set_properties({textures = {shade_texture}, nametag = "Shade of " .. settler_name})`.
  - Sets `use_texture_alpha = "blend"` for translucent rendering.
- **Behavior:**
  - Hostile toward players, remaining settlers, and passive mobs.
  - `light_damage = 0` so Shades persist in daylight and darkness until defeated.

---

## Integration with Existing Systems
- **Guard Retaliation (Alarm System):** If the death cause is identified as player assault, nearby guards receive an immediate distress alert.
- **Reputation Penalties:** Unsettled settler murders decrease the player's reputation with local merchants.
