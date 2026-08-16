-- wrapper for core.item_eat (this way we make sure other mods can't break this one)
function core.do_item_eat(hunger_points, replace_with_item, itemstack, user, pointed_thing)
	if not user or not user.is_player or not user:is_player() or user.is_fake_player then return itemstack end

	local rc = mcl_util.call_on_rightclick (itemstack, user, pointed_thing)
	if rc then
		return rc
	end

	local itemname = itemstack:get_name()
	local playername = user:get_player_name()
	local creative = core.is_creative_enabled(playername)
	local def = core.registered_items[itemname]

	if def and def._mcl_eat_effect then
		def._mcl_eat_effect(itemstack, user)
	end

	local old_itemstack = itemstack

	if hunger_points then
		mcl_damage.heal_player (user, hunger_points)
	end

	if not creative then
		itemstack:take_item()
		local nstack = ItemStack(replace_with_item)
		local inv = user:get_inventory()
		if itemstack:is_empty () then
			itemstack:add_item(replace_with_item)
		elseif inv:room_for_item("main",nstack) then
			inv:add_item("main", nstack)
		else
			core.add_item(user:get_pos(), nstack)
		end
	end

	for _, callback in pairs(core.registered_on_item_eats) do
		local result = callback(hunger_points, replace_with_item, itemstack, user, pointed_thing, old_itemstack)
		if result then
			return result
		end
	end

	return itemstack
end
