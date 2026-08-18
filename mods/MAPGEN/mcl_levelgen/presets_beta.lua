------------------------------------------------------------------------
-- Beta 1.7.3 world generation preset.
------------------------------------------------------------------------

local floor = math.floor
local band = bit.band

------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------

mcl_levelgen.beta = {
	HEIGHT = 128,
	SEA_LEVEL = 63,
	MIN_Y = 0,

	-- Noise generator scales (coordinate multipliers before octave
	-- frequency scaling).
	LOW_NOISE_SCALE        = 1.0 / 684.412,
	HIGH_NOISE_SCALE       = 1.0 / 684.412,
	SELECTOR_NOISE_X_SCALE = 1.0 / (684.412 / 80.0),
	SELECTOR_NOISE_Y_SCALE = 1.0 / (684.412 / 160.0),
	SELECTOR_NOISE_Z_SCALE = 1.0 / (684.412 / 80.0),
	CONTINENTALNESS_SCALE  = 1.0 / 1.121,
	DEPTH_NOISE_SCALE      = 1.0 / 200.0,

	-- Octave counts for each generator.
	LOW_OCTAVES  = 16,
	HIGH_OCTAVES = 16,
	SELECTOR_OCTAVES = 8,
	CONTINENTALNESS_OCTAVES = 10,
	DEPTH_OCTAVES = 16,
	TREE_DENSITY_OCTAVES = 8,

	-- Biome noise scales.
	TEMPERATURE_OCTAVES = 4,
	TEMPERATURE_X_SCALE = 0.025,
	TEMPERATURE_Y_SCALE = 0.025,
	TEMPERATURE_Z_SCALE = 0.25,

	HUMIDITY_OCTAVES = 4,
	HUMIDITY_X_SCALE = 0.05,
	HUMIDITY_Y_SCALE = 0.05,
	HUMIDITY_Z_SCALE = 1.0 / 3.0,

	VARIATION_OCTAVES = 2,
	VARIATION_X_SCALE = 0.25,
	VARIATION_Y_SCALE = 0.25,

	-- Biome cache size.
	BIOME_CACHE_SIZE = 64,

	-- Tree density threshold (lower = more trees).
	TREE_DENSITY_THRESHOLD = 0.0,
}

------------------------------------------------------------------------
-- Biome definitions.
------------------------------------------------------------------------

-- Biome IDs (engine-side).
local B_TEMPERATE_FOREST = 1
local B_FOREST          = 2
local B_SHRUBLAND       = 3
local B_TAIGA           = 4
local B_DESERT          = 5
local B_PLAINS          = 6
local B_ICE_DESERT      = 7
local B_TUNDRA          = 8

mcl_levelgen.beta.BIOME_TEMPERATE_FOREST = B_TEMPERATE_FOREST
mcl_levelgen.beta.BIOME_FOREST           = B_FOREST
mcl_levelgen.beta.BIOME_SHRUBLAND        = B_SHRUBLAND
mcl_levelgen.beta.BIOME_TAIGA            = B_TAIGA
mcl_levelgen.beta.BIOME_DESERT           = B_DESERT
mcl_levelgen.beta.BIOME_PLAINS           = B_PLAINS
mcl_levelgen.beta.BIOME_ICE_DESERT       = B_ICE_DESERT
mcl_levelgen.beta.BIOME_TUNDRA           = B_TUNDRA

-- Biome metadata: top block, filler block, rainfall, snow.
mcl_levelgen.beta.biomes = {
	[B_TEMPERATE_FOREST] = {
		name = "Seasonal Forest",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = false,
	},
	[B_FOREST] = {
		name = "Forest",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = false,
	},
	[B_SHRUBLAND] = {
		name = "Shrubland",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = false,
	},
	[B_TAIGA] = {
		name = "Taiga",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = true,
	},
	[B_DESERT] = {
		name = "Desert",
		top = "mcl_core:sand",
		filler = "mcl_core:sand",
		rain = false,
		snow = false,
	},
	[B_PLAINS] = {
		name = "Plains",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = false,
	},
	[B_ICE_DESERT] = {
		name = "Ice Desert",
		top = "mcl_core:sand",
		filler = "mcl_core:sand",
		rain = false,
		snow = true,
	},
	[B_TUNDRA] = {
		name = "Tundra",
		top = "mcl_core:dirt_with_grass",
		filler = "mcl_core:dirt",
		rain = true,
		snow = true,
	},
}

------------------------------------------------------------------------
-- Biome selection table.
-- Beta 1.7.3 uses a simple temperature/humidity grid.
-- Temperature: 0..1, Humidity: 0..1
-- Grid divides each axis into regions.
------------------------------------------------------------------------

-- Lookup: temperature/humidity -> biome ID.
-- Grid boundaries from decompiled BiomeGenBase.
mcl_levelgen.beta.biome_grid = {
	-- temperature < 0.15
	{ temp_max = 0.15, hum_max = 0.85, biome = B_TAIGA },
	{ temp_max = 0.15, hum_max = 1.01, biome = B_TUNDRA },
	-- temperature 0.15..0.45
	{ temp_max = 0.45, hum_max = 0.50, biome = B_PLAINS },
	{ temp_max = 0.45, hum_max = 0.85, biome = B_TUNDRA },
	{ temp_max = 0.45, hum_max = 1.01, biome = B_ICE_DESERT },
	-- temperature 0.45..0.75
	{ temp_max = 0.75, hum_max = 0.35, biome = B_SHRUBLAND },
	{ temp_max = 0.75, hum_max = 0.60, biome = B_TEMPERATE_FOREST },
	{ temp_max = 0.75, hum_max = 0.85, biome = B_FOREST },
	{ temp_max = 0.75, hum_max = 1.01, biome = B_TAIGA },
	-- temperature 0.75..1.01
	{ temp_max = 1.01, hum_max = 0.35, biome = B_DESERT },
	{ temp_max = 1.01, hum_max = 0.60, biome = B_DESERT },
	{ temp_max = 1.01, hum_max = 0.85, biome = B_FOREST },
	{ temp_max = 1.01, hum_max = 1.01, biome = B_TEMPERATE_FOREST },
}

------------------------------------------------------------------------
-- Map BiomeGenBase IDs to engine biome names.
------------------------------------------------------------------------

mcl_levelgen.beta.biome_name_map = {
	[B_TEMPERATE_FOREST] = "Forest",
	[B_FOREST]          = "Forest",
	[B_SHRUBLAND]       = "Shrubland",
	[B_TAIGA]           = "Taiga",
	[B_DESERT]          = "Desert",
	[B_PLAINS]          = "Plains",
	[B_ICE_DESERT]      = "Ice Desert",
	[B_TUNDRA]          = "Tundra",
}

------------------------------------------------------------------------
-- Select a biome from temperature and humidity.
------------------------------------------------------------------------

function mcl_levelgen.beta.select_biome (temperature, humidity)
	for _, entry in ipairs (mcl_levelgen.beta.biome_grid) do
		if temperature < entry.temp_max and humidity < entry.hum_max then
			return entry.biome
		end
	end
	return B_PLAINS
end

------------------------------------------------------------------------
-- Stone type selection by depth.
------------------------------------------------------------------------

function mcl_levelgen.beta.stone_at_depth (y, rng)
	-- Granite: ~1% at y < 16
	if y < 16 and rng:next_within (100) == 0 then
		return "mcl_core:granite"
	end
	-- Diorite: ~1% at y < 16
	if y < 16 and rng:next_within (100) == 0 then
		return "mcl_core:diorite"
	end
	-- Andesite: ~1% at y < 16
	if y < 16 and rng:next_within (100) == 0 then
		return "mcl_core:andesite"
	end
	return "mcl_core:stone"
end

------------------------------------------------------------------------
-- Preset factory for Beta 1.7.3.
------------------------------------------------------------------------

function mcl_levelgen.make_beta_preset (seed)
	local beta = mcl_levelgen.beta

	local preset = {
		min_y = beta.MIN_Y,
		height = beta.HEIGHT,
		sea_level = beta.SEA_LEVEL,
		default_block = "mcl_core:stone",
		default_fluid = "mcl_core:water_source",
		seed = seed,
		is_beta = true,
	}

	return preset
end
