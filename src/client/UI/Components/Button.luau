--!strict
--[[
	Button: the only interactive control style. Flat fill, 1 px edge, 4 px corners, no default
	Roblox look (AutoButtonColor is off, and the press state comes from Theme).

	Behaviour the spec depends on:
	- Never smaller than the touch minimum (Layout.touchSize), whatever width is requested.
	- Selectable, with a visible focus ring, so gamepad navigation has somewhere to stand.
	- Disabled buttons are inactive and skipped by focus, rather than hidden. Hidden controls
	  confuse players who are looking for them.
	- Pressed feedback is a short client-side tween. It is never replicated.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Layout = require(script.Parent.Parent.Layout)
local Label = require(script.Parent.Label)

local Button = {}

export type Variant = "primary" | "secondary" | "danger"
export type Options = {
	text: string,
	variant: Variant?,
	width: number?,
	height: number?,
	onActivated: () -> (),
}

type Look = { fill: Style.ColorName, label: Style.ColorName, edge: Style.ColorName }

local LOOKS: { [Variant]: Look } = {
	primary = { fill = "accent", label = "ink", edge = "accent" },
	secondary = { fill = "raised", label = "text", edge = "hairline" },
	danger = { fill = "stop", label = "ink", edge = "stop" },
}

local DEFAULT_WIDTH = 160

function Button.new(options: Options): TextButton
	local variant: Variant = options.variant or "secondary"
	local look = LOOKS[variant]
	Label.checkText(options.text, "label")
	local width, height = Layout.touchSize(
		options.width or DEFAULT_WIDTH,
		options.height or Theme.size.touchComfort,
		Theme.size.touchMin
	)

	local button = Instance.new("TextButton")
	button.Name = `Button_{options.text}`
	button.Text = string.upper(options.text)
	button.AutoButtonColor = false
	button.BorderSizePixel = 0
	button.Selectable = true
	button.Size = UDim2.fromOffset(width, height)
	button.TextTruncate = Enum.TextTruncate.AtEnd
	button.BackgroundColor3 = Style.color(look.fill)
	button.TextColor3 = Style.color(look.label)
	Style.applyType(button, "label")

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.radius.control)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Style.color(look.edge)
	stroke.Thickness = Theme.size.hairline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	local restFill = Style.color(look.fill)
	local pressedFill = restFill:Lerp(Style.color("ink"), 0.2)
	local info =
		TweenInfo.new(Style.duration("fast"), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function fadeTo(color: Color3)
		TweenService:Create(button, info, { BackgroundColor3 = color }):Play()
	end

	button.MouseButton1Down:Connect(function()
		if button.Active then
			fadeTo(pressedFill)
		end
	end)
	button.MouseButton1Up:Connect(function()
		fadeTo(restFill)
	end)
	button.MouseLeave:Connect(function()
		fadeTo(restFill)
	end)

	button.SelectionGained:Connect(function()
		stroke.Thickness = Theme.size.focusRing
		stroke.Color = Style.color("accent")
	end)
	button.SelectionLost:Connect(function()
		stroke.Thickness = Theme.size.hairline
		stroke.Color = Style.color(look.edge)
	end)

	button.Activated:Connect(function()
		if button.Active then
			options.onActivated()
		end
	end)

	return button
end

-- Enables or disables a button without hiding it. Disabled buttons drop out of gamepad focus.
function Button.setEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.Selectable = enabled
	button.TextTransparency = if enabled then 0 else 0.5
	button.BackgroundTransparency = if enabled then 0 else 0.3
end

return Button
