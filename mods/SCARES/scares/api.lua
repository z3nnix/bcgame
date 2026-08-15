-- Scares framework: core event-driven API.
-- Scare mods register "events" via scares.register_event(); the scheduler
-- (scheduler.lua) triggers them periodically for each player and drives
-- their lifecycle through on_spawn / on_update / on_finish hooks.

scares.events = {}
scares.state = {}
scares.clock = 0

---Register a scare event.
--@param def Event definition:
--   id          string, required, unique
--   name        string, display name (defaults to id)
--   weight      number, relative pick probability (default 1)
--   min_distance, max_distance  spawn distance range from the player
--   duration    number, failsafe lifetime in seconds (nil = unlimited)
--   on_spawn    function(ctx) -> obj | nil, materializes the scare;
--               returns the spawned entity or nil on failure
--   on_update   function(ctx, dtime), called every tick while active
--   on_finish   function(ctx, reason), called when the scare ends.
--               Reasons: "ended" (entity gone), "timeout", "spawn_failed",
--               "player_left", "disabled".
function scares.register_event(def)
	assert(type(def.id) == "string" and def.id ~= "", "scares: event needs a non-empty 'id'")
	assert(not scares.events[def.id], "scares: duplicate event id '" .. def.id .. "'")
	def.name = def.name or def.id
	def.weight = def.weight or 1
	scares.events[def.id] = def
end

---List registered event ids (sorted).
function scares.list_event_ids()
	local ids = {}
	for id in pairs(scares.events) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

---Pick a random event weighted by `weight`.
function scares.pick_random_event()
	local total = 0
	for _, def in pairs(scares.events) do
		total = total + def.weight
	end
	if total <= 0 then
		return nil
	end
	local r = math.random() * total
	for _, def in pairs(scares.events) do
		r = r - def.weight
		if r <= 0 then
			return def
		end
	end
	return nil
end

---Get (and lazily create) the per-player state table.
--The state carries an accumulating counter (`credit`) and the current
--counter target (`target`). The scheduler adds dtime to `credit` every
--tick and attempts a scare once `credit` reaches `target`. A successful
--scare resets the counter; a failed spawn does NOT reset it, so the
--player is guaranteed to meet an event within `interval_max` at worst.
function scares.get_player_state(player)
	local pname = player:get_player_name()
	local pstate = scares.state[pname]
	if not pstate then
		pstate = {
			credit = 0,
			target = scares.random_interval(),
		}
		scares.state[pname] = pstate
	else
		if pstate.credit == nil then
			pstate.credit = 0
		end
		if pstate.target == nil then
			pstate.target = scares.random_interval()
		end
	end
	return pstate
end

---Random interval in seconds until the next scare attempt.
function scares.random_interval()
	local mn = scares.settings.interval_min
	local mx = math.max(mn, scares.settings.interval_max)
	return mn + math.random() * (mx - mn)
end

---Short delay before retrying a scare whose spawn failed.
--The accumulated credit is kept, so the retry only delays the attempt,
--never cancels it.
function scares.retry_delay()
	return 10 + math.random() * 20
end

---Trigger a scare for a player.
--@param player  ObjectRef of the target player
--@param event_id string|nil, optional specific event id
--@return ctx on success, nil otherwise
function scares.trigger(player, event_id)
	local pstate = scares.get_player_state(player)

	if not scares.settings.enabled then
		return nil
	end

	local def = event_id and scares.events[event_id]
	if not def and not event_id then
		def = scares.pick_random_event()
	end
	if not def then
		-- No events registered: don't spin, wait a full interval.
		pstate.target = scares.random_interval()
		return nil
	end

	local ctx = {
		player = player,
		pname = player:get_player_name(),
		event = def,
		entity = nil,
		data = {},
		started = scares.clock,
	}
	if def.on_spawn then
		ctx.entity = def.on_spawn(ctx)
	end
	if not ctx.entity or not ctx.entity:get_pos() then
		scares.finish_ctx(ctx, "spawn_failed")
		-- Accumulation: keep the credit and retry shortly instead of
		-- resetting the counter, so the scare is eventually guaranteed.
		pstate.target = scares.retry_delay()
		return nil
	end
	-- Success: reset the accumulating counter for the next scare.
	pstate.credit = 0
	pstate.target = scares.random_interval()
	pstate.active = ctx
	return ctx
end

---End the active scare of a player (if any).
function scares.finish(player, reason)
	local pstate = scares.state[player:get_player_name()]
	if not pstate then
		return
	end
	scares.finish_ctx(pstate.active, reason)
end

---Teardown a context: run on_finish and remove the entity.
function scares.finish_ctx(ctx, reason)
	if not ctx then
		return
	end
	local pstate = scares.state[ctx.pname]
	if pstate and pstate.active == ctx then
		pstate.active = nil
	end
	if ctx.event and ctx.event.on_finish then
		ctx.event.on_finish(ctx, reason)
	end
	if ctx.entity and ctx.entity:get_pos() then
		ctx.entity:remove()
	end
end
