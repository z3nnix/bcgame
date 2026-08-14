local S = core.get_translator(core.get_current_modname())

mcl_compass = {}

-- Number of dynamic compass images (and items registered.)
local compass_frames = 32

-- random compass spinning tick in seconds.
-- Increase if there are performance problems.
local spin_timer_tick = 0.1
local spin_timer = 0
local spin_velocity = 1

-- Initialize random compass frame for spinning compass.  It is updated in
-- the compass globalstep function.
local random_frame = math.random(0, compass_frames-1)

core.register_globalstep(function(dtime)
	spin_timer = spin_timer + dtime
	if spin_timer >= spin_timer_tick then
		random_frame = (random_frame + spin_velocity) % compass_frames
		spin_timer = 0
	end
end)

--set recovery meta
core.register_on_dieplayer(function(player)
	local meta = player:get_meta();
	meta:set_string("mcl_compass:recovery_pos",core.pos_to_string(player:get_pos()))
end)

local lodestones = {}

local function add_lodestone(pos)
	lodestones[core.hash_node_position(pos)] = true
end

local function remove_lodestone(pos)
	lodestones[core.hash_node_position(pos)] = nil
end

local function check_lodestone(pos)
	if lodestones[core.hash_node_position(pos)] then
		return true
	end
	local node = core.get_node(pos)
	if node.name == "ignore" then
		core.get_voxel_manip():read_from_map(pos, pos)
		node = core.get_node(pos)
	end
	if node.name == "mcl_compass:lodestone" then
		add_lodestone(pos)
		return true
	else
		return false
	end
end

--- Get compass needle angle.
-- Returns the angle that the compass needle should point at expressed in
-- 360 degrees divided by the number of possible compass image frames..
--
-- pos: position of the compass;
-- target: position that the needle points towards;
-- dir: rotational direction of the compass.
--
local function get_compass_angle(pos, target, dir)
	local angle_north = math.deg(math.atan2(target.x - pos.x, target.z - pos.z))
	if angle_north < 0 then angle_north = angle_north + 360 end
	local angle_dir = -math.deg(dir)
	local angle_relative = (angle_north - angle_dir + 180) % 360
	return math.floor((angle_relative/11.25) + 0.5)
end

local function update_compass_img(stack, frame)
	local def = stack:get_definition()
	local img = string.format(def._mcl_compass_img_fmt, frame)
	local m = stack:get_meta()
	m:set_string("inventory_image", img)
	m:set_string("wield_image", img)
	return stack
end

local function update_compass(stack, player)
	local frame = random_frame
	local pos = player:get_pos()
	-- Compasses only work in the overworld
	if mcl_worlds.compass_works(pos) then
		local spawn_pos = core.setting_get_pos("static_spawnpoint")
			or vector.new(0, 0, 0)
		local dir = player:get_look_horizontal()
		frame = get_compass_angle(pos, spawn_pos, dir) % compass_frames
	end
	return update_compass_img(stack, frame)
end

local function update_lodestone_compass(stack, player)
	local frame = random_frame
	local lpos_str = stack:get_meta():get_string("pointsto")
	local lpos = core.string_to_pos(lpos_str)
	if not lpos then
		stack:get_meta():set_string("pointsto", "")
	else
		local _, l_dim = mcl_worlds.y_to_layer(lpos.y)
		local pos = player:get_pos()
		local _, p_dim = mcl_worlds.y_to_layer(pos.y)
		-- compass and lodestone must be in the same dimension
		if l_dim == p_dim then
			--check if lodestone still exists
			if check_lodestone(lpos) then
				local dir = player:get_look_horizontal()
				frame = get_compass_angle(pos, lpos, dir) % compass_frames
			else
				stack:get_meta():set_string("pointsto", "")
			end
		end
	end
	return update_compass_img(stack, frame)
end

local function update_recovery_compass(stack, player)
	local frame = random_frame
	local rpos_str =  player:get_meta():get_string("mcl_compass:recovery_pos")
	local rpos = core.string_to_pos(rpos_str)
	if rpos then
		local _, r_dim = mcl_worlds.y_to_layer(rpos.y)
		local pos = player:get_pos()
		local _, p_dim = mcl_worlds.y_to_layer(pos.y)
		if r_dim == p_dim then
			local dir = player:get_look_horizontal()
			frame = get_compass_angle(pos, rpos, dir) % compass_frames
		end
	end
	return update_compass_img(stack, frame)
end

mcl_player.register_globalstep(function(player, dtime)
	local inv = player:get_inventory()
	for j, stack in pairs(inv:get_list("main")) do
		local compass_group = core.get_item_group(stack:get_name(), "compass")
		if compass_group > 0 then
			local def = stack:get_definition()
			if def._mcl_compass_update then
				inv:set_stack("main", j, def._mcl_compass_update(stack, player))
			end
		end
	end
end)

function mcl_compass.register_compass(name, def)
	core.register_craftitem(":mcl_compass:"..(def.name or name), table.merge({}, def.overrides or {}, {
		groups = table.merge({tool = 1, disable_repair = 1}, def.overrides.groups)
	}))
	if def.name_fmt then
		for i = 0, compass_frames - 1 do
			core.register_alias(string.format(def.name_fmt, i), "mcl_compass:"..(def.name or name))
		end
	end
end

--
-- Node and craftitem definitions
--
mcl_compass.register_compass("compass", {
	name = "compass",
	name_fmt = "mcl_compass:%d",
	overrides = {
		description = S("Compass"),
		_tt_help = S("Points to the world origin"),
		_doc_items_longdesc = S("Compasses are tools which point to the world origin (X=0, Z=0) or the spawn point in the Overworld."),
		_doc_items_usagehelp = S("A Compass always points to the world spawn point when the player is in the overworld.  In other dimensions, it spins randomly."),
		inventory_image = "mcl_compass_compass_01.png",
		wield_image = "mcl_compass_compass_01.png",
		groups = { compass = 1 },
		_mcl_compass_update = update_compass,
		_mcl_compass_img_fmt = "mcl_compass_compass_%02d.png",
	}
})

core.register_craft({
	output = "mcl_compass:compass",
	recipe = {
		{"", "mcl_core:iron_ingot", ""},
		{"mcl_core:iron_ingot", "mcl_redstone:redstone", "mcl_core:iron_ingot"},
		{"", "mcl_core:iron_ingot", ""}
	}
})

mcl_compass.register_compass("lodestone_compass", {
	name = "compass_lodestone",
	name_fmt = "mcl_compass:%d_lodestone",
	overrides = {
		description = S("Lodestone Compass"),
		_tt_help = S("Points to a lodestone"),
		_doc_items_longdesc = S("Lodestone compasses resemble regular compasses, but they point to a specific lodestone."),
		_doc_items_usagehelp = S("A Lodestone compass can be made from an ordinary compass by using it on a lodestone.  After becoming a lodestone compass, it always points to its linked lodestone, provided that they are in the same dimension.  If not in the same dimension, the lodestone compass spins randomly, similarly to a regular compass when outside the overworld.  A lodestone compass can be relinked with another lodestone."),
		inventory_image = "mcl_compass_compass_01.png^[colorize:purple:50",
		wield_image = "mcl_compass_compass_01.png^[colorize:purple:50",
		groups = { compass = 2, not_in_creative_inventory = 1 },
		_mcl_compass_update = update_lodestone_compass,
		_mcl_compass_img_fmt = "mcl_compass_compass_%02d.png^[colorize:purple:50",
	}
})

mcl_compass.register_compass("recovery_compass", {
	name = "compass_recovery",
	name_fmt = "mcl_compass:%d_recovery",
	overrides = {
		description = S("Recovery Compass"),
		_tt_help = S("Points to your last death location"),
		_doc_items_longdesc = S("Recovery Compasses are compasses that point to your last death location"),
		_doc_items_usagehelp = S("Recovery Compasses always point to the location of your last death, in case you haven't died yet, it will just randomly spin around"),
		inventory_image = "mcl_compass_recovery_compass_01.png",
		wield_image = "mcl_compass_recovery_compass_01.png",
		groups = { compass = 3, rarity = 1 },
		_mcl_compass_update = update_recovery_compass,
		_mcl_compass_img_fmt = "mcl_compass_recovery_compass_%02d.png",
	}
})

core.register_craft({
	output = "mcl_compass:" .. random_frame .. "_recovery",
	recipe = {
		{"mcl_sculk:echo_shard","mcl_sculk:echo_shard", "mcl_sculk:echo_shard"},
		{"mcl_sculk:echo_shard", "mcl_compass:compass", "mcl_sculk:echo_shard"},
		{"mcl_sculk:echo_shard", "mcl_sculk:echo_shard", "mcl_sculk:echo_shard"}
	}
})

core.register_node("mcl_compass:lodestone",{
	description=S("Lodestone"),
	tiles = {
		"lodestone_top.png",
		"lodestone_bottom.png",
		"lodestone_side1.png",
		"lodestone_side2.png",
		"lodestone_side3.png",
		"lodestone_side4.png"
	},
	groups = {pickaxey=1, material_stone=1, deco_block=1, unmovable_by_piston = 1},
	_mcl_hardness = 3.5,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_rightclick = function(pos, _, clicker, itemstack)
		local compass  = core.get_item_group(itemstack:get_name(), "compass")
		if compass > 0 and compass < 3 then
			if compass == 1 then
				itemstack:set_name("mcl_compass:compass_lodestone")
				awards.unlock(clicker:get_player_name(), "mcl:countryLode")
			end
			itemstack:get_meta():set_string("pointsto", core.pos_to_string(pos))
		end
		return itemstack
	end,
	on_construct = add_lodestone,
	on_destruct = remove_lodestone,
})

core.register_craft({
	output = "mcl_compass:lodestone",
	recipe = {
		{"mcl_core:stonebrickcarved","mcl_core:stonebrickcarved","mcl_core:stonebrickcarved"},
		{"mcl_core:stonebrickcarved", "mcl_core:iron_ingot", "mcl_core:stonebrickcarved"},
		{"mcl_core:stonebrickcarved", "mcl_core:stonebrickcarved", "mcl_core:stonebrickcarved"}
	}
})

-- Backwards compatibility definitions

mcl_compass.stereotype = "mcl_compass:compass"

function mcl_compass.get_compass_itemname()
	mcl_util.log_deprecated_call("error")
	return mcl_compass.stereotype
end

function mcl_compass.get_compass_angle()
	mcl_util.log_deprecated_call("error")
	return 0
end
