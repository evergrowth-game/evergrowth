# Evergrowth Villages: Job Board Design Document

The Job Board is an interactive node designed to mechanically justify building large settlements. Instead of complex, lag-inducing NPC AI, the Job Board relies on stable, native Minetest engine features (node timers, formspecs, and inventories) to provide deep gameplay loops.

Below are three modular, highly feasible implementation concepts.

## Concept 1: The "Passive Income" Depot (Resource Generation)
Currently, villagers are static shopkeepers. This concept turns them into a localized automation system.

**Mechanics:**
* The Job Board acts as a chest with an inventory.
* Every in-game morning (via a slow node timer), the Job Board performs a `minetest.find_nodes_in_area` scan in a 100-block radius to find all occupied `Housing Deed` blocks.
* It reads the profession stored in each occupied Deed's metadata.
* It deposits materials into its inventory based on the town's population (e.g., +2 Wheat per Farmer, +1 Wood per Lumberjack, +1 Coal per Miner).

**Why it works:** Gives players a massive mechanical incentive to build large, diverse towns. It requires zero pathfinding or entity ticking.

## Concept 2: The Contract Shop (Centralized Recruitment)
Replaces the current system of crafting Contracts out of random items.

**Mechanics:**
* The Job Board features a shop UI (formspec).
* Once per day, the Board populates with 3-5 randomized "Seekers" looking for a home.
* *Example Listing:* "A Blacksmith is looking for a home. Cost: 5 Gold Ingots."
* The player places the required currency in a payment slot, clicks "Recruit", and the Board dispenses the appropriate Contract.

**Why it works:** It makes town-building feel like managing a community rather than just following a crafting recipe, and provides a continuous sink for the player's late-game wealth.

## Concept 3: The Bounty Board (Infinite Quests)
Provides an infinite loop of localized quests to give players direction.

**Mechanics:**
* The Job Board has an "Input" slot and an "Output" slot.
* The `infotext` (hover-text) above the block displays a daily, randomly generated request tied to the town's current professions.
* *Example Request:* "The local Gunsmith needs 20 Iron Ingots."
* The player places 20 Iron Ingots into the Input slot. The node consumes the items and dispenses a reward (like a high-tier weapon, rare seeds, or a special currency) into the Output slot.

**Why it works:** Solves late-game boredom by giving the player specific, randomly generated goals that fit seamlessly into the world lore.
