mcl_attachments = {}

------------------------------------------------------------------------
-- Object attachment API.
--
-- Objects attached at an offset to their parents are considered by
-- the server to exist at the position of the parent without regard to
-- the offset.  This prevents raycasts and other mechanisms from
-- effectively targeting mobs and players which are attached to other
-- objects.
--
-- This module provides an entity whose selection box is increased to
-- encompass approximations of the client-side selection boxes of
-- attached entities, in order to intercept raycasts and redirect them
-- to the entities which should actually exist at their positions.
--
-- TODO
--  [X] Test all of the mobs which have been modified.
--  [X] Restore compatibility with older CSM clients.
--  [ ] Implement support for object iterators.
--  [X] Environmental damage for mobs.
--  [ ] Environmental damage for players.
------------------------------------------------------------------------

local mathsin = math.sin
local mathcos = math.cos

------------------------------------------------------------------------
-- Utility functions.
------------------------------------------------------------------------

local function vector_rotate (v, rot)
	local sinpitch = mathsin (-rot.x)
	local sinyaw = mathsin (-rot.y)
	local sinroll = mathsin (-rot.z)
	local cospitch = mathcos (rot.x)
	local cosyaw = mathcos (rot.y)
	local cosroll = mathcos (rot.z)
	local matrix = {
		{
			sinyaw * sinpitch * sinroll + cosyaw * cosroll,
			sinyaw * sinpitch * cosroll - cosyaw * sinroll,
			sinyaw * cospitch,
		},
		{
			cospitch * sinroll,
			cospitch * cosroll,
			-sinpitch,
		},
		{
			cosyaw * sinpitch * sinroll - sinyaw * cosroll,
			cosyaw * sinpitch * cosroll + sinyaw * sinroll,
			cosyaw * cospitch,
		},
	}
	local vx = v.x
	local vy = v.y
	local vz = v.z
	v.x = matrix[1][1] * vx + matrix[1][2] * vy + matrix[1][3] * vz
	v.y = matrix[2][1] * vx + matrix[2][2] * vy + matrix[2][3] * vz
	v.z = matrix[3][1] * vx + matrix[3][2] * vy + matrix[3][3] * vz
end

local v = vector.zero ()

local function get_player_body_rotation (object)
	v.y = object:get_look_horizontal ()
	return v
end

local bones_warned = {}

local blurb = "[mcl_attachments]: Attempting to attach entity `%s' to parent `%s' at unknown bone `%s'."

local old_csm_offsets = {
	["mobs_mc:horse"] = 0.3,
	["mobs_mc:skeleton_horse"] = 0.3,
	["mobs_mc:zombie_horse"] = 0.3,
	["mobs_mc:donkey"] = 0.3,
	["mobs_mc:mule"] = 0.3,
}

local function add_selection_box_offset (object, v)
	local parent, bone, position, rotation, _
		= object:get_attach ()
	local entity = object:get_luaentity ()
	-- Equivalent to ((entity && old_csm_offsets[entity.name]))
	--                ? old_csm_offsets[entity.name] : 0.0)
	local eye_height = entity and old_csm_offsets[entity.name] or 0

	if not parent then
		local rot = object:get_rotation ()
			or get_player_body_rotation (object)
		vector_rotate (v, rot)
		return nil, eye_height
	end

	local parent_entity = parent:get_luaentity ()

	if entity then
		-- Apply any offset desired by the child.
		if entity._add_selection_box_offset then
			local rc = entity:_add_selection_box_offset (parent,
								     parent_entity,
								     bone, position)
			if rc then
				return parent, eye_height
			end
		end
	end

	if parent_entity then
		-- Apply any offset desired by the parent.
		local fn = parent_entity._add_child_selection_box_offset
		if fn then
			local rc = fn (parent_entity, object, entity, bone,
				       position, rotation)
			if rc then
				return parent, eye_height
			end
		end
	end

	-- Attempt to infer a suitable offset from the
	-- attachment parameters provided.
	local properties = parent:get_properties ()
	if bone ~= "" and not bones_warned[bone] then
		local entity_name = entity and entity.name or "player"
		local parent_name = parent_entity and parent_entity.name or "player"
		core.log ("warning", string.format (blurb, entity_name,
						    parent_name, bone))
		bones_warned[bone] = true
	end

	-- Caveat emptor: this function does not account for visual
	-- size elsewhere than in computing offsets.  If multiple
	-- objects are attached with inconsistent visual sizes, they
	-- must take pains to adjust their visual sizes correctly
	-- before `attach_to_object' is invoked.

	local visual_size = properties.visual_size
	vector_rotate (v, rotation)
	v.x = (v.x + position.x * 0.1) * visual_size.x
	v.y = (v.y + position.y * 0.1) * visual_size.y
	v.z = (v.z + position.z * 0.1) * visual_size.z
	return parent, eye_height
end

local function real_selection_box (position, input, obj)
	position.x = 0
	position.y = 0
	position.z = 0
	local object = obj
	local csm_eye_height
	repeat
		-- Return only the obsolete eye height offset of the
		-- mob which is genuinely being mounted.
		object, csm_eye_height
			= add_selection_box_offset (object, position)
	until not object

	local selection_box = obj:get_properties ().selectionbox

	-- Save the real selection box of this object with the
	-- attachment offset applied.
	local real_box = input
	real_box[1] = selection_box[1] + position.x
	real_box[2] = selection_box[2] + position.y
	real_box[3] = selection_box[3] + position.z
	real_box[4] = selection_box[4] + position.x
	real_box[5] = selection_box[5] + position.y
	real_box[6] = selection_box[6] + position.z
	return real_box, selection_box, csm_eye_height
end

------------------------------------------------------------------------
-- Debugging utilities.
------------------------------------------------------------------------

core.register_entity ("mcl_attachments:outline", {
	initial_properties = {
		visual = "cube",
		textures = {
			"mcl_levelgen_schematic_border_checkers.png",
			"mcl_levelgen_schematic_border_checkers.png",
			"mcl_levelgen_schematic_border_checkers.png",
			"mcl_levelgen_schematic_border_checkers.png",
			"mcl_levelgen_schematic_border_checkers.png",
			"mcl_levelgen_schematic_border_checkers.png",
		},
		visual_size = {x = 10, y = 10,},
		pointable = false,
		physical = false,
		static_save = false,
		glow = core.LIGHT_MAX,
		use_texture_alpha = true,
		backface_culling = false,
	},
	_age = 0,
	on_step = function (self, dtime)
		self._age = self._age + dtime
		if self._age > 10.0 then
			self.object:remove ()
		end
	end,
	on_activate = function (self)
		self.object:set_armor_groups ({immortal = 1,})
	end,
})

local function unpack_cbox (x, self_pos)
	local bx = self_pos.x
	local by = self_pos.y
	local bz = self_pos.z
	return x[1] + bx, x[2] + by, x[3] + bz,
		x[4] + bx, x[5] + by, x[6] + bz
end

local function display_attachment_bounds (itemstack, user, pointed_thing)
	if not (user and user:is_player ()) or pointed_thing.type ~= "object" then
		return
	end
	local obj_pos = pointed_thing.ref:get_pos ()
	local obj = core.add_entity (obj_pos, "mcl_attachments:outline")
	if obj then
		local real_box, _ = real_selection_box (vector.new (), {},
							pointed_thing.ref)
		local x1, y1, z1, x2, y2, z2
			= unpack_cbox (real_box, obj_pos)
		local pos = vector.new ((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
		obj:set_pos (pos)
		obj:set_properties ({
			visual_size = {
				x = (x2 - x1 + 0.01),
				y = (y2 - y1 + 0.01),
				z = (z2 - z1 + 0.01),
			},
		})
	end
end

core.register_tool ("mcl_attachments:attachment_dbg_tool", {
	description = "Debug attachment bounds",
	inventory_image = "default_stick.png",
	groups = { testtool = 1, disable_repair = 1,
		   not_in_creative_inventory = 1, },
	on_use = display_attachment_bounds,
})

------------------------------------------------------------------------
-- Interceptor entity.
------------------------------------------------------------------------

local interceptors_by_obj = {}

local interceptor_entity = {
	initial_properties = {
		visual = "cube",
		visual_size = vector.zero (),
		textures = {
			"mcl_core_glass_green.png",
			"mcl_core_glass_green.png",
			"mcl_core_glass_green.png",
			"mcl_core_glass_green.png",
			"mcl_core_glass_green.png",
			"mcl_core_glass_green.png",
		},
		pointable = false,
		collide_with_objects = false,
		selection_box = {
			0, 0, 0,
			0, 0, 0,
		},
		static_save = false,
	},

	_attached_obj = nil,
	_selection_box_offset = vector.zero (),
	_real_selection_box = nil,
	_last_cbox = nil,
}

function interceptor_entity:on_activate (_, _)
	self._real_selection_box = {
		0, 0, 0, 0, 0, 0,
	}
	self._last_cbox = {
		0, 0, 0, 0, 0, 0,
	}
	self._selection_box_offset = vector.zero ()
end

-- local us = 0

function interceptor_entity:update (obj)
	-- local clock = core.get_us_time ()
	local v = self._selection_box_offset
	local real_box, scratch, csm_eye_height
		= real_selection_box (v, self._real_selection_box, obj)
	local obj_pos = obj:get_pos ()
	local x1, y1, z1, x2, y2, z2
		= unpack_cbox (real_box, obj_pos)
	local cx = (x1 + x2) / 2
	local cy = (y1 + y2) / 2
	local cz = (z1 + z2) / 2
	obj_pos.x = cx
	obj_pos.y = cy
	obj_pos.z = cz
	self.object:set_pos (obj_pos)
	local last_cbox = self._last_cbox
	if x1 - cx ~= last_cbox[1]
		or y1 - cy ~= last_cbox[2]
		or z1 - cz ~= last_cbox[3]
		or x2 - cx ~= last_cbox[4]
		or y2 - cy ~= last_cbox[5]
		or z2 - cz ~= last_cbox[6] then
		scratch[1] = x1 - cx
		scratch[2] = y1 - cy
		scratch[3] = z1 - cz
		scratch[4] = x2 - cx
		scratch[5] = y2 - cy
		scratch[6] = z2 - cz
		self._last_cbox = scratch
		self.object:set_properties ({
			selectionbox = scratch,
		})
	end

	if obj:is_player () then
		obj_pos.y = v.y * 10.0
		obj_pos.x = 0
		obj_pos.z = 0

		if mcl_serverplayer.is_csm_capable (obj)
			and not mcl_serverplayer.is_csm_at_least (obj, 13) then
			-- Protocol versions before 13 required the
			-- client redundantly to adjust the eye height
			-- in the cases of some mobs, which is no
			-- longer necessary, as the eye height is now
			-- applied on the server and computed from a
			-- mob's attachment parameters.
			obj_pos.y = obj_pos.y - csm_eye_height * 10
		end
		obj:set_eye_offset (obj_pos, obj_pos, obj_pos)
	end
	-- us = us + (core.get_us_time () - clock)
end

-- core.register_globalstep (function ()
-- 	print (us)
-- 	us = 0
-- end)

function interceptor_entity:on_deactivate (_)
	if self._attached_obj then
		interceptors_by_obj[self._attached_obj] = nil
	end
end

function interceptor_entity:on_step (dtime)
	local obj = self._attached_obj
	if not obj or not obj:is_valid () or not obj:get_attach () then
		self.object:remove ()
		return
	end
	self:update (obj)
end

function interceptor_entity:attach_to_object (obj)
	if not obj:is_valid () then
		return false
	end
	self:update (obj)
	self._attached_obj = obj
	return true
end

core.register_entity ("mcl_attachments:interceptor", interceptor_entity)

------------------------------------------------------------------------
-- Attachment API.
------------------------------------------------------------------------

local RAYCAST_POINTABILITIES = {
	objects = {
		["mcl_attachments:interceptor"] = true,
	},
}

function mcl_attachments.raycast (pos1, pos2, objects, liquids)
	return core.raycast (pos1, pos2, objects, liquids,
			     RAYCAST_POINTABILITIES)
end

function mcl_attachments.raycast_intercept (v1, v2, pointed_thing)
	-- V1 and V2 must be provided so that it may be possible to
	-- adopt an approach where the selection box is as large as is
	-- necessary to encompass the real selection box, while the
	-- entity itself is attached to its parent, and a raycast is
	-- conducted by hand to establish whether an intersection
	-- exists.
	if pointed_thing.type == "object" then
		if interceptors_by_obj[pointed_thing.ref] then
			pointed_thing.type = nil
			return nil
		end

		local entity = pointed_thing.ref:get_luaentity ()
		if entity
			and entity.name == "mcl_attachments:interceptor"
			and entity._attached_obj
			and entity._attached_obj:is_valid () then
			pointed_thing.ref = entity._attached_obj
			-- Quare how pointed_thing.intersection_point
			-- should be adjusted, if at all.
			return pointed_thing
		end
	end

	return pointed_thing
end

function mcl_attachments.spawn_attachment_entity (obj)
	if interceptors_by_obj[obj] then
		local entity = interceptors_by_obj[obj]:get_luaentity ()
		if entity then
			entity:update (obj)
			return
		end
	end

	local interceptor
		= core.add_entity (obj:get_pos (), "mcl_attachments:interceptor")
	interceptors_by_obj[obj] = interceptor
	if interceptor then
		local entity = interceptor:get_luaentity ()
		entity:attach_to_object (obj)
	end
end

function mcl_attachments.remove_attachment_entity (obj)
	if interceptors_by_obj[obj] then
		interceptors_by_obj[obj]:remove ()
		interceptors_by_obj[obj] = nil
	end
end

-- This will always be one globalstep behind, which is acceptable,
-- since the vertical offset of a player seldom changes.  ATTACK may
-- be an invalid object, in which case `nil' is returned.

function mcl_attachments.get_attachment_pos (attack)
	local obj = interceptors_by_obj[attack]
	if obj then
		local entity = obj:get_luaentity ()
		local pos = attack:get_pos ()
		if pos then
			pos.x = pos.x + entity._selection_box_offset.x
			pos.y = pos.y + entity._selection_box_offset.y
			pos.z = pos.z + entity._selection_box_offset.z
		end
		return pos
	end
	return attack:get_pos ()
end

function mcl_attachments.get_attachment_offsets (attack)
	local obj = interceptors_by_obj[attack]
	if obj then
		local entity = obj:get_luaentity ()
		local x = entity._selection_box_offset.x
		local y = entity._selection_box_offset.y
		local z = entity._selection_box_offset.z
		return x, y, z
	end
	return 0, 0, 0
end

function mcl_attachments.maybe_get_attached_object (object)
	local entity = object:get_luaentity ()
	if entity
		and entity.name == "mcl_attachments:interceptor"
		and entity._attached_obj
		and entity._attached_obj:is_valid () then
		return entity._attached_obj
	elseif not interceptors_by_obj[object] then
		return object
	end
	return nil
end
