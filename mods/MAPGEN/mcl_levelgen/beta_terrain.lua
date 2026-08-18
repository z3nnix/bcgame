------------------------------------------------------------------------
-- Beta 1.7.3 terrain generation.
-- Fills a VoxelManip with terrain based on heightmap.
------------------------------------------------------------------------

local floor = math.floor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift

------------------------------------------------------------------------
-- Node content IDs.
------------------------------------------------------------------------

local cid_stone
local cid_water_source
local cid_lava_source
local cid_air
local cid_bedrock
local cid_dirt
local cid_grass
local cid_sand
local cid_gravel
local cid_snow

local function init_cids ()
	cid_stone = core.get_content_id ("mcl_core:stone")
	cid_water_source = core.get_content_id ("mcl_core:water_source")
	cid_lava_source = core.get_content_id ("mcl_core:lava_source")
	cid_air = core.CONTENT_AIR
	cid_bedrock = core.get_content_id ("mcl_core:bedrock")
	cid_dirt = core.get_content_id ("mcl_core:dirt")
	cid_grass = core.get_content_id ("mcl_core:dirt_with_grass")
	cid_sand = core.get_content_id ("mcl_core:sand")
	cid_gravel = core.get_content_id ("mcl_core:gravel")
	cid_snow = core.get_content_id ("mcl_core:snow")
end

if core and core.register_on_mods_loaded then
	core.register_on_mods_loaded (init_cids)
else
	init_cids ()
end

------------------------------------------------------------------------
-- Beta terrain generator object.
------------------------------------------------------------------------

local beta_terrain = {}
mcl_levelgen.beta_terrain = beta_terrain

------------------------------------------------------------------------
-- Generate terrain for a chunk.
-- minp, maxp: Luanti coordinates.
-- cids, param2s: output arrays.
-- area: VoxelArea.
-- gen: beta_generators object.
-- biomes: output biome array (indexed by x*16+z+1).
------------------------------------------------------------------------

function beta_terrain.generate (minp, maxp, cids, param2s, area,
			       gen, biomes)
	local beta = mcl_levelgen.beta
	local SEA_LEVEL = beta.SEA_LEVEL
	local HEIGHT = beta.HEIGHT
	local MIN_Y = beta.MIN_Y
	local biomes_table = mcl_levelgen.beta.biomes

	-- Chunk coordinates in Minecraft space (Z inverted).
	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	-- Heightmap for this chunk (16x16).
	local heightmap = {}

	-- Phase 1: Compute heightmap and biomes.
	for lx = 0, 15 do
		for lz = 0, 15 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz

			-- Compute terrain height.
			local raw_height = gen.height_at (cx, cz)
			local height = floor (raw_height + 0.5)
			height = math.max (MIN_Y,
				math.min (HEIGHT - 1, height))
			heightmap[lx * 16 + lz + 1] = height

			-- Compute biome.
			local temp, hum = gen.biome_noise_at (cx, cz)
			local biome_id = mcl_levelgen.beta.select_biome (
				temp, hum)
			biomes[lx * 16 + lz + 1] = biome_id
		end
	end

	-- Phase 2: Fill VoxelManip.
	local index = area.index

	for lx = 0, 15 do
		for lz = 0, 15 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz
			local h = heightmap[lx * 16 + lz + 1]
			local biome_id = biomes[lx * 16 + lz + 1]
			local biome = biomes_table[biome_id]
				or biomes_table[beta.BIOME_PLAINS]

			for ly = MIN_Y, HEIGHT - 1 do
				local vi = index (minp.x + lx,
						  minp.y + ly,
						  minp.z + lz)

				if ly == 0 then
					-- Bedrock layer.
					cids[vi] = cid_bedrock
				elseif ly <= h then
					-- Underground / surface.
					if ly == h then
						-- Surface block.
						if biome.top == "mcl_core:dirt_with_grass" then
							cids[vi] = cid_grass
						elseif biome.top == "mcl_core:sand" then
							cids[vi] = cid_sand
						else
							cids[vi] = cid_dirt
						end
					elseif ly >= h - 3 then
						-- Filler (dirt/sand).
						if biome.filler == "mcl_core:dirt" then
							cids[vi] = cid_dirt
						else
							cids[vi] = cid_sand
						end
					else
						-- Stone.
						cids[vi] = cid_stone
					end
					param2s[vi] = 0
				else
					-- Above terrain.
					if ly <= SEA_LEVEL then
						-- Water.
						cids[vi] = cid_water_source
					else
						cids[vi] = cid_air
					end
					param2s[vi] = 0
				end
			end
		end
	end

	return heightmap
end

------------------------------------------------------------------------
-- Get height at a world position (for ersatz compatibility).
------------------------------------------------------------------------

function beta_terrain.get_height (gen, wx, wz)
	local raw = gen.height_at (wx, wz)
	return floor (raw + 0.5)
end
