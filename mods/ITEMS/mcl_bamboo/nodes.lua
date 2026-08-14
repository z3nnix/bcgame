local S = core.get_translator("mcl_bamboo")
local SCAFFOLD_BASE_AWAY_LIMIT = 6

function mcl_bamboo.random(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
	return pr:next(1,4)
end

function mcl_bamboo.check_structure(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
	local max_height = pr:next(12,16)
	local bottom = mcl_util.traverse_tower_group(pos,-1,"bamboo_tree")
	local top,h = mcl_util.traverse_tower_group(bottom,1,"bamboo_tree")
	local basenode = core.get_node(bottom)
	local basegroup = core.get_item_group(basenode.name, "bamboo_tree")
	local nn = core.find_nodes_in_area(
		bottom,
		vector.offset(bottom,0,max_height,0),
		{"group:bamboo_tree"}
	)

	-- Check growing in size
	if h > 1 and basegroup < 2 then
		if math.random() < 0.5 then
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_small", param2=basenode.param2})
		else
			core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_big", param2=basenode.param2})
		end
	end

	-- Update basegroup after size changes
	basenode = core.get_node(bottom)
	basegroup = core.get_item_group(basenode.name, "bamboo_tree")

	-- Check growing in leaf
	if basegroup == 1 then return end
	local size = basegroup == 2 and "small" or "big"
	local leaf_bamboo = "mcl_bamboo:bamboo_"..size.."_leafsmall"
	core.bulk_set_node(nn, {name="mcl_bamboo:bamboo_"..size, param2=basenode.param2})
	if h > 3 then
		core.set_node(top, {name="mcl_bamboo:bamboo_"..size.."_leafbig", param2=basenode.param2})
		core.set_node(vector.offset(top,0,-1,0), {name="mcl_bamboo:bamboo_"..size.."_leafbig", param2=basenode.param2})
		core.set_node(vector.offset(top,0,-2,0), {name=leaf_bamboo, param2=basenode.param2})
	elseif h > 2 then
		core.set_node(top, {name=leaf_bamboo, param2=basenode.param2})
		core.set_node(vector.offset(top,0,-1,0), {name=leaf_bamboo, param2=basenode.param2})
	elseif h > 1 then
		core.set_node(top, {name=leaf_bamboo, param2=basenode.param2})
	end
end

function mcl_bamboo.grow(pos)
	local pr = PcgRandom(core.hash_node_position(pos))
	local max_height = pr:next(12,16)
	local bottom = mcl_util.traverse_tower_group(pos,-1,"bamboo_tree")
	local top,h = mcl_util.traverse_tower_group(bottom,1,"bamboo_tree")

	local light = core.get_node_light(vector.offset(top,0,1,0)) or 0
	if h < max_height and light >= 9 then
		if core.get_node(vector.offset(top,0,1,0)).name ~= "air" then return end
		core.set_node(vector.offset(top,0,1,0), {name=core.get_node(bottom).name})
		mcl_bamboo.check_structure(pos)
	end
end

local bamboo_def = {
	description = S("Bamboo"),
	tiles = {"mcl_bamboo_bamboo.png"},
	drawtype = "mesh",
	mesh = "mcl_bamboo_shoot.obj",
	paramtype = "light",
	paramtype2 = "4dir",
	selection_box = {
		type = "fixed",
		fixed = {
			{-6.4/16, -0.5, -6.4/16, 6.4/16, 0.25, 6.4/16}
		}
	},
	use_texture_alpha = "clip",
	groups = {
		handy=1, axey=1, swordy_bamboo=1, choppy=1,
		dig_by_piston=1, plant=1, non_mycelium_plant=1, flammable=3,
		bamboo=1, bamboo_tree=1, vinelike_node=1, unsticky=1,
		pathfinder_partial=2
	},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	drop = "mcl_bamboo:bamboo",
	inventory_image = "mcl_bamboo_bamboo_inv.png",
	wield_image = "mcl_bamboo_bamboo_inv.png",
	_mcl_burntime = 2.5,
	_mcl_blast_resistance = 1,
	_mcl_hardness = 1,
	node_placement_prediction = "",
	on_place = mcl_util.generate_on_place_plant_function(function(pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		local result = core.get_item_group(node_below.name, "soil_bamboo") > 0 or bamboo_below
		local param2 = bamboo_below and node_below.param2 or mcl_bamboo.random(pos)
		return result, param2
	end),
	after_place_node = function (pos)
		local node_below = core.get_node(vector.offset(pos,0,-1,0))
		local bamboo_below = core.get_item_group(node_below.name, "bamboo_tree") > 0
		if bamboo_below then
			core.swap_node(pos, {name=node_below.name})
			mcl_bamboo.check_structure(pos)
		else
			core.set_node(pos, {name="mcl_bamboo:bamboo_shoot", param2=mcl_bamboo.random(pos)})
		end
	end,
	_on_bone_meal = function(_, _, _, pos)
		return mcl_bamboo.grow(pos)
	end,
}

local cbox_small = {
	type = "fixed",
	fixed = {
		{0.1875, -0.5, -0.3125, 0.3125, 0.5, -0.1875}
	}
}
local cbox_big = {
	type = "fixed",
	fixed = {
		{0.1575, -0.5, -0.3425, 0.3425, 0.5, -0.1575}
	}
}

core.register_node("mcl_bamboo:bamboo_shoot", table.merge_deep(bamboo_def, {
	collision_box = {
		type = "fixed",
		fixed = {{0,0,0,0,0,0}}
	},
	groups = {not_in_creative_inventory=1},
}))
core.register_node("mcl_bamboo:bamboo_small", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "blank.png"},
	groups = {bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_small_leafsmall", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_small_leafbig", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_small.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_big.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=2},
	selection_box = cbox_small,
	collision_box = cbox_small,
}))
core.register_node("mcl_bamboo:bamboo_big", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "blank.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_node("mcl_bamboo:bamboo_big_leafsmall", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_small.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_node("mcl_bamboo:bamboo_big_leafbig", table.merge_deep(bamboo_def, {
	mesh = "mcl_bamboo_big.obj",
	tiles = {"mcl_bamboo_bamboo.png", "mcl_bamboo_leaf_big.png"},
	groups = {not_in_creative_inventory=1, bamboo_tree=3},
	selection_box = cbox_big,
	collision_box = cbox_big,
}))
core.register_alias("mcl_bamboo:bamboo", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_1", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_2", "mcl_bamboo:bamboo_small")
core.register_alias("mcl_bamboo:bamboo_3", "mcl_bamboo:bamboo_small")

mcl_flowerpots.register_potted_cube("mcl_bamboo:bamboo_small", {
	name = "bamboo",
	desc = S("Bamboo Plant"),
	image = "mcl_bamboo_bamboo_fpm.png",
})

core.register_node("mcl_bamboo:bamboo_mosaic",  {
	description = S("Bamboo Mosaic Plank"),
	_doc_items_longdesc = S("Bamboo Mosaic Plank"),
	_doc_items_hidden = false,
	tiles = {"mcl_bamboo_bamboo_plank_mosaic.png"},
	is_ground_content = false,
	groups = {handy = 1, axey = 1, building_block = 1, flammable = 3, fire_encouragement = 5, fire_flammability = 20},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_blast_resistance = 3,
	_mcl_hardness = 2,
	_mcl_burntime = 15
})

mcl_stairs.register_stair("bamboo_mosaic", {
	baseitem = "mcl_bamboo:bamboo_mosaic",
	description = S("Bamboo Mosaic Stairs"),
	overrides = {_mcl_burntime = 15}
})

mcl_stairs.register_slab("bamboo_mosaic", {
	baseitem = "mcl_bamboo:bamboo_mosaic",
	description = S("Bamboo Mosaic Slab"),
	overrides = {_mcl_burntime = 7.5}
})

local adjacents = {
	vector.new(0,0,1),
	vector.new(0,0,-1),
	vector.new(1,0,0),
	vector.new(-1,0,0),
}

local allowed_base_groups = { "solid", "slab_top" }

local function can_place_on(node)
	local def = core.registered_nodes[node.name]

	if not def then
		return false
	end

	for _, j in pairs(allowed_base_groups) do
		if core.get_item_group(node.name, j) > 0 then
			return true
		end
	end

	return false
end

local cid_scaffolding_v
local cid_scaffolding_h
-- based on update_leaves() in https://codeberg.org/mineclonia/mineclonia/src/tag/0.120.1/mods/ITEMS/mcl_trees/api.lua#L73
local function update_scaffolding_horizontal(pos, old_distance)
	local vm = core.get_voxel_manip()
	local emin, emax = vm:read_from_map(pos:offset(-8, -8, -8), pos:offset(8, 8, 8))
	local a = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	local param2_data = vm:get_param2_data()

	local function get_distance(ind)
		local cid = data[ind]
		if cid == cid_scaffolding_v or cid == cid_scaffolding_h then
			return param2_data[ind]
		end
	end

	local updated_data = {}
	local function update_distance(ind, distance, pos)
		param2_data[ind] = distance
		updated_data[ind] = { pos = pos, distance = distance }
	end

	local clear_queue = mcl_util.queue()
	local fill_queue = mcl_util.queue()
	if old_distance then
		clear_queue:enqueue({ pos = pos, distance = old_distance })
	end
	if get_distance(a:indexp(pos)) then
		fill_queue:enqueue({ pos = pos, distance = get_distance(a:indexp(pos)) })
	end

	while clear_queue:size() > 0 do
		local entry = clear_queue:dequeue()
		local pos = entry.pos ---@diagnostic disable-line: need-check-nil
		local distance = entry.distance ---@diagnostic disable-line: need-check-nil

		for _, dir in pairs(adjacents) do
			local pos2 = pos:add(dir)
			local ind2 = a:indexp(pos2)
			local distance2 = get_distance(ind2)
			if distance2 and distance2 <= SCAFFOLD_BASE_AWAY_LIMIT then
				if distance2 > distance then
					if data[ind2] == cid_scaffolding_h then
						update_distance(ind2, SCAFFOLD_BASE_AWAY_LIMIT + 1, pos2)
						clear_queue:enqueue({ pos = pos2, distance = distance + 1 })
					end
				else
					fill_queue:enqueue({ pos = pos2, distance = distance2 })
				end
			end
		end
	end

	while fill_queue:size() > 0 do
		local entry = fill_queue:dequeue()
		local pos = entry.pos ---@diagnostic disable-line: need-check-nil
		local distance2 = entry.distance + 1 ---@diagnostic disable-line: need-check-nil

		for _, dir in pairs(adjacents) do
			local pos2 = pos:add(dir)
			local ind2 = a:indexp(pos2)
			if data[ind2] == cid_scaffolding_h and get_distance(ind2) > distance2 then
				update_distance(ind2, distance2, pos2)
				fill_queue:enqueue({ pos = pos2, distance = distance2 })
			end
		end
	end

	--vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:write_to_map(false)

	return updated_data
end

local function scaffolding_horizontal_falling(pos, node)
	local obj = core.add_entity(pos, "__builtin:falling_node")
	if obj then
		local def = core.registered_nodes[node.name]
		if def and def.sounds and def.sounds.fall then
			core.sound_play(def.sounds.fall, {pos = pos}, true)
		end

		obj:get_luaentity():set_node(node, {})
	end
	core.remove_node(pos)
	core.check_for_falling(vector.offset(pos,0,1,0))
end

local function update_scaffolding(pos, oldnode)
	for _, entry in pairs(update_scaffolding_horizontal(pos, oldnode and oldnode.param2)) do
		if entry.distance > SCAFFOLD_BASE_AWAY_LIMIT then
			scaffolding_horizontal_falling(entry.pos, core.get_node(entry.pos))
		else
			local upos = vector.offset(entry.pos,0,1,0)
			local unode = core.get_node(upos)
			if unode.name == "mcl_bamboo:scaffolding" then
				mcl_util.traverse_tower(upos,1,function(pos, _, node)
					if node.name ~= "mcl_bamboo:scaffolding" then return true end
					core.swap_node(pos, { name = "mcl_bamboo:scaffolding", param2 = entry.distance })
					update_scaffolding(pos, node)
				end)
			end
		end
	end
end

local function after_falling_scaffolding(pos, _)
	local node = core.get_node(pos)

	if node.name == "mcl_bamboo:scaffolding" and node.param2 > SCAFFOLD_BASE_AWAY_LIMIT then
		-- don't drop if fallen after placing
		mcl_util.safe_place(pos, {name = "mcl_bamboo:scaffolding"})
	else
		mcl_util.safe_place(pos, {name = "air"})
		core.add_item(pos,"mcl_bamboo:scaffolding")
	end
end

local scaffolding_def = {
	_doc_items_hidden = false,
	tiles = {"mcl_bamboo_scaffolding_top.png", "mcl_bamboo_scaffolding_top.png", "mcl_bamboo_scaffolding_side.png"},
	drawtype = "nodebox",
	paramtype = "light",
	use_texture_alpha = "clip",
	drop = "mcl_bamboo:scaffolding",
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},
	is_ground_content = false,
	walkable = true,
	climbable = true,
	physical = true,
	groups = { handy = 1, axey = 1, flammable = 3,  material_wood = 1, fire_encouragement = 5, fire_flammability = 60, solid = 1, scaffolding = 1, dig_by_piston = 1, unsticky = 1 },
	sounds = mcl_sounds.node_sound_wood_defaults(),
	after_destruct = update_scaffolding,
	_mcl_after_falling = after_falling_scaffolding,
}

core.register_node("mcl_bamboo:scaffolding", table.merge_deep(scaffolding_def , {
	description = S("Scaffolding"),
	_doc_items_longdesc = S("Scaffolding is a temporary structure to easily climb up while building that is easily removed"),
	tiles = {"mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_side.png"},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, -0.375, 0.5, -0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, -0.375},
			{0.375, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, 0.375, -0.375, 0.5, 0.5},
		}
	},
	node_placement_prediction = "",
	groups = { deco_block = 1, falling_node = 1 },
	_mcl_hardness = 0,
	_mcl_burntime = 2.5,
	on_place = function(itemstack, placer, ptd)
		if not placer or not placer:is_player() then
			return itemstack
		end

		local rc = mcl_util.call_on_rightclick(itemstack, placer, ptd)
		if rc then return rc end
		if not ptd then return end
		local node = core.get_node(ptd.under)
		local pos = ptd.above
		local to_place
		local dist

		if core.get_item_group(node.name, "scaffolding") ~= 0 then
			dist = node.param2

			local ctrl = placer:get_player_control()
			local arc = placer:get_look_vertical() * (180 / math.pi)

			if ctrl and ctrl.sneak and ptd.under.y == ptd.above.y then
				-- place sideways
				to_place = "mcl_bamboo:scaffolding_horizontal"
				dist = dist + 1
			elseif arc > 45 and arc < 90 and ptd.under.y ~= ptd.above.y then
				to_place = "mcl_bamboo:scaffolding_horizontal"
				local fourdir = core.dir_to_fourdir(placer:get_look_dir())
				local offset_z = fourdir % 2 == 0 and 0 - (fourdir -1) or 0
				local offset_x = fourdir % 2 ~= 0 and 2 - fourdir or 0

				pos = ptd.under
				dist = dist + 1
				-- extend scaffolding_horizontal
				while dist <= SCAFFOLD_BASE_AWAY_LIMIT
					and core.get_item_group(node.name, "scaffolding") ~= 0 do
					local next_pos = vector.offset(pos, offset_x, 0, offset_z)
					local next_node = core.get_node(next_pos)
					if next_node.name ~= "air" and core.get_item_group(next_node.name, "scaffolding") == 0 then
					    break
					end
					dist = node.param2 + 1
					pos = next_pos
					node = next_node
				end
			else
				to_place = "mcl_bamboo:scaffolding"
				-- tower up scaffolding (vertical)
				if node.name == "mcl_bamboo:scaffolding" then
					local top = mcl_util.traverse_tower(ptd.under,1)
					pos = vector.offset(top,0,1,0)
				end
			end
		elseif can_place_on(node) then
			to_place = "mcl_bamboo:scaffolding"
			-- param2 > SCAFFOLD_BASE_AWAY_LIMIT: don't drop if it falls after placing
			dist = SCAFFOLD_BASE_AWAY_LIMIT + 1
		end

		if to_place and core.get_node(pos).name == "air" then
			local force_vertical = dist > SCAFFOLD_BASE_AWAY_LIMIT
			local name = force_vertical and "mcl_bamboo:scaffolding" or to_place
			itemstack = mcl_util.safe_place(pos, {name = name, param2 = dist }, placer, itemstack) or itemstack
			if not core.check_single_for_falling(pos) then
				if force_vertical then
					core.swap_node(pos, { name = name })
				end
				local def = core.registered_nodes[name]
				if def and def.sounds and def.sounds.place then
					core.sound_play(def.sounds.place, {pos = pos}, true)
				end
				update_scaffolding(pos)
			end
		end

		return itemstack
	end,
}))

core.register_node("mcl_bamboo:scaffolding_horizontal", table.merge_deep(scaffolding_def, {
	tiles = {"mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_top.png","mcl_bamboo_scaffolding_side.png"},
	drawtype = "nodebox",
	paramtype = "light",
	use_texture_alpha = "clip",
	drop = "mcl_bamboo:scaffolding",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, -0.375, 0.5, -0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, -0.375},
			{0.375, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, 0.375, -0.375, 0.5, 0.5},
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
		}
	},
	groups = { building_block = 1, not_in_creative_inventory = 1, disable_descend = 1 },
}))

cid_scaffolding_v = core.get_content_id("mcl_bamboo:scaffolding")
cid_scaffolding_h = core.get_content_id("mcl_bamboo:scaffolding_horizontal")
