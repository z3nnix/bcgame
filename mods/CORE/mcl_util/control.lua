local old_player_control = {}

core.register_globalstep(function()
	local player_control = {}
	for _, player in pairs(core.get_connected_players()) do
		player_control[player:get_player_name()] = player:get_player_control()
	end
	old_player_control = player_control
end)

-- Check if place key was held. Used to avoid on_place actions being performed
-- repeatedly when key is held.
function mcl_util.place_was_held(player)
	return (old_player_control[player:get_player_name()] or {}).place
end
