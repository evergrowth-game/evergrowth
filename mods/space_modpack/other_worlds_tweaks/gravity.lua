-- other_worlds_tweaks/gravity.lua
-- Applies low gravity in space (Y >= 2000) using player_monoids

local SPACE_ALTITUDE_THRESHOLD = 2000
local SPACE_GRAVITY_FACTOR = 0.35
local MONOID_ID = "other_worlds_space_gravity"

if player_monoids and player_monoids.gravity then
	local check_timer = 0
	minetest.register_globalstep(function(dtime)
		check_timer = check_timer + dtime
		if check_timer < 0.5 then return end
		check_timer = 0

		for _, player in ipairs(minetest.get_connected_players()) do
			local pos = player:get_pos()
			if pos then
				if pos.y >= SPACE_ALTITUDE_THRESHOLD then
					player_monoids.gravity:add_change(player, SPACE_GRAVITY_FACTOR, MONOID_ID)
				else
					player_monoids.gravity:del_change(player, MONOID_ID)
				end
			end
		end
	end)

	minetest.register_on_leaveplayer(function(player)
		player_monoids.gravity:del_change(player, MONOID_ID)
	end)
end
