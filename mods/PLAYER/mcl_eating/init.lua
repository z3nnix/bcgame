local modpath = core.get_modpath (core.get_current_modname ())

mcl_eating = {}

-- The hunger mechanic is disabled entirely: eating food heals health.
mcl_eating.active = false

function mcl_eating.is_player_full (player)
	return false
end

function mcl_eating.can_eat_when_full (player, itemstack)
	return true
end

function mcl_eating.play_drinking_sound (object)
	core.sound_play ("mcl_potions_drinking", {
		gain = 0.75,
		max_hear_distance = 6,
		object = object,
	}, true)
end

function mcl_eating.play_eating_sound (object)
	core.sound_play ("mcl_eating_eat", {
		gain = 0.4,
		max_hear_distance = 6,
		object = object,
	}, true)
end

dofile (modpath .. "/eat.lua")

if core.settings:get_bool ("mcl_eating_instant_eat", false) then
	dofile (modpath .. "/instanteat.lua")
else
	dofile (modpath .. "/holdeat.lua")
end
