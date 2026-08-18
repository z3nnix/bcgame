------------------------------------------------------------------------
-- Beta 1.7.3 tree generation.
-- Trees are placed based on biome and density noise.
------------------------------------------------------------------------

local floor = math.floor

local beta_trees = {}
mcl_levelgen.beta_trees = beta_trees

------------------------------------------------------------------------
-- Tree types by biome.
------------------------------------------------------------------------

local tree_types = {
	[mcl_levelgen.beta.BIOME_TEMPERATE_FOREST] = "oak",
	[mcl_levelgen.beta.BIOME_FOREST]          = "oak",
	[mcl_levelgen.beta.BIOME_SHRUBLAND]       = "oak",
	[mcl_levelgen.beta.BIOME_TAIGA]           = "pine",
	[mcl_levelgen.beta.BIOME_DESERT]          = nil,
	[mcl_levelgen.beta.BIOME_PLAINS]          = "oak",
	[mcl_levelgen.beta.BIOME_ICE_DESERT]      = nil,
	[mcl_levelgen.beta.BIOME_TUNDRA]          = "pine",
}

------------------------------------------------------------------------
-- Tree placement seeds.
------------------------------------------------------------------------

local function tree_seed (cx, cz)
	return bit.bxor (
		cx * 341873128712 + cz * 132897987541,
		0x5DEECE66D)
end

------------------------------------------------------------------------
-- Place a simple oak tree at (wx, wy, wz).
------------------------------------------------------------------------

local function place_oak (cids, area, wx, wy, wz)
	local log = core.get_content_id ("mcl_core:tree")
	local leaves = core.get_content_id ("mcl_core:leaves")
	local air = core.CONTENT_AIR
	local index = area.index

	-- Trunk: 4-5 blocks tall.
	local trunk_h = 4
	local vi = index (wx, wy, wz)
	if cids[vi] ~= air then return end

	for dy = 0, trunk_h - 1 do
		local ti = index (wx, wy + dy, wz)
		if ti then cids[ti] = log end
	end

	-- Leaves: 3x3x2 around top, 3x3 at one lower.
	local top = wy + trunk_h
	for dx = -2, 2 do
		for dz = -2, 2 do
			if abs (dx) + abs (dz) <= 3 then
				for dy = -1, 1 do
					local li = index (wx + dx,
							   top + dy,
							   wz + dz)
					if li and cids[li] == air then
						cids[li] = leaves
					end
				end
			end
		end
	end

	-- Top cap.
	for dx = -1, 1 do
		for dz = -1, 1 do
			if abs (dx) + abs (dz) <= 1 then
				local li = index (wx + dx, top + 2, wz + dz)
				if li and cids[li] == air then
					cids[li] = leaves
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Place a simple pine tree at (wx, wy, wz).
------------------------------------------------------------------------

local function place_pine (cids, area, wx, wy, wz)
	local log = core.get_content_id ("mcl_core:spruce_tree")
	local leaves = core.get_content_id ("mcl_core:spruce_leaves")
	local air = core.CONTENT_AIR
	local index = area.index

	local vi = index (wx, wy, wz)
	if cids[vi] ~= air then return end

	-- Trunk: 6-7 blocks tall.
	local trunk_h = 6
	for dy = 0, trunk_h - 1 do
		local ti = index (wx, wy + dy, wz)
		if ti then cids[ti] = log end
	end

	-- Leaves: cone shape.
	local top = wy + trunk_h
	for radius = 0, 2 do
		local y_start = top - radius * 2
		for dy = 0, 2 do
			for dx = -radius, radius do
				for dz = -radius, radius do
					if abs (dx) + abs (dz) <= radius + 1 then
						local li = index (
							wx + dx,
							y_start + dy,
							wz + dz)
						if li and cids[li] == air then
							cids[li] = leaves
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Place trees for a chunk.
------------------------------------------------------------------------

function beta_trees.generate (cids, area, minp, maxp, heightmap, biomes)
	local beta = mcl_levelgen.beta
	local biomes_table = beta.biomes
	local SEA_LEVEL = beta.SEA_LEVEL
	local index = area.index

	-- Use chunk seed for deterministic placement.
	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	-- Try to place 1-3 trees per chunk in suitable biomes.
	for lx = 2, 13 do
		for lz = 2, 13 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz
			local biome_id = biomes[lx * 16 + lz + 1]
			local tree_type = tree_types[biome_id]

			if tree_type then
				local h = heightmap[lx * 16 + lz + 1]
				if h and h > SEA_LEVEL + 1
					and h < 120 then
					-- Deterministic placement.
					local seed = tree_seed (cx, cz)
					local rng = mcl_levelgen.jvm_random (
						mcl_levelgen.extull (seed))

					-- ~15% chance of tree per column.
					if rng:next_within (100) < 15 then
						local wx = minp.x + lx
						local wz = minp.z + lz
						local wy = h + 1

						if tree_type == "oak" then
							place_oak (cids, area,
								   wx, wy, wz)
						elseif tree_type == "pine" then
							place_pine (cids, area,
							    wx, wy, wz)
						end
					end
				end
			end
		end
	end
end
