# Town Watch Desk (`eg_settlers:town_watch_desk`)

## 1. Overview & Architecture

The **Town Watch Desk** is a municipal defense and justice interaction node in `eg_settlers`. It separates guard management and law enforcement from the civil **Town Ledger**:

- **Town Ledger (Civil Administration):** Placed within settlement territory to manage territory claims, associate access control, town tier progression, population census, and granary/satiation food supplies.
- **Town Watch Desk (Defenses & Justice):** Placed within settlement territory to manage guard patrol shifts, ward stones, incident mortality logs, and criminal justice records.

---

## 2. Node Specification

- **Item String:** `eg_settlers:town_watch_desk`
- **Description:** "Town Watch Desk"
- **Visual Appearance:** 3D mesh node representing a fortified timber and steel command desk with dispatch documents, a town watch register, and metal trim.
- **Crafting Recipe:**
  - `default:steel_ingot` x2
  - `default:wood` x4
  - `default:paper` x2
  - `default:gold_lump` x1
- **Placement & Linking:**
  - Auto-binds to the nearest settlement via `eg_settlers.db.find_nearest_settlement(pos, 200)`.
  - Can be placed, accessed, and configured by the settlement **Owner** or authorized **Associates** (or any player accessing the desk to pay off their own restitution fines).

---

## 3. Formspec Layout & Tab Structure

The node provides an interactive Formspec UI organized into four dedicated operational tabs:

### Tab 1: Guard Operations & Shift Roster
Provides complete visibility and control over all settlement guards without requiring manual re-placement.
- **Guard Roster Table:**
  - Columns: `Name`, `Shift` (`Day` / `Night`), `Duty State` (`On Duty (Workstation)` vs `Off Duty (Bed)`), `Health` (`HP / 50`), `Workstation Pos`.
- **Shift Balance Metric:** Displays total distribution (e.g. `Active Guards: 4 (2 Day / 2 Night)`).
- **Interactive Shift Toggle:**
  - Selecting a guard from the table enables the `[ Switch Shift ]` button.
  - Clicking `[ Switch Shift ]`:
    1. Toggles metadata `guard_shift` between `"day"` and `"night"` on the guard's Armory Stand workstation node.
    2. Updates the live entity `self.guard_shift`.
    3. Dynamically renames the guard's nametag (e.g., `Oscar the Day Guard` $\rightarrow$ `Oscar the Night Guard`).
    4. Triggers instant schedule re-evaluation (if switching to off-duty, walks to bed; if switching to on-duty, wakes and reports to post).
    5. Refreshes the UI in real-time.

### Tab 2: Incident & Mortality Log
Migrated from Tab 3 of the Town Ledger.
- **Recent Deaths List:** Displays timestamped log of fallen settlers with cause of death, killer identity, location coordinates, and burial status.
- **Historical Mortality Counter:** Total lifetime settler deaths recorded in the settlement database.

### Tab 3: Criminal Justice & Restitution
Migrated from Tab 3 of the Town Ledger.
- **Settlement Wanted List:** Displays criminal records for players who committed assaults or murders against settlers, along with decay time estimates.
- **Restitution Fine Paystation:** Allows players with criminal standings to pay off Assault fines (50 Gold Lumps) or Murder fines (200 Gold Lumps) directly from their inventory to restore trading privileges.

### Tab 4: Defense Overview
Summary of active settlement defenses:
- Count of active Ward Stones within territory bounds.
- Ratio of guards to total settlement population.
- Status of automated defenses (e.g., future Sentry Guns, Searchlights).

---

## 4. Migration & Integration Strategy

1. **Town Ledger Clean-up:**
   - Remove `tab_index == 3` (*Incidents & Justice*) from `town_ledger.lua`.
   - The Town Ledger formspec reduces to 2 clean tabs: `Info` (Census & Satiation) and `Access Control` (Owner & Associates).
2. **Database Compatibility:**
   - No schema changes required in `settlement_db.lua`. The Town Watch Desk queries existing fields: `s.residents`, `s.death_log`, `s.criminal_records`, and `s.historical_fallen_count`.
3. **In-Game Documentation:**
   - Update Chapter 2 (*The Town Ledger & Granary*) and Chapter 6 (*Town Defenses & Medical Care*) in `guide_content.lua` to describe the Town Watch Desk.
