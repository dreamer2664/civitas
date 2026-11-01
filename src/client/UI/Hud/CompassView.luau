--!strict
--[[
	Compass strip: a horizontal band across the top of the screen showing the headings near the
	player's heading. Positions come from Compass.offsetX with a width of 1, so each mark is placed as
	a fraction of the strip, and the strip works at any screen size. The heading is an input from the
	caller (the camera), not something this module reads.
]]

local Compass = require(script.Parent.Compass)
local Style = require(script.Parent.Parent.Style)
local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)
local Label = require(script.Parent.Parent.Components.Label)

local CompassView = {}

export type View = {
	root: Frame,
	setHeading: (degrees: number) -> (),
	destroy: () -> (),
}

-- How many degrees the strip shows across its whole width.
local SPAN = 90
local TICK_EVERY = 15

-- One mark is a label or a tick, at a fixed bearing. Marks outside the window are hidden.
type Mark = { bearing: number, gui: GuiObject }

function CompassView.new(parent: GuiObject): View
	local root = Panel.new({ name = "Compass", elevation = "raised" })
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, Theme.space.s4)
	root.Size = UDim2.new(0.6, 0, 0, Theme.size.dot * 2 + Theme.space.s3)
	root.Parent = parent

	local marks: { Mark } = {}
	-- A parameter, not a table field: Luau checks table fields exactly, which rejects a TextLabel as a GuiObject.
	local function addMark(bearing: number, gui: GuiObject)
		table.insert(marks, { bearing = bearing, gui = gui })
	end
	for _, cardinal in Compass.cardinals do
		local label = Label.new({
			name = `Cardinal{cardinal.text}`,
			text = cardinal.text,
			type = "label",
			color = "text",
			align = "center",
		})
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Parent = root
		addMark(cardinal.bearing, label)
	end
	for bearing = 0, 359, TICK_EVERY do
		local isCardinal = bearing % 90 == 0
		if not isCardinal then
			local tick = Instance.new("Frame")
			tick.Name = `Tick{bearing}`
			tick.AnchorPoint = Vector2.new(0.5, 1)
			tick.Position = UDim2.fromScale(0.5, 1)
			tick.Size = UDim2.fromOffset(1, Theme.space.s2)
			tick.BackgroundColor3 = Style.color("textMuted")
			tick.BorderSizePixel = 0
			tick.Parent = root
			addMark(bearing, tick)
		end
	end

	local function setHeading(degrees: number)
		for _, mark in marks do
			local x = Compass.offsetX(degrees, mark.bearing, 1, SPAN)
			if x == nil then
				mark.gui.Visible = false
			else
				mark.gui.Visible = true
				mark.gui.Position = UDim2.fromScale(0.5 + x, mark.gui.Position.Y.Scale)
			end
		end
	end

	setHeading(0)

	return {
		root = root,
		setHeading = setHeading,
		destroy = function()
			root:Destroy()
		end,
	}
end

return CompassView
