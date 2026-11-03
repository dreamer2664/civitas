--!strict
--[[
	Meter: a row of notches for throttle, brake and similar notched controls. Lit notches show the
	level; the numeric readout beside it carries the exact value. Colour is never the only
	signal: a lit notch is also a filled block, and the caller prints the number.

	The fill rule lives in Gauge.luau (pure, tested). This file only draws it.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Gauge = require(script.Parent.Parent.Gauge)

local Meter = {}

export type Tone = "proceed" | "caution" | "stop" | "accent"
export type Meter = {
	frame: Frame,
	segments: { Frame },
	notches: number,
}

-- Creates `notches` blocks laid out left to right. Each block is a separate Frame, so the meter
-- costs `notches` draw calls; keep notch counts small (the cab uses 8).
function Meter.new(notches: number, width: number, height: number): Meter
	assert(notches >= 1, "a meter needs at least one notch")
	local frame = Instance.new("Frame")
	frame.Name = "Meter"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(width, height)

	local gap = Theme.space.s1
	local blockW = (width - (notches - 1) * gap) / notches
	local segments: { Frame } = {}
	for i = 1, notches do
		local block = Instance.new("Frame")
		block.Name = `Notch{i}`
		block.BorderSizePixel = 0
		block.BackgroundColor3 = Style.color("pressed")
		block.Position = UDim2.fromOffset((i - 1) * (blockW + gap), 0)
		block.Size = UDim2.fromOffset(blockW, height)
		block.Parent = frame
		table.insert(segments, block)
	end
	return { frame = frame, segments = segments, notches = notches }
end

-- Lights the blocks up to the notch nearest to `value`, in the given tone.
function Meter.set(meter: Meter, value: number, minV: number, maxV: number, tone: Tone)
	local level = Gauge.notch(Gauge.fraction(value, minV, maxV), meter.notches)
	local lit = Style.color(tone)
	for i, block in meter.segments do
		block.BackgroundColor3 = if i <= level then lit else Style.color("pressed")
	end
end

return Meter
