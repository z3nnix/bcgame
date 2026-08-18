------------------------------------------------------------------------
-- Beta 1.7.3 population pipeline.
-- Orchestrates all decorators in the correct order:
--   1. Terrain (base heightmap + stone/water/air)
--   2. Aquifer (water/lava below sea level)
--   3. Surface (biome top/filler blocks)
--   4. Carvers (caves)
--   5. Ores
--   6. Lakes
--   7. Trees
--   8. Vegetation
--   9. Dungeons
--  10. Freeze (snow/ice for cold biomes)
------------------------------------------------------------------------

local beta_population = {}
mcl_levelgen.beta_population = beta_population

------------------------------------------------------------------------
-- Generate a complete chunk.
-- Returns heightmap for use by ersatz system.
------------------------------------------------------------------------

function beta_population.generate_chunk (minp, maxp, cids, param2s, area)
	local gen = mcl_levelgen.beta_gen
	if not gen then
		return nil
	end

	local beta = mcl_levelgen.beta

	-- Temporary biome array (16x16).
	local biomes = {}

	-- Step 1: Generate terrain (heightmap + stone/water).
	local heightmap = mcl_levelgen.beta_terrain.generate (
		minp, maxp, cids, param2s, area, gen, biomes)

	-- Step 2: Fill aquifers.
	mcl_levelgen.beta_aquifer.fill (cids, area, minp, maxp, heightmap)

	-- Step 3: Freeze (snow/ice for cold biomes).
	mcl_levelgen.beta_surface.freeze (cids, area, minp, maxp, biomes)

	-- Step 4: Carve caves.
	mcl_levelgen.beta_carvers.generate (cids, area, minp, maxp,
					   heightmap)

	-- Step 5: Place ores.
	mcl_levelgen.beta_ores.generate (cids, area, minp, maxp)

	-- Step 6: Place lakes.
	mcl_levelgen.beta_lakes.generate (cids, area, minp, maxp,
					  heightmap)

	-- Step 7: Place trees.
	mcl_levelgen.beta_trees.generate (cids, area, minp, maxp,
					  heightmap, biomes)

	-- Step 8: Place vegetation.
	mcl_levelgen.beta_vegetation.generate (cids, area, minp, maxp,
					       heightmap, biomes)

	-- Step 9: Place dungeons.
	mcl_levelgen.beta_dungeons.generate (cids, area, minp, maxp,
					     heightmap)

	return heightmap
end

------------------------------------------------------------------------
-- Beta terrain generator object (compatible with existing interface).
------------------------------------------------------------------------

local beta_gen_object = {}
mcl_levelgen.beta_gen_object = beta_gen_object

function beta_gen_object.generate (self, x, y, z, cids, param2s,
				   structuremask, index_fn, biomes)
	local minp = { x = x, y = y, z = z }
	local maxp = {
		x = x + self.chunksize - 1,
		y = y + self.chunksize_y - 1,
		z = z + self.chunksize - 1,
	}

	local heightmap = beta_population.generate_chunk (
		minp, maxp, cids, param2s, self.area)

	if heightmap then
		-- Copy heightmap for ersatz compatibility.
		for i = 1, self.chunksize * self.chunksize do
			self.heightmap[i] = heightmap[i] or 0
			self.heightmap_wg[i] = heightmap[i] or 0
		end
	end

	return true
end

function beta_gen_object.get_one_height (self, x, z)
	if not mcl_levelgen.beta_gen then
		return -32768
	end
	return mcl_levelgen.beta_terrain.get_height (
		mcl_levelgen.beta_gen, x, -z - 1)
end

------------------------------------------------------------------------
-- Initialize the Beta 1.7.3 terrain generator.
------------------------------------------------------------------------

function mcl_levelgen.make_beta_terrain_generator (preset, chunksize,
						   ychunksize)
	local gen = mcl_levelgen.beta.make_generators (preset.seed)
	mcl_levelgen.beta_gen = gen

	local obj = {}
	for k, v in pairs (beta_gen_object) do
		obj[k] = v
	end

	obj.preset = preset
	obj.chunksize = chunksize
	obj.chunksize_y = ychunksize
	obj.y_min = preset.min_y
	obj.level_height = preset.height
	obj.heightmap = {}
	obj.heightmap_wg = {}

	for i = 1, chunksize * chunksize do
		obj.heightmap[i] = 0
		obj.heightmap_wg[i] = 0
	end

	-- Create VoxelArea helper.
	local emin = { x = 0, y = 0, z = 0 }
	local emax = {
		x = chunksize - 1,
		y = ychunksize - 1,
		z = chunksize - 1,
	}
	obj.area = VoxelArea (emin, emax)

	return obj
end
