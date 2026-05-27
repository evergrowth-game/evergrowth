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
