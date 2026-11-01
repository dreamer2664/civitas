--!strict
-- Contrast and token rules from docs/ui/UI-SPEC.md §4 and §5. A change to Theme.luau that breaks
-- one of these is a design decision and must be made in the spec too.

local harness = require("../harness")
local Theme = require("../../src/client/UI/Theme")

local P = Theme.palette

harness.suite("theme")

harness.test("every palette entry is a valid 6-digit hex colour", function()
	for name, hex in P do
		Theme.rgb(hex)
		harness.truthy(name ~= "", "palette key must be named")
	end
end)

harness.test("malformed hex is rejected with a message naming the value", function()
	harness.raises(function()
		Theme.rgb("#12345")
	end, "6 hex digits")
end)

harness.test("contrast: black on white is 21:1 and the ratio is symmetric", function()
	harness.near(Theme.contrast("000000", "FFFFFF"), 21, 0.001)
	harness.near(Theme.contrast("FFFFFF", "000000"), 21, 0.001)
end)

-- Body and caption text on every surface it can sit on must reach WCAG AA (4.5:1).
harness.test("primary, muted and faint text reach 4.5:1 on every surface", function()
	local surfaces = { P.surface, P.raised, P.pressed }
	for _, bg in surfaces do
		for _, fg in { P.text, P.textMuted, P.textFaint } do
			local ratio = Theme.contrast(fg, bg)
			harness.truthy(ratio >= 4.5, `{fg} on {bg} is {ratio}, below 4.5`)
		end
	end
end)

harness.test("sign text on the station sign panel reaches 4.5:1", function()
	harness.truthy(Theme.contrast(P.signText, P.sign) >= 4.5)
end)

-- Button labels are ink on a solid fill. The same fills, used as text on a surface, have their own
-- rule below.
harness.test("ink labels on every solid fill reach 4.5:1", function()
	for _, fill in { P.accent, P.proceed, P.caution, P.stop } do
		local ratio = Theme.contrast(P.ink, fill)
		harness.truthy(ratio >= 4.5, `ink on {fill} is {ratio}, below 4.5`)
	end
end)

-- Solid accent is for fills and focus rings; text in the accent hue uses `accentText`, which is
-- lightened until it clears 4.5:1 on every surface (solid accent measures 4.3:1 on raised).
harness.test("accent text reaches 4.5:1 on every surface", function()
	for _, bg in { P.surface, P.raised, P.pressed } do
		local ratio = Theme.contrast(P.accentText, bg)
		harness.truthy(ratio >= 4.5, `accentText on {bg} is {ratio}, below 4.5`)
	end
end)

harness.test("solid accent is not used as text on raised surfaces", function()
	harness.truthy(Theme.contrast(P.accent, P.raised) < 4.5, "documents why accentText exists")
end)

-- Status and focus colours are non-text graphics (WCAG 1.4.11): 3:1 against the surface.
harness.test("status and focus colours reach 3:1 against the surface", function()
	for _, fill in { P.accent, P.proceed, P.caution, P.stop } do
		local ratio = Theme.contrast(fill, P.surface)
		harness.truthy(ratio >= 3, `{fill} on surface is {ratio}, below 3`)
	end
end)

harness.test("every map line colour reaches 3:1 against the surface", function()
	for name, hex in Theme.lineColours do
		local ratio = Theme.contrast(hex, P.surface)
		harness.truthy(ratio >= 3, `line {name} ({hex}) is {ratio}, below 3`)
	end
end)

harness.test("ink badge text reaches 4.5:1 on every line colour", function()
	for name, hex in Theme.lineColours do
		local ratio = Theme.contrast(P.ink, hex)
		harness.truthy(ratio >= 4.5, `badge text on line {name} ({hex}) is {ratio}, below 4.5`)
	end
end)

harness.test("spacing is a 4-point grid", function()
	for name, value in Theme.space do
		harness.equal(value % 4, 0, `space.{name} = {value} is not a multiple of 4`)
	end
end)

harness.test(
	"type scale respects the minimum text size and uses the verified font names",
	function()
		local verified = {
			BuilderSansExtraBold = true,
			BuilderSansBold = true,
			BuilderSansMedium = true,
			BuilderSans = true,
			RobotoCondensed = true,
			RobotoMono = true,
		}
		for name, style in Theme.type do
			harness.truthy(verified[style.face], `type.{name} uses unverified face '{style.face}'`)
			harness.truthy(style.size >= Theme.size.minTextSize, `type.{name} is below the minimum`)
			harness.truthy(style.size <= Theme.size.maxTextSize, `type.{name} is above the maximum`)
		end
	end
)

harness.test("motion durations are ordered and non-negative", function()
	local m = Theme.motion
	harness.equal(m.instant, 0)
	harness.truthy(m.fast > 0 and m.fast < m.base, "fast must be shorter than base")
	harness.truthy(m.base < m.slow, "base must be shorter than slow")
end)

harness.test("touch minimum is at least 48 px and comfort is larger", function()
	harness.truthy(Theme.size.touchMin >= 48)
	harness.truthy(Theme.size.touchComfort > Theme.size.touchMin)
end)

-- Elevation is depth by fill step. If a higher level were darker than the one below, a raised
-- card would look sunk into its panel, so the order is checked, not assumed.
harness.test("elevation levels get lighter as they rise", function()
	local flat = Theme.luminance(Theme.palette[Theme.elevation.flat])
	local raised = Theme.luminance(Theme.palette[Theme.elevation.raised])
	local overlay = Theme.luminance(Theme.palette[Theme.elevation.overlay])
	harness.truthy(flat < raised, "raised must be lighter than flat")
	harness.truthy(raised < overlay, "overlay must be lighter than raised")
end)

-- The button looks are pairs of fill and label. Each pair must meet the text rule, otherwise a
-- primary or danger button would be unreadable in the cab.
harness.test("button label colours reach 4.5:1 on their fills", function()
	local pairs_ = {
		{ "ink", "accent", "primary" },
		{ "text", "raised", "secondary" },
		{ "ink", "stop", "danger" },
	}
	for _, pair in pairs_ do
		local ratio = Theme.contrast(Theme.palette[pair[1]], Theme.palette[pair[2]])
		harness.truthy(ratio >= 4.5, `{pair[3]} button label is {ratio} on its fill`)
	end
end)
