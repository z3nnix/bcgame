-- Temporary verification mod for the mcl_slice biome neutralization.
-- Samples the biome of a grid of columns (both overworld and nether) and
-- logs any modern biome name that the map generator could still select.

local modern = {
	BambooJungle = true, CherryGrove = true, DeepDark = true,
	DripstoneCave = true, Grove = true, LushCaves = true,
	MangroveSwamp = true, PaleGarden = true,
}

local function modern_name(name)
	if modern[name] then
		return true
	end
	for base in pairs(modern) do
		if name:sub(1, #base + 1) == base .. "_" then
			return true
		end
	end
	return false
end

core.register_on_mods_loaded(function()
	core.after(5, function()
		local found = {}
		local names = {}
		for x = -2000, 2000, 64 do
			for z = -2000, 2000, 64 do
				for _, y in ipairs({ -60, 0, 40, 64, 100, 140 }) do
					local data = core.get_biome_data({ x = x, y = y, z = z })
					local name = data and core.get_biome_name(data.biome) or "?"
					names[name] = true
					if modern_name(name) then
						found[name] = true
					end
				end
			end
		end
		local list = {}
		for name in pairs(names) do
			table.insert(list, name)
		end
		table.sort(list)
		local bad = {}
		for name in pairs(found) do
			table.insert(bad, name)
		end
		table.sort(bad)
		core.log("action", "[slice_test] sampled biomes: " .. #list
			.. " (" .. table.concat(list, ", ") .. ")")
		if #bad == 0 then
			core.log("action", "[slice_test] OK: no modern biome selectable")
		else
			core.log("error", "[slice_test] LEAK: modern biome selectable: "
				.. table.concat(bad, ", "))
		end
	end)
end)
