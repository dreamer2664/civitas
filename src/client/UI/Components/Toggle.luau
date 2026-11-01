--!strict
--[[
	Toggle: an on/off control shown as a full-width button. The state is written in the label, so
	"Reduce motion: On" is readable without colour. On uses the accent fill with ink text; off
	stays on a raised fill with light text. Both pairs meet the text rule (tests/client/theme.spec).

	The control only renders state. The caller owns the value and calls Toggle.render after it
	changes, so the server or a settings store stays the single source of truth.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Label = require(script.Parent.Label)

local Toggle = {}

export type Options = {
	name: string?,
	label: string,
	value: boolean,
}

-- Writes "<label>: On" or "<label>: Off" into the button and sets its fill to match.
function Toggle.render(button: TextButton, label: string, value: boolean)
	local word = if value then "On" else "Off"
	local text = `{label}: {word}`
	Label.checkText(text, "label")
	button.Text = text
	if value then
		button.BackgroundColor3 = Style.color("accent")
		button.TextColor3 = Style.color("ink")
	else
		button.BackgroundColor3 = Style.color("raised")
		button.TextColor3 = Style.color("text")
	end
end

function Toggle.new(options: Options): TextButton
	Label.checkText(options.label, "label")

	local button = Instance.new("TextButton")
	button.Name = if options.name then options.name else "Toggle"
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, Theme.size.touchComfort)
	button.TextXAlignment = Enum.TextXAlignment.Left
	Style.applyType(button, "label")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.radius.control)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.space.s4)
	padding.Parent = button

	Toggle.render(button, options.label, options.value)
	return button
end

return Toggle
