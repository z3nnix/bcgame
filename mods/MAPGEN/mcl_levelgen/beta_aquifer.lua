------------------------------------------------------------------------
-- Beta 1.7.3 aquifer (water/lava placement).
-- In Beta 1.7.3, aquifers are simple:
-- - Water fills below sea level where there is air.
-- - Lava fills below y=10 where there is air.
------------------------------------------------------------------------

local beta_aquifer = {}
mcl_levelgen.beta_aquifer = beta_aquifer

local cid_water_source
local cid_lava_source
local cid_air

local function init_cids ()
	cid_water_source = core.get_content_id ("mcl_core:water_source")
	cid_lava_source = core.get_content_id ("mcl_core:lava_source")
	cid_air = core.CONTENT_AIR
end

if core and core.register_on_mods_loaded then
	core.register_on_mods_loaded (init_cids)
else
	init_cids ()
end

------------------------------------------------------------------------
-- Fill water and lava in the VoxelManip.
-- Called after terrain generation.
------------------------------------------------------------------------

function beta_aquifer.fill (cids, area, minp, maxp, heightmap)
	local SEA_LEVEL = mcl_levelgen.beta.SEA_LEVEL
	local LAVA_LEVEL = 10

	local index = area.index

	for lx = 0, 15 do
		for lz = 0, 15 do
			local h = heightmap[lx * 16 + lz + 1]
				or SEA_LEVEL

			for ly = 0, 127 do
				local vi = index (minp.x + lx,
						  minp.y + ly,
						  minp.z + lz)

				if cids[vi] == cid_air then
					if ly <= SEA_LEVEL and ly > h then
						-- Water above sea level
						-- but below terrain.
						cids[vi] = cid_water_source
					elseif ly <= LAVA_LEVEL then
						-- Lava at deep level.
						cids[vi] = cid_lava_source
					end
				end
			end
		end
	end
end
