------------------------------------------------------------------------
-- Beta 1.7.3 surface system.
-- Applies biome-specific surface blocks (top + filler).
-- Also handles snow layer placement for cold biomes.
------------------------------------------------------------------------

local beta_surface = {}
mcl_levelgen.beta_surface = beta_surface

local cid_dirt
local cid_sand
local cid_snow
local cid_snow_block
local cid_ice
local cid_grass
local cid_air
local cid_water

local function init_cids ()
	cid_dirt = core.get_content_id ("mcl_core:dirt")
	cid_sand = core.get_content_id ("mcl_core:sand")
	cid_snow = core.get_content_id ("mcl_core:snow")
	cid_snow_block = core.get_content_id ("mcl_core:snowblock")
	cid_ice = core.get_content_id ("mcl_core:ice")
	cid_grass = core.get_content_id ("mcl_core:dirt_with_grass")
	cid_air = core.CONTENT_AIR
	cid_water = core.get_content_id ("mcl_core:water_source")
end

if core and core.register_on_mods_loaded then
	core.register_on_mods_loaded (init_cids)
else
	init_cids ()
end

------------------------------------------------------------------------
-- Apply snow/ice for cold biomes after terrain generation.
------------------------------------------------------------------------

function beta_surface.freeze (cids, area, minp, maxp, biomes)
	local beta = mcl_levelgen.beta
	local biomes_table = beta.biomes
	local index = area.index

	for lx = 0, 15 do
		for lz = 0, 15 do
			local biome_id = biomes[lx * 16 + lz + 1]
			local biome = biomes_table[biome_id]
			if biome and biome.snow then
				-- Find the top block of this column.
				for ly = 127, 0, -1 do
					local vi = index (minp.x + lx,
							  minp.y + ly,
							  minp.z + lz)
					if cids[vi] ~= cid_air
						and cids[vi] ~= cid_water then
						-- Place snow on top.
						if ly < 127 then
							local top_vi
								= index (
									minp.x + lx,
									minp.y + ly + 1,
									minp.z + lz)
							if cids[top_vi] == cid_air then
								cids[top_vi] = cid_snow
							end
						end
						-- Ice on water in frozen biomes.
						if cids[vi] == cid_water then
							cids[vi] = cid_ice
						end
						break
					end
				end
			end
		end
	end
end
