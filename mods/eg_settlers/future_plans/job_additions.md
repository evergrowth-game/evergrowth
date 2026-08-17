# Job Additions Template

This document serves as the master template for proposing new NPC jobs for the `eg_settlers` mod. It details the required trade tables, visual assets, and contract logic for each new profession.

## [Profession Name]

[Brief description of the profession, what role they serve in the village, and what kinds of items they trade.]

### 1. Attributes & Implementation Details

*   **Profession ID:** `[profession_id]` (e.g., lowercase, no spaces)
*   **Recruitment Contract Recipe Item:** `[mod_name:item_name]` (The item used to craft the contract)
*   **Required Textures:** 
    *   Male: `male_[profession_id].png`
    *   Female: `female_[profession_id].png`
*   **Files Required for Implementation:**
    *   `trades.lua`: Add the Trade Table to `eg_settlers.trades_list`
    *   `spawners.lua`: Add texture definitions to `profession_textures` inside `spawn_trader()`
    *   `contracts.lua`: Call `register_contract("[profession_id]", "[profession_id]", "[mod_name:item_name]", "[Profession Name]'s Contract")`

### 2. Trade Table Definition

Below is the proposed trade list for the [Profession Name], adhering to the standard `{"item count", "price count", chance}` format.

**NPC Sells (Player provides currency, receives items):**
*   `{"[received_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*
*   `{"[received_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*
*   `{"[received_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*

**NPC Buys (Player provides items, receives currency):**
*   `{"[provided_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*
*   `{"[provided_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*
*   `{"[provided_item count]", "[currency_item count]", [chance]}` *([Item description/purpose])*

---

## Armorer

Crafts, fits, and repairs wearable armor suits, shields, and protective equipment. Specializes in converting refined metal ingots and treated leather into defensive gear for villagers and players.

### 1. Attributes & Implementation Details

*   **Profession ID:** `armorer`
*   **Workstation Job Block:** `eg_settlers:job_block_armorer` (Armorer's Fitting Rack, Cost: 12 Gold)
*   **Recruitment Contract Recipe Item:** `3d_armor:chestplate_steel` (or `eg_settlers:hiring_contract` via Job Board)
*   **Required Textures:**
    *   Male: `male_armorer.png`
    *   Female: `female_armorer.png`
*   **Environmental Requirement:** Requires at least 1 anvil (`group:anvil`) or furnace (`default:furnace`, `default:furnace_active`) within 4 blocks.
*   **Files Required for Implementation:**
    *   `town/job_blocks.lua`: Register `job_block_armorer` with workstation mesh/tiles and cost.
    *   `api/settlement.lua`: Add environmental validation check in `validate_job_block_environment()`.
    *   `npc/trades.lua`: Add the Trade Table to `eg_settlers.trades_list.armorer`.
    *   `npc/spawners.lua`: Add texture definitions to `profession_textures` inside `spawn_trader()`.
    *   `docs/guide_content.lua`: Update documentation and guide entries.

### 2. Trade Table Definition

**NPC Sells (Player provides gold, receives armor):**
*   `{"default:gold_lump 3", "3d_armor:helmet_steel 1", 100}` *(Steel Helmet)*
*   `{"default:gold_lump 5", "3d_armor:chestplate_steel 1", 100}` *(Steel Chestplate)*
*   `{"default:gold_lump 4", "3d_armor:leggings_steel 1", 100}` *(Steel Leggings)*
*   `{"default:gold_lump 2", "3d_armor:boots_steel 1", 100}` *(Steel Boots)*
*   `{"default:gold_lump 4", "3d_armor:shield_steel 1", 100}` *(Steel Shield)*
*   `{"default:gold_lump 3", "3d_armor:chestplate_bronze 1", 100}` *(Bronze Chestplate)*
*   `{"default:gold_lump 2", "3d_armor:shield_bronze 1", 100}` *(Bronze Shield)*
*   `{"default:gold_lump 10", "3d_armor:chestplate_diamond 1", 50}` *(Diamond Chestplate)*

**NPC Buys (Player provides materials, receives gold):**
*   `{"default:steel_ingot 10", "default:gold_lump 6", 100}` *(Steel Ingots)*
*   `{"default:bronze_ingot 10", "default:gold_lump 4", 100}` *(Bronze Ingots)*
*   `{"mobs:leather 8", "default:gold_lump 2", 100}` *(Treated Leather)*
*   `{"default:copper_ingot 12", "default:gold_lump 3", 100}` *(Copper Ingots)*

---

## Cook

Prepares, bakes, and trades gourmet meals, soups, and hearty rations. Converts raw agricultural crops and livestock meats into high-nutrition foodstuffs providing enhanced saturation and health recovery.

### 1. Attributes & Implementation Details

*   **Profession ID:** `cook`
*   **Workstation Job Block:** `eg_settlers:job_block_cook` (Chef's Prep Station, Cost: 8 Gold)
*   **Recruitment Contract Recipe Item:** `farming:bread` (or `eg_settlers:hiring_contract` via Job Board)
*   **Required Textures:**
    *   Male: `male_cook.png`
    *   Female: `female_cook.png`
*   **Environmental Requirement:** Requires at least 1 stove/campfire (`group:campfire`, `default:furnace`, `default:furnace_active`) and 1 vessel/pot node within 3 blocks.
*   **Files Required for Implementation:**
    *   `town/job_blocks.lua`: Register `job_block_cook` with workstation mesh/tiles and cost.
    *   `api/settlement.lua`: Add environmental validation check in `validate_job_block_environment()`.
    *   `npc/trades.lua`: Add the Trade Table to `eg_settlers.trades_list.cook`.
    *   `npc/spawners.lua`: Add texture definitions to `profession_textures` inside `spawn_trader()`.
    *   `docs/guide_content.lua`: Update documentation and guide entries.

### 2. Trade Table Definition

**NPC Sells (Player provides gold, receives cooked food):**
*   `{"default:gold_lump 1", "farming:bread 6", 100}` *(Fresh Bread)*
*   `{"default:gold_lump 1", "farming:tomato_soup 3", 100}` *(Warm Tomato Soup)*
*   `{"default:gold_lump 2", "farming:burger 3", 100}` *(Hearty Burger)*
*   `{"default:gold_lump 2", "farming:spaghetti 2", 100}` *(Spaghetti Pasta)*
*   `{"default:gold_lump 2", "farming:apple_pie 2", 100}` *(Baked Apple Pie)*
*   `{"default:gold_lump 2", "farming:paella 2", 100}` *(Seafood Paella)*
*   `{"default:gold_lump 3", "farming:bibimbap 2", 100}` *(Gourmet Bibimbap Platter)*
*   `{"default:gold_lump 1", "cheese:cheese_slice 5", 100}` *(Aged Cheese Slices)*

**NPC Buys (Player provides raw ingredients, receives gold):**
*   `{"farming:flour 10", "default:gold_lump 1", 100}` *(Flour)*
*   `{"farming:garlic 15", "default:gold_lump 1", 100}` *(Garlic Bulbs)*
*   `{"mobs:meat_raw 5", "default:gold_lump 2", 100}` *(Raw Beef / Meat)*
*   `{"mobs:chicken_raw 6", "default:gold_lump 2", 100}` *(Raw Poultry)*
*   `{"mobs:egg 8", "default:gold_lump 1", 100}` *(Fresh Eggs)*
*   `{"mobs:bucket_milk 1", "default:gold_lump 1", 100}` *(Whole Milk Bucket)*
