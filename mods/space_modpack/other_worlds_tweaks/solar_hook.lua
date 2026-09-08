-- other_worlds_tweaks/solar_hook.lua
-- Integrates TechAge TA4 solar panels, carriers, inverters, and minicells with orbital space physics.

local has_techage = minetest.get_modpath("techage")
local has_networks = minetest.get_modpath("networks")

if not has_techage or not has_networks then return end

local M = minetest.get_meta
local S = techage.S
local Cable = techage.ElectricCable
local Solar = techage.TA4_Cable
local power = networks.power
local control = networks.control

local PWR_PERF = 3
local INVERTER_MAX_PWR = 100

-- Distance-based solar efficiency curve
local function get_space_solar_efficiency(y)
	if y >= 7000 then
		return 0.40 -- Deep Space: 40% (1.20 kU)
	elseif y >= 6000 then
		return 0.75 -- Mars Orbit: 75% (2.25 kU)
	elseif y >= 5000 then
		return 0.90 -- Asteroid Belt: 90% (2.70 kU)
	elseif y >= 1000 then
		return 1.00 -- Low Orbit: 100% (3.00 kU)
	else
		return nil -- Terrestrial Earth (use default TechAge biome heat calculation)
	end
end

-- Checks if a position is exposed to space sunlight (unblocked by opaque nodes)
local function is_sunlit_space(pos)
	local node = minetest.get_node(pos)
	local nname = node.name
	if nname == "air" or nname:find("^vacuum:air") or nname == "vacuum:vacuum" or nname == "ignore" then
		return true
	end
	local def = minetest.registered_nodes[nname]
	if not def then return true end
	return def.sunlight_propagates == true or def.drawtype == "airlike" or def.walkable == false
end

local function get_param2(pos, side)
	local dir = networks.side_to_outdir(pos, side)
	return (dir + 1) % 4
end

-- Checks if solar module is present and sunlit
local function is_space_solar_module(base_pos, pos, side)
	local pos1 = techage.get_pos(pos, side)
	if pos1 then
		local node = techage.get_node_lvm(pos1)
		if node and node.name == "techage:ta4_solar_module" then
			local above_pos = {x = pos1.x, y = pos1.y + 1, z = pos1.z}
			if is_sunlit_space(above_pos) then
				local meta = M(base_pos)
				local expected = (side == "L") and meta:get_int("left_param2") or meta:get_int("right_param2")
				if expected == 0 then
					expected = get_param2(base_pos, side)
				end
				if (node.param2 % 4) == (expected % 4) then
					return true
				end
			end
		end
	end
	return false
end

-- Shared power resolution helper for carriers (Carrier A: y_offset = 0, Carrier B: y_offset = 1)
local function resolve_carrier_power(pos, y_offset, orig_cb)
	if pos.y >= 1000 then
		local eff = get_space_solar_efficiency(pos.y) or 1.0
		local pos1 = {x = pos.x, y = pos.y + y_offset, z = pos.z}
		if is_space_solar_module(pos, pos1, "L") and is_space_solar_module(pos, pos1, "R") then
			return PWR_PERF * eff
		end
		return 0
	end
	if orig_cb then return orig_cb(pos, Solar, "power") end
	return 0
end

-- Hook carrier nodes in control network
-- 1. Override Carrier A (y_offset = 0)
	local def_carrierA = minetest.registered_nodes["techage:ta4_solar_carrier"]
	local orig_carrierA_req = def_carrierA and def_carrierA.control and def_carrierA.control.on_request
	control.register_nodes({"techage:ta4_solar_carrier"}, {
		on_receive = function(pos, tlib2, topic, payload) end,
		on_request = function(pos, tlib2, topic)
			if topic == "power" then
				return resolve_carrier_power(pos, 0, orig_carrierA_req)
			end
			if orig_carrierA_req then return orig_carrierA_req(pos, tlib2, topic) end
		end,
	})

	-- 2. Override Carrier B (y_offset = 1)
	local def_carrierB = minetest.registered_nodes["techage:ta4_solar_carrierB"]
	local orig_carrierB_req = def_carrierB and def_carrierB.control and def_carrierB.control.on_request
	control.register_nodes({"techage:ta4_solar_carrierB"}, {
		on_receive = function(pos, tlib2, topic, payload) end,
		on_request = function(pos, tlib2, topic)
			if topic == "power" then
				return resolve_carrier_power(pos, 1, orig_carrierB_req)
			end
			if orig_carrierB_req then return orig_carrierB_req(pos, tlib2, topic) end
		end,
	})

	-- 3. Override Solar Module info
	minetest.override_item("techage:ta4_solar_module", {
		techage_info = function(pos)
			if pos.y >= 1000 then
				local eff = get_space_solar_efficiency(pos.y) or 1.0
				local above_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
				local sunlit = is_sunlit_space(above_pos)
				local power_val = sunlit and (PWR_PERF * eff / 2.0) or 0
				local eff_pct = math.floor(eff * 100)
				return string.format("Solar Output: %.2f kU (%d%%)", power_val, eff_pct)
			else
				local power_val = 0
				local pos1 = {x = pos.x, y = pos.y + 1, z = pos.z}
				if minetest.get_node(pos1).name == "air" and (minetest.get_node_light(pos1) or 0) >= 14 then
					local data = minetest.get_biome_data(pos)
					local heat = data and data.heat or 0
					power_val = PWR_PERF * heat / 200.0
				end
				local light_val = (minetest.get_node_light(pos1) or 0) .. " / 15"
				return S("power") .. " = " .. power_val .. ", " .. S("light") .. " = " .. light_val
			end
		end
	})

	-- 4. Override Inverter node timer to support continuous orbital solar
	local inverter_def = minetest.registered_nodes["techage:ta4_solar_inverter"]
	if inverter_def then
		local orig_on_timer = inverter_def.on_timer
		minetest.override_item("techage:ta4_solar_inverter", {
			on_timer = function(pos, elapsed)
				if pos.y >= 1000 then
					local nvm = techage.get_nvm(pos)
					local running = techage.is_running(nvm)

					-- Determine space DC power from carrier line
					local outdir = M(pos):get_int("leftdir")
					local netw = networks.get_network_table(pos, Solar, outdir) or {}
					local num_inv = #(netw.con or {})
					local max_power = 0
					for _, pwr in ipairs(control.request(pos, Solar, outdir, "junc", "power")) do
						max_power = max_power + pwr
					end

					if num_inv == 1 then
						nvm.max_power = math.min(INVERTER_MAX_PWR, max_power)
					else
						nvm.max_power = 0
					end

					local has_power = (nvm.max_power > 0)
					if running and not has_power then
						nvm.provided = 0
						nvm.techage_state = techage.STANDBY
						local out_d = M(pos):get_int("outdir")
						power.start_storage_calc(pos, Cable, out_d)
					elseif not running and has_power then
						nvm.provided = 0
						nvm.ticks = 0
						local out_d = M(pos):get_int("outdir")
						power.start_storage_calc(pos, Cable, out_d)
						techage.evaluate_charge_termination(nvm, M(pos))
						nvm.techage_state = techage.RUNNING
					elseif running then
						local meta = M(pos)
						local out_d = meta:get_int("outdir")
						local tp1 = tonumber(meta:get_string("termpoint1"))
						local tp2 = tonumber(meta:get_string("termpoint2"))
						nvm.provided = power.provide_power(pos, Cable, out_d, nvm.max_power, tp1, tp2)
						local val = power.get_storage_load(pos, Cable, out_d, nvm.max_power)
						if val > 0 then
							nvm.load = val
						end
					end
					return true
				else
					return orig_on_timer(pos, elapsed)
				end
			end
		})
	end

	-- 5. Override Minicell (Streetlamp Solar Cell) for space operation
	local minicell_def = minetest.registered_nodes["techage:ta4_solar_minicell"]
	if minicell_def then
		local orig_minicell_timer = minicell_def.on_timer
		minetest.override_item("techage:ta4_solar_minicell", {
			on_timer = function(pos, elapsed)
				if pos.y >= 1000 then
					local nvm = techage.get_nvm(pos)
					nvm.capa = nvm.capa or 0
					local above_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
					local eff = get_space_solar_efficiency(pos.y) or 1.0

					if is_sunlit_space(above_pos) then
						nvm.capa = math.min(nvm.capa + 1.2 * eff, 2400)
					end

					if nvm.capa > 0 then
						if not nvm.providing then
							power.start_storage_calc(pos, Cable, 5)
							nvm.providing = true
						else
							nvm.provided = power.provide_power(pos, Cable, 5, 1 * eff, 0.8, 1.0)
							nvm.capa = nvm.capa - (nvm.provided or 0)
						end
					else
						power.start_storage_calc(pos, Cable, 5)
						nvm.providing = false
						nvm.provided = 0
						nvm.capa = 0
					end
					return true
				else
					return orig_minicell_timer(pos, elapsed)
				end
			end
		})
	end

minetest.log("action", "[other_worlds_tweaks] Loaded TechAge orbital solar power compatibility hook.")
