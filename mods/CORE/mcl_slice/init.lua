-- Betacraft content slice.
-- When the `mcl_slice` setting is enabled, everything introduced in
-- Minecraft 1.13 or later (the pre-1.13 cutoff) is stripped:
--   * hidden from the creative inventory,
--   * crafting recipes producing it are removed,
--   * it no longer spawns as mobs or structures.
-- The lists of modern content live in generated_slice.lua (produced by
-- tools/gen_content_inventory.py).

local slice_enabled = core.settings:get_bool("mcl_slice", true)

if slice_enabled then
	-- Ensure the generated lists are available (load order is not guaranteed).
	dofile(core.get_modpath(core.get_current_modname()) .. "/generated_slice.lua")

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

	core.register_on_mods_loaded(function()
		-- Hide modern items from the creative inventory and drop their recipes.
		-- Hide by mod prefix (catches dynamically-registered items), plus the
		-- explicitly-listed itemstrings (e.g. modern mob spawn eggs, whose
		-- mod also contains pre-1.13 content). Pre-1.13 items inside modern
		-- mods are kept via MCL_SLICE.keep.
		local prefix_set, keep_set, explicit_set = {}, {}, {}
		for _, prefix in ipairs(MCL_SLICE.mod_prefixes) do
			prefix_set[prefix] = true
		end
		for _, name in ipairs(MCL_SLICE.keep) do
			keep_set[name] = true
		end
		for _, name in ipairs(MCL_SLICE.items) do
			explicit_set[name] = true
		end
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
		core.log("action", "[mcl_slice] hidden " .. hidden
			.. " items, disabled " .. #MCL_SLICE.structures .. " structures")

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
	end)
end
