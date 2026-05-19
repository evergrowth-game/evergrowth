# Job Additions Log

This document serves as the master record for new NPC jobs added to the `evergrowth_villages` mod. It details the required trade tables, visual assets, and contract logic for each new profession.

## Roboticist

The Roboticist serves as a high-tier cybernetics engineer, trading in automated helper droids (Maidroids), programming tools, and advanced materials.

### 1. Attributes & Implementation Details

*   **Profession ID:** `roboticist`
*   **Recruitment Contract Recipe Item:** `maidroid_tool:capture_rod`
*   **Required Textures:** 
    *   Male: `male_roboticist.png`
    *   Female: `female_roboticist.png`
*   **Files Required for Implementation:**
    *   `trades.lua`: Add the Trade Table to `evergrowth_villages.trades_list`
    *   `spawners.lua`: Add texture definitions to `profession_textures` inside `spawn_trader()`
    *   `contracts.lua`: Call `register_contract("roboticist", "roboticist", "maidroid_tool:capture_rod", "Roboticist's Contract")`

### 2. Trade Table Definition

Below is the verified trade list for the Roboticist, adhering to the standard `{"item count", "price count", chance}` format.

**NPC Sells (Player provides gold, receives technology):**
*   `{"default:gold_lump 40", "maidroid:maidroid_egg 1", 100}` *(High-value droid activator)*
*   `{"default:gold_lump 20", "maidroid_tool:capture_rod 1", 100}` *(Android control rod)*
*   `{"default:gold_lump 5", "maidroid_tool:nametag 1", 100}` *(Android tracking tag)*

**NPC Buys (Player provides items, receives gold):**
*   `{"default:bronzeblock 1", "default:gold_lump 8", 100}` *(Bronze blocks for chassis)*
*   `{"default:coalblock 2", "default:gold_lump 6", 100}` *(Graphite casings)*
*   `{"default:mese 1", "default:gold_lump 4", 100}` *(Mese processors)*
