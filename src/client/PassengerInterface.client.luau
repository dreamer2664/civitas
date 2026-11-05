--!strict
-- Experimental passenger seat HUD. All alighting decisions are made on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ExperimentalShuttleRemotes")
local snapshot = remotes:WaitForChild("Snapshot") :: RemoteEvent
local alight = remotes:WaitForChild("Alight") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "ExperimentalPassengerControls"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "PassengerPanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -16, 1, -16)
panel.Size = UDim2.fromOffset(260, 110)
panel.BackgroundColor3 = Color3.fromRGB(22, 28, 34)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local label = Instance.new("TextLabel")
label.Name = "Status"
label.Position = UDim2.fromOffset(12, 5)
label.Size = UDim2.new(1, -24, 0, 42)
label.BackgroundTransparency = 1
label.Font = Enum.Font.BuilderSansMedium
label.TextSize = 14
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextColor3 = Color3.fromRGB(238, 241, 243)
label.Text = "EXPERIMENTAL SHUTTLE\nWaiting for safe alighting"
label.Parent = panel
local button = Instance.new("TextButton")
button.Name = "Alight"
button.Position = UDim2.fromOffset(12, 53)
button.Size = UDim2.new(1, -24, 0, 46)
button.BackgroundColor3 = Color3.fromRGB(31, 38, 46)
button.BorderSizePixel = 0
button.Font = Enum.Font.BuilderSansMedium
button.TextSize = 14
button.TextColor3 = Color3.fromRGB(238, 241, 243)
button.Text = "ALIGHT AT PLATFORM"
button.Active = true
button.Selectable = true
button.Parent = panel
button.Activated:Connect(function()
	alight:FireServer()
end)

local connection: RBXScriptConnection? = nil
local function watchCharacter(character: Model)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	panel.Visible = false
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if player.Character ~= character then
		return
	end
	local function updateSeat(active: boolean, seatPart: BasePart?)
		panel.Visible = active
			and seatPart ~= nil
			and string.sub(seatPart.Name, 1, 14) == "PassengerSeat_"
			and seatPart:FindFirstAncestor("ExperimentalShuttle") ~= nil
	end
	connection = humanoid.Seated:Connect(updateSeat)
	updateSeat(humanoid.Sit, humanoid.SeatPart)
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	task.spawn(watchCharacter, player.Character)
end
snapshot.OnClientEvent:Connect(function(data: any)
	if type(data) ~= "table" or type(data.speedKph) ~= "number" then
		return
	end
	local safe = data.atPlatform == true and data.doorsOpen == true and data.speedKph <= 0.036
	label.Text = if safe
		then "EXPERIMENTAL SHUTTLE\nDoors open - alighting available"
		else "EXPERIMENTAL SHUTTLE\nWaiting for safe alighting"
	button.Active = safe
	button.Selectable = safe
	button.TextTransparency = if safe then 0 else 0.5
end)
