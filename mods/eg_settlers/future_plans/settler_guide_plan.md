# Settler's Guide Book Implementation Plan

This document outlines the technical approach for implementing the "Lore Guidebook" (`Settler's Guide`), fulfilling the final item on the Priority 4 roadmap.

## User Review Required

Please review the proposed chapters and content breakdown for the guide to ensure it covers all the necessary mechanics from the Evergrowth Villages mod.

## Open Questions

1. **Starting Inventory:** The documentation plan suggests giving this book to players when they first spawn. Should we implement an `on_joinplayer` callback to give new players this item automatically, or just rely on the crafting recipe?
2. **Crafting Recipe:** What materials should be required to craft the book? (e.g., 1 Book + 1 Default Wood, or just 1 Book?)
3. **Formspec Layout:** I'm planning to use a tabbed interface or "Next/Previous" buttons for navigation. A tabbed interface might be easier to jump directly to specific mechanics. Does a tabbed interface sound good?

## Proposed Changes

### Documentation Content
The book will need to cover all the recently added features from the mod, broken down into manageable sections/tabs:
1. **Introduction:** High-level overview of building a village and progression.
2. **Town Ledger & Defenses:** Explaining the town center, Granary, food satiation, and the Sentinel Ward Stone (monster defense).
3. **Housing Deeds:** How deeds act as tethers, the day/night sleeping schedule, and the failsafe for retrieving contracts (right-clicking with an empty hand if a villager dies).
4. **Villagers & Contracts:** How to assign contracts, the different professions (including Roboticist), relocation contracts, and using the Wardrobe Wand to change outfits.
5. **Job Board:** Explaining passive resource income via the depot, daily quests, and Seeker Contracts.

### Code Implementation (New File: `tools/guidebook.lua`)

#### [NEW] `tools/guidebook.lua`
*   **Item Registration:** Register `eg_settlers:settlers_guide` craftitem with a book texture.
*   **Crafting Recipe:** Standard 2-item shapeless recipe.
*   **Formspec Generation:**
    *   Create a function `eg_settlers.get_guidebook_formspec(player_name, current_tab)` to generate the UI dynamically.
    *   Use a `tabheader` element for easy navigation between the 5 topics.
    *   Use `textarea` or `hypertext` (if Minetest version allows) for displaying the formatted text content.
*   **`on_use` Callback:** When right-clicked, call `minetest.show_formspec("eg_settlers:guidebook", eg_settlers.get_guidebook_formspec(name, 1))` to open the book on the first tab.
*   **Formspec Callback:** Register `minetest.register_on_player_receive_fields` to listen for tab changes and update the UI accordingly.

### Code Implementation (Modifying `init.lua`)

#### [MODIFY] `init.lua`
*   Add `dofile(minetest.get_modpath("eg_settlers") .. "/tools/guidebook.lua")` to initialize the book.

## Verification Plan

### Manual Verification
1. Launch the Minetest world.
2. Craft the `eg_settlers:settlers_guide` item.
3. Right-click with the book to open the formspec.
4. Verify that all tabs load correctly and content is legible without overflowing the screen.
5. Verify that all mentioned mechanics (Housing, Ledger, Job Board, etc.) are accurately described based on the current codebase.
