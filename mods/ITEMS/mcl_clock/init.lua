local S = core.get_translator(core.get_current_modname())
mcl_clock = {}

local clock_frames = 64
local image_fmt = "mcl_clock_clock_%02d.png"

local clock_images = {}
-- the first and last element of clock_images are the same. This is to
-- accomodate for `core.get_timeofday` returning values in [0, 1], where
-- the value `0` and `1` indicate the same time.
for i = 0, clock_frames do
	local frame = (i + (clock_frames / 2) - 1) % clock_frames
	clock_images[i] = string.format(image_fmt, frame)
end

-- random clock spinning tick in seconds.
-- Increase if there are performance problems
local spin_timer_tick = 0.1
local spin_timer = 0
local spin_velocity = 1

local random_frame = math.random(1, clock_frames)
local current_frame = 0

-- This timer makes sure the clocks get updated from time to time regardless of time_speed,
-- just in case some clocks in the world go wrong
local force_clock_update_timer = 0

core.register_globalstep(function(dtime)
	spin_timer = spin_timer + dtime
	if spin_timer >= spin_timer_tick then
		random_frame = (random_frame + spin_velocity) % clock_frames
		spin_timer = 0
	end
	force_clock_update_timer = force_clock_update_timer + dtime
	local new_frame = math.round(clock_frames * core.get_timeofday())
	if current_frame == new_frame and force_clock_update_timer < 1 then
		return
	end
	force_clock_update_timer = 0
	current_frame = new_frame
end)

mcl_player.register_globalstep(function(player, dtime)
	local frame
	-- Clocks do not work in certain zones
	if not mcl_worlds.clock_works(player:get_pos()) then
		frame = random_frame
	else
		frame = current_frame
	end
	local inv = player:get_inventory()
	for s, stack in pairs(inv:get_list("main")) do
		if core.get_item_group(stack:get_name(), "clock") > 0 then
			if stack:get_name() ~= "mcl_clock:clock" then
				-- compat to update inventories - aliases do not do this.
				stack:set_name("mcl_clock:clock")
			end
			local m = stack:get_meta()
			m:set_string("wield_image", clock_images[frame])
			m:set_string("inventory_image", clock_images[frame])
			inv:set_stack("main", s, stack)
		end
	end
end)

core.register_craftitem("mcl_clock:clock", {
	description = S("Clock"),
	_tt_help = S("Displays the time of day in the Overworld"),
	_doc_items_longdesc = S("Clocks are tools which shows the current time of day in the Overworld."),
	_doc_items_usagehelp = S("The clock contains a rotating disc with a sun symbol (yellow disc) and moon symbol and a little “pointer” which shows the current time of day by estimating the real position of the sun and the moon in the sky. Noon is represented by the sun symbol and midnight is represented by the moon symbol."),
	inventory_image = clock_images[0],
	groups = { tool=1, clock = 1, disable_repair=1 },
	wield_image = "",
	_on_entity_step = function(self, dtime, _)
		self._clock_timer = (self._clock_timer or 0) - dtime
		if self._clock_timer > 0 then return end
		self._clock_timer = 5
		local frame
		if not mcl_worlds.clock_works(self.object:get_pos()) then
			frame = random_frame
		else
			frame = current_frame
		end
		local stack = ItemStack("mcl_clock:clock")
		local m = stack:get_meta()
		m:set_string("inventory_image", clock_images[frame])
		m:set_string("wield_image", clock_images[frame])
		self.object:set_properties({wield_item = stack:to_string()})
	end
})

-- Register aliases for old clock items
for a = 0, clock_frames - 1 do
	core.register_alias("mcl_clock:clock_"..tostring(a), "mcl_clock:clock")
end

core.register_craft({
	output = "mcl_clock:clock",
	recipe = {
		{"", "mcl_core:gold_ingot", ""},
		{"mcl_core:gold_ingot", "mcl_redstone:redstone", "mcl_core:gold_ingot"},
		{"", "mcl_core:gold_ingot", ""}
	}
})
