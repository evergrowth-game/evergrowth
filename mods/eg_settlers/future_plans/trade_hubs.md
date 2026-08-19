# Inter-Town Trade Hubs & Logistics

Introduce a "Trade Post" node that acts as a logistics hub to automatically ship excess items from one town's Depot to another's Granary/Depot. This allows players to build highly specialized settlements (e.g., a massive farming town feeding a distant mining town). To make it feel alive without unloaded-chunk pathfinding issues, the system relies on player-built infrastructure: players must place "Trade Road" markers or "Channel Buoys" leading to the town border. Scheduled shipments will spawn a visual Caravan or Ship entity that safely navigates along the player's custom path to/from the town edge before despawning, giving the illusion of a bustling physical trade network. 

Options:
1. **Player Bulk Logistics**: Automatically transport massive amounts of player loot, building materials, or excess gathered items from one town's Depot to another, saving the player from manual transport trips between distant bases.
2. **Passive Income Generation**: Acts as an export hub to passively convert excess goods (pulled from a dropbox or town depot) into gold lumps that the player receives as taxes.

### Physical Node & Interaction Design
1. **Multi-block Structure (Capacity)**: Instead of a single magic block, the Trade Post requires a modular build. The central "Trade Desk" node manages the routes, but its daily shipping volume is determined by how many physical "Cargo Crate" nodes the player builds around it.
2. **Visual State Changes**: The Trade Post node dynamically updates its mesh/texture based on its status—appearing empty when idle, stacked with crates when goods are queued, and flying a red lantern if the trade route is invalid or blocked.
3. **Static Dockmaster Ledger**: Instead of a wandering NPC that players might have to chase down, the interaction point is a static, non-moving "Dockmaster's Ledger" or "Shipping Manifest" node. This provides a reliable, permanent formspec access point for managing routes without the overhead of tracking entity positions or needing new NPC textures.
4. **Containerized Cargo Loading**: To export items, players could physically pack items into individual "Shipping Crate" nodes. Once filled, players place these crates onto a designated "Loading Bay" platform. When the scheduled transport vehicle (caravan/ship) departs, the physical crate nodes are removed from the bay and visually loaded onto the vehicle, making the logistics process tangible.

### Additional Gameplay Considerations
**Multiplayer Permissions**: Currently, `eg_settlers` ledgers do not natively record a "Mayor" or "Owner" player. If a Trade Post is implemented, the core `town_ledger.lua` and `settlement_db.lua` would need a refactor to record the `player_name` of whoever founded the town. This would allow the Trade Desk to restrict route changes and loading bay access to authorized players, preventing griefing or theft on multiplayer servers.

Note: Textures for caravans and ships can potentially be sourced from the `commoditymarket_fantasy` (CC-BY-SA-3.0) and `fishing_boat` (CC-BY-3.0) mods, provided appropriate attribution is given. Alternatively, Kenney's [Watercraft Kit](https://opengameart.org/content/watercraft-kit) is available under the CC0 (Public Domain) license, and provides numerous watercraft models and textures, as well as shipping containers. (Design Note: For a dynamic, modular visual system, use the empty-deck `ship-cargo-c.obj` as the base entity and dynamically attach individual `cargo-container-*.obj` entities to it using `set_attach()` to visually represent current cargo load).
