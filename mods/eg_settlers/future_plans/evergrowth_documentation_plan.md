# Evergrowth Player Onboarding & Documentation Plan

This document outlines options for introducing players to the complex mechanics of the Evergrowth and Evergrowth Villages mods directly within the Minetest engine, without requiring external wikis or browser tabs.

## The Three-Layer Approach

Minetest players typically interact with the world through trial and error, relying heavily on the crafting guide. To effectively teach mechanics without breaking immersion, information should be tiered from immediate context clues down to deep reference material.

### Layer 1: Diegetic Clues (Immediate Interaction)
**Goal:** Show players what to do *at the exact moment they need to do it*.
**Status:** Partially implemented.
**Action Items:**
*   **Enhance Item Descriptions:** Update `contracts.lua` to expand the tooltip on all contracts. 
    *   *Current:* "Use on a Housing Deed to assign a resident."
    *   *Proposed addition:* "Sneak+Right-Click an assigned villager to relocate them."
*   **Enhance Infotext:** Ensure all interactive nodes have clear hover-text.
    *   *Current:* The Housing Deed clearly states "(Vacant) - Use a Contract here". This is perfect.
*   **Chat Feedback:** Maintain the contextual chat messages (e.g., "Resident is alive. Use a Relocation Contract to move them.") as immediate error-handling guidance.

### Layer 2: In-Game Reference (Deep Learning)
**Goal:** Provide a central repository of knowledge that players can browse on-demand.
**Proposed Solution:** Integrate the community-standard `doc` modpack (`doc_basics`, `doc_items`).
**Action Items:**
*   **Dependency:** Add `doc` to `depends.txt` (as an optional dependency `doc?`).
*   **Code Integration:** Write a Lua script (`documentation.lua`) that detects if the `doc` mod is running, and if so, injects detailed encyclopedia entries into the help menu.
*   **Content Needed:**
    *   *Housing Deed Entry:* Explain that deeds act as tethers, detail the day/night sleeping behaviors, and explicitly explain the "empty-hand right-click" failsafe for dead villagers.
    *   *Contracts Entry:* Explain the different professions, trade tables, and the relocation mechanics.
    *   *General "Settlements" Category:* A high-level guide on how to build a thriving village from scratch.

### Layer 3: Breadcrumbs (Guided Progression)
**Goal:** Subtly suggest goals to the player so they know the mechanics actually exist to be discovered.
**Proposed Solution:** Integrate the `awards` (Achievements) mod.
**Action Items:**
*   Create a custom "Evergrowth Villages" achievement tree that acts as a hidden tutorial.
*   **Suggested Achievements:**
    *   *Foundation:* Craft your first Housing Deed.
    *   *The Bureaucrat:* Craft your first Villager Contract.
    *   *Welcome to the Neighborhood:* Successfully assign a villager to a deed.
    *   *Moving Day:* Safely pick up a resident using a Relocation Contract.

---

## Implementation Paths

### Option A: The "Vanilla" Route (No extra dependencies)
*   Rely entirely on Layer 1 (Tooltips, Infotext, Chat). 
*   **Pros:** Keeps the mod entirely standalone and lightweight.
*   **Cons:** Players might struggle to discover advanced mechanics (like Relocation or the Empty-Hand Failsafe) unless they accidentally stumble upon them.

### Option B: The "Lore" Route (In-game Books)
*   Add a craftable "Settler's Guide" book that opens a custom text-heavy formspec. Give it to players when they spawn.
*   **Pros:** Highly immersive, fits a roleplay server well.
*   **Cons:** Players easily lose the book or bury it in a chest. Static text is harder to search through than an indexed menu.

### Option C: The "Encyclopedia" Route (Recommended)
*   Implement Layer 1 tweaks, and fully integrate Layer 2 (`doc` modpack).
*   **Pros:** This is the gold standard for complex Minetest mods (e.g., Technic, MineClone2). It is easily accessible at all times via a button in the player's inventory menu and automatically indexes your custom items.
*   **Cons:** Requires adding the `doc` modpack to your server/game configuration.
