# Evergrowth

![Evergrowth Screenshot](screenshot.png)

Evergrowth is an open-ended sandbox game for Minetest (Luanti) built on the foundation of Minetest Game. Set across diverse biomes and deep caverns, it places no limits on your ambition. Players can wander ancient ruins and fight hostile plunderers, collect and cultivate a wide variety of crops, establish towns and trade with hired NPC specialists, craft magical items of great power, build resource extraction and automation networks, or bypass the terrain entirely using ground, maritime, and aerial vehicles.

## Core Features
- **Dynamic Settlements (`eg_settlers`)**: NPC and economy system that allows players to "hire" and trade with specialized settlers (such as guards, farmers, and blacksmiths), with future plans for community management structures, daily schedules, and more.
- **Industry & Automation**: Technology infrastructure powered by the `techage` ecosystem, supporting automation, fluid dynamics, power generation, and advanced processing networks.
- **Transportation**: Dynamic vehicle physics utilizing `airutils` (and its descendents), `automobiles_pck`, and `motorboat` libraries, bringing ground, maritime, and aerial transport. This includes cars, ships, fixed-wing aircraft, helicopters, and submarines into active play.
- **World Gen & Biomes**: Multi-faceted exploration spanning custom surface environments via `ethereal` and subterranean layers through `caverealms`.
- **Survival Mechanics**: Hunger and satiation mechanics integrated with HUD bars, armor progression, a dynamic weather and wind system (`climate`), and expanded cooking and farming ecosystems.
- **Combat & Hostile Mobs**: Defensive equipment and weapons from `bweapons_modpack`, item enchantment from `x_enchanting`, hostile NPCs from `raiders`, and natural predators from `mobs_water`.

## Repository Structure

- `mods/` - Integrated mod ecosystem containing community packs, MTG foundation mods, and custom-developed game modules:
  - `eg_settlers/` - Village generation, NPC hiring, trade economy, settlement census, and civic schedules.
  - `eg_companions/` - Domestic companion NPCs, plaque/bed dual-tethering, and relocation contracts.
  - `eg_constructs/` - Clay Golem and Combat Drone allies for expeditions, raiding, and hauling.
  - `eg_third_party_docs/` - Centralized in-game documentation and encyclopedia entries for third-party systems.
  - `*_tweaks/` - Engine overrides and custom integration layers for community mods (e.g., `aircraft_tweaks`, `automobiles_tweaks`, `bweapons_tweaks`, `climate_tweaks`, `dungeon_tweaks`, `mobs_animal_tweaks`, `techage_tweaks`, `walls_tweaks`, etc.).
- `evergrowth.sh` - Management and deployment script for quick deployment, launching, and map rendering.
- `menu/` - Main menu assets and configuration.
- `research/` - Prototyping and reference designs for game sub-systems.
- `utils/` - Maintenance tools, texture generators (`generate_human_texture.py`, `generate_automaton_texture.py`, `recolor.py`), mod upstream inspector/updater (`update_external_mods.sh`), texture optimizer (`optimize_textures.sh`), and automated test harness (`utils/test/run.sh`).

## Integrated Community Mods

Evergrowth is built on the foundation of Minetest Game (MTG) and utilizes a carefully curated selection of 80 integrated community mods to provide rich features (such as vehicle systems, machinery, biomes, and magic) without rebuilding those complex engines from scratch.

These mods are pre-packaged directly in the `mods/` directory for three critical reasons:
1. **Out-of-the-Box Playability**: Players and server hosts do not need to hunt down, download, or configure 80 separate external mods. The game is fully complete and playable immediately upon installation.
2. **Stability & Version Control**: Community mods evolve independently and updates can introduce breaking conflicts. Statically snapshotting these specific versions guarantees that all integrated systems remain locked at tested, compatible, and stable states.
3. **Custom Integration & Optimization**: Many of these mods have been custom-tweaked via `*_tweaks` layers to ensure thematic compatibility, resolved dependencies, and clean performance.

The complete list of these integrated community dependencies is documented in [external_mods.md](external_mods.md).

## Management CLI (`evergrowth.sh`)

The included `evergrowth.sh` helper script streamlines common development, playing, and mod inspection tasks:

```bash
# Deploy a Git ref (branch or tag) to the local Luanti game directory (default: dev)
./evergrowth.sh deploy [REF]

# Deploy main (stable) to Luanti and launch the game
./evergrowth.sh play

# Render a 2D map of a world using minetestmapper (default output: ~/Desktop)
./evergrowth.sh map [WORLD] [OUTPUT_PATH]

# List all tracked external community mods and divergence status
./evergrowth.sh mod list

# Inspect high-level feature change summary (commits & file stats) against upstream
./evergrowth.sh mod diff <mod_name>

# Inspect full line-by-line diff against upstream
./evergrowth.sh mod diff <mod_name> --detailed

# Sync a non-diverged external mod from upstream HEAD
./evergrowth.sh mod sync <mod_name>
```

## Installation & Setup

1. Clone or copy the `evergrowth` directory to your Minetest / Luanti `games/` folder:
   - **macOS**: `~/Library/Application Support/minetest/games/evergrowth`
   - **Linux**: `~/.minetest/games/evergrowth`
   - **Windows**: `<minetest_install_directory>\games\evergrowth`
2. Launch Minetest / Luanti (v5.8+ recommended).
3. Create a new world, selecting **Evergrowth** as the target game.
