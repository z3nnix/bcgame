local S = core.get_translator(core.get_current_modname())
local storage = core.get_mod_storage()

mcl_seasons = {}
mcl_seasons.valid_seasons = {winter = true, spring = true, summer = true, autumn = true}
mcl_seasons.current = "spring"
mcl_seasons.on_change_callbacks = {}

-- One game day = 86400 / time_speed ticks.  With time_speed=72 that is 1200
-- ticks (20 real minutes).  14 game days = 16800 ticks.
local SEASON_LENGTH = 14 * (86400 / (tonumber(core.settings:get("time_speed")) or 72))
mcl_seasons.next_change = nil

----------------------------------------------------------------
-- Core API
----------------------------------------------------------------

function mcl_seasons.register_on_change(callback)
	table.insert(mcl_seasons.on_change_callbacks, callback)
end

function mcl_seasons.set_season(season)
	if not mcl_seasons.valid_seasons[season] then
		return false
	end
	if mcl_seasons.current == season then
		return true
	end
	local old = mcl_seasons.current
	mcl_seasons.current = season
	storage:set_string("season", season)
	-- Schedule next automatic change
	local gt = core.get_gametime()
	if gt then
		mcl_seasons.next_change = gt + SEASON_LENGTH
		storage:set_int("next_change", mcl_seasons.next_change)
	end
	core.log("info", "[mcl_seasons] Season changed: " .. old .. " -> " .. season)
	-- Fire callbacks
	for _, cb in ipairs(mcl_seasons.on_change_callbacks) do
		cb(season, old)
	end
	-- Force sky re-evaluation
	if mcl_weather.skycolor then
		mcl_weather.skycolor.force_update = true
	end
	return true
end

function mcl_seasons.get_season()
	return mcl_seasons.current
end

----------------------------------------------------------------
-- Season colours for grass blocks and leaves
----------------------------------------------------------------

local SEASON_COLORS = {
	winter  = nil,   -- no override (snow covers everything)
	spring  = nil,   -- default palette colours
	summer  = "#C4C970",
	autumn  = "#D4923A",
}

-- Override item definitions for grass blocks and leaves when season
-- changes.  This affects NEWLY placed blocks and (depending on engine
-- rendering) may also update already-placed blocks because the colour
-- is read from the registered definition at render time.

local grass_nodes = {
	"mcl_core:dirt_with_grass",
}

-- Collect all leaves node names once on mod load.
local leaves_nodes = {}

local function collect_leaves()
	for name, def in pairs(core.registered_nodes) do
		if core.get_item_group(name, "leaves") ~= 0 then
			table.insert(leaves_nodes, name)
		end
	end
end

local function apply_season_color(season)
	local col = SEASON_COLORS[season]

	-- Grass blocks
	for _, name in ipairs(grass_nodes) do
		if col then
			core.override_item(name, {color = col})
		else
			core.override_item(name, {color = "#8EB971"})
		end
	end

	-- Leaves
	for _, name in ipairs(leaves_nodes) do
		if col then
			core.override_item(name, {color = col})
		else
			core.override_item(name, {color = "#FFFFFF"})
		end
	end
end

----------------------------------------------------------------
-- Scan placed blocks and update their colour.
-- We walk a cube around every connected player, 128 blocks radius.
-- Processed in small batches per globalstep to avoid lag spikes.
----------------------------------------------------------------

local scan_queue = {}   -- positions to check
local scanning = false
local SCAN_BATCH = 2048 -- nodes per step
local SCAN_RADIUS = 128

local SEASON_COLOR_MAP = {
	summer = "#C4C970",
	autumn = "#D4923A",
}
local GRASS_DEFAULT = "#8EB971"
local LEAVES_DEFAULT = "#FFFFFF"

local function is_season_target(nodename)
	return core.get_item_group(nodename, "leaves") ~= 0
		or core.get_item_group(nodename, "grass_block") ~= 0
end

local function build_scan_queue()
	scan_queue = {}
	for player in mcl_util.connected_players() do
		local p = player:get_pos()
		local minp = {x = p.x - SCAN_RADIUS, y = math.max(p.y - SCAN_RADIUS, -31000), z = p.z - SCAN_RADIUS}
		local maxp = {x = p.x + SCAN_RADIUS, y = math.min(p.y + SCAN_RADIUS, 31000), z = p.z + SCAN_RADIUS}
		-- Find all target nodes in range
		local targets = core.find_nodes_in_area(minp, maxp, {"group:leaves", "group:grass_block"})
		for _, pos in ipairs(targets) do
			table.insert(scan_queue, pos)
		end
	end
	-- Shuffle so we don't always process the same region first
	for i = #scan_queue, 2, -1 do
		local j = math.random(i)
		scan_queue[i], scan_queue[j] = scan_queue[j], scan_queue[i]
	end
end

local season_color_target = nil
local season_color_default = nil

local function process_scan_batch()
	if #scan_queue == 0 then
		scanning = false
		return
	end
	local count = 0
	while #scan_queue > 0 and count < SCAN_BATCH do
		local pos = table.remove(scan_queue)
		local node = core.get_node(pos)
		if is_season_target(node.name) then
			-- Read current colour from node definition
			local ndef = core.registered_nodes[node.name]
			if ndef then
				local current_color = ndef.color
				if season_color_target and current_color ~= season_color_target then
					core.set_node(pos, {name = node.name, param1 = node.param1, param2 = node.param2})
					count = count + 1
				elseif not season_color_target and current_color ~= season_color_default then
					core.set_node(pos, {name = node.name, param1 = node.param1, param2 = node.param2})
					count = count + 1
				end
			end
		end
	end
end

----------------------------------------------------------------
-- Callback: when season changes, override items + trigger scan
----------------------------------------------------------------

mcl_seasons.register_on_change(function(season)
	-- Update item definitions
	apply_season_color(season)

	-- Prepare scan parameters
	season_color_target = SEASON_COLORS[season]
	if season == "winter" or season == "spring" then
		season_color_default = nil
	else
		season_color_default = SEASON_COLORS[season]
	end

	-- Rebuild scan queue and start scanning
	build_scan_queue()
	scanning = true
end)

----------------------------------------------------------------
-- Sky / fog colour per season
----------------------------------------------------------------

local SEASON_SKY = {
	spring = nil,  -- use biome defaults
	summer = {
		day_sky     = "#7BA4FF",
		day_horizon = "#D0E0FF",
		dawn_sky    = "#FFD4A0",
		dawn_horizon= "#FFE0B0",
		night_sky   = "#000000",
		night_horizon = "#4A6790",
		fog_sun_tint = "#FFE880",
	},
	autumn = {
		day_sky     = "#8BA4C0",
		day_horizon = "#C8B8A0",
		dawn_sky    = "#C08040",
		dawn_horizon= "#D8A060",
		night_sky   = "#000000",
		night_horizon = "#3A5060",
		fog_sun_tint = "#D08030",
	},
	winter = {
		day_sky     = "#A0B0C0",
		day_horizon = "#C0C8D0",
		dawn_sky    = "#9098A8",
		dawn_horizon= "#B0B8C0",
		night_sky   = "#000000",
		night_horizon = "#2A3A50",
		fog_sun_tint = "#E0E0E0",
	},
}

-- Intercept skycolor update to apply season tinting
local original_set_sky_box_clear = mcl_weather.set_sky_box_clear
if original_set_sky_box_clear then
	mcl_weather.set_sky_box_clear = function(player, sky, fog)
		local season = mcl_seasons.current
		local ss = SEASON_SKY[season]
		if ss then
			original_set_sky_box_clear(player,
				ss.day_sky or sky,
				ss.day_horizon or fog)
			-- Apply dawn/night overrides via set_sky
			if mcl_serverplayer and not mcl_serverplayer.is_csm_at_least(player, 2) then
				player:set_sky({
					type = "regular",
					sky_color = {
						day_sky      = ss.day_sky or sky or "#7BA4FF",
						day_horizon  = ss.day_horizon or fog or "#C0D8FF",
						dawn_sky      = ss.dawn_sky or ss.day_sky or "#7BA4FF",
						dawn_horizon  = ss.dawn_horizon or ss.day_horizon or "#C0D8FF",
						night_sky     = ss.night_sky or "#000000",
						night_horizon = ss.night_horizon or "#4A6790",
						indoors       = ss.day_horizon or "#C0D8FF",
						fog_sun_tint  = ss.fog_sun_tint or "#ff5f33",
						fog_moon_tint = nil,
						fog_tint_type = "custom",
					},
					clouds = mcl_player.get_player_setting(player, "mcl_weather:enable_clouds", true),
				})
			end
		else
			original_set_sky_box_clear(player, sky, fog)
		end
	end
end

----------------------------------------------------------------
-- Auto season change (every 14 game days)
----------------------------------------------------------------

local first_step = true

core.register_globalstep(function(dtime)
	local gt = core.get_gametime()
	if not gt then return end

	-- Initialise next_change on first available tick
	if first_step then
		first_step = false
		if not mcl_seasons.next_change then
			mcl_seasons.next_change = gt + SEASON_LENGTH
		end
	end

	-- Process colour-scan queue
	if scanning then
		process_scan_batch()
	end

	-- Auto season change
	if mcl_seasons.next_change and gt >= mcl_seasons.next_change then
		local order = {"spring", "summer", "autumn", "winter"}
		local idx = 1
		for i, s in ipairs(order) do
			if s == mcl_seasons.current then
				idx = i
				break
			end
		end
		local next_season = order[(idx % 4) + 1]
		mcl_seasons.set_season(next_season)
	end
end)

----------------------------------------------------------------
-- Load saved state
----------------------------------------------------------------

core.register_on_shutdown(function()
	storage:set_string("season", mcl_seasons.current)
	if mcl_seasons.next_change then
		storage:set_int("next_change", mcl_seasons.next_change)
	end
end)

local function load_season()
	local saved = storage:get_string("season")
	if saved and mcl_seasons.valid_seasons[saved] then
		mcl_seasons.current = saved
	end
	local nc = storage:get_int("next_change")
	if nc and nc > 0 then
		mcl_seasons.next_change = nc
	else
		-- core.get_gametime() may be nil during early init;
		-- defer the assignment until the first globalstep tick.
		mcl_seasons.next_change = nil
	end
	-- Apply initial season visual overrides
	core.register_on_mods_loaded(function()
		collect_leaves()
		apply_season_color(mcl_seasons.current)
	end)
end

load_season()

----------------------------------------------------------------
-- /season command
----------------------------------------------------------------

core.register_chatcommand("season", {
	params = "(winter | spring | summer | autumn)",
	description = S("Changes the current season."),
	privs = {weather_manager = true},
	func = function(name, param)
		param = param:lower()
		if not mcl_seasons.valid_seasons[param] then
			return false, S("Error: Invalid season. Use: winter, spring, summer, or autumn.")
		end
		mcl_seasons.set_season(param)
		core.log("action", name .. " changed season to " .. param)
		return true, S("Season changed to @1.", param)
	end,
})
