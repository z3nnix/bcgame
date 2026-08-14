local mob_class = mcl_mobs.mob_class
local ipairs = ipairs
local pairs = pairs

local mathfloor = math.floor
local mathsqrt = math.sqrt
local mathmax = math.max
local mathmin = math.min
local mathpow = math.pow

local ENTITY_CRAMMING_MAX = 24
local DEATH_DELAY = 0.5

local get_attachment_pos = mcl_attachments.get_attachment_pos

local mobs_drop_items = core.settings:get_bool ("mobs_drop_items") ~= false

function mob_class:item_drop(cooked, looting_level, mcl_reason)
	if not mobs_drop_items then return end
	looting_level = looting_level or 0
	if (self.child and self.type ~= "monster") then
		return
	end

	local obj, item
	local pos = self.object:get_pos()

	self.drops = self.drops or {}

	for _, dropdef in pairs(self.drops) do
		local chance = 1 / dropdef.chance
		local looting_type = dropdef.looting

		if looting_level > 0 then
			local chance_function = dropdef.looting_chance_function
			if chance_function then
				chance = chance_function(looting_level)
			elseif looting_type == "rare" then
				chance = chance + (dropdef.looting_factor or 0.01) * looting_level
			end
		end

		local num = 0
		local do_common_looting = (looting_level > 0 and looting_type == "common")
		if math.random() < chance then
			num = math.random(dropdef.min or 1, dropdef.max or 1)
		elseif not dropdef.looting_ignore_chance then
			do_common_looting = false
		end

		if do_common_looting then
			num = num + math.floor(math.random(0, looting_level) + 0.5)
		end

		-- Always drop mob heads when killed by a charged creeper explosion.
		if (dropdef.mob_head and mcl_reason
		    and mcl_reason.type == "explosion"
		    and mcl_reason.mob_name == "mobs_mc:creeper_charged") then
		    num = 1
		end

		if num > 0 then
			item = dropdef.name
			if cooked then
				local output = core.get_craft_result({ method = "cooking", width = 1, items = {item}})
				if output and output.item and not output.item:is_empty() then
					item = output.item:get_name()
				end
			end

			for _ = 1, num do
				obj = core.add_item(pos, ItemStack(item .. " " .. 1))
			end

			if obj and obj:get_luaentity() then
				obj:set_velocity({
					x = math.random(-10, 10) / 9,
					y = 6,
					z = math.random(-10, 10) / 9,
				})
			elseif obj then
				obj:remove() -- item does not exist
			end
		end
	end
	local bonus_chance = looting_level * 0.01
	self:drop_armor (bonus_chance)
	self:drop_wielditem (bonus_chance)
	self:drop_offhand_item (bonus_chance)
	if self.drop_custom then
		self:drop_custom (looting_level)
	end
	self.drops = {}
end

local function get_cbox_for_collision (obj)
	local entity = obj:get_luaentity ()
	if entity then
		return entity.is_mob
			and entity.pushable
			and not entity.dead
			and entity.collisionbox or nil
	elseif obj:is_player () then
		return obj:get_properties ().collisionbox
	else
		return nil
	end
end

local function cbox_intersect_p (cbox, x, y, z, cbox1, pos1)
	return cbox[1] + x <= pos1.x + cbox1[4]
		and cbox[2] + y <= pos1.y + cbox1[5]
		and cbox[3] + z <= pos1.z + cbox1[6]
		and cbox[4] + x >= pos1.x + cbox1[1]
		and cbox[5] + y >= pos1.y + cbox1[2]
		and cbox[6] + z >= pos1.z + cbox1[3]
end

local function common_collision (cbox, this_object, pos)
	local w = cbox[4] - cbox[1]
	local x, z = 0, 0
	local px, py, pz = pos.x, pos.y, pos.z
	local count = 0
	for object in core.objects_inside_radius (pos, w + 1.0) do
		if object ~= this_object and not object:get_attach () then
			local pos1 = object:get_pos ()
			local cbox1 = get_cbox_for_collision (object)
			if cbox1 and cbox_intersect_p (cbox, px, py, pz, cbox1, pos1) then
				count = count + 1
				if count > ENTITY_CRAMMING_MAX then
					break
				end

				local dx = pos1.x - pos.x
					+ math.random () * 0.10 - 0.05
				local dz = pos1.z - pos.z
					+ math.random () * 0.10 - 0.05
				local bw = mathmax (cbox1[6] - cbox1[3],
						    cbox1[4] - cbox1[1])
				local d = mathsqrt (dx * dx + dz * dz) / (bw + w)
				if d > 0.01 then
					local v = mathpow (1 / d, 0.333) * 0.75
					x = x - dx / d * v
					z = z - dz / d * v
				end
			end
		end
	end
	return x, z, count
end

mcl_mobs.common_collision = common_collision

function mob_class:collision (pos)
	local x, z, count
		= common_collision (self.collisionbox, self.object, pos)
	return x, z, count
end

-- move mob in facing direction
function mob_class:set_velocity(v)
	self.acc_speed = v
	-- Minecraft scales forward acceleration by desired
	-- velocity in blocks/tick.
	self.acc_dir.z = v * 0.05
	self.acc_dir.x = 0
	self.acc_dir.y = 0
end

-- calculate mob velocity
function mob_class:get_velocity ()
	local v = self.object:get_velocity ()
	if v then
		return mathsqrt (v.x * v.x + v.z * v.z)
	end
	return 0
end

-- check if mob is dead or only hurt
function mob_class:check_for_death (mcl_reason, damage)
	-- Don't display death animations when no damage was dealt,
	-- e.g. when it was all neutralized by fire resistance or
	-- water breathing.
	if damage <= 0 then
		return false
	end

	if self.dead then
		self:jockey_death ()
		return true
	end

	-- Make mob flash red.
	self:add_texture_mod ("^[colorize:#d42222:175")

	-- Still got some health?
	if self.health > 0 then
		self:mob_sound ("damage")
		-- Limit health to defined maximum value.
		local hp_max = self.object:get_properties ().hp_max
		self.health = math.min (self.health, hp_max)

		-- Remove damage overlay.
		core.after (0.5, function (self)
			if self and not self.dead and self.object
				and self.object:get_pos () then
				self:remove_texture_mod ("^[colorize:#d42222:175")
			end
		end, self)
		return false
	end

	self:mob_sound ("death")
	self:jockey_death ()

	-- Execute custom death function
	if self.on_die then
		local pos = self.object:get_pos()
		local on_die_exit = self:on_die (pos, mcl_reason)
		if on_die_exit == true then
			self.dead = true
			self:safe_remove()
			return true
		end
	end

	self.dead = true
	self:remove_texture_mod ("^[colorize:#FF000040")
	self:remove_texture_mod ("^[brighten")

	self.object:set_properties ({
		pointable = false,
		collide_with_objects = false,
	})

	local length
	-- default death function and die animation (if defined)
	if self.instant_death then
		length = 0
	elseif self.animation
		and self.animation.die_start
		and self.animation.die_end then
		local frames = self.animation.die_end - self.animation.die_start
		local speed = self.animation.die_speed or 15
		length = math.max(frames / speed, 0) + DEATH_DELAY
		self:set_animation ("die")
	else
		length = 1 + DEATH_DELAY
		self:set_animation ("stand", true)
	end

	local killed_by_player = false
	if self.last_player_hit_time
		and core.get_gametime() - self.last_player_hit_time <= 5 then
		killed_by_player  = true
	end

	-- Drop items and xp
	if mcl_reason and (mcl_reason.type == "lava" or mcl_reason.type == "fire") then
		self:item_drop (true, 0, mcl_reason)
	elseif mcl_reason then
		local wielditem = mcl_reason.direct and mcl_util.get_wielditem (mcl_reason.direct)
		local cooked = mcl_burning.is_burning(self.object)
			or mcl_enchanting.has_enchantment(wielditem, "fire_aspect")
		local looting = mcl_enchanting.get_enchantment(wielditem, "looting")
		self:item_drop (cooked, looting, mcl_reason)
		if killed_by_player then
			if self.type == "monster"
				or self.name == "mobs_mc:zombified_piglin"
				and self.last_player_hit_name then
				awards.unlock(self.last_player_hit_name, "mcl:monsterHunter")
			end

			if ((not self.child) or self.type ~= "animal") then
				local pos = self.object:get_pos()
				local xp_amount = math.random(self.xp_min, self.xp_max)
				if not core.is_creative_enabled(self.last_player_hit_name)
					and not mcl_sculk.handle_death(pos, xp_amount) then
					mcl_experience.throw_xp(pos, xp_amount)
				end
			end
		end
	end

	-- Remove body after a few seconds
	local kill = function(self)
		if not self.object:get_luaentity() then
			return
		end

		local dpos = self.object:get_pos()
		local cbox = self.object:get_properties().collisionbox
		local yaw = self:get_yaw ()
		self:safe_remove()
		mcl_mobs.death_effect(dpos, yaw, cbox, not self.instant_death)
	end

	if length <= 0 then
		kill(self)
	else
		core.after(length, kill, self)
	end

	return true
end

------------------------------------------------------------------------
-- Environmental damage.
------------------------------------------------------------------------

function mob_class:reset_breath ()
	self.breath = self._max_air_supply
end

function mob_class:respire (dtime)
	self.breath = mathmin (self._max_air_supply, self.breath + dtime)
end

local function get_internal_light_level ()
	local tod = core.get_timeofday ()
	local ratio = core.time_to_day_night_ratio (tod)
	local light = math.floor (ratio * 15)

	-- See: https://minecraft.wiki/w/Light#Internal_light_level
	local weather = mcl_weather.get_weather ()
	if weather == "thunder" then
		light = math.max (0, 10 - (15 - light))
	elseif weather == "rain" or weather == "snow" then
		light = math.max (0, 12 - (15 - light))
	end
	return light
end

function mob_class:endangered_by_sunlight ()
	local self_pos = self.object:get_pos ()
	local dimension = mcl_worlds.pos_to_dimension (self_pos)
	if dimension == "overworld"
		and not mcl_weather.is_exposed_to_rain (self_pos)
		and get_internal_light_level () >= 12 then
		return true
	end
	return false
end

function mob_class:get_weather_with_light (node_pos, time_of_day)
	-- Don't return natural light till the artificial light at
	-- this position exceeds the threshold at which natural light
	-- becomes significant, for natural light tests are expensive.
	local local_light = core.get_node_light (node_pos) or 0
	local has_rain = self:is_exposed_to_rain (node_pos)
	if local_light > 10 then
		local direct_light = core.get_natural_light (node_pos) or 0

		-- See: https://minecraft.wiki/w/Light#Internal_light_level
		local weather = mcl_weather.get_weather ()
		local light = direct_light
		if weather == "thunder" then
			light = math.max (0, 10 - (15 - light))
		elseif weather == "rain" or weather == "snow" then
			light = math.max (0, 12 - (15 - light))
		end
		return light, direct_light, has_rain
	else
		return local_light, local_light, has_rain
	end
end

function mob_class:fast_ignite (time)
	if self.burn_time then
		local t = self.burn_time
		self.burn_time = mathmax (t, time)
	else
		mcl_burning.set_on_fire (self.object, time)
	end
end

function mob_class:step_drowning (dtime, is_in_water)
	local is_drowning
	if self.breathes_in_water then
		is_drowning = not is_in_water
	else
		is_drowning = is_in_water
	end

	if is_drowning then
		if self._respiration_level > 0 then
			local r = math.random (1, self._respiration_level + 1)
			if r ~= 1 then
				return
			end
		end
		local t = mathmax (self.breath - dtime, -1.0)
		if t == -1.0 then
			self.breath = 0.0
			if self:damage_mob ("drowning", 2.0) then
				return true
			end

			local attach_pos = get_attachment_pos (self.object)
			attach_pos.y = attach_pos.y + self:get_eye_height ()
			mcl_mobs.effect (attach_pos, 8, "bubble.png", nil, nil, 1, nil)
		else
			self.breath = t
		end
	else
		self:respire (dtime)
	end
end

local SPEED_MODIFIER_POWDER_SNOW = "mcl_mobs:powder_snow_movement"
local v1 = vector.zero ()
local scale_chance

core.register_on_mods_loaded (function ()
	scale_chance = mcl_mobs.scale_chance
end)

function mob_class:can_freeze ()
	return self._can_freeze
end

function mob_class:is_exposed_to_rain (node_pos)
	local value = self._cached_rain_exposure
	if not value or self:check_timer ("rain_exposure", 0.5) then
		value = mcl_weather.is_exposed_to_rain (node_pos)
	end
	self._cached_rain_exposure = value
	return value
end

function mob_class:apply_environment_damage (attach_pos, immersion_depth,
					     liquidtype, params, dtime)
	local damage = 0.0
	local damagetype = nil
	local fire_resistant = self._fire_resistant
	local skip_burning = false
	local node_pos = v1

	node_pos.x = mathfloor (attach_pos.x + 0.5)
	node_pos.y = mathfloor (attach_pos.y + 0.5)
	node_pos.z = mathfloor (attach_pos.z + 0.5)

	if params.dps > 0.0
		and self:check_timer ("environment_damage", 0.5) then
		self:damage_mob ("environment", params.dps * 0.5)
	end

	if liquidtype == "water" then
		if self.burn_time then
			mcl_burning.extinguish (self.object)
		end
		skip_burning = true
	elseif liquidtype == "lava" and not fire_resistant then
		damage = 4.0
		damagetype = "lava"
		if not self:is_exposed_to_rain (node_pos) then
			self:fast_ignite (15.0)
		end
	elseif params.in_soul_fire_node and not fire_resistant then
		if damage < 2.0 then
			damage = 2.0
			damagetype = "in_fire"
		end
		if not self:is_exposed_to_rain (node_pos) then
			self:fast_ignite (5.0)
		end
	elseif params.in_fire_node and not fire_resistant then
		if damage < 1.0 then
			damage = 1.0
			damagetype = "in_fire"
		end
		if not self:is_exposed_to_rain (node_pos) then
			self:fast_ignite (5.0)
		end
	end
	if params.in_solid_node then
		if damage < 1.0 then
			damage = 1.0
			damagetype = "in_wall"
		end
	end

	if params.in_powder_snow and self:can_freeze () then
		local t = mathmin (self._frozen_for + dtime, 7.0)
		self._frozen_for = t
		self:add_physics_factor ("movement_speed", SPEED_MODIFIER_POWDER_SNOW,
					 -1.0 * t / 7.0, "add")
		if t == 7.0 and damage < 1.0
			and self:check_timer ("freeze_damage", 2.0) then
			damage = 1.0
			damagetype = "freeze"
		end
		if self.burn_time then
			mcl_burning.extinguish (self.object)
		end
		skip_burning = true
	elseif self._frozen_for > 0.0 then
		local t = mathmax (self._frozen_for - dtime, 0.0)
		self._frozen_for = t
		if t == 0.0 then
			self:remove_physics_factor ("movement_speed",
						    SPEED_MODIFIER_POWDER_SNOW)
		else
			self:add_physics_factor ("movement_speed", SPEED_MODIFIER_POWDER_SNOW,
						 -1.0 * t / 7.0, "add")
		end
	end

	if not fire_resistant
		and self.standing_on == "mcl_nether:magma" then
		if damage < 1.0 then
			damage = 1.0
			damagetype = "hot_floor"
		end
	end

	if self._collision_count > ENTITY_CRAMMING_MAX - 1
		and damage < 6.0
		and math.random (1, 4) == 1 then
		damage = 6.0
		damagetype = "cramming"
	end

	if self:check_timer ("environment_damage", 0.5)
		and damage > 0.0
		and self:damage_mob (damagetype, damage) then
		return true
	end

	local eye_height = self:get_eye_height ()
	if liquidtype == "water" and immersion_depth > eye_height then
		if self:step_drowning (dtime, true) then
			return true
		end
	elseif self:step_drowning (dtime, false) then
		return true
	end

	if (self._water_sensitive or self.burn_time)
		and self:check_timer ("rain_damage", 0.5) then
		if liquidtype == "water"
			or self:is_exposed_to_rain (node_pos) then
			if self.burn_time then
				mcl_burning.extinguish (self.object)
				skip_burning = true
			end
			if self._water_sensitive
				and self:damage_mob ("environment", 1.0) then
				return true
			end
		end
	end

	if self.ignited_by_sunlight and not skip_burning
		and math.random (scale_chance (dtime, 30)) == 1 then
		local _, dim = mcl_worlds.y_to_layer (node_pos.y)
		if dim == "overworld" then
			node_pos.y = mathfloor (attach_pos.y + eye_height + 0.5)

			local tod = mcl_util.get_current_time_of_day ()
			local sunlight, direct_sunlight, has_rain
				= self:get_weather_with_light (node_pos, tod)
			self._direct_sunlight = direct_sunlight
			if direct_sunlight >= 15 and sunlight >= 12
				and not has_rain and dim == "overworld" then
				if self.armor_list.head == "" then
					self:fast_ignite (10.0)
				elseif math.random (2) == 1 then
					local stack = ItemStack (self.armor_list.head)
					mcl_util.use_item_durability (stack, 1)
					-- Apply wear to head armor.
					self.armor_list.head = stack:to_string ()
					if stack:is_empty () then
						self:set_armor_texture ()
					end
				end
			end
		end
	end
end

function mob_class:damage_mob (reason, damage)
	local damage = mathfloor (damage)
	if damage > 0 then
		local mcl_reason = { type = reason }
		mcl_damage.finish_reason (mcl_reason)
		mcl_util.deal_damage (self.object, damage, mcl_reason)
	end
	return self.dead
end

local floor = math.floor

local function node_name_with_fallback (pos, fallback)
	local cid, _, param2, pos_ok
		= core.get_node_raw (floor (pos.x + 0.5),
				     floor (pos.y + 0.5),
				     floor (pos.z + 0.5))
	if pos_ok then
		local name = core.get_name_from_content_id (cid)
		return core.registered_nodes[name] and name or fallback, param2
	else
		return fallback, 0
	end
end
mcl_mobs.node_name_with_fallback = node_name_with_fallback

------------------------------------------------------------------------
-- Fall damage.
------------------------------------------------------------------------

function mob_class:check_fall_damage (dtime, attach_pos, moveresult)
	if self._no_fall_damage or self.dead then
		return
	elseif self._csm_driving then
		self._last_fall_y = nil
		self._fall_distance = 0
		return
	end

	-- Integrate fall damage.
	local fall_y = self._last_fall_y or attach_pos.y
	local d = self._fall_distance + (fall_y - attach_pos.y)
	self._fall_distance = mathmax (d, 0)
	self._last_fall_y = attach_pos.y

	if self.reset_fall_damage then
		self._fall_distance = 0
	end

	if self._liquidtype == "water" or self._stuck_in then
		self.last_fall_y = nil
		self._fall_distance = 0
	elseif self.liquidtype == "lava" then
		local d = mathpow (0.5, dtime / 0.05)
		self._fall_distance = self._fall_distance * d
	end

	if moveresult.touching_ground
	-- Be certain that the area beneath this mob is actually
	-- loaded.
		and self.standing_on ~= "ignore" then
		local distance = self._fall_distance
		if distance > self._safe_fall_distance then
			local amt = (distance - self._safe_fall_distance)
				* self.fall_damage_multiplier
			-- Apply `fall_damage_add_percent' node
			-- definitions.
			local greatest = 0.0
			for _, collision in pairs (moveresult.collisions) do
				if collision.type == "node"
					and collision.axis == "y"
				-- Gravity-induced collision.
					and collision.new_velocity.y > collision.old_velocity.y then
					local node, _ = node_name_with_fallback (collision.node_pos,
										 "ignore")
					local this = core.get_item_group (node, "fall_damage_add_percent")

					if this < 0.0 then
						greatest = this
					else
						greatest = mathmax (greatest, this)
					end
				end
			end
			self:damage_mob ("fall", amt + amt * (greatest / 100.0))
		end
		self._fall_distance = 0
	end
	self.reset_fall_damage = false
	return
end

function mob_class:teleport_safely (pos)
	self.object:set_pos (pos)
	self.reset_fall_damage = true
end

------------------------------------------------------------------------
-- Miscellaneous functions.
------------------------------------------------------------------------

function mob_class:check_water_flow (attach_pos)
	return self._water_current
end

local pi = math.pi

function mob_class:check_dying (dtime)
	if self.dead and not self.animation.die_end then
		if self.object then
			local rot = self.object:get_rotation ()
			local x = dtime * 20.0
			local y = (mathpow (4, x) * rot.z) / mathpow (5, x)
				- (mathpow (4, x) * pi) / (2 * mathpow (5, x))
				+ pi * 0.5
			rot.z = y
			self.object:set_rotation (rot)
		end
		return true
	end
end

------------------------------------------------------------------------
-- Attribute modifiers.
-- Ref: https://minecraft.wiki/w/Attribute#Modifiers.
------------------------------------------------------------------------

mcl_mobs.persistent_physics_factors = {}

function mob_class:validate_attribute (field, value)
	if value == "knockback_resistance" then
		return mathmax (0.0, mathmin (1.0, value))
	elseif value == "movement_speed" then
		return mathmax (field, 0.001)
	end
	return value
end

function mob_class:post_apply_physics_factor (field, oldvalue, value)
	if field == "movement_speed" then
		-- Rescale gowp velocity (or stupid_velocity) to match
		-- the new movement_speed.
		--
		-- A velocity of nil is a placeholder for
		-- movement_speed anyway, and as such no adjustment is
		-- necessary in these cases.
		if self.waypoints or self.pathfinding_context then
			if self.gowp_velocity then
				local factor = self.gowp_velocity / oldvalue
				self.gowp_velocity = factor * value
			end
		elseif self.stupid_target then
			if self.stupid_velocity then
				local factor = self.stupid_velocity / oldvalue
				self.stupid_velocity = factor * value
			end
		end

		if self.driver and self._csm_driving then
			mcl_serverplayer.update_vehicle (self.driver, {
				movement_speed = self.movement_speed,
			})
		end
	elseif field == "jump_height" then
		if self.driver and self._csm_driving then
			mcl_serverplayer.update_vehicle (self.driver, {
				jump_height = self.jump_height,
			})
		end
	elseif field == "_safe_fall_distance" then
		if self.driver and self._csm_driving
			and mcl_serverplayer.is_csm_at_least (self.driver, 11) then
			mcl_serverplayer.update_vehicle (self.driver, {
				safe_fall_distance = self._safe_fall_distance,
			})
		end
	end
end

local function apply_physics_factors (self, field)
	local base = self._physics_factors[field].base or self[field]
	local total = base
	local to_add = {}
	local to_add_multiply_base = {}
	local to_multiply_total = {}
	for name, value in pairs (self._physics_factors[field]) do
		if name ~= "base" then
			if value.op == "scale_by" then
				table.insert (to_multiply_total, value.amount)
			elseif value.op == "add_multiplied_base" then
				table.insert (to_add_multiply_base, value.amount)
			elseif value.op == "add_multiplied_total" then
				table.insert (to_multiply_total, 1.0 + value.amount)
			elseif value.op == "add" then
				table.insert (to_add, value.amount)
			end
		end
	end
	for _, value in ipairs (to_add) do
		total = total + value
	end
	base = total
	for _, value in ipairs (to_add_multiply_base) do
		total = total + base * value
	end
	for _, value in ipairs (to_multiply_total) do
		total = total * value
	end
	local oldvalue = self[field]
	self[field] = self:validate_attribute (field, total)
	self:post_apply_physics_factor (field, oldvalue, total)
end

function mob_class:set_physics_factor_base (field, base)
	if not self._physics_factors[field] then
		self._physics_factors[field] = { base = base, }
	else
		self._physics_factors[field].base = base
	end
	apply_physics_factors (self, field)
end

function mob_class:add_physics_factor (field, id, factor, op, add_to_existing)
	if not self._physics_factors[field] then
		self._physics_factors[field] = { base = self[field], }
	else
		-- Do not apply physics factors redundantly.
		local old = self._physics_factors[field][id]
		if old then
			if add_to_existing then
				old.amount = old.amount + factor
				old.op = op
				apply_physics_factors (self, field)
				return
			elseif old.amount == factor and old.op == op then
				return
			end
		end
	end
	self._physics_factors[field][id] = {
		amount = factor,
		op = op or "scale_by",
	}
	apply_physics_factors (self, field)
end

function mob_class:remove_physics_factor (field, id)
	if not self._physics_factors[field]
		or not self._physics_factors[field][id] then
		return
	end
	self._physics_factors[field][id] = nil
	apply_physics_factors (self, field)
end

function mob_class:stock_value (field)
	if not self._physics_factors[field] then
		return self[field]
	end
	return self._physics_factors[field].base
end

function mob_class:restore_physics_factors ()
	for field, factors in pairs (self._physics_factors) do
		-- Upgrade obsolete numerical factors.
		for id, data in pairs (factors) do
			if id ~= "base" and type (data) == "number" then
				factors[id] = {
					amount = data,
					op = "scale_by",
				}
			end
		end
		apply_physics_factors (self, field)
	end
end

function mcl_mobs.make_physics_factor_persistent (id)
	mcl_mobs.persistent_physics_factors[id] = true
end

------------------------------------------------------------------------
-- Soul Speed & enchantment modifiers.
------------------------------------------------------------------------

local SPEED_MODIFIER_SOUL_SPEED = "mcl_mobs:soul_speed_movement_modifier"

function mob_class:node_changed (standon)
	if not standon or not self.wears_armor then
		return
	end

	local soul_block = standon.groups.soul_block or 0
	if soul_block <= 0 or self._soul_speed_level <= 0 then
		if self._last_soul_speed_bonus ~= -1 then
			self._last_soul_speed_bonus = -1
			self:remove_physics_factor ("movement_speed", SPEED_MODIFIER_SOUL_SPEED)
		end
	else
		local level = self._soul_speed_level
		local f = 0.03 * (1.0 + level * 0.35) * 20.0
		if self._last_soul_speed_bonus ~= f then
			self:add_physics_factor ("movement_speed", SPEED_MODIFIER_SOUL_SPEED,
						 f, "add", false)
			self._last_soul_speed_bonus = f
		end
	end
end

function mob_class:reapply_soul_speed_modifiers ()
	local standon = core.registered_nodes[self.standing_on]
	self:node_changed (standon)
end

function mob_class:pre_motion_step (dtime)
	if self.standing_on ~= self._last_standing_on then
		local standon = core.registered_nodes[self.standing_on]
		self:node_changed (standon)
	end
end

------------------------------------------------------------------------
-- Mob motion routines.  Do not tamper with the mechanics or constants
-- in this section without reference to
-- https://minecraft.wiki/w/Physics and a number of documents
-- available online, and a copy of Minecraft for visual comparison.
------------------------------------------------------------------------

--- Constants.  These remain constant for the duration of the game but
--- are adjusted so as to reflect the global step time.

local function pow_by_step (value, dtime)
	return mathpow (value, dtime / 0.05)
end
mcl_mobs.pow_by_step = pow_by_step

local AIR_DRAG			= 0.98
local AIR_FRICTION		= 0.91
local WATER_DRAG		= 0.8
local AQUATIC_WATER_DRAG	= 0.9
local AQUATIC_GRAVITY		= -0.1
local SPRINTING_WATER_DRAG	= 0.9
local JUMPING_LAVA_DRAG		= 0.8
local LAVA_FRICTION		= 0.5
local LAVA_SPEED		= 0.4
local FLYING_LIQUID_SPEED	= 0.4
local FLYING_GROUND_SPEED	= 2.0
local FLYING_AIR_SPEED		= 0.4
local BASE_SLIPPERY		= 0.98
local BASE_SLIPPERY_1		= 0.989
local BASE_FRICTION		= 0.6
local LIQUID_FORCE		= 0.28
local LAVA_FORCE		= 0.09
local LAVA_FORCE_NETHER		= 0.14
local BASE_FRICTION3		= math.pow (0.6, 3)
local FLYING_BASE_FRICTION3	= math.pow (BASE_FRICTION * AIR_FRICTION, 3)
local LIQUID_JUMP_THRESHOLD	= 0.4
local LIQUID_JUMP_FORCE		= 0.8
local LIQUID_JUMP_FORCE_ONESHOT	= 6.0
local LAVA_JUMP_THRESHOLD	= 0.1

mcl_mobs.AIR_FRICTION = AIR_FRICTION
mcl_mobs.LIQUID_JUMP_FORCE = 0.1

local function scale_speed (speed, friction)
	local f = BASE_FRICTION3 / (friction * friction * friction)
	return speed * f
end

local function scale_speed_flying (speed, friction)
	local f = FLYING_BASE_FRICTION3 / (friction * friction * friction)
	return speed * f
end

function mob_class:accelerate_relative (acc, speed_x, speed_y)
	local yaw = self:get_yaw ()
	local acc_x, acc_y, acc_z
	local magnitude = vector.length (acc)
	if magnitude > 1.0 then
		acc_x = acc.x / magnitude * speed_x
		acc_y = acc.y / magnitude * speed_y
		acc_z = acc.z / magnitude * speed_x
	else
		acc_x = acc.x * speed_x
		acc_y = acc.y * speed_y
		acc_z = acc.z * speed_x
	end
	local s = -math.sin (yaw)
	local c = math.cos (yaw)
	local x = acc_x * c + acc_z * s
	local z = acc_z * c - acc_x * s
	return x, acc_y, z
end

function mob_class:get_jump_force (moveresult)
	return self.jump_height
end

function mob_class:jump_actual (v, jump_force)
	if self.animation.jump_start then
		self._current_animation = nil
		self:set_animation ("jump")
	end
	self:mob_sound ("jump")
	v = vector.new (v.x, jump_force, v.z)

	-- Apply acceleration if sprinting.
	if self._sprinting then
		local yaw = self:get_yaw ()
		v.x = v.x + math.sin (yaw) * -4.0
		v.z = v.z + math.cos (yaw) * 4.0
	end
	return v
end

local function horiz_collision (moveresult)
	for _, item in ipairs (moveresult.collisions) do
		if item.type == "node"
			and (item.axis == "x" or item.axis == "z") then
			return true
		end
	end
	return false
end

mcl_mobs.horiz_collision = horiz_collision

local function clamp (num, min, max)
	return math.min (max, math.max (num, min))
end

function mob_class:immersion_depth (liquidgroup, pos, max)
	local start = pos.y
	local ymax
	local i = start
	local limit = i + max + 1

	while i < limit do
		local pos = { x = pos.x, y = i, z = pos.z, }
		local node = core.get_node (pos)
		local def = core.registered_nodes[node.name]
		if def and def.groups[liquidgroup] and def.groups[liquidgroup] > 0 then
			local height = 1
			if def.liquidtype == "flowing" then
				height = 0.1 + node.param2 * 0.1
			end
			ymax = math.floor (i + 0.5) + height - 0.5
		end
		i = i + 1
	end

	return ymax and ymax - start or 0
end

function mob_class:check_collision (attach_pos, v, h_scale)
	-- can mob be pushed, if so calculate direction
	if self.pushable and not self.object:get_attach () then
		local c_x, c_z, count = self:collision (attach_pos)
		v.x = v.x + c_x * h_scale
		v.z = v.z + c_z * h_scale
		self._collision_count = count
	end
end

local function box_intersection (box, other_box)
	for index = 1, 3 do
		if box[index] > other_box[index + 3]
			or other_box[index] > box[index + 3] then
			return false
		end
	end
	return true
end

local function will_breach_water_1 (node, cbox)
	local node_data = core.get_node (node)
	local def = core.registered_nodes[node_data.name]

	if def and not def.walkable and def.liquidtype == "none" then
		return false
	end

	local boxes
		= core.get_node_boxes ("collision_box", node, node_data)
	for _, box in pairs (boxes) do
		box[1] = box[1] + node.x
		box[2] = box[2] + node.y
		box[3] = box[3] + node.z
		box[4] = box[4] + node.x
		box[5] = box[5] + node.y
		box[6] = box[6] + node.z

		if box_intersection (box, cbox) then
			return true
		end
	end
	return false
end

local will_breach_water_scratch = vector.zero ()
local scratch_cbox = {}

function mob_class:will_breach_water (attach_pos, dx, dy, dz)
	local cbox = self.collisionbox
	scratch_cbox[1] = cbox[1] + attach_pos.x + dx
	scratch_cbox[2] = cbox[2] + attach_pos.y + dy
	scratch_cbox[3] = cbox[3] + attach_pos.z + dz
	scratch_cbox[4] = cbox[4] + attach_pos.x + dx
	scratch_cbox[5] = cbox[5] + attach_pos.y + dy
	scratch_cbox[6] = cbox[6] + attach_pos.z + dz

	-- Crude collision detection that does not take movement into
	-- account.
	local xmin = math.floor (scratch_cbox[1] + 0.5)
	local ymin = math.floor (scratch_cbox[2] + 0.5) - 1
	local zmin = math.floor (scratch_cbox[3] + 0.5)
	local xmax = math.floor (scratch_cbox[4] + 0.5)
	local ymax = math.floor (scratch_cbox[5] + 0.5) + 1
	local zmax = math.floor (scratch_cbox[6] + 0.5)
	local v = will_breach_water_scratch

	for z = zmin, zmax do
		for x = xmin, xmax do
			for y = ymin, ymax do
				v.x = x
				v.y = y
				v.z = z
				if will_breach_water_1 (v, scratch_cbox) then
					return false
				end
			end
		end
	end
	return true
end

function mob_class:motion_step (dtime, moveresult, attach_pos)
	if not moveresult then
		return
	end
	local standin = core.registered_nodes[self.standing_in]
	local standon = core.registered_nodes[self.standing_on]
	local acc_dir = self.acc_dir
	local acc_speed = self.acc_speed
	local fall_speed = self._acc_no_gravity and 0 or self.fall_speed
	local touching_ground = moveresult.touching_ground or moveresult.standing_on_object
	local jumping = self._jump
	local p
	local h_scale, v_scale
	local climbing = false
	local always_enable_step_height = false

	-- Note that mobs being controlled by a player should sink.
	if self.floats == 1 and not self.driver and math.random (10) < 8 then
		local depth = self._immersion_depth or 0
		if depth > LIQUID_JUMP_THRESHOLD or self._liquidtype == "lava" then
			jumping = true
		end
	end

	-- Note: this does not exist in Minecraft and is only meant to
	-- approximate floating in liquids for striders.
	if self.floats_on_lava and math.random (10) < 8 then
		local depth = self._liquidtype == "lava"
			and self._immersion_depth or 0
		if depth > LAVA_JUMP_THRESHOLD then
			jumping = true
		elseif depth > 0 then
			-- Enable this mob to step out of this liquid
			-- pseudo-surface.
			always_enable_step_height = true
		end
	end

	if self.jump_timer and self.jump_timer > 0 then
		self.jump_timer = math.max (0, self.jump_timer - dtime)
	end

	p = pow_by_step (AIR_DRAG, dtime)
	acc_dir.x = acc_dir.x * p
	acc_dir.z = acc_dir.z * p

	local v = self.object:get_velocity ()
	local climbable = standin.climbable or standon.climbable

	if self.climb_powder_snow then
		if self.standing_in == "mcl_powder_snow:powder_snow"
			or self.standing_on == "mcl_powder_snow:powder_snow" then
			climbable = true
		end
	end

	-- If standing on a climable block and jumping or impeded
	-- horizontally, begin climbing, and prevent fall speed from
	-- exceeding 3.0 blocks/s.
	if (self.always_climb and horiz_collision (moveresult)) or climbable then
		if v.y < -3.0 then
			v.y = -3.0
		end
		v.x = clamp (v.x, -3.0, 3.0)
		v.z = clamp (v.z, -3.0, 3.0)
		if jumping or horiz_collision (moveresult) then
			v.y = 4.0
			jumping = false
			self._jump = false
		end
		climbing = true
		self.reset_fall_damage = true
	end

	-- In Minecraft, gravity is applied after being attenuated by
	-- gravity_drag, but acceleration is unaffected.
	-- Consequently, fv.y must be applied after fall_speed, with
	-- gravity_drag in between.
	local gravity_drag = 1
	if self.gravity_drag and ((not touching_ground and v.y < 0)
					or self._apply_gravity_drag_on_ground) then
		gravity_drag = self.gravity_drag
	end

	local water_vec = self:check_water_flow (attach_pos)
	local velocity_factor = 1.0
	local liquidtype = self._last_liquidtype
		or (self.floats_on_lava and self._liquidtype == "lava"
			and "lava")

	if self._soul_speed_level <= 0
		or not standon.groups.soul_block
		or standon.groups.soul_block <= 0 then
		velocity_factor = standon._mcl_velocity_factor or 1.0
	end

	if liquidtype == "water" then
		local saved_vy = v.y
		local water_friction = self.water_friction
		if self._sprinting then
			water_friction = SPRINTING_WATER_DRAG
		end
		local friction = water_friction * velocity_factor
		local speed = self.water_velocity

		-- Apply depth strider.
		local level = math.min (3, self._depth_strider_level)
		level = touching_ground and level or level / 2
		if level > 0 then
			local delta = BASE_FRICTION * AIR_FRICTION - friction
			friction = friction + delta * level / 3
			delta = acc_speed - speed
			speed = speed + delta * level / 3
		end

		-- Adjust speed by friction.  Minecraft applies
		-- friction to acceleration (speed), not just the
		-- previous velocity.
		local r, z = pow_by_step (friction, dtime), friction
		local base_water_drag = WATER_DRAG * gravity_drag
		local p = pow_by_step (base_water_drag, dtime)
		h_scale = (1 - r) / (1 - z)
		v_scale = (1 - p) / (1 - base_water_drag)

		local speed_x, speed_y = speed * h_scale, speed * v_scale
		local fv_x, fv_y, fv_z
			= self:accelerate_relative (acc_dir, speed_x, speed_y)

		-- Apply friction and acceleration.
		v.x = v.x * r + fv_x
		v.y = v.y * p
		v.z = v.z * r + fv_z

		-- Apply vertical acceleration.
		v.y = v.y + fv_y

		-- Apply gravity unless this mob is sprinting.
		if not self._sprinting then
			v.y = v.y + fall_speed / 16 * v_scale
			if v.y > -0.06 and v.y < 0 then
				v.y = -0.06
			end
		end

		-- If colliding horizontally within water, detect
		-- whether the result of this movement is vertically
		-- within 0.6 nodes of a position clear of water and
		-- collisions, and apply a force to this mob so as to
		-- breach the water if so.
		if horiz_collision (moveresult) then
			local traveled = saved_vy * dtime
			local diff_tick = v.y * 0.05
			local dx = v.x * 0.05
			local dy = diff_tick + 0.6 - traveled
			local dz = v.z * 0.05
			local will_breach_water
				= self:will_breach_water (attach_pos, dx, dy, dz)
			if will_breach_water then
				v.y = 6.0
			end
		end
	elseif liquidtype == "lava" then
		if not self.floats_on_lava then
			local saved_vy = v.y
			local speed = LAVA_SPEED
			local r, z = pow_by_step (LAVA_FRICTION, dtime), LAVA_FRICTION
			h_scale = (1 - r) / (1 - z)
			v_scale, p = h_scale, r

			-- If this mob is not submerged in lava to a
			-- depth of LIQUID_JUMP_THRESHOLD, apply a
			-- reduced drag.
			local depth = self._immersion_depth
			if depth <= LIQUID_JUMP_THRESHOLD then
				p = pow_by_step (JUMPING_LAVA_DRAG, dtime)
				v_scale = (1 - p) / (1 - JUMPING_LAVA_DRAG)
			end

			local speed_x, speed_y
				= speed * h_scale, speed * v_scale
			local fv_x, fv_y, fv_z
				= self:accelerate_relative (acc_dir, speed_x, speed_y)
			v.x = v.x * r + fv_x
			v.y = v.y * p
			v.z = v.z * r + fv_z
			v.y = v.y + (fall_speed / 4.0) * v_scale
			v.y = v.y + fv_y

			-- If colliding horizontally within lava,
			-- detect whether the result of this movement
			-- is vertically within 0.6 nodes of a
			-- position clear of lava and collisions, and
			-- apply a force to this mob so as to breach
			-- the water if so.
			if horiz_collision (moveresult) then
				local traveled = saved_vy * dtime
				local diff_tick = v.y * 0.05
				local dx = v.x * 0.05
				local dy = diff_tick + 0.6 - traveled
				local dz = v.z * 0.05
				local will_breach_lava
					= self:will_breach_water (attach_pos, dx, dy, dz)
				if will_breach_lava then
					v.y = 6.0
				end
			end
		else
			local speed = acc_speed
			local r, z = pow_by_step (BASE_FRICTION, dtime), BASE_FRICTION
			h_scale = (1 - r) / (1 - z)
			speed = speed * h_scale

			local fv_x, _, fv_z
				= self:accelerate_relative (acc_dir, speed, speed)
			v.x = v.x * r + fv_x
			v.z = v.z * r + fv_z

			p = pow_by_step (WATER_DRAG, dtime)
			v_scale = (1 - p) / (1 - WATER_DRAG)
			v.y = v.y * p
		end
	else
		-- If not standing on air, apply slippery to a base value of
		-- 0.6.
		local slippery = standon.groups.slippery
		local friction
		-- The order in which Minecraft applies velocity is
		-- such that it is scaled by ground friction after
		-- application even if vertical acceleration would
		-- render the mob airborne.  Emulate this behavior, in
		-- order to avoid a marked disparity in the speed of
		-- mobs that jump while in motion or walk off ledges.
		if self._was_touching_ground
			and slippery and slippery > 0 then
			if slippery > 3 then
				friction = BASE_SLIPPERY_1
			else
				friction = BASE_SLIPPERY
			end
		elseif self._was_touching_ground then
			friction = BASE_FRICTION
		else
			friction = 1
		end

		-- Apply friction, relative movement, and speed.
		local speed

		if touching_ground or climbing
			or self._airborne_agile then
			speed = scale_speed (acc_speed, friction)
		else
			speed = 0.4 -- 0.4 blocks/s
		end
		-- Apply friction (velocity_factor) from Soul Sand and
		-- the like.  NOTE: this friction is supposed to be
		-- applied after movement, just as with standard
		-- friction.
		friction = friction * AIR_FRICTION * velocity_factor

		-- Adjust speed by friction.  Minecraft applies
		-- friction to acceleration (speed), not just the
		-- previous velocity.  The manner in which friction is
		-- applied to acceleration is very peculiar, in that
		-- mobs are moved by the original speed each tick,
		-- before the modified speed is integrated into the
		-- velocity.
		--
		-- In Minetest, this is emulated by integrating the
		-- full speed into the velocity after applying
		-- friction to the same, which is more logical anyway.
		local base_air_drag = AIR_DRAG * gravity_drag
		local r, z = pow_by_step (friction, dtime), friction
		local p = pow_by_step (base_air_drag, dtime)
		h_scale = (1 - r) / (1 - z)
		v_scale = (1 - p) / (1 - base_air_drag)
		local speed_x, speed_y = speed * h_scale, speed * v_scale
		local fv_x, fv_y, fv_z
			= self:accelerate_relative (acc_dir, speed_x, speed_y)
		v.x = v.x * r + fv_x
		v.y = v.y * p + fall_speed * v_scale * base_air_drag
		v.z = v.z * r + fv_z
		v.y = v.y + fv_y
	end

	if water_vec ~= nil and vector.length (water_vec) ~= 0 then
		v.x = v.x + water_vec.x * h_scale
		v.y = v.y + water_vec.y * v_scale
		v.z = v.z + water_vec.z * h_scale
	end

	if jumping then
		if liquidtype then
			if self.floats == 1 or self.floats_on_lava then
				v.y = v.y + LIQUID_JUMP_FORCE * v_scale
			else
				v.y = v.y + LIQUID_JUMP_FORCE_ONESHOT
			end
		else
			if touching_ground
				and (not self.jump_timer or self.jump_timer <= 0) then
				local force = self:get_jump_force (moveresult)
				v = self:jump_actual (v, force)
				self.jump_timer = 0.2
			end
		end
	end

	-- Step height should always be configured to zero while not
	-- standing.  This might be slightly counter-intuitive, but it
	-- enables jumping to function correctly when the mob is
	-- accelerating forward.
	local enable_step_height = touching_ground or always_enable_step_height
	if enable_step_height and self._previously_floating then
		self._previously_floating = false
		self.object:set_properties ({stepheight = self._initial_step_height})
	elseif not enable_step_height and not self._previously_floating then
		self._previously_floating = true
		self.object:set_properties ({stepheight = 0.0})
	end

	-- Clear the jump flag even when jumping is not yet possible.
	self._jump = false
	self._was_touching_ground = touching_ground
	self:check_collision (attach_pos, v, h_scale)
	self.object:set_velocity (v)
	return h_scale, v_scale
end

-- Simplified `motion_step' for true (i.e., not birds or blazes)
-- flying mobs unaffected by gravity (i.e., not ghasts).

function mob_class:flying_step (dtime, moveresult, attach_pos)
	if not moveresult then
		return
	end
	local standin = core.registered_nodes[self.standing_in]
	local standon = core.registered_nodes[self.standing_on]
	local touching_ground = moveresult.touching_ground
		or moveresult.standing_on_object
	local v = self.object:get_velocity ()
	local p = pow_by_step (AIR_DRAG, dtime)
	local acc_dir = self.acc_dir
	local speed, scale

	acc_dir.x = acc_dir.x * p
	acc_dir.z = acc_dir.z * p

	if standin.groups.water and standin.groups.water > 0 then
		speed = FLYING_LIQUID_SPEED
		p = pow_by_step (WATER_DRAG, dtime)
		scale = (1 - p) / (1 - WATER_DRAG)
	elseif standin.groups.lava and standin.groups.lava > 0 then
		speed = FLYING_LIQUID_SPEED
		p = pow_by_step (LAVA_FRICTION, dtime)
		scale = (1 - p) / (1 - LAVA_FRICTION)
	else
		local slippery = standon.groups.slippery
		local friction

		if touching_ground and slippery and slippery > 0 then
			if slippery > 3 then
				friction = BASE_SLIPPERY_1 * AIR_FRICTION
			else
				friction = BASE_SLIPPERY * AIR_FRICTION
			end
			speed = scale_speed_flying (FLYING_GROUND_SPEED, friction)
		elseif touching_ground then
			friction = BASE_FRICTION * AIR_FRICTION
			speed = scale_speed_flying (FLYING_GROUND_SPEED, friction)
		else
			friction = AIR_FRICTION
			speed = FLYING_AIR_SPEED
		end
		p = pow_by_step (friction, dtime)
		scale = (1 - p) / (1 - friction)
	end

	local speed = speed * scale
	local fv_x, fv_y, fv_z = self:accelerate_relative (acc_dir, speed, speed)
	v.x = v.x * p + fv_x
	v.y = v.y * p + fv_y
	v.z = v.z * p + fv_z
	self._previously_floating = true
	self.object:set_properties ({stepheight = 0.0})
	self:check_collision (attach_pos, v, scale)
	self.object:set_velocity (v)
end

-- Simplified `motion_step' for true (i.e., not birds or blazes)
-- swimming mobs.

local default_motion_step = mob_class.motion_step

function mob_class:aquatic_step (dtime, moveresult, attach_pos)
	if not moveresult then
		return
	end

	local standin = core.registered_nodes[self.standing_in]
	if standin.groups.water and standin.groups.water > 0 then
		local acc_speed = self.acc_speed
		local acc_dir = self.acc_dir
		local acc_fixed = self._acc_y_fixed or 0
		local p = pow_by_step (AIR_DRAG, dtime)
		local v = self.object:get_velocity ()

		acc_dir.x = acc_dir.x * p
		acc_dir.z = acc_dir.z * p
		p = pow_by_step (AQUATIC_WATER_DRAG, dtime)
		local scale = (1 - p) / (1 - AQUATIC_WATER_DRAG)

		local speed = acc_speed * scale
		local fv_x, fv_y, fv_z
			= self:accelerate_relative (acc_dir, speed, speed)
		v.x = v.x * p + fv_x
		v.y = v.y * p + fv_y + acc_fixed * scale
		v.z = v.z * p + fv_z

		-- Apply gravity unless attacking mob.
		if not self.attacking and not self._acc_no_gravity then
			v.y = v.y + AQUATIC_GRAVITY * scale
		end

		self:check_collision (attach_pos, v, scale)
		self.object:set_velocity (v)
		self._previously_floating = true
		self.object:set_properties ({stepheight = 0.0})
	else
		default_motion_step (self, dtime, moveresult, attach_pos)
	end
end

mcl_mobs.mob_class.slowdown_nodes = {
	["mcl_farming:sweet_berry_bush_0"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_farming:sweet_berry_bush_1"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_farming:sweet_berry_bush_2"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_farming:sweet_berry_bush_3"] = {
		x = 0.8,
		y = 0.75,
		z = 0.8,
	},
	["mcl_core:cobweb"] = {
		x = 0.25,
		y = 0.05,
		z = 0.25,
	},
	["mcl_powder_snow:powder_snow"] = {
		x = 0.9,
		y = 1.5,
		z = 0.9,
	},
}

local function standing_in_liquid_or_walkable (self)
	if self.standing_in == "air" then
		return false
	end
	local def = core.registered_nodes[self.standing_in]
	return not def and def.liquidtype ~= "flowing" and not def.walkable
end

function mob_class:display_sprinting_particles ()
	-- Don't display such particles if standing in a liquid or
	-- similar block.
	return self._sprinting and not self._crouching
		and not standing_in_liquid_or_walkable (self)
end

local get_node_raw = mcl_mobs.get_node_raw

local function get_node (nodepos)
	if get_node_raw then
		local x, y, z = nodepos.x, nodepos.y, nodepos.z
		local id, _, param2 = get_node_raw (x, y, z)
		return core.get_name_from_content_id (id), param2
	else
		local node = core.get_node (nodepos)
		return node.name, node.param2
	end
end

function mob_class:check_one_immersion_depth (node, param2, base_y, pos, current, dimension)
	local def = core.registered_nodes [node]
	local liquid_type = def and (def.liquidtype or def._liquidtype)
	if liquid_type and liquid_type ~= "none" then
		local height
		if def.liquid_type == "flowing" then
			height = 0.1 + param2 * 0.1
		else
			height = 1.0
		end
		if pos.y + height - 0.5 > base_y then
			local depth = ((pos.y - 0.5) + height - base_y)
			if not self.swims then
				local fluidtype
				-- Integrate liquid current.
				local v = flowlib.quick_flow (pos, {
					name = node,
					param2 = param2,
				})

				if depth < 0.4 then
					v.x = v.x * depth
					v.y = v.y * depth
					v.z = v.z * depth
				end

				if def.groups.lava then
					fluidtype = "lava"
					local force = dimension == "nether"
						and LAVA_FORCE_NETHER or LAVA_FORCE
					current.x = current.x + v.x * force
					current.y = current.y + v.y * force
					current.z = current.z + v.z * force
				else
					fluidtype = "water"
					current.x = current.x + v.x * LIQUID_FORCE
					current.y = current.y + v.y * LIQUID_FORCE
					current.z = current.z + v.z * LIQUID_FORCE
				end
				return depth, fluidtype
			end
			if def.groups.lava then
				return depth, "lava"
			else
				return depth, "water"
			end
		end
	end
	return 0.0, nil
end

local check_standin_scratch = vector.zero ()
local params = {}

local function check_node_group (def, group)
	-- N.B. that in fact this is equivalent to:
	-- ((def && def->groups[group]) ? def->groups[group] : 0)
	return (def and def.groups[group] or 0) > 0
end

function mob_class:check_standin (dtime, attach_pos)
	local cbox = self.collisionbox
	local x0 = mathfloor (cbox[1] + attach_pos.x + 0.5 + 0.01)
	local x1 = mathfloor (cbox[4] + attach_pos.x + 0.5 - 0.01)
	local y0 = mathfloor (cbox[2] + attach_pos.y + 0.5 + 0.01)
	local y1 = mathfloor (cbox[5] + attach_pos.y + 0.5 - 0.01)
	local z0 = mathfloor (cbox[3] + attach_pos.z + 0.5 + 0.01)
	local z1 = mathfloor (cbox[6] + attach_pos.z + 0.5 - 0.01)
	local immersion_depth = 0.0
	local worst_type = nil
	local v = check_standin_scratch
	local current = self._water_current
	current.x = 0
	current.y = 0
	current.z = 0
	local n_fluids = 0
	local dimension = mcl_worlds.pos_to_dimension (attach_pos)

	params.in_powder_snow = false
	params.in_fire_node = false
	params.in_soul_fire_node = false
	params.in_solid_node = false
	params.dps = 0

	local eye_height = self:get_eye_height () + attach_pos.y

	for y = y0, y1 do
		local in_eyeline = y - 0.5 <= eye_height
			and y + 0.5 >= eye_height
		for x = x0, x1 do
			for z = z0, z1 do
				v.x = x
				v.y = y
				v.z = z
				local node, param2 = get_node (v)
				local depth, liquidtype
					= self:check_one_immersion_depth (node, param2,
									  attach_pos.y,
									  v, current,
									  dimension)
				immersion_depth = mathmax (depth, immersion_depth)
				if liquidtype then
					n_fluids = n_fluids + 1

					if worst_type ~= "lava" then
						worst_type = liquidtype
					end
				end
				local factors = self.slowdown_nodes[node]
				if factors then
					self._stuck_in = factors
				end
				local def = core.registered_nodes[node]
				if node == "mcl_powder_snow:powder_snow" then
					params.in_powder_snow = true
				elseif node == "mcl_blackstone:soul_fire" then
					params.in_soul_fire_node = true
				elseif check_node_group (def, "fire") then
					params.in_fire_node = true
				elseif not check_node_group (def, "lava") then
					if in_eyeline
						and node ~= "air"
						and check_node_group (def, "opaque")
						and check_node_group (def, "solid") then
						if not check_node_group (def, "disable_suffocation") then
							params.in_solid_node = true
						end
					end
					local dps = def and def.damage_per_second or 0
					params.dps = mathmax (params.dps, dps)
				end
			end
		end
	end
	if n_fluids > 0 then
		current.x = current.x / n_fluids
		current.y = current.y / n_fluids
		current.z = current.z / n_fluids
	end
	self:apply_environment_damage (attach_pos, immersion_depth, worst_type, params, dtime)
	return immersion_depth, worst_type
end

function mob_class:post_motion_step (attach_pos, dtime, moveresult)
	-- Apply slowdowns from blocks that should impede movement.
	local slowdown = self._stuck_in
	if slowdown then
		local v = self.object:get_velocity ()
		v.x = v.x * pow_by_step (slowdown.x, dtime)
		v.y = v.y * pow_by_step (slowdown.y, dtime)
		v.z = v.z * pow_by_step (slowdown.z, dtime)
		self.object:set_velocity (v)
		self._stuck_in = nil
		-- Indicate that the velocity must be reset
		-- upon the next globalstep
		self._was_stuck = true
	end

	self._last_standing_in = self.standing_in
	self._last_standing_on = self.standing_on
	self._last_liquidtype = self._liquidtype

	----------------------------------------------------------------
	-- Sprinting particles.
	----------------------------------------------------------------

	-- Generate sprinting particles if and standing on a surface
	-- appropriate.
	if self:display_sprinting_particles () then
		local def = core.registered_nodes[self.standing_on]
		if def and def.walkable then
			local p2 = self.standing_on_param2
			local p2_type = def.paramtype2
			local tile = mcl_sprint.get_top_node_tile (p2, p2_type)
			local v = self.object:get_velocity ()
			local xwidth = (self.collisionbox[4] - self.collisionbox[1]) / 2
			local zwidth = (self.collisionbox[6] - self.collisionbox[3]) / 2
			v.x = v.x * -0.2
			v.z = v.z * -0.2
			v.y = 2.15
			core.add_particlespawner ({
					amount = math.random (1, 2),
					time = 1,
					minpos = {
						x = -xwidth,
						y = 0.1,
						z = -zwidth,
					},
					maxpos = {
						x = xwidth,
						y = 0.1,
						z = zwidth,
					},
					minvel = v,
					maxvel = v,
					minexptime = 0.1,
					maxexptime = 1.5,
					minacc = {
						x = 0,
						y = -13,
						z = 0,
					},
					maxacc = {
						x = 0,
						y = -13,
						z = 0,
					},
					collisiondetection = true,
					attached = self.object,
					vertical = false,
					node = {
						name = self.standing_on,
						param2 = p2,
					},
					node_tile = tile,
			})
		end
	end

	local def = core.registered_nodes[self.standing_in]
	if def._on_object_in then
		-- This is a workaround to prevent excess table allocations
		local saved_y_pos = attach_pos.y
		local foot_pos = self.collisionbox[2] + 1.0e-2
		attach_pos.y = mathfloor (attach_pos.y + foot_pos + 0.5)
		local def = core.registered_nodes[self.standing_in]
		local node = mcl_mobs.node_ok (attach_pos, "air")
		def._on_object_in (attach_pos, node, self.object)
		attach_pos.y = saved_y_pos
	end
end
