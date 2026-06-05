# Evergrowth Villages: Prioritized Todo List

This document acts as the active roadmap and master task checklist for development milestones.

---

## 🟩 Priority 1: Town Ledger & Satiation (`town_management_design.md`)
*   [x] **Establish Town Center:** Register the `eg_settlers:town_ledger` node.
*   [x] **Granary Inventory:** Design a 4x4 food-only container slot within the Ledger.
*   [x] **Registration Registry (Anti-Lag):** Code a coordinate registration system where Housing Deeds register themselves to their parent Ledger metadata instead of scanning the world.
*   [x] **Satiation Consumption Logic:** Set up a 1200-second timer using `minetest.get_gametime()` timestamp catch-up to calculate missed days and consume granary food when chunks unload.
*   [x] **Food Value Hierarchy:** Implement a multi-layer lookup function (farming registry, `on_use` item definition, generic `group:food` fallback).
*   [x] **Trade Locking:** Edit `npc_behavior.lua` to block trading interfaces if the linked town Ledger is starving.
*   [x] **Mayor Dashboard:** Design the custom status UI showing population, name, and food supply days remaining.

---

## 🟨 Priority 2: Job Board Depot & Quests (`job_board_design.md`)
*   [ ] **Register Job Board:** Create the interactive `eg_settlers:job_board` node.
*   [ ] **Passive Income Depot:** Code daily scans of `Housing Deeds` to deposit resources based on resident professions (e.g., Farmer yields wheat, Miner yields coal).
*   [ ] **Daily Quest Generator:** Design the Bounty Board input/output system with daily item requests matching the town's population.
*   [ ] **Seeker Contracts:** Set up the centralized contract shop to recruit random NPCs.

---

## 🟧 Priority 3: The Roboticist Profession (`job_additions.md`)
*   [X] **Define Trades:** Add the cybernetics trade table to `trades.lua`.
*   [X] **Recruitment Contract:** Register the Roboticist Deed and spawn item in `contracts.lua`.
*   [X] **Entity Spawning:** Register Male/Female skin textures and add them to `spawners.lua`.

---

## 🟦 Priority 4: Player Onboarding & Documentation (`evergrowth_documentation_plan.md`)
*   [ ] **Layer 1 Tooltips:** Expand housing deeds and contract tooltips in `contracts.lua` to highlight the relocation and empty-hand failsafe mechanics.
*   [ ] **Lore Guidebook:** Create the craftable *Settler's Guide* book that opens a custom help/tutorial formspec.
