# Evergrowth Settlers (`eg_settlers`)

`eg_settlers` is a Minetest mod designed to introduce dynamic NPC settlements, trading, and town management mechanics to the Evergrowth game.

## Features

- **Dynamic NPCs:** Supports multiple professions including Traders, Companions, and Roboticists.
- **Housing Deeds:** Placeable nodes that set an NPC's home coordinate and establish a wander tether.
- **Town Management:** The Town Ledger tracks population and manages the food supply (satiation system) for NPCs within its radius using a centralized database.
- **Trading & Contracts:** Systems for recruiting, relocating, and managing NPCs, alongside defined trade tables.
- **Job Board:** A dynamic request board for fulfilling daily town bounties and recruiting new seekers.
- **NPC Schedules:** Villagers exhibit day/night cycles, returning home to sleep at night and actively looking at/greeting players during the day.
- **Sentinel Ward Stones:** Placeable nodes that deal periodic damage to hostile mobs within a defined radius.

## Documentation

For deep dives into the architectural design and mechanics of specific systems, please refer to the `docs/` directory:

- [Town Management Design](docs/town_management_design.md): Explains the technical implementation of the Town Ledger and the NPC Satiation system, including the global registration pattern.

## Future Plans

The `future_plans/` directory contains templates and roadmaps for upcoming features and a generic template for proposing new job additions.
