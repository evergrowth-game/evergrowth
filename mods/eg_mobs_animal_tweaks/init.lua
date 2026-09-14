-- Override specific mobs to prevent them from attacking players unprovoked
local entities = {
	"mobs_animal:cow",
	"mobs_animal:panda",
	"mobs_animal:pumba",
	"mob_horse:horse"
}

minetest.register_on_mods_loaded(function()
	for _, name in ipairs(entities) do
		local entity = minetest.registered_entities[name]
		if entity and entity.passive == false and entity.attack_players ~= false then
			entity.attack_players = false
		end
	end
end)
