--!strict
-- Deterministic service telemetry; NOT an in-engine performance benchmark.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Kinematics = require("../../src/shared/Rail/Kinematics")
local Driver = require("../../src/shared/Rail/DriverControl")
local Service = require("../../src/shared/Rail/ShuttleService")
local Engine = require("../../src/shared/Rail/TrainSimulation").create(Kinematics, Driver)
local station = require("../../src/server/World/CityConfig").station
local route = {
	stops = {
		{
			id = "garden",
			name = "West Gardens",
			distanceStuds = station.westStopX - station.railMinX,
		},
		{
			id = "central",
			name = "Civitas Central",
			distanceStuds = station.centerX - station.railMinX,
		},
	},
	dwellSeconds = 18,
	maxSpeedMs = 6,
}
local settings = {
	trackLengthStuds = station.railMaxX - station.railMinX,
	marginStuds = 80,
	commandTimeoutSeconds = 0.6,
	maxSpeedMs = 20,
}
local motion = Engine.new(route.stops[2].distanceStuds, settings)
local service = Service.new(route, motion.motion)
local config = Kinematics.defaultConfig()
local samples = {}
local arrivals = {}
local peak = 0
local maxCorrection = 0
local doorViolations = 0
for tick = 1, 21600 do
	local now = tick / 30
	local command, docking
	service, command, docking = Service.step(service, route, motion.motion, 1 / 30)
	if docking then
		maxCorrection = math.max(maxCorrection, math.abs(motion.motion.distanceStuds - docking))
		table.insert(arrivals, { seconds = now, station = route.stops[service.target].name })
		motion.motion = { distanceStuds = docking, speedMs = 0 }
	end
	local accepted = Engine.submit(motion, command, now)
	assert(accepted ~= nil, "automatic command rejected")
	motion = Engine.step(
		accepted,
		settings,
		config,
		1 / 30,
		now,
		0,
		Service.atStop(route, motion.motion.distanceStuds) ~= nil
	)
	peak = math.max(peak, math.abs(motion.motion.speedMs))
	if
		motion.doorsOpen
		and (
			math.abs(motion.motion.speedMs) > 0.01
			or Service.atStop(route, motion.motion.distanceStuds) == nil
		)
	then
		doorViolations += 1
	end
	if tick % 30 == 0 then
		table.insert(samples, {
			seconds = now,
			positionStuds = motion.motion.distanceStuds,
			speedKph = math.abs(motion.motion.speedMs) * 3.6,
			doorsOpen = motion.doorsOpen,
			phase = service.phase,
		})
	end
end
assert(doorViolations == 0, "unsafe simulated door state")
fs.writeFile(
	"evidence/norman/service-telemetry.json",
	serde.encode("json", {
		provenance = "720 simulated seconds at 30 Hz through ShuttleService + TrainSimulation + Kinematics, not Roblox runtime",
		arrivals = arrivals,
		samples = samples,
		peakSpeedKph = peak * 3.6,
		maxDockingCorrectionStuds = maxCorrection,
		doorViolations = doorViolations,
		arrivalsIncludingStartup = #arrivals,
	}, true)
)
print(
	string.format(
		"Service: %d arrivals including startup; peak %.2f km/h; max docking correction %.3f studs; %d door violations",
		#arrivals,
		peak * 3.6,
		maxCorrection,
		doorViolations
	)
)
