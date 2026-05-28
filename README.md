# Evergrowth

Evergrowth is a custom survival, automation, and settlement-building game for Minetest (Luanti) built on the foundation of Minetest Game. It integrates advanced technology systems, dynamic logistics, specialized NPC communities, and a high-stakes survival loop.

## Core Features
- **Dynamic Settlements (`eg_settlers`)**: NPC and economy system that allows players to "hire" and trade with specialized settlers (such as guards, farmers, and blacksmiths), with future plans for community management structures, daily schedules, and more.
- **Industry & Automation**: Technology infrastructure powered by the `techage` ecosystem, supporting automation, fluid dynamics, power generation, and advanced processing networks.
- **Transportation**: Dynamic vehicle physics utilizing `airutils` (and its descendents), `automobiles_pck`. and `motorboat`libraries, bringing ground, maritime, and aerial transport. This includes cars, ships, fixed-wing aircraft, helicopters, and submarines into active play.
- **World Gen & Biomes**: Multi-faceted exploration spanning custom surface environments via `ethereal` and subterranean layers through `caverealms`.
- **Survival Mechanics**: Hunger and satiation mechanics integrated with HUD bars, armor progression, a dynamic weather and wind system (`climate`), and expanded cooking and farming ecosystems.

## Repository Structure

The `evergrowth` game is tracked as a single unified monorepo.

- `mods/` - Integrated mod ecosystem containing community packs and custom-developed mods.
  - `eg_settlers/` - The core settlement generation mod (formerly `evergrowth_villages`), fully merged with historical commits preserved.
  - `aircraft_tweaks/`, `automobiles_tweaks/` - Core overrides managing vehicle friction and handling behavior.
- `research/` - Prototyping and reference designs for sub-systems.
- `utils/` - Administrative and maintenance tools.

## Third-Party Dependencies

To guarantee an out-of-the-box playable experience, all external community-developed mods required by Evergrowth are pre-packaged as static snapshots directly inside the `mods/` directory. No global mods or manual installs are required. 

For a complete list of these integrated dependencies, see the [external_mods.md](external_mods.md) directory file.

## Installation & Setup

1. Clone or copy the `evergrowth` directory to your Minetest `games/` folder:
   - **macOS**: `/Users/<user>/Library/Application Support/minetest/games/evergrowth`
   - **Linux**: `~/.minetest/games/evergrowth`
   - **Windows**: `<minetest_install_directory>\games\evergrowth`
2. Launch Minetest (v5.8+ recommended).
3. Create a new world, selecting **Evergrowth** as the target game.
