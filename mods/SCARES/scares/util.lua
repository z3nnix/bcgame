-- Scares framework: shared utilities (eye contact, line of sight,
-- facing a target, finding safe spawn positions).

scares.util = {}

local settings = scares.settings

---Get the node definition at a position (nil if not registered).
local function get_node_def(pos)
	local node = core.get_node_or_nil(pos)
	if not node then
		return nil
	end
	return core.registered_nodes[node.name]
end

---True if the node at pos blocks sight and movement.
local function is_walkable(pos)
	local def = get_node_def(pos)
	return def ~= nil and def.walkable == true
end

---True if a scare entity can stand at pos (open node with walkable floor
---and enough headroom).
function scares.util.is_standable(pos)
	local def = get_node_def(pos)
	if not def or def.walkable or def.liquidtable then
		return false
	end
	if not is_walkable({ x = pos.x, y = pos.y - 1, z = pos.z }) then
		return false
	end
	local up = get_node_def({ x = pos.x, y = pos.y + 1, z = pos.z })
	if up and (up.walkable or up.liquidtable) then
		return false
	end
	return true
end

---Scan downward from pos and return the first standable position, or nil.
function scares.util.find_ground(pos, max_drop)
	max_drop = max_drop or 12
	local y = math.floor(pos.y)
	for dy = 0, -max_drop, -1 do
		local p = { x = pos.x, y = y + dy, z = pos.z }
		if scares.util.is_standable(p) then
			return p
		end
	end
	return nil
end

---Find a standable position within [min_dist, max_dist] of center.
---Optionally avoids spots the player is already looking at.
function scares.util.find_scare_pos(center, min_dist, max_dist, player, avoid_eye_contact)
	local tries = 30
	for _ = 1, tries do
		local angle = math.random() * 2 * math.pi
		local dist = min_dist + math.random() * (max_dist - min_dist)
		local ground = scares.util.find_ground({
			x = center.x + math.cos(angle) * dist,
			y = center.y + 1,
			z = center.z + math.sin(angle) * dist,
		})
		if ground then
			local ok = true
			if avoid_eye_contact then
				local eye = { x = ground.x, y = ground.y + scares.EYE_HEIGHT, z = ground.z }
				if scares.util.player_looking_at(player, eye) then
					ok = false
				end
			end
			if ok then
				return ground
			end
		end
	end
	return nil
end

---True if there is a clear (no walkable node) path between pos1 and pos2.
function scares.util.line_of_sight(pos1, pos2)
	local ray = core.raycast(pos1, pos2, false, false)
	for pointed in ray do
		if pointed.type == "node" and is_walkable(pointed.under) then
			return false
		end
	end
	return true
end

---True if `player` is looking (roughly) straight at position `pos`.
function scares.util.player_looking_at(player, pos)
	if not player or not player:is_player() then
		return false
	end
	local ppos = mcl_util.target_eye_pos(player)
	if not ppos then
		return false
	end
	local distance = vector.distance(ppos, pos)
	if distance < 1 then
		return false
	end
	local look_dir = player:get_look_dir()
	local direction = vector.direction(ppos, pos)
	local dot = vector.dot(look_dir, direction)
	if dot < 1.0 - scares.settings.eye_strictness / distance then
		return false
	end
	return scares.util.line_of_sight(ppos, pos)
end

---Rotate an object so its model always faces the target position.
---Uses the engine's canonical yaw convention (core.dir_to_yaw: models
---face +Z at yaw 0), so the direction is resolved by the engine, not
---by hand-rolled atan2 that depends on the model's orientation.
function scares.util.face_target(obj, target)
	local pos = obj:get_pos()
	if not pos or not target then
		return
	end
	obj:set_yaw(core.dir_to_yaw(vector.direction(pos, target)))
end
