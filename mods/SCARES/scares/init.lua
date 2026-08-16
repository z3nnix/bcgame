-- Scares framework: event-driven scare modpack core.
-- Loads the API, utilities and scheduler, reads settings and provides
-- the /scare chat command for manual testing.

scares = {}
scares.EYE_HEIGHT = 1.62

local function sget(name, default)
	local v = core.settings:get(name)
	if v == nil or v == "" then
		return default
	end
	return tonumber(v) or default
end

scares.settings = {
	enabled = core.settings:get_bool("scares_enabled", true),
	interval_min = sget("scares_interval_min", 1800),
	interval_max = sget("scares_interval_max", 2700),
	eye_strictness = sget("scares_eye_contact_strictness", 0.03),
}

local modpath = core.get_modpath(core.get_current_modname())
dofile(modpath .. "/api.lua")
dofile(modpath .. "/util.lua")
dofile(modpath .. "/scheduler.lua")

core.register_chatcommand("scare", {
	params = "[event_id] [player_name]",
	description = "Trigger a scare event. Without arguments a random event is picked. Optionally pick a specific event_id and/or target another player.",
	privs = { interact = true },
	func = function(name, param)
		local event_id, target_name = param:match("^(%S*)%s*(%S*)$")
		if event_id == "" then event_id = nil end
		if target_name == "" then target_name = nil end

		local target = target_name and core.get_player_by_name(target_name) or core.get_player_by_name(name)
		if not target then
			return false, "Player not found."
		end
		if event_id and not scares.events[event_id] then
			return false, "Unknown scare event '" .. event_id .. "'. Known: " .. table.concat(scares.list_event_ids(), ", ")
		end

		local ctx = scares.trigger(target, event_id)
		if ctx then
			return true, "Scare '" .. ctx.event.name .. "' triggered."
		end
		return false, "No scare event is registered, or no valid spawn position was found."
	end,
})
