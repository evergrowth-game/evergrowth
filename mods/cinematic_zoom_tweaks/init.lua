-- cinematic_zoom_tweaks/init.lua
-- Removes the black bars and replaces cinematic_zoom's FOV scaling to respect binoculars

local speed = tonumber(minetest.settings:get("cinematic_zoom.speed")) or 1
local player_default_fov = {}

-- 1. Unregister cinematic_zoom's globalstep and on_joinplayer callbacks
-- We do this by searching the registered tables for the ones defined in the cinematic_zoom mod.
if minetest.registered_globalsteps then
	for i = #minetest.registered_globalsteps, 1, -1 do
		local info = debug.getinfo(minetest.registered_globalsteps[i])
		if info and info.source and info.source:find("cinematic_zoom") then
			table.remove(minetest.registered_globalsteps, i)
		end
	end
end

if minetest.registered_on_joinplayers then
	for i = #minetest.registered_on_joinplayers, 1, -1 do
		local info = debug.getinfo(minetest.registered_on_joinplayers[i])
		if info and info.source and info.source:find("cinematic_zoom") then
			table.remove(minetest.registered_on_joinplayers, i)
		end
	end
end

-- 2. Register our own on_joinplayer to capture starting FOV per player
minetest.register_on_joinplayer(function(player)
	player:set_properties({zoom_fov = 0})

	local name = player:get_player_name()
	local base_fov = tonumber(minetest.settings:get("fov")) or 72
	local fov, multiplier = player:get_fov()
	if fov and fov ~= 0 then
		player_default_fov[name] = multiplier and (base_fov * fov) or fov
	else
		player_default_fov[name] = base_fov
	end

	-- We don't add HUD bars!
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_default_fov[name] = nil
	if cinematic_zoom and cinematic_zoom.activated then
		cinematic_zoom.activated[name] = nil
	end
end)

-- 3. Register our own globalstep to handle smooth Zooming without bars
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:get_pos()
		local default_fov = player_default_fov[name] or tonumber(minetest.settings:get("fov")) or 72

		-- Current FOV calculations
		local fov, multiplier = player:get_fov()
		if fov == 0 then
			fov = default_fov
		elseif multiplier == true then
			fov = default_fov * fov
		end
		if fov <= 0 then
			fov = default_fov
		end

		-- Disable cinematic zoom in orbital space (Y >= 1000) to prevent jitter and control fighting during EVA
		if pos and pos.y >= 1000 then
			if cinematic_zoom and cinematic_zoom.activated then
				cinematic_zoom.activated[name] = false
			end
			if math.abs(fov - default_fov) > 0.1 then
				player:set_fov(0, false, 0)
			end
		else
			-- Determine Target FOV based on item held
			local target_fov = 30 -- cinematic_zoom's default
			local inv = player:get_inventory()

			if inv and inv:contains_item("main", "binoculars:binoculars") then
				target_fov = 10
			elseif minetest.is_creative_enabled(name) then
				target_fov = 15
			end

			-- Zoom IN
			if cinematic_zoom.activated[name] == true then
				if fov > target_fov + 0.2 then
					local fov_val = fov - (fov - target_fov) * math.min(1.0, (speed * 10) * dtime)
					player:set_fov(fov_val, false, 0.05)
				elseif fov > target_fov then
					player:set_fov(target_fov, false, 0)
				end
			-- Zoom OUT
			elseif cinematic_zoom.activated[name] == false then
				if fov < default_fov - 0.2 then
					local fov_val = fov + (default_fov - fov) * math.min(1.0, (speed * 20) * dtime)
					player:set_fov(fov_val, false, 0.05)
				elseif fov < default_fov - 0.01 then
					player:set_fov(0, false, 0)
				end
			end
		end
	end
end)
