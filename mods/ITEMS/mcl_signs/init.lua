mcl_signs = {}

local modname = core.get_current_modname()

local S = core.get_translator(modname)
local modpath = core.get_modpath(modname)

-- UTF-8 library from modlib
local utf8 = mcl_util.utf8

-- Character map (see API.md for reference)
local charmap = {}
for line in io.lines(modpath .. DIR_DELIM .. "characters.tsv") do
	local split = line:split("\t")
	if #split == 3 then
		local char, img, _ = split[1], split[2], split[3] -- 3rd is ignored, reserved for width
		local code = utf8.codepoint(char)
		charmap[code] = img
	end
end

local signs_editable = core.settings:get_bool("mcl_signs_editable", false)

local SIGN_WIDTH = 115

local LINE_LENGTH = 15
local NUMBER_OF_LINES = 4

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5

local SIGN_GLOW_INTENSITY = 14

local NEWLINE = {
	[0x000A] = true,
	[0x000B] = true,
	[0x000C] = true,
	-- U+000D (CR) is dropped on U-string conversion
	[0x0085] = true,
	[0x2028] = true,
	[0x2029] = true,
}

local WHITESPACE = {
	[0x0009] = true,
	[0x0020] = true,
	-- U+00A0 is a whitespace, but a non-breaking one
	[0x1680] = true,
	[0x2000] = true,
	[0x2001] = true,
	[0x2002] = true,
	[0x2003] = true,
	[0x2004] = true,
	[0x2005] = true,
	[0x2006] = true,
	-- U+2007 is a whitespace, but a non-breaking one
	[0x2008] = true,
	[0x2009] = true,
	[0x200A] = true,
	-- U+202F is a whitespace, but a non-breaking one
	[0x205F] = true,
	[0x3000] = true,
}

local HYPHEN = {
	[0x002D] = true,
	[0x00AD] = true,
	[0x058A] = true,
	[0x05BE] = true,
	[0x1806] = true,
	[0x2010] = true,
	-- U+2011 is a hyphen, but a non-breaking one
	[0x2E17] = true,
	[0x2E5D] = true,
	[0x30FB] = true,
	[0xFE63] = true,
	[0xFF0D] = true,
	[0xFF65] = true,
}

local CR_CODEPOINT = utf8.codepoint("\r") -- ignored
local WRAP_CODEPOINT = utf8.codepoint("‐") -- default, ellipsis for "truncate"

local DEFAULT_COLOR = "#000000"

local F = core.formspec_escape

-- Template definition
local sign_tpl = {
	_tt_help = S("Can be written"),
	_doc_items_longdesc = S("Signs can be written and come in two variants: Wall sign and sign on a sign post. Signs can be placed on the top and the sides of other blocks, but not below them."),
	_doc_items_usagehelp = S("After placing the sign, you can write something on it. You have @1 lines of text with up to @2 characters for each line; anything beyond these limits is lost. Not all characters are supported. The text can be changed after it's written by rightclicking the sign. Can be colored and made to glow. Use bone meal to remove color and glow.", NUMBER_OF_LINES, LINE_LENGTH),
	use_texture_alpha = "opaque",
	sunlight_propagates = true,
	walkable = false,
	is_ground_content = false,
	paramtype2 = "degrotate",
	drawtype = "mesh",
	mesh = "mcl_signs_sign.obj",
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = {-0.2, -0.5, -0.2, 0.2, 0.5, 0.2}
	},
	groups = {axey = 1, handy = 2, sign = 1, supported_node = 1, not_in_creative_inventory = 1, breaking_cactus = 1},
	stack_max = 16,
	sounds = mcl_sounds.node_sound_wood_defaults(),
	node_placement_prediction = "",
	on_rotate = false,
	_mcl_sign_type = "standing"
}

-- Signs data / meta
local function normalize_rotation(rot)
	return math.floor(0.5 + rot / 15) * 15
end

local function get_signdata(pos)
	local node = core.get_node(pos)
	local def = core.registered_nodes[node.name]
	if not def or core.get_item_group(node.name, "sign") < 1 then return end

	local meta = core.get_meta(pos)
	local text = core.deserialize(meta:get_string("utext"), true) or {}
	local color = meta:get_string("color")
	if color == "" then
		color = DEFAULT_COLOR
	end
	local glow = core.is_yes(meta:get_string("glow"))

	local yaw, spos
	local typ = "standing"
	if def.paramtype2  == "wallmounted" then
		typ = "wall"
		local dir = core.wallmounted_to_dir(node.param2)
		spos = vector.add(vector.offset(pos, 0, -0.25, 0), dir * 0.41)
		yaw = core.dir_to_yaw(dir)
	elseif def.paramtype2 == "4dir" then
		typ = "hanging"
		local dir = core.fourdir_to_dir (node.param2)
		spos = vector.add (vector.offset (pos,0,-0.45,0), dir * -0.075)
		yaw = core.dir_to_yaw (dir)
	elseif def.groups.hanging_sign and def.groups.hanging_sign >= 1 then
		yaw = math.rad(((node.param2 * 1.5 ) + 1 ) % 360)
		local dir = core.yaw_to_dir(yaw)
		spos = vector.add(vector.offset(pos,0,-0.45,0),dir * -0.075)
	else
		yaw = math.rad(((node.param2 * 1.5) + 1) % 360)
		local dir = core.yaw_to_dir(yaw)
		spos = vector.add(vector.offset(pos, 0, 0.08, 0), dir * -0.05)
	end

	return {
		text = text,
		color = color,
		yaw = yaw,
		node = node,
		typ = typ,
		glow = glow,
		text_pos = spos,
	}
end

local function set_signmeta(pos, tbl)
	local meta = core.get_meta(pos)
	if tbl.text then meta:set_string("utext", core.serialize(tbl.text)) end
	if tbl.color then meta:set_string("color", tbl.color) end
	if tbl.glow then meta:set_string("glow", tbl.glow) end
end

-- Text processing
function mcl_signs.string_to_ustring(str, max_characters)
	-- limit saved text to 256 characters by default
	-- (4 lines x 15 chars = 60 so this should be more than is ever needed)
	max_characters = max_characters or 256

	local ustr = {}

	for i, code in utf8.codes(str) do
		if i >= max_characters or code == CR_CODEPOINT then
			break
		end
		table.insert(ustr, code)
	end

	return ustr
end

local function ustring_to_string(ustr)
	local str = ""
	for _, code in ipairs(ustr) do
		str = str .. utf8.char(code)
	end
	return str
end

-- TODO: make shared code as table.slice()?
local function subseq(ustr, s, e)
	local line = {}
	for i = s, e do
		line[#line+1] = ustr[i]
	end
	return line
end

local function ustring_to_line_array(ustr)
	local lines = {}
	local start, stop = 1, 1

	for cursor, code in ipairs(ustr) do
		if #lines >= NUMBER_OF_LINES then break end

		if WHITESPACE[code] or HYPHEN[code] then
			stop = cursor
		elseif NEWLINE[code] then
			table.insert(lines, subseq(ustr, start, cursor - 1))
			start, stop = cursor + 1, cursor + 1
		elseif cursor - start + 1 >= LINE_LENGTH then
			if stop <= start then -- forced break, no space in word
				local line = subseq(ustr, start, cursor)
				table.insert(line, WRAP_CODEPOINT)
				table.insert(lines, line)
				start, stop = cursor + 1, cursor + 1
			else
				table.insert(lines, subseq(ustr, start, stop + (HYPHEN[ustr[stop]] and 0 or -1)))
				start, stop = stop + 1, stop + 1
			end
		end
	end
	if #lines < NUMBER_OF_LINES and start <= #ustr then
		table.insert(lines, subseq(ustr, start, #ustr))
	end

	return lines
end

local function generate_line(ustr, ypos)
	local parsed = {}
	local width = 0
	local printed_char_width = CHAR_WIDTH + 1

	for _, code in ipairs(ustr) do
		local file = "_rc"
		if charmap[code] then file = charmap[code] end

		width = width + printed_char_width
		table.insert(parsed, file)
	end

	width = width - 1
	local texture = ""
	local xpos = math.floor((SIGN_WIDTH - width) / 2) -- center with X offset

	for _, file in ipairs(parsed) do
		texture = texture .. ":" .. xpos .. "," .. ypos .. "=" .. file.. ".png"
		xpos = xpos + printed_char_width
	end
	return texture
end

local function generate_texture(data)
	local lines = ustring_to_line_array(data.text)
	local texture = "[combine:" .. SIGN_WIDTH .. "x" .. SIGN_WIDTH
	local ypos = 0
	local letter_color = data.color or DEFAULT_COLOR

	for _, line in ipairs(lines) do
		texture = texture .. generate_line(line, ypos)
		ypos = ypos + LINE_HEIGHT
	end

	texture = "(" .. texture .. "^[multiply:" .. letter_color .. ")"
	return texture
end

-- Text entity handling
function mcl_signs.get_text_entity(pos, force_remove)
	local objects = core.get_objects_inside_radius(pos, 0.5)
	local text_entity
	local i = 0
	for _, v in pairs(objects) do
		local ent = v:get_luaentity()
		if ent and ent.name == "mcl_signs:text" then
			i = i + 1
			if i > 1 or force_remove == true then
				v:remove()
			else
				text_entity = v
			end
		end
	end
	return text_entity
end

-- Update the sign text entity (create if doesn't exist)
function mcl_signs.update_sign(pos)
	local data = get_signdata(pos)

	local text_entity = mcl_signs.get_text_entity(pos)
	if text_entity and not data then
		text_entity:remove()
		return false
	elseif not data then
		return false
	elseif not text_entity then
		text_entity = core.add_entity(data.text_pos, "mcl_signs:text")
		if not text_entity or not text_entity:get_pos() then return end
	end

	text_entity:set_properties({
		textures = {generate_texture(data)},
		glow = data.glow and SIGN_GLOW_INTENSITY or 0,
	})
	text_entity:set_yaw(data.yaw)
	text_entity:set_armor_groups({immortal = 1})
	return true
end

core.register_lbm({
	name = "mcl_signs:restore_entities",
	nodenames = {"group:sign"},
	label = "Restore sign text",
	run_at_every_load = true,
	action = mcl_signs.update_sign,
})

-- Text entity definition
core.register_entity("mcl_signs:text", {
	initial_properties = {
		pointable = false,
		visual = "upright_sprite",
		physical = false,
		collide_with_objects = false,
	},
	on_activate = function(self)
		local pos = self.object:get_pos()
		mcl_signs.update_sign(pos)
		local props = self.object:get_properties()
		local t = props and props.textures
		if type(t) ~= "table" or #t == 0 then self.object:remove() end
	end,
})

-- Formspec
local function show_formspec(player, pos)
	if not pos then return end
	local meta = core.get_meta(pos)
	local old_text = ustring_to_string(core.deserialize(meta:get_string("utext"), true) or {})
	local fs = {
		"size[6,3]textarea[0.25,0.25;6,1.5;text;",
		F(S("Enter sign text:")), ";", F(old_text), "]",
		"label[0,1.5;",
			F(S("Maximum line length: @1", LINE_LENGTH)), "\n",
			F(S("Maximum lines: @1", NUMBER_OF_LINES)),
		"]",
		"button_exit[0,2.4;6,1;submit;", F(S("Done")), "]"
	}
	core.show_formspec(player:get_player_name(), "mcl_signs:set_text_"..pos.x.."_"..pos.y.."_"..pos.z, table.concat(fs))
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname:find("mcl_signs:set_text_") == 1 then
		local x, y, z = formname:match("mcl_signs:set_text_(.-)_(.-)_(.*)")
		local pos = vector.new(tonumber(x), tonumber(y), tonumber(z))
		if not fields or not fields.text then return end
		if not mcl_util.check_position_protection(pos, player) and (signs_editable or core.get_meta(pos):get_string("text") == "") then
			local utext = mcl_signs.string_to_ustring(fields.text)
			set_signmeta(pos, {text = utext})
			mcl_signs.update_sign(pos)
		end
	end
end)

local unlimited_player_transfer_distance = core.settings:get_bool("unlimited_player_transfer_distance", true)
local player_transfer_distance = unlimited_player_transfer_distance and 0 or tonumber(core.settings:get("player_transfer_distance")) or 0
local mcl_hand_range_creative = tonumber(core.settings:get("mcl_hand_range_creative")) or 10
local max_close_formspec_range = math.min(mcl_hand_range_creative + 1, player_transfer_distance > 0 and player_transfer_distance or math.huge)

function mcl_signs.close_formspec(pos)
	for player in mcl_util.connected_players(pos, max_close_formspec_range) do
		core.close_formspec(player:get_player_name(),
			"mcl_signs:set_text_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z)
	end
end

local function project_placer_dir (axis, placer_dir)
	local axis_1 = vector.normalize (vector.new (axis.z, 0, axis.x))
	local dot = vector.dot (axis_1, placer_dir)
	return vector.multiply (axis_1, dot ~= 0.0 and dot or 1.0)
end

local FULL_BLOCK = mcl_util.decompose_AABBs ({
	{
		-0.5, -0.5, -0.5,
		0.5, 0.5, 0.5,
	},
})

-- Node definition callbacks
function sign_tpl.on_place(itemstack, placer, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if rc then return rc end

	local under = pointed_thing.under
	local above = pointed_thing.above
	local dir = vector.subtract(under, above)
	local wdir = core.dir_to_wallmounted(dir)

	-- Signs can be attached to walkable nodes and other signs.
	local node = core.get_node(under)
	local ndef = core.registered_nodes[node.name]

	-- If pointed at node is buildable_to we instead check node behind
	-- (which is the node core.item_place_node will attach the sign to).
	if ndef and ndef.buildable_to then
		under = vector.add(under, dir)
		node = core.get_node(under)
		ndef = core.registered_nodes[node.name]
	end

	if not ndef or (not ndef.walkable and core.get_item_group(node.name, "sign") == 0) then
		return itemstack
	end

	local itemstring = itemstack:get_name()
	local def = itemstack:get_definition()

	local pos
	local placestack = ItemStack(itemstack)
	if core.get_item_group (itemstring, "hanging_sign") == 0 then
		if wdir < 1 then
			-- no placement on ceilings allowed yet
			return itemstack
		elseif wdir == 1 then
			placestack:set_name("mcl_signs:standing_sign_"..def._mcl_sign_wood)
			-- param2 value is degrees / 1.5
			local rot = normalize_rotation(placer:get_look_horizontal() * 180 / math.pi / 1.5)
			itemstack, pos = core.item_place_node(placestack, placer, pointed_thing, rot)
		else
			placestack:set_name("mcl_signs:wall_sign_"..def._mcl_sign_wood)
			itemstack, pos = core.item_place_node(placestack, placer, pointed_thing, wdir)
		end
	else
		-- Hanging sign.
		if wdir == 0 then
			if not ndef.walkable then
				return itemstack
			end

			local boxes = core.get_node_boxes ("collision_box", under)
			local shape = mcl_util.decompose_AABBs (boxes)
			if not shape then
				return itemstack
			end
			local face = shape:select_face ("y", -0.5)
			if face:equal_p (FULL_BLOCK) then
				local dir = vector.subtract (above, placer:get_pos ())
				local fourdir = core.dir_to_fourdir (dir)
				placestack:set_name ("mcl_signs:hanging_sign_" .. def._mcl_sign_wood)
				itemstack, pos = core.item_place_node (placestack, placer, pointed_thing,
								       fourdir)
			else
				local rot = normalize_rotation(placer:get_look_horizontal() * 180 / math.pi / 1.5)
				placestack:set_name ("mcl_signs:hanging_sign_attached_" .. def._mcl_sign_wood)
				itemstack, pos = core.item_place_node (placestack, placer, pointed_thing, rot)
			end
		elseif wdir ~= 1 then
			local placer_dir = vector.subtract (above, placer:get_pos ())
			local dir = project_placer_dir (dir, vector.normalize (placer_dir))
			local fourdir = core.dir_to_fourdir (dir)
			placestack:set_name ("mcl_signs:hanging_sign_wall_" .. def._mcl_sign_wood)
			itemstack, pos = core.item_place_node (placestack, placer, pointed_thing,
							       fourdir)
		else
			return itemstack
		end
	end

	show_formspec(placer, pos)
	-- restore canonical name as core.item_place_node might have changed it
	itemstack:set_name(itemstring)
	return itemstack
end


function sign_tpl.on_rightclick(pos, _, clicker, itemstack, _)
	if itemstack:get_name() == "mcl_mobitems:glow_ink_sac" then
		local data = get_signdata(pos)
		if data then
			if data.color == "#000000" then
				data.color = "#7e7e7e" --black doesn't glow in the dark
			end
			set_signmeta(pos,{glow="true",color=data.color})
			mcl_signs.update_sign(pos)
			if not core.is_creative_enabled(clicker:get_player_name()) then
				itemstack:take_item()
			end
		end
	elseif signs_editable then
		if not mcl_util.check_position_protection(pos, clicker) then
			show_formspec(clicker, pos)
		end
	end
	return itemstack
end

function sign_tpl.on_destruct(pos)
	mcl_signs.get_text_entity(pos, true)
	mcl_signs.close_formspec(pos)
end

function sign_tpl._on_dye_place(pos,color)
	set_signmeta(pos,{
		color = mcl_dyes.colors[color].rgb
	})
	mcl_signs.update_sign(pos)
end

-- Wall sign definition
local sign_wall = table.merge(sign_tpl, {
	mesh = "mcl_signs_signonwallmount.obj",
	paramtype2 = "wallmounted",
	selection_box = {
		type = "wallmounted",
		wall_side = {-0.5, -7/28, -0.5, -23/56, 7/28, 0.5}
	},
	groups = {axey = 1, handy = 2, sign = 1, supported_node_wallmounted = 1, deco_block = 1, breaking_cactus = 1},
	_mcl_sign_type = "wall",
})

local function colored_texture(texture, color)
	return texture.."^[multiply:"..color
end

function mcl_signs.register_sign(name, color, def)
	local newfields = {
		tiles = {colored_texture("mcl_signs_sign_greyscale.png", color)},
		inventory_image = colored_texture("mcl_signs_default_sign_greyscale.png", color),
		wield_image = colored_texture("mcl_signs_default_sign_greyscale.png", color),
		drop = "mcl_signs:wall_sign_"..name,
		_mcl_sign_wood = name,
	}

	def = def or {}
	core.register_node(":mcl_signs:standing_sign_"..name, table.merge(sign_tpl, newfields, def))
	core.register_node(":mcl_signs:wall_sign_"..name, table.merge(sign_wall, newfields, def))
end

local sign_hanging = table.merge(sign_tpl,{
	mesh = "mcl_signs_sign_hanging.obj",
	tiles = { "mcl_signs_sign_hanging.png" },
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	selection_box = {
		type = "fixed",
		fixed = {
			-0.4375,
			-0.5,
			-0.0625,
			0.4375,
			0.125,
			0.0625,
		},
	},
	groups = {
		axey = 1, handy = 2, sign = 1, hanging_sign = 1,
		attached_node = 4, deco_block = 1, breaking_cactus = 1,
	},
	_mcl_sign_type = "hanging",
})

local sign_hanging_wall = table.merge(sign_tpl,{
	mesh = "mcl_signs_sign_hanging_wall.obj",
	tiles = { "mcl_signs_sign_hanging_wall.png" },
	paramtype2 = "4dir",
	use_texture_alpha = "clip",
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = {
			{
				-0.4375,
				-0.5,
				-0.0625,
				0.4375,
				0.125,
				0.0625,
			},
			{
				-0.5,
				0.375,
				-0.125,
				0.5,
				0.5,
				0.125,
			},
		},
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{
				-0.5,
				0.375,
				-0.125,
				0.5,
				0.5,
				0.125,
			},
		},
	},
	groups = {
		axey = 1, handy = 2,
		sign = 1, hanging_sign = 1,
		not_in_creative_inventory = 1,
	},
	_mcl_sign_type = "hanging",
})

local sign_hanging_attached = table.merge (sign_tpl, {
	mesh = "mcl_signs_sign_hanging_attached.obj",
	tiles = { "mcl_signs_sign_hanging_wall.png" },
	paramtype2 = "degrotate",
	use_texture_alpha = "clip",
	selection_box = {
		type = "fixed",
		fixed = {
			{
				-0.4375,
				-0.5,
				-0.4375,
				0.4375,
				0.125,
				0.4375,
			},
		},
	},
	groups = {
		axey = 1, handy = 2, sign = 1, hanging_sign = 1,
		attached_node = 4, not_in_creative_inventory = 1,
	},
})


function mcl_signs.register_hanging_sign (name, def)
	local newfields = {
		inventory_image = "mcl_signs_hanging_sign_" .. name .. "_item.png",
		wield_image = "mcl_signs_hanging_sign_" .. name .. "_item.png",
		drop = "mcl_signs:hanging_sign_" .. name,
		_mcl_sign_wood = name,
	}
	core.register_node(":mcl_signs:hanging_sign_"..name,table.merge(sign_hanging, newfields, {
		tiles = {
			"mcl_signs_hanging_sign_" .. name .. ".png",
		},
	}, def or {}))
	core.register_node(":mcl_signs:hanging_sign_wall_"..name,table.merge(sign_hanging_wall, newfields, {
		tiles = {
			"mcl_signs_hanging_sign_" .. name .. ".png",
		},
	}, def or {}))
	core.register_node(":mcl_signs:hanging_sign_attached_"..name,table.merge(sign_hanging_attached, newfields, {
		tiles = {
			"mcl_signs_hanging_sign_" .. name .. ".png",
		},
	}, def or {}))
end
