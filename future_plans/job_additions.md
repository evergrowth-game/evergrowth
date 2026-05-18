# Job Additions Log

This document serves as the master record for new NPC jobs added to the `evergrowth_villages` mod. It details the required trade tables, visual assets, and contract logic for each new profession.

## Fisher

The Fisher acts as a convenience vendor for players who prefer not to engage in the fishing minigame, selling raw aquatic resources and buying scavenging materials.

### 1. Attributes & Implementation Details

*   **Profession ID:** `fisher`
*   **Recruitment Contract Recipe Item:** `ethereal:fishing_rod`
*   **Required Textures:** 
    *   Male: `male_fisher.png`
    *   Female: `female_fisher.png`
*   **Files Required for Implementation:**
    *   `trades.lua`: Add the Trade Table to `evergrowth_villages.trades_list`
    *   `spawners.lua`: Add texture definitions to `profession_textures` inside `spawn_trader()`
    *   `contracts.lua`: Call `register_contract("fisher", "fisher", "ethereal:fishing_rod", "Fisher's Contract")`

### 2. Trade Table Definition

Below is the verified trade list for the Fisher, adhering to the standard `{"item count", "price count", chance}` format.

**NPC Sells (Player provides gold, receives ingredients):**
*   `{"default:gold_lump 1", "ethereal:fish_salmon 2", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_cod 2", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_tuna 2", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_trout 2", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_bluefin 2", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_mackerel 2", 100}`
*   `{"default:gold_lump 2", "ethereal:fish_shrimp 5", 100}`
*   `{"default:gold_lump 2", "ethereal:fish_squid 2", 100}`
*   `{"default:gold_lump 2", "ethereal:fish_pufferfish 1", 100}`
*   `{"default:gold_lump 2", "ethereal:fish_clownfish 1", 100}`
*   `{"default:gold_lump 1", "ethereal:fish_jellyfish 1", 100}`

**NPC Buys (Player provides items, receives gold):**
*   `{"farming:string 20", "default:gold_lump 1", 100}`
*   `{"default:stick 30", "default:gold_lump 1", 100}`
*   `{"default:clay_lump 20", "default:gold_lump 1", 100}`
*   `{"default:sand 30", "default:gold_lump 1", 100}`
*   `{"default:coral_brown 10", "default:gold_lump 1", 100}`
*   `{"default:coral_orange 10", "default:gold_lump 1", 100}`
