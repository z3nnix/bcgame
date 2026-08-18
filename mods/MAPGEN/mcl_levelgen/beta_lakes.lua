------------------------------------------------------------------------
-- Beta 1.7.3 water and lava lake generation.
-- Small lakes placed on the surface.
------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs

local beta_lakes = {}
mcl_levelgen.beta_lakes = beta_lakes

------------------------------------------------------------------------
-- Lake parameters.
------------------------------------------------------------------------

local MIN_LAKE_SIZE = 3
local MAX_LAKE_SIZE = 5

------------------------------------------------------------------------
-- Place a small lake at (wx, wy, wz).
------------------------------------------------------------------------

local function place_lake (cids, area, wx, wy, wz, is_lava)
	local water = core.get_content_id ("mcl_core:water_source")
	local lava = core.get_content_id ("mcl_core:lava_source")
	local air = core.CONTENT_AIR
	local stone = core.get_content_id ("mcl_core:stone")
	local dirt = core.get_content_id ("mcl_core:dirt")
	local sand = core.get_content_id ("mcl_core:sand")
	local index = area.index

	local fluid = is_lava and lava or water

	-- Elliptical lake shape.
	local radius_x = 2 + (bit.band (
		wx * 73 + wz * 137, 0xFF) % (MAX_LAKE_SIZE - MIN_LAKE_SIZE + 1))
	local radius_z = 2 + (bit.band (
		wx * 137 + wz * 73, 0xFF) % (MAX_LAKE_SIZE - MIN_LAKE_SIZE + 1))

	for dx = -radius_x, radius_x do
		for dz = -radius_z, radius_z do
			local norm = (dx / radius_x) ^ 2 + (dz / radius_z) ^ 2
			if norm <= 1.0 then
				local bx = wx + dx
				local bz = wz + dz

				-- Find surface at this position.
				for ly = wy + 3, wy - 3, -1 do
					local vi = index (bx, ly, bz)
					if vi and (cids[vi] == stone
						or cids[vi] == dirt
						or cids[vi] == sand) then
						-- Place fluid at and above.
						for fill_y = ly + 1, ly + 2 do
							local fi = index (bx, fill_y, bz)
							if fi and cids[fi] == air then
								cids[fi] = fluid
							end
						end
						break
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Place lakes for a chunk.
------------------------------------------------------------------------

function beta_lakes.generate (cids, area, minp, maxp, heightmap)
	local SEA_LEVEL = mcl_levelgen.beta.SEA_LEVEL
	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	-- Try a few candidate positions per chunk.
	for attempt = 1, 3 do
		local lx = (bit.bxor (chunk_x * 31 + attempt * 7, 0xABCD) % 16)
		local lz = (bit.bxor (chunk_z * 31 + attempt * 13, 0xDCBA) % 16)

		local h = heightmap[lx * 16 + lz + 1]
		if h and h > SEA_LEVEL + 1 and h < 110 then
			-- ~5% chance per attempt.
			local seed = bit.bxor (
				chunk_x * 73856093 + chunk_z * 83492791
				+ attempt * 31337, 0x5DEECE66D)
			local rng = mcl_levelgen.jvm_random (
				mcl_levelgen.extull (seed))

			if rng:next_within (100) < 5 then
				local is_lava = (h < 10)
				place_lake (cids, area,
					    minp.x + lx,
					    h,
					    minp.z + lz,
					    is_lava)
			end
		end
	end
end
