# Farm Tools

Based on the [Scythes & Sickles](https://github.com/t-affeldt/sickles) mod by TestificateMods, this mod adds various tools to make farming more convenient.

![Banner image](https://codeberg.org/camelia/farmtools/media/tag/0.0.1/screenshot.png)

Scythes allow you to quickly sweep through your fields. They can only break fully grown crops and harvest multiple plants at once. They also replant harvested crops automatically. Alternatively, they can be used as an effective weapon with higher range.
Sickles allow you to scrape grass and moss from overgrown nodes. The resulting moss can then be used as dye or fertilizer. They also let you to cut wheat and other grains more precisely, allowing you to harvest some crops without completely resetting them.
Finally, rakes allow you to turn dirt into soil in a 3x3 area, so that you can create bigger farms more quickly.

## About this mod

### Why a fork?

When I created this fork, the source code repository of the original mod didn't have any activity since almost a year, and there were some issues in the mod since multiple years. After sending my patches to the maintainer of the original mod, I decided to go ahead and make my own fork.

### How does it differ from the original mod?

It may differ more and more in the future. Currently, I have fixed two long-lasting bugs:

- The scythes and sickles now work on all plants from the `farming_redo` mod. In the original mod, they didn't work when the node ID of the plant was different from the item name (for instance, raspberries have the following node ID: `farming:raspberry`, whereas the item in the inventory has `farming:raspberries`).
- Plants from the `farming_redo` that don't drop their seeds when harvested can now be replanted if seeds can be crafted from their fruit. This is the case for `farming:sunflower`, `farming:garlic` and `farming:pepper`.

In addition:

- I also added a diamond version of the tools, and plan to support other materials in the future.
- I added rakes, that allow to turn dirt into soil in a 3x3 area.

## Roadmap

- [x] Add support for `x_farming` mod
- [x] Add rakes with other materials (i.e. gold, diamond, etc.)
- [x] Add mithril tools
- [ ] Improve translations

## Features

### Scythes

- only break fully grown crops
- harvest all grown neighboring crops as well
- automatically replant harvested crops
- can be used as a weapon with slightly more range

### Sickles

- are an effective cutting tool
- can harvest grass and moss from overgrown nodes
- reset wheat and other grains by a few stages upon harvest instead of destroying them
- have a slightly shorter range

### Rakes

- can turn dirt into soil in a 3x3 area
- are therefore more efficient than hoes

### Moss

- can be found in four different colors
- can be used as fuel in a furnace
- can be crafted into dye
- can be cooked into fertiliser (requires bonemeal mod)
- can be turned into blocks
- can be placed on the side of any node
- can be eaten for a minimal health gain

### Moss Blocks

- are an effective fuel in a furnace
- can be used as a building block
- can be crafted into slabs and stairs
- can be dyed in any of it's four natural colors

## Credits

### Code

- This is a fork of [the original mod](https://github.com/t-affeldt/sickles) written by Till Affeldt and licensed under [LGPL-3.0](https://www.gnu.org/licenses/lgpl-3.0.en.html).
- This fork is made by Camelia Lavender and is licensed under [LGPL-3.0](https://www.gnu.org/licenses/lgpl-3.0.en.html). as well.
- Some of the code used for the rakes (`lib/rake.lua`) is directly based on the [Minetest Game farming/hoes mod](https://github.com/luanti-org/minetest_game/blob/master/mods/farming/hoes.lua). The original code is licensed under [LGPL-2.1](https://github.com/luanti-org/minetest_game/blob/master/LICENSE.txt), and the adapted code present in this repository is licensed under [LGPL-3.0](https://www.gnu.org/licenses/lgpl-3.0.en.html).
- Mineclonia/VoxeLibre support was made by [bgstack15](https://codeberg.org/bgstack15).

### Assets

- Textures for rakes are made by Camelia Lavender, and are licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en).
- Textures for scythes and sickles added in this fork (i.e. diamond scythes and sickles, etc.) are made by Camelia Lavender based on the textures made by Cap for the original mod, that are licensed under _CC BY-SA 3.0_. [Therefore](https://creativecommons.org/share-your-work/licensing-considerations/compatible-licenses/), those textures are licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en).
- Textures for tools included in the original mod and moss items are made by Cap for the original mod and licensed under [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/deed.en).
- Textures for placed moss node and flower petals are by Vanessa Ezekowitz under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en) for her [plantlife modpack](https://forum.minetest.net/viewtopic.php?t=3898).
- The sound effect for placing or breaking moss blocks is made by DrMinky under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.en) and can be found on [FreeSound](https://freesound.org/people/DrMinky/sounds/167073/).
