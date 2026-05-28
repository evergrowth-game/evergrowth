# Farm Tools API

The `farmtools` mod exposes an API that makes it easy (as long as you understand Lua) to register new tools.

## 1. Scythes

The code related to scythes is available in `lib/scythes.lua`. However, scythes (along with other tools) are registered in `lib/tools.lua`.

### 1.1. `farmtools.register_scythe`

The function used for registering new scythes.

#### Usage

```lua
local S = core.get_translator("my_mod")

farmtools.register_scythe("my_mod:my_scythe", {
  description = S("My Scythe"),
  inventory_image = "my_mod_my_scythe.png",
  level = 1,
  max_uses = 200,
  material = "my_mod:my_material_ingot"
})
```

#### Arguments

- **name**: the name of the item to register as a scythe (e.g. `"my_mod:my_scythe"`).
- **def**: the definition table, that can contain:
  - **description**: the name of the item as shown to the user (default: `Scythe`).
  - **inventory_image**: the image of the item to display in the game (default: `unknown_item.png`)
  - **level**: the level of the scythe (`0` = the scythe will harvest the pointed node only, `1` = the scythe will harvest in a 3x3 area, `2` = the scythe will harvest in a 5x5 area, and so on) (default: `1`).
  - **max_uses**: the number of times the scythe can be used (default: `90`, but you may want to use at least `200` here, otherwise the tool will wear out very fast). Note that unlike in the original `sickles` mod, _one use_ corresponds to _one node_ processed (i.e. if 9 nodes are processed, this will be considered _nine uses_).
  - **material**: the material used for the default scythe recipe (no default: if not specified, the recipe won't be registered)
  - **recipe**: alternatively, it is possible to specify the recipe directly (note that this will override any `material` specified)

#### Default recipe

The default recipe for scythes is as follow (it can be overriden using `recipe` in the definition table):

```text
----------------------------------
|          |          |          |
|          | material | material |
|          |          |          |
----------------------------------
|          |          |          |
| material |          |  stick   |
|          |          |          |
----------------------------------
|          |          |          |
|          |          |  stick   |
|          |          |          |
----------------------------------
```

### 1.2. `farmtools.scythe_on_use`

The function called when the scythe is used. This function should not be called directly unless you know what you are doing.

#### Usage

```lua
farmtools.scythe_on_use(itemstack, user, pointed_thing, uses)
```

#### Arguments

- **itemstack**: the ItemStack object (should be in the scythe group, otherwise it will not be able to harvest in an area bigger than a single node).
- **user**: the player using the scythe.
- **pointed_thing**: the pointed thing when the scythe is used.
- **uses**: the maximum number of times the scythe can be used.

#### Returns

- **ItemStack**: the ItemStack specified as an argument (worn-out, if it should be)

## 2. Rakes

The code related to rakes is available in `lib/rakes.lua`. However, rakes (along with other tools) are registered in `lib/tools.lua`.

### 2.1. `farmtools.register_rake`

The function used for registering new rakes.

#### Usage

```lua
local S = core.get_translator("my_mod")

farmtools.register_rake("my_mod:my_rake", {
  description = S("My Rake"),
  inventory_image = "my_mod_my_rake.png",
  level = 1,
  max_uses = 200,
  material = "my_mod:my_material_ingot"
})
```

#### Arguments

- **name**: the name of the item to register as a rake (e.g. `"my_mod:my_rake"`).
- **def**: the definition table, that can contain:
  - **description**: the name of the item as shown to the user (default: `Rake`).
  - **inventory_image**: the image of the item to display in the game (default: `unknown_item.png`)
  - **level**: the level of the rake (`0` = the rake will turn only the pointed node into soil (as long as it is possible to do so), `1` = the rake will turn dirt into soil in a 3x3 area, `2` = the rake will turn dirt into soil in a 5x5 area, and so on) (default: `1`).
  - **max_uses**: the number of times the rake can be used (default: `90`). Note that unlike in the original `sickles` mod, _one use_ corresponds to _one node_ processed (i.e. if 9 nodes are processed, this will be considered _nine uses_).
  - **material**: the material used for the default rake recipe (no default: if not specified, the recipe won't be registered)
  - **recipe**: alternatively, it is possible to specify the recipe directly (note that this will override any `material` specified)

#### Default recipe

The default recipe for rakes is as follow (it can be overriden using `recipe` in the definition table):

```text
----------------------------------
|          |          |          |
| material | material | material |
|          |          |          |
----------------------------------
|          |          |          |
| material |  stick   | material |
|          |          |          |
----------------------------------
|          |          |          |
|          |  stick   |          |
|          |          |          |
----------------------------------
```

### 2.2. `farmtools.rake_on_use`

The function called when the rake is used. This function should not be called directly unless you know what you are doing.

#### Usage

```lua
farmtools.rake_on_use(itemstack, user, pointed_thing, uses)
```

#### Arguments

- **itemstack**: the ItemStack object (should be in the rake group, otherwise it will act as a regular hoe).
- **user**: the player using the rake.
- **pointed_thing**: the pointed thing when the rake is used.
- **uses**: the maximum number of times the ItemStack object can be used.

#### Returns

- **ItemStack**: the ItemStack specified as an argument (worn-out, if it should be)

## 3. Sickles

### 3.1. `farmtools.register_sickle`

The function used for registering new sickles.

#### Usage

```lua
local S = core.get_translator("my_mod")

farmtools.register_sickle("my_mod:my_sickle", {
  description = S("My Sickle"),
  inventory_image = "my_mod_my_sickle.png",
  max_uses = 200,
  material = "my_mod:my_material_ingot",
  damage_groups = { fleshy = 2 },
  groupcaps = {
    snappy = { times = { [1] = 2.75, [2] = 1.30, [3] = 0.375 }, uses = 100, maxlevel = 2 }
  }
})
```

#### Arguments

- **name**: the name of the item to register as a sickle (e.g. `"my_mod:my_sickle"`).
- **def**: the definition table, that can contain:
  - **description**: the name of the item as shown to the user (default: `Sickle`).
  - **inventory_image**: the image of the item to display in the game (default: `unknown_item.png`)
  - **max_uses**: the number of times the rake can be used (default: `120`).
  - **material**: the material used for the default sickle recipe (no default: if not specified, the recipe won't be registered)
  - **recipe**: alternatively, it is possible to specify the recipe directly (note that this will override any `material` specified)
  - **damage_groups**: a table containing the damage the item can do to different entity groups.
  - **groupcaps**: a `groupcaps` table ([more information here](https://api.luanti.org/tool-capabilities/#uses-uses-tools-only)).

#### Default recipe

The default recipe for sickles is as follow (it can be overriden using `recipe` in the definition table):

```text
----------------------------------
|          |          |          |
| material |          |          |
|          |          |          |
----------------------------------
|          |          |          |
|          | material |          |
|          |          |          |
----------------------------------
|          |          |          |
|  stick   |          |          |
|          |          |          |
----------------------------------
```

### 3.2. `farmtools.register_cuttable`

The function used for registering nodes that can be cut with the sickle.

#### Usage

```lua
farmtools.register_cuttable(nodename, base, item)
-- e.g.:
farmtools.register_cuttable("default:mossycobble", "default:cobble", "farmtools:moss")
```

#### Arguments

- **nodename**: the node to register as cuttable
- **base**: the node that should be put in place of the cuttable node after it is cut
- **item**: the item that the player obtains when cutting the cuttable node

### 3.3. `farmtools.register_trimmable`

The function used for registering nodes that can be trimmed with the sickle.

#### Usage

```lua
farmtools.register_trimmable(node, base)
-- e.g.:
farmtools.register_trimmable("farming:wheat_8", "farming:wheat_2")
```

#### Arguments

- **node**: the node to register as trimmable
- **base**: the node that should be put in place of the trimmable node after it is trimmed
