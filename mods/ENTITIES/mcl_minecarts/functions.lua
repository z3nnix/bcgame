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
			right_check = true
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
-- (the minecart with furnace), which sits at the head of the train.
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

-- Walk the attachment chain towards the head of the train.
function mcl_minecarts:find_train_head(le)
	local current = le
	local guard = 0
	while current and current._train_parent and guard < 64 do
		local p = current._train_parent:get_luaentity()
		if not p or not p._train_id then break end
		current = p
		guard = guard + 1
	end
	return current
end

-- Walk the attachment chain towards the tail of the train.
function mcl_minecarts:find_train_tail(le)
	local current = le
	local guard = 0
	while current and current._train_child and guard < 64 do
		local c = current._train_child:get_luaentity()
		if not c or not c._train_id then break end
		current = c
		guard = guard + 1
	end
	return current
end

-- After a world load a member's stored position is its real position (train
-- carts are free-standing now); locate the parent cart it must follow again.
function mcl_minecarts:find_train_parent(le)
	local pos = le.object:get_pos()
	if not pos or not le._train_id then return nil end
	local wanted = (le._train_index or 0) - 1
	for obj in core.objects_inside_radius(pos, 3) do
		local e = obj:get_luaentity()
		if e and e ~= le and e._train_id == le._train_id
				and e._train_index == wanted then
			return e
		end
	end
	return nil
end

-- Assign _train_id / _train_dir / _train_index to a whole sub-chain (starting
-- at le, following children). base_index is the index of le itself.
function mcl_minecarts:set_train_chain(le, id, dir, base_index)
	local current = le
	local index = base_index or 0
	local guard = 0
	while current and guard < 128 do
		current._train_id = id
		current._train_dir = dir
		current._train_index = index
		index = index + 1
		current = current._train_child and current._train_child:get_luaentity()
		guard = guard + 1
	end
end

-- Assign _train_dir to a whole sub-chain.
function mcl_minecarts:set_train_dir_recursive(le, dir)
	local current = le
	local guard = 0
	while current and guard < 128 do
		current._train_dir = dir
		current = current._train_child and current._train_child:get_luaentity()
		guard = guard + 1
	end
end

local function new_train_id()
	return tostring(core.get_us_time()) .. "_" .. math.random(1000, 999999)
end

-- Train carts are free-standing now (each runs its own rail physics), so the
-- visual position of a cart is simply its real position.
function mcl_minecarts:get_attached_world_pos(le)
	if not le or not le.object then return nil end
	return le.object:get_pos()
end

-- Couple two carts: parent is in front, child is coupled behind it. Each cart
-- keeps running its own rail physics; the spacing between them is maintained
-- by the coupling controller in coupling_accel().
function mcl_minecarts:couple_carts(parent_le, child_le)
	if not parent_le or not child_le or parent_le == child_le then return false end
	if not parent_le.object or not child_le.object then return false end
	if child_le._train_parent and child_le._train_parent == parent_le.object then
		return true
	end

	local tid = parent_le._train_id
	if not tid then
		tid = new_train_id()
		parent_le._train_id = tid
		parent_le._train_index = 0
		parent_le._train_dir = parent_le._train_dir or 0
	end
	local train_dir = parent_le._train_dir or 0
	parent_le._train_index = parent_le._train_index or 0
	child_le.object:set_velocity(vector.new())
	child_le.object:set_acceleration(vector.new())
	child_le._train_parent = parent_le.object
	child_le._old_pos = nil
	child_le._old_vel = nil
	parent_le._train_child = child_le.object
	mcl_minecarts:set_train_chain(child_le, tid, train_dir, (parent_le._train_index or 0) + 1)

	local pos = parent_le.object:get_pos()
	if pos then
		core.sound_play("mcl_minecarts_couple", {pos=pos, gain=0.8, max_hear_distance=12}, true)
	end
	return true
end

-- Detach le from the cart in front of it. The sub-chain behind le stays coupled.
function mcl_minecarts:uncouple_cart(le)
	if not le or not le.object then return end
	local parent_obj = le._train_parent
	le._train_parent = nil
	le.object:set_velocity(vector.new())
	le.object:set_acceleration(vector.new())
	if le._train_child then
		mcl_minecarts:set_train_chain(le, new_train_id(), 0, 0)
	else
		le._train_id = nil
		le._train_dir = 0
	end
	le._train_index = nil
	-- If the cart in front now has no carts behind it, it is a lone cart again.
	if parent_obj then
		local pele = parent_obj:get_luaentity()
		if pele then
			pele._train_child = nil
			if not pele._train_parent and not pele._train_child then
				pele._train_id = nil
				pele._train_dir = 0
			end
		end
	end
	le._old_pos = nil
	local pos = le.object:get_pos()
	if pos then
		core.sound_play("mcl_minecarts_uncouple", {pos=pos, gain=0.8, max_hear_distance=12}, true)
	end
end

-- Detach the whole sub-chain behind le (used when le itself is removed).
function mcl_minecarts:detach_children(le)
	local child_obj = le._train_child
	le._train_child = nil
	if not child_obj then return end
	local child = child_obj:get_luaentity()
	if not child then return end
	child._train_parent = nil
	child.object:set_velocity(vector.new())
	child.object:set_acceleration(vector.new())
	if child._train_child then
		mcl_minecarts:set_train_chain(child, new_train_id(), 0, 0)
	else
		child._train_id = nil
	end
	child._train_index = nil
	child._train_dir = 0
	child._old_pos = nil
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
			local opos = mcl_minecarts:get_attached_world_pos(e)
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

-- Safety net: the cart in front of a member disappeared without the normal
-- removal path clearing our links (stale object references, e.g. after an
-- unload). The member (and any carts behind it) become their own train.
function mcl_minecarts:release_member(le)
	if not le or not le.object then return end
	local parent_obj = le._train_parent
	le._train_parent = nil
	le._train_index = nil
	if le._train_child then
		mcl_minecarts:set_train_chain(le, new_train_id(), 0, 0)
	else
		le._train_id = nil
		le._train_dir = 0
	end
	if parent_obj then
		local pele = parent_obj:get_luaentity()
		if pele and pele._train_child == le.object then
			pele._train_child = nil
			if not pele._train_parent and not pele._train_child then
				pele._train_id = nil
				pele._train_dir = 0
			end
		end
	end
	le._old_pos = nil
	le.object:set_velocity(vector.new())
	le.object:set_acceleration(vector.new())
end

-- Acceleration controller for a coupled member: it keeps exactly train_spacing
-- nodes behind its parent and matches the parent's speed. Each cart runs its
-- own rail physics; this only adds a correction to the member's acceleration.
-- dir is the member's rail direction (may be non-unit on slopes), vel its
-- current velocity.
--
-- The correction is applied as a VECTOR along the line between the carts,
-- based on the RELATIVE velocity along that line. Too close -> the member is
-- pushed away from the parent, too far -> it is pulled back. Because it acts
-- on the distance itself (not on the member's along-track speed), it works
-- identically whether the train rolls forward or backward: reversing never
-- lets the locomotive catch up with its own train or scramble the cart order.
function mcl_minecarts:coupling_accel(le, dir, vel)
	local parent_le = le._train_parent and le._train_parent:get_luaentity()
	if not parent_le or not parent_le.object or not le.object then return {x=0, y=0, z=0} end
	local mpos = le.object:get_pos()
	local ppos = parent_le.object:get_pos()
	if not mpos or not ppos then return {x=0, y=0, z=0} end
	local spacing = mcl_minecarts.train_spacing or 1.0

	-- Centre-to-centre horizontal distance.
	local dx = mpos.x - ppos.x
	local dz = mpos.z - ppos.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.001 then return {x=0, y=0, z=0} end

	-- Unit vector from the parent toward the member.
	local sepx, sepz = dx / dist, dz / dist
	local pv = parent_le.object:get_velocity() or vector.new()
	local vv = vel or vector.new()

	-- Desired relative velocity along the parent-member line: opens the gap
	-- when too close, closes it when too far.
	local target_rel = (spacing - dist) * 4
	local tvel = {x = pv.x + sepx * target_rel, y = 0, z = pv.z + sepz * target_rel}

	local acc = {x = (tvel.x - vv.x) * 5, y = 0, z = (tvel.z - vv.z) * 5}
	local mag = math.sqrt(acc.x * acc.x + acc.z * acc.z)
	if mag > 3 then
		acc.x, acc.z = acc.x / mag * 3, acc.z / mag * 3
	end
	return acc
end

-- HARD spacing floor for coupled members. The coupling controller is soft (it
-- only nudges acceleration), so during a hard brake a trailing cart can still
-- roll into the one in front and carts could pass through each other. This
-- guarantees train_min_spacing centre-to-centre no matter what: whenever the
-- gap is about to fall below the floor this tick, the member is snapped back
-- to it (along the rail axis), given an outward velocity so the gap starts
-- growing again, and its closing acceleration is cancelled. It only fires when
-- the soft controller is not enough; normal rolling keeps the spacing around
-- train_spacing (1.0) and never trips it.
--
-- Returns the (possibly modified) member acceleration.
function mcl_minecarts:enforce_min_spacing(le, acc, dtime)
	local parent_le = le._train_parent and le._train_parent:get_luaentity()
	if not parent_le or not parent_le.object or not le.object then return acc end
	local mpos = le.object:get_pos()
	local ppos = parent_le.object:get_pos()
	if not mpos or not ppos then return acc end
	local dx = mpos.x - ppos.x
	local dz = mpos.z - ppos.z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.001 then return acc end
	local floor = mcl_minecarts.train_min_spacing or 0.9
	dtime = dtime or 0.05
	local margin, outward = 0.05, 0.5

	-- Remember the rail-aligned direction from the parent toward the member, so
	-- an enforced member is always pushed back onto the tail side even if a
	-- momentary collision has crossed the two centres.
	if dist >= floor then
		if math.abs(dx) >= math.abs(dz) then
			le._sep_dir = {x = dx > 0 and 1 or -1, y = 0, z = 0}
		else
			le._sep_dir = {x = 0, y = 0, z = dz > 0 and 1 or -1}
		end
	end

	-- Closing velocity/acceleration along the parent->member line.
	local mv = le.object:get_velocity() or vector.new()
	local pv = parent_le.object:get_velocity() or vector.new()
	local nx, nz
	if le._sep_dir then
		nx, nz = le._sep_dir.x, le._sep_dir.z
	else
		nx, nz = dx / dist, dz / dist
	end
	local rel = (mv.x - pv.x) * nx + (mv.z - pv.z) * nz
	local rel_acc = 0
	if acc then rel_acc = (acc.x or 0) * nx + (acc.z or 0) * nz end
	local close = 0
	if rel < 0 then close = close - rel * dtime end
	if rel_acc < 0 then close = close - rel_acc * 0.5 * dtime * dtime end
	if dist - close >= floor + margin then return acc end

	-- Snap back to the floor and give the member an outward velocity so the gap
	-- grows again instead of hovering at the floor.
	local target = floor + outward * dtime
	le.object:set_pos({x = ppos.x + nx * target, y = mpos.y, z = ppos.z + nz * target})
	if rel < outward then
		local dv = rel - outward
		mv.x = mv.x - dv * nx
		mv.z = mv.z - dv * nz
		le.object:set_velocity(mv)
	end
	if acc and rel_acc < 0 then
		acc.x = acc.x - rel_acc * nx
		acc.z = acc.z - rel_acc * nz
	end
	return acc
end

-- Determine which of two free carts is "in front" along the rail.
-- Returns (parent, child).
function mcl_minecarts:determine_front(a_le, b_le)
	local ap = a_le.object:get_pos()
	local bp = b_le.object:get_pos()
	local vx = bp.x - ap.x
	local vz = bp.z - ap.z
	local axis = "x"
	if math.abs(vz) > math.abs(vx) then axis = "z" end
	local a_dir = mcl_minecarts:get_rail_direction(ap, {x=1,y=0,z=0}, nil, nil, a_le._railtype)
	local sign = (axis == "x") and a_dir.x or a_dir.z
	if sign == 0 then
		local b_dir = mcl_minecarts:get_rail_direction(bp, {x=1,y=0,z=0}, nil, nil, b_le._railtype)
		sign = (axis == "x") and b_dir.x or b_dir.z
	end
	if sign == 0 then sign = 1 end
	if ap[axis] * sign < bp[axis] * sign then
		return a_le, b_le
	end
	return b_le, a_le
end

-- Couple a free cart to whatever it is touching.
function mcl_minecarts:try_couple(free_le, target_le)
	if free_le.name == "mcl_minecarts:furnace_minecart" then
		-- The furnace is always the head of the train.
		if mcl_minecarts:is_train_member(target_le) then
			local old_head = mcl_minecarts:find_train_head(target_le)
			-- Only take over as head when actually touching it; otherwise a
			-- furnace bumped against the tail of a train would jump to the front.
			local hpos = mcl_minecarts:get_attached_world_pos(old_head)
			local fpos = free_le.object:get_pos()
			if hpos and fpos and vector.distance(hpos, fpos) <= 1.9 then
				return mcl_minecarts:couple_carts(free_le, old_head)
			end
			return false
		end
		return mcl_minecarts:couple_carts(free_le, target_le)
	end
	-- A free cart attaches to a train only at its tail, and only when it is
	-- right behind that tail. Carts bumping the middle of a parked train are
	-- not coupled to the far-away tail.
	local tail = nil
	if target_le.name == "mcl_minecarts:furnace_minecart" then
		tail = mcl_minecarts:find_train_tail(target_le)
	elseif mcl_minecarts:is_train_member(target_le) then
		tail = mcl_minecarts:find_train_tail(target_le)
	end
	if tail then
		local tpos = mcl_minecarts:get_attached_world_pos(tail)
		local fpos = free_le.object:get_pos()
		if tpos and fpos and vector.distance(tpos, fpos) <= 1.9 then
			return mcl_minecarts:couple_carts(tail, free_le)
		end
		return false
	end
	local parent, child = mcl_minecarts:determine_front(free_le, target_le)
	return mcl_minecarts:couple_carts(parent, child)
end

-- Toggle the direction of the whole train. key > 0 = W (up), key < 0 = S (down).
-- forward ->(S)-> stop ->(S)-> backward ->(W)-> stop ->(W)-> forward
function mcl_minecarts:handle_direction_key(le, key)
	local dir = le._train_dir or 0
	local new_dir = dir
	if key > 0 then
		if dir == -1 then new_dir = 0
		elseif dir == 0 then new_dir = 1 end
	else
		if dir == 1 then new_dir = 0
		elseif dir == 0 then
			-- Reverse only from a full stop, so the train cannot turn around
			-- mid-roll (which used to scramble the cart order).
			local hvel = le.object:get_velocity()
			if hvel and math.abs(hvel.x) + math.abs(hvel.z) > 0.5 then
				return dir
			end
			new_dir = -1
		end
	end
	if new_dir ~= dir then
		local head = mcl_minecarts:find_train_head(le)
		mcl_minecarts:set_train_dir_recursive(head, new_dir)
		if new_dir == -1 then
			mcl_minecarts:kick_train_backward(head)
		end
	end
	return new_dir
end

-- Start the whole train moving backward as one unit: every cart (head first)
-- is launched along its rail in the reverse of the train's forward direction.
-- The forward direction is recorded on the head the first time it is kicked,
-- so reversing always goes back along the same track regardless of how the
-- train last rolled. Carts whose rail does not accept the reverse direction
-- (e.g. on a curve) are skipped; the coupling controller pulls them along.
function mcl_minecarts:kick_train_backward(head)
	if not head or not head.object then return end
	local fd = head._forward_dir
	if not fd then return end
	local hint = vector.multiply(fd, -1)
	local current = head
	local guard = 0
	while current and current.object and guard < 128 do
		local pos = current.object:get_pos()
		if pos then
			local start_dir = mcl_minecarts:get_rail_direction(pos, hint, nil, 0, current._railtype)
			if start_dir and not vector.equals(start_dir, {x=0, y=0, z=0}) then
				current.object:set_velocity(vector.multiply(start_dir, 3))
			end
		end
		current = current._train_child and current._train_child:get_luaentity()
		guard = guard + 1
	end
end

-- Return the player controls of the first driver sitting anywhere in the train.
function mcl_minecarts:find_driver_ctrl(le)
	local current = le
	local guard = 0
	while current and guard < 64 do
		if current._driver then
			local p = core.get_player_by_name(current._driver)
			if p then return p:get_player_control() end
		end
		current = current._train_child and current._train_child:get_luaentity()
		guard = guard + 1
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
	local epos = mcl_minecarts:get_attached_world_pos(le)
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
		"label[0.375,0.375;" .. core.formspec_escape(core.colorize(mcl_formspec.label_color, train_S("Minecart with Furnace"))) .. "]",
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
