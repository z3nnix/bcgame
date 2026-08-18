------------------------------------------------------------------------
-- Beta 1.7.3 ore generation.
-- Ores are placed using Java Random seeded per-column.
------------------------------------------------------------------------

local floor = math.floor

local beta_ores = {}
mcl_levelgen.beta_ores = beta_ores

------------------------------------------------------------------------
-- Ore definitions.
-- Each ore: name, min_y, max_y, veins_per_chunk, vein_size,
--           frequency (blocks between veins on each axis).
------------------------------------------------------------------------

local ore_defs = {
	{
		name = "Coal",
		node = "mcl_core:stone_with_coal",
		min_y = 5,
		max_y = 80,
		veins = 20,
		vein_size = 17,
		frequency = 14,
	},
	{
		name = "Iron",
		node = "mcl_core:stone_with_iron",
		min_y = 5,
		max_y = 64,
		veins = 20,
		vein_size = 9,
		frequency = 11,
	},
	{
		name = "Gold",
		node = "mcl_core:stone_with_gold",
		min_y = 5,
		max_y = 32,
		veins = 2,
		vein_size = 9,
		frequency = 10,
	},
	{
		name = "Diamond",
		node = "mcl_core:stone_with_diamond",
		min_y = 5,
		max_y = 16,
		veins = 1,
		vein_size = 8,
		frequency = 9,
	},
	{
		name = "Redstone",
		node = "mcl_core:stone_with_redstone",
		min_y = 5,
		max_y = 16,
		veins = 8,
		vein_size = 8,
		frequency = 10,
	},
	{
		name = "Lapis",
		node = "mcl_core:stone_with_lapis",
		min_y = 14,
		max_y = 32,
		veins = 1,
		vein_size = 7,
		frequency = 9,
	},
}

------------------------------------------------------------------------
-- Java Random per-column seed for ore placement.
-- Uses the standard Minecraft column seed formula.
------------------------------------------------------------------------

local function column_seed (cx, cz, salt)
	return bit.bxor (
		cx * 341873128712 + cz * 132897987541 + salt,
		0x5DEECE66D)
end

------------------------------------------------------------------------
-- Place ores for a single column.
------------------------------------------------------------------------

local function place_ore_column (ore, cx, cz, cids, area, minp,
				 stone_cid)
	local band = bit.band
	local index = area.index

	for _, v in ipairs (ore_defs) do
		-- Seed RNG for this column and ore.
		local seed = column_seed (cx, cz, v.name:len () * 7919)
		local rng = mcl_levelgen.jvm_random (mcl_levelgen.extull (seed))

		for _ = 1, v.veins do
			local vx = rng:next_within (15)
			local vz = rng:next_within (15)
			local vy = v.min_y
				+ rng:next_within (v.max_y - v.min_y)

			-- Generate vein.
			for _ = 1, v.vein_size do
				local dx = rng:next_within (v.frequency)
					- math.floor (v.frequency / 2)
				local dy = rng:next_within (v.frequency)
					- math.floor (v.frequency / 2)
				local dz = rng:next_within (v.frequency)
					- math.floor (v.frequency / 2)

				local bx = minp.x + vx + dx
				local by = vy + dy
				local bz = minp.z + vz + dz

				if by >= 5 and by <= v.max_y then
					local vi = index (bx, by, bz)
					if vi and cids[vi] == stone_cid then
						cids[vi] = core.get_content_id (v.node)
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Place all ores for a chunk.
------------------------------------------------------------------------

function beta_ores.generate (cids, area, minp, maxp)
	local stone_cid = core.get_content_id ("mcl_core:stone")
	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	for lx = 0, 15 do
		for lz = 0, 15 do
			local cx = chunk_x + lx
			local cz = chunk_z + lz
			place_ore_column (nil, cx, lz, cids, area, minp,
					   stone_cid)
		end
	end
end
