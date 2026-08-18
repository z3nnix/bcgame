------------------------------------------------------------------------
-- Beta 1.7.3 dungeon generation.
-- Dark brick rooms with mob spawners and chests.
------------------------------------------------------------------------

local floor = math.floor

local beta_dungeons = {}
mcl_levelgen.beta_dungeons = beta_dungeons

------------------------------------------------------------------------
-- Dungeon parameters.
------------------------------------------------------------------------

local DUNGEON_MIN_SIZE = 2
local DUNGEON_MAX_SIZE = 5

------------------------------------------------------------------------
-- Attempt to place a dungeon in a chunk.
------------------------------------------------------------------------

function beta_dungeons.generate (cids, area, minp, maxp, heightmap)
	local stone = core.get_content_id ("mcl_core:stone")
	local air = core.CONTENT_AIR
	local cobble = core.get_content_id ("mcl_core:cobble")
	local mossy = core.get_content_id ("mcl_core:mossycobble")
	local spawner = core.get_content_id ("mcl_mobspawners:spawner")
	local plank = core.get_content_id ("mcl_core:planks")
	local index = area.index

	local SEA_LEVEL = mcl_levelgen.beta.SEA_LEVEL
	local chunk_x = minp.x
	local chunk_z = -maxp.z - 1

	-- ~25% chance of dungeon per chunk.
	local seed = bit.bxor (
		chunk_x * 73856093 + chunk_z * 83492791 + 9999,
		0x5DEECE66D)
	local rng = mcl_levelgen.jvm_random (mcl_levelgen.extull (seed))

	if rng:next_within (100) >= 25 then
		return
	end

	-- Choose dungeon position and size.
	local dx = rng:next_within (8) + 3
	local dz = rng:next_within (8) + 3
	local dw = DUNGEON_MIN_SIZE + rng:next_within (
		DUNGEON_MAX_SIZE - DUNGEON_MIN_SIZE + 1)
	local dd = DUNGEON_MIN_SIZE + rng:next_within (
		DUNGEON_MAX_SIZE - DUNGEON_MIN_SIZE + 1)
	local dh = 3

	-- Find a suitable Y position (underground).
	local lx = dx
	local lz = dz
	local h = heightmap[lx * 16 + lz + 1] or SEA_LEVEL
	local dy = math.max (5, h - 8 - rng:next_within (10))

	-- Carve room.
	for x = 0, dw do
		for z = 0, dd do
			for y = 0, dh do
				local bx = minp.x + dx + x
				local bz = minp.z + dz + z
				local by = dy + y

				local vi = index (bx, by, bz)
				if vi then
					if y == 0 then
						-- Floor.
						if rng:next_within (10) < 3 then
							cids[vi] = mossy
						else
							cids[vi] = cobble
						end
					elseif x == 0 or x == dw
						or z == 0 or z == dd then
						-- Walls.
						cids[vi] = cobble
					else
						cids[vi] = air
					end
				end
			end
		end
	end

	-- Place spawner in center.
	local sx = minp.x + dx + math.floor (dw / 2)
	local sz = minp.z + dz + math.floor (dd / 2)
	local sy = dy + 1
	local si = index (sx, sy, sz)
	if si then
		cids[si] = spawner
	end

	-- Place chests (1-2 per dungeon).
	local num_chests = 1 + rng:next_within (2)
	for _ = 1, num_chests do
		local cx = minp.x + dx + 1 + rng:next_within (math.max (1, dw - 2))
		local cz = minp.z + dz + 1 + rng:next_within (math.max (1, dd - 2))
		local cy = dy + 1
		local ci = index (cx, cy, cz)
		if ci then
			cids[ci] = core.get_content_id ("mcl_chests:chest")
		end
	end
end
