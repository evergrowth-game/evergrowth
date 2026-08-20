# Evergrowth Settlers (`eg_settlers`)

`eg_settlers` is a Minetest mod introducing dynamic NPC settlements, profession-based trading, dual-tethered housing and workstations, incident logging, proportional justice, and town management mechanics to the Evergrowth game.

## Features

- **Dynamic NPCs & Professions:** Supports a variety of villager professions including Merchants, Farmers, Miners, Blacksmiths, Machinists, Guards, and Companions.
- **Trading & NPC Commerce:** Interactive trade interface for each profession, allowing players to exchange resources, tools, and specialized items.
- **Workstations & Job Blocks:** 3D workstation nodes defining settler professions, paired with dual-tethered day/night routines (working at workstations by day, sleeping in assigned beds by night).
- **Hiring, Relocation & Contracts:** Systems for recruiting settlers via unified hiring contracts, relocating existing NPCs, and placing companion contracts on housing deeds.
- **Job Board Hub:** Central procurement board for purchasing workstation blocks and hiring contracts directly with gold, alongside daily town bounties.
- **Town Management & Satiation:** Centralized administration via the Town Ledger and Granary, tracking population, town progression tiers (Outpost, Hamlet, Village), resident rosters, and food supplies.
- **Town Depot (Passive Production):** Generates daily resource yields based on resident professions when the settlement is well-fed.
- **Incident Logging & Proportional Justice:** Persistent mortality logging and law enforcement systems requiring criminal restitution fines before merchants resume trading with offenders.
- **Smart Intent Detection:** Misclick protection differentiating non-weapon tool/hand strikes from intentional heavy weapon attacks.
- **Settlement Build Protection:** Enforces territory build protection across settlement bounds via integration with the `protector` mod.
- **Defenses & Medical Care:** Ward Stones for automated territory defense, alternating Day/Night shift Guards with dawn/dusk overlap and distress alarm wake responses, and Medkits for settler health restoration.

## Documentation

For technical architecture and design details, refer to the `docs/` directory:

- [Town Management Design](docs/town_management_design.md): Architectural specification for the Town Ledger, global database, satiation mechanics, justice system, intent detection, and build protection.
- [In-Game Guide Content](docs/guide_content.lua): Player-facing documentation registered with `doc` and `guidebooks` mods.

## Future Plans

The `future_plans/` directory contains feature roadmaps ([TODO.md](future_plans/TODO.md)), infrastructure ideas, and asset references for future settlement expansions.
