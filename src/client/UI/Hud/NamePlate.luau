--!strict
--[[
	Name plate: a short raised label at a screen position the caller computed. It serves stations
	and people. The caller projects a world position onto the screen. This module never reads a
	Workspace instance, so a plate for something that streams out is destroyed, not left pointing
	at nothing.
]]

local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)
local Label = require(script.Parent.Parent.Components.Label)

local NamePlate = {}

export type Plate = {
	frame: Frame,
	setText: (text: string) -> (),
	moveTo: (x: number, y: number) -> (),
	destroy: () -> (),
}

-- `x` and `y` are the bottom-centre of the plate in pixels from the parent's top left, so a plate
-- sits above the point it names (the bottom edge is the anchor).
function NamePlate.new(parent: GuiObject, text: string): Plate
	local frame = Panel.new({ name = "NamePlate", elevation = "raised" })
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.space.s3)
	padding.PaddingRight = UDim.new(0, Theme.space.s3)
	padding.PaddingTop = UDim.new(0, Theme.space.s1)
	padding.PaddingBottom = UDim.new(0, Theme.space.s1)
	padding.Parent = frame

	local label = Label.new({
		name = "PlateText",
		text = text,
		type = "label",
		color = "text",
		align = "center",
	})
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Parent = frame

	local function setText(newText: string)
		Label.setText(label, newText, "label")
	end

	local function moveTo(x: number, y: number)
		frame.Position = UDim2.fromOffset(x, y)
	end

	return {
		frame = frame,
		setText = setText,
		moveTo = moveTo,
		destroy = function()
			frame:Destroy()
		end,
	}
end

return NamePlate
