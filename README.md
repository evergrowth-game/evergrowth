# Evergrowth

Evergrowth is a custom survival, automation, and settlement-building game for Minetest (Luanti) built on the foundation of Minetest Game. It integrates advanced technology systems, dynamic logistics, specialized NPC communities, and a high-stakes survival loop.

## Core Features

- **Dynamic Settlements (`eg_settlers`)**: Custom-generated villages featuring interactive NPC settlers, specialized trade systems, community structures, and an evolving framework for daily schedules and town ledgers.
- **Industrial Engineering & Automation**: Technical infrastructure powered by the `techage` ecosystem, supporting automation, fluid dynamics, power generation, and advanced processing networks.
- **Advanced Logistics & Vehicles**: Dynamic vehicle physics utilizing the `airutils` and `automobiles_pck` libraries, bringing ground and aerial transport (including fixed-wing aircraft, helicopters, and watercraft) into active play.
- **Extensive World Gen & Biomes**: Multi-faceted exploration spanning custom surface environments via `ethereal` and hazardous subterranean layers driven by `caverealms`.
- **Survival Mechanics**: Comprehensive hunger, thirst, and environmental challenges integrated with HUD bars, armor progression, and cooking/farming systems.

## Repository Structure

The `evergrowth` game is tracked as a single unified monorepo.

- `mods/` - Integrated mod ecosystem containing community packs and custom-developed mods.
  - `eg_settlers/` - The core settlement generation mod (formerly `evergrowth_villages`), fully merged with historical commits preserved.
  - `aircraft_tweaks/`, `automobiles_tweaks/` - Core overrides managing vehicle friction and handling behavior.
- `research/` - Prototyping and reference designs for sub-systems.
- `utils/` - Administrative and maintenance tools.

## Installation & Setup

1. Clone or copy the `evergrowth` directory to your Minetest `games/` folder:
   - **macOS**: `/Users/<user>/Library/Application Support/minetest/games/evergrowth`
   - **Linux**: `~/.minetest/games/evergrowth`
   - **Windows**: `<minetest_install_directory>\games\evergrowth`
2. Launch Minetest (v5.8+ recommended).
3. Create a new world, selecting **Evergrowth** as the target game.
