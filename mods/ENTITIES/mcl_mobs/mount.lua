local mob_class = mcl_mobs.mob_class

local function force_detach(player)
	if not player
		or not player:is_player ()
		or not player:is_valid () then
		return
	end

	local attached_to = player:get_attach()
	if not attached_to then
		return
	end

	local entity = attached_to:get_luaentity()
	if entity and entity.is_mob
		and entity.driver and entity.driver == player then
		entity.driver = nil
		entity:driver_detached (player, false)
	end

	-- Otherwise this player might already have left.
	if mcl_player.players[player] then
		player:set_detach()
		mcl_player.players[player].attached = false
		player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		mcl_player.player_set_animation(player, "stand" , 30)
		player:set_properties({visual_size = {x = 1, y = 1} })
	end
end

core.register_on_shutdown(function()
	for player in mcl_util.connected_players() do
		force_detach(player)
	end
end)
core.register_on_leaveplayer(force_detach)
core.register_on_dieplayer(force_detach)

function mob_class:attach (player, force_server_side)
	if self._jockey_rider then
		return false
	end

	self.player_rotation
		= self.player_rotation or vector.zero ()
	self.driver_attach_at
		= self.driver_attach_at or vector.zero ()
	self.driver_scale
		= self.driver_scale or {x = 1, y = 1}
	if not force_server_side
		and self._csm_driving_enabled
		and mcl_serverplayer.is_csm_capable (player) then
		mcl_serverplayer.begin_mount (player, self.object, self.name, {
			bone = "",
			position = self.driver_attach_at,
			rotation = self.driver_rotation,
		})
		return false
	end

	local attach_at
	self._last_jump = 0

	local rot_view = 0

	if self.player_rotation.y == 90 then
		rot_view = math.pi/2
	end

	attach_at = self.driver_attach_at
	self.driver = player
	self._csm_driving = false

	force_detach(player)

	player:set_attach(self.object, "", attach_at, self.player_rotation)
	mcl_attachments.spawn_attachment_entity (player)
	mcl_player.players[player].attached = true
	player:set_properties({
		visual_size = {
			x = self.driver_scale.x,
			y = self.driver_scale.y
		}
	})

	core.after(0.2, function(name)
		local player = core.get_player_by_name(name)
		if player then
			mcl_player.player_set_animation(player, "sit_mount" , 30)
		end
	end, player:get_player_name())

	player:set_look_horizontal(self:get_yaw () - rot_view)
	self:update_driving_hud (player)
	return true
end


function mob_class:detach(player, offset)
	force_detach(player)
	mcl_player.player_set_animation(player, "stand" , 30)
	if offset then
		player:set_pos(vector.add(player:get_pos(), offset))
	else
		player:add_velocity(vector.new(math.random(-6,6),math.random(5,8),math.random(-6,6))) --throw the rider off
	end
end

function mob_class:should_drive ()
	-- Remove invalid drivers.
	if self.driver and not self.driver:is_valid () then
		local driver = self.driver
		self.driver = nil
		self:driver_detached (driver, false)
		return nil
	end
	if self.steer_class == "controls" then
		return self.driver ~= nil
	else
		if not self.driver then
			return nil
		end
		local item = self.driver:get_wielded_item ()
		local itemname = item and item:get_name ()
		return self.steer_item == nil
			or mcl_util.is_item_or_in_group (itemname, self.steer_item)
	end
end

function mob_class:expel_underwater_drivers ()
	-- Detach the driver if submerged.
	if self.driver then
		if core.get_item_group(self.head_in, "water") > 0 then
			self:detach (self.driver)
			return
		end
	end
end

function mob_class:apply_driver_input (speed, self_pos, moveresult, dtime)
	if self.steer_class == "follow_item" then
		self.acc_speed = speed
		-- Since the entirety of SPEED will be applied,
		-- drive_bonus should be set to a suitably small value
		-- to compensate, unless driving is intended to be
		-- faster than this mob's ordinary movement speed.
		self.acc_dir.z = 1

		if self:check_jump (self_pos, moveresult) then
			self._jump = true
		end
	elseif self.steer_class == "controls" then
		local controls = self.driver:get_player_control ()
		if controls.movement_x then
			self.acc_dir.z = controls.movement_y
			self.acc_dir.x = controls.movement_x * 0.5
		else
			local x = (controls.left and -1.0 or 0.0)
				+ (controls.right and 1.0 or 0.0)
			local z = (controls.up and 1.0 or 0.0)
				+ (controls.down and -1.0 or 0.0)
			self.acc_dir.z = z
			self.acc_dir.x = x * 0.5
		end
		self.acc_speed = speed

		if self.acc_dir.z < 0 then
			self.acc_dir.z = self.acc_dir.z * 0.5
		end

		if controls.jump then
			self._jump = true
		end
	end
end

local MAX_PHYSICS_DTIME = 0.075

function mob_class:drive (moving_anim, stand_anim, can_fly, dtime, moveresult)
	local dir = self.driver:get_look_horizontal ()
	self:set_yaw (dir)

	-- Cancel any ongoing activity.
	if self._active_activity then
		self:replace_activity (nil)
	end
	if not self:navigation_finished () then
		self:cancel_navigation ()
	end

	if self._csm_driving then
		local self_pos = self.object:get_pos ()
		local vel = self.object:get_velocity ()
		-- Driving is the responsibility of the client.
		self:halt_in_tracks (false, true)

		-- Detect whether this mob's course has deviated from
		-- the client-specified course and send a movement
		-- correction message if so.
		mcl_serverplayer.maybe_correct_course (self.driver, self.object,
					moveresult, dtime, self_pos, vel)
		-- Configure a suitable animation.
		local v = self.object:get_velocity ()
		local speed = math.sqrt (v.x * v.x + v.z * v.z)
		if speed > 0.25 then
			self:set_animation ("walk")
		else
			self:set_animation ("stand")
		end

		-- Process hog boosting.
		if self._drive_boost_elapsed then
			local total = self._drive_boost_total
			self._drive_boost_elapsed
				= self._drive_boost_elapsed + dtime
			if self._drive_boost_elapsed > total then
				self._drive_boost_elapsed = nil
			end
		end
		return
	end

	-- Move forward but steer the pig in the direction the
	-- driver is facing.
	local pos = self.object:get_pos ()
	local elapsed, total
	local phys_dtime = math.min (dtime, MAX_PHYSICS_DTIME)

	if self._drive_boost_elapsed then
		self._drive_boost_elapsed = self._drive_boost_elapsed + dtime
		if self._drive_boost_elapsed > self._drive_boost_total then
			self._drive_boost_elapsed = nil
		else
			elapsed = self._drive_boost_elapsed
			total = self._drive_boost_total
		end
	end

	local speed = self.movement_speed * self.drive_bonus
	if elapsed then
		local f = 1.0 + 1.5 * math.sin (elapsed / total * math.pi)
		speed = speed * f
	end

	self:apply_driver_input (speed, pos, moveresult, dtime)
	self:pre_motion_step (dtime)
	self:motion_step (phys_dtime, moveresult, pos)

	-- This function is called after motion_step to apply forces
	-- (e.g. velocity changes for jumping) that must not be
	-- attenuated by motion_step.
	if self.post_apply_driver_input then
		self:post_apply_driver_input (speed, pos, moveresult, dtime)
	end

	if self:get_velocity () > 0.05 then
		self:set_animation (moving_anim)
	else
		self:set_animation (stand_anim)
	end
end

function mob_class:hog_boost ()
	if self._drive_boost_elapsed ~= nil then
		return false
	end
	self._drive_boost_elapsed = 0
	self._drive_boost_total = (math.random (841) + 140) / 20.0
	if self._csm_driving then
		mcl_serverplayer.update_vehicle (self.driver, {
			_drive_boost_total = self._drive_boost_total,
		})
	end
	return true
end

-- N.B. that this callback may be executed with DRIVER an invalid
-- object (if the driver was detached for this reason), or during
-- deactivation, in which case IS_DEACTIVATION is non-nil.

function mob_class:driver_detached (driver, is_deactivation)
	if driver:is_valid () then
		mcl_mobs.remove_driving_hud (driver)
		mcl_attachments.remove_attachment_entity (driver)
	end
end

function mob_class:on_detach_child (child)
	if self.driver == child then
		self.driver = nil
		self:driver_detached (child, false)
	end
end

function mob_class:on_detach ()
	-- Mobs which are attached will never register as being in
	-- contact with the ground, and consequently will accumulate
	-- fall damage indefinitely which must be reset upon
	-- detachment lest it should be applied.
	self._fall_distance = 0
	mcl_attachments.remove_attachment_entity (self.object)
end

------------------------------------------------------------------------
--- Client-side steering.
------------------------------------------------------------------------

function mob_class:complete_attachment (player, state)
	self.driver = player
	self._csm_driving = true
	self._driving_sent = nil
	mcl_serverplayer.update_vehicle (player, {
		movement_speed = self.movement_speed,
		jump_height = self.jump_height,
		safe_fall_distance = self._safe_fall_distance,
		_EF = self._EF,
		ef_set = true,
		_drive_boost_total = self._drive_boost_total,
		_drive_boost_elapsed = self._drive_boost_elapsed,
	})

	player:set_properties ({
		visual_size = {
			x = self.driver_scale.x,
			y = self.driver_scale.y,
		},
	})
	self:update_driving_hud (player)
	mcl_attachments.spawn_attachment_entity (player)
end

function mob_class:fallback_attach (player, state)
	self:attach (player, true)
end

function mob_class:detach_client_driver (player)
	if player == self.driver then
		self.driver = nil
		self:driver_detached (player)
		self._csm_driving = false
		self:detach (player)
	end
end

function mob_class:max_delta_movement ()
	return self.movement_speed * 5.0
end

function mob_class:set_touching_ground (touching_ground)
	if touching_ground then
		self.object:set_properties ({
			stepheight = self._initial_step_height,
		})
		self._previously_floating = true
	else
		self.object:set_properties ({
			stepheight = 0.0,
		})
		self._previously_floating = false
	end
end

function mob_class:register_status_effect (effect)
	if self._csm_driving_enabled then
		if not self._EF then
			self._EF = {}
		end
		self._EF[effect.name] = effect

		if self.driver and self._csm_driving then
			mcl_serverplayer.update_vehicle (self.driver, {
				_EF = self._EF,
				ef_set = true,
			})
		end
	end
end

function mob_class:remove_status_effect (id)
	if self._csm_driving_enabled and self._EF then
		self._EF[id] = nil

		if self.driver and self._csm_driving then
			mcl_serverplayer.update_vehicle (self.driver, {
				_EF = self._EF,
				ef_set = true,
			})
		end
	end
end


------------------------------------------------------------------------
-- Health indicator HUDs.
------------------------------------------------------------------------

local player_hud_bars = {}
local floor = math.floor
local ceil = math.ceil

core.register_on_leaveplayer (function (player)
	player_hud_bars[player] = nil
end)

local function refresh_player_health_hud (player, value, total)
	local hp = ceil (value) -- HP to display.
	local bars_total = floor ((total + 19) / 20) -- Number of HUD bars required.
	local bars_filled = floor ((hp + 19) / 20)

	-- Reconfigure this player's HUD bars if necessary.
	local hud_bars = player_hud_bars[player] or {}
	if #hud_bars > bars_total then
		for i = #hud_bars, bars_total + 1, -1 do
			player:hud_remove (hud_bars[i])
			hud_bars[i] = nil
		end
	elseif #hud_bars < bars_total then
		for i = #hud_bars + 1, bars_total do
			-- Taken from hb.register_hudbar.
			local offset_x
				= hb.settings.start_offset_right.x
			local offset_y
				= hb.settings.start_offset_right.y - hb.settings.vmargin * ((i-1))
			hud_bars[i] = player:hud_add ({
				type = "statbar",
				position = hb.settings.pos_right,
				offset = {
					x = offset_x,
					y = offset_y,
				},
				text = "mcl_mobs_hud_vehicle_full.png",
				text2 = "mcl_mobs_hud_vehicle_container.png",
				number = 0,
				item = 20,
				direction = 0,
				size = {
					x = 24,
					y = 24,
				},
				alignment = {
					x = -1,
					y = -1,
				},
			})
		end
	end
	for i = 1, bars_total do
		if i < bars_filled then
			player:hud_change (hud_bars[i], "number", 20)
		elseif i == bars_filled then
			local remainder = hp - (bars_filled - 1) * 20
			player:hud_change (hud_bars[i], "number", remainder)
		else
			player:hud_change (hud_bars[i], "number", 0)
		end
		if i == bars_total then
			local remainder = total - (bars_total - 1) * 20
			player:hud_change (hud_bars[i], "item", remainder)
		else
			player:hud_change (hud_bars[i], "item", 20)
		end
	end
	player_hud_bars[player] = hud_bars
end

function mob_class:update_driving_hud (player, max_hp)
	local hp_max = max_hp or self.object:get_properties ().hp_max
	refresh_player_health_hud (player, self.health, hp_max)
end

function mcl_mobs.remove_driving_hud (player)
	-- Do not remove existing driving HUDs if PLAYER is being
	-- detached to facilitate mounting another mob.
	local attach = player:get_attach ()
	if attach then
		local luaentity = attach:get_luaentity ()
		if luaentity._is_mob and player == luaentity.driver then
			return
		end
	end

	local hud_bars = player_hud_bars[player]
	if hud_bars then
		for _, id in ipairs (hud_bars) do
			player:hud_remove (id)
		end
		player_hud_bars[player] = nil
	end
end
