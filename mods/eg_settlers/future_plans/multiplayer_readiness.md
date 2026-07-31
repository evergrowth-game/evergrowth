# Evergrowth Settlers: Multiplayer Readiness & Vulnerabilities

This document outlines the current state of the `eg_settlers` mod in a multiplayer environment based on an in-depth code review.

## What is Safe (Protected/Restricted)
1. **Town Granary:** The `allow_metadata_inventory_take` callback explicitly returns `0`. Nobody (not even the person who placed it) can withdraw food points once they are inserted. It functions perfectly as a one-way deposit box for the town's satiation.
2. **Trade Blocking:** The system properly blocks trades with starving towns on an individual villager level.

## What is Vulnerable (The Real Multiplayer Issues)
Because Minetest defaults to allowing inventory interaction if the `allow_metadata_inventory_*` callbacks are omitted, and because the `settlement_db` lacks an `owner` field, several severe vulnerabilities exist for multiplayer:

1. **The Town Depot is Unprotected:**
   Unlike the Granary, `town_depot.lua` does *not* define `allow_metadata_inventory_take` or `allow_metadata_inventory_put`. This means **any player on the server can walk up to another player's Town Depot and steal all of their passive income** (wheat, leather, etc.).

2. **The Job Board is Unprotected:**
   Similarly, `job_board.lua` lacks inventory protection callbacks. Any player can open another town's job board and steal the `default:gold_lump` items placed in the `contract_payment` slot, or steal the rewards from the `bounty_output` slot. 

3. **Anyone Can Disband Any Town:**
   The `town_ledger.lua` formspec handler does not check who is submitting the form fields. If player B finds player A's Town Ledger, player B can click the "Disband" button, and `eg_settlers.db.delete_settlement(sid)` will execute without checking ownership—permanently deleting the town and releasing all villagers.

4. **Territory Merging / Proximity:**
   Because `find_nearest_settlement(pos, 200)` blindly searches by radius, player B could intentionally build Housing Deeds within 200 blocks of player A's town. Player B's villagers would then draw from player A's Granary reserves, essentially parasitizing their food supply.

5. **NPC Removal is Soft-Locked for Normal Players:**
   In `npc_behavior.lua` and `companions.lua`, the code explicitly checks `if minetest.check_player_privs(name, {server=true}) or minetest.is_singleplayer() then` before allowing a player to safely remove/relocate an NPC. In a multiplayer setting, a standard player will be completely unable to remove their own NPCs unless you give them the `server` privilege.

6. **Infrastructure Node Breaking & Explosions:**
   The `town_ledger.lua` has a `can_dig` callback that allows *any* player holding sneak to bypass formspec checks and instantly destroy the ledger. Furthermore, `town_depot.lua`, `town_granary.lua`, and `job_board.lua` lack explicit `can_dig` and `on_blast` protections entirely. A griefer can simply mine these nodes when empty or blow them up with TNT to permanently cripple a town.

## Implementation Plan for Multiplayer Patch
To make this viable for a multiplayer server, the following changes must be implemented:
* **Database Updates:** Add an `owner` string and an `associates` list to settlements in the DB. Add a mechanism to transfer ownership. Add a migration hook on startup to assign ownership of unowned legacy settlements to the host player.
* **Formspec Protection:** Update the Town Ledger formspec to allow the owner to add/remove associates and transfer ownership. Enforce that only the owner or associates can access the Ledger and Job Board formspecs (with some actions like 'Disband' restricted strictly to the owner).
* **Inventory & Node Protection:** Add `allow_metadata_inventory_take` and `allow_metadata_inventory_put` callbacks to the **Job Board** and **Town Depot** so only authorized players can access them. Add strict `can_dig` and `on_blast` protections to all infrastructure nodes to prevent mining bypasses and explosion griefing.
* **NPC Interaction:** Change the NPC removal logic to check if the player is the owner or an associate of the town, rather than checking for admin privileges.
* **Protection Mod Hooks (Optional):** Ensure deeds can only be placed if the player has permission to build in that area (hooks into `areas` or `protector` mods if present), preventing players from placing deeds near towns they don't own.
* **Global Build Protection (Integration):** We can override `minetest.is_protected(pos, name)` so that the Town Ledger itself acts as a massive protection block. If a player tries to build or dig within the town's radius, the system will check if they are the owner or an associate. If not, it blocks the action. https://content.luanti.org/packages/TenPlus1/protector/
* **NPC Damage Deterrence:** We can apply consequences to outside players who attack them, as a disincentive to "griefing". Options include:
  * **Guard Retaliation (Alarm System):** Because normal NPCs have limited vision and line-of-sight, we would implement a "distress call" in the attacked settler's `on_punch` code. This code would instantly scan a large radius for any Guard NPCs and forcefully override their target to the attacker, bypassing their normal vision limits.
  * **Damage Reflection:** A portion of the damage dealt to the settler is reflected back to the attacker.
  * **Reputation Penalty:** The attacker is logged as a criminal or loses reputation in settlement database, which causes all traders in the settlement to refuse service to them permanently or temporarily.
  * **Proportional Justice System (NPC Damage):** Instead of preventing damage, the system tracks damage dealt by any player (including owners) and applies consequences based on severity, mimicking real-world law:
    * **Accidents (Forgiveness Threshold):** Minor, non-lethal damage (e.g., a single punch) is treated as an accident and carries no penalty.
    * **Assault:** If a player crosses a specific damage threshold without killing the settler, it triggers consequences. Guards are alerted to attack the offender, and the player receives a temporary reputation penalty in the town database.
    * **Murder:** Dealing a lethal blow results in the harshest consequences. The player is permanently flagged as an enemy of the town, all traders refuse service permanently, and guards will attack them on sight indefinitely.
  * **Incident Logging (Graveyard):** To provide transparency to the town owner, all settler deaths are recorded in the settlement database. The log will store the timestamp, the victim's name, and the cause of death. 
    * **Technical Implementation:** While the game engine doesn't natively provide a "cause of death" string, we will construct it by caching the `puncher` object during the `on_punch` event as a `last_attacker` variable. During the `on_die` event, the system checks this variable to identify if a player or mob killed the settler. If no attacker is found, the system checks the current map node (e.g., water, lava) to log environmental causes like drowning. The owner can view this log at the Town Ledger to investigate missing villagers.