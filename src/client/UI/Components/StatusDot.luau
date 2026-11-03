--!strict
--[[
	StatusDot: a status shown as a dot, its colour, and a required word. The word is mandatory
	on purpose. A dot on its own is colour-only signalling, which UI-SPEC §4 forbids: a player who
	cannot tell the colours apart would see nothing.

	Tones are tokens. `neutral` uses textMuted, not a status colour, so an idle state never looks
	like a warning.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Label = require(script.Parent.Label)

local StatusDot = {}

export type Tone = "proceed" | "caution" | "stop" | "neutral"

export type Options = {
	name: string?,
	tone: Tone,
	text: string,
}

local TONE: { [Tone]: Style.ColorName } = {
	proceed = "proceed",
	caution = "caution",
	stop = "stop",
	neutral = "textMuted",
}

function StatusDot.new(options: Options): Frame
	if options.text == "" then
		error("StatusDot needs a word: a dot without text is colour-only signalling (UI-SPEC §4)")
	end

	local row = Instance.new("Frame")
	row.Name = if options.name then options.name else "StatusDot"
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, Theme.size.touchMin)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, Theme.space.s2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.LayoutOrder = 1
	dot.BorderSizePixel = 0
	dot.Size = UDim2.fromOffset(Theme.size.dot, Theme.size.dot)
	dot.BackgroundColor3 = Style.color(TONE[options.tone])
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = dot
	dot.Parent = row

	local word = Label.new({ name = "Word", text = options.text, type = "label", color = "text" })
	word.LayoutOrder = 2
	word.Size = UDim2.new(1, -(Theme.size.dot + Theme.space.s2), 1, 0)
	word.Parent = row

	return row
end

return StatusDot
