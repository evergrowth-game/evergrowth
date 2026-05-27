-- cinematic_zoom_tweaks/init.lua
-- Removes the black bars and replaces cinematic_zoom's FOV scaling to respect binoculars

local speed = tonumber(minetest.settings:get("cinematic_zoom.speed")) or 1
local default_fov = tonumber(minetest.settings:get("fov")) or 72

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

-- 2. Register our own on_joinplayer to capture starting FOV
minetest.register_on_joinplayer(function(player)
	player:set_properties({zoom_fov = 0})
	
	default_fov = tonumber(minetest.settings:get("fov")) or 72
	local fov, multiplier = player:get_fov()
	if fov and fov ~= 0 then
		if multiplier == true then
			default_fov = default_fov * fov
		else
			default_fov = fov
		end
	end

	-- We don't add HUD bars!
end)

-- 3. Register our own globalstep to handle smooth Zooming without bars
minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		
		-- Current FOV calculations
		local fov, multiplier = player:get_fov()
		if fov == 0 then
			fov = default_fov
		end
		if multiplier == true then
			fov = default_fov * fov
		end
		if fov <= 0 then
			fov = default_fov
		end
		
		-- Determine Target FOV based on item held
		local target_fov = 30 -- cinematic_zoom's default
		local inv = player:get_inventory()
		
		if inv and inv:contains_item("main", "binoculars:binoculars") then
			target_fov = 10
		elseif minetest.is_creative_enabled(name) then
			target_fov = 15
		end

		local fov_val = fov

		-- Zoom IN
		if cinematic_zoom.activated[name] == true and fov > target_fov then
			if fov > target_fov then
				fov_val = fov - (fov - target_fov) * (speed / 10)
			end
			player:set_fov(fov_val, false, 0.1)
		end

		-- Zoom OUT
		if cinematic_zoom.activated[name] == false and fov < default_fov - 0.01 then
			if fov < default_fov then
				fov_val = fov + (default_fov - fov) * ((speed * 2) / 10)
			end
			player:set_fov(fov_val, false, 0.1)
		end
	end
end)
