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
local ShuttleService = require(rail.ShuttleService)
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
local route = {
	stops = {
		{ id = "garden", name = "West Gardens", distanceStuds = station.westStopX - MIN_X },
		{ id = "central", name = "Civitas Central", distanceStuds = START_DISTANCE },
	},
	dwellSeconds = 18,
	maxSpeedMs = 6,
}
local service = ShuttleService.new(route, state.motion)
local doorFraction = 0
local function currentStop(): ShuttleService.Stop?
	return ShuttleService.atStop(route, state.motion.distanceStuds)
end

local geometry = require(script.Parent.RailGeometry).build(station, Workspace)
local train = geometry.train
local anchor = geometry.anchor
local seat = geometry.seat
local passengerSeats = geometry.passengerSeats
local prompt = geometry.prompt
local passengerPrompt = geometry.passengerPrompt
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
		and BoardingRules.canBoard(
			state.doorsOpen,
			state.motion.speedMs,
			currentStop() ~= nil,
			true
		)
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
	local atPlatform = currentStop() ~= nil
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
	local atPlatform = currentStop() ~= nil
	if
		not BoardingRules.canAlight(state.doorsOpen, state.motion.speedMs, atPlatform, isPassenger)
	then
		return
	end
	local destination = currentStop()
	if destination == nil then
		return
	end
	humanoid.Sit = false
	-- Let the seat weld release before repositioning; still requires live Studio verification.
	task.delay(0.1, function()
		if player.Character == character and root.Parent ~= nil and not humanoid.Sit then
			root.CFrame = CFrame.new(
				MIN_X + destination.distanceStuds,
				station.platformTopY + 3,
				station.platformCenterZ - 3
			)
		end
	end)
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
			if previousOccupant == nil then
				service = ShuttleService.new(route, state.motion)
			end
		end
		if seat.Occupant == nil then
			local command, docking
			service, command, docking = ShuttleService.step(service, route, state.motion, DT)
			if docking then
				state.motion = { distanceStuds = docking, speedMs = 0 }
			end
			local accepted = Simulation.submit(state, command, os.clock())
			if accepted then
				state = accepted
			end
		end
		local atPlatform = currentStop() ~= nil
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
		local pivot = CFrame.new(MIN_X + state.motion.distanceStuds, 0, station.railCenterZ)
		train:PivotTo(pivot)
		-- Only the platform-facing side opens. Door leaves remain visual/non-colliding;
		-- seat admission is still server gated. This is not a walk-through boarding system.
		local desiredFraction = if state.doorsOpen then 1 else 0
		doorFraction += math.clamp(desiredFraction - doorFraction, -DT * 3, DT * 3)
		for _, leaf in ipairs(geometry.doorLeaves) do
			local onPlatformSide = leaf.closed.Position.Z < 0
			local fraction = if onPlatformSide then doorFraction else 0
			leaf.part.CFrame = pivot * leaf.closed * CFrame.new(leaf.slide * fraction, 0, 0)
		end
		prompt.Enabled = BoardingRules.canBoard(
			state.doorsOpen,
			state.motion.speedMs,
			atPlatform,
			seat.Occupant == nil
		)
		ticks += 1
		if ticks % 6 == 0 then
			snapshot:FireAllClients({
				speedKph = math.abs(state.motion.speedMs) * 3.6,
				position = state.motion.distanceStuds,
				atPlatform = atPlatform,
				doorsOpen = state.doorsOpen,
				intervention = state.intervention,
				mode = if seat.Occupant == nil then "automatic" else "manual",
				stopName = if currentStop()
					then (currentStop() :: ShuttleService.Stop).name
					else nil,
				targetName = if seat.Occupant == nil
					then route.stops[service.target].name
					else "Driver-operated shuttle",
				phase = if seat.Occupant == nil then service.phase else "manual",
				dwellRemaining = if seat.Occupant == nil then service.remaining else 0,
				completedLegs = service.completedLegs,
			})
		end
	end
end)
