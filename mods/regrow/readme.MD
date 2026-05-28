minetest mod REGROW
===================

Mod to regrow fruits with self-contained API

## Information
-----------

This mod helps to regrow tree fruits instead of the need for replanting
saplings each time.


![screenshot.jpg](screenshot.jpg)


## Technical info
--------------

This mod is named `regrow` a simplified optimized version 
of fruits nodes to reappears on place after dig using timer parameters.

#### Dependences

none, core minetest api, the mod has a node detection inside the api function 
so its secure to use no matter if the corresponding node exits or not.

### Configuration

Each fruit will grow depending of the minimun and maximun value, 
the time the fruit appears is random between the two configured values:

| setting name        | description             | type | default | observations |
| ------------------- | ----------------------- | --- | ------- | ----------- |
| regrow_min_interval | Minimum Regrow Interval | int | 600  | Seconds |
| regrow_max_interval | Maximum Regrow Interval | int | 1200 | seconds |

### Overview:

Based on "endless_apples" by Shara RedCat (2018). Its starting 
at https://forum.minetest.net/viewtopic.php?p=379158#p379158 to solve 
an issue over growing fruits and now is mantained.

The mod works as is but can be used for other mods, currently the mod 
has support for `ethereal`, `farming_plus`, `australia`, `aotearoa`, 
and `moretrees`. It also support some special others.

#### Nodes

| MOD supported | Fruit to regrow (node) | Sustitute when growing (node) |
| ------------- | ---------------------- | ----------------------------- |
| default       | default:apple         | default:leaves             |
| farming (redo)| farming:kiwi          | farming:kiwi_leaves        |
| ethereal      | ethereal:banana       | ethereal:bananaleaves      |
| ethereal      | ethereal:banana_bunch | ethereal:bananaleaves      |
| ethereal      | ethereal:orange       | ethereal:orange_leaves     |
| ethereal      | ethereal:coconut      | ethereal:palmleaves        |
| ethereal      | ethereal:lemon        | ethereal:lemon_leaves      |
| ethereal      | ethereal:olive        | ethereal:olive_leaves      |
| ethereal      | ethereal:golden_apple | ethereal:yellowleaves (disabled) |
| cool_trees    | cacaotree:pod         | cacaotree:trunk (override) |
| cool_trees    | cherrytree:cherries   | cherrytree:blossom_leaves  |
| cool_trees    | clementinetree:clementine | clementinetree:leaves  |
| cool_trees    | ebony:persimmon       | ebony:leaves               |
| cool_trees    | lemontree:lemon       | lemontree:leaves           |
| cool_trees    | oak:acorn             | oak:leaves                 |
| cool_trees    | palm:coconut          | palm:leaves                |
| cool_trees    | pomegranate:pomegranate | pomegranate:leaves       |
| farming_plus  | farming_plus:cocoa    | farming_plus:cocoa_leaves  |
| farming_plus  | farming_plus:banana   | farming_plus:banana_leaves |
| aotearoa      | aotearoa:karaka_fruit | aotearoa:karaka_leaves     |
| aotearoa      | aotearoa:miro_fruit   | aotearoa:miro_leaves       |
| aotearoa      | aotearoa:tawa_fruit   | aotearoa:tawa_leaves       |
| aotearoa      | aotearoa:hinau_fruit  | aotearoa:hinau_leaves      |
| aotearoa      | aotearoa:kawakawa_fruit | aotearoa:kawakawa_leaves |
| australia     | australia:cherry      | australia:cherry_leaves    |
| australia     | australia:lilly_pilly_berries     | australia:lilly_pilly_leaves |
| australia     | australia:macadamia   | australia:macadamia_leaves |
| australia     | australia:mangrove_apple | australia:mangrove_apple_leaves |
| australia     | australia:moreton_bay_fig | australia:moreton_bay_fig_leaves |
| australia     | australia:quandong    | australia:quandong_leaves  |
| moretrees     | moretrees:acorn       | moretrees:oak_leaves       |
| moretrees     | moretrees:cedar_cone  | moretrees:cedar_leaves     |
| moretrees     | moretrees:fir_cone    | moretrees:fir_leaves       |
| moretrees     | moretrees:spruce_cone | moretrees:spruce_leaves    |

#### API usage

The `regrow.add_fruit()` function is used to override each fruits `after_dig_node`
function so that an placeholder node (nostly leaves) is placed once it is taken, then a timer is
started that will regrow the fruit on completion (unless tree is chopped down).

#### Definition

`regrow.add_fruit(fruit_node, leaves_node, param2_check_override)`

#### Examples:

```
	regrow.add_fruit("default:apple", "default:leaves")
	regrow.add_fruit("cacaotree:pod", "cacaotree:trunk", true)
```

Changelog
---------

- 0.1 - Initial upload.
- 0.2 - Add checks for player placed fruit and tree's nearby.
- 0.3 - Make add_fruit a global function for other mods to use.
- 0.4 - Add check for fruit tree leaf type before re-growing.
- 0.5 - Ethereal Lemons and Olives can now regrow.
- 0.6 - Add support for cool_trees, farming_plus, aotearoa, australia and moretrees
- 0.7 - Add param2 override for cacao with placement param2 check
- 0.8 - Add custom min and max time regrow interval settings (defaults are 600 and 1200)
- 0.9 - Add Kiwi from farming redo and a new screenshot.


## LICENSE

MIT see [license.txt](license.txt) file.

