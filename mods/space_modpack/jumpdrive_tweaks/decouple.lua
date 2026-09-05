-- jumpdrive_tweaks/decouple.lua
-- Disconnects dockside pipes safely when a ship jumps

if jumpdrive and jumpdrive.register_after_jump then
	jumpdrive.register_after_jump(function(from_area, to_area)
		if minetest.get_modpath("techage") and techage and techage.liquid then
			-- Scan perimeter of from_area for disconnected pipe links
			local p1 = from_area.min
			local p2 = from_area.max
			if p1 and p2 then
				local nodes = minetest.find_nodes_in_area(
					vector.subtract(p1, {x=1, y=1, z=1}),
					vector.add(p2, {x=1, y=1, z=1}),
					{"group:techage_pipe", "group:pipe"}
				)
				for _, pos in ipairs(nodes) do
					local meta = minetest.get_meta(pos)
					if meta then
						-- Trigger refresh of neighboring pipe connections
						minetest.check_for_falling(pos)
					end
				end
			end
		end
	end)
end
