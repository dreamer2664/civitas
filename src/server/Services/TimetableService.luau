--!strict
--[[
TimetableService.luau — server-boundary timetable dispatcher.

Driven by the fixed tick: each tick, asks TimetableScheduler which departures are
due and spawns them via TrainService. Not unit-testable under lune (touches
game:GetService / RunService); verified by selene + luau-lsp + rojo build.

Start after TrainService.start(), passing the TrainService module.
--]]

local RunService: RunService = game:GetService("RunService") :: RunService
local ReplicatedStorage: ReplicatedStorage =
	game:GetService("ReplicatedStorage") :: ReplicatedStorage

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Instance

local TimetableModule = require(Shared:WaitForChild("Config"):WaitForChild("Timetable"))
local StopsModule = require(Shared:WaitForChild("Config"):WaitForChild("Stops"))
local TracksModule = require(Shared:WaitForChild("Config"):WaitForChild("Tracks"))
local TimetableSchedulerModule =
	require(Shared:WaitForChild("Scheduling"):WaitForChild("TimetableScheduler"))

local Timetable = TimetableModule :: any
local Stops = StopsModule :: any
local Tracks = TracksModule :: any
local TimetableScheduler = TimetableSchedulerModule :: any

local TimetableService = {}

local trainService: any = nil -- set by start()
local serviceStartTime: number? = nil
local spawnedTrainIds: { [string]: boolean } = {}
local headwayLastDeparture: { [string]: number } = {}

local DT = 1 / 30 -- match TrainService tick rate

function TimetableService.start(service: any)
	trainService = service
	serviceStartTime = os.clock()

	local accumulator = 0
	RunService.Heartbeat.Connect(function(stepDt: number): any
		accumulator += stepDt
		while accumulator >= DT do
			accumulator -= DT
			TimetableService.tick(DT)
		end
		return nil
	end)
end

function TimetableService.tick(_dt: number)
	if trainService == nil or serviceStartTime == nil then
		return
	end

	local nowSeconds = os.clock() - serviceStartTime

	local due = TimetableScheduler.dueDepartures(
		Timetable,
		nowSeconds,
		spawnedTrainIds,
		headwayLastDeparture
	)

	for _, entry in ipairs(due) do
		local line = Tracks[entry.lineId]
		if line == nil then
			warn(string.format("TimetableService: unknown line %q", entry.lineId))
			continue
		end

		-- Look up the start station's arc-length distance on the line.
		local startDistance = 0
		local stops = Stops[entry.lineId]
		if stops ~= nil then
			for _, stop in ipairs(stops) do
				if stop.stationId == entry.startStationId then
					startDistance = stop.distanceStuds
					break
				end
			end
		end

		trainService.spawnTrain(entry.trainId, entry.lineId, line.controlPoints, startDistance, {})

		-- Initial direction: backward (-1) means reverse tractive.
		local initialTractive = entry.direction == -1 and -0.6 or 0.6
		trainService.applyIntent(entry.trainId, {
			tractive = initialTractive,
			brake = 0,
			emergencyBrake = false,
		})

		TimetableScheduler.recordDeparture(spawnedTrainIds, headwayLastDeparture, entry, nowSeconds)
	end
end

return TimetableService
