--!strict
--[[
	Field: a labelled text input. The caption is a label token above a raised well; the typed text
	is body type. An error is shown as the word "Error:" plus the message, in the stop colour, so a
	player who cannot see colour still reads it.

	Touch: the well is the comfortable touch size (56 px), so the input is easy to tap on a phone.
]]

local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)
local Label = require(script.Parent.Label)
local Panel = require(script.Parent.Panel)

local Field = {}

export type Options = {
	name: string?,
	label: string,
	placeholder: string?,
	text: string?,
}

export type FieldView = {
	root: Frame,
	input: TextBox,
	error: TextLabel,
}

function Field.new(options: Options): FieldView
	-- The caption and the placeholder are shown, so both pass the same coverage check as any label.
	Label.checkText(options.label, "label")
	if options.placeholder then
		Label.checkText(options.placeholder, "body")
	end

	local root = Instance.new("Frame")
	root.Name = if options.name then options.name else "Field"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 0)
	root.AutomaticSize = Enum.AutomaticSize.Y

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, Theme.space.s2)
	layout.Parent = root

	local caption =
		Label.new({ name = "Caption", text = options.label, type = "label", color = "textMuted" })
	caption.LayoutOrder = 1
	caption.AutomaticSize = Enum.AutomaticSize.Y
	caption.Size = UDim2.fromScale(1, 0)
	caption.Parent = root

	local well = Panel.new({ name = "Well", elevation = "raised" })
	well.LayoutOrder = 2
	well.Size = UDim2.new(1, 0, 0, Theme.size.touchComfort)
	well.Parent = root

	local input = Instance.new("TextBox")
	input.Name = "Input"
	input.BackgroundTransparency = 1
	input.BorderSizePixel = 0
	input.Size = UDim2.fromScale(1, 1)
	input.ClearTextOnFocus = false
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.TextColor3 = Style.color("text")
	input.PlaceholderColor3 = Style.color("textFaint")
	input.PlaceholderText = options.placeholder or ""
	input.Text = options.text or ""
	Style.applyType(input, "body")

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.space.s3)
	padding.PaddingRight = UDim.new(0, Theme.space.s3)
	padding.Parent = well
	input.Parent = well

	local errorLabel = Label.new({ name = "Error", text = " ", type = "caption", color = "stop" })
	errorLabel.LayoutOrder = 3
	errorLabel.AutomaticSize = Enum.AutomaticSize.Y
	errorLabel.Size = UDim2.fromScale(1, 0)
	errorLabel.Visible = false
	errorLabel.Parent = root

	return { root = root, input = input, error = errorLabel }
end

-- Shows the error with its word, or clears it when `message` is nil.
function Field.setError(view: FieldView, message: string?)
	if message == nil then
		view.error.Visible = false
		return
	end
	local text = `Error: {message}`
	Label.setText(view.error, text, "caption")
	view.error.Visible = true
end

return Field
