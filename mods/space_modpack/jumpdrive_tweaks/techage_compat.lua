-- jumpdrive_tweaks/techage_compat.lua
-- TechAge NVM state migration, network invalidation, and machine continuity engine

jumpdrive_tweaks = rawget(_G, "jumpdrive_tweaks") or {}

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for k, v in pairs(orig) do
			copy[deepcopy(k)] = deepcopy(v)
		end
	else
		copy = orig
	end
	return copy
end

-- 1. Migrate single node NVM storage from origin to destination
function jumpdrive_tweaks.migrate_techage_node(from_pos, to_pos)
	if not rawget(_G, "techage") then return end
	if type(techage.peek_nvm) ~= "function" or type(techage.get_nvm) ~= "function" then return end

	local src_nvm = techage.peek_nvm(from_pos)
	if src_nvm and next(src_nvm) ~= nil then
		local dst_nvm = techage.get_nvm(to_pos)
		for k, v in pairs(src_nvm) do
			dst_nvm[k] = deepcopy(v)
		end

		if type(techage.del_mem) == "function" then
			techage.del_mem(from_pos)
		end
	end
end

-- 2. Post-jump network cache invalidation, reconnection, and machine reactivation
function jumpdrive_tweaks.reconnect_techage_networks(ship_scan, delta_vector)
	local node_list = ship_scan and (ship_scan.nodes or ship_scan.ship_node_list)
	if not node_list then return end

	local has_techage = rawget(_G, "techage") ~= nil
	local has_networks = rawget(_G, "networks") ~= nil

	-- Phase A: Invalidate network caches at origin positions across all direction indices (0..6)
	if has_networks and type(networks.update_network) == "function" and networks.registered_networks then
		for _, from_pos in ipairs(node_list) do
			for _, netw_map in pairs(networks.registered_networks) do
				for _, tlib2 in pairs(netw_map) do
					for dir = 0, 6 do
						networks.update_network(from_pos, dir, tlib2)
					end
				end
			end
			-- Purge any temporary connection metadata created on vacated origin coordinates
			local node = minetest.get_node_or_nil(from_pos)
			local nodedef = node and minetest.registered_nodes[node.name]
			if not node or node.name == "air" or node.name == "vacuum:vacuum" or (nodedef and nodedef.buildable_to) then
				local meta = minetest.get_meta(from_pos)
				meta:from_table(nil)
			end
		end
	end

	-- Phase B: Reconnect destination networks and resume operational machine loops
	for _, from_pos in ipairs(node_list) do
		local to_pos = vector.add(from_pos, delta_vector)
		local node = minetest.get_node_or_nil(to_pos)

		if node and node.name ~= "air" and node.name ~= "ignore" then
			local nodedef = minetest.registered_nodes[node.name]
			local has_network_def = (nodedef and (nodedef.networks or (nodedef.groups and nodedef.groups.techage_node)))
				or node.name:find("^techage")
				or node.name:find("^tubelib")
				or node.name:find("^jumpdrive_tweaks:fuel_")

			-- Re-establish cable / pipe connections only for network-capable nodes
			if has_network_def and has_networks and type(networks.update_network) == "function" and networks.registered_networks then
				for _, netw_map in pairs(networks.registered_networks) do
					for _, tlib2 in pairs(netw_map) do
						networks.update_network(to_pos, 0, tlib2)
					end
				end
			end

			-- Restore operational state and restart node timers for TechAge machines
			if has_techage and type(techage.has_nvm) == "function" and techage.has_nvm(to_pos) then
				local nvm = techage.get_nvm(to_pos)
				local is_running = (type(techage.is_running) == "function" and techage.is_running(nvm))
					or nvm.running == true
					or (nvm.techage_state and nvm.techage_state == (techage.RUNNING or 1))

				local is_standby = (nvm.techage_state and nvm.techage_state == (techage.STANDBY or 3))
					or (nvm.techage_state and nvm.techage_state == (techage.BLOCKED or 2))
					or (nvm.techage_state and nvm.techage_state == (techage.NOPOWER or 4))

				if is_running or is_standby then
					local timer = minetest.get_node_timer(to_pos)
					if timer and not timer:is_started() then
						local cycle = 1.0
						if node.name == "techage:ta4_solar_inverter" or node.name == "techage:ta3_akku" then
							cycle = 2.0
						elseif nodedef and nodedef.cycle_time then
							cycle = nodedef.cycle_time
						end
						if is_standby and not is_running then
							cycle = cycle * 2
						end
						timer:start(cycle)
					end

					-- Specific device handler triggers
					if node.name == "techage:ta3_akku" and rawget(_G, "networks") and networks.power and techage.ElectricCable then
						local meta = minetest.get_meta(to_pos)
						local outdir = meta:get_int("outdir")
						if type(networks.power.start_storage_calc) == "function" then
							networks.power.start_storage_calc(to_pos, techage.ElectricCable, outdir)
						end
					end
				end
			end
		end
	end
end

minetest.log("action", "[jumpdrive_tweaks] Loaded TechAge NVM and power/fluid network jump migration engine.")
