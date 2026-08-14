local modpath = core.get_modpath(core.get_current_modname())
local utf8 = mcl_util.utf8

-- data parsed from UCD CaseFolding.txt
-- * index by codepoint
-- * output is either a codepoint (C) or a pre-baked string (F)
local casefold_data = dofile(modpath .. "/casefold_data.lua")

local function fold_codepoint(code)
	-- Basic Latin (ASCII), Latin-1 Supplement
	if (code >= 0x41 and code <= 0x5A) or
			(code >= 0xC0 and code <= 0xD6) or
			(code >= 0xD8 and code <= 0xDE) then
		return code + 0x20
	end

	-- Latin Extended-A
	if code >= 0x0100 and code <= 0x012E and code % 2 == 0 then
		return code + 1
	end

	-- Greek and Coptic
	if (code >= 0x0391 and code <= 0x03A1) or -- (0x03A2 is missing)
			(code >= 0x03A3 and code <= 0x03A9) then
		return code + 0x20
	end

	-- Cyrillic
	if code >= 0x0410 and code <= 0x042F then
		return code + 0x20
	end
	if code >= 0x0400 and code <= 0x040F then
		return code + 0x50
	end

	local entry = casefold_data[code]
	if entry then return entry end

	return code
end

function mcl_util.casefold(str)
	local out = {}
	for _, code in utf8.codes(str) do
		local folded = fold_codepoint(code)
		if type(folded) == "string" then
			table.insert(out, folded)
		else
			table.insert(out, utf8.char(folded))
		end
	end
	return table.concat(out)
end
