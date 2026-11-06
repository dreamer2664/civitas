--!strict
-- Connect the existing city HUD and the provisional network diagram to StarterPlayerScripts.
-- The diagram is a plan, not a claim that trains or the depicted stations are operational.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local SignText = require(script.Parent.UI.Components.SignText)
local MapView = require(script.Parent.UI.Map.MapView)
local NetworkSource = require(script.Parent.UI.Map.NetworkSource)
local NetworkData = require(script.Parent.UI.Map.NetworkData)
local Button = require(script.Parent.UI.Components.Button)
local Label = require(script.Parent.UI.Components.Label)
local Style = require(script.Parent.UI.Style)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screen = Instance.new("ScreenGui")
screen.Name = "CivitasCityInterface"
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screen.Parent = playerGui

-- Keep the stock Roblox movement controls; the prototype stick has no movement controller yet.
local district =
	SignText.new({ text = "Historic Core", width = 160, height = 48, align = "center" })
district.Name = "DistrictSign"
district.Position = UDim2.fromOffset(16, 16)
district.Parent = screen

local mapPanel = Instance.new("Frame")
mapPanel.Name = "PlannedNetworkPanel"
mapPanel.BackgroundColor3 = Style.color("ink")
mapPanel.BorderSizePixel = 0
mapPanel.Position = UDim2.fromScale(0.05, 0.08)
mapPanel.Size = UDim2.fromScale(0.9, 0.84)
mapPanel.Visible = false
mapPanel.ClipsDescendants = true
mapPanel.Parent = screen

local heading = Label.new({
	name = "Heading",
	text = "PLANNED NETWORK",
	type = "heading",
	color = "text",
})
heading.Position = UDim2.fromOffset(16, 4)
heading.Size = UDim2.new(1, -32, 0, 25)
heading.Parent = mapPanel
local note = Label.new({
	name = "Status",
	text = "Plan only - test shuttle separate. Zoom for names.",
	type = "caption",
	color = "textMuted",
})
note.Position = UDim2.fromOffset(16, 29)
note.Size = UDim2.new(1, -32, 0, 30)
note.Parent = mapPanel

local mapHolder = Instance.new("Frame")
mapHolder.Name = "MapHolder"
mapHolder.BackgroundTransparency = 1
mapHolder.Position = UDim2.fromOffset(12, 64)
mapHolder.Size = UDim2.new(1, -24, 1, -128)
mapHolder.Parent = mapPanel

local view: MapView.View? = nil
local toggle: TextButton
local function setMapOpen(open: boolean)
	if open == mapPanel.Visible then
		return
	end
	mapPanel.Visible = open
	playerGui:SetAttribute("CivitasMapOpen", open)
	if open then
		view = MapView.new(mapHolder, NetworkSource.fromTable("planned network", NetworkData))
	else
		if view then
			MapView.destroy(view)
			view = nil
		end
	end
	toggle.Text = if open then "CLOSE MAP" else "MAP"
end

toggle = Button.new({
	text = "Map",
	width = 120,
	onActivated = function()
		setMapOpen(not mapPanel.Visible)
	end,
})
toggle.Name = "MapToggle"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -16, 0, 16)
toggle.Parent = screen

local function zoomButton(text: string, x: number, factor: number)
	local button = Button.new({
		text = text,
		width = 56,
		onActivated = function()
			if view then
				MapView.zoom(view, factor)
			end
		end,
	})
	button.Position = UDim2.new(0, x, 1, -56)
	button.Parent = mapPanel
end
zoomButton("-", 12, 1 / 1.35)
zoomButton("+", 76, 1.35)

ContextActionService:BindAction("CivitasTogglePlannedMap", function(_name, state, _input)
	if state == Enum.UserInputState.Begin then
		setMapOpen(not mapPanel.Visible)
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.M, Enum.KeyCode.ButtonSelect)

screen.Destroying:Connect(function()
	ContextActionService:UnbindAction("CivitasTogglePlannedMap")
	if view then
		MapView.destroy(view)
		view = nil
	end
end)
