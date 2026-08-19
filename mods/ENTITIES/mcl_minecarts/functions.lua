function mcl_minecarts:get_sign(z)
	if z == 0 then
		return 0
	else
		return z / math.abs(z)
	end
end

function mcl_minecarts:velocity_to_dir(v)
	if math.abs(v.x) > math.abs(v.z) then
		return {x=mcl_minecarts:get_sign(v.x), y=mcl_minecarts:get_sign(v.y), z=0}
	else
		return {x=0, y=mcl_minecarts:get_sign(v.y), z=mcl_minecarts:get_sign(v.z)}
	end
end

function mcl_minecarts:is_rail(pos, railtype)
	local node = core.get_node(pos).name
	if node == "ignore" then
		local vm = core.get_voxel_manip()
		local emin, emax = vm:read_from_map(pos, pos)
		local area = VoxelArea:new{
			MinEdge = emin,
			MaxEdge = emax,
		}
		local data = vm:get_data()
		local vi = area:indexp(pos)
		node = core.get_name_from_content_id(data[vi])
	end
	if core.get_item_group(node, "rail") == 0 then
		return false
	end
	if not railtype then
		return true
	end
	return core.get_item_group(node, "connect_to_raillike") == railtype
end

function mcl_minecarts:check_front_up_down(pos, dir_, check_down, railtype)
	local dir = vector.new(dir_)
	-- Front
	dir.y = 0
	local cur = vector.add(pos, dir)
	if mcl_minecarts:is_rail(cur, railtype) then
		return dir
	end
	-- Up
	if check_down then
		dir.y = 1
		cur = vector.add(pos, dir)
		if mcl_minecarts:is_rail(cur, railtype) then
			return dir
		end
	end
	-- Down
	dir.y = -1
	cur = vector.add(pos, dir)
	if mcl_minecarts:is_rail(cur, railtype) then
		return dir
	end
	return nil
end

function mcl_minecarts:get_rail_direction(pos_, dir, ctrl, old_switch, railtype)
	local pos = vector.round(pos_)
	local cur
	local left_check, right_check = true, true

	-- Check left and right
	local left = {x=0, y=0, z=0}
	local right = {x=0, y=0, z=0}
	if dir.z ~= 0 and dir.x == 0 then
		left.x = -dir.z
		right.x = dir.z
	elseif dir.x ~= 0 and dir.z == 0 then
		left.z = dir.x
		right.z = -dir.x
	end

	if ctrl then
		if old_switch == 1 then
			left_check = false
		elseif old_switch == 2 then
			right_check = false
		end
		if ctrl.left and left_check then
			cur = mcl_minecarts:check_front_up_down(pos, left, false, railtype)
			if cur then
				return cur, 1
			end
			left_check = false
		end
		if ctrl.right and right_check then
			cur = mcl_minecarts:check_front_up_down(pos, right, false, railtype)
			if cur then
				return cur, 2
			end
			right_check = false
		end
	end

	-- Normal
	cur = mcl_minecarts:check_front_up_down(pos, dir, true, railtype)
	if cur then
		return cur
	end

	-- Left, if not already checked
	if left_check then
		cur = mcl_minecarts:check_front_up_down(pos, left, false, railtype)
		if cur then
			return cur
		end
	end

	-- Right, if not already checked
	if right_check then
		cur = mcl_minecarts:check_front_up_down(pos, right, false, railtype)
		if cur then
			return cur
		end
	end
	-- Backwards
	if not old_switch then
		cur = mcl_minecarts:check_front_up_down(pos, {
				x = -dir.x,
				y = dir.y,
				z = -dir.z
			}, true, railtype)
		if cur then
			return cur
		end
	end
	return {x=0, y=0, z=0}
end

local plane_adjacents = {
	vector.new(-1,0,0),
	vector.new(1,0,0),
	vector.new(0,0,-1),
	vector.new(0,0,1),
}

function mcl_minecarts:get_start_direction(pos)
	local dir
	local i = 0
	while (not dir and i < #plane_adjacents) do
		i = i+1
		local node = core.get_node_or_nil(vector.add(pos, plane_adjacents[i]))
		if node ~= nil
		and core.get_item_group(node.name, "rail") == 0
		and core.get_item_group(node.name, "solid") == 1
		and core.get_item_group(node.name, "opaque") == 1
		then
			dir = mcl_minecarts:check_front_up_down(pos, vector.multiply(plane_adjacents[i], -1), true)
		end
	end
	return dir
end

function mcl_minecarts:set_velocity(obj, dir, factor)
	obj._velocity = vector.multiply(dir, factor or 3)
	obj._old_pos = nil
	obj._punched = true
end

-- ---------------------------------------------------------------------------
-- Train system: minecarts couple to each other and are hauled by a locomotive
-- (the locomotive), which sits at the head of the train.
-- ---------------------------------------------------------------------------

local train_S = core.get_translator(core.get_current_modname())

function mcl_minecarts:show_direction_feedback(le, player, dir)
	if not player then return end
	local text
	if dir > 0 then
		text = train_S("Train: forward")
	elseif dir < 0 then
		text = train_S("Train: backward")
	else
		text = train_S("Train: stopped")
	end
	mcl_title.set(player, "actionbar", {text=text, color="white", stay=40})
end

function mcl_minecarts:is_minecart(le)
	return le ~= nil and type(le.name) == "string"
		and le.name:sub(1, #"mcl_minecarts:") == "mcl_minecarts:"
end

function mcl_minecarts:is_train_member(le)
	return mcl_minecarts:is_minecart(le) and le._train_id ~= nil
end

-- The locomotive of a train. le is the locomotive itself if it has train index
-- 0; a follower re-finds the locomotive through its cached object reference or
-- a short scan by train id (needed after a world load, when object references
-- are not persisted).
function mcl_minecarts:find_train_head(le)
	if not le or not le.object then return nil end
	if (le._train_index or 0) == 0 then return le end
	if le._train_head and le._train_head:is_valid() then
		local h = le._train_head:get_luaentity()
		if h and h._train_id == le._train_id then return h end
	end
	if not le._train_id then return nil end
	local pos = le.object:get_pos()
	if not pos then return nil end
	for obj in core.objects_inside_radius(pos, 8) do
		local e = obj:get_luaentity()
		if e and e ~= le and e._train_id == le._train_id
				and (e._train_index or 0) == 0 then
			le._train_head = obj
			return e
		end
	end
	return nil
end

-- All carts of the train that le belongs to (the locomotive first).
function mcl_minecarts:get_train_carts(le)
	local head = mcl_minecarts:find_train_head(le)
	if not head then return {} end
	local carts = {head}
	local pos = head.object:get_pos()
	local tid = head._train_id
	if not pos or not tid then return carts end
	for obj in core.objects_inside_radius(pos, 8) do
		local e = obj:get_luaentity()
		if e and e ~= head and e._train_id == tid and e.object then
			carts[#carts + 1] = e
		end
	end
	return carts
end

-- The rearmost cart of the train (or the locomotive itself if it is alone).
function mcl_minecarts:find_train_tail(le)
	local best, best_idx = nil, -1
	for _, e in ipairs(mcl_minecarts:get_train_carts(le)) do
		local idx = e._train_index or 0
		if idx > best_idx then
			best, best_idx = e, idx
		end
	end
	return best
end

local function new_train_id()
	return tostring(core.get_us_time()) .. "_" .. math.random(1000, 999999)
end

-- Walk `steps` rail nodes backwards from pos, following the rail. dir is the
-- locomotive's last rail direction (the direction the train faces); the walk
-- starts from it reversed, so followers trail the locomotive on the same
-- track. Returns the position of the node reached and the rail direction at
-- that node, or nil when the rail ends (the follower stays put).
function mcl_minecarts:get_rail_node_back(pos, dir, steps, railtype)
	if not pos or not dir then return nil end
	local cur = vector.round(pos)
	local railtype = railtype or "default_rail"
	local back = {x = -dir.x, y = dir.y, z = -dir.z}
	local node_dir = dir
	for i = 1, (steps or 0) do
		-- old_switch=3 keeps the left/right corner checks but disables the
		-- backwards fallback, so the walk cannot double back on itself.
		node_dir = mcl_minecarts:get_rail_direction(cur, back, nil, 3, railtype)
		if not node_dir or vector.equals(node_dir, {x=0, y=0, z=0}) then
			return nil
		end
		cur = vector.add(cur, node_dir)
	end
	return {pos = cur, dir = node_dir}
end

-- Place a follower (a train cart that runs no physics of its own) on
-- the rail node `le._train_index` nodes behind the locomotive, once per tick.
-- Uses _forward_dir so the physical order stays the same when reversing
-- (the locomotive pushes the wagons).  Position is interpolated for smooth
-- visual movement instead of teleporting.
function mcl_minecarts:place_follower(le, dtime)
	local head = mcl_minecarts:find_train_head(le)
	if not head or not head.object then return end
	if not (le._train_index and le._train_index >= 1) then return end
	local hpos = head.object:get_pos()
	if not hpos then return end

	-- When the locomotive has stopped, keep followers at their current
	-- positions so braking distance is preserved.
	local hvel = head.object:get_velocity()
	if hvel and math.abs(hvel.x) + math.abs(hvel.z) < 0.1 then
		return
	end

	-- Always trail behind the forward direction so the physical layout
	-- doesn't flip when the train reverses.
	local hdir = head._forward_dir or head._last_move_dir
	if not hdir then return end

	-- Walk the base number of nodes, then interpolate 40 % toward the
	-- next node so the gap is wider than one rail segment.
	local base_steps = le._train_index
	local step_a = mcl_minecarts:get_rail_node_back(hpos, hdir, base_steps, le._railtype)
	if not step_a then return end
	local step_b = mcl_minecarts:get_rail_node_back(hpos, hdir, base_steps + 1, le._railtype)
	local step
	if step_b then
		local f = 0.4
		step = {
			pos = {
				x = step_a.pos.x + (step_b.pos.x - step_a.pos.x) * f,
				y = step_a.pos.y + (step_b.pos.y - step_a.pos.y) * f,
				z = step_a.pos.z + (step_b.pos.z - step_a.pos.z) * f,
			},
			dir = step_a.dir,
		}
	else
		step = step_a
	end

	-- Smooth interpolation: lerp toward the target position.  Snap
	-- directly when the distance is large (e.g. first couple or after
	-- a world load) to avoid a long visible slide.
	local current = le.object:get_pos()
	if current then
		local dist = vector.distance(current, step.pos)
		if dist > 2 then
			le.object:set_pos(step.pos)
		else
			local t = math.min((dtime or 0.05) * 15, 1)
			le.object:set_pos({
				x = current.x + (step.pos.x - current.x) * t,
				y = current.y + (step.pos.y - current.y) * t,
				z = current.z + (step.pos.z - current.z) * t,
			})
		end
	else
		le.object:set_pos(step.pos)
	end

	-- Compute yaw from the rail direction at the follower's position,
	-- matching the locomotive's rotation logic.
	local dir = step.dir
	if dir then
		local yaw = 0
		if dir.x < 0 then
			yaw = 0.5
		elseif dir.x > 0 then
			yaw = 1.5
		elseif dir.z < 0 then
			yaw = 1
		end
		local yaw_rad = yaw * math.pi
		local target_pitch = 0
		if dir.y ~= 0 then
			target_pitch = dir.y * (math.pi / 4)
		end
		le.object:set_rotation(vector.new(target_pitch, yaw_rad, 0))
	end

	le.object:set_velocity(vector.new())
	le.object:set_acceleration(vector.new())
	le._old_pos = vector.new(step.pos)
	le._old_vel = vector.new()
end

-- Assign _train_id / _train_index to the free cart child_le, appended to the
-- train of parent_le (which may be the locomotive or any follower).
function mcl_minecarts:append_cart(parent_le, child_le)
	if not parent_le or not child_le or parent_le == child_le then return false end
	if not parent_le.object or not child_le.object then return false end

	local tid = parent_le._train_id
	if not tid then
		tid = new_train_id()
		parent_le._train_id = tid
		parent_le._train_index = 0
	end
	child_le._train_id = tid
	child_le._train_index = (parent_le._train_index or 0) + 1
	child_le._train_head = parent_le._train_index == 0 and parent_le.object or nil
	child_le.object:set_velocity(vector.new())
	child_le.object:set_acceleration(vector.new())
	child_le._old_pos = nil
	child_le._old_vel = nil

	local pos = parent_le.object:get_pos()
	if pos then
		core.sound_play("mcl_minecarts_couple", {pos=pos, gain=0.8, max_hear_distance=12}, true)
	end
	return true
end

-- A free cart bumped into another cart: decide the new train arrangement.
-- The furnace is always the head of the train (index 0); every other cart
-- becomes a follower that rides on a fixed rail node behind the head.
function mcl_minecarts:try_couple(free_le, target_le)
	if free_le.name == "mcl_minecarts:furnace_minecart" then
		-- Furnace bumps into a train: it takes over as the head, but only when
		-- it is actually touching the head (not the tail of a long train).
		if mcl_minecarts:is_train_member(target_le) then
			local old_head = mcl_minecarts:find_train_head(target_le)
			local hpos = old_head and old_head.object:get_pos()
			local fpos = free_le.object:get_pos()
			if hpos and fpos and vector.distance(hpos, fpos) <= 1.9 then
				if mcl_minecarts:append_cart(free_le, old_head) then
					-- old_head (and every follower behind it) now trails the
					-- new furnace by one extra node.
					local carts = mcl_minecarts:get_train_carts(free_le)
					for _, e in ipairs(carts) do
						if e ~= free_le then
							e._train_head = free_le.object
						end
					end
					return true
				end
			end
			return false
		end
		return mcl_minecarts:append_cart(free_le, target_le)
	end

	-- A free cart bumps into a train: it only attaches at the tail, and only
	-- when it is right behind that tail.
	local tail = nil
	if mcl_minecarts:is_train_member(target_le) then
		tail = mcl_minecarts:find_train_tail(target_le)
	end
	if tail then
		local tpos = tail.object:get_pos()
		local fpos = free_le.object:get_pos()
		if tpos and fpos and vector.distance(tpos, fpos) <= 1.9 then
			return mcl_minecarts:append_cart(tail, free_le)
		end
		return false
	end

	-- Both free: the furnace becomes the head, the other cart trails it.
	if free_le.name == "mcl_minecarts:furnace_minecart"
			or target_le.name == "mcl_minecarts:furnace_minecart" then
		if target_le.name == "mcl_minecarts:furnace_minecart" then
			return mcl_minecarts:append_cart(target_le, free_le)
		end
		return mcl_minecarts:append_cart(free_le, target_le)
	end

	-- Two free plain carts: couple them anyway (head is the first one).
	return mcl_minecarts:append_cart(free_le, target_le)
end

-- Detach the rearmost cart of the train (sneak-punch). Returns true when a
-- follower was detached; a lone locomotive returns false (it stays a train).
function mcl_minecarts:uncouple_last_cart(le)
	local head = mcl_minecarts:find_train_head(le)
	if not head then return false end
	local tail = mcl_minecarts:find_train_tail(head)
	if not tail or tail == head then return false end
	tail._train_id = nil
	tail._train_index = nil
	tail._train_head = nil
	tail.object:set_velocity(vector.new())
	tail.object:set_acceleration(vector.new())
	tail._old_pos = nil
	tail._old_vel = nil
	local pos = tail.object:get_pos()
	if pos then
		core.sound_play("mcl_minecarts_uncouple", {pos=pos, gain=0.8, max_hear_distance=12}, true)
	end
	return true
end

-- Remove le from its train. Removing the locomotive frees every follower;
-- removing a follower re-indexes the ones behind it.
function mcl_minecarts:remove_cart_from_train(le)
	if not le or not le.object then return end
	local tid = le._train_id
	local idx = le._train_index or 0
	le._train_id = nil
	le._train_index = nil
	le._train_head = nil
	le._old_pos = nil
	le.object:set_velocity(vector.new())
	le.object:set_acceleration(vector.new())
	if not tid then return end

	if idx == 0 then
		-- Locomotive removed: the whole train breaks into free carts.
		local pos = le.object:get_pos()
		if pos then
			for obj in core.objects_inside_radius(pos, 8) do
				local e = obj:get_luaentity()
				if e and e ~= le and e._train_id == tid then
					e._train_id = nil
					e._train_index = nil
					e._train_head = nil
					e._old_pos = nil
					e.object:set_velocity(vector.new())
					e.object:set_acceleration(vector.new())
				end
			end
		end
		return
	end

	-- A follower removed: followers behind it move one node closer to the head.
	local head = mcl_minecarts:find_train_head(le)
	if head then
		local pos = head.object:get_pos()
		if pos then
			for obj in core.objects_inside_radius(pos, 8) do
				local e = obj:get_luaentity()
				if e and e ~= le and e._train_id == tid
						and (e._train_index or 0) > idx then
					e._train_index = (e._train_index or 0) - 1
				end
			end
		end
	end
end

-- Find another minecart near scan_pos (the le's visual position) that is
-- touching it and could be coupled (same raillike, aligned with le, reachable
-- along the rail). When exclude_train is set, train members are skipped (used
-- by the train tail, which only picks up free carts).
function mcl_minecarts:get_coupling_target(le, scan_pos, exclude_train)
	if not le._railtype then return nil end
	local pos = scan_pos or le.object:get_pos()
	if not pos then return nil end
	local best, best_dist = nil, nil
	for obj in core.objects_inside_radius(pos, 1.9) do
		local e = obj:get_luaentity()
		if e and e ~= le and e._railtype and e._railtype == le._railtype
				and not e._boomtimer and not (exclude_train and e._train_id) then
			local opos = e.object:get_pos()
			if opos then
				local dx = opos.x - pos.x
				local dz = opos.z - pos.z
				if math.abs(dx) < 0.05 or math.abs(dz) < 0.05 then
					local dist = math.abs(dx) + math.abs(dz)
					if dist > 0.25 and dist < 1.5 and math.abs(opos.y - pos.y) < 1.5 then
						local dir = {x = mcl_minecarts:get_sign(dx), y = 0, z = mcl_minecarts:get_sign(dz)}
						local rpos = vector.round(pos)
						if mcl_minecarts:check_front_up_down(rpos, dir, true, le._railtype) then
							if not best_dist or dist < best_dist then
								best = e
								best_dist = dist
							end
						end
					end
				end
			end
		end
	end
	return best
end

-- Followers are positioned by the locomotive every tick, so no spacing
-- controller is needed: they can never drift into each other or the head.

-- Toggle the direction of the whole train. key > 0 = W (up), key < 0 = S (down).
-- forward ->(S)-> stop ->(S)-> backward ->(W)-> stop ->(W)-> forward.
-- Only the locomotive stores _train_dir; followers don't carry direction at all.
function mcl_minecarts:handle_direction_key(le, key)
	local head = mcl_minecarts:find_train_head(le)
	if not head then return 0 end
	local dir = head._train_dir or 0
	local new_dir = dir
	if key > 0 then
		if dir == -1 then new_dir = 0
		elseif dir == 0 then new_dir = 1 end
	else
		if dir == 1 then new_dir = 0
		elseif dir == 0 then
			-- Reverse only from a full stop.
			local hvel = head.object:get_velocity()
			if hvel and math.abs(hvel.x) + math.abs(hvel.z) > 0.5 then
				return dir
			end
			new_dir = -1
		end
	end
	if new_dir ~= dir then
		head._train_dir = new_dir
		if new_dir == -1 and head._forward_dir then
			-- Kick the locomotive backward along the reverse of the forward dir.
			local hint = vector.multiply(head._forward_dir, -1)
			local pos = head.object:get_pos()
			if pos then
				local start_dir = mcl_minecarts:get_rail_direction(pos, hint, nil, 0, head._railtype)
				if start_dir and not vector.equals(start_dir, {x=0, y=0, z=0}) then
					head.object:set_velocity(vector.multiply(start_dir, 3))
				end
			end
		elseif new_dir == 0 then
			head.object:set_velocity(vector.new())
		end
	end
	return new_dir
end

-- Return the player controls of the first driver found anywhere in the
-- train (head first, then followers).  The furnace minecart's right-click
-- opens the fuel GUI instead of attaching a player, so drivers typically
-- sit in follower carts.
function mcl_minecarts:find_driver_ctrl(le)
	local head = mcl_minecarts:find_train_head(le)
	if not head then return nil end
	if head._driver then
		local p = core.get_player_by_name(head._driver)
		if p then return p:get_player_control() end
	end
	for _, cart in ipairs(mcl_minecarts:get_train_carts(head)) do
		if cart ~= head and cart._driver then
			local p = core.get_player_by_name(cart._driver)
			if p then return p:get_player_control() end
		end
	end
	return nil
end

-- ============ Minecart furnace (locomotive) fuel interface ============
--
-- The furnace minecart ("locomotive") gets a furnace-style GUI with a single
-- fuel slot. Fuel from that slot is drawn into the burner only while the cart
-- is actually moving (or, as the head of a train, commanded to move by a
-- driver), so a parked train does not waste its fuel.

local FURNACE_INV_PREFIX = "mcl_minecarts_furnace_"

-- Return the detached inventory holding the furnace fuel slot (1 item).
function mcl_minecarts:furnace_inv(le)
	if not le._fuel_inv_id then
		le._fuel_inv_id = FURNACE_INV_PREFIX ..
			core.sha1(core.get_gametime() .. core.pos_to_string(le.object:get_pos()) .. tostring(math.random()))
	end
	local inv = core.get_inventory({type = "detached", name = le._fuel_inv_id})
	if not inv then
		inv = core.create_detached_inventory(le._fuel_inv_id, {
			allow_put = function(_, _, _, stack, player)
				if not mcl_util.is_fuel(stack) then return 0 end
				return mcl_minecarts:furnace_inv_distance(le, player, stack:get_count())
			end,
			allow_take = function(_, _, _, stack, player)
				return mcl_minecarts:furnace_inv_distance(le, player, stack:get_count())
			end,
			allow_move = function(_, _, _, _, _, count, player)
				return mcl_minecarts:furnace_inv_distance(le, player, count)
			end,
			on_put = function() mcl_minecarts:save_fuel_slot(le) end,
			on_take = function() mcl_minecarts:save_fuel_slot(le) end,
			on_move = function() mcl_minecarts:save_fuel_slot(le) end,
		})
		inv:set_size("fuel", 1)
		if le._fuel_item then
			inv:set_stack("fuel", 1, le._fuel_item)
		end
		le._fuel_inv = inv
	end
	return inv
end

function mcl_minecarts:furnace_inv_distance(le, player, count)
	if not player then return 0 end
	local ppos = player:get_pos()
	local epos = le.object:get_pos()
	if not ppos or not epos then return 0 end
	if vector.distance(ppos, epos) > 5 then return 0 end
	return count
end

-- Sync the persistent fuel field from the (possibly open) inventory.
function mcl_minecarts:save_fuel_slot(le)
	if not le._fuel_inv then return end
	local st = le._fuel_inv:get_stack("fuel", 1)
	le._fuel_item = st:is_empty() and nil or st:to_string()
end

-- Return the item currently sitting in the fuel slot (itemstring or nil).
function mcl_minecarts:get_fuel_stack(le)
	if le._fuel_item then return le._fuel_item end
	if le._fuel_inv then
		local st = le._fuel_inv:get_stack("fuel", 1)
		if not st:is_empty() then return st:to_string() end
	end
	return nil
end

-- Draw the next fuel item from the furnace slot into the burner. Returns
-- true if the burner has fuel afterwards.
function mcl_minecarts:refill_fuel(le)
	if le.name ~= "mcl_minecarts:furnace_minecart" then
		return le._fueltime and le._fueltime > 0
	end
	if le._fueltime and le._fueltime > 0 then return true end
	local inv = mcl_minecarts:furnace_inv(le)
	local st = inv:get_stack("fuel", 1)
	if st:is_empty() then return false end
	local burn = mcl_util.get_burntime(st)
	if burn <= 0 then
		inv:set_stack("fuel", 1, ItemStack(""))
		mcl_minecarts:save_fuel_slot(le)
		return false
	end
	st:take_item(1)
	inv:set_stack("fuel", 1, st)
	le._fueltime = burn
	le._fuel_totaltime = burn
	mcl_minecarts:save_fuel_slot(le)
	return true
end

-- Furnace-style formspec: fuel slot + burning fire + player inventory.
function mcl_minecarts:furnace_cart_formspec(le)
	local burning = le._fueltime and le._fueltime > 0
	local fuel_percent = 0
	if burning and le._fuel_totaltime and le._fuel_totaltime > 0 then
		fuel_percent = math.floor(math.min(le._fueltime / le._fuel_totaltime, 1) * 100)
	end
	local fire
	if burning then
		fire = "default_furnace_fire_bg.png^[lowpart:" .. (100 - fuel_percent) .. ":default_furnace_fire_fg.png"
	else
		fire = "default_furnace_fire_bg.png"
	end
	return table.concat({
		"formspec_version[4]",
		"size[11.75,10.425]",
		"label[0.375,0.375;" .. core.formspec_escape(core.colorize(mcl_formspec.label_color, train_S("Locomotive"))) .. "]",
		"image[3.5,2;1,1;" .. fire .. "]",
		mcl_formspec.get_itemslot_bg_v4(3.5, 3.25, 1, 1),
		"list[detached:" .. le._fuel_inv_id .. ";fuel;3.5,3.25;1,1;]",
		"label[0.375,4.7;" .. core.formspec_escape(core.colorize(mcl_formspec.label_color, train_S("Inventory"))) .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		"listring[detached:" .. le._fuel_inv_id .. ";fuel]",
		"listring[current_player;main]",
	})
end

-- Open the fuel GUI for a player and start tracking them as a viewer.
function mcl_minecarts:show_furnace_cart_inv(le, player)
	mcl_minecarts:furnace_inv(le)
	le._inv_viewers = le._inv_viewers or {}
	le._inv_viewers[player:get_player_name()] = true
	le._fuel_refresh = 0
	core.show_formspec(player:get_player_name(), le._fuel_inv_id,
		mcl_minecarts:furnace_cart_formspec(le))
end
