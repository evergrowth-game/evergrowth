
-- setup global with min and max growth invertals from settings

regrow = {
	min_interval = tonumber(core.settings:get("regrow_min_interval")) or 600,
	max_interval = tonumber(core.settings:get("regrow_max_interval")) or 1200
}

-- hidden node that runs timer and regrows fruit stored in meta

core.register_node("regrow:hidden", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	groups = {not_in_creative_inventory = 1},

	-- once placed start random timer between min and max interval setting
	on_construct = function(pos)

		local time = math.random(regrow.min_interval, regrow.max_interval)

		core.get_node_timer(pos):start(time)
	end,

	-- when timer reached check which fruit to place if tree still exists
	on_timer = function(pos, elapsed)

		local meta = core.get_meta(pos) ; if not meta then return end
		local fruit = meta:get_string("fruit")
		local leaf = meta:get_string("leaf")
		local p2 = meta:get_int("p2") or 0

		if fruit == "" or leaf == "" or not core.find_node_near(pos, 1, leaf) then
			fruit = "air"
		end

		core.set_node(pos, {name = fruit, param2 = p2})
	end
})

-- global function to register fruit nodes

function regrow.add_fruit(nodename, leafname, ignore_param2)

	-- does node actually exist ?
	if not core.registered_nodes[nodename] then return end

	-- change attached_node values so fruits regrow instead of dropping
	local def = core.registered_nodes[nodename]
	local groups = def.groups and table.copy(def.groups) or {}

	groups.attached_node = 0

	core.override_item(nodename, {

		-- override on_dig to remove any special functions
		on_dig = core.node_dig,

		-- override after_dig_node to start regrowth
		after_dig_node = function(pos, oldnode, oldmetadata, digger)

			-- if node has been placed by player then do not regrow
			if ignore_param2 ~= true and oldnode.param2 > 0 then return end

			-- replace fruit with regrowth node, set fruit & leaf name
			core.set_node(pos, {name = "regrow:hidden"})

			local meta = core.get_meta(pos)

			meta:set_string("fruit", nodename)
			meta:set_string("leaf", leafname)
			meta:set_int("p2", (oldnode.param2 or 0))
		end,
	})
end

-- override fruits helper

local function add_fruits()

	-- default
	regrow.add_fruit("default:apple", "default:leaves")

	-- ethereal
	regrow.add_fruit("ethereal:banana", "ethereal:bananaleaves")
	regrow.add_fruit("ethereal:banana_bunch", "ethereal:bananaleaves")
	regrow.add_fruit("ethereal:orange", "ethereal:orange_leaves")
	regrow.add_fruit("ethereal:coconut", "ethereal:palmleaves")
	regrow.add_fruit("ethereal:lemon", "ethereal:lemon_leaves")
	regrow.add_fruit("ethereal:olive", "ethereal:olive_leaves")
--	regrow.add_fruit("ethereal:golden_apple", "ethereal:yellowleaves") -- too OP

	-- cool trees
	regrow.add_fruit("cacaotree:pod", "cacaotree:trunk", true)
	regrow.add_fruit("cherrytree:cherries", "cherrytree:blossom_leaves")
	regrow.add_fruit("clementinetree:clementine", "clementinetree:leaves")
	regrow.add_fruit("ebony:persimmon", "ebony:leaves")
	regrow.add_fruit("lemontree:lemon", "lemontree:leaves")
	regrow.add_fruit("oak:acorn", "oak:leaves")
	regrow.add_fruit("palm:coconut", "palm:leaves")
--	regrow.add_fruit("plumtree:plum", "plumtree:leaves") -- regrows already
	regrow.add_fruit("pomegranate:pomegranate", "pomegranate:leaves")
	regrow.add_fruit("chestnuttree:bur", "chestnuttree:leaves")

	-- farming plus
	regrow.add_fruit("farming_plus:cocoa", "farming_plus:cocoa_leaves")
	regrow.add_fruit("farming_plus:banana", "farming_plus:banana_leaves")

	-- aotearoa
	regrow.add_fruit("aotearoa:karaka_fruit", "aotearoa:karaka_leaves")
	regrow.add_fruit("aotearoa:miro_fruit", "aotearoa:miro_leaves")
	regrow.add_fruit("aotearoa:tawa_fruit", "aotearoa:tawa_leaves")
	regrow.add_fruit("aotearoa:hinau_fruit", "aotearoa:hinau_leaves")
	regrow.add_fruit("aotearoa:kawakawa_fruit", "aotearoa:kawakawa_leaves")

	-- australia
	regrow.add_fruit("australia:cherry", "australia:cherry_leaves")
	regrow.add_fruit("australia:lilly_pilly_berries", "australia:lilly_pilly_leaves")
	regrow.add_fruit("australia:macadamia", "australia:macadamia_leaves")
	regrow.add_fruit("australia:mangrove_apple", "australia:mangrove_apple_leaves")
	regrow.add_fruit("australia:moreton_bay_fig", "australia:moreton_bay_fig_leaves")
	regrow.add_fruit("australia:quandong", "australia:quandong_leaves")

	-- more trees
	regrow.add_fruit("moretrees:acorn", "moretrees:oak_leaves")
	regrow.add_fruit("moretrees:cedar_cone", "moretrees:cedar_leaves")
	regrow.add_fruit("moretrees:fir_cone", "moretrees:fir_leaves")
	regrow.add_fruit("moretrees:spruce_cone", "moretrees:spruce_leaves")

	-- xnether
	regrow.add_fruit("xnether:fruit", "xnether:blue_leaves")

	-- multibiomegen
	for f = 0, 230 do
		regrow.add_fruit("multibiomegen:fruit_" .. f, "multibiomegen:leaf_" .. f)
	end

	-- farming redo
	regrow.add_fruit("farming:kiwi", "farming:kiwi_leaves")
end

-- wait until mods are loaded to save dependency mess

core.after(0, add_fruits)


print("[MOD] Regrow loaded")
