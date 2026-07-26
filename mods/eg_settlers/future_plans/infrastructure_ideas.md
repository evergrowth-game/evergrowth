# Future Plans & Ideas

## 1. Visual Boundary Markers
The 200-block town radius is currently invisible. Adding an item (e.g., a "Surveyor's Tool") that temporarily highlights the town's N/S/E/W borders using non-colliding, temporary visual entities (similar to Techage's marker cubes) would be a huge quality-of-life improvement for players trying to figure out where they can place deeds, while completely avoiding particle lag.

## 2. Inter-Town Trade Hubs
Introduce a "Trade Post" node that acts as a logistics hub to automatically ship excess items from one town's Depot to another's Granary/Depot. This allows players to build highly specialized settlements (e.g., a massive farming town feeding a distant mining town). To make it feel alive without unloaded-chunk pathfinding issues, the system relies on player-built infrastructure: players must place "Trade Road" markers or "Channel Buoys" leading to the town border. Scheduled shipments will spawn a visual Caravan or Ship entity that safely navigates along the player's custom path to/from the town edge before despawning, giving the illusion of a bustling physical trade network. 

Options:
1. **Player Bulk Logistics**: Automatically transport massive amounts of player loot, building materials, or excess gathered items from one town's Depot to another, saving the player from manual transport trips between distant bases.
2. **Passive Income Generation**: Acts as an export hub to passively convert excess goods (pulled from a dropbox or town depot) into gold lumps that the player receives as taxes.

Note: Textures for caravans and ships can potentially be sourced from the `commoditymarket_fantasy` (CC-BY-SA-3.0) and `fishing_boat` (CC-BY-3.0) mods, provided appropriate attribution is given. Alternatively, Kenney's [Watercraft Kit](https://opengameart.org/content/watercraft-kit) is available under the CC0 (Public Domain) license.
