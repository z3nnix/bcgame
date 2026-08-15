local F = core.formspec_escape

-- Luanti (real_coordinates, formspec_version >= 2) renders list items at a
-- pitch of 1.25 form units (16px item, 4px spacing). The baked 18px vanilla
-- slot pitch must be scaled to match that pitch: 18 * P = 1.25 * ITEM_SCALE.
-- ITEM_SCALE shrinks the whole inventory panel (cells get ~25% smaller).
local ITEM_SCALE = 0.75
local P = ITEM_SCALE * 1.25 / 18
-- Item icons are drawn at ITEM_SIZE, 10% smaller than the slot pitch
-- (1.25 * ITEM_SCALE). ITEM_SIZE + ITEM_SPACING must equal the slot pitch
-- so items stay aligned with the baked slots. The hover highlight follows
-- the item size, so it is ~10% smaller than the cell.
local ITEM_SIZE = 1.25 * ITEM_SCALE * 0.9
local ITEM_SPACING = 1.25 * ITEM_SCALE - ITEM_SIZE

mcl_inventory.registered_survival_inventory_tabs = {}

function mcl_inventory.register_survival_inventory_tab(def)
	if #mcl_inventory.registered_survival_inventory_tabs == 7 then
		error("Too many tabs registered!")
	end

	assert(def.id)
	assert(def.description)
	assert(def.item_icon)
	assert(def.build)
	assert(def.handle)

	for _, d in ipairs(mcl_inventory.registered_survival_inventory_tabs) do
		assert(d.id ~= def.id, "Another tab exists with the same name!")
	end

	if not def.access then
		function def.access(_)
			return true
		end
	end

	if def.show_inventory == nil then
		def.show_inventory = true
	end

	table.insert(mcl_inventory.registered_survival_inventory_tabs, def)
end

local player_current_tab = {}

core.register_on_joinplayer(function(player)
	player_current_tab[player] = "main"
end)

core.register_on_leaveplayer(function(player)
	player_current_tab[player] = nil
end)

local function build_page(_, content, inventory, tabname)
	local tab_buttons = "style_type[image;noclip=true]"

	if #mcl_inventory.registered_survival_inventory_tabs ~= 1 then
		for i, d in ipairs(mcl_inventory.registered_survival_inventory_tabs) do
			local btn_name = "tab_" .. d.id

			tab_buttons = tab_buttons .. table.concat({
				"style[" .. btn_name .. ";border=false;bgimg=;bgimg_pressed=;noclip=true]",
				"image[" ..
					(0.2 + (i - 1) * 1.6) ..
					",-1.34;1.5,1.44;" .. (tabname == d.id and "crafting_creative_active.png" or "crafting_creative_inactive.png") ..
					"]",
				"item_image_button[" .. (0.44 + (i - 1) * 1.6) .. ",-1.1;1,1;" .. d.item_icon .. ";" .. btn_name .. ";]",
				"tooltip[" .. btn_name .. ";" .. F(d.description) .. "]"
			})
		end
	end

	return table.concat({
		"formspec_version[6]",
		"size[" .. 176 * P .. "," .. 166 * P .. "]",

		--Vanilla inventory panel background
		"image[0,0;" .. 176 * P .. "," .. 166 * P .. ";mcl_inventory_survival_bg.png]",

		--Shrink list items to match the scaled slot pitch
		"style_type[list;size=" .. ITEM_SIZE .. ";spacing=" .. ITEM_SPACING .. "]",

		--Transparent slot background so the baked panel (frames, armor
		--silhouettes) shows through; hovering lightens the whole cell.
		"listcolors[#00000000;#FFFFFF40]",

		inventory and table.concat({
			--Main inventory
			"list[current_player;main;" .. 8 * P .. "," .. 84 * P .. ";9,3;9]",

			--Hotbar
			"list[current_player;main;" .. 8 * P .. "," .. 142 * P .. ";9,1;]"
		}) or "",

		content,
		tab_buttons,
	})
end

local function get_inventory_formspec(player)
	local inv = player:get_inventory()

	local craft_width = inv:get_width("craft")
	if craft_width == 0 then
		core.log("warning", "[mcl_inventory] craft width for player " .. player:get_player_name() .. " is 0")
		craft_width = 3
	end

	return table.concat({
		--Armor slots
		"list[current_player;armor;" .. 8 * P .. "," .. 8 * P .. ";1,1;1]",
		"list[current_player;armor;" .. 8 * P .. "," .. 26 * P .. ";1,1;2]",
		"list[current_player;armor;" .. 8 * P .. "," .. 44 * P .. ";1,1;3]",
		"list[current_player;armor;" .. 8 * P .. "," .. 62 * P .. ";1,1;4]",

		--Craft grid
		"list[current_player;craft;" .. 88 * P .. "," .. 26 * P .. ";2,1]",
		"list[current_player;craft;" .. 88 * P .. "," .. 44 * P .. ";2,1;", craft_width, "]",

		--Crafting result
		"list[current_player;craftpreview;" .. 144 * P .. "," .. 36 * P .. ";1,1;]",

		--Listring
		"listring[current_player;main]",
		"listring[current_player;sorter]",
		"listring[current_player;main]",
		"listring[current_player;craft]",
		"listring[current_player;main]",
		"listring[current_player;armor]",
		"listring[current_player;main]",

		-- Player model
		mcl_player.get_player_formspec_model(player, 25 * P, 8 * P, 62 * P, 70 * P, "", true, "-10,180"),
	})
end

mcl_inventory.register_survival_inventory_tab({
	id = "main",
	description = "Main Inventory",
	item_icon = "mcl_crafting_table:crafting_table",
	show_inventory = true,
	build = get_inventory_formspec,
	handle = function() end,
})

--[[
mcl_inventory.register_survival_inventory_tab({
	id = "test",
	description = "Test",
	item_icon = "mcl_core:stone",
	show_inventory = true,
	build = function(player)
		return "label[1,1;Hello hello]button[2,2;2,2;Hello;hey]"
	end,
	handle = function(player, fields)
		print(dump(fields))
	end,
})]]

function mcl_inventory.build_survival_formspec(player)
	local tab = player_current_tab[player]

	local tab_def = nil

	for _, d in ipairs(mcl_inventory.registered_survival_inventory_tabs) do
		if tab == d.id then
			tab_def = d
			break
		end
	end
	local form

	if tab_def then
		form = build_page(player, tab_def.build(player), tab_def.show_inventory, tab)
	end

	return form
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "" and #mcl_inventory.registered_survival_inventory_tabs ~= 1 and
		player:get_meta():get_string("gamemode") ~= "creative" then
		for _, d in ipairs(mcl_inventory.registered_survival_inventory_tabs) do
			if fields["tab_" .. d.id] and d.access(player) then
				player_current_tab[player] = d.id
				mcl_inventory.update_inventory(player)
				break
			end
		end

		for _, d in ipairs(mcl_inventory.registered_survival_inventory_tabs) do
			if player_current_tab[player] == d.id and d.access(player) then
				d.handle(player, fields)
				return
			end
		end
	end
end)

local function find_empty_inv_slots(inv)
	local main, hotbar
	for i, stack in pairs(inv:get_list("main")) do
		if i > 9 and not main and stack:is_empty() then
			main = i
		elseif i <= 9 and not hotbar and stack:is_empty() then
			hotbar = i
		end
		if hotbar and main then break end
	end
	return main, hotbar
end

core.register_on_player_inventory_action(function(player, action, inv, info)
	if action == "move" and info.to_list == "sorter" then
		local stack = inv:get_stack(info.to_list, info.to_index)
		local empty_main, empty_hotbar = find_empty_inv_slots(inv)
		if core.get_item_group(stack:get_name(), "armor") > 0 then
			local newstack = mcl_armor.equip(stack, player, true)
			if newstack and not newstack:is_empty() then
				if inv:get_stack(info.from_list, info.from_index):is_empty() then
					inv:set_stack(info.from_list, info.from_index, newstack)
				elseif inv:room_for_item(info.from_list, newstack) then
					inv:add_item(info.from_list, newstack)
				end
			end
		elseif info.from_list == "main" and info.from_index <= 9 and empty_main then --hotbar to inv
			inv:set_stack("main", empty_main, stack)
		elseif info.from_list == "main" and info.from_index > 9 and empty_hotbar then
			inv:set_stack("main", empty_hotbar, stack)
		else
			inv:set_stack(info.from_list, info.from_index, stack)
		end
		inv:set_stack("sorter", 1, ItemStack(""))
	end
end)

core.register_allow_player_inventory_action(function(_, action, inv, info)
	if info.to_list == "sorter" or info.from_list == "sorter" or info.listname == "sorter" then
		if action == "put" or action == "take" then return 0 end
		local stack = inv:get_stack(info.from_list, info.from_index)
		local empty_main, empty_hotbar = find_empty_inv_slots(inv)
		if core.get_item_group(stack:get_name(), "armor") > 0 then
			return 1
		elseif ( info.from_list == "main" and info.from_index <= 9 and empty_main ) or
			( info.from_list == "main" and info.from_index > 9 and empty_hotbar ) then
			return stack:get_count()
		end
		return 0
	end
end)
