--!strict
--[[
	Compass strip maths. Pure: numbers in, numbers out, no requires, so lune tests every rule.

	The strip shows a window of headings centred on the player's heading. A bearing (north is 0,
	clockwise positive, as in a real compass) maps to a horizontal pixel offset from the strip's
	centre, or nil when it is outside the visible window. The window wraps at 360 degrees, so a
	heading of 350 still shows a bearing of 10 just to its right.
]]

local Compass = {}

-- Normalises an angle to [-180, 180). Lua's % is floored, so this is correct for negative input.
function Compass.wrap(degrees: number): number
	return (degrees + 180) % 360 - 180
end

-- Horizontal offset in pixels from the strip centre, or nil if the bearing is outside the window.
-- `span` is the number of degrees the strip shows across its full width.
function Compass.offsetX(heading: number, bearing: number, width: number, span: number): number?
	assert(width > 0 and span > 0, "compass needs a positive width and span")
	local relative = Compass.wrap(bearing - heading)
	local half = span / 2
	if math.abs(relative) > half then
		return nil
	end
	return relative / half * (width / 2)
end

-- Cardinal and intercardinal marks. Shown as letters; minor ticks are drawn every 15 degrees.
Compass.cardinals = {
	{ bearing = 0, text = "N" },
	{ bearing = 90, text = "E" },
	{ bearing = 180, text = "S" },
	{ bearing = 270, text = "W" },
}

return Compass
