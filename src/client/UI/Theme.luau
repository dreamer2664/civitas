--!strict
--[[
	Civitas Signal design tokens (see docs/ui/UI-SPEC.md, sections 3–5).

	Pure data plus pure colour maths: no Roblox API, so lune can test the contrast rules the spec
	promises. Conversion to Color3 and Enum.Font happens in UI/Style.luau.

	Why tokens instead of literals: every colour, font, size, space and duration used by a component
	is read from here, so the written spec and the running code cannot drift apart. A component that
	hard-codes a colour is a review rejection.
]]

local Theme = {}

export type Palette = {
	ink: string,
	surface: string,
	raised: string,
	pressed: string,
	hairline: string,
	text: string,
	textMuted: string,
	textFaint: string,
	accent: string,
	accentText: string,
	proceed: string,
	caution: string,
	stop: string,
	sign: string,
	signText: string,
}

export type TypeStyle = {
	face: string,
	size: number,
}

-- Hex strings without '#'. Values were chosen against the contrast table in UI-SPEC §4 and are
-- re-checked by tests/client/theme.spec.luau. Saturation is deliberately low: nothing here is neon.
Theme.palette = {
	ink = "0E1216", -- behind everything; the world shows through only as a dimmed backdrop
	surface = "161C22", -- panels
	raised = "1F262E", -- cards, buttons at rest
	pressed = "29323C", -- pressed and selected rows
	hairline = "3A4550", -- 1 px borders; decorative only, never the sole carrier of meaning
	text = "EEF1F3", -- primary text
	textMuted = "AEB8C1", -- secondary text
	textFaint = "949FA9", -- captions and units
	accent = "5B8DB8", -- platform blue: fills and focus rings only, never text
	accentText = "84ADD2", -- the same blue lightened for text: 4.5:1 or better on every surface
	proceed = "4E9A6B", -- signal green: normal running, on time
	caution = "D9A441", -- signal amber: late, speed restriction ahead
	stop = "D46B5E", -- signal red: emergency, door fault, danger
	sign = "1E3A46", -- station sign panel
	signText = "F3EFE4", -- warm white on sign panels, like enamel signage
} :: Palette

-- Six line colours for the network map. Each line is also identified by its code (a text badge),
-- so colour is never the only signal (WCAG 1.4.1). Badge text is always ink, and every colour
-- keeps ink at 4.5:1 or better and reaches 3:1 against `surface` (tests/client/theme.spec.luau).
-- Brick sits close to `stop`; the map never shows status colours beside lines, see UI-SPEC §8.
Theme.lineColours = {
	teal = "2A9696",
	ochre = "C99A2E",
	plum = "B47BAF",
	slate = "5C8AC8",
	brick = "C46E5E",
	moss = "6F8F3A",
} :: { [string]: string }

-- Typefaces are restricted to Enum.Font members verified against the Roblox API dump. Only the
-- family names are used; weight comes from the family itself, so no Font.new asset paths are needed.
Theme.type = {
	display = { face = "BuilderSansExtraBold", size = 36 } :: TypeStyle, -- main menu wordmark
	title = { face = "BuilderSansBold", size = 24 } :: TypeStyle, -- screen titles
	heading = { face = "BuilderSansMedium", size = 18 } :: TypeStyle,
	body = { face = "BuilderSans", size = 16 } :: TypeStyle,
	label = { face = "BuilderSansMedium", size = 14 } :: TypeStyle, -- buttons, chips
	caption = { face = "BuilderSans", size = 12 } :: TypeStyle, -- smallest permitted text
	sign = { face = "RobotoCondensed", size = 22 } :: TypeStyle, -- station and destination signs
	signLarge = { face = "RobotoCondensed", size = 40 } :: TypeStyle, -- platform numbers
	numXL = { face = "RobotoMono", size = 56 } :: TypeStyle, -- speed readout in the cab
	numL = { face = "RobotoMono", size = 28 } :: TypeStyle,
	numM = { face = "RobotoMono", size = 18 } :: TypeStyle, -- times on departure rows
}

-- 4-point grid. Every value is a multiple of 4; tests enforce it.
Theme.space = {
	s1 = 4,
	s2 = 8,
	s3 = 12,
	s4 = 16,
	s6 = 24,
	s8 = 32,
	s12 = 48,
}

Theme.radius = {
	sign = 2,
	control = 4,
	panel = 6,
}

Theme.size = {
	touchMin = 48, -- smallest tappable control, in pixels, on any device
	touchComfort = 56, -- cab controls and primary actions
	hairline = 1,
	focusRing = 2,
	dot = 12, -- status dot diameter
	minTextSize = 12, -- UITextSizeConstraint floor; Roblox documents values below 9 as unreadable
	maxTextSize = 72,
}

-- Durations in seconds. Motion is client-only (never a server TweenService: that replicates every
-- frame, see docs/RESOURCES.md). Reduced motion sets every duration except `instant` to 0.
export type Motion = {
	instant: number,
	fast: number,
	base: number,
	slow: number,
	easeStyle: string,
	easeDirection: string,
}

Theme.motion = {
	instant = 0,
	fast = 0.12,
	base = 0.2,
	slow = 0.32,
	easeStyle = "Quad",
	easeDirection = "Out",
} :: Motion

-- ---------------------------------------------------------------------------------------------
-- Colour maths. Pure, so the contrast rules can be tested without Roblox.
-- ---------------------------------------------------------------------------------------------

function Theme.rgb(hex: string): (number, number, number)
	if string.match(hex, "^%x%x%x%x%x%x$") == nil then
		error(`Theme colour must be exactly 6 hex digits, got "{hex}"`)
	end
	local r = tonumber(string.sub(hex, 1, 2), 16) :: number
	local g = tonumber(string.sub(hex, 3, 4), 16) :: number
	local b = tonumber(string.sub(hex, 5, 6), 16) :: number
	return r, g, b
end

local function linear(channel: number): number
	-- sRGB transfer function from WCAG 2.x. Channel is 0..255.
	local c = channel / 255
	if c <= 0.03928 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

function Theme.luminance(hex: string): number
	local r, g, b = Theme.rgb(hex)
	return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

-- Elevation is a fill step, not a drop shadow: shadows cost fill-rate on low-end phones and the
-- palette is night-lit (dark ink base, warm text), so depth reads as a lighter surface. Each level
-- must be lighter than the one below it; tests/client/theme.spec.luau checks that order.
Theme.elevation = {
	flat = "surface",
	raised = "raised",
	overlay = "pressed",
} :: { [string]: string }

-- WCAG 2.x contrast ratio, from 1 to 21.
function Theme.contrast(a: string, b: string): number
	local la = Theme.luminance(a)
	local lb = Theme.luminance(b)
	local hi = math.max(la, lb)
	local lo = math.min(la, lb)
	return (hi + 0.05) / (lo + 0.05)
end

return Theme
