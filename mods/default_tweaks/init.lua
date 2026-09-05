local orig_request_shutdown = minetest.request_shutdown

if orig_request_shutdown then
	function minetest.request_shutdown(message, reconnect, delay)
		if delay ~= nil then
			return orig_request_shutdown(message or "", reconnect, delay)
		elseif reconnect ~= nil then
			return orig_request_shutdown(message or "", reconnect)
		end
		return orig_request_shutdown(message or "")
	end
end

-- Filter non-standard armor naming warnings from 3d_armor
local orig_log = minetest.log
if orig_log then
	function minetest.log(level, text)
		if (level and type(level) == "string" and level:find("does not have \"_material\" specified")) or
		   (text and type(text) == "string" and text:find("does not have \"_material\" specified")) then
			return
		end
		return orig_log(level, text)
	end
end

