--!strict
--[[
	Panel: a surface container. Raised fill, 6 px corners and a 1 px hairline edge. Panels carry no
	behaviour; they only group controls and text. Depth comes from the fill step between surface
	and raised, not from drop shadows, which cost fill-rate on low-end phones.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)

local Panel = {}

export type Options = {
	name: string?,
	elevation: Style.Elevation?,
}

function Panel.new(options: Options?): Frame
	local frame = Instance.new("Frame")
	frame.Name = if options and options.name then options.name else "Panel"
	frame.BorderSizePixel = 0
	local level: Style.Elevation = if options and options.elevation
		then options.elevation
		else "flat"
	frame.BackgroundColor3 = Style.elevation(level)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.radius.panel)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Style.color("hairline")
	stroke.Thickness = Theme.size.hairline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame

	return frame
end

return Panel
