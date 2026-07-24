# Modular Game-Wide Documentation Plan

This document outlines the architecture for a modular, game-wide documentation system. It separates the global UI engine from the actual lore and text, allowing documentation for both custom and third-party mods.

## 1. The Core UI Engine

Wuzzy's documentation mods (`doc`, `doc_basics`, and `doc_items`) will serve as the global UI engine.
*   **Automation:** `doc_items` automatically parses the game's registry to generate documentation for all standard blocks, tools, and crafting recipes.
*   **UI Integration:** The `doc` mod natively handles state management, adds an inventory button, and provides a searchable encyclopedia formspec.
*   **Custom Entries:** Custom `doc.add_category()` and `doc.add_entry()` calls will be utilized exclusively for complex, non-standard mechanics that cannot be automatically parsed.

## 2. Physical Item Integration
To support players who prefer immersive physical items, both `guidebooks` and `doc_encyclopedia` will be supported as optional dependencies.
*   **Encyclopedia (`doc_encyclopedia`):** If installed, this mod provides a single craftable "Encyclopedia" item that acts as a physical gateway to the master global UI, allowing access to the entire game's documentation.
*   **Settler's Guide (`guidebooks`):** If `guidebooks` is detected, `eg_settlers` will register a dedicated, craftable `eg_settlers:settlers_guide` item. The exact same text drafted for the `doc` registry will be reused to populate this standalone book, providing a focused manual just for settlements.

## 3. Handling Third-Party Mod Documentation

To avoid modifying other people's work (which makes updating those mods very difficult), a dedicated content mod will be created: `eg_third_party_docs`.
*   This mod will act purely as a text repository.
*   It will detect if a specific third-party mod is loaded (e.g., `if minetest.get_modpath("farming") then`), and if so, it will inject custom documentation entries for that mod into the central UI registry.
*   This ensures zero coupling and leaves the original third-party mod directories completely untouched.

## 4. Targeted Mods for Documentation

The following large, intricate, or high-touch mods have been identified as primary candidates for documentation via `eg_third_party_docs`:
1.  **Farming Redo (`farming`):** Crops, soil requirements, and advanced food recipes.
2.  **Mobs Redo (`mobs_animal`, `mobs_monster`):** Breeding mechanics, taming, and mob drops.
3.  **Vehicles & Transport (`airutils`, `automobiles_pck`, `nautilus`, `supercub`):** Controls, fueling, and vehicle physics.
4.  **Magic & Enchanting (`magic_materials`, `x_enchanting`, `mana`):** How to gather magic materials and use the enchanting table.
5.  **Techage (`techage_modpack`):** Techage already heavily utilizes `doclib`. A bridge script will be written to link Techage's existing manuals into the `doc` UI.

## 5. Evergrowth Settlements Content Draft (`mods/eg_settlers/docs/guide_content.lua`)

The exact text strings to be injected into the registry for the `eg_settlers` mod. The term "Evergrowth Settlements" is now used throughout.

### Chapter 1: Introduction to Settlements
*   **Text:** "Welcome to Evergrowth Settlements. This guide will teach you how to build a thriving, self-sustaining settlement. You will manage resources, recruit specialized villagers, and protect your town from external threats."

### Chapter 2: The Town Ledger & Granary
*   **Text:** "The Town Ledger (`eg_settlers:town_ledger`) is the heart of your settlement. It tracks your total population and the village's food supply. \n\nDirectly inside the Ledger is a 4x4 Granary. Villagers consume food over time. If the Granary runs out of food, your town will begin to starve. Starving villagers suffer poor morale and will refuse to trade with you until the Granary is restocked."

### Chapter 3: Housing Deeds & Tethers
*   **Text:** "Housing Deeds (`eg_settlers:housing_deed`) act as tethers for your villagers. Once a deed is placed, you must use a Contract on it to assign a resident. \n\nVillagers follow a strict day/night schedule. During the day, they will wander the town. At night, they will return to their deed to sleep. \n\n**Failsafe:** If a villager is killed or goes missing, you can retrieve their contract by Sneak+Right-Clicking their housing deed with an empty hand."

### Chapter 4: Contracts, Professions & Wardrobes
*   **Text:** "Villagers are recruited using Contracts. Different contracts provide different professions, such as Farmers, Miners, and Roboticists, each offering unique trade tables.\n\n**Relocation:** You can pick up a living villager and move them by using a Relocation Contract on them.\n\n**Customization:** If you want to change a villager's appearance, punch them while holding the Wardrobe Wand (`eg_settlers:wardrobe_wand`)."

### Chapter 5: Job Board & Passive Income
*   **Text:** "The Job Board (`eg_settlers:job_board`) offers daily quests for rare rewards. \n\nAdditionally, your villagers generate passive income based on their professions. A Farmer will produce crops, while a Miner produces ores. These resources are automatically deposited into the Town Depot (`eg_settlers:town_depot`) every in-game day. Check the Depot regularly to claim your town's production!"

### Chapter 6: Town Defenses
*   **Text:** "The Sentinel Ward Stone (`eg_settlers:ward_stone`) is a crucial defense mechanism. Once placed, it will automatically detect and deal 10 damage to any hostile monsters within a 15-block radius, helping to keep your villagers safe."
