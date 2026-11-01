--!strict
-- Glyph coverage guard: real European place names and labels pass, and characters outside the
-- declared coverage fail with the exact character named. Failing loudly is the feature.

local harness = require("../harness")
local Text = require("../../src/client/UI/Text")
local FontCoverage = require("../../src/client/UI/FontCoverage")

harness.suite("text")

local RANGES = FontCoverage.forFace("BuilderSans")

harness.test("plain ASCII and Latin-1 names are covered", function()
	harness.equal(#Text.uncovered("Central Station", RANGES), 0)
	harness.equal(#Text.uncovered("Mühlbach", RANGES), 0)
	harness.equal(#Text.uncovered("Søndergård", RANGES), 0)
	harness.equal(#Text.uncovered("Straße 12, Café Crème", RANGES), 0)
end)

harness.test("Latin Extended characters are reported, each once", function()
	-- Ł (U+0141) and ź (U+017A) are outside the claimed set; ó is Latin-1 and is covered.
	local missing = Text.uncovered("Łódź", RANGES)
	harness.equal(#missing, 2)
	harness.equal(missing[1], "Ł (U+0141)")
	harness.equal(missing[2], "ź (U+017A)")
	harness.equal(
		#Text.uncovered("ŁŁŁ Łódź Łódź", RANGES),
		2,
		"a repeated character counts once"
	)
end)

harness.test("assertCovered errors and names the character and the remedy", function()
	harness.raises(function()
		Text.assertCovered("Station name", "Győr", RANGES)
	end, "U+0151")
	harness.raises(function()
		Text.assertCovered("Station name", "Győr", RANGES)
	end, "FontCoverage.luau")
end)

harness.test("assertCovered passes silently for covered text", function()
	Text.assertCovered("Station name", "Mühlbach", RANGES)
end)

harness.test("invalid UTF-8 is an error, not a silent pass", function()
	harness.raises(function()
		Text.uncovered("\xFF\xFE", RANGES)
	end, "not valid UTF-8")
end)

harness.test("an unknown face gets the claimed set only", function()
	local ranges = FontCoverage.forFace("NotARealFace")
	harness.equal(#Text.uncovered("Łódź", ranges), 2)
end)
