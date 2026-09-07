# Space Exploration & Starships Modpack

An integrated spaceflight, celestial colonization, orbital logistics, and starship engineering suite for Evergrowth / Luanti.

---

## Modpack Architecture

```
mods/space_modpack/
├── jumpdrive/             # Upstream Jumpdrive core (engine, power buffers, fleet digilines)
├── jumpdrive_tweaks/      # Dynamic backbone tracker, selective hull jumps, fuel tanks, ISRU pipes, beacons
├── other_worlds/          # Celestial space layers, planetary biomes, asteroids, ore deposits
├── other_worlds_tweaks/   # Orbital solar curves, water-fed TA4 electrolyzer hook, gravity monoids
├── spacesuit/             # Spacesuit armor, pressure envelopes, air canisters
├── spacesuit_tweaks/      # Cold-gas EVA Thrusters, auto-refueling, zero-g fall mitigation
├── vacuum/                # Vacuum air physics, pressure loss, hull sealing
├── vacuum_tweaks/         # Vacuum sealing hooks and node integrations
└── tests/                 # Automated standalone regression test suites
```

---

## Starship Engineering & Scaling Mechanics

### 1. Mass Scaling & Energy Formulation

In classical rocketry, Tsiolkovsky's rocket equation is exponential ($m_0 = m_f \cdot e^{\Delta v / v_e}$), creating the "tyranny of the rocket equation" where adding propellant exponentially increases required launch mass.

In Evergrowth, Jumpdrive starship mechanics scale **sub-linearly with the cube root of solid hull node count** ($N^{1/3}$):

- **Effective Radius ($R$)**:
  $$R = \mathrm{clamp}\left(\lceil N^{1/3} \cdot 1.2 \rceil,\, 1,\, 25\right)$$
- **Jump Energy Demand**:
  $$\text{Energy (EU)} = 10 \cdot \text{Distance (m)} \cdot R$$
- **Propellant Conversion Ratio**:
  $$1\text{ Unit Propellant} = 50\text{ EU} \quad (\text{Fuel to EU Ratio})$$
- **Propellant Required per Jump**:
  $$\text{Fuel Units} = \frac{10 \cdot \text{Distance} \cdot R}{50} = \frac{\text{Distance} \cdot R}{5}$$

### 2. Vessel Classes & Fuel Consumption

| Class | Solid Nodes ($N$) | Effective Radius ($R$) | Fuel / $1,000\text{m}$ Jump | Fuel / $4,000\text{m}$ Orbital Climb | Tank Equivalent ($5,000\text{u}$ / tank) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Scout / Probe** | $100$ | $6$ | $1,200\text{ u}$ | $4,800\text{ u}$ | $0.96\text{ tanks}$ |
| **Refinery Explorer** | $300$ | $8$ | $1,600\text{ u}$ | $6,400\text{ u}$ | $1.28\text{ tanks}$ |
| **Cruiser / Habitat** | $800$ | $12$ | $2,400\text{ u}$ | $9,600\text{ u}$ | $1.92\text{ tanks}$ |
| **Heavy Dreadnought** | $3,000$ | $18$ | $3,600\text{ u}$ | $14,400\text{ u}$ | $2.88\text{ tanks}$ |
| **Maximum Hull Cap** | $\ge 9,260$ | $25$ | $5,000\text{ u}$ | $20,000\text{ u}$ | $4.00\text{ tanks}$ |

### 3. Anti-Rocket Equation Scaling Advantage

- **Fuel Storage**: Adds $+5,000\text{ units}$ of capacity linearly ($O(k)$) per `jumpdrive_tweaks:fuel_tank` node.
- **ISRU Refinery Overhead**: An entire onboard refinery (Electrolyzer + Ice Melter + Inverter + Battery + 6 Solar Carriers + 12 Solar Wings + 2 Fuel Tanks) adds only $+29\text{ nodes}$.
- **Marginal Cost**: Adding $+29\text{ nodes}$ to a 250-node ship does not increase $R$ ($R=8 \to 8$, $+0\text{ fuel}$ penalty). Even across tier transitions ($R=8 \to 9$), the marginal jump cost is $+200\text{ units}$ for a $1,000\text{m}$ jump, versus $+10,000\text{ units}$ added propellant storage.
- **Result**: Larger, self-sufficient starships have vastly greater operational range and endurance margins than minimal hulls.

---

## In-Situ Resource Utilization (ISRU) Closed Loop

The space exploration pipeline enables perpetual deep-space exploration without planetary resupply:

```
[ Comet Ice Mining ] 
        │
        ▼
[ Thermal Ice Melter ]  (jumpdrive_tweaks:ice_melter)
        │ Pure Liquid Water
        ▼
[ TechAge Liquid Pipes ] (techage:pipe)
        │
        ▼
[ TA4 Space Electrolyzer ] (techage:ta4_electrolyzer) ◄── [ Orbital Solar Array ] (techage:ta4_solar_carrier)
        │ Hydrogen Gas (H2)
        ▼
[ Spacecraft Fuel Tank ] (jumpdrive_tweaks:fuel_tank)
        │ Direct Propellant Feed
        ▼
[ Starship Jumpdrive ] (jumpdrive:engine)
```

### Power Generation & Production Rates
- **Orbital Solar Output**:
  - Low Orbit ($Y = 1,000\text{m}$): $100\%$ ($3.00\text{ kU / carrier}$)
  - Asteroid Belt ($Y = 5,000\text{m}$): $90\%$ ($2.70\text{ kU / carrier}$)
  - Mars Orbit ($Y = 6,000\text{m}$): $75\%$ ($2.25\text{ kU / carrier}$)
  - Deep Space ($Y \ge 7,000\text{m}$): $40\%$ ($1.20\text{ kU / carrier}$)
- **TA4 Space Electrolyzer**:
  - Input: $35\text{ power units}$ / $2\text{s cycle}$, $1\text{ unit liquid water}$.
- **Fast Refuel**: Direct hydrogen canister loading (`techage:cylinder_large_hydrogen` for 5,000 units, `techage:cylinder_small_hydrogen` for 1,000 units) allows instant manual tank replenishment.

## Navigation & Wayfinding Systems

1. **Orbital Waypoint Presets**: Jumpdrive console provides direct trajectory presets for Low Orbit ($Y=1,200$), Asteroids ($Y=5,200$), Mars Orbit ($Y=6,200$), Deep Space ($Y=10,000$), and Void ($Y=20,000$).
2. **Ship Transponder Beacon (`jumpdrive_tweaks:beacon`)**:
   - In-world 3D HUD waypoint displaying real-time vessel direction and distance.
   - Automatically migrates coordinates during jump execution.
   - Filtered to orbital altitudes ($Y \ge 1,000$) to prevent HUD clutter upon death or surface return.
3. **Quantum Recall Tether (`jumpdrive_tweaks:quantum_tether`)**:
   - Tunable quantum recall device.
   - Teleports stranded astronauts back to tuned beacon positions within $5,000\text{m}$.

---

## EVA Thruster & Life Support

- **EVA Thruster (`spacesuit_tweaks:eva_thruster`)**: Compressed-gas propulsion item with zero-inventory-drag usage. Auto-refuels in flight from carried air bottles or airtanks.
- **Orbital Zero-G Fall Mitigation**: Disables collision damage from high vertical falls while operating in space ($Y \ge 1,000$).

---

## Test Automation Suite

Standalone regression test suites validate all mechanics without requiring an active Minetest server:

```bash
# Run Starship Backbone Tracker & Geometry Test Suite
luajit mods/space_modpack/tests/test_ship_tracker.lua

# Run ISRU Refinery, Ice Melter & Solar Generation Suite
luajit mods/space_modpack/tests/test_isru.lua

# Run EVA Thruster & Propellant Management Suite
luajit mods/space_modpack/tests/test_eva_thruster.lua
```
