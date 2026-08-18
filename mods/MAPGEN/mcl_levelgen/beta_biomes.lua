------------------------------------------------------------------------
-- Beta 1.7.3 biome generation and caching.
-- Biomes are computed from temperature and humidity using Simplex noise
-- and cached in a 64x64 table as in the original.
------------------------------------------------------------------------

local floor = math.floor
local band = bit.band

local beta_biomes = {}
mcl_levelgen.beta_biomes = beta_biomes

------------------------------------------------------------------------
-- Biome cache.
-- Stores biome IDs for a 64x64 region, recomputed on each chunk load
-- as in the original Beta 1.7.3.
------------------------------------------------------------------------

function beta_biomes.generate_biome_cache (gen, chunk_x, chunk_z)
	local cache_size = mcl_levelgen.beta.BIOME_CACHE_SIZE
	local cache = {}

	for lx = 0, cache_size - 1 do
		for lz = 0, cache_size - 1 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz
			local temp, hum = gen.biome_noise_at (cx, cz)
			cache[lx * cache_size + lz + 1]
				= mcl_levelgen.beta.select_biome (temp, hum)
		end
	end

	return cache, cache_size
end

------------------------------------------------------------------------
-- Get biome at a local position within the cache.
------------------------------------------------------------------------

function beta_biomes.get_biome (cache, cache_size, lx, lz)
	-- Wrap coordinates into cache range.
	local ix = band (lx, cache_size - 1)
	local iz = band (lz, cache_size - 1)
	return cache[ix * cache_size + iz + 1]
end

------------------------------------------------------------------------
-- Engine-side biome registration for Beta 1.7.3 biomes.
------------------------------------------------------------------------

function beta_biomes.register_engine_biomes ()
	if not core or not core.register_biome then
		return
	end

	local biomes_table = mcl_levelgen.beta.biomes
	local name_map = mcl_levelgen.beta.biome_name_map

	for id, info in pairs (biomes_table) do
		local name = name_map[id] or info.name

		-- Map biome to Minetest biome properties.
		local temp_dev = 0.5
		local hum_dev = 0.5

		-- Cold biomes.
		if info.snow then
			temp_dev = 0.0
		elseif info.rain then
			temp_dev = 0.5
		end

		if info.rain then
			hum_dev = 0.8
		else
			hum_dev = 0.0
		end

		core.register_biome ({
			name = "beta_" .. name .. "_" .. id,
			node_top = info.top,
			node_filler = info.filler,
			depth_filler = 3,
			node_stone = "mcl_core:stone",
			y_min = 1,
			y_max = 128,
			heat_point = temp_dev * 100,
			humidity_point = hum_dev * 100,
		})
	end
end
