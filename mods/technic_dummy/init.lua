technic = {}

local function no_op() 
    -- Do nothing
end

-- Use a metatable to dynamically intercept ANY missing function call
-- and return a silent no-op function instead of crashing.
-- This protects against mods like 'magic_materials' that assume Technic is 
-- fully installed and try to register custom machines.
setmetatable(technic, {
    __index = function(t, key)
        minetest.log("info", "[technic_dummy] Intercepted dummy call to technic." .. tostring(key))
        return no_op
    end
})

-- Keep explicitly defined methods just in case mods check their specific existence
technic.register_power_tool = no_op
technic.set_RE_wear = no_op
technic.refill_RE_charge = no_op

-- Register dummy anchor nodes so mods like jumpdrive can safely override them
minetest.register_node("technic:admin_anchor", {
	description = "Admin Anchor (Dummy)",
	groups = {not_in_creative_inventory = 1},
})
minetest.register_node("technic:anchor", {
	description = "Anchor (Dummy)",
	groups = {not_in_creative_inventory = 1},
})

