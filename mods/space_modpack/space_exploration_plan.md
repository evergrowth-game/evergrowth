# Space Exploration & Spacecraft Integration Plan

This technical specification details the architecture, file structure, Lua API hooks, node registrations, and roadmap for outer space biomes, asteroid fields, life support mechanics, starship propulsion, and deep-space orbital gameplay in Evergrowth.

---

## 1. Directory Structure & Upstream Isolation Policy

Third-party mods remain 100% unmodified in `mods/space_modpack/<mod_name>/`. All integration logic, custom nodes, overrides, and recipes reside in dedicated `mods/space_modpack/*_tweaks/` layers.

```
mods/space_modpack/
├── modpack.conf
├── modpack.txt
├── other_worlds/
├── other_worlds_tweaks/
│   ├── mod.conf
│   ├── init.lua
│   ├── nodes.lua                  (Rich ores, comet ice, cosmic crystals)
│   ├── asteroid_mapgen.lua        (Multi-mineral asteroid generator, sunlight propagation)
│   ├── gravity.lua                (player_monoids gravity scaling 0.35x at Y >= 1000)
│   ├── climate_hook.lua           (Suppresses wind/rain and merges space skyboxes)
│   ├── solar_hook.lua             (24/7 continuous orbital solar generation & efficiency scaling)
│   └── electrolyzer_hook.lua      (Water feedstock integration, dual-port isolation & orbital ISRU)
├── vacuum/
├── vacuum_tweaks/
│   ├── mod.conf
│   └── init.lua                   (eg_constructs drone/golem immunity rules)
├── spacesuit/
├── spacesuit_tweaks/
│   ├── mod.conf
│   ├── init.lua                   (Suit airtanks breathing integration)
│   ├── crafts.lua                 (Techage composite fiber & glass recipes)
│   └── eva_thruster.lua           (Handheld EVA RCS Thruster with dynamic gravity vectoring)
├── jumpdrive/
└── jumpdrive_tweaks/
    ├── mod.conf
    ├── init.lua
    ├── formspec.lua               (Flight deck telemetry, coordinates, and navigation UI)
    ├── nodes_fuel.lua             (jumpdrive_tweaks:fuel_tank & fuel_port)
    ├── ice_melter.lua             (Starship Thermal Ice Melter & liquefier node)
    ├── crafts.lua                 (Fuel tanks, ports, ice melter, beacons, and tether recipes)
    ├── terrain_filter.lua         (Planetary terrain and flora jump blacklist)
    ├── beacon.lua                 (Ship Transponder Beacon & Quantum Recall Tether)
    ├── techage_pipe.lua           (Techage Liquid Network registration & pump hooks)
    ├── validator.lua              (Single-click uncharted sector emergence & fuel checks)
    └── decouple.lua               (Safe dockside pipe disconnection on jump)
```

---

## 2. Completed Implementations [DONE]

### 2.1 High-Altitude Worldgen & Resources (`other_worlds` & `other_worlds_tweaks`) [DONE]
* **Asteroid Generator (`asteroid_mapgen.lua`):** Balanced 1-in-6 ore distribution featuring Diamond, Mese Crystals, Gold, Egerum, Februm, Copper, Tin, Iron, Coal, and Comet Ice.
* **Lighting Fix:** Added `sunlight_propagates = true` on asteroid nodes to eliminate phantom surface shadows beneath asteroid clusters.
* **Atmosphere & Skybox (`climate_hook.lua`):** Merged space skyboxes with `climate_api.skybox` and suppressed terrestrial weather (rain, wind, storm clouds) in orbit.
* **Low Gravity (`gravity.lua`):** Integrated with `player_monoids.gravity` to establish low orbital gravity ($0.35\times$) at $Y \ge 1,000$.

### 2.2 Life Support & Entity Rules (`vacuum` & `spacesuit`) [DONE]
* **Vacuum Survival (`vacuum` / `vacuum_tweaks`):** Room seal flood-fill algorithm, atmospheric depressurization, and mechanical immunity for `eg_constructs` drones and golems.
* **Pressurized Spacesuit (`spacesuit` / `spacesuit_tweaks`):** 3D Armor integration with dual air tanks supplying oxygen in vacuum ($Y \ge 1,000$) and underwater.
* **Industrial Techage Crafting:** High-tier composite plates, reinforced glass, and circuit recipes for suit fabrication.

### 2.3 Starship Propulsion & Uncharted Navigation (`jumpdrive` & `jumpdrive_tweaks`) [DONE]
* **Jump Engine & Fueling:** Cryogenic fuel tanks (`jumpdrive_tweaks:fuel_tank`) and external fuel ports (`jumpdrive_tweaks:fuel_port`) hooked into the Techage liquid network.
* **Uncharted Sector Emergence:** Configured `jumpdrive.config.emerge_uncharted = true` and eliminated the 10-second mapgen lockout in `validator.lua` for single-click travel to unexplored space sectors.
* **Dockside Decoupling:** Automatic pipe disconnection upon jump to prevent broken network pointers.

### 2.4 Navigation, Anti-Stranding & EVA Mobility [DONE]
* **Ship Transponder Beacon (`jumpdrive_tweaks:beacon`):** Placeable ship beacon projecting a continuous 3D in-world HUD waypoint marker visible across space with custom callsign and channel frequency selection.
* **Quantum Recall Tether (`jumpdrive_tweaks:quantum_tether`):** Handheld emergency recall device tuned to return drifting players to active ship beacons.
* **EVA RCS Thruster Pack (`spacesuit_tweaks:eva_thruster`):** Handheld maneuvering pack using dynamic gravity vectoring (`Space` upward thrust / fall deceleration, `Shift` descent, `WASD` glide, `Left-Click` boost surge).

### 2.5 Orbital High-Output Solar Power (`solar_hook.lua`) [DONE]
* **Continuous Generation:** Overrides `techage:ta4_solar_carrier`, `techage:ta4_solar_carrierB`, `techage:ta4_solar_inverter`, and `techage:ta4_solar_minicell` to bypass terrestrial day/night cycles and biome heat at $Y \ge 1,000$.
* **Distance Efficiency Curve:** 100% in Low Orbit ($1,000 \le Y < 5,000$), 90% in Asteroid Belt ($5,000 \le Y < 6,000$), 75% in Mars Orbit ($6,000 \le Y < 7,000$), and 40% in Deep Space ($Y \ge 7,000$).
* **Telemetry:** Displays orbital output and efficiency percentage in the node inspection interface.

### 2.6 In-Situ Propellant Refinery: Ice Melter & Water-Fed Electrolysis [DONE]
* **Thermal Ice Melter (`jumpdrive_tweaks:ice_melter`):** Starship appliance converting mined `other_worlds_tweaks:comet_ice` ($10\text{ units H}_2\text{O}$), `default:ice` ($5\text{ units H}_2\text{O}$), or snow into continuous piped `techage:water` powered by orbital electricity.
* **Water-Fed Electrolysis Hook (`electrolyzer_hook.lua`):** Overrides `techage:ta4_electrolyzer` with dual-port liquid isolation (back port: water intake, right port: hydrogen output) and enforces water feedstock consumption in orbit ($Y \ge 1,000$).
* **Full Closed-Loop Flow:** Comet Ice $\to$ Water Melter $\to$ Electrolyzer $\to$ Hydrogen Propellant $\to$ Starship Fuel Tank.

### 2.7 In-Game Documentation (`eg_third_party_docs`) [DONE]
* **Documentation Manual:** Registered `space_exploration` category in `doc` covering vacuum survival, EVA maneuvering, ship transponders, quantum recall, orbital solar power, ice liquefaction, and jumpdrive engineering.
* **Item Encyclopedia:** Added descriptions and usage guides in `doc_items` for all space tools and nodes.

---

## 3. Upcoming Gameplay Roadmap

### 3.1 Tier 1: High-Priority Additions and Immediate Feasibility
1. **Derelict Starships & Orbital Stations:**
   - **Mechanism:** Procedural schematic placement integrated into `other_worlds_tweaks/asteroid_mapgen.lua` spawning abandoned vessel hulls and orbital outpost ruins in asteroid fields.
   - **Content:** Salvageable Techage machinery, damaged solar arrays, fuel storage containers, high-tier electronic circuits, and exploration log terminals.
2. **Ship Sensor & Radar Array Console:**
   - **Mechanism:** Cockpit console node interfacing with surrounding chunk voxels within a 500m–1,000m radius.
   - **Output:** Identifies directions and coordinates of rich mineral asteroid cores, derelict wrecks, and active transponders.
3. **Hydroponic Oxygen Scrubbers & Life Support Modules:**
   - **Mechanism:** Station life support machine linking to TechAge water pipes and electricity. Automatically pressurizes station chambers and recharges inventory air bottles without manual crafting.

### 3.2 Tier 2: Medium-Priority Additions (Moderate Complexity)
1. **Derelict Defense Drones & Security Constructs:**
   - **Mechanism:** Leverages `eg_constructs` and `mobs` to spawn vacuum-immune automated security drones patrolling derelict stations that defend salvage with directed-energy weapons.
2. **Solar Radiation & Cosmic Ray Storms:**
   - **Mechanism:** Periodic high-altitude space weather events that inflict radiation damage unless players are sheltered within sealed, reinforced hull compartments (verified via `vacuum` seal checks).
3. **Ship-Mounted Mining Lasers / Drills:**
   - **Mechanism:** Hull-mounted excavation heads allowing pilots to bore through asteroid rock and harvest mineral veins directly from the vessel cockpit.

### 3.3 Tier 3: Stretch Goals
1. **Dynamic Ship-to-Ship Docking Clamps:**
   - **Concept:** Structural docking blocks allowing two independent jumpable vessels to lock together into a single jump entity.
   - **Consideration:** Requires handling coordinate offsets and bounding-box merges across independent `jumpdrive` controllers.
2. **Gas Giant & Planetary Ring Siphons:**
   - **Concept:** Orbital harvesting platforms designed to collect exotic gases (Helium-3, volatile plasmas) from outer planetary boundaries.
