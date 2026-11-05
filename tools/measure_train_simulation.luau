--!strict
-- Generate reproducible evidence from the pure prototype; not a Studio or multiplayer test.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Kinematics = require("../src/shared/Rail/Kinematics")
local DriverControl = require("../src/shared/Rail/DriverControl")
local Simulation = require("../src/shared/Rail/TrainSimulation").create(Kinematics, DriverControl)

local settings =
	{ trackLengthStuds = 2000, marginStuds = 8, commandTimeoutSeconds = 0.5, maxSpeedMs = 20 }
local config = Kinematics.defaultConfig()
local state = Simulation.new(100, settings)
local samples = {}
for tick = 1, 1200 do
	local now = tick / 30
	local command = if now <= 12
		then { throttle = 1, brake = 0, reverser = 1 }
		elseif now <= 30 then { throttle = 0, brake = 1, reverser = 1 }
		else { throttle = 0, brake = 1, reverser = 1, doors = "open" }
	local nextState, reason = Simulation.submit(state, command, now)
	assert(nextState, reason or "command rejected")
	state = Simulation.step(nextState, settings, config, 1 / 30, now, 0, now > 30)
	if tick % 3 == 0 then
		table.insert(samples, {
			time = now,
			speedKph = state.motion.speedMs * 3.6,
			distanceStuds = state.motion.distanceStuds,
			doorsOpen = state.doorsOpen,
		})
	end
end
fs.writeFile("tools/train-simulation-evidence.json", serde.encode("json", samples, true))
print(`Prototype evidence: {#samples} samples, final speed {state.motion.speedMs} m/s`)
