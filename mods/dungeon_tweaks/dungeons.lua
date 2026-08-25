-- dungeon_tweaks: Overhaul dungeonsplus room features and inject raider spawner blocks

if not minetest.get_modpath("dungeonsplus") then
	return
end

local cids = {
	air = minetest.CONTENT_AIR,
	chest = nil,
	straw = nil,
	wood = nil,
	log = nil,
	bottle = nil,
	shelf = nil,
	bootynode = nil,
	slab = nil,
}

local chest_on_construct
local vs = vector.subtract

local function get_cid_if_exists(nodename)
	if minetest.registered_nodes[nodename] then
		return minetest.get_content_id(nodename)
	end
	return nil
end

minetest.register_on_mods_loaded(function()
	cids.chest = get_cid_if_exists("default:chest") or minetest.CONTENT_AIR
	cids.straw = get_cid_if_exists("farming:straw")
	cids.wood = get_cid_if_exists("default:wood")
	cids.log = get_cid_if_exists("default:tree")
	cids.bottle = get_cid_if_exists("vessels:glass_bottle")
	cids.shelf = get_cid_if_exists("vessels:shelf")
	cids.bootynode = get_cid_if_exists("raiders:bootynode")

	if minetest.registered_nodes["stairs:slab_wood"] then
		cids.slab = minetest.get_content_id("stairs:slab_wood")
	elseif minetest.registered_nodes["stairs:slab_cobble"] then
		cids.slab = minetest.get_content_id("stairs:slab_cobble")
	end

	local chest_def = minetest.registered_nodes["default:chest"]
	if chest_def and chest_def.on_construct then
		chest_on_construct = chest_def.on_construct
	end
end)

local function blocked(pos, vdata)
	return vdata[pos] ~= cids.air
end

-- Custom chest placement with tiered rotated loot and bootynode spawner chance
local function place_tweaked_chest(pos, vdata, va)
	if not cids.chest or cids.chest == minetest.CONTENT_AIR then
		return false
	end

	vdata[pos] = cids.chest
	local vpos = va:position(pos)

	if chest_on_construct then
		chest_on_construct(vpos)
	end

	local meta = minetest.get_meta(vpos)
	local inv = meta and meta:get_inventory()
	if not inv then
		return true
	end

	local slots_count = inv:get_size("main")
	if not slots_count or slots_count <= 0 then
		inv:set_size("main", 32)
		slots_count = 32
	end

	local pcgr = PcgRandom(minetest.hash_node_position(vpos))
	-- Randomized slot distribution (8-16 filled slots with tiered variety)
	local num_items = pcgr:next(6, 16)
	for _ = 1, num_items do
		local slot_idx = pcgr:next(1, slots_count)
		local item = dungeon_tweaks.get_dungeon_loot(pcgr, vpos.y)
		if item and not item:is_empty() then
			if inv:get_stack("main", slot_idx):is_empty() then
				inv:set_stack("main", slot_idx, item)
			else
				inv:add_item("main", item)
			end
		end
	end
	return true
end

-- Custom small feature list for storerooms
local storeroom_small = {
	place_tweaked_chest,
	place_tweaked_chest,
	function(pos, vdata)
		-- Spawn a raider bootynode (spawner) with a 35% chance if raiders mod exists
		if cids.bootynode and PcgRandom(pos):next(1, 100) <= 35 then
			vdata[pos] = cids.bootynode
			return true
		end
		if cids.straw then
			vdata[pos] = cids.straw
		end
		return false
	end,
	function(pos, vdata)
		if cids.straw then vdata[pos] = cids.straw end
		return false
	end,
	function(pos, vdata)
		if cids.wood then vdata[pos] = cids.wood end
		return false
	end,
	function(pos, vdata)
		if cids.slab then vdata[pos] = cids.slab end
		return false
	end,
	function(pos, vdata)
		if cids.bottle then vdata[pos] = cids.bottle end
		return false
	end,
}

-- Override existing Storeroom feature in dungeonsplus.features
for _, feat in ipairs(dungeonsplus.features) do
	if feat.name == "Storeroom" or feat.name == "storeroom" then
		feat.generate = function(data)
			local room = data.room
			local va = data.va
			local ystride = va.ystride
			local zstride = va.zstride
			local pos = va:indexp(room.min) + ystride
			local vdata = data.vdata
			local vparam2 = data.vparam2
			local pcgr = PcgRandom(pos)

			local size = vs(room.max, room.min)
			local xmin = 1
			local xmax = size.x - 1
			local zmin = 1
			local zmax = size.z - 1

			-- Add small props & chests
			for x = xmin, xmax do
				for z = zmin, zmax do repeat
					local npos = pos + x + z * zstride
					if blocked(npos, vdata) or not blocked(npos - ystride, vdata) then
						break
					end

					local against = false
					local p2 = 0
					for _, adj in ipairs({
						{ npos + 1, 1 },
						{ npos - 1, 3 },
						{ npos + zstride, 0 },
						{ npos - zstride, 2 },
					}) do
						if blocked(adj[1], vdata) then
							against = true
							p2 = adj[2]
							break
						end
					end

					if not against then
						break
					end

					if pcgr:next(1, 100) < 18 then
						local fn = storeroom_small[pcgr:next(1, #storeroom_small)]
						if fn(npos, vdata, va) then
							vparam2[npos] = p2
						end
					end
				until true end
			end
			return true
		end
		minetest.log("action", "[dungeon_tweaks] Overrode dungeonsplus Storeroom feature with tiered loot & raider spawners")
		break
	end
end

-- Register a new dedicated "Raider Outpost" dungeon room feature
if minetest.get_modpath("raiders") and dungeonsplus.register_dungeon_feature then
	dungeonsplus.register_dungeon_feature({
		name = "Raider Outpost",
		surfaces = "floor",
		weight = 2,
		generate = function(data)
			local room = data.room
			local va = data.va
			local ystride = va.ystride
			local zstride = va.zstride
			local pos = va:indexp(room.min) + ystride
			local vdata = data.vdata
			local vparam2 = data.vparam2
			local pcgr = PcgRandom(pos)

			local size = vs(room.max, room.min)
			local xmin = 1
			local xmax = size.x - 1
			local zmin = 1
			local zmax = size.z - 1

			-- Place bootynode spawner in the center of the room
			local center_pos = va:indexp(room.pos)
			if not blocked(center_pos, vdata) and blocked(center_pos - ystride, vdata) and cids.bootynode then
				vdata[center_pos] = cids.bootynode
			end

			-- Place chests and props along walls
			for x = xmin, xmax do
				for z = zmin, zmax do repeat
					local npos = pos + x + z * zstride
					if blocked(npos, vdata) or not blocked(npos - ystride, vdata) then
						break
					end

					local against = false
					local p2 = 0
					for _, adj in ipairs({
						{ npos + 1, 1 },
						{ npos - 1, 3 },
						{ npos + zstride, 0 },
						{ npos - zstride, 2 },
					}) do
						if blocked(adj[1], vdata) then
							against = true
							p2 = adj[2]
							break
						end
					end

					if not against then
						break
					end

					local roll = pcgr:next(1, 100)
					if roll < 25 then
						place_tweaked_chest(npos, vdata, va)
						vparam2[npos] = p2
					elseif roll < 40 and cids.straw then
						vdata[npos] = cids.straw
					elseif roll < 55 and cids.wood then
						vdata[npos] = cids.wood
					end
				until true end
			end
			return true
		end,
	})
	minetest.log("action", "[dungeon_tweaks] Registered Raider Outpost dungeon feature")
end
