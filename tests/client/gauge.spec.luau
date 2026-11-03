--!strict
-- Meter rules: clamping, degenerate ranges, and notch rounding for the throttle and brake.

local harness = require("../harness")
local Gauge = require("../../src/client/UI/Gauge")

harness.suite("gauge")

harness.test("fraction is the position within the range, clamped to 0..1", function()
	harness.near(Gauge.fraction(50, 0, 100), 0.5, 1e-9)
	harness.near(Gauge.fraction(150, 0, 100), 1, 1e-9)
	harness.near(Gauge.fraction(-5, 0, 100), 0, 1e-9)
end)

harness.test("fraction reads zero for NaN or a degenerate range, never NaN", function()
	harness.equal(Gauge.fraction(0 / 0, 0, 100), 0)
	harness.equal(Gauge.fraction(5, 10, 10), 0)
	harness.equal(Gauge.fraction(5, 10, 0), 0)
end)

harness.test("notch rounds to the nearest of 0..n", function()
	harness.equal(Gauge.notch(0.06, 8), 0)
	harness.equal(Gauge.notch(0.5, 8), 4)
	harness.equal(Gauge.notch(0.94, 8), 8)
	harness.equal(Gauge.notch(1.7, 8), 8, "over-range clamps to the last notch")
end)

harness.test("notch refuses a non-integer or zero notch count", function()
	harness.raises(function()
		Gauge.notch(0.5, 0)
	end, "whole number")
	harness.raises(function()
		Gauge.notch(0.5, 2.5)
	end, "whole number")
end)
