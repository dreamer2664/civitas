--!strict
--[[
	Divider: a 1 px hairline between groups. Decorative only; it never carries meaning on its own.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)

local Divider = {}

export type Options = {
	name: string?,
	vertical: boolean?,
}

function Divider.new(options: Options?): Frame
	local vertical = if options then options.vertical == true else false
	local frame = Instance.new("Frame")
	frame.Name = if options and options.name then options.name else "Divider"
	frame.BackgroundColor3 = Style.color("hairline")
	frame.BorderSizePixel = 0
	if vertical then
		frame.Size = UDim2.new(0, Theme.size.hairline, 1, 0)
	else
		frame.Size = UDim2.new(1, 0, 0, Theme.size.hairline)
	end
	return frame
end

return Divider
