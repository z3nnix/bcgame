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
-- Seasonal node variants.
--
-- `override_item` changes are not pushed to already connected clients,
-- so texture swaps only show up after a re-login.  Instead we register
-- dedicated seasonal variant nodes (copies of the originals with the
-- season-specific textures) and swap placed nodes between the base node
-- and its variants with `swap_node`.  A periodic check keeps every
-- placed node consistent with the current season.
----------------------------------------------------------------

-- Map: base texture -> {summer = variant, autumn = variant}.
-- Spring and winter use the default textures (no entry needed).
local SEASON_TEXTURES = {
	-- Grass block
	["mcl_core_grass_block_top.png"] = {
		summer = "mcl_core_summer_grass_block_top.png",
		autumn = "mcl_core_autumn_grass_block_top.png",
	},
	["mcl_core_grass_block_side_overlay.png"] = {
		summer = "mcl_core_summer_grass_block_side_overlay.png",
		autumn = "mcl_core_autumn_grass_block_side_overlay.png",
	},
	-- Leaves
	["default_leaves.png"] = {
		summer = "summer_leaves.png",
		autumn = "autumn_leaves.png",
	},
	["default_acacia_leaves.png"] = {
		summer = "summer_acacia_leaves.png",
		autumn = "autumn_acacia_leaves.png",
	},
	["default_jungleleaves.png"] = {
		summer = "summer_jungleleaves.png",
		autumn = "autumn_jungleleaves.png",
	},
	["mcl_core_leaves_big_oak.png"] = {
		summer = "mcl_core_summer_leaves_big_oak.png",
		autumn = "mcl_core_autumn_leaves_big_oak.png",
	},
	["mcl_core_leaves_birch.png"] = {
		summer = "mcl_core_summer_leaves_birch.png",
		autumn = "mcl_core_autumn_leaves_birch.png",
	},
	["mcl_core_leaves_spruce.png"] = {
		summer = "mcl_core_summer_leaves_spruce.png",
		autumn = "mcl_core_autumn_leaves_spruce.png",
	},
}

-- Returns the seasonal variant of a tile (string or table) for the given
-- season, or nil when the tile has no seasonal texture.
local function swap_texture(tile, season)
	local base, mods
	if type(tile) == "string" then
		base, mods = tile:match("^([^%^]+)%^(.*)$")
		if not base then base, mods = tile, nil end
		local entry = SEASON_TEXTURES[base]
		if entry and entry[season] then
			return entry[season] .. (mods and "^" .. mods or "")
		end
	elseif type(tile) == "table" and tile.name then
		base, mods = tile.name:match("^([^%^]+)%^(.*)$")
		if not base then base, mods = tile.name, nil end
		local entry = SEASON_TEXTURES[base]
		if entry and entry[season] then
			local copy = {}
			for k, v in pairs(tile) do
				copy[k] = v
			end
			copy.name = entry[season] .. (mods and "^" .. mods or "")
			return copy
		end
	end
	return nil
end

local SEASONAL_SEASONS = {"summer", "autumn"}

-- [base_node_name] = {summer = variant_name, autumn = variant_name}
local base_to_variant = {}
-- [variant_name] = base_node_name
local variant_to_base = {}

local function copy_tiles(tiles, season)
	local out = {}
	for i, t in ipairs(tiles) do
		out[i] = swap_texture(t, season) or t
	end
	return out
end

local function has_seasonal_tiles(def)
	if not def.tiles then return false end
	for _, t in ipairs(def.tiles) do
		if swap_texture(t, "summer") then
			return true
		end
	end
	return false
end

-- Registers a summer and autumn variant for every node whose tiles use a
-- seasonal texture.  Runs at mod load time, so mcl_seasons must load after
-- the base nodes are registered (see mod.conf dependencies).
local function register_season_variants()
	for name, def in pairs(core.registered_nodes) do
		if has_seasonal_tiles(def) then
			base_to_variant[name] = {}
			for _, season in ipairs(SEASONAL_SEASONS) do
				local vname = "mcl_seasons:" .. name:gsub(":", "_") .. "_" .. season
				local vdef = {}
				for k, v in pairs(def) do
					vdef[k] = v
				end
				vdef.tiles = copy_tiles(def.tiles, season)
				if def.overlay_tiles then
					vdef.overlay_tiles = copy_tiles(def.overlay_tiles, season)
				end
				vdef.groups = {}
				if def.groups then
					for k, v in pairs(def.groups) do
						vdef.groups[k] = v
					end
				end
				vdef.groups.season_variant = 1
				vdef.groups.not_in_creative_inventory = 1
				vdef._mcl_seasons_base = name
				vdef._doc_items_create_entry = false
				vdef.description = (def.description or name) .. " (" .. season .. ")"
				if def._mcl_leaves then
					vdef._mcl_leaves = vname
				end
				core.register_node(vname, vdef)
				base_to_variant[name][season] = vname
				variant_to_base[vname] = name
			end
		end
	end
	-- Link each leaf variant to its seasonal orphan variant, so the leaf
	-- decay system never converts seasonal nodes back to the base family.
	for vname, base in pairs(variant_to_base) do
		local vdef = core.registered_nodes[vname]
		local basedef = core.registered_nodes[base]
		if vdef and basedef and basedef._mcl_orphan_leaves then
			local season = vname:match("_(summer|autumn)$")
			local vorphan = base_to_variant[basedef._mcl_orphan_leaves]
			if vorphan and season then
				vdef._mcl_orphan_leaves = vorphan[season]
			end
		end
	end
end

-- Returns the node name a position should have for the given season:
-- the seasonal variant for summer/autumn, the base node for spring/winter.
local function expected_node_name(name, season)
	local v = base_to_variant[name]
	if v then
		return v[season] or name
	end
	local base = variant_to_base[name]
	if base then
		local bv = base_to_variant[base]
		return (bv and bv[season]) or base
	end
	return name
end

----------------------------------------------------------------
-- Periodically re-check placed nodes and swap them to the correct
-- seasonal variant.  We walk a cube around every connected player.
-- Processed in small batches per globalstep to avoid lag spikes.
----------------------------------------------------------------

local scan_queue = {}   -- positions to check
local scanning = false
local SCAN_BATCH = 2048 -- nodes per step
local SCAN_RADIUS = 128
local CHECK_INTERVAL = tonumber(core.settings:get("mcl_seasons_check_interval")) or 60

local function build_scan_queue()
	scan_queue = {}
	for player in mcl_util.connected_players() do
		local p = player:get_pos()
		local minp = {x = p.x - SCAN_RADIUS, y = math.max(p.y - SCAN_RADIUS, -31000), z = p.z - SCAN_RADIUS}
		local maxp = {x = p.x + SCAN_RADIUS, y = math.min(p.y + SCAN_RADIUS, 31000), z = p.z + SCAN_RADIUS}
		-- Find all target nodes in range
		local targets = core.find_nodes_in_area(minp, maxp, {"group:leaves", "group:grass_block", "group:grass_block_snow", "group:snow_layer"})
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

local function process_scan_batch()
	if #scan_queue == 0 then
		scanning = false
		return
	end
	local count = 0
	while #scan_queue > 0 and count < SCAN_BATCH do
		local pos = table.remove(scan_queue)
		local node = core.get_node(pos)
		local def = core.registered_nodes[node.name]
		-- Snowed variants (grass/mycelium/podzol under snow) are only
		-- correct while a snow cover sits directly above them.  The
		-- snow removal below uses swap_node which skips after_destruct,
		-- so a leftover snowed block is corrected here as well.
		if def and def._mcl_snowless then
			local above = core.get_node(vector.offset(pos, 0, 1, 0))
			local covered = core.get_item_group(above.name, "snow_cover") > 0
			if not covered then
				local expected = expected_node_name(def._mcl_snowless, mcl_seasons.current)
				if expected ~= node.name then
					core.swap_node(pos, {name = expected, param2 = node.param2})
					count = count + 1
				end
			end
		-- In spring, the snow that fell during winter melts away.
		elseif mcl_seasons.current == "spring"
			and core.get_item_group(node.name, "snow_layer") > 0 then
			core.swap_node(pos, {name = "air"})
			-- swap_node skips after_destruct, so revert a snowed block
			-- below that is now exposed.
			local below = core.get_node(vector.offset(pos, 0, -1, 0))
			local below_def = core.registered_nodes[below.name]
			if below_def and below_def._mcl_snowless then
				local expected = expected_node_name(below_def._mcl_snowless, mcl_seasons.current)
				core.swap_node(vector.offset(pos, 0, -1, 0), {name = expected, param2 = below.param2})
			end
			count = count + 1
		else
			local expected = expected_node_name(node.name, mcl_seasons.current)
			if expected ~= node.name then
				-- swap_node preserves param1/param2 (light, biome colour,
				-- leaf distance) and immediately updates connected clients.
				core.swap_node(pos, {name = expected, param2 = node.param2})
				count = count + 1
			end
		end
	end
end

----------------------------------------------------------------
-- Callback: when season changes, re-check all placed nodes
----------------------------------------------------------------

mcl_seasons.register_on_change(function(season)
	build_scan_queue()
	scanning = true
end)

-- Autumn and winter have near-constant rain (snow in winter), so
-- precipitation starts immediately when the season arrives.
mcl_seasons.register_on_change(function(season)
	if mcl_weather and mcl_weather.change_weather
		and (season == "autumn" or season == "winter") then
		mcl_weather.change_weather("rain", nil, "mcl_seasons")
	end
end)

register_season_variants()

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
local tick_count = 0

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

	-- Periodic consistency check: swap nodes that don't match the season
	tick_count = tick_count + 1
	if tick_count >= CHECK_INTERVAL then
		tick_count = 0
		if not scanning then
			build_scan_queue()
			scanning = true
		end
	end
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
