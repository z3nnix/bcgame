-- backwards compatibility for callers of the old and deprecated API

function mcl_hunger.register_food(name, hunger_change, replace_with_item, poisontime, poison, exhaust, poisonchance, sound)
	mcl_util.log_deprecated_call("error")
end

function mcl_hunger.eat(hunger_points, replace_with_item, itemstack, user, _)
	mcl_util.log_deprecated_call("error")
end

function mcl_hunger.item_eat(hunger_points, replace_with_item, poisontime, poison, exhaust, poisonchance)
	mcl_util.log_deprecated_call("error")
	return function(itemstack, user)
		return itemstack
	end
end
