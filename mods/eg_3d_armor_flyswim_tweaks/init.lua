-- Replace 3d_armor_flyswim's join callback with a valid local-animation vector.
if minetest.registered_on_joinplayers then
	for i = #minetest.registered_on_joinplayers, 1, -1 do
		local info = debug.getinfo(minetest.registered_on_joinplayers[i])
		if info and info.source and info.source:find("3d_armor_flyswim/init.lua") then
			table.remove(minetest.registered_on_joinplayers, i)
		end
	end
end

minetest.register_on_joinplayer(function(player)
	local player_mod = armor_fly_swim.get_player_model()
	player_api.set_model(player, player_mod)
	player_api.player_attached[player:get_player_name()] = false

	local none = {x = 0, y = 0}
	player:set_local_animation(none, none, none, none, 30)
end)
