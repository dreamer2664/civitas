--!strict
--[[
	Label: text in a type token and a colour token. Transparent, wraps, never default-styled.

	Every string is checked against the coverage of its face before it reaches the screen
	(UI/Text.luau). A character the font is not declared to cover fails here, with its name, in the
	build, not as a box on a player's screen. Label.checkText is the one place that rule lives;
	other components call it too.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Text = require(script.Parent.Parent.Text)
local FontCoverage = require(script.Parent.Parent.FontCoverage)

local Label = {}

export type Options = {
	name: string?,
	text: string,
	type: Style.TypeName?,
	color: Style.ColorName?,
	align: ("left" | "center" | "right")?,
}

-- Errors if `text` uses a character the face of `typeName` is not declared to cover.
function Label.checkText(text: string, typeName: Style.TypeName)
	Text.assertCovered("Text", text, FontCoverage.forFace(Theme.type[typeName].face))
end

local ALIGN: { [string]: Enum.TextXAlignment } = {
	left = Enum.TextXAlignment.Left,
	center = Enum.TextXAlignment.Center,
	right = Enum.TextXAlignment.Right,
}

function Label.new(options: Options): TextLabel
	local typeName: Style.TypeName = options.type or "body"
	Label.checkText(options.text, typeName)

	local label = Instance.new("TextLabel")
	label.Name = options.name or "Label"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.TextWrapped = true
	label.TextXAlignment = ALIGN[options.align or "left"]
	label.TextColor3 = Style.color(options.color or "text")
	label.Text = options.text
	Style.applyType(label, typeName)
	return label
end

-- Changing the text of an existing label goes through the same check.
function Label.setText(label: TextLabel, text: string, typeName: Style.TypeName)
	Label.checkText(text, typeName)
	label.Text = text
end

return Label
