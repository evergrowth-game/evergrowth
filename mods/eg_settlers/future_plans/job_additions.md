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
