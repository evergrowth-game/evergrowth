# Evergrowth Villages: Prioritized Todo List

This document acts as the active roadmap and master task checklist for development milestones.

---

## 🟩 Priority 1: Town Ledger & Satiation (`town_management_design.md`)
*   [ ] **Establish Town Center:** Register the `evergrowth_villages:town_ledger` node.
*   [ ] **Granary Inventory:** Design a 4x4 food-only container slot within the Ledger.
*   [ ] **Registration Registry (Anti-Lag):** Code a coordinate registration system where Housing Deeds register themselves to their parent Ledger metadata instead of scanning the world.
*   [ ] **Satiation Consumption Logic:** Set up a 1200-second timer using `minetest.get_gametime()` timestamp catch-up to calculate missed days and consume granary food when chunks unload.
*   [ ] **Food Value Hierarchy:** Implement a multi-layer lookup function (farming registry, `on_use` item definition, generic `group:food` fallback).
*   [ ] **Trade Locking:** Edit `npc_behavior.lua` to block trading interfaces if the linked town Ledger is starving.
*   [ ] **Mayor Dashboard:** Design the custom status UI showing population, name, and food supply days remaining.

---

## 🟨 Priority 2: Job Board Depot & Quests (`job_board_design.md`)
*   [ ] **Register Job Board:** Create the interactive `evergrowth_villages:job_board` node.
*   [ ] **Passive Income Depot:** Code daily scans of `Housing Deeds` to deposit resources based on resident professions (e.g., Farmer yields wheat, Miner yields coal).
*   [ ] **Daily Quest Generator:** Design the Bounty Board input/output system with daily item requests matching the town's population.
*   [ ] **Seeker Contracts:** Set up the centralized contract shop to recruit random NPCs.

---

## 🟧 Priority 3: The Roboticist Profession (`job_additions.md`)
*   [ ] **Define Trades:** Add the cybernetics trade table to `trades.lua`.
*   [ ] **Recruitment Contract:** Register the Roboticist Deed and spawn item in `contracts.lua`.
*   [ ] **Entity Spawning:** Register Male/Female skin textures and add them to `spawners.lua`.

---

## 🟦 Priority 4: Player Onboarding & Documentation (`evergrowth_documentation_plan.md`)
*   [ ] **Layer 1 Tooltips:** Expand housing deeds and contract tooltips in `contracts.lua` to highlight the relocation and empty-hand failsafe mechanics.
*   [ ] **Lore Guidebook:** Create the craftable *Settler's Guide* book that opens a custom help/tutorial formspec.
