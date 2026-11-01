--!strict
--[[
TrainService.luau — server-authoritative train service (thin Roblox layer).

Server owns position; clients send intent only. Integrates each active train along its
spline at a fixed 30 Hz tick using Kinematics.luau and publishes TrainState snapshots
(Train.State) at the same tick for clients to interpolate.

Pure rules live in src/shared/Rail (Spline, Kinematics — unit tested under lune). This module
is the Roblox boundary: RunService tick loop, RemoteEvent wiring, intent validation.

Not unit-testable under lune (touches game:GetService / RunService); verified by selene +
luau-lsp with tools/globalTypes.d.luau, plus rojo build.
--]]

-- `game` and `Workspace` are declared as export const in tools/globalTypes.d.luau,
-- loaded via luau-lsp --definitions.
local RunService: RunService = game:GetService("RunService") :: RunService
local ReplicatedStorage: ReplicatedStorage =
	game:GetService("ReplicatedStorage") :: ReplicatedStorage

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Instance
local Rail = Shared:WaitForChild("Rail") :: Instance

-- Module loading at the Roblox boundary: WaitForChild returns Instance?, so the require
-- result is cast. Pure rules in Spline/Kinematics are unit-tested separately under lune.
local SplineModule = require(Rail:WaitForChild("Spline") :: ModuleScript)
local KinematicsModule = require(Rail:WaitForChild("Kinematics") :: ModuleScript)
local Spline = SplineModule :: any
local Kinematics = KinematicsModule :: any

-- Remote names mirror src/shared/Contracts/RemoteContract.luau (PROVISIONALLY RATIFIED).
local REMOTE_CONTROL = "Train.Control"
local REMOTE_STATE = "Train.State"

-- Fixed tick: 30 Hz (~33.3 ms per tick). All of integration + publication fits in one tick.
local TICK_RATE = 30
local DT = 1 / TICK_RATE

-- Train state mirrors RailContract.TrainState (frozen shape). Runtime representation here;
-- types are aligned by contract, not by import (types are erased at runtime).
export type TrainState = {
	trainId: string,
	lineId: string,
	distanceStuds: number,
	speedStudsPerS: number,
	direction: number,
	doorState: string,
	signalAspect: string,
	speedLimitKph: number,
	updatedAt: number,
}

export type ActiveTrain = {
	trainId: string,
	lineId: string,
	spline: any,
	state: {
		speedMs: number,
		distanceStuds: number,
	},
	config: any,
	lastCommand: {
		tractive: number,
		brake: number,
		emergencyBrake: boolean,
	},
}

local TrainService = {}
local activeTrains: { [string]: ActiveTrain } = {}
local pendingIntents: { [string]: { tractive: number, brake: number, emergencyBrake: boolean } } =
	{}

local controlRemote: RemoteEvent?
local stateRemote: RemoteEvent?

-- Helper: find a child by name, creating it if absent. Always returns non-nil.
local function getOrCreate(child: Instance, name: string, className: string): Instance
	local existing = child:FindFirstChild(name)
	if existing ~= nil then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = child
	return created
end

-- Ensure remotes exist under ReplicatedStorage.Remotes.
local function ensureRemotes(): (RemoteEvent, RemoteEvent)
	local remotes = getOrCreate(ReplicatedStorage, "Remotes", "Folder")
	local control = getOrCreate(remotes, REMOTE_CONTROL, "RemoteEvent") :: RemoteEvent
	local state = getOrCreate(remotes, REMOTE_STATE, "RemoteEvent") :: RemoteEvent
	return control, state
end

-- Validate and clamp an intent command before the sim sees it. All fields bounded.
local function sanitizeCommand(command: {
	tractive: number?,
	brake: number?,
	emergencyBrake: boolean?,
}): {
	tractive: number,
	brake: number,
	emergencyBrake: boolean,
}
	return {
		tractive = math.clamp(command.tractive or 0, -1, 1),
		brake = math.clamp(command.brake or 0, 0, 1),
		emergencyBrake = command.emergencyBrake == true,
	}
end

function TrainService.spawnTrain(
	trainId: string,
	lineId: string,
	controlPoints: { { x: number, y: number, z: number } },
	startDistanceStuds: number?,
	config: any?
): ActiveTrain
	if activeTrains[trainId] ~= nil then
		error(string.format("TrainService: train %q already exists", trainId))
	end
	local spline = Spline.new(controlPoints)
	local train: ActiveTrain = {
		trainId = trainId,
		lineId = lineId,
		spline = spline,
		state = { speedMs = 0, distanceStuds = startDistanceStuds or 0 },
		config = config or {},
		lastCommand = { tractive = 0, brake = 0, emergencyBrake = false },
	}
	activeTrains[trainId] = train
	return train
end

function TrainService.despawnTrain(trainId: string)
	activeTrains[trainId] = nil
	pendingIntents[trainId] = nil
end

-- Player intent (client-to-server). Validated here; the server owns position.
function TrainService.applyIntent(
	trainId: string,
	command: {
		tractive: number?,
		brake: number?,
		emergencyBrake: boolean?,
	}
)
	local train = activeTrains[trainId]
	if train == nil then
		warn(string.format("TrainService: intent for unknown train %q", trainId))
		return
	end
	pendingIntents[trainId] = sanitizeCommand(command)
end

function TrainService.getTrainCount(): number
	local count = 0
	for _ in pairs(activeTrains) do
		count += 1
	end
	return count
end

-- One fixed tick of the simulation.
local function tick(dt: number)
	for _, train in pairs(activeTrains) do
		local command = pendingIntents[train.trainId]
			or { tractive = 0, brake = 0, emergencyBrake = false }
		-- Consume the intent: apply once per tick.
		pendingIntents[train.trainId] = nil

		-- Kinematics.integrate is pure; called here at the Roblox boundary.
		local newState = Kinematics.integrate(
			train.state :: any,
			dt,
			{
				tractive = command.tractive,
				serviceBrake = command.brake,
				emergencyBrake = command.emergencyBrake,
			},
			train.config :: any,
			0 -- grade: looked up from the track segment in Phase 2 signalling
		)
		train.state = {
			speedMs = newState.speedMs,
			distanceStuds = newState.distanceStuds,
		}
	end

	-- Publish authoritative state at the fixed tick.
	if stateRemote ~= nil then
		local states = {}
		for _, train in pairs(activeTrains) do
			table.insert(states, {
				trainId = train.trainId,
				lineId = train.lineId,
				distanceStuds = train.state.distanceStuds,
				speedStudsPerS = train.state.speedMs / (1 / 0.28), -- m/s -> studs/s
				direction = 1,
				doorState = "closed",
				signalAspect = "green",
				speedLimitKph = 120,
				updatedAt = os.clock(),
			})
		end
		stateRemote.FireAllClients(states)
	end
end

function TrainService.start()
	controlRemote, stateRemote = ensureRemotes()
	assert(controlRemote ~= nil, "TrainService: control remote must exist")
	assert(stateRemote ~= nil, "TrainService: state remote must exist")

	controlRemote.OnServerEvent.Connect(function(_player: Instance, trainId: any, command: any)
		if type(trainId) ~= "string" then
			return nil
		end
		if type(command) ~= "table" then
			return nil
		end
		TrainService.applyIntent(
			trainId,
			command :: {
				tractive: number?,
				brake: number?,
				emergencyBrake: boolean?,
			}
		)
		return nil
	end)

	local accumulator = 0
	RunService.Heartbeat.Connect(function(stepDt: number): any
		accumulator += stepDt
		while accumulator >= DT do
			tick(DT)
			accumulator -= DT
		end
		return nil
	end)
end

return TrainService
