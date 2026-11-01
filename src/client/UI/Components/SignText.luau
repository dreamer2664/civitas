--!strict
--[[
	SignText: a station or destination sign. Warm white on a dark enamel-blue plate, upper case,
	condensed type, 2 px corners. It is the only place the game uses a plate look, so a platform
	sign and a departure board read as the same family of signage.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Label = require(script.Parent.Label)

local SignText = {}

export type Options = {
	text: string,
	large: boolean?,
	width: number?,
	height: number?,
	align: ("left" | "center")?,
}

function SignText.new(options: Options): TextLabel
	Label.checkText(options.text, if options.large then "signLarge" else "sign")
	local label = Instance.new("TextLabel")
	label.Name = `Sign_{options.text}`
	label.Text = string.upper(options.text)
	label.BorderSizePixel = 0
	label.BackgroundColor3 = Style.color("sign")
	label.TextColor3 = Style.color("signText")
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = if options.align == "left"
		then Enum.TextXAlignment.Left
		else Enum.TextXAlignment.Center
	label.Size = UDim2.fromOffset(options.width or 240, options.height or 48)
	Style.applyType(label, if options.large then "signLarge" else "sign")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.radius.sign)
	corner.Parent = label

	return label
end

return SignText
