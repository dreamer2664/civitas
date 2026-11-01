--!strict
--[[
	Walk-mode HUD: the screen-space frame around the player on foot. Everything here is built from
	Theme through Style and the components in UI/Components. No default Roblox look.

	What it shows: a district sign at the top left (when the caller has a district name), an
	interaction prompt above the thumb zones (when there is something to act on), and, on touch, the
	movement pad and action buttons placed by Layout.touchControls.

	What it does not do: move anybody. Movement and actions leave through callbacks, and the walk
	controller (WALK · pave) decides what they mean. The HUD reads no Workspace instance, so it works
	while the city streams in and out. It takes the safe area from its ScreenGui's AbsoluteSize, which
	relies on ScreenInsets = DeviceSafeInsets shrinking that size; that is unverified without Studio.
]]

local UserInputService = game:GetService("UserInputService")

local Layout = require(script.Parent.Parent.Layout)
local Style = require(script.Parent.Parent.Style)
local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)
local Label = require(script.Parent.Parent.Components.Label)
local Button = require(script.Parent.Parent.Components.Button)
local SignText = require(script.Parent.Parent.Components.SignText)

local WalkHud = {}

export type Action = { id: string, label: string, variant: Button.Variant? }
export type Options = {
	district: string?, -- top-left sign; nil hides it
	prompt: string?, -- interaction prompt; nil hides it
	actions: { Action }, -- right thumb, row by row; at most 6
	touch: boolean, -- true lays out touch controls; false leaves keyboard and gamepad alone
	onMove: (x: number, y: number) -> (),
	onAction: (id: string) -> (),
}

export type View = {
	root: ScreenGui,
	setPrompt: (text: string?) -> (),
	setDistrict: (text: string?) -> (),
	destroy: () -> (),
}

-- Gap between touch controls and from the zone edges. Theme owns the number; the layout maths
-- takes it as an argument so it stays testable.
local TOUCH_GAP = Theme.space.s2
local MAX_ACTIONS = 6

function WalkHud.new(root: ScreenGui, options: Options): View
	assert(
		#options.actions <= MAX_ACTIONS,
		`walk HUD supports {MAX_ACTIONS} actions, got {#options.actions}`
	)
	root.ResetOnSpawn = false
	root.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

	local frame = Instance.new("Frame")
	frame.Name = "WalkHud"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = root

	local connections: { RBXScriptConnection } = {}
	local districtSign: TextLabel? = nil
	local prompt: TextLabel? = nil
	local controls: { GuiObject } = {}

	local function setDistrict(text: string?)
		if districtSign then
			districtSign:Destroy()
			districtSign = nil
		end
		if text == nil then
			return
		end
		local sign = SignText.new({ text = text, large = false, align = "left" })
		sign.Name = "District"
		sign.Position = UDim2.fromOffset(Theme.space.s4, Theme.space.s4)
		sign.Parent = frame
		districtSign = sign
	end

	local function setPrompt(text: string?)
		if prompt then
			prompt:Destroy()
			prompt = nil
		end
		if text == nil then
			return
		end
		local label = Label.new({
			name = "Prompt",
			text = text,
			type = "label",
			color = "text",
			align = "center",
		})
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		-- Above the thumb zones (which start at 55% of the height), so a prompt never sits under a thumb.
		label.Position = UDim2.fromScale(0.5, 0.45)
		label.Parent = frame
		prompt = label
	end

	setDistrict(options.district)
	setPrompt(options.prompt)

	if options.touch then
		local pad = Panel.new({ name = "MovePad", elevation = "raised" })
		pad.Parent = frame
		table.insert(controls, pad)

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Size = UDim2.fromOffset(Theme.size.touchComfort / 2, Theme.size.touchComfort / 2)
		knob.BackgroundColor3 = Style.color("accent")
		knob.BorderSizePixel = 0
		knob.Parent = pad
		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(0.5, 0)
		knobCorner.Parent = knob

		local actionButtons: { TextButton } = {}
		for _, action in options.actions do
			local button = Button.new({
				text = action.label,
				variant = action.variant or "secondary",
				width = Theme.size.touchComfort,
				height = Theme.size.touchComfort,
				onActivated = function()
					options.onAction(action.id)
				end,
			})
			button.Parent = frame
			table.insert(actionButtons, button)
			table.insert(controls, button)
		end

		-- The pad captures one touch at a time: the first one that starts on it owns the stick until
		-- it lifts. Position is read from the pad's current AbsolutePosition each time, so a rotated
		-- or resized screen does not leave a stale centre.
		local activeTouch: InputObject? = nil
		local function updateStick(position: Vector3)
			local sx, sy = Layout.padVector({
				x = pad.AbsolutePosition.X,
				y = pad.AbsolutePosition.Y,
				w = pad.AbsoluteSize.X,
				h = pad.AbsoluteSize.Y,
			}, position.X, position.Y)
			options.onMove(sx, sy)
			local radius = math.min(pad.AbsoluteSize.X, pad.AbsoluteSize.Y) / 2
			knob.Position = UDim2.fromOffset(
				pad.AbsoluteSize.X / 2 + sx * radius,
				pad.AbsoluteSize.Y / 2 + sy * radius
			)
		end
		local function release()
			activeTouch = nil
			options.onMove(0, 0)
			knob.Position = UDim2.fromScale(0.5, 0.5)
		end

		table.insert(
			connections,
			pad.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.Touch and activeTouch == nil then
					activeTouch = input
					updateStick(input.Position)
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if input == activeTouch then
					updateStick(input.Position)
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputEnded:Connect(function(input: InputObject)
				if input == activeTouch then
					release()
				end
			end)
		)

		-- Positions follow the screen. Recomputed on every size change, never cached as pixels.
		local function relayout()
			local w, h = frame.AbsoluteSize.X, frame.AbsoluteSize.Y
			if w <= 0 or h <= 0 then
				return
			end
			local safe = { x = 0, y = 0, w = w, h = h }
			local placed = Layout.touchControls(safe, TOUCH_GAP, #actionButtons)
			pad.Position = UDim2.fromOffset(placed.pad.x, placed.pad.y)
			pad.Size = UDim2.fromOffset(placed.pad.w, placed.pad.h)
			for i, button in actionButtons do
				local r = placed.actions[i]
				button.Position = UDim2.fromOffset(r.x, r.y)
				button.Size = UDim2.fromOffset(r.w, r.h)
			end
		end
		table.insert(connections, frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout))
		task.defer(relayout)
	end

	local destroyed = false
	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, control in controls do
			control:Destroy()
		end
		frame:Destroy()
	end

	return {
		root = root,
		setPrompt = setPrompt,
		setDistrict = setDistrict,
		destroy = destroy,
	}
end

return WalkHud
