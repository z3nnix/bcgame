-- Scares framework: scheduler. Drives the global clock, accumulates a
-- per-player counter and fires events, and ticks the lifecycle of active
-- scares.

local check_interval = 0.5
local timer = 0

core.register_globalstep(function(dtime)
	scares.clock = scares.clock + dtime

	timer = timer + dtime
	if timer < check_interval then
		return
	end
	timer = 0

	for _, player in ipairs(core.get_connected_players()) do
		local pname = player:get_player_name()
		local pstate = scares.state[pname]
		if not pstate then
			scares.get_player_state(player)
			pstate = scares.state[pname]
		end

		local ctx = pstate.active
		if ctx then
			local alive = ctx.entity and ctx.entity:get_pos() ~= nil
			local elapsed = scares.clock - ctx.started
			if not alive then
				scares.finish_ctx(ctx, "ended")
			elseif ctx.event.duration and elapsed >= ctx.event.duration then
				scares.finish_ctx(ctx, "timeout")
			elseif ctx.event.on_update then
				ctx.event.on_update(ctx, dtime)
			end
		elseif scares.settings.enabled then
			-- Accumulate the counter. Once it reaches the target a scare
			-- is attempted; failed spawns keep the credit, so every player
			-- meets an event within interval_max at the latest.
			pstate.credit = pstate.credit + dtime
			if pstate.credit >= pstate.target then
				scares.trigger(player, nil)
			end
		end
	end
end)

core.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	local pstate = scares.state[pname]
	if pstate and pstate.active then
		scares.finish_ctx(pstate.active, "player_left")
	end
	scares.state[pname] = nil
end)
