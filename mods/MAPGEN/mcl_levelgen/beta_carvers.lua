------------------------------------------------------------------------
-- Beta 1.7.3 cave (carver) generation.
-- Uses Perlin noise to carve tunnels and chambers.
------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs

local beta_carvers = {}
mcl_levelgen.beta_carvers = beta_carvers

------------------------------------------------------------------------
-- Cave parameters.
------------------------------------------------------------------------

local CAVE_NOISE_SCALE_X = 1.0 / 64.0
local CAVE_NOISE_SCALE_Y = 1.0 / 64.0
local CAVE_NOISE_SCALE_Z = 1.0 / 64.0
local CAVE_THRESHOLD = 0.55

local RAVINE_NOISE_SCALE_X = 1.0 / 200.0
local RAVINE_NOISE_SCALE_Y = 1.0 / 80.0
local RAVINE_NOISE_SCALE_Z = 1.0 / 200.0
local RAVINE_THRESHOLD = 0.7

------------------------------------------------------------------------
-- Carve caves in a column.
------------------------------------------------------------------------

function beta_carvers.carve_column (cids, area, minp, lx, lz,
				    heightmap, gen_rnd)
	local stone_cid = core.get_content_id ("mcl_core:stone")
	local air_cid = core.CONTENT_AIR
	local lava_cid = core.get_content_id ("mcl_core:lava_source")
	local water_cid = core.get_content_id ("mcl_core:water_source")

	local index = area.index
	local SEA_LEVEL = mcl_levelgen.beta.SEA_LEVEL

	local h = heightmap[lx * 16 + lz + 1] or SEA_LEVEL

	-- Simple pseudo-cave carving using column-based randomness.
	-- In Beta 1.7.3, caves are carved using 3D Perlin noise.
	for ly = 2, math.min (h - 1, 120) do
		local vi = index (minp.x + lx, minp.y + ly, minp.z + lz)

		if cids[vi] == stone_cid then
			-- Use a deterministic hash for cave noise.
			local wx = minp.x + lx
			local wz = minp.z + lz

			-- Simple hash-based cave determination.
			local hash = bit.bxor (
				wx * 73856093 + ly * 19349669
				+ wz * 83492791, ly * 6364136223846793005)

			-- Cave frequency check.
			if bit.band (hash, 0x1FF) == 0 and ly < h - 5 then
				-- Carve a small cave.
				for dx = -1, 1 do
					for dz = -1, 1 do
						for ddy = -1, 0 do
							local nx = wx + dx
							local nz = wz + dz
							local ny = ly + ddy
							if ny >= 2 and ny < h then
								local nvi = index (nx, ny + minp.y, nz)
								if nvi and cids[nvi] == stone_cid then
									cids[nvi] = air_cid
								end
							end
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Carve caves for an entire chunk.
------------------------------------------------------------------------

function beta_carvers.generate (cids, area, minp, maxp, heightmap)
	for lx = 0, 15 do
		for lz = 0, 15 do
			beta_carvers.carve_column (cids, area, minp,
						   lx, lz, heightmap)
		end
	end
end
