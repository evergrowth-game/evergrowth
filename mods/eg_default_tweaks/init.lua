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
