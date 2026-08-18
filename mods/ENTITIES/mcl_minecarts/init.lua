local modname = core.get_current_modname()
local S = core.get_translator(modname)

mcl_minecarts = {}
mcl_minecarts.modpath = core.get_modpath(modname)
mcl_minecarts.speed_max = 10
mcl_minecarts.check_float_time = 15
-- Center-to-center spacing a coupled member tries to keep behind its parent.
mcl_minecarts.train_spacing = 1.0

dofile(mcl_minecarts.modpath.."/functions.lua")
dofile(mcl_minecarts.modpath.."/rails.lua")

-- Furnace minecart textures: the front shows a lit furnace while fuel burns.
local FURNACE_TEX_INACTIVE = {
	"default_furnace_top.png",
	"default_furnace_top.png",
	"default_furnace_front.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"mcl_minecarts_minecart.png",
}
local FURNACE_TEX_ACTIVE = {
	"default_furnace_top.png",
	"default_furnace_top.png",
	"default_furnace_front_active.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"default_furnace_side.png",
	"mcl_minecarts_minecart.png",
}

local function detach_driver(self)
	if not self._driver then
		return
	end
	local player = core.get_player_by_name(self._driver)
	self._driver = nil
	if player then
		mcl_player.players[player].attached = nil
		player:set_detach()
		player:set_eye_offset({x=0, y=0, z=0},{x=0, y=0, z=0})
		mcl_player.player_set_animation(player, "stand" , 30)
	end
end

local function activate_tnt_minecart(self, timer)
	if self._boomtimer then
		return
	end
	self.object:set_armor_groups({immortal=1})
	if timer then
		self._boomtimer = timer
	else
		self._boomtimer = mcl_tnt.BOOMTIMER
	end
	self.object:set_properties({textures = {
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_tnt_blink.png",
		"mcl_minecarts_minecart.png",
	}})
	self._blinktimer = mcl_tnt.BLINKTIMER
	core.sound_play("tnt_ignite", {pos = self.object:get_pos(), gain = 1.0, max_hear_distance = 15}, true)
end

local activate_normal_minecart = detach_driver

local function hopper_take_item(self)
	local pos = self.object:get_pos()
	if not pos then return end

	if not self or self.name ~= "mcl_minecarts:hopper_minecart" then return end

	local above_pos = vector.offset(pos, 0, 0.9, 0)

	for v in core.objects_inside_radius(above_pos, 1.25) do
		local ent = v:get_luaentity()
		local taken_items = false

		if ent and not ent._removed and ent.itemstring and ent.itemstring ~= "" then
			local inv = mcl_entity_invs.load_inv(self, 5)
			if not inv then	return false end

			local current_itemstack = ItemStack(ent.itemstring)

			if inv:room_for_item("main", current_itemstack) then
				inv:add_item("main", current_itemstack)
				v:get_luaentity().itemstring = ""
				v:remove()
				taken_items = true
			end

			if not taken_items then
				local items_remaining = current_itemstack:get_count()
				for i = 1, self._inv_size, 1 do
					local stack = inv:get_stack("main", i)

					if current_itemstack:get_name() == stack:get_name() then
						local room_for = stack:get_stack_max() - stack:get_count()
						if room_for < items_remaining then
							items_remaining = items_remaining - room_for
							stack:set_count(stack:get_stack_max())
							inv:set_stack("main", i, stack)
							taken_items = true
						elseif room_for ~= 0 then --do nothing if 0
							local new_stack_size = stack:get_count() + items_remaining
							stack:set_count(new_stack_size)
							inv:set_stack("main", i, stack)
							v:get_luaentity().itemstring = ""
							v:remove()
							taken_items = true
							break
						end
					end

					if i == self._inv_size and taken_items then
						current_itemstack:set_count(items_remaining)
						ent.itemstring = current_itemstack:to_string()
					end
				end
			end
		end

		if taken_items then
			mcl_entity_invs.save_inv(ent)
			return taken_items
		end
	end

	return false
end

-- Table for item-to-entity mapping. Keys: itemstring, Values: Corresponding entity ID
local entity_mapping = {}

local function register_entity(entity_id, mesh, textures, drop, on_rightclick, on_activate_by_rail)
	local cart = {
		initial_properties = {
			physical = false,
			collisionbox = {-10/16., -0.5, -10/16, 10/16, 0.25, 10/16},
			visual = "mesh",
			mesh = mesh,
			visual_size = {x=1, y=1},
			textures = textures,
		},

		on_rightclick = on_rightclick,

		_driver = nil, -- player who sits in and controls the minecart (only for minecart!)
		_passenger = nil, -- for mobs
		_punched = false, -- used to re-send _velocity and position
		_velocity = {x=0, y=0, z=0}, -- only used on punch
		_last_float_check = nil, -- timestamp of last time the cart was checked to be still on a rail
		_fueltime = nil, -- how many seconds worth of fuel is left. Only used by minecart with furnace
		_boomtimer = nil, -- how many seconds are left before exploding
		_blinktimer = nil, -- how many seconds are left before TNT blinking
		_blink = false, -- is TNT blink texture active?
		_old_dir = {x=0, y=0, z=0},
		_old_pos = nil,
		_old_vel = {x=0, y=0, z=0},
		_old_switch = 0,
		_railtype = nil,
		-- Train coupling
		_train_id = nil, -- shared id of the train this cart belongs to
		_train_parent = nil, -- object ref of the cart in front (towards the head)
		_train_child = nil, -- object ref of the cart behind
		_train_dir = 0, -- 1 = forward, 0 = stopped, -1 = backward
		_prev_ctrl_up = nil, -- for detecting W/S key presses
		_prev_ctrl_down = nil,
		_coupling_timer = 0, -- throttle for the coupling scan
		_mcl_fishing_hookable = true,
		_mcl_fishing_reelable = true,
	}

	function cart:on_activate(staticdata, _)
		-- Initialize
		local data = core.deserialize(staticdata)
		if type(data) == "table" then
			self._railtype = data._railtype
			self._passenger = data._passenger
			self._train_id = data._train_id
			self._train_index = data._train_index
			self._fueltime = data._fueltime
			self._fuel_totaltime = data._fuel_totaltime
			self._fuel_item = data._fuel_item
			self._fuel_inv_id = data._fuel_inv_id
		end
		self.object:set_armor_groups({immortal=1})

		-- Object links are not saved to disk, so a coupled train has to be
		-- reassembled after a world load: the head (index 0) stays put while
		-- every following cart finds its parent again in on_step.
		if self._train_id then
			self._train_dir = 0
			self._train_child = nil
			self._train_parent = nil
			self._old_pos = nil
			self._old_vel = {x=0, y=0, z=0}
			if self._train_index and self._train_index > 0 then
				self._pending_reattach = core.get_gametime() + 30
			end
		end

		-- Activate cart if on activator rail
		if self.on_activate_by_rail then
			local pos = self.object:get_pos()
			local node = core.get_node(vector.floor(pos))
			if node.name == "mcl_minecarts:activator_rail_on" then
				self:on_activate_by_rail()
			end
		end
	end

	function cart:on_punch(puncher, time_from_last_punch, tool_capabilities, _)
		local pos = self.object:get_pos()
		if not self._railtype then
			local node = core.get_node(vector.floor(pos)).name
			self._railtype = core.get_item_group(node, "connect_to_raillike")
		end

		if not puncher or not puncher:is_player() then
			local cart_dir = mcl_minecarts:get_rail_direction(pos, {x=1, y=0, z=0}, nil, nil, self._railtype)
			if vector.equals(cart_dir, {x=0, y=0, z=0}) then
				return
			end
			mcl_minecarts:set_velocity(self, cart_dir)
			return
		end

		-- Punch+sneak: uncouple the last cart of a train, or pick up a
		-- standalone minecart (unless TNT was ignited)
		if puncher:get_player_control().sneak and not self._boomtimer then
			if self._train_id then
				-- Sneak-punching any cart of a train uncouples its last cart.
				local tail = mcl_minecarts:find_train_tail(self)
				if tail and tail ~= self then
					mcl_minecarts:uncouple_cart(tail)
					return
				end
				-- Only one cart left in this (former) train: pick it up below.
				self._train_id = nil
				self._train_dir = 0
			end
			-- Detach anything still coupled behind before removing ourselves.
			if self._train_child then
				mcl_minecarts:detach_children(self)
			end
			if self._driver then
				if self._old_pos then
					self.object:set_pos(self._old_pos)
				end
				detach_driver(self)
			end

			-- Disable detector rail
			local rou_pos = vector.round(pos)
			local node = core.get_node(rou_pos)
			if node.name == "mcl_minecarts:detector_rail_on" then
				local newnode = {name="mcl_minecarts:detector_rail", param2 = node.param2}
				mcl_redstone.swap_node(rou_pos, newnode)
			end

			-- Drop items and remove cart entity
			if not core.is_creative_enabled(puncher:get_player_name()) then
				for d=1, #drop do
					core.add_item(self.object:get_pos(), drop[d])
				end
				local fuel = mcl_minecarts:get_fuel_stack(self)
				if fuel then
					core.add_item(self.object:get_pos(), fuel)
				end
				if self._on_destroy_minecart then
					self:_on_destroy_minecart (puncher)
				end
			elseif puncher and puncher:is_player() then
				local inv = puncher:get_inventory()
				for d=1, #drop do
					if not inv:contains_item("main", drop[d]) then
						inv:add_item("main", drop[d])
					end
				end
				local fuel = mcl_minecarts:get_fuel_stack(self)
				if fuel then
					inv:add_item("main", fuel)
				end
			end
			-- The fuel slot was handed out above; don't drop it again on removal.
			if self._fuel_inv then
				self._fuel_inv:set_stack("fuel", 1, ItemStack(""))
			end
			self._fuel_item = nil
			self.object:remove()
			return
		end

		local vel = self.object:get_velocity()
		if puncher:get_player_name() == self._driver then
			if math.abs(vel.x + vel.z) > 7 then
				return
			end
		end

		local punch_dir = mcl_minecarts:velocity_to_dir(puncher:get_look_dir())
		punch_dir.y = 0
		local cart_dir = mcl_minecarts:get_rail_direction(pos, punch_dir, nil, nil, self._railtype)
		if vector.equals(cart_dir, {x=0, y=0, z=0}) then
			return
		end

		time_from_last_punch = math.min(time_from_last_punch, tool_capabilities.full_punch_interval)
		local f = 3 * (time_from_last_punch / tool_capabilities.full_punch_interval)

		mcl_minecarts:set_velocity(self, cart_dir, f)
	end

	cart.on_activate_by_rail = on_activate_by_rail

	local passenger_attach_position = vector.new(0, -1.75, 0)

	function cart:on_step(dtime)
		hopper_take_item(self)

		local ctrl, player = nil, nil
		if self._driver then
			player = core.get_player_by_name(self._driver)
			if player then
				ctrl = player:get_player_control()
				-- player detach
				if ctrl.sneak then
					detach_driver(self)
					return
				end
			end
		end

		-- A free minecart that touches another minecart couples to it.
		if not self._train_id then
			self._coupling_timer = (self._coupling_timer or 0) - dtime
			if self._coupling_timer <= 0 then
				self._coupling_timer = 0.1
				local target = mcl_minecarts:get_coupling_target(self)
				if target then
					mcl_minecarts:try_couple(self, target)
				end
			end
		end

		-- Train logic
		if self._train_id then
			-- Reassemble a train after a world reload: object links are not
			-- persisted, so each member re-finds its parent again.
			if self._pending_reattach then
				if core.get_gametime() >= self._pending_reattach then
					self._train_id = nil
					self._train_index = nil
					self._pending_reattach = nil
					self._coupling_timer = nil
				else
					local p = mcl_minecarts:find_train_parent(self)
					if p then
						self._train_parent = p.object
						p._train_child = self.object
						self._pending_reattach = nil
						self.object:set_velocity(vector.new())
						self.object:set_acceleration(vector.new())
					end
				end
				if self._pending_reattach then return end
			end

			-- W/S direction keys (only while a driver rides this cart)
			if self._driver and player and ctrl then
				if self._prev_ctrl_up == nil then
					self._prev_ctrl_up = ctrl.up
					self._prev_ctrl_down = ctrl.down
				else
					if ctrl.up and not self._prev_ctrl_up then
						local new_dir = mcl_minecarts:handle_direction_key(self, 1)
						mcl_minecarts:show_direction_feedback(self, player, new_dir)
					end
					if ctrl.down and not self._prev_ctrl_down then
						local new_dir = mcl_minecarts:handle_direction_key(self, -1)
						mcl_minecarts:show_direction_feedback(self, player, new_dir)
					end
					self._prev_ctrl_up = ctrl.up
					self._prev_ctrl_down = ctrl.down
				end
			end

			if self._train_parent then
				-- Safety net: the cart in front disappeared without the normal
				-- removal path clearing our links (stale object references).
				local pe = self._train_parent:get_luaentity()
				if not pe or not pe.object then
					mcl_minecarts:release_member(self)
				end
			end

			if self._train_parent then
				-- The tail of the train picks up free carts that are pushed
				-- against it.
				if not self._train_child then
					self._coupling_timer = (self._coupling_timer or 0) - dtime
					if self._coupling_timer <= 0 then
						self._coupling_timer = 0.1
						local target = mcl_minecarts:get_coupling_target(self, nil, true)
						if target then
							mcl_minecarts:couple_carts(self, target)
						end
					end
				end
				-- A member keeps running its own rail physics below; the
				-- coupling controller keeps it spaced behind its parent.
			else
				-- Head of the train: only moves when a driver sits somewhere in
				-- the train and a direction is commanded.
				ctrl = mcl_minecarts:find_driver_ctrl(self)
				self._train_dir = self._train_dir or 0
				if not ctrl or self._train_dir == 0 then
					-- Brake smoothly instead of stopping on the spot, so the
					-- coupled carts roll to a halt one after another.
					local hvel = self.object:get_velocity()
					if not hvel or math.abs(hvel.x) + math.abs(hvel.z) < 0.1 then
						self.object:set_velocity(vector.new())
						self.object:set_acceleration(vector.new())
						self._old_pos = nil
						self._old_vel = {x=0, y=0, z=0}
						return
					end
					local bdir = vector.normalize(hvel)
					self.object:set_acceleration(vector.multiply(bdir, -3))
					self._old_pos = nil
					self._old_vel = vector.new(hvel)
					return
				end

				-- Kick the train off from standstill: a stationary cart has no
				-- velocity to derive a rail direction from. Only with fuel.
				local hvel = self.object:get_velocity()
				if math.abs(hvel.x) + math.abs(hvel.z) < 0.01 then
					-- Pull the next fuel item from the furnace slot before kicking.
					mcl_minecarts:refill_fuel(self)
					if self._fueltime and self._fueltime > 0 then
						-- Resolve the rail in the commanded direction WITHOUT the
						-- "backwards" fallback: if the rail ends ahead, start_dir
						-- stays {0,0,0} and the locomotive must not launch into it.
						local hint = {x = self._train_dir > 0 and 1 or -1, y=0, z=0}
						local start_dir = mcl_minecarts:get_rail_direction(self.object:get_pos(), hint, nil, 0, self._railtype)
						if start_dir and not vector.equals(start_dir, {x=0,y=0,z=0}) then
							self.object:set_velocity(vector.multiply(start_dir, 3))
						end
					end
				end
			end
		end

		-- A parked member starts rolling once its parent moves: give it a velocity
		-- matching the parent's speed along the track, so it follows right away
		-- instead of lagging behind the locomotive.
		if self._train_parent then
			local v = self.object:get_velocity()
			if v and math.abs(v.x) + math.abs(v.z) < 0.01 then
				local p = self._train_parent:get_luaentity()
				if p and p.object then
					local pv = p.object:get_velocity()
					if pv and math.abs(pv.x) + math.abs(pv.z) > 0.01 then
						local d = mcl_minecarts:velocity_to_dir(pv)
						if d then
							local speed = math.max(0.5,
								math.min(mcl_minecarts.speed_max, math.abs(pv.x) + math.abs(pv.z)))
							self.object:set_velocity(vector.multiply(d, speed))
						end
					end
				end
			end
		end

		local vel = self.object:get_velocity()
		local update = {}
		if self._last_float_check == nil then
			self._last_float_check = 0
		else
			self._last_float_check = self._last_float_check + dtime
		end

		local pos, rou_pos, node = self.object:get_pos()
		local r = 0.6
		for _, node_pos in pairs({{r, 0}, {0, r}, {-r, 0}, {0, -r}}) do
			if core.get_node(vector.offset(pos, node_pos[1], 0, node_pos[2])).name == "mcl_core:cactus" then
				if self._train_child then
					mcl_minecarts:detach_children(self)
				end
				detach_driver(self)
				for d = 1, #drop do
					core.add_item(pos, drop[d])
				end
				self.object:remove()
				return
			end
		end

		-- Grab mob
		if math.random(1,20) > 15 and not self._passenger then
			if self.name == "mcl_minecarts:minecart" then
				for mob in core.objects_inside_radius(self.object:get_pos(), 1.3) do
					local entity = mob:get_luaentity()
					if entity and entity.is_mob and entity.can_ride_cart then
						self._passenger = entity
						mob:set_attach(self.object, "", passenger_attach_position, vector.zero())
						mcl_attachments.spawn_attachment_entity (mob)
						break
					end
				end
			end
		elseif self._passenger then
			local passenger_pos = self._passenger.object:get_pos()
			if not passenger_pos then
				self._passenger = nil
			end
		end

		-- Drop minecart if it isn't on a rail anymore
		if self._last_float_check >= mcl_minecarts.check_float_time then
			pos = self.object:get_pos()
			rou_pos = vector.round(pos)
			node = core.get_node(rou_pos)
			local g = core.get_item_group(node.name, "connect_to_raillike")
			if g ~= self._railtype and self._railtype then
				-- Detach driver
				if player then
-- A member's spacing is controlled by the coupling controller; skip the
		-- teleport/stuck-rollback heuristic that would fight it.
		if self._old_pos and not self._train_parent then
						self.object:set_pos(self._old_pos)
					end
					mcl_player.players[player].attached = nil
					player:set_detach()
				end

				-- Explode if already ignited
				if self._boomtimer then
					if self._train_child then
						mcl_minecarts:detach_children(self)
					end
					mcl_explosions.explode(pos, 4, {}, self.object)
					self.object:remove()
					return
				end

			-- Drop minecart if it isn't on a rail anymore
			if self._train_child then
				mcl_minecarts:detach_children(self)
			end
			for d = 1, #drop do
				core.add_item(pos, drop[d])
			end
				if player and self._on_destroy_minecart then
					self:_on_destroy_minecart(player)
				end
				self.object:remove()
				return
			end
			self._last_float_check = 0
		end

		-- Update furnace stuff
		if self._fuel_item or self._fuel_inv_id or self._fueltime then
			local cur_vel = self.object:get_velocity()
			local is_moving = math.abs(cur_vel.x) + math.abs(cur_vel.z) > 0.01
			-- Fuel is only consumed while the cart actually moves (or is
			-- commanded to move as a locomotive), not when parked.
			local fuel_active = is_moving or (self._train_dir and self._train_dir ~= 0)
			if fuel_active then
				-- Draw the next item from the fuel slot once the current one
				-- has burned out.
				mcl_minecarts:refill_fuel(self)
				if self._fueltime and self._fueltime > 0 then
					self._fueltime = self._fueltime - dtime
				end
			end
			if self._fueltime and self._fueltime <= 0 then
				self._fueltime = 0
			end
			local burning = self._fueltime and self._fueltime > 0
			if burning ~= self._burning then
				self._burning = burning
				self.object:set_properties({textures = burning and FURNACE_TEX_ACTIVE or FURNACE_TEX_INACTIVE})
			end
		end
		local has_fuel = self._fueltime and self._fueltime > 0

		-- Keep the furnace GUI (fuel slot + fire) up to date for onlookers.
		if self._inv_viewers then
			local watching = false
			for name in pairs(self._inv_viewers) do
				if core.get_player_by_name(name) then watching = true end
			end
			if watching then
				self._fuel_refresh = (self._fuel_refresh or 0) - dtime
				if self._fuel_refresh <= 0 then
					self._fuel_refresh = 0.5
					local fs = mcl_minecarts:furnace_cart_formspec(self)
					if fs ~= self._last_fuel_fs then
						self._last_fuel_fs = fs
						for name in pairs(self._inv_viewers) do
							core.show_formspec(name, self._fuel_inv_id, fs)
						end
					end
				end
			end
		end

		-- Update TNT stuff
		if self._boomtimer then
			-- Explode
			self._boomtimer = self._boomtimer - dtime
			local pos = self.object:get_pos()
			if self._boomtimer <= 0 then
				if self._train_child then
					mcl_minecarts:detach_children(self)
				end
				mcl_explosions.explode(pos, 4, {}, self.object)
				self.object:remove()
				return
			else
				mcl_tnt.smoke_step(pos)
			end
		end
		if self._blinktimer then
			self._blinktimer = self._blinktimer - dtime
			if self._blinktimer <= 0 then
				self._blink = not self._blink
				if self._blink then
					self.object:set_properties({textures =
					{
					"default_tnt_top.png",
					"default_tnt_bottom.png",
					"default_tnt_side.png",
					"default_tnt_side.png",
					"default_tnt_side.png",
					"default_tnt_side.png",
					"mcl_minecarts_minecart.png",
					}})
				else
					self.object:set_properties({textures =
					{
					"mcl_tnt_blink.png",
					"mcl_tnt_blink.png",
					"mcl_tnt_blink.png",
					"mcl_tnt_blink.png",
					"mcl_tnt_blink.png",
					"mcl_tnt_blink.png",
					"mcl_minecarts_minecart.png",
					}})
				end
				self._blinktimer = mcl_tnt.BLINKTIMER
			end
		end

		if self._punched then
			vel = vector.add(vel, self._velocity)
			self.object:set_velocity(vel)
			self._old_dir.y = 0
		elseif vector.equals(vel, {x=0, y=0, z=0}) and (not has_fuel) then
			return
		end

		local dir, last_switch, restart_pos = nil, nil, nil
		if not pos then
			pos = self.object:get_pos()
		end
		if self._old_pos and not self._punched then
			local flo_pos = vector.floor(pos)
			local flo_old = vector.floor(self._old_pos)
			-- Members skip the node-boundary gate so the coupling controller
			-- runs (and updates the acceleration) every tick.
			if vector.equals(flo_pos, flo_old) and (not has_fuel) and not self._train_parent then
				return
				-- Prevent querying the same node over and over again
			end

			if not rou_pos then
				rou_pos = vector.round(pos)
			end
			local rou_old = vector.round(self._old_pos)
			if not node then
				node = core.get_node(rou_pos)
			end
			local node_old = core.get_node(rou_old)

			-- Update detector rails
			if node.name == "mcl_minecarts:detector_rail" then
				local newnode = {name="mcl_minecarts:detector_rail_on", param2 = node.param2}
				mcl_redstone.swap_node(rou_pos, newnode)
			end
			if node.name == "mcl_minecarts:golden_rail_on" then
				restart_pos = rou_pos
			end
			if node_old.name == "mcl_minecarts:detector_rail_on" then
				local newnode = {name="mcl_minecarts:detector_rail", param2 = node_old.param2}
				mcl_redstone.swap_node(rou_old, newnode)
			end
			-- Activate minecart if on activator rail
			if node_old.name == "mcl_minecarts:activator_rail_on" and self.on_activate_by_rail then
				self:on_activate_by_rail()
			end
		end

		-- Stop cart if velocity vector flips (only for free carts: train carts
		-- reverse smoothly through the direction state machine / coupling).
		if not self._train_id and self._old_vel and self._old_vel.y == 0 and
				(self._old_vel.x * vel.x < 0 or self._old_vel.z * vel.z < 0) then
			self._old_vel = {x = 0, y = 0, z = 0}
			self._old_pos = pos
			self.object:set_velocity(vector.new())
			self.object:set_acceleration(vector.new())
			return
		end
		self._old_vel = vector.new(vel)

		if self._old_pos then
			local diff = vector.subtract(self._old_pos, pos)
			for _,v in ipairs({"x","y","z"}) do
				if math.abs(diff[v]) > 1.1 then
					local expected_pos = vector.add(self._old_pos, self._old_dir)
					dir, last_switch = mcl_minecarts:get_rail_direction(pos, self._old_dir, ctrl, self._old_switch, self._railtype)
					if vector.equals(dir, {x=0, y=0, z=0}) then
						dir = false
						pos = vector.new(expected_pos)
						update.pos = true
					end
					break
				end
			end
		end

		-- Don't snap a member's small velocity to zero: the coupling controller
		-- needs it to keep the member rolling with the train.
		if vel.y == 0 and not self._train_parent then
			for _,v in ipairs({"x", "z"}) do
				if vel[v] ~= 0 and math.abs(vel[v]) < 0.9 then
					vel[v] = 0
					update.vel = true
				end
			end
		end

		local cart_dir = mcl_minecarts:velocity_to_dir(vel)
		local max_vel = mcl_minecarts.speed_max
		if not dir then
			dir, last_switch = mcl_minecarts:get_rail_direction(pos, cart_dir, ctrl, self._old_switch, self._railtype)
		end

		-- A train cart (or any self-propelled locomotive) that reaches the end
		-- of a rail stops instead of being turned back by the "backwards"
		-- fallback of get_rail_direction, which would otherwise push it off
		-- the track (or launch it back the way it came).
		if (self._train_id or has_fuel) and not vector.equals(dir, {x=0, y=0, z=0}) then
			if vel.x * dir.x + vel.z * dir.z < 0 then
				vel = {x=0, y=0, z=0}
				update.vel = true
				self.object:set_velocity(vector.new())
				self.object:set_acceleration(vector.new())
				self._old_pos = nil
				self._old_vel = {x=0, y=0, z=0}
				return
			end
		end

		local new_acc = {x=0, y=0, z=0}
		if vector.equals(dir, {x=0, y=0, z=0}) then
			-- No usable rail in any direction: stop (a dead-end rail, a T that
			-- runs out, or the cart has rolled off the track).
			vel = {x=0, y=0, z=0}
			update.vel = true
		else
			-- If the direction changed
			if dir.x ~= 0 and self._old_dir.z ~= 0 then
				vel.x = dir.x * math.abs(vel.z)
				vel.z = 0
				pos.z = math.floor(pos.z + 0.5)
				update.pos = true
			end
			if dir.z ~= 0 and self._old_dir.x ~= 0 then
				vel.z = dir.z * math.abs(vel.x)
				vel.x = 0
				pos.x = math.floor(pos.x + 0.5)
				update.pos = true
			end
			-- Up, down?
			if dir.y ~= self._old_dir.y then
				vel.y = dir.y * math.abs(vel.x + vel.z)
				pos = vector.round(pos)
				update.pos = true
			end

			-- Slow down or speed up
			local acc = dir.y * -1.8
			local friction = 0.4
			local ndef = core.registered_nodes[core.get_node(pos).name]
			local speed_mod = ndef and ndef._rail_acceleration

			acc = acc - friction

			if has_fuel then
				acc = acc + 0.6
			end

			if speed_mod and speed_mod ~= 0 then
				acc = acc + speed_mod + friction
			end

			-- Coupled member: the coupling controller overrides the free-cart
			-- acceleration so it keeps the right spacing behind its parent.
			if self._train_parent then
				acc = acc + mcl_minecarts:coupling_accel(self, dir, vel)
			end

			new_acc = vector.multiply(dir, acc)
		end

		self.object:set_acceleration(new_acc)
		self._old_pos = vector.new(pos)
		self._old_dir = vector.new(dir)
		self._old_switch = last_switch

		-- Limits
		for _,v in ipairs({"x","y","z"}) do
			if math.abs(vel[v]) > max_vel then
				vel[v] = mcl_minecarts:get_sign(vel[v]) * max_vel
				new_acc[v] = 0
				update.vel = true
			end
		end

		if update.pos or self._punched then
			local yaw = 0
			if dir.x < 0 then
				yaw = 0.5
			elseif dir.x > 0 then
				yaw = 1.5
			elseif dir.z < 0 then
				yaw = 1
			end
			self.object:set_yaw(yaw * math.pi)

			-- Handle tilting on slopes
			local yaw_rad = yaw * math.pi
			local target_pitch = 0
			if dir.y ~= 0 then
				target_pitch = dir.y * (math.pi / 4)
			end

			self.object:set_rotation(vector.new(target_pitch, yaw_rad, 0))
		end

		if self._punched then
			self._punched = false
		end

		if not (update.vel or update.pos) then
			return
		end


		local anim = {x=0, y=0}
		if dir.y == -1 then
			anim = {x=1, y=1}
		elseif dir.y == 1 then
			anim = {x=2, y=2}
		end
		self.object:set_animation(anim, 1, 0)

		self.object:set_velocity(vel)
		if update.pos then
			self.object:set_pos(pos)
		end

		-- stopped on "mcl_minecarts:golden_rail_on"
		if vector.equals(vel, {x=0, y=0, z=0}) and restart_pos then
			local dir = mcl_minecarts:get_start_direction(restart_pos)
			if dir then
				mcl_minecarts:set_velocity(self, dir)
			end
		end
	end

	function cart:get_staticdata()
		if self._fuel_inv then
			mcl_minecarts:save_fuel_slot(self)
		end
		return core.serialize({
			_railtype = self._railtype,
			_train_id = self._train_id,
			_train_index = self._train_index,
			_fueltime = self._fueltime,
			_fuel_totaltime = self._fuel_totaltime,
			_fuel_item = self._fuel_item,
			_fuel_inv_id = self._fuel_inv_id,
		})
	end

	-- Clean up the fuel inventory when the cart is deactivated or removed.
	function cart:on_deactivate(removal)
		if self._fuel_inv then
			mcl_minecarts:save_fuel_slot(self)
			if removal then
				local fuel = self._fuel_item
				if fuel then
					core.add_item(self.object:get_pos(), fuel)
				end
			end
			core.remove_detached_inventory(self._fuel_inv_id)
			self._fuel_inv = nil
		end
	end

	core.register_entity(entity_id, cart)
	return core.registered_entities[entity_id]
end

-- Place a minecart at pointed_thing
function mcl_minecarts.place_minecart(itemstack, pointed_thing, placer)
	if pointed_thing.type ~= "node" then
		return
	end

	local railpos, node
	if mcl_minecarts:is_rail(pointed_thing.under) then
		railpos = pointed_thing.under
		node = core.get_node(pointed_thing.under)
	elseif mcl_minecarts:is_rail(pointed_thing.above) then
		railpos = pointed_thing.above
		node = core.get_node(pointed_thing.above)
	else
		return
	end

	-- Activate detector rail
	if node.name == "mcl_minecarts:detector_rail" then
		local newnode = {name="mcl_minecarts:detector_rail_on", param2 = node.param2}
		mcl_redstone.swap_node(railpos, newnode)
	end

	local entity_id = entity_mapping[itemstack:get_name()]
	local cart = core.add_entity(railpos, entity_id)
	if not cart or not cart:get_pos() then return end
	local railtype = core.get_item_group(node.name, "connect_to_raillike")
	local le = cart:get_luaentity()
	if le then
		le._railtype = railtype
	end
	local cart_dir
	if node.name == "mcl_minecarts:golden_rail_on" then
		cart_dir = mcl_minecarts:get_start_direction(railpos)
	end
	if cart_dir then
		mcl_minecarts:set_velocity(le, cart_dir)
	else
		cart_dir = mcl_minecarts:get_rail_direction(railpos, {x=1, y=0, z=0}, nil, nil, railtype)
	end
	cart:set_yaw(core.dir_to_yaw(cart_dir))

	local pname = ""
	if placer then
		pname = placer:get_player_name()
	end
	if not core.is_creative_enabled(pname) then
		itemstack:take_item()
	end
	return itemstack
end


local function register_craftitem(itemstring, entity_id, description, tt_help, longdesc, usagehelp, icon, creative)
	entity_mapping[itemstring] = entity_id

	local groups = { minecart = 1, transport = 1 }
	if creative == false then
		groups.not_in_creative_inventory = 1
	end
	local def = {
		stack_max = 1,
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return
			end

			-- Call on_rightclick if the pointed node defines it
			local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
			if rc then return rc end

			return mcl_minecarts.place_minecart(itemstack, pointed_thing, placer)
		end,
		_on_dispense = function(stack, _, droppos, dropnode, _)
			-- Place minecart as entity on rail. If there's no rail, just drop it.
			local placed
			if core.get_item_group(dropnode.name, "rail") ~= 0 then
				-- FIXME: This places minecarts even if the spot is already occupied
				local pointed_thing = { under = droppos, above = { x=droppos.x, y=droppos.y+1, z=droppos.z } }
				placed = mcl_minecarts.place_minecart(stack, pointed_thing)
			end
			if placed == nil then
				-- Drop item
				core.add_item(droppos, stack)
			end
		end,
		groups = groups,
	}
	def.description = description
	def._tt_help = tt_help
	def._doc_items_longdesc = longdesc
	def._doc_items_usagehelp = usagehelp
	def.inventory_image = icon
	def.wield_image = icon
	core.register_craftitem(itemstring, def)
end

--[[
Register a minecart
* itemstring: Itemstring of minecart item
* entity_id: ID of minecart entity
* description: Item name / description
* longdesc: Long help text
* usagehelp: Usage help text
* mesh: Minecart mesh
* textures: Minecart textures table
* icon: Item icon
* drop: Dropped items after destroying minecart
* on_rightclick: Called after rightclick
* on_activate_by_rail: Called when above activator rail
* creative: If false, don't show in Creative Inventory
]]
local function register_minecart(itemstring, entity_id, description, tt_help, longdesc, usagehelp, mesh, textures, icon, drop, on_rightclick, on_activate_by_rail, creative)
	local entity = register_entity(entity_id, mesh, textures, drop, on_rightclick, on_activate_by_rail)
	tt_help = (tt_help and tt_help .. "\n" or "") .. S("Sneak-click to remove")
	register_craftitem(itemstring, entity_id, description, tt_help, longdesc, usagehelp, icon, creative)
	doc.sub.identifier.register_object(entity_id, "craftitems", itemstring)
	return entity
end

-- Minecart
register_minecart(
	"mcl_minecarts:minecart",
	"mcl_minecarts:minecart",
	S("Minecart"),
	S("Vehicle for fast travel on rails"),
	S("Minecarts can be used for a quick transportion on rails.") .. "\n" ..
	S("Minecarts only ride on rails and always follow the tracks. At a T-junction with no straight way ahead, they turn left. The speed is affected by the rail type."),
	S("You can place the minecart on rails. Right-click it to enter it. Punch it to get it moving.") .. "\n" ..
	S("To obtain the minecart, punch it while holding down the sneak key.") .. "\n" ..
	S("If it moves over a powered activator rail, you'll get ejected."),
	"mcl_minecarts_minecart.b3d",
	{"mcl_minecarts_minecart.png"},
	"mcl_minecarts_minecart_normal.png",
	{"mcl_minecarts:minecart"},
	function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		local name = clicker:get_player_name()
		if self._driver and name == self._driver then
			detach_driver(self)
		elseif not self._driver then
			self._driver = name
			mcl_player.players[clicker].attached = true
			clicker:set_attach(self.object, "", {x=0, y=-1.75, z=-2}, {x=0, y=0, z=0})
			mcl_attachments.spawn_attachment_entity (clicker)
			core.after(0.2, function(name)
				local player = core.get_player_by_name(name)
				if player then
					mcl_player.player_set_animation(player, "sit" , 30)
					mcl_title.set(clicker, "actionbar", {text=S("Sneak to dismount"), color="white", stay=60})
				end
			end, name)
		end
	end, activate_normal_minecart
)

-- Minecart with Chest
local minecart_with_chest = register_minecart(
	"mcl_minecarts:chest_minecart",
	"mcl_minecarts:chest_minecart",
	S("Minecart with Chest"),
	nil, nil, nil,
	"mcl_minecarts_minecart_chest.b3d",
	{ "mcl_chests_normal.png", "mcl_minecarts_minecart.png" },
	"mcl_minecarts_minecart_chest.png",
	{"mcl_minecarts:minecart", "mcl_chests:chest"},
	nil, nil, true)
mcl_entity_invs.register_inv("mcl_minecarts:chest_minecart","Minecart",27,false,true)

function minecart_with_chest:_on_show_entity_inv (player)
	mobs_mc.enrage_piglins (player, true)
end

function minecart_with_chest:_on_destroy_minecart (player)
	mobs_mc.enrage_piglins (player, true)
end

-- Minecart with Furnace
register_minecart(
	"mcl_minecarts:furnace_minecart",
	"mcl_minecarts:furnace_minecart",
	S("Minecart with Furnace"),
	nil,
	S("A minecart with furnace is a vehicle that travels on rails. It can propel itself with fuel."),
	S("Place it on rails. If you give it some coal, the furnace will start burning for a long time and the minecart will be able to move itself. Punch it to get it moving.") .. "\n" ..
	S("To obtain the minecart and furnace, punch them while holding down the sneak key."),

	"mcl_minecarts_minecart_block.b3d",
	{
		"default_furnace_top.png",
		"default_furnace_top.png",
		"default_furnace_front.png",
		"default_furnace_side.png",
		"default_furnace_side.png",
		"default_furnace_side.png",
		"mcl_minecarts_minecart.png",
	},
	"mcl_minecarts_minecart_furnace.png",
	{"mcl_minecarts:minecart", "mcl_furnaces:furnace"},
	-- Open the furnace-style fuel GUI
	function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		mcl_minecarts:show_furnace_cart_inv(self, clicker)
	end, nil, true
)

-- Minecart with Command Block
register_minecart(
	"mcl_minecarts:command_block_minecart",
	"mcl_minecarts:command_block_minecart",
	S("Minecart with Command Block"),
	nil, nil, nil,
	"mcl_minecarts_minecart_block.b3d",
	{
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"jeija_commandblock_off.png^[verticalframe:2:0",
		"mcl_minecarts_minecart.png",
	},
	"mcl_minecarts_minecart_command_block.png",
	{"mcl_minecarts:minecart"},
	nil, nil, false
)

-- Minecart with Hopper
register_minecart(
	"mcl_minecarts:hopper_minecart",
	"mcl_minecarts:hopper_minecart",
	S("Minecart with Hopper"),
	nil, nil, nil,
	"mcl_minecarts_minecart_hopper.b3d",
	{
		"mcl_hoppers_hopper_inside.png",
		"mcl_minecarts_minecart.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_top.png",
	},
	"mcl_minecarts_minecart_hopper.png",
	{"mcl_minecarts:minecart", "mcl_hoppers:hopper"},
	nil, nil, true
)
mcl_entity_invs.register_inv("mcl_minecarts:hopper_minecart", "Hopper Minecart", 5, false, true)

-- Minecart with TNT
register_minecart(
	"mcl_minecarts:tnt_minecart",
	"mcl_minecarts:tnt_minecart",
	S("Minecart with TNT"),
	S("Vehicle for fast travel on rails").."\n"..S("Can be ignited by tools or powered activator rail"),
	S("A minecart with TNT is an explosive vehicle that travels on rail."),
	S("Place it on rails. Punch it to move it. The TNT is ignited with a flint and steel or when the minecart is on an powered activator rail.") .. "\n" ..
	S("To obtain the minecart and TNT, punch them while holding down the sneak key. You can't do this if the TNT was ignited."),
	"mcl_minecarts_minecart_block.b3d",
	{
		"default_tnt_top.png",
		"default_tnt_bottom.png",
		"default_tnt_side.png",
		"default_tnt_side.png",
		"default_tnt_side.png",
		"default_tnt_side.png",
		"mcl_minecarts_minecart.png",
	},
	"mcl_minecarts_minecart_tnt.png",
	{"mcl_minecarts:minecart", "mcl_tnt:tnt"},
	-- Ingite
	function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		if self._boomtimer then
			return
		end
		local held = clicker:get_wielded_item()
		if core.get_item_group(held:get_name(),"flint_and_steel") > 0 then
			if not core.is_creative_enabled(clicker:get_player_name()) then
				held:add_wear(65535/65) -- 65 uses
				local index = clicker:get_wield_index()
				local inv = clicker:get_inventory()
				inv:set_stack("main", index, held)
			end
			activate_tnt_minecart(self)
		end
	end, activate_tnt_minecart)


core.register_craft({
	output = "mcl_minecarts:minecart",
	recipe = {
		{"mcl_core:iron_ingot", "", "mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot", "mcl_core:iron_ingot", "mcl_core:iron_ingot"},
	},
})

core.register_craft({
	output = "mcl_minecarts:tnt_minecart",
	recipe = {
		{"mcl_tnt:tnt"},
		{"mcl_minecarts:minecart"},
	},
})

core.register_craft({
	output = "mcl_minecarts:furnace_minecart",
	recipe = {
		{"mcl_furnaces:furnace"},
		{"mcl_minecarts:minecart"},
	},
})

core.register_craft({
	output = "mcl_minecarts:hopper_minecart",
	recipe = {
		{"mcl_hoppers:hopper"},
		{"mcl_minecarts:minecart"},
	},
})


core.register_craft({
	output = "mcl_minecarts:chest_minecart",
	recipe = {
		{"mcl_chests:chest"},
		{"mcl_minecarts:minecart"},
	},
})


mcl_wip.register_wip_item("mcl_minecarts:chest_minecart")
mcl_wip.register_wip_item("mcl_minecarts:furnace_minecart")
mcl_wip.register_wip_item("mcl_minecarts:command_block_minecart")

-- Stop tracking a player once they close the furnace minecart's fuel GUI.
core.register_on_player_receive_fields(function(player, formname, fields)
	if fields.quit and formname and formname:match("^mcl_minecarts_furnace_") then
		local name = player:get_player_name()
		for _, ent in pairs(core.luaentities) do
			if ent._fuel_inv_id == formname and ent._inv_viewers then
				ent._inv_viewers[name] = nil
				break
			end
		end
	end
end)
