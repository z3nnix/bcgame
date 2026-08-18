------------------------------------------------------------------------
-- Beta 1.7.3 vegetation (flowers, tall grass).
------------------------------------------------------------------------

local beta_vegetation = {}
mcl_levelgen.beta_vegetation = beta_vegetation

------------------------------------------------------------------------
-- Vegetation per biome.
------------------------------------------------------------------------

local vegetation_defs = {
	[mcl_levelgen.beta.BIOME_TEMPERATE_FOREST] = {
		{ node = "mcl_flowers:dandelion",    chance = 30 },
		{ node = "mcl_flowers:poppy",        chance = 20 },
		{ node = "mcl_core:tallgrass",       chance = 50 },
	},
	[mcl_levelgen.beta.BIOME_FOREST] = {
		{ node = "mcl_flowers:dandelion",    chance = 25 },
		{ node = "mcl_flowers:poppy",        chance = 25 },
		{ node = "mcl_core:tallgrass",       chance = 40 },
	},
	[mcl_levelgen.beta.BIOME_SHRUBLAND] = {
		{ node = "mcl_flowers:dandelion",    chance = 15 },
		{ node = "mcl_core:tallgrass",       chance = 60 },
	},
	[mcl_levelgen.beta.BIOME_TAIGA] = {
		{ node = "mcl_core:tallgrass",       chance = 40 },
	},
	[mcl_levelgen.beta.BIOME_PLAINS] = {
		{ node = "mcl_flowers:dandelion",    chance = 10 },
		{ node = "mcl_flowers:poppy",        chance = 5 },
		{ node = "mcl_core:tallgrass",       chance = 50 },
	},
	[mcl_levelgen.beta.BIOME_TUNDRA] = {
		{ node = "mcl_core:tallgrass",       chance = 20 },
	},
}

------------------------------------------------------------------------
-- Place vegetation for a chunk.
------------------------------------------------------------------------

function beta_vegetation.generate (cids, area, minp, maxp,
				   heightmap, biomes)
	local beta = mcl_levelgen.beta
	local SEA_LEVEL = beta.SEA_LEVEL
	local air = core.CONTENT_AIR
	local index = area.index

	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	for lx = 0, 15 do
		for lz = 0, 15 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz
			local biome_id = biomes[lx * 16 + lz + 1]
			local defs = vegetation_defs[biome_id]

			if defs then
				local h = heightmap[lx * 16 + lz + 1]
				if h and h > SEA_LEVEL and h < 120 then
					local seed = bit.bxor (
						cx * 73856093 + cz * 83492791,
						0x5DEECE66D)
					local rng = mcl_levelgen.jvm_random (
						mcl_levelgen.extull (seed))

					for _, def in ipairs (defs) do
						if rng:next_within (100) < def.chance then
							-- Random offset for position.
							local ox = rng:next_within (15)
							local oz = rng:next_within (15)
							local bx = minp.x + ox
							local bz = minp.z + oz
							local by = (heightmap[
								ox * 16 + oz + 1]
								or SEA_LEVEL) + 1

							if by > SEA_LEVEL
								and by < 120 then
								local vi = index (bx, by, bz)
								if vi
									and cids[vi] == air then
									cids[vi] = core.get_content_id (
										def.node)
								end
							end
						end
					end
				end
			end
		end
	end
end
