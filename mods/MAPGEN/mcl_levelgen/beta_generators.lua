------------------------------------------------------------------------
-- Beta 1.7.3 octave Perlin noise generators.
--
-- Creates octave Perlin noise in the Beta 1.7.3 style:
--   result = sum(i=0..N) { perlin[i](x*freq, y*freq, z*freq) * amp }
-- where freq doubles and amp halves each octave.
------------------------------------------------------------------------

local make_octave = mcl_levelgen.make_octave

------------------------------------------------------------------------
-- Beta octave Perlin: create N single-octave Perlin samplers from a
-- single Random and return a callable that sums them.
------------------------------------------------------------------------

function mcl_levelgen.beta.make_octaved_perlin (rng, num_octaves)
	local octaves = {}
	for i = 1, num_octaves do
		octaves[i] = make_octave (rng)
	end

	return function (x, y, z)
		local result = 0.0
		local amplitude = 1.0
		local frequency = 1.0
		for i = 1, num_octaves do
			result = result
				+ octaves[i] (x * frequency,
					       y * frequency,
					       z * frequency)
				* amplitude
			frequency = frequency * 2.0
			amplitude = amplitude * 0.5
		end
		return result
	end
end

------------------------------------------------------------------------
-- Create all Beta 1.7.3 terrain noise generators from a seed.
------------------------------------------------------------------------

function mcl_levelgen.beta.make_generators (seed)
	local beta = mcl_levelgen.beta
	local ull = mcl_levelgen.ull
	local extull = mcl_levelgen.extull

	local rng_seed = ull (seed[2], seed[1])
	local rng = mcl_levelgen.jvm_random (rng_seed)

	local gen = {}

	-- Low noise (16 octaves, base terrain shape A).
	gen.low_noise = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.LOW_OCTAVES)

	-- High noise (16 octaves, base terrain shape B).
	gen.high_noise = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.HIGH_OCTAVES)

	-- Selector noise (8 octaves, blends low/high).
	gen.selector_noise = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.SELECTOR_OCTAVES)

	-- Continentalness (10 octaves, large-scale variation).
	gen.continentalness = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.CONTINENTALNESS_OCTAVES)

	-- Depth noise (16 octaves, fine detail).
	gen.depth_noise = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.DEPTH_OCTAVES)

	-- Tree density noise (8 octaves).
	gen.tree_noise = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.TREE_DENSITY_OCTAVES)

	-- Temperature noise (4 octaves, for biome selection).
	gen.temperature = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.TEMPERATURE_OCTAVES)

	-- Humidity noise (4 octaves, for biome selection).
	gen.humidity = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.HUMIDITY_OCTAVES)

	-- Variation noise (2 octaves, biome detail).
	gen.variation = mcl_levelgen.beta.make_octaved_perlin (
		rng, beta.VARIATION_OCTAVES)

	-- Precompute scales.
	gen.low_scale = beta.LOW_NOISE_SCALE
	gen.high_scale = beta.HIGH_NOISE_SCALE
	gen.selector_x_scale = beta.SELECTOR_NOISE_X_SCALE
	gen.selector_y_scale = beta.SELECTOR_NOISE_Y_SCALE
	gen.selector_z_scale = beta.SELECTOR_NOISE_Z_SCALE
	gen.continentalness_scale = beta.CONTINENTALNESS_SCALE
	gen.depth_scale = beta.DEPTH_NOISE_SCALE

	-- Temperature/humidity scales.
	gen.temp_x_scale = beta.TEMPERATURE_X_SCALE
	gen.temp_y_scale = beta.TEMPERATURE_Y_SCALE
	gen.temp_z_scale = beta.TEMPERATURE_Z_SCALE
	gen.hum_x_scale = beta.HUMIDITY_X_SCALE
	gen.hum_y_scale = beta.HUMIDITY_Y_SCALE
	gen.hum_z_scale = beta.HUMIDITY_Z_SCALE
	gen.var_x_scale = beta.VARIATION_X_SCALE
	gen.var_y_scale = beta.VARIATION_Y_SCALE

	------------------------------------------------------------------------
	-- Terrain height calculation for a column (cx, cz).
	------------------------------------------------------------------------

	function gen.height_at (cx, cz)
		local low = gen.low_noise (
			cx * gen.low_scale,
			0,
			cz * gen.low_scale)

		local high = gen.high_noise (
			cx * gen.high_scale,
			0,
			cz * gen.high_scale)

		local selector = gen.selector_noise (
			cx * gen.selector_x_scale,
			cx * gen.selector_y_scale,
			cz * gen.selector_z_scale)

		-- Selector blends between low and high noise.
		local terrain
		if selector > 0.0 then
			terrain = low
		else
			terrain = high
		end

		-- Continentalness modulation.
		local continental = gen.continentalness (
			cx * gen.continentalness_scale,
			0,
			cz * gen.continentalness_scale)

		terrain = terrain * (continental + 1.0)

		-- Depth noise adds fine detail.
		local depth = gen.depth_noise (
			cx * gen.depth_scale,
			0,
			cz * gen.depth_scale)

		-- Final height: base sea level + terrain offset.
		terrain = terrain + 68.0 - depth * 4.0

		return terrain
	end

	------------------------------------------------------------------------
	-- Biome noise sampling for a column (cx, cz).
	-- Returns temperature and humidity in [0..1].
	------------------------------------------------------------------------

	function gen.biome_noise_at (cx, cz)
		local temperature = gen.temperature (
			cx * gen.temp_x_scale,
			cz * gen.temp_y_scale,
			0) * 0.5 + 0.5

		local humidity = gen.humidity (
			cx * gen.hum_x_scale,
			cz * gen.hum_y_scale,
			0) * 0.5 + 0.5

		-- Clamp to [0..1].
		temperature = math.max (0.0, math.min (1.0, temperature))
		humidity = math.max (0.0, math.min (1.0, humidity))

		return temperature, humidity
	end

	------------------------------------------------------------------------
	-- Tree density at a column.
	------------------------------------------------------------------------

	function gen.tree_density_at (cx, cz)
		return gen.tree_noise (
			cx * gen.low_scale,
			0,
			cz * gen.low_scale)
	end

	return gen
end
