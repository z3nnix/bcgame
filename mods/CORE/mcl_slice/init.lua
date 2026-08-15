-- Betacraft content slice.
-- When the `mcl_slice` setting is enabled, everything introduced in
-- Minecraft 1.13 or later (the pre-1.13 cutoff) is stripped:
--   * hidden from the creative inventory,
--   * crafting recipes producing it are removed,
--   * it no longer spawns as mobs or structures,
--   * modern biomes, ores and decorations no longer generate.
-- The lists of modern content live in generated_slice.lua (produced by
-- tools/gen_content_inventory.py).

local slice_enabled = core.settings:get_bool("mcl_slice", true)

if slice_enabled then
	-- Ensure the generated lists are available (load order is not guaranteed).
	dofile(core.get_modpath(core.get_current_modname()) .. "/generated_slice.lua")

	local prefix_set, keep_set, explicit_set, biome_set = {}, {}, {}, {}
	for _, prefix in ipairs(MCL_SLICE.mod_prefixes) do
		prefix_set[prefix] = true
	end
	for _, name in ipairs(MCL_SLICE.keep) do
		keep_set[name] = true
	end
	for _, name in ipairs(MCL_SLICE.items) do
		explicit_set[name] = true
	end
	for _, name in ipairs(MCL_SLICE.biomes) do
		biome_set[name] = true
	end

	-- Extend the disabled-structures list before mcl_structures loads.
	-- mcl_structures reads this setting during its own initialization; this
	-- mod has no dependencies and is therefore loaded before it.
	local disabled = {}
	local existing = core.settings:get("mcl_disabled_structures")
	if existing then
		for part in existing:gmatch("[^,]+") do
			disabled[part] = true
		end
	end
	for _, name in ipairs(MCL_SLICE.structures) do
		disabled[name] = true
	end
	local out = {}
	for name in pairs(disabled) do
		table.insert(out, name)
	end
	table.sort(out)
	core.settings:set("mcl_disabled_structures", table.concat(out, ","))

	local mob_set = {}
	for _, name in ipairs(MCL_SLICE.mobs) do
		mob_set[name] = true
	end

	local function biome_modern(name)
		if biome_set[name] then
			return true
		end
		for base in pairs(biome_set) do
			if name:sub(1, #base + 1) == base .. "_" then
				return true
			end
		end
		return false
	end

	local function node_sliced(nodename)
		if type(nodename) ~= "string" then
			return false
		end
		if explicit_set[nodename] then
			return true
		end
		local mod = nodename:match("^([^:]+):")
		return mod and prefix_set[mod] or false
	end

	local function biomes_modern(list)
		if type(list) == "string" then
			return biome_modern(list)
		end
		if type(list) == "table" then
			for _, name in ipairs(list) do
				if biome_modern(name) then
					return true
				end
			end
		end
		return false
	end

	-- Intercept worldgen registration. mcl_slice loads before mcl_biomes
	-- (no dependencies), so these wrappers see every modern biome/ore/deco.
	-- Modern biomes stay registered (other mods resolve their name -> id in
	-- on_mods_loaded callbacks) but get an inverted vertical range, so the
	-- map generator can never select them. Ores and decorations have no
	-- unregister API, so they are dropped at registration time.
	local neutralized_biomes, skipped_ores, skipped_deco = 0, 0, 0

	local old_register_biome = core.register_biome
	local old_register_ore = core.register_ore
	local old_register_decoration = core.register_decoration

	function core.register_biome(def)
		if def and biome_modern(def.name) then
			neutralized_biomes = neutralized_biomes + 1
			if type(def.y_min) == "number" and type(def.y_max) == "number" then
				def.y_min, def.y_max = def.y_max, def.y_min
			elseif type(def.min_pos) == "table" and type(def.max_pos) == "table" then
				local tmp = def.min_pos.y
				def.min_pos.y = def.max_pos.y
				def.max_pos.y = tmp
			end
			def.vertical_blend = 0
		end
		return old_register_biome(def)
	end

	function core.register_ore(def)
		if def and node_sliced(def.ore) then
			skipped_ores = skipped_ores + 1
			return nil
		end
		return old_register_ore(def)
	end

	function core.register_decoration(def)
		if def and (node_sliced(def.deco) or biomes_modern(def.biomes)) then
			skipped_deco = skipped_deco + 1
			return nil
		end
		return old_register_decoration(def)
	end

	core.register_on_mods_loaded(function()
		-- Hide modern items from the creative inventory and drop their recipes.
		-- Hide by mod prefix (catches dynamically-registered items), plus the
		-- explicitly-listed itemstrings (e.g. modern mob spawn eggs, whose
		-- mod also contains pre-1.13 content; and wood-derived items that live
		-- in shared namespaces like mcl_trees / mcl_signs). Pre-1.13 items
		-- inside modern mods are kept via MCL_SLICE.keep.
		local hidden = 0
		for name, def in pairs(core.registered_items) do
			local mod = name:match("^([^:]+):")
			local modern = (mod and prefix_set[mod] and not keep_set[name])
				or explicit_set[name]
			if modern then
				local groups = table.copy(def.groups or {})
				groups.not_in_creative_inventory = 1
				core.override_item(name, { groups = groups })
				core.clear_craft({ output = name })
				hidden = hidden + 1
			end
		end

		-- Remove modern mob spawners. mcl_mobs rebuilds its spawner table in
		-- its own on_mods_loaded callback, which runs after this callback, so
		-- defer the filtering to the next server step.
		core.after(0, function()
			if not mcl_mobs or not mcl_mobs.registered_spawners then
				return
			end
			local function filter_map(map)
				for _, categories in pairs(map) do
					for _, list in pairs(categories) do
						for i = #list, 1, -1 do
							local spawner = list[i]
							if spawner and spawner.name and mob_set[spawner.name] then
								table.remove(list, i)
							end
						end
					end
				end
			end
			filter_map(mcl_mobs.registered_spawners)
			if mcl_mobs.registered_structure_spawners then
				filter_map(mcl_mobs.registered_structure_spawners)
			end
		end)

		-- Log the totals on the first server step (the counters are final by
		-- now, and no mapgen chunk has been generated yet).
		core.after(0, function()
			core.log("action", "[mcl_slice] hidden " .. hidden
				.. " items, disabled " .. #MCL_SLICE.structures
				.. " structures, neutralized " .. neutralized_biomes
				.. " biomes, " .. skipped_ores .. " ores, " .. skipped_deco
				.. " decorations")
		end)
	end)
end
