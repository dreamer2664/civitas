--!strict
-- Experimental single-track shuttle behind the District A placeholder station.
-- Separate from the proposed network: it is not a signalling system or production rail service.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local rail = ReplicatedStorage.Shared.Rail
local Kinematics = require(rail.Kinematics)
local DriverControl = require(rail.DriverControl)
local ControlGate = require(rail.ControlGate)
local BoardingRules = require(rail.BoardingRules)
local Simulation = require(rail.TrainSimulation).create(Kinematics, DriverControl)
local station = require(script.Parent.Parent.World.CityConfig).station

local MIN_X = station.railMinX
local MAX_X = station.railMaxX
local START_DISTANCE = station.centerX - MIN_X
local DT = 1 / 30
local settings = {
	trackLengthStuds = MAX_X - MIN_X,
	marginStuds = 80, -- more than half the prototype's 148.2-stud length
	commandTimeoutSeconds = 0.6,
	maxSpeedMs = 20,
}
local state = Simulation.new(START_DISTANCE, settings)
local dynamics = Kinematics.defaultConfig()

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.Parent = parent
	return p
end

local function visual(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local p = part(parent, name, size, position, color, material)
	p.CanCollide = false
	p.CanQuery = false
	return p
end

local model = Instance.new("Model")
model.Name = "ExperimentalRailway"
model:SetAttribute("Status", "Single-track prototype; not the final Civitas network")
model.Parent = Workspace
local track = Instance.new("Model")
track.Name = "TestTrack"
track.Parent = model
local centerX = (MIN_X + MAX_X) / 2
visual(
	track,
	"Ballast",
	Vector3.new(MAX_X - MIN_X, 0.18, 12),
	Vector3.new(centerX, 0.09, station.railCenterZ),
	Color3.fromRGB(92, 86, 76),
	Enum.Material.Slate
)
for _, offset in ipairs({ -2.56285, 2.56285 }) do
	visual(
		track,
		"Rail",
		Vector3.new(MAX_X - MIN_X, 0.25, 0.25),
		Vector3.new(centerX, station.railTopY - 0.125, station.railCenterZ + offset),
		Color3.fromRGB(142, 146, 145),
		Enum.Material.Metal
	)
end
local sleeperSpacing = 2.1429
for index = 0, math.floor((MAX_X - MIN_X) / sleeperSpacing) do
	visual(
		track,
		"Sleeper",
		Vector3.new(0.8, 0.22, 9),
		Vector3.new(MIN_X + index * sleeperSpacing, 0.21, station.railCenterZ),
		Color3.fromRGB(82, 68, 54),
		Enum.Material.WoodPlanks
	)
end

local train = Instance.new("Model")
train.Name = "ExperimentalShuttle"
train:SetAttribute("Status", "Prototype geometry; not the imported EMU-1")
train.Parent = model
local anchor = visual(
	train,
	"Pivot",
	Vector3.new(1, 1, 1),
	Vector3.new(station.centerX, 0, station.railCenterZ),
	Color3.new(),
	Enum.Material.SmoothPlastic
)
anchor.Transparency = 1
train.PrimaryPart = anchor
local bodyWidth = 10.1786
local bodyBottom = station.railTopY + 3
local bodyHeight = 11.1429
local totalLength = 75 + 1.7857 + 71.4286
local carCenters = {
	station.centerX - totalLength / 2 + 37.5,
	station.centerX - totalLength / 2 + 75 + 1.7857 + 71.4286 / 2,
}
local carLengths = { 75, 71.4286 }
for index, carX in ipairs(carCenters) do
	local length = carLengths[index]
	local car = Instance.new("Model")
	car.Name = if index == 1 then "CabCar" else "IntermediateCar"
	car.Parent = train
	visual(
		car,
		"Body",
		Vector3.new(length, bodyHeight, bodyWidth),
		Vector3.new(carX, bodyBottom + bodyHeight / 2, station.railCenterZ),
		Color3.fromRGB(211, 216, 210),
		Enum.Material.Metal
	)
	visual(
		car,
		"Roof",
		Vector3.new(length, 0.65, bodyWidth + 0.2),
		Vector3.new(carX, bodyBottom + bodyHeight + 0.325, station.railCenterZ),
		Color3.fromRGB(95, 106, 107),
		Enum.Material.Metal
	)
	for _, side in ipairs({ -1, 1 }) do
		local faceZ = station.railCenterZ + side * (bodyWidth / 2 + 0.1)
		visual(
			car,
			"WindowBand",
			Vector3.new(length * 0.84, 3.6, 0.22),
			Vector3.new(carX, bodyBottom + 7.3, faceZ),
			Color3.fromRGB(29, 67, 75),
			Enum.Material.Glass
		)
		for _, doorX in ipairs({ -length * 0.25, length * 0.25 }) do
			visual(
				car,
				"DoorMarker",
				Vector3.new(4.6429, 6.9643, 0.3),
				Vector3.new(carX + doorX, bodyBottom + 3.48215, faceZ + side * 0.12),
				Color3.fromRGB(155, 57, 48),
				Enum.Material.Metal
			)
		end
	end
	for _, offset in ipairs({ -length / 2 + 10.7143, length / 2 - 10.7143 }) do
		visual(
			car,
			"Bogie",
			Vector3.new(9, 2.5, 8),
			Vector3.new(carX + offset, station.railTopY + 1.5, station.railCenterZ),
			Color3.fromRGB(43, 48, 48),
			Enum.Material.Metal
		)
	end
end
local seat = Instance.new("Seat")
seat.Name = "CivitasShuttleDriverSeat"
seat.Size = Vector3.new(3, 1, 3)
seat.Position = Vector3.new(station.centerX + 55, bodyBottom + 4, station.railCenterZ)
seat.Anchored = true
seat.CanCollide = false
seat.Transparency = 1
seat.Parent = train
local passengerSeats: { Seat } = {}
for index, carX in ipairs(carCenters) do
	for _, offset in ipairs({ -20, 0, 20 }) do
		local passengerSeat = Instance.new("Seat")
		passengerSeat.Name = "PassengerSeat_" .. tostring(index) .. "_" .. tostring(offset)
		passengerSeat.Size = Vector3.new(3, 1, 3)
		passengerSeat.Position = Vector3.new(carX + offset, bodyBottom + 3, station.railCenterZ)
		passengerSeat.Anchored = true
		passengerSeat.CanCollide = false
		passengerSeat.Transparency = 1
		passengerSeat.Parent = train
		table.insert(passengerSeats, passengerSeat)
	end
end
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Board test shuttle"
prompt.ObjectText = "Experimental driver seat"
prompt.MaxActivationDistance = 24
prompt.RequiresLineOfSight = false
prompt.Parent = anchor
local passengerPrompt = Instance.new("ProximityPrompt")
passengerPrompt.Name = "PassengerBoarding"
passengerPrompt.ActionText = "Board as passenger"
passengerPrompt.ObjectText = "Experimental shuttle"
passengerPrompt.MaxActivationDistance = 24
passengerPrompt.RequiresLineOfSight = false
passengerPrompt.Enabled = false
passengerPrompt.Parent = anchor
local generatedPartCount = 0
for _, descendant in ipairs(model:GetDescendants()) do
	if descendant:IsA("BasePart") then
		generatedPartCount += 1
	end
end
model:SetAttribute("GeneratedPartCount", generatedPartCount)
print(
	string.format(
		"Civitas ExperimentalRailway: %d parts (separate from city count)",
		generatedPartCount
	)
)
prompt.Triggered:Connect(function(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		humanoid
		and root
		and root:IsA("BasePart")
		and humanoid.Health > 0
		and not humanoid.Sit
		and seat.Occupant == nil
		and (root.Position - anchor.Position).Magnitude <= prompt.MaxActivationDistance + 3
		and math.abs(state.motion.speedMs) < 0.01
		and math.abs(state.motion.distanceStuds - START_DISTANCE) <= 20
	then
		seat:Sit(humanoid)
	end
end)
passengerPrompt.Triggered:Connect(function(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		not humanoid
		or not root
		or not root:IsA("BasePart")
		or humanoid.Health <= 0
		or humanoid.Sit
	then
		return
	end
	if (root.Position - anchor.Position).Magnitude > passengerPrompt.MaxActivationDistance + 3 then
		return
	end
	local atPlatform = math.abs(state.motion.distanceStuds - START_DISTANCE) <= 20
	for _, passengerSeat in ipairs(passengerSeats) do
		if
			BoardingRules.canBoard(
				state.doorsOpen,
				state.motion.speedMs,
				atPlatform,
				passengerSeat.Occupant == nil
			)
		then
			passengerSeat:Sit(humanoid)
			return
		end
	end
end)

local remotes = Instance.new("Folder")
remotes.Name = "ExperimentalShuttleRemotes"
remotes.Parent = ReplicatedStorage
local control = Instance.new("RemoteEvent")
control.Name = "Control"
control.Parent = remotes
local snapshot = Instance.new("RemoteEvent")
snapshot.Name = "Snapshot"
snapshot.Parent = remotes
local alight = Instance.new("RemoteEvent")
alight.Name = "Alight"
alight.Parent = remotes

local buckets: { [Player]: ControlGate.Bucket } = {}
local function allow(player: Player, now: number): boolean
	local updated, allowed = ControlGate.consume(buckets[player], now)
	if updated then
		buckets[player] = updated
	end
	return allowed
end
Players.PlayerRemoving:Connect(function(player: Player)
	buckets[player] = nil
end)
control.OnServerEvent:Connect(function(player: Player, raw: any)
	local now = os.clock()
	if not allow(player, now) then
		return
	end
	local occupant = seat.Occupant
	if not ControlGate.authorized(player.Character, if occupant then occupant.Parent else nil) then
		return
	end
	local nextState = Simulation.submit(state, raw, now)
	if nextState then
		state = nextState
	end
end)
alight.OnServerEvent:Connect(function(player: Player)
	if not allow(player, os.clock()) then
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end
	local isPassenger = false
	for _, passengerSeat in ipairs(passengerSeats) do
		if passengerSeat.Occupant == humanoid then
			isPassenger = true
			break
		end
	end
	local atPlatform = math.abs(state.motion.distanceStuds - START_DISTANCE) <= 20
	if
		not BoardingRules.canAlight(state.doorsOpen, state.motion.speedMs, atPlatform, isPassenger)
	then
		return
	end
	humanoid.Sit = false
	root.CFrame = CFrame.new(station.centerX, station.platformTopY + 3, station.platformCenterZ)
end)
local accumulator = 0
local ticks = 0
local previousOccupant: Humanoid? = nil
RunService.Heartbeat:Connect(function(elapsed: number)
	accumulator = math.min(accumulator + elapsed, 4 * DT)
	while accumulator >= DT do
		accumulator -= DT
		if seat.Occupant ~= previousOccupant then
			state.lastCommand = nil
			state.commandTime = nil
			previousOccupant = seat.Occupant
		end
		local atPlatform = math.abs(state.motion.distanceStuds - START_DISTANCE) <= 20
		state = Simulation.step(state, settings, dynamics, DT, os.clock(), 0, atPlatform)
		local hasFreeSeat = false
		for _, passengerSeat in ipairs(passengerSeats) do
			if passengerSeat.Occupant == nil then
				hasFreeSeat = true
				break
			end
		end
		local canBoard =
			BoardingRules.canBoard(state.doorsOpen, state.motion.speedMs, atPlatform, hasFreeSeat)
		if passengerPrompt.Enabled ~= canBoard then
			passengerPrompt.Enabled = canBoard
		end
		train:PivotTo(CFrame.new(MIN_X + state.motion.distanceStuds, 0, station.railCenterZ))
		ticks += 1
		if ticks % 6 == 0 then
			snapshot:FireAllClients({
				speedKph = math.abs(state.motion.speedMs) * 3.6,
				position = state.motion.distanceStuds,
				atPlatform = atPlatform,
				doorsOpen = state.doorsOpen,
				intervention = state.intervention,
			})
		end
	end
end)
