--!strict
-- Live prototype service status. The planned network map remains explicitly separate.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local snapshot = ReplicatedStorage:WaitForChild("ExperimentalShuttleRemotes")
	:WaitForChild("Snapshot") :: RemoteEvent
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local seated = false
local gui = Instance.new("ScreenGui")
gui.Name = "CivitasServiceStatus"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.Parent = playerGui
local panel = Instance.new("Frame")
panel.Name = "ServiceBoard"
panel.Position = UDim2.fromOffset(16, 78)
panel.Size = UDim2.fromOffset(238, 88)
panel.BackgroundColor3 = Color3.fromRGB(22, 35, 39)
panel.BorderSizePixel = 0
panel.Parent = gui
local bar = Instance.new("Frame")
bar.BackgroundColor3 = Color3.fromRGB(211, 189, 130)
bar.BorderSizePixel = 0
bar.Size = UDim2.new(0, 3, 1, 0)
bar.Parent = panel
local label = Instance.new("TextLabel")
label.Position = UDim2.fromOffset(14, 7)
label.Size = UDim2.new(1, -24, 1, -14)
label.BackgroundTransparency = 1
label.Font = Enum.Font.BuilderSansMedium
label.TextSize = 14
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Center
label.TextColor3 = Color3.fromRGB(238, 232, 215)
label.TextWrapped = true
label.Text = "S1  •  EXPERIMENTAL SHUTTLE\nWaiting for service status"
label.Parent = panel
local function refreshVisibility()
	panel.Visible = not seated and playerGui:GetAttribute("CivitasMapOpen") ~= true
end
playerGui:GetAttributeChangedSignal("CivitasMapOpen"):Connect(refreshVisibility)
local seatConnection: RBXScriptConnection? = nil
local function watchCharacter(character: Model)
	if seatConnection then
		seatConnection:Disconnect()
	end
	seated = false
	refreshVisibility()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if player.Character ~= character then
		return
	end
	seatConnection = humanoid.Seated:Connect(function(active: boolean)
		seated = active
		refreshVisibility()
	end)
	seated = humanoid.Sit
	refreshVisibility()
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	task.spawn(watchCharacter, player.Character)
end
local lastSnapshot = 0
snapshot.OnClientEvent:Connect(function(data: any)
	if
		type(data) ~= "table"
		or type(data.mode) ~= "string"
		or type(data.targetName) ~= "string"
	then
		return
	end
	lastSnapshot = os.clock()
	if data.mode == "manual" then
		label.Text =
			"S1  •  MANUAL OPERATION\nDriver controls this test shuttle\nCentral ↔ West Gardens"
	elseif
		data.phase == "dwelling"
		and type(data.stopName) == "string"
		and type(data.dwellRemaining) == "number"
	then
		label.Text = string.format(
			"S1  •  %s\n%s\nDeparts in %ds · doors open",
			"AUTOMATIC",
			data.stopName,
			math.max(0, math.ceil(data.dwellRemaining))
		)
	elseif data.phase == "closing" then
		label.Text = "S1  •  AUTOMATIC\nDoors closing · stand clear\nCentral ↔ West Gardens"
	else
		label.Text = "S1  •  AUTOMATIC\nNext: " .. data.targetName .. "\nCentral ↔ West Gardens"
	end
end)
-- Never leave a stale countdown looking live after snapshots stop.
task.spawn(function()
	while gui.Parent ~= nil do
		task.wait(1)
		if lastSnapshot > 0 and os.clock() - lastSnapshot > 3 then
			label.Text =
				"S1  •  EXPERIMENTAL SHUTTLE\nService status unavailable\nWaiting for server"
		end
	end
end)
