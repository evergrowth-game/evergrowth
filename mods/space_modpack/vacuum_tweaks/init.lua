-- vacuum_tweaks/init.lua
-- Sets space vacuum height and grants vacuum immunity to mechanical constructs

-- Align space vacuum boundary with other_worlds space threshold (Y >= 2000)
if vacuum then
	vacuum.space_height = 2000
end

-- Hook entity damage / suffocation loop to exempt mechanical constructs (drones & golems)
minetest.register_on_mods_loaded(function()
	if vacuum and vacuum.check_entity_suffocation then
		local old_check = vacuum.check_entity_suffocation
		vacuum.check_entity_suffocation = function(entity, pos)
			if not entity or not entity.name then return false end
			-- Immune mechanical constructs from eg_constructs
			if entity.name:find("^eg_constructs:drone_") or entity.name:find("^eg_constructs:clay_golem") then
				return false
			end
			return old_check(entity, pos)
		end
	end
	minetest.log("action", "[vacuum_tweaks] Initialized space vacuum height (Y=2000) and construct immunity rules.")
end)
