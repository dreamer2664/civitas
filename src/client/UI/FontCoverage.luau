--!strict
--[[
	Declared glyph coverage for each font face the UI uses. Read by UI/Text.luau.

	STATUS: CLAIMED, NOT MEASURED. Roblox documents the Font enum names but publishes no glyph
	coverage for BuilderSans or Roboto, and nothing in the sandbox can render them. So the claim
	below is the conservative set every modern European UI font is expected to cover: Basic Latin
	and Latin-1 Supplement, which carries ä ö ü ß é è à ç ñ ø å æ. Anything beyond it, such as
	Ł, ő, ş or ą, fails the guard until it is added.

	To extend a face: render the new characters in Studio on a TextLabel with that face, confirm
	no box appears, then add the range to `extra` with a comment saying when and by whom it was
	checked. Nothing is added speculatively.
]]

local FontCoverage = {}

export type Range = { lo: number, hi: number }

-- Basic Latin (space to tilde) and Latin-1 Supplement (no-break space to ÿ).
local CLAIMED: { Range } = {
	{ lo = 0x20, hi = 0x7E },
	{ lo = 0xA0, hi = 0xFF },
}

-- Added after a Studio check. Empty until one is made.
local extra: { [string]: { Range } } = {}

-- Ranges for a face name as used in Theme.type (for example "BuilderSans"). Unknown faces get the
-- claimed set only, so a new face cannot silently gain coverage.
function FontCoverage.forFace(face: string): { Range }
	local ranges: { Range } = table.clone(CLAIMED)
	local added: { Range } = extra[face] or {}
	for _, range in added do
		table.insert(ranges, range)
	end
	return ranges
end

FontCoverage.claimed = CLAIMED

return FontCoverage
