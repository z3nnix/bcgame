mcl_pickblock = {}

local function get_pick_range(player)
	local name = player:get_player_name()
	if core.is_creative_enabled(name) then
		return tonumber(core.settings:get("mcl_hand_range_creative")) or 10
	end
	return tonumber(core.settings:get("mcl_hand_range")) or 4.5
end

local function get_pick_stack(pos)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	if not def then
		return nil
	end
	local baseitem = def._mcl_baseitem
	local stack
	if type(baseitem) == "function" then
		stack = baseitem(pos)
	elseif type(baseitem) == "string" then
		stack = ItemStack(baseitem)
	else
		stack = ItemStack(node.name)
		if core.get_item_group(node.name, "not_in_creative_inventory") > 0 then
			if type(def.drop) ~= "string" or def.drop == "" then
				return nil
			end
			stack = ItemStack(def.drop)
		end
	end
	if not stack or stack:is_empty() or not core.registered_items[stack:get_name()] then
		return nil
	end
	return stack
end

local function select_from_inventory(player, stack)
	local inv = player:get_inventory()
	if not inv then
		return false
	end
	local wield_index = player:get_wield_index()
	local main = inv:get_list("main")
	if not main then
		return false
	end
	local item_name = stack:get_name()
	for i, istack in pairs(main) do
		if istack:get_name() == item_name then
			if i ~= wield_index then
				inv:set_stack("main", i, main[wield_index])
				inv:set_stack("main", wield_index, istack)
			end
			player:set_wielded_item(inv:get_stack("main", wield_index))
			return true
		end
	end
	return false
end

local function do_pick(player)
	local pos = player:get_pos()
	if not pos then
		return
	end
	local eye = vector.offset(pos, 0, player:get_properties().eye_height, 0)
	local dir = vector.multiply(player:get_look_dir(), get_pick_range(player))
	local pointed
	for ray in core.raycast(eye, vector.add(eye, dir), false, true) do
		if ray.type == "node" then
			pointed = ray
			break
		end
	end
	if not pointed then
		return
	end
	local stack = get_pick_stack(pointed.under)
	if not stack then
		return
	end

	if core.is_creative_enabled(player:get_player_name()) then
		if not select_from_inventory(player, stack) then
			stack:set_count(stack:get_stack_max())
			player:set_wielded_item(stack)
		end
	else
		select_from_inventory(player, stack)
	end
end

controls.register_on_press(function(player, cname)
	if cname == "aux1" then
		do_pick(player)
	end
end)