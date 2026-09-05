technic = {}

local function no_op() 
    -- Do nothing
end

-- Explicitly define known registration stubs and properties used across community mods.
-- We avoid a blanket __index metatable so that feature detection checks (e.g. `if technic.machines then`)
-- correctly evaluate to nil/false instead of returning a truthy no_op function.
technic.register_power_tool = no_op
technic.set_RE_wear = no_op
technic.refill_RE_charge = no_op
technic.register_machine = no_op
technic.register_separating_recipe = no_op
technic.register_grinder_recipe = no_op
technic.register_alloy_recipe = no_op
technic.register_extractor_recipe = no_op
technic.receiver = "receiver"
technic.producer = "producer"

-- Register dummy anchor nodes so mods like jumpdrive can safely override them
minetest.register_node("technic:admin_anchor", {
	description = "Admin Anchor (Dummy)",
	groups = {not_in_creative_inventory = 1},
})
minetest.register_node("technic:anchor", {
	description = "Anchor (Dummy)",
	groups = {not_in_creative_inventory = 1},
})


