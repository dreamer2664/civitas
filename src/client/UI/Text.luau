--!strict
--[[
	Glyph coverage guard. A font that lacks a character draws a box, and nothing in Roblox warns
	about it, so this module checks every string a label is given against the coverage the font
	is declared to have, and fails loudly with the exact characters at fault.

	Pure: code points in, code points out. The Roblox components call it with the ranges from
	FontCoverage.luau. It deliberately knows nothing about fonts, so the same check runs in lune.
]]

local Text = {}

export type Range = { lo: number, hi: number }

local function isCovered(codepoint: number, ranges: { Range }): boolean
	for _, range in ranges do
		if codepoint >= range.lo and codepoint <= range.hi then
			return true
		end
	end
	return false
end

-- Each uncovered character once, as "Ł (U+0141)", in order of first appearance.
function Text.uncovered(s: string, ranges: { Range }): { string }
	if utf8.len(s) == nil then
		error("Text.uncovered: the string is not valid UTF-8, so its characters cannot be checked")
	end
	local missing: { string } = {}
	local seen: { [number]: boolean } = {}
	for _, codepoint in utf8.codes(s) do
		if not seen[codepoint] and not isCovered(codepoint, ranges) then
			seen[codepoint] = true
			table.insert(missing, `{utf8.char(codepoint)} (U+{string.format("%04X", codepoint)})`)
		end
	end
	return missing
end

-- Errors with the label, the characters and the remedy. A rendered box is the failure this stops.
function Text.assertCovered(label: string, s: string, ranges: { Range })
	local missing = Text.uncovered(s, ranges)
	if #missing > 0 then
		error(
			`{label} "{s}" uses characters the font is not declared to cover: {table.concat(
				missing,
				", "
			)}. `
				.. "Either change the text, or, once the glyphs are checked in Studio, add the range to FontCoverage.luau."
		)
	end
end

return Text
