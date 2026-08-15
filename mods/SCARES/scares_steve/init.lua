-- First test scare: "Steve".
-- A Steve (default player skin on the player model) spawns 8-20 blocks
-- from the player, stands dead-still while always facing the player, and
-- vanishes the instant the player meets its gaze (eye contact).

local EYE_HEIGHT = scares.EYE_HEIGHT
local REMOVE_DISTANCE = 24
local CLOSE_DISTANCE = 5
local CONTACT_TIME = 0.25

core.register_entity("scares_steve:steve", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_armor_character.b3d",
		textures = { "character.png", "scares_steve_blank.png" },
		visual_size = { x = 1, y = 1 },
		physical = false,
		collisionbox = { -0.35, 0, -0.35, 0.35, 1.8, 0.35 },
		selectionbox = { 0, 0, 0, 0, 0, 0 },
		pointable = false,
		nametag = "",
		hp_max = 1,
		damage_texture_modifier = "",
		static_save = false,
	},
	on_activate = function(self)
		self._contact = 0
		self.object:set_animation({ x = 0, y = 79 }, 0)
	end,
	on_step = function(self, dtime)
		local player = self.player_name and core.get_player_by_name(self.player_name)
		if not player then
			self.object:remove()
			return
		end
		local pos = self.object:get_pos()
		if not pos then
			return
		end
		local ppos = player:get_pos()
		if not ppos then
			self.object:remove()
			return
		end
		-- Failsafe: drift out of range -> despawn.
		-- Too close: don't let the player approach the scare -> vanish.
		local dist = vector.distance(pos, ppos)
		if dist > REMOVE_DISTANCE or dist < CLOSE_DISTANCE then
			self.object:remove()
			return
		end
		-- Always stare straight at the player: body turns, head tilts.
		scares.util.face_target(self.object, ppos)
		local eye = { x = pos.x, y = pos.y + EYE_HEIGHT, z = pos.z }
		local player_eye = mcl_util.target_eye_pos(player)
		local dx = player_eye.x - eye.x
		local dy = player_eye.y - eye.y
		local dz = player_eye.z - eye.z
		local horiz = math.sqrt(dx * dx + dz * dz)
		if horiz > 0.1 then
			local pitch = math.deg(math.atan2(dy, horiz))
			mcl_util.set_bone_position(self.object, "Head_Control", nil,
				{ x = math.max(-60, math.min(60, pitch)), y = 0, z = 0 })
		end
		-- Eye contact: the player looks straight at the scare's face.
		if scares.util.player_looking_at(player, eye) then
			self._contact = self._contact + dtime
			if self._contact >= CONTACT_TIME then
				self.object:remove()
			end
		else
			self._contact = 0
		end
	end,
})

scares.register_event({
	id = "scares_steve:steve",
	name = "Steve",
	weight = 1,
	min_distance = 8,
	max_distance = 20,
	duration = 30,
	on_spawn = function(ctx)
		local player = ctx.player
		local ppos = player:get_pos()
		if not ppos then
			return nil
		end
		local spawn_pos = scares.util.find_scare_pos(ppos, ctx.event.min_distance,
			ctx.event.max_distance, player, true)
		if not spawn_pos then
			return nil
		end
		local obj = core.add_entity(spawn_pos, "scares_steve:steve")
		if not obj then
			return nil
		end
		obj:get_luaentity().player_name = player:get_player_name()
		return obj
	end,
})
