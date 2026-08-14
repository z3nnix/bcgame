local deepslate_max = mcl_worlds.layer_to_y(16)
local deepslate_min = mcl_vars.mg_overworld_min

local mountains = {
	"ExtremeHills", "ExtremeHills_beach", "ExtremeHills_ocean", "ExtremeHills_deep_ocean", "ExtremeHills_underground",
	"ExtremeHills+", "ExtremeHills+_ocean", "ExtremeHills+_deep_ocean", "ExtremeHills+_underground",
	"ExtremeHillsM", "ExtremeHillsM_ocean", "ExtremeHillsM_deep_ocean", "ExtremeHillsM_underground",
}

local mesa = {
	"Mesa", "Mesa_sandlevel", "Mesa_ocean", "MesaBryce", "MesaBryce_sandlevel",
	"MesaBryce_ocean", "MesaPlateauF", "MesaPlateauF_sandlevel", "MesaPlateauF_ocean",
	"MesaPlateauFM", "MesaPlateauFM_sandlevel", "MesaPlateauFM_ocean",
}

local dripstone = {
	"DripstoneCave", "DripstoneCave_deep_underground",
}

--Clay
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:clay",
	wherein        = {"mcl_core:sand","mcl_core:stone","mcl_core:gravel"},
	clust_scarcity = 15*15*15,
	clust_num_ores = 33,
	clust_size     = 5,
	y_min          = -5,
	y_max          = 0,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 34843,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

-- Diorite, andesite and granite
local specialstones = { "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite" }
for s=1, #specialstones do
	local node = specialstones[s]
	core.register_ore({
		ore_type       = "blob",
		ore            = node,
		wherein        = {"mcl_core:stone"},
		clust_scarcity = 15*15*15,
		clust_num_ores = 33,
		clust_size     = 5,
		y_min          = mcl_vars.mg_overworld_min_old,
		y_max          = mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		}
	})
	core.register_ore({
		ore_type       = "blob",
		ore            = node,
		wherein        = {"mcl_core:stone"},
		clust_scarcity = 10*10*10,
		clust_num_ores = 58,
		clust_size     = 7,
		y_min          = mcl_vars.mg_overworld_min_old,
		y_max          = mcl_vars.mg_overworld_max,
		noise_params = {
			offset  = 0,
			scale   = 1,
			spread  = {x=250, y=250, z=250},
			seed    = 12345,
			octaves = 3,
			persist = 0.6,
			lacunarity = 2,
			flags = "defaults",
		}
	})
end

local stonelike = {"mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite"}

-- Dirt
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:dirt",
	wherein        = stonelike,
	clust_scarcity = 15*15*15,
	clust_num_ores = 33,
	clust_size     = 4,
	y_min          = mcl_vars.mg_overworld_min_old,
	y_max          = mcl_vars.mg_overworld_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

-- Gravel
core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_core:gravel",
	wherein        = stonelike,
	clust_scarcity = 14*14*14,
	clust_num_ores = 33,
	clust_size     = 5,
	y_min          = mcl_vars.mg_overworld_min_old,
	y_max          = mcl_worlds.layer_to_y(111),
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_deepslate:deepslate",
	wherein        = { "mcl_core:stone" },
	clust_scarcity = 200,
	clust_num_ores = 100,
	clust_size     = 10,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = { x = 250, y = 250, z = 250 },
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "blob",
	ore            = "mcl_deepslate:tuff",
	wherein        = { "mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite", "mcl_deepslate:deepslate" },
	clust_scarcity = 10*10*10,
	clust_num_ores = 58,
	clust_size     = 7,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	noise_params = {
		offset  = 0,
		scale   = 1,
		spread  = {x=250, y=250, z=250},
		seed    = 12345,
		octaves = 3,
		persist = 0.6,
		lacunarity = 2,
		flags = "defaults",
	}
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_deepslate:infested_deepslate",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 26 * 26 * 26,
	clust_num_ores = 3,
	clust_size     = 2,
	y_min          = deepslate_min,
	y_max          = deepslate_max,
	biomes         = mountains,
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:water_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(5),
	y_max          = deepslate_max,
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 2000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(1),
	y_max          = mcl_worlds.layer_to_y(10),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein        = "mcl_deepslate:deepslate",
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(11),
	y_max          = deepslate_max,
})

if core.settings:get_bool("mcl_generate_ores", true) then
	--
	-- Ancient debris
	--
	local ancient_debris_wherein = {"mcl_nether:netherrack","mcl_blackstone:blackstone","mcl_blackstone:basalt"}
	-- Common spawn
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 15000,
		-- in MC it's 0.004% chance (~= scarcity 25000) but reports and experiments show that ancient debris is unreasonably hard to find in survival with that value
		clust_num_ores = 3,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min + 8,
		y_max = mcl_vars.mg_nether_min + 22,
	})

	-- Rare spawn (below)
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 32000,
		clust_num_ores = 2,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min,
		y_max = mcl_vars.mg_nether_min + 8,
	})

	-- Rare spawn (above)
	core.register_ore({
		ore_type       = "scatter",
		ore            = "mcl_nether:ancient_debris",
		wherein         = ancient_debris_wherein,
		clust_scarcity = 32000,
		clust_num_ores = 2,
		clust_size     = 3,
		y_min = mcl_vars.mg_nether_min + 22,
		y_max = mcl_vars.mg_nether_min + 119,
	})

	local stonelike = { "mcl_core:stone", "mcl_core:diorite", "mcl_core:andesite", "mcl_core:granite" }

	local function register_ore_mg(ore, wherein, defs)
		core.register_ore({
			ore_type       = "scatter",
			ore            = ore,
			wherein        = wherein,
			clust_scarcity = defs[1],
			clust_num_ores = defs[2],
			clust_size     = defs[3],
			y_min          = defs[4],
			y_max          = defs[5],
			biomes		   = defs[6],
		})
	end

	-- Methodology for transforming MC wiki values:
	--
	-- MC tries per chunk are multiplied by 25 (default chunksize^2). For
	-- non uniform distribution tries are distributed to height layers
	-- usually 16 or 32 blocks high. This large height is on the coarse
	-- side, but unfortunately thinner layers would easily exceed the
	-- supported scarcity range for rare ores.
	--
	-- Distribution of tries is mostly chosen to give 'nice' scarcity
	-- values, i.e. number of tries evenly divide 80x80, to prevent
	-- unexpected ore node loss due to rounding in the engine with default
	-- chunksize 5. 8, 16, 25, 32, 40, 50, 64, 80, 100 are 'good' values for
	-- number of tries in a height range.
	--
	-- Luanti clust_scarcity = (volume / (MC tries * 25))
	--
	-- Volume usually is (80^2 * (y_max-y_min)), but chunk borders may need
	-- to be taken into account for rarer ores; the most relevant chunk
	-- borders for default chunksize 5 are at y = -48 and y = 32.
	--
	-- Tries per height range may be aggregated to prevent scarcity from
	-- coming close to the engine supported scarcity limit - beyond which no
	-- ore will be generated at all - or to get better values.
	--
	-- Split of tries between stone and deepslate:
	-- - all tries for range [-128, -65] go to deepslate
	-- - all tries for range [-48, +inf] go to stone
	-- - tries for range [-64, -49] are doubled for deepslate and stone (the
	--   assumption being that around half the nodes will hit the wrong
	--   stone type and get discarded by the engine; as always numbers may
	--   be jiggled a bit to get 'nice' scarcity values)
	--
	-- MC spawn size values are converted to clust_size/clust_num_ores with
	-- hopefully similar average number of ore nodes in a cluster (there
	-- seems to be little data on actual MC ore cluster size distribution,
	-- Luanti scatter ores have a binomial distribution). Values get tweaked
	-- to account for air exposure reduction using the following
	-- assumptions:
	-- - ~50% of clusters will be intersected by a cave
	-- - ~33% of nodes exposed to air
	-- -> (100 * <air exposure reduction factor> / 6)% nodes lost
	-- -> adapt tries to account for too large/small reduction, because of
	--    coarse value range for clust_num_ores (cluster size may need to
	--    be adjusted similarly to get better scarcity values)
	--
	-- Challenges:
	-- - partial tries per chunk are not (well) supported by Luanti ores
	--   (see https://github.com/luanti-org/luanti/issues/16065)
	-- - Luanti ores can't place different ore nodes depending on
	--   replaced node (making it necessary to separate stone and deepslate
	--   ores)
	-- - Luanti's calculation of number of ore nodes in a cluster and
	--   cluster shape seems very different from MC
	local ore_mapgen = {
		["deepslate"] = {
			["coal"] = {
				-- spawnsize 17, max 37 nodes
				-- -> num = 25, size = 4 (>99% 4-34 nodes)
				-- 20 tries per chunk, triangular, 96+-96, air exposure reduction 0.5
				-- -> 12 tries in deepslate (+ 488 stone tries), num -= 4 (16%)
				-- 12 tries   [  0,  15]
				-- replace by 25 tries of num = 12, size = 3
				{ 4096, 12, 3, -64, -49},
				-- 30 tries per chunk, uniform, [136, 320]
				-- -> 0 tries in deepslate
				-- 20 tries per chunk, uniform, [128, 256], mountains (Bedrock only)
				-- -> 0 tries in deepslate
			},
			["iron"] = {
				-- spawnsize 4, max 5 nodes
				-- -> num = 3, size = 2 (>94% 1-5 nodes)
				-- 4 tries per chunk, uniform, [-64, 72], no air exposure reduction
				-- -> 100 + ~12 tries
				-- -> 64 tries in deepslate (+50 stone tries)
				-- 64 tries  [ -64,  15]
				{ 8000, 3, 2, -128, -49 },
				-- spawnsize 10 (BE, JE has 9), max 16 nodes
				-- -> num = 7, size = 3 (>99% 2-13 nodes)
				-- 10 tries per chunk, triangular, 16+-40, no air exposure reduction
				-- -> 250 + 75 tries
				-- -> 121 tries in deepslate (+193 stone tries)
				-- 8 tries   [-24, -17]
				{ 6400, 7, 3, -88, -81 },
				-- 16 tries  [-16,  -9]
				{ 3200, 7, 3, -80, -73 },
				-- 25 tries  [ -8,  -1]
				{ 2048, 7, 3, -72, -65 },
				-- 32 tries  [  0,   7]
				{ 1600, 7, 3, -64, -57 },
				-- 40 tries  [  8,  15]
				-- increase cluster size a bit in the max density layer
				-- to compensate for slightly to few overall clusters
				{ 1280, 8, 3, -56, -49 },
				-- spawnsize 10 (BE, JE has 9), max 16 nodes
				-- -> num = 7, size = 3 (>99% 2-13 nodes)
				-- 90 tries per chunk, triangular, 232+-152, no air exposure reduction
				-- no tries in deepslate
			},
			["gold"] = {
				{ 4775, 5, 3, deepslate_min, deepslate_max },
				{ 6560, 7, 3, deepslate_min, deepslate_max },
			},
			["diamond"] = {
				-- spawnsize 4, max 5 nodes
				-- -> num = 3, size = 2 (>94% 1-5 nodes)
				-- 7 tries per chunk, triangular, -64+80, air exposure reduction 0.5
				-- -> 161 tries in deepslate (+14 stone tries), num -= 1 (33%) except lowest
				-- 50 tries   [ -64,  -49]
				{  2048, 3, 2, -128, -113 },
				-- 40 tries   [ -48,  -33]
				{  2560, 2, 2, -112,  -97 },
				-- 32 tries   [ -32,  -17]
				{  3200, 2, 2,  -96,  -81 },
				-- 25 tries   [ -16,   -1]
				{  4096, 2, 2,  -80,  -65 },
				-- aggregate tries for all spawn sizes in highest layer
				-- 25 tries   [   0,   15]
				{  4096, 2, 2,  -64,  -49 },
				-- spawnsize 8, max 10 nodes
				-- -> num = 5, size = 3 (>99% 1-10 nodes)
				-- 4 tries per chunk, triangular, -64+80, air exposure reduction 1.0
				-- 2 tries per chunk, uniform, [-64, -4], air exposure reduction 0.5
				-- -> 4 tries in stone (+146 tries in deepslate), num -= 1 (20%) except lowest
				-- 50 tries   [ -64,  -49]
				{  2048, 5, 3, -128, -113 },
				-- 40 tries   [ -48,  -33]
				{  2560, 4, 3, -112,  -97 },
				-- 32 tries   [ -32,  -17]
				{  3200, 4, 3,  -96,  -81 },
				-- 20 tries   [ -16,   -1]
				-- replace by 25 tries of num 3, size 2
				{  4096, 3, 2,  -80,  -65 },
				-- spawnsize 12, max 23 nodes, reduced air exposure
				-- -> num = 12, size = 3 (>99% 5-19 nodes)
				-- 1/9 tries per chunk, triangular, -64+80, air exposure reduction 0.7
				-- -> 3 tries in deepslate (0 stone tries, num -= 2 (16,7%)
				-- 1 tries [-128, -49]
				{ 512000, 10, 3, -128, -49 },
				-- 1 tries [-128, -81]
				{ 307200, 10, 3, -128, -81 },
				-- 1 tries [-128, -113]
				{ 102400, 10, 3, -128, -113 },
			},
			["redstone"] = {
				{ 500, 4, 3, deepslate_min, mcl_worlds.layer_to_y(13) },
				{ 800, 7, 4, deepslate_min, mcl_worlds.layer_to_y(13) },
				{ 1000, 4, 3, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 1600, 7, 4, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["lapis"] = {
				-- spawnsize 7, max 10 nodes
				-- -> num = 5, size = 3 (~99% 1-10 nodes)
				-- 4 tries per chunk, uniform, [-64, 64]
				-- -> 62.5 tries in deepslate (+ 50 tries in stone)
				-- 62.5 tries [ -64,  15]
				{ 8192, 5, 3,  -128, -49 },
				-- 2 tries per chunk, triangular, 0+-32
				-- air exposure reduction factor 1.0
				-- -> num -= 1 (-20%), size -= 1, -> upgrade to ~2.5 tries per chunk
				-- -> 58 tries in deepslate (+ 33 tries in stone)
				-- 8 tries    [-32, -17]
				{  6400, 4, 2, -96, -81 },
				-- 50 tries   [-16,  15]
				{  4096, 4, 2, -80, -49 },
			},
			["emerald"] = {
				-- spawnsize 3, max 4 nodes
				-- -> num = 2, size = 2 (~87% 1-4 nodes, ~10% 0 nodes)
				-- 100 tries per chunk, triangular, 232+-248, mountains
				-- -> ~50 tries in deepslate (+ 2475 tries in stone)
				-- 50 tries   [-16,  15]
				{ 4096, 2, 2,  -80, -49, mountains },
			},
			["copper"] = {
				-- spawnsize 20 (in deepslate, 10 in stone), max 52 nodes
				-- -> num = 27, size = 4 (>99% 8-46 nodes)
				-- 10 tries per chunk, triangular, 48+-64
				-- -> 20 tries in deepslate (+ 230 tries in stone)
				-- 8 tries    [-16,  -1]
				-- replace by 25 tries of num = 9, size = 3
				{ 4096,  9, 3, -80, -65},
				-- 12 tries   [  0,  15]
				-- replace by 25 tries of num = 13, size = 3
				{ 4096, 13, 3, -64, -49},
				-- 20 tries per chunk, triangular, 48+-64, dripstone caves
				-- -> 40 tries in deepslate (+ 460 tries in stone)
				-- 16 tries   [-16,  -1]
				-- replace by 25 tries of num = 18, size = 3
				{ 4096, 18, 3, -80, -65, dripstone},
				-- 25 tries   [  0,  15]
				{ 4096, 27, 4, -64, -49, dripstone},
			}
		},
		["stone"] = {
			["coal"] = {
				-- spawnsize 17, max 37 nodes
				-- -> num = 25, size = 4 (>99% 4-34 nodes)
				-- 20 tries per chunk, triangular, 96+-96, air exposure reduction 0.5
				-- -> 488 tries in stone (+ 12 deepslate tries), num -= 4 (16%)
				-- 12 tries   [  0,  15]
				-- replace by 25 tries of num = 12, size = 3
				{ 4096, 12, 3, -64, -49},
				-- 64 tries   [ 16,  47]
				{ 3200, 21, 4, -48, -17},
				-- 80 tries   [ 48,  79]
				{ 2560, 21, 4, -16,  15},
				-- 100 tries  [ 80, 111]
				{ 2048, 21, 4,  16,  47},
				-- 64 tries   [ 88, 103]
				{ 1600, 21, 4,  24,  39},
				-- 80 tries   [112, 143]
				{ 2560, 21, 4,  48,  79},
				-- 64 tries   [144, 175]
				{ 3200, 21, 4,  80, 111},
				-- 24 tries   [176, 191]
				-- replace by 50 tries of num = 10, size = 3
				{ 2048, 10, 3, 112, 127},
				-- 30 tries per chunk, uniform, [136, 320]
				-- -> 750 tries in stone
				{ 1571, 25, 4,  72, 256},
				-- 20 tries per chunk, uniform, [128, 256], mountains (Bedrock only)
				-- -> 500 tries in stone
				{ 1639, 25, 4,  64, 192, mountains},
			},
			["iron"] = {
				-- spawnsize 4, max 5 nodes
				-- -> num = 3, size = 2 (>94% 1-5 nodes)
				-- 4 tries per chunk, uniform, [-64, 72], no air exposure reduction
				-- -> 100 + ~12 tries
				-- -> 50 tries in stone (+64 deepslate tries)
				-- 50 tries   [  0, 71]
				{ 10240, 3, 2, -64,  7 },
				-- spawnsize 10 (BE, JE has 9), max 16 nodes
				-- -> num = 7, size = 3 (>99% 2-13 nodes)
				-- 10 tries per chunk, triangular, 16+-40, no air exposure reduction
				-- -> 250 + 75 tries
				-- -> 193 tries in stone (+121 deepslate tries)
				-- 32 tries  [  0,   7]
				{ 1600, 7, 3, -64, -57 },
				-- 40 tries  [  8,  23]
				-- increase cluster size a bit in the max density layer
				-- to compensate for slightly to few overall clusters
				{ 1280, 8, 3, -56, -41 },
				-- 32 tries  [ 24,  31]
				{ 1600, 7, 3, -40, -33 },
				-- 25 tries  [ 32,  39]
				{ 2048, 7, 3, -32, -25 },
				-- 16 tries  [ 40,  47]
				{ 3200, 7, 3, -24, -17 },
				-- 8 tries   [ 48,  55]
				{ 6400, 7, 3, -16,  -9 },
				-- spawnsize 10 (BE, JE has 9), max 16 nodes
				-- -> num = 7, size = 3 (>99% 2-13 nodes)
				-- 90 tries per chunk, triangular, 232+-152, no air exposure reduction
				-- -> 2250 tries in stone
				-- use 2500 tries with some smaller clusters
				-- 475 tries [ 80, 383]
				{ 4096, 6, 3,  16, 319 },
				-- 425 tries [ 96, 367]
				{ 4096, 6, 3,  32, 303 },
				-- 375 tries [112, 351]
				{ 4096, 6, 3,  48, 287 },
				-- 325 tries [128, 335]
				{ 4096, 6, 3,  64, 271 },
				-- 275 tries [144, 319]
				{ 4096, 7, 3,  80, 255 },
				-- 225 tries [160, 303]
				{ 4096, 7, 3,  96, 239 },
				-- 175 tries [176, 287]
				{ 4096, 7, 3, 112, 223 },
				-- 125 tries [192, 271]
				{ 4096, 7, 3, 128, 207 },
				--  75 tries [208, 255]
				{ 4096, 7, 3, 144, 191 },
				--  25 tries [224, 239]
				{ 4096, 7, 3, 160, 175 },
			},
			["gold"] = {
				{ 4775, 5, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(30) },
				{ 6560, 7, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(30) },
				{ 13000, 4, 2, mcl_worlds.layer_to_y(31), mcl_worlds.layer_to_y(33) },
				{ 3333, 5, 3, mcl_worlds.layer_to_y(32), mcl_worlds.layer_to_y(79), mesa }
			},
			["diamond"] = {
				-- spawnsize 4, max 5 nodes
				-- -> num = 3, size = 2 (>94% 1-5 nodes)
				-- 7 tries per chunk, triangular, -64+80, air exposure reduction 0.5
				-- -> 14 tries in stone (+161 deepslate tries)
				-- spawnsize 8, max 10 nodes
				-- -> num = 5, size = 3 (>99% 1-10 nodes)
				-- 4 tries per chunk, triangular, -64+80, air exposure reduction 1.0
				-- 2 tries per chunk, uniform, [-64, -4], air exposure reduction 0.5
				-- -> 4 tries in stone (+146 tries in deepslate)
				-- spawnsize 12, max 23 nodes, reduced air exposure
				-- -> num = 12, size = 3 (>99% 5-19 nodes)
				-- 1/9 tries per chunk, triangular, -64+80, air exposure reduction 0.7
				-- -> 0 tries in stone (+3 deepslate tries)
				-- aggregate all stone tries, num = 2, size = 2
				-- 25 tries  [  0,  15]
				{ 4096, 2, 2, -64, -49 },
			},
			["redstone"] = {
				{ 500, 4, 3, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(13) },
				{ 800, 7, 4, mcl_vars.mg_overworld_min, mcl_worlds.layer_to_y(13) },
				{ 1000, 4, 3, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
				{ 1600, 7, 4, mcl_worlds.layer_to_y(13), mcl_worlds.layer_to_y(15) },
			},
			["lapis"] = {
				-- spawnsize 7, max 10 nodes
				-- -> num = 5, size = 3 (~99% 1-10 nodes)
				-- 4 tries per chunk, uniform, [-64, 64]
				-- -> 50 tries in stone (+ 62.5 tries in deepslate)
				-- 50 tries  [  0, 63]
				{ 8192, 5, 3, -64, -1 },
				-- 2 tries per chunk, triangular, 0+-32
				-- air exposure reduction factor 1.0
				-- -> num -= 1 (-20%), size -= 1, -> upgrade to ~2.5 tries per chunk
				-- -> 33 tries in stone (+ 58 tries in deepslate)
				-- 25 tries   [  0,  15]
				{  4096, 4, 2, -64, -49 },
				-- 8 tries    [ 16,  31]
				{  6400, 4, 2, -48, -33 },
			},
			["copper"] = {
				-- spawnsize 10 (in stone, 20 in deepslate), max 16 nodes
				-- -> num = 8, size = 3 (>99% 1-16 nodes)
				-- 10 tries per chunk, triangular, 48+-64
				-- -> 230 tries in stone (+ 20 tries in deepslate)
				-- 13 tries  [  0,  15]
				-- replace by 25 tries of num = 4, size = 3
				{ 4096, 4, 3, -64, -49},
				-- 32 tries  [ 16,  31]
				{ 3200, 8, 3, -48, -33},
				-- 80 tries  [ 32,  63]
				{ 2560, 8, 3, -32,  -1},
				-- 40 tries  [ 40,  55]
				{ 2560, 8, 3, -24,  -9},
				-- 32 tries  [ 64,  79]
				{ 3200, 8, 3,   0,  15},
				-- 25 tries  [ 80,  95]
				-- replace by 50 tries of num = 4, size = 3
				{ 2048, 4, 3,  16,  31},
				-- 8 tries   [ 96, 111]
				-- replace by 25 tries of num = 2, size = 2
				{ 4096,  2, 2,  32,  47},
				-- 20 tries per chunk, triangular, 48+-64, dripstone caves
				-- -> 460 tries in stone (+ 40 tries in deepslate)
				-- 25 tries  [  0,  15]
				{ 4096, 8, 3, -64, -49, dripstone},
				-- 64 tries  [ 16,  31]
				{ 1600, 8, 3, -48, -33, dripstone},
				-- 160 tries [ 32,  63]
				{ 1280, 8, 3, -32,  -1, dripstone},
				-- 80 tries  [ 40,  55]
				{ 1280, 8, 3, -24,  -9, dripstone},
				-- 64 tries  [ 64,  79]
				{ 1600, 8, 3,   0,  15, dripstone},
				-- 25 tries  [ 80,  95]
				{ 4096, 8, 3,  16,  31, dripstone},
				-- 16 tries  [ 96, 111]
				-- replace by 25 tries of num = 5, size = 3
				{ 4096, 5, 3,  32,  47, dripstone},
			},
			["emerald"] = {
				-- spawnsize 3, max 4 nodes
				-- -> num = 2, size = 2 (~87% 1-4 nodes, ~10% 0 nodes)
				-- 100 tries per chunk, triangular, 232+-248, mountains
				-- -> ~2475 tries in stone (+ 50 tries in deepslate)
				-- increase to 2625 tries to offset 0 (and 5) node clusters
				-- (the distribution below is one block off chunksize 5
				-- luanti chunk borders, but all numbers are adequate for
				-- 16 layer ores, so it doesn't matter)
				-- 50 tries   [  0,  31]
				{ 4096, 2, 2,  -64, -33, mountains },
				-- 250 tries  [ 32, 111]
				{ 2048, 2, 2,  -32,  47, mountains },
				-- 500 tries  [112, 191]
				{ 1024, 2, 2,   48, 127, mountains },
				-- 1000 tries [192, 271]
				{ 512, 2, 2,   128, 207, mountains },
				-- 500 tries  [272, 351]
				{ 1024, 2, 2,  208, 287, mountains },
				-- 250 tries  [352, 431]
				{ 2048, 2, 2,  288, 367, mountains },
				-- 75 tries   [432, 479]
				{ 4096, 2, 2,  368, 415, mountains },
			},
		}
	}

	for stone, ore in pairs(ore_mapgen) do
		local modname = ""
		local wherein

		for name, defs in pairs(ore) do
			if stone == "deepslate" then
				modname = "mcl_deepslate"
				wherein = { "mcl_deepslate:deepslate", "mcl_deepslate:tuff" }
			elseif stone == "stone" then
				modname = "mcl_core"
				wherein = stonelike
				if name == "copper" then
					modname = "mcl_copper"
				end
			end
			for _, def in pairs(defs) do
				register_ore_mg(modname..":"..stone.."_with_"..name, wherein, def)
			end
		end
	end
end

if not mcl_vars.superflat then
-- Water and lava springs (single blocks of lava/water source)
-- Water appears at nearly every height, but not near the bottom
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:water_source",
	wherein         = {"mcl_core:stone", "mcl_core:andesite", "mcl_core:diorite", "mcl_core:granite", "mcl_core:dirt"},
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(5),
	y_max          = mcl_worlds.layer_to_y(128),
})

-- Lava springs are rather common at -31 and below
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 2000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(1),
	y_max          = mcl_worlds.layer_to_y(10),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 9000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(11),
	y_max          = mcl_worlds.layer_to_y(31),
})

-- Lava springs will become gradually rarer with increasing height
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 32000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(32),
	y_max          = mcl_worlds.layer_to_y(47),
})

core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 72000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(48),
	y_max          = mcl_worlds.layer_to_y(61),
})

-- Lava may even appear above surface, but this is very rare
core.register_ore({
	ore_type       = "scatter",
	ore            = "mcl_core:lava_source",
	wherein         = stonelike,
	clust_scarcity = 96000,
	clust_num_ores = 1,
	clust_size     = 1,
	y_min          = mcl_worlds.layer_to_y(62),
	y_max          = mcl_worlds.layer_to_y(127),
})
end
