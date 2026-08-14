local eat_block = {}
function mcl_hunger.prevent_eating(player)
	eat_block[player:get_player_name()] = true
end

core.register_globalstep(function()
	for _, player in pairs(core.get_connected_players()) do
		eat_block[player:get_player_name()] = nil
	end
end)

local function use(itemstack, player, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	if rc then
		return rc
	end

	local itemstack = player:get_wielded_item ()
	local itemname = itemstack:get_name ()
	local pointed_thing = mcl_util.get_pointed_thing (player, true)

	if mcl_hunger.is_player_full(player) and not mcl_hunger.can_eat_when_full(player, itemstack) then
		return
	end

	local def = core.registered_items[itemname]
	local hunger_points = core.get_item_group(itemname, "eatable")

	itemstack = core.do_item_eat(hunger_points, def._mcl_eat_replace_with, itemstack, player, pointed_thing)
	if core.get_item_group(itemname, "food") == 3 then
		mcl_hunger.play_drinking_sound(player)
	else
		mcl_hunger.play_eating_sound(player)
	end

	if itemstack then
		player:set_wielded_item(itemstack)
	end
end

core.register_on_mods_loaded(function()
	for name, def in pairs(core.registered_items) do
		if core.get_item_group(name, "food") ~= 0 then
			local old_on_place = def.on_place
			core.override_item(name, {
				on_place = function(itemstack, player, pointed_thing)
					local new_itemstack = old_on_place(itemstack, player, pointed_thing) or itemstack
					if not eat_block[player:get_player_name()] and not mcl_util.place_was_held(player) then
						return use(new_itemstack, player, pointed_thing)
					end
					return new_itemstack
				end,
				on_secondary_use = use,
			})
		end
	end
end)
