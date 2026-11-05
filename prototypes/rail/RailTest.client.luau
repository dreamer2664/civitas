--!strict
-- Standalone, deliberately simple driving controls. Server checks driver seat and every command.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("RailTestRemotes")
local control = remoteFolder:WaitForChild("Control") :: RemoteEvent
local snapshot = remoteFolder:WaitForChild("Snapshot") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "RailTestControls"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "Controls"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -12)
panel.Size = UDim2.new(0.96, 0, 0, 166)
panel.BackgroundColor3 = Color3.fromRGB(22, 28, 34)
panel.BorderSizePixel = 0
panel.Parent = gui
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(850, 166)
sizeConstraint.Parent = panel
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -16, 0, 24)
title.Position = UDim2.fromOffset(8, 4)
title.Font = Enum.Font.BuilderSansBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(238, 241, 243)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "RAIL TEST  /  board at platform to drive"
title.Parent = panel
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(8, 27)
status.Size = UDim2.new(1, -16, 0, 24)
status.Font = Enum.Font.RobotoMono
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(174, 184, 193)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
status.Text = "Awaiting server state..."
status.Parent = panel

local throttle = 0
local brake = 1
local reverser = 1
local doors = "hold"
local driving = false
local seatConnection: RBXScriptConnection? = nil

local function refreshTitle()
	if not driving then
		title.Text = "RAIL TEST  /  board at platform to drive"
		return
	end
	local mode = if brake > 0 then "BRAKE" elseif throttle ~= 0 then "POWER" else "COAST"
	title.Text = `RAIL TEST  /  {mode}  /  {if reverser == 1 then "FORWARD" else "REVERSE"}`
end

local function connectCharacter(character: Model)
	if seatConnection then
		seatConnection:Disconnect()
		seatConnection = nil
	end
	driving = false
	throttle, brake, reverser, doors = 0, 1, 1, "hold"
	refreshTitle()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if player.Character ~= character then
		return
	end
	local function updateSeat(active: boolean, seatPart: BasePart?)
		driving = active and seatPart ~= nil and seatPart.Name == "PrototypeDriverSeat"
		-- Never carry a previously latched power command into a newly occupied seat.
		throttle, brake, reverser, doors = 0, 1, 1, "hold"
		refreshTitle()
	end
	seatConnection = humanoid.Seated:Connect(updateSeat)
	updateSeat(humanoid.Sit, humanoid.SeatPart)
end
player.CharacterAdded:Connect(connectCharacter)
if player.Character then
	task.spawn(connectCharacter, player.Character)
end
local function makeButton(text: string, column: number, row: number, action: () -> ())
	local button = Instance.new("TextButton")
	button.Name = text
	button.Text = text
	button.Font = Enum.Font.BuilderSansMedium
	button.TextSize = 14
	button.TextColor3 = Color3.fromRGB(238, 241, 243)
	button.BackgroundColor3 = Color3.fromRGB(31, 38, 46)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Active = true
	button.Selectable = true
	button.Position = UDim2.new((column - 1) / 4, 4, 0, 55 + (row - 1) * 52)
	button.Size = UDim2.new(0.25, -8, 0, 46)
	button.Parent = panel
	button.Activated:Connect(action)
end
local function forward()
	reverser = 1
	throttle = 0
	brake = 1
	refreshTitle()
end
local function reverse()
	reverser = -1
	throttle = 0
	brake = 1
	refreshTitle()
end
local function power()
	throttle = reverser
	brake = 0
	refreshTitle()
end
local function coast()
	throttle = 0
	brake = 0
	refreshTitle()
end
local function stop()
	throttle = 0
	brake = 1
	refreshTitle()
end
makeButton("POWER [W]", 1, 1, power)
makeButton("COAST [C]", 2, 1, coast)
makeButton("BRAKE [S]", 3, 1, stop)
makeButton("FORWARD [F]", 4, 1, forward)
makeButton("REVERSE [R]", 1, 2, reverse)
makeButton("OPEN DOORS", 2, 2, function()
	doors = "open"
end)
makeButton("CLOSE DOORS", 3, 2, function()
	doors = "close"
end)
makeButton("HOLD DOORS", 4, 2, function()
	doors = "hold"
end)
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.W then
		power()
	elseif input.KeyCode == Enum.KeyCode.C then
		coast()
	elseif input.KeyCode == Enum.KeyCode.S then
		stop()
	elseif input.KeyCode == Enum.KeyCode.F then
		forward()
	elseif input.KeyCode == Enum.KeyCode.R then
		reverse()
	end
end)
snapshot.OnClientEvent:Connect(function(data: any)
	if type(data) ~= "table" then
		return
	end
	if type(data.speedKph) ~= "number" or type(data.position) ~= "number" then
		return
	end
	status.Text = string.format(
		"%05.1f km/h  |  %.0f studs  |  doors %s  |  %s",
		data.speedKph,
		data.position,
		if data.doorsOpen then "open" else "closed",
		data.intervention or "ready"
	)
end)
-- Repeat current intent to satisfy the server's dead-man timeout. This runs only while the GUI exists.
task.spawn(function()
	while gui.Parent do
		control:FireServer({
			throttle = throttle,
			brake = brake,
			reverser = reverser,
			doors = doors,
		})
		task.wait(0.2)
	end
end)
