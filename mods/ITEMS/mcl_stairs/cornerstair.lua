-- Corner stairs handling

-- This code originally copied from the [mcstair] mod and merged into this mod.
-- This file is licensed under CC0.

mcl_stairs.cornerstair = {}

local STAIR_DIR = {
	[0] = {x = 0, z = 1},
	[1] = {x = 1, z = 0},
	[2] = {x = 0, z = -1},
	[3] = {x = -1, z = 0},
}

local RULES = {
	{slot = "lead_turn", turn = "left", blocked = "right_blocked", shape = 2, turn_right = false},
	{slot = "lead_turn", turn = "right", blocked = "left_blocked", shape = 2, turn_right = true},
	{slot = "trail_turn", turn = "left", blocked = "left_blocked", shape = 3, turn_right = false},
	{slot = "trail_turn", turn = "right", blocked = "right_blocked", shape = 3, turn_right = true},
}

local SIDE_ATTACH_BASE = {
	[0] = {[5] = true},
	[1] = {[3] = true},
	[2] = {[4] = true},
	[3] = {[2] = true},
	[20] = {[5] = true},
	[21] = {[2] = true},
	[22] = {[4] = true},
	[23] = {[3] = true},
}

local SIDE_ATTACH_INNER = {
	[0] = {[2] = true, [5] = true},
	[1] = {[3] = true, [5] = true},
	[2] = {[3] = true, [4] = true},
	[3] = {[2] = true, [4] = true},
	[20] = {[3] = true, [5] = true},
	[21] = {[2] = true, [5] = true},
	[22] = {[2] = true, [4] = true},
	[23] = {[3] = true, [4] = true},
}

local UPDATE_OFFSETS = {
	{x = -1, z = -1},
	{x = 0, z = -1},
	{x = 1, z = -1},
	{x = -1, z = 0},
	{x = 0, z = 0},
	{x = 1, z = 0},
	{x = -1, z = 1},
	{x = 0, z = 1},
	{x = 1, z = 1},
}

local function get_stair_facing(param2)
	if param2 < 20 then
		return param2 % 4
	end
	local facing = param2 - 20
	if facing == 1 then
		return 3
	elseif facing == 3 then
		return 1
	end
	return facing
end

local function get_base_facing(pos, node)
	local meta = core.get_meta(pos)
	local orig = meta:get_string("mcl_stairs:facing")
	if orig ~= "" then
		return tonumber(orig)
	end
	return get_stair_facing(node.param2)
end

local function get_stair_from_param(param, stairs)
	if param < 12 then
		if param < 4 then
			return {name = stairs[1], param2 = param}
		elseif param < 8 then
			return {name = stairs[2], param2 = param - 4}
		else
			return {name = stairs[3], param2 = param - 8}
		end
	else
		if param >= 20 then
			return {name = stairs[1], param2 = param}
		elseif param >= 16 then
			return {name = stairs[2], param2 = param + 4}
		else
			return {name = stairs[3], param2 = param + 8}
		end
	end
end

local function stair_param_to_connect(param, ceiling)
	local out = {false, false, false, false, false, false, false, false}
	if not ceiling then
		if param == 0 then
			out[3] = true
			out[8] = true
		elseif param == 1 then
			out[2] = true
			out[5] = true
		elseif param == 2 then
			out[4] = true
			out[7] = true
		elseif param == 3 then
			out[1] = true
			out[6] = true
		elseif param == 4 then
			out[1] = true
			out[8] = true
		elseif param == 5 then
			out[2] = true
			out[3] = true
		elseif param == 6 then
			out[4] = true
			out[5] = true
		elseif param == 7 then
			out[6] = true
			out[7] = true
		elseif param == 8 then
			out[3] = true
			out[6] = true
		elseif param == 9 then
			out[5] = true
			out[8] = true
		elseif param == 10 then
			out[2] = true
			out[7] = true
		elseif param == 11 then
			out[1] = true
			out[4] = true
		end
	else
		if param == 12 then
			out[5] = true
			out[8] = true
		elseif param == 13 then
			out[3] = true
			out[6] = true
		elseif param == 14 then
			out[1] = true
			out[4] = true
		elseif param == 15 then
			out[2] = true
			out[7] = true
		elseif param == 16 then
			out[2] = true
			out[3] = true
		elseif param == 17 then
			out[1] = true
			out[8] = true
		elseif param == 18 then
			out[6] = true
			out[7] = true
		elseif param == 19 then
			out[4] = true
			out[5] = true
		elseif param == 20 then
			out[3] = true
			out[8] = true
		elseif param == 21 then
			out[1] = true
			out[6] = true
		elseif param == 22 then
			out[4] = true
			out[7] = true
		elseif param == 23 then
			out[2] = true
			out[5] = true
		end
	end
	return out
end

local function stair_connect_to_param(connect, ceiling)
	if not ceiling then
		if connect[3] and connect[8] then
			return 0
		elseif connect[2] and connect[5] then
			return 1
		elseif connect[4] and connect[7] then
			return 2
		elseif connect[1] and connect[6] then
			return 3
		elseif connect[1] and connect[8] then
			return 4
		elseif connect[2] and connect[3] then
			return 5
		elseif connect[4] and connect[5] then
			return 6
		elseif connect[6] and connect[7] then
			return 7
		elseif connect[3] and connect[6] then
			return 8
		elseif connect[5] and connect[8] then
			return 9
		elseif connect[2] and connect[7] then
			return 10
		elseif connect[1] and connect[4] then
			return 11
		end
	elseif connect[5] and connect[8] then
		return 12
	elseif connect[3] and connect[6] then
		return 13
	elseif connect[1] and connect[4] then
		return 14
	elseif connect[2] and connect[7] then
		return 15
	elseif connect[2] and connect[3] then
		return 16
	elseif connect[1] and connect[8] then
		return 17
	elseif connect[6] and connect[7] then
		return 18
	elseif connect[4] and connect[5] then
		return 19
	elseif connect[3] and connect[8] then
		return 20
	elseif connect[1] and connect[6] then
		return 21
	elseif connect[4] and connect[7] then
		return 22
	elseif connect[2] and connect[5] then
		return 23
	end
end

local PARAM_BY_VISUAL = {
	[false] = {[1] = {}, [2] = {}, [3] = {}},
	[true] = {[1] = {}, [2] = {}, [3] = {}},
}

for _, ceiling in ipairs({ false, true }) do
	local start_param = ceiling and 12 or 0
	local end_param = ceiling and 23 or 11
	for param = start_param, end_param do
		local visual
		if param < 12 then
			if param < 4 then
				visual = 1
			elseif param < 8 then
				visual = 2
			else
				visual = 3
			end
		else
			if param >= 20 then
				visual = 1
			elseif param >= 16 then
				visual = 2
			else
				visual = 3
			end
		end
		local node = get_stair_from_param(param, { "base", "outer", "inner" })
		PARAM_BY_VISUAL[ceiling][visual][get_stair_facing(node.param2)] = param
	end
end

local function relative_turn(center_facing, neighbor_facing)
	if
		neighbor_facing == nil
		or neighbor_facing == center_facing
		or ((neighbor_facing + 2) % 4) == center_facing
	then
		return "none"
	elseif neighbor_facing == (center_facing + 3) % 4 then
		return "left"
	end
	return "right"
end

local function mirror_turn(turn)
	if turn == "left" then
		return "right"
	elseif turn == "right" then
		return "left"
	end
	return turn
end

local function get_neighbor_facing(pos, dir, ceiling)
	local npos = { x = pos.x + dir.x, y = pos.y, z = pos.z + dir.z }
	local node = core.get_node(npos)
	local def = core.registered_nodes[node.name]
	if not def or not def.stairs then
		return nil
	end
	if (node.param2 >= 20) ~= ceiling then
		return nil
	end
	return get_base_facing(npos, node)
end

local function get_shape_result(pos)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	if not def or not def.stairs then
		return nil
	end

	local upside_down = node.param2 >= 20
	local facing = get_base_facing(pos, node)
	local lead = get_neighbor_facing(pos, STAIR_DIR[facing], upside_down)
	local trail = get_neighbor_facing(pos, STAIR_DIR[(facing + 2) % 4], upside_down)
	local left = get_neighbor_facing(pos, STAIR_DIR[(facing + 3) % 4], upside_down)
	local right = get_neighbor_facing(pos, STAIR_DIR[(facing + 1) % 4], upside_down)
	local lead_turn = relative_turn(facing, lead)
	local trail_turn = relative_turn(facing, trail)
	local left_blocked
	local right_blocked
	if upside_down then
		left_blocked = right == facing
		right_blocked = left == facing
	else
		left_blocked = left == facing
		right_blocked = right == facing
	end
	local observed = {
		lead_turn = upside_down and mirror_turn(lead_turn) or lead_turn,
		trail_turn = upside_down and mirror_turn(trail_turn) or trail_turn,
		left_blocked = left_blocked,
		right_blocked = right_blocked,
	}

	local out_shape = 1
	local out_facing = facing
	for i = 1, #RULES do
		local rule = RULES[i]
		if observed[rule.slot] == rule.turn and not observed[rule.blocked] then
			out_shape = rule.shape
			if rule.turn_right then
				out_facing = upside_down and (facing + 3) % 4 or (facing + 1) % 4
			end
			break
		end
	end

	local target_param = PARAM_BY_VISUAL[upside_down][out_shape][out_facing]
	local connect = stair_param_to_connect(target_param, upside_down)
	local new_node = get_stair_from_param(stair_connect_to_param(connect, upside_down), def.stairs)

	return {
		node = node,
		new_node = new_node,
	}
end

local function placement_prevented_base(params)

	if params == nil or params.itemstack == nil or params.pointed_thing == nil then
		return true
	end

	local wield_name = params.itemstack:get_name()
	local ndef = core.registered_nodes[wield_name]
	local groups = ndef.groups or {}

	local under = params.pointed_thing.under
	local node = core.get_node(under)
	local above = params.pointed_thing.above
	local wdir = core.dir_to_wallmounted({ x = under.x - above.x, y = under.y - above.y, z = under.z - above.z })

	-- on top of upside down
	if groups.attaches_to_top and (node.param2 >= 20 and wdir == 1) then
		return false
	end

	-- on base of upright stair
	if groups.attaches_to_base and (node.param2 < 20 and wdir == 0) then
		return false
	end

	if groups.attaches_to_side then
		local allowed = SIDE_ATTACH_BASE[node.param2]
		if allowed and allowed[wdir] then
			return false
		end
	end

	return true
end

local function placement_prevented_outer(params)

	if params == nil or params.itemstack == nil or params.pointed_thing == nil then
		return true
	end

	local wield_name = params.itemstack:get_name()
	local ndef = core.registered_nodes[wield_name]
	local groups = ndef.groups or {}

	local under = params.pointed_thing.under
	local node = core.get_node(under)
	local above = params.pointed_thing.above
	local wdir = core.dir_to_wallmounted({ x = under.x - above.x, y = under.y - above.y, z = under.z - above.z })

	-- on top of upside down
	if groups.attaches_to_top and (node.param2 >= 20 and wdir == 1) then
		return false
	end

	-- on base of upright stair
	if groups.attaches_to_base and (node.param2 < 20 and wdir == 0) then
		return false
	end

	return true
end

local function placement_prevented_inner(params)
	if params == nil or params.itemstack == nil or params.pointed_thing == nil then
		return true
	end

	local wield_name = params.itemstack:get_name()
	local ndef = core.registered_nodes[wield_name]
	local groups = ndef.groups or {}

	local under = params.pointed_thing.under
	local node = core.get_node(under)
	local above = params.pointed_thing.above
	local wdir = core.dir_to_wallmounted({ x = under.x - above.x, y = under.y - above.y, z = under.z - above.z })

	-- on top of upside down
	if groups.attaches_to_top and (node.param2 >= 20 and wdir == 1) then
		return false
	end

	-- on base of upright stair
	if groups.attaches_to_base and (node.param2 < 20 and wdir == 0) then
		return false
	end

	if groups.attaches_to_side then
		local allowed = SIDE_ATTACH_INNER[node.param2]
		if allowed and allowed[wdir] then
			return false
		end
	end

	return true
end

local function check_sides(pos)
	local source = core.get_node(pos)
	local def = core.registered_nodes[source.name]
	if not def or type(def.placement_prevented) ~= "function" then
		return
	end

	local px = pos.x
	local py = pos.y
	local pz = pos.z

	for i = 0, 3 do
		local dir = STAIR_DIR[i]
		local npos = {
			x = px + dir.x,
			y = py,
			z = pz + dir.z,
		}
		local node = core.get_node(npos)
		local ndef = core.registered_nodes[node.name]
		local groups = ndef.groups or {}

		if groups.attaches_to_base or groups.attaches_to_side or groups.attaches_to_top then
			if def.placement_prevented({
				itemstack = ItemStack(node.name),
				pointed_thing = {
					under = pos,
					above = npos,
				},
			}) then
				mcl_attached.drop_attached_node(npos)
			end
		end
	end
end

local function update_stair(pos)
	local result = get_shape_result(pos)
	if not result then
		return false
	end

	if result.node.name == result.new_node.name and result.node.param2 == result.new_node.param2 then
		return false
	end

	local meta = core.get_meta(pos)
	if meta:get_string("mcl_stairs:facing") == "" then
		meta:set_string("mcl_stairs:facing", tostring(get_stair_facing(result.node.param2)))
	end

	core.swap_node(pos, result.new_node)
	check_sides(pos)

	local new_def = core.registered_nodes[result.new_node.name]
	if new_def and new_def.stairs and result.new_node.name == new_def.stairs[1] then
		meta:set_string("mcl_stairs:facing", "")
	end

	return true
end

local function update_stairs_around(pos)
	update_stair(pos)
	for i = 1, #UPDATE_OFFSETS do
		local offset = UPDATE_OFFSETS[i]
		if offset.x ~= 0 or offset.z ~= 0 then
			update_stair({
				x = pos.x + offset.x,
				y = pos.y,
				z = pos.z + offset.z,
			})
		end
	end

	update_stair(pos)
end

local function rotate_stair_from_base_facing(pos, node, mode)
	local def = core.registered_nodes[node.name]
	if not def or not def.stairs then
		return false
	end

	local upside_down = node.param2 >= 20
	local facing = get_base_facing(pos, node)
	if mode == screwdriver.ROTATE_AXIS then
		upside_down = not upside_down
	elseif mode == screwdriver.ROTATE_FACE then
		facing = (facing + 1) % 4
	else
		return false
	end

	local base_param2 = PARAM_BY_VISUAL[upside_down][1][facing]
	core.set_node(pos, {
		name = def.stairs[1],
		param2 = base_param2,
	})
	core.get_meta(pos):set_string("mcl_stairs:facing", tostring(facing))
	update_stairs_around(pos)
	return true
end

--[[
mcl_stairs.cornerstair.add(name, stairtiles)

NOTE: This function is used internally. If you register a stair, this function is already called, no
need to call it again!

Usage:
* name is the name of the node to make corner stairs for.
* stairtiles is optional, can specify textures for inner and outer stairs. 3 data types are accepted:
    * string: one of:
        * "default": Use same textures as original node
        * "woodlike": Take first frame of the original tiles, then take a triangle piece
                      of the texture, rotate it by 90° and overlay it over the original texture
    * table: Specify textures explicitly. Table of tiles to override textures for
             inner and outer stairs. Table format:
                 { tiles_def_for_outer_stair, tiles_def_for_inner_stair }
    * nil: Equivalent to "default"
]]

local function corner_stair_on_rotate(pos, node, _user, mode, _new_param2)
	return rotate_stair_from_base_facing(pos, node, mode)
end

function mcl_stairs.cornerstair.add(name, stairtiles)
	local node_def = core.registered_nodes[name]
	local outer_tiles
	local inner_tiles
	if stairtiles ~= nil and stairtiles ~= "default" and stairtiles ~= "woodlike" then
		outer_tiles = stairtiles[1]
		inner_tiles = stairtiles[2]
	end
	if inner_tiles == nil then inner_tiles = node_def.tiles end
	if outer_tiles == nil then outer_tiles = node_def.tiles end
	local outer_groups = table.copy(node_def.groups)
	outer_groups.not_in_creative_inventory = 1
	local inner_groups = table.copy(outer_groups)
	outer_groups.stair = 2
	outer_groups.not_in_craft_guide = 1
	inner_groups.stair = 3
	inner_groups.not_in_craft_guide = 1
	local drop = node_def.drop or name
	local old_after_place_node = node_def.after_place_node
	local old_after_dig_node = node_def.after_dig_node
	local old_on_rotate = node_def.on_rotate
	core.override_item(name, {
		stairs = {name, name.."_outer", name.."_inner"},
		placement_prevented = placement_prevented_base,
		on_neighbor_update = update_stair,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			if old_after_dig_node then
				old_after_dig_node(pos, oldnode, oldmetadata, digger)
			end
			update_stairs_around(pos)
		end,
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if old_after_place_node then
				old_after_place_node(pos, placer, itemstack, pointed_thing)
			end
			update_stairs_around(pos)
		end,
		on_rotate = function(pos, node, user, mode, new_param2)
			if mode == screwdriver.ROTATE_AXIS or mode == screwdriver.ROTATE_FACE then
				return rotate_stair_from_base_facing(pos, node, mode)
			end

			if old_on_rotate then
				return old_on_rotate(pos, node, user, mode, new_param2)
			end
			return false
		end,
	})
	core.register_node(":"..name.."_outer", {
		description = node_def.description,
		_doc_items_create_entry = false,
		drawtype = "nodebox",
		tiles = outer_tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = outer_groups,
		sounds = node_def.sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0, 0.5, 0.5}
			}
		},
		drop = drop,
		stairs = {name, name.."_outer", name.."_inner"},
		on_neighbor_update = update_stair,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			update_stairs_around(pos)
		end,
		_mcl_hardness = node_def._mcl_hardness,
		_mcl_baseitem = name,
		on_rotate = corner_stair_on_rotate,
		placement_prevented = placement_prevented_outer,
	})
	core.register_node(":"..name.."_inner", {
		description = node_def.description,
		_doc_items_create_entry = false,
		drawtype = "nodebox",
		tiles = inner_tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		groups = inner_groups,
		sounds = node_def.sounds,
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
				{-0.5, 0, 0, 0.5, 0.5, 0.5},
				{-0.5, 0, -0.5, 0, 0.5, 0}
			}
		},
		drop = drop,
		stairs = {name, name.."_outer", name.."_inner"},
		on_neighbor_update = update_stair,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			update_stairs_around(pos)
		end,
		_mcl_hardness = node_def._mcl_hardness,
		_mcl_baseitem = name,
		on_rotate = corner_stair_on_rotate,
		placement_prevented = placement_prevented_inner,
	})

	doc.add_entry_alias("nodes", name, "nodes", name.."_inner")
	doc.add_entry_alias("nodes", name, "nodes", name.."_outer")
end


