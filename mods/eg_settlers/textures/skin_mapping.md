# NPC Skin Mapping

This document outlines the final mapping of standard human skins from local mod assets (`skinsdb`, `mobs_npc`, and `mobf_trader`) to the 10 professions in the `eg_settlers` mod.

There is **zero overlap** in this mapping, and **no monster or raider skins** are used. Every profession and gender uses a distinct and distinctive standard human skin.

## Source Assets

### skinsdb
1. `character_farmer_male.png`
2. `character_farmer_female.png`
3. `character_prince.png`
4. `character_princess.png`
5. `character_castaway_male.png`
6. `character_castaway_female.png`
7. `character_rogue_male.png`
8. `character_rogue_female.png`

### mobs_npc (Excluding monster skins)
1. `mobs_npc.png`
2. `mobs_npc2.png`
3. `mobs_npc3.png`
4. `mobs_npc4.png`
5. `mobs_npc5.png`
6. `mobs_npc6.png`
7. `mobs_trader.png`
8. `mobs_trader2.png`
9. `mobs_trader3.png`
10. `mobs_trader4.png`

### mobf_trader
1. `baeuerin.png`
2. `bauer_in_sonntagskleidung.png`

---

## Profession Allocation

| Profession | Gender | Source Path | Target Filename |
| :--- | :--- | :--- | :--- |
| **Farmer 1** | Male | `skinsdb/textures/character_farmer_male.png` | `male_farmer_1.png` |
| **Farmer 1** | Female | `skinsdb/textures/character_farmer_female.png` | `female_farmer_1.png` |
| **Farmer 2** | Male | `mobf_trader/textures/tomatenhaendler.png` | `male_farmer_2.png` |
| **Farmer 2** | Female | `mobf_trader/textures/baeuerin.png` | `female_farmer_2.png` |
| **Smith** | Male | Online ID 390 (`Builder`) | `male_smith.png` |
| **Smith** | Female | Online ID 1319 (`Lillyta Guard`) | `female_blacksmith.png` |
| **Lumberjack** | Male | Online ID 732 (`Woodcutter`) | `male_lumberjack.png` |
| **Lumberjack** | Female | `skinsdb/textures/character_castaway_female.png` | `female_lumberjack.png` |
| **Miner** | Male | `skinsdb/textures/character_rogue_male.png` | `male_miner.png` |
| **Miner** | Female | `skinsdb/textures/character_rogue_female.png` | `female_miner.png` |
| **Merchant** | Male | `mobs_npc/textures/mobs_trader.png` | `male_merchant.png` |
| **Merchant** | Female | `mobs_npc/textures/mobs_trader2.png` | `female_merchant.png` |
| **Brewer** | Male | `mobs_npc/textures/mobs_npc3.png` | `male_brewer.png` |
| **Brewer** | Female | `mobs_npc/textures/mobs_npc4.png` | `female_brewer.png` |
| **Librarian** | Male | `mobs_npc/textures/mobs_trader3.png` | `male_librarian.png` |
| **Librarian** | Female | `mobs_npc/textures/mobs_trader4.png` | `female_librarian.png` |
| **Mage** | Male | Online ID 1435 (`Green Wizard`) | `male_mage.png` |
| **Mage** | Female | `mobs_npc/textures/mobs_npc6.png` | `female_mage.png` |
| **Gunsmith** | Male | `mobs_npc/textures/mobs_npc.png` | `male_gunsmith.png` |
| **Gunsmith** | Female | `mobs_npc/textures/mobs_npc2.png` | `female_gunsmith.png` |
| **Fisher** | Male | Online ID 1841 (`PirateMan`) | `male_fisher.png` |
| **Fisher** | Female | Online ID 467 | `female_fisher.png` |
| **Guard** | Male | Online ID 1166 (`Knight`) | `male_guard.png` |
| **Guard** | Female | Online ID 2335 (`Knighted Girl`) | `female_guard.png` |
| **Automobile Mechanic** | Male | Original Mechanic Skin | `male_mechanic.png` |
| **Automobile Mechanic** | Female | Original Mechanic Skin | `female_mechanic.png` |
| **Aircraft Mechanic** | Male | Original Mechanic Skin (Green Hue Shift) | `male_aircraft_mechanic.png` |
| **Aircraft Mechanic** | Female | Original Mechanic Skin (Green Hue Shift) | `female_aircraft_mechanic.png` |
| **Nautical Mechanic** | Male | Original Mechanic Skin (Blue Hue Shift) | `male_nautical_mechanic.png` |
| **Nautical Mechanic** | Female | Original Mechanic Skin (Blue Hue Shift) | `female_nautical_mechanic.png` |
| **Roboticist** | Male | Online ID 1138 (`Scientist MB`) | `male_roboticist.png` |
| **Roboticist** | Female | Online ID 1961 (`woman_lott`) | `female_roboticist.png` |
