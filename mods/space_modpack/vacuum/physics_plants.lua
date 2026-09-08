

-- plants in vacuum
minetest.register_abm({
	label = "space vacuum plants",
	nodenames = {
		"group:sapling",
		"group:plant",
		"group:flora",
		"group:flower",
		"group:leafdecay",
		"ethereal:banana", -- ethereal compat
		"ethereal:orange",
		"ethereal:strawberry"
	},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = vacuum.throttle(100, function(pos)
		local node = minetest.get_node(pos)
		if not node or not node.name then return end
		-- Protect alien / space-adapted plants from vacuum decay
		if minetest.get_item_group(node.name, "space_flora") > 0 then
			return
		end
		minetest.set_node(pos, {name = "default:dry_shrub"})
	end)
})

