--!strict
-- Standalone test track only: this does not install unreviewed railway geometry in District A.
-- Server owns the simulation and geometry. A seated driver may send validated intent only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local rail = ReplicatedStorage.Shared.Rail
local Kinematics = require(rail.Kinematics)
local DriverControl = require(rail.DriverControl)
local ControlGate = require(rail.ControlGate)
local Simulation = require(rail.TrainSimulation).create(Kinematics, DriverControl)

local settings =
	{ trackLengthStuds = 1200, marginStuds = 35, commandTimeoutSeconds = 0.6, maxSpeedMs = 20 }
local config = Kinematics.defaultConfig()
local state = Simulation.new(160, settings)

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
	p.Parent = parent
	return p
end

local world = Instance.new("Model")
world.Name = "RailTestWorld"
world.Parent = workspace
part(
	world,
	"Ground",
	Vector3.new(1400, 2, 160),
	Vector3.new(600, -1, 0),
	Color3.fromRGB(84, 105, 79),
	Enum.Material.Grass
)
part(
	world,
	"Ballast",
	Vector3.new(1200, 0.5, 17),
	Vector3.new(600, 0.25, 0),
	Color3.fromRGB(91, 88, 80),
	Enum.Material.Slate
)
for _, z in ipairs({ -3.2, 3.2 }) do
	part(
		world,
		"Rail",
		Vector3.new(1200, 0.5, 0.5),
		Vector3.new(600, 0.75, z),
		Color3.fromRGB(130, 135, 137),
		Enum.Material.Metal
	)
end
for x = 0, 1200, 15 do
	part(
		world,
		"Sleeper",
		Vector3.new(2, 0.3, 11),
		Vector3.new(x, 0.58, 0),
		Color3.fromRGB(88, 70, 57),
		Enum.Material.WoodPlanks
	)
end
part(
	world,
	"Platform",
	Vector3.new(230, 2, 15),
	Vector3.new(160, 1, -14),
	Color3.fromRGB(175, 170, 155),
	Enum.Material.Concrete
)
part(
	world,
	"TactileEdge",
	Vector3.new(230, 0.08, 1),
	Vector3.new(160, 2.04, -7),
	Color3.fromRGB(217, 194, 126),
	Enum.Material.Concrete
).CanCollide =
	false
local spawn = Instance.new("SpawnLocation")
spawn.Name = "RailTestSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(160, 2.5, -17)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = world

local train = Instance.new("Model")
train.Name = "PrototypeTrain"
train.Parent = world
local body = part(
	train,
	"Body",
	Vector3.new(44, 7, 9),
	Vector3.new(160, 5, 0),
	Color3.fromRGB(207, 213, 208),
	Enum.Material.Metal
)
body.CanCollide = false
train.PrimaryPart = body
local stripe = part(
	train,
	"WindowBand",
	Vector3.new(36, 2.3, 9.15),
	Vector3.new(157, 6, 0),
	Color3.fromRGB(30, 61, 70),
	Enum.Material.SmoothPlastic
)
stripe.CanCollide = false
local roof = part(
	train,
	"Roof",
	Vector3.new(44, 0.5, 9.2),
	Vector3.new(160, 8.75, 0),
	Color3.fromRGB(99, 109, 109),
	Enum.Material.Metal
)
roof.CanCollide = false
local seat = Instance.new("Seat")
seat.Name = "PrototypeDriverSeat"
seat.Size = Vector3.new(3, 1, 3)
seat.Position = Vector3.new(175, 9.5, 0)
seat.Anchored = true
seat.CanCollide = false
seat.Color = Color3.fromRGB(40, 48, 52)
seat.Parent = train
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "BoardDriver"
prompt.ActionText = "Board driver seat"
prompt.ObjectText = "Test train"
prompt.MaxActivationDistance = 20
prompt.RequiresLineOfSight = false
prompt.Parent = body
prompt.Triggered:Connect(function(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if
		humanoid
		and root
		and root:IsA("BasePart")
		and humanoid.Health > 0
		and seat.Occupant == nil
		and (root.Position - body.Position).Magnitude <= prompt.MaxActivationDistance + 3
		and math.abs(state.motion.speedMs) < 0.01
		and math.abs(state.motion.distanceStuds - 160) <= 20
	then
		seat:Sit(humanoid)
	end
end)

local remotes = Instance.new("Folder")
remotes.Name = "RailTestRemotes"
remotes.Parent = ReplicatedStorage
local control = Instance.new("RemoteEvent")
control.Name = "Control"
control.Parent = remotes
local snapshot = Instance.new("RemoteEvent")
snapshot.Name = "Snapshot"
snapshot.Parent = remotes

-- Per-player token bucket, capped and removed on exit. This is not a production authority layer.
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

local accumulator = 0
local ticks = 0
local previousOccupant: Humanoid? = nil
RunService.Heartbeat:Connect(function(elapsed: number)
	-- Discard excessive backlog rather than doing unbounded catch-up work on a stalled server.
	accumulator = math.min(accumulator + elapsed, 4 / 30)
	while accumulator >= 1 / 30 do
		accumulator -= 1 / 30
		-- A vacated or changed seat immediately loses the previous driver's intent.
		if seat.Occupant ~= previousOccupant then
			state.lastCommand = nil
			state.commandTime = nil
			previousOccupant = seat.Occupant
		end
		local atPlatform = math.abs(state.motion.distanceStuds - 160) <= 20
		state = Simulation.step(state, settings, config, 1 / 30, os.clock(), 0, atPlatform)
		train:PivotTo(CFrame.new(state.motion.distanceStuds, 5, 0))
		ticks += 1
		if ticks % 6 == 0 then
			snapshot:FireAllClients({
				speedKph = math.abs(state.motion.speedMs) * 3.6,
				position = state.motion.distanceStuds,
				doorsOpen = state.doorsOpen,
				intervention = state.intervention,
			})
		end
	end
end)
