-- Compatibility functions

-- Write a luanti-style deprecation message to the log.
-- Optionally log an added custom message.
function mcl_util.log_deprecated_call(level, moreinfo_msg)
	local info2 = debug.getinfo(2)
	local info3 = debug.getinfo(3)
	local deprecated_msg = string.format("Calling %s() is deprecated (at %s:%s)",
		info2.name or "unknown",
		info3.short_src or "unknown",
		info3.currentline or "unknown"
	)
	core.log(level or "warning", deprecated_msg)
	if moreinfo_msg then
		core.log(level or "warning", moreinfo_msg)
	end
end

-- Polyfills for legacy Luanti

function mcl_util.is_valid_objectref (object)
	return object:is_valid ()
end

local function valid_object_iterator(objects)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		if obj:is_player() and mcl_player.players[obj] and mcl_player.players[obj].joinplayer_done and obj:is_valid() then
			return obj
		elseif not obj:is_player() and obj:is_valid() then
			return obj
		end
		return next_valid_object()
	end
	return next_valid_object
end

local function valid_object_iterator_in_radius(objects, center, radius)
	local i = 0
	local function next_valid_object()
		i = i + 1
		local obj = objects[i]
		if obj == nil then
			return
		end
		local p = obj:get_pos()
		local distance = p and vector.distance (p, center)
		if p and distance <= radius then
			return obj, distance
		end
		return next_valid_object()
	end
	return next_valid_object
end

function mcl_util.connected_players(center, radius)
	local pls = core.get_connected_players()
	if not center then return valid_object_iterator(pls) end
	return valid_object_iterator_in_radius(pls, center, radius or 1)
end

-- mcl_util.get_node_raw is defined to a built-in core.get_node_raw,
-- if it does in fact exist, and should be evaluated to decide whether
-- to utilize this function for performance.

if not core.get_node_raw then -- polyfill for pre minetest 5.13
	local env = core.request_insecure_environment ()

	-- If mcl_util is a trusted mod, it may be possible to extract
	-- the definition of `get_node_raw' from core.get_node and
	-- avoid garbage collection incurred by table allocation in
	-- the loop below.
	local get_node = core.get_node
	local i = 1
	while env do
		local name, upvalue = env.debug.getupvalue (get_node, i)
		if not name then
			break
		end

		if name == "get_node_raw" then
			core.get_node_raw = upvalue
			mcl_util.get_node_raw = upvalue
			break
		end

		i = i + 1
	end

	if not core.get_node_raw then
		local v = vector.new ()
		function core.get_node_raw(x, y, z)
			v.x, v.y, v.z = x, y, z
			local node = get_node (v)
			local cid = core.get_content_id (node.name)
			return cid, node.param1, node.param2, cid ~= core.CONTENT_IGNORE
		end
	end
else
	mcl_util.get_node_raw = core.get_node_raw
end

-- pre-5.15 polyfill
if not core.path_exists then
	function core.path_exists(path)
		local file_exists = mcl_util.file_exists(path)
		if file_exists then return file_exists end
		return core.get_dir_list(path) ~= nil
	end
end

-- pre-5.13 polyfill for VoxelManip:close()
function mcl_util.vm_close(vm)
	if vm.close then
		vm:close()
	else
		-- recommended workaround; see <https://github.com/luanti-org/luanti/issues/13982>
		collectgarbage()
	end
end
