-- Automobiles Tweaks
-- Overrides fuel, control, and on_step physics for techage integration and drift fix.

if not minetest.get_modpath("automobiles_lib") then return end

-- 1. Techage Fuel Integration
if automobiles_lib and automobiles_lib.fuel then
    automobiles_lib.fuel['techage:ta3_barrel_gasoline'] = 10
    automobiles_lib.fuel['techage:ta3_canister_gasoline'] = 1
end

-- 2. Autobahn Speed Boost & Control
local modpath = minetest.get_modpath("eg_automobiles_tweaks")
dofile(modpath .. "/control.lua")

-- 3. On-step overrides
dofile(modpath .. "/entities.lua")
