--!strict
local harness = require("../harness")
local LabelLayout = require("../../src/client/UI/Map/LabelLayout")

harness.suite("map label layout")
harness.test("overlapping and clipped labels are suppressed", function()
	local accepted: { LabelLayout.Rect } = {}
	harness.truthy(LabelLayout.accept({ x = 10, y = 10, w = 60, h = 18 }, accepted, 150, 100))
	harness.falsy(LabelLayout.accept({ x = 60, y = 12, w = 40, h = 18 }, accepted, 150, 100))
	harness.falsy(LabelLayout.accept({ x = 140, y = 40, w = 30, h = 18 }, accepted, 150, 100))
	harness.truthy(LabelLayout.accept({ x = 10, y = 28, w = 60, h = 18 }, accepted, 150, 100))
	harness.equal(#accepted, 2)
end)

harness.test("layout can reveal a previously hidden label after zoom", function()
	local initial: { LabelLayout.Rect } = {}
	harness.truthy(LabelLayout.accept({ x = 10, y = 10, w = 50, h = 18 }, initial, 300, 200))
	harness.falsy(LabelLayout.accept({ x = 50, y = 10, w = 50, h = 18 }, initial, 300, 200))
	local zoomed: { LabelLayout.Rect } = {}
	harness.truthy(LabelLayout.accept({ x = 10, y = 10, w = 50, h = 18 }, zoomed, 300, 200))
	harness.truthy(LabelLayout.accept({ x = 90, y = 10, w = 50, h = 18 }, zoomed, 300, 200))
end)
