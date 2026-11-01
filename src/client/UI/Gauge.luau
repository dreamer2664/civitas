--!strict
--[[
	Value-to-fill rules for meters: the throttle and brake notches, the speed bar and the reverser.
	Pure. The Roblox meter component only draws what these functions return.

	Throttle and brake are notched controls in real cabs, so the notch function rounds to the
	nearest notch rather than showing a fraction the driver cannot set.
]]

local Gauge = {}

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Position of `value` between `minV` and `maxV` as 0..1. Out-of-range input is clamped; NaN and
-- a degenerate range read as zero, so an empty meter is shown rather than a broken one.
function Gauge.fraction(value: number, minV: number, maxV: number): number
	if not isFinite(value) or not isFinite(minV) or not isFinite(maxV) or maxV <= minV then
		return 0
	end
	return math.clamp((value - minV) / (maxV - minV), 0, 1)
end

-- Nearest notch in 0..notches for a 0..1 fraction. Notches must be at least 1.
function Gauge.notch(fraction: number, notches: number): number
	assert(notches >= 1 and math.floor(notches) == notches, "notches must be a whole number >= 1")
	if not isFinite(fraction) then
		return 0
	end
	return math.clamp(math.floor(fraction * notches + 0.5), 0, notches)
end

return Gauge
