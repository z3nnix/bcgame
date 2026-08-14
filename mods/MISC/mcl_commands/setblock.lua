local S = core.get_translator(core.get_current_modname())

core.register_chatcommand("setblock", {
	params = S("<X>,<Y>,<Z> <NodeString>"),
	description = S("Set node at given position"),
	privs = {give=true, interact=true},
	func = function(name, param)
		local player = core.get_player_by_name(name)
		local relpos
		if player then
			relpos = player:get_pos()
		end
		local p = {}
		local nodestring
		p.x, p.y, p.z, nodestring = string.match(param, "^([%d.~-]+)[, ] *([%d.~-]+)[, ] *([%d.~-]+) +(.+)$")
		p = core.parse_coordinates(p.x, p.y, p.z, relpos)
		if p and p.x and p.y and p.z and nodestring then
			if not core.registered_nodes[nodestring] then
				return false, S("Invalid node")
			end
			core.set_node(p, {name=nodestring})
			return true, S("@1 spawned.", nodestring)
		end
		return false, S("Invalid parameters (see /help setblock)")
	end,
})
