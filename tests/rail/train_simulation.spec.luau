--!strict
local suite = require("../support/suite")
local expect = suite.expect
local DriverControl = require("../../src/shared/Rail/DriverControl")
local Kinematics = require("../../src/shared/Rail/Kinematics")
local Simulation =
	require("../../src/shared/Rail/TrainSimulation").create(Kinematics, DriverControl)

local settings =
	{ trackLengthStuds = 600, marginStuds = 8, commandTimeoutSeconds = 0.5, maxSpeedMs = 20 }
local config = Kinematics.defaultConfig()
local forward = { throttle = 1, brake = 0, reverser = 1 }
local reverse = { throttle = -1, brake = 0, reverser = -1 }
local brake = { throttle = 0, brake = 1, reverser = 1 }

local function send(state, command, time)
	local nextState, reason = Simulation.submit(state, command, time)
	assert(nextState, reason)
	return nextState
end

suite.test("DriverControl: rejects malformed and adversarial commands", function()
	local invalid = {
		false,
		{},
		{ throttle = 0 / 0, brake = 0, reverser = 1 },
		{ throttle = math.huge, brake = 0, reverser = 1 },
		{ throttle = 0, brake = -1, reverser = 1 },
		{ throttle = 1, brake = 0, reverser = 0 },
		{ throttle = -1, brake = 0, reverser = 1 },
		{ throttle = 0, brake = 0, reverser = 0, doors = "explode" },
		{ throttle = 0, brake = 0, reverser = 0, horn = 1 },
	}
	for _, raw in ipairs(invalid) do
		local command, reason = DriverControl.validate(raw)
		expect.equal(command, nil)
		expect.ok(type(reason) == "string")
	end
	local command =
		DriverControl.validate({ throttle = 0, brake = 1, reverser = 0, distanceStuds = 999 })
	assert(command, "expected valid command")
	expect.equal((command :: any).distanceStuds, nil)
end)

suite.test("TrainSimulation: stale driver commands brake the train to rest", function()
	local state = Simulation.new(100, settings)
	for tick = 1, 150 do
		local t = tick / 30
		state = send(state, forward, t)
		state = Simulation.step(state, settings, config, 1 / 30, t, 0, false)
	end
	expect.ok(state.motion.speedMs > 1)
	local speed = state.motion.speedMs
	for tick = 151, 500 do
		state = Simulation.step(state, settings, config, 1 / 30, tick / 30, 0, false)
	end
	expect.equal(state.motion.speedMs, 0)
	expect.ok(speed > state.motion.speedMs)
	expect.equal(state.intervention, "command timeout")
end)

suite.test(
	"TrainSimulation: doors require platform and standstill, then interlock traction",
	function()
		local state = Simulation.new(100, settings)
		local open = { throttle = 0, brake = 1, reverser = 1, doors = "open" }
		state = send(state, open, 1)
		state = Simulation.step(state, settings, config, 1 / 30, 1, 0, false)
		expect.equal(state.doorsOpen, false)
		state = Simulation.step(state, settings, config, 1 / 30, 1.1, 0, true)
		expect.equal(state.doorsOpen, true)
		state = send(state, forward, 1.2)
		state = Simulation.step(state, settings, config, 1 / 30, 1.2, 0, true)
		expect.equal(state.motion.speedMs, 0)
		expect.equal(state.intervention, "doors open")
		state = send(state, { throttle = 1, brake = 0, reverser = 1, doors = "close" }, 1.3)
		state = Simulation.step(state, settings, config, 1 / 30, 1.3, 0, true)
		expect.ok(state.motion.speedMs > 0)
		state = send(state, open, 1.4)
		state = Simulation.step(state, settings, config, 1 / 30, 1.4, 0, true)
		expect.equal(state.doorsOpen, false)
	end
)

suite.test("TrainSimulation: reverser cannot switch while moving", function()
	local state = Simulation.new(100, settings)
	for tick = 1, 60 do
		state = send(state, forward, tick / 30)
		state = Simulation.step(state, settings, config, 1 / 30, tick / 30, 0, false)
	end
	state = send(state, reverse, 2.1)
	state = Simulation.step(state, settings, config, 1 / 30, 2.1, 0, false)
	expect.equal(state.reverser, 1)
	expect.equal(state.intervention, "reverser change while moving")
end)

suite.test("TrainSimulation: repeated throttle cannot leave either track end", function()
	for _, scenario in ipairs({ { pos = 590, cmd = forward }, { pos = 10, cmd = reverse } }) do
		local state = Simulation.new(scenario.pos, settings)
		for tick = 1, 1200 do
			local time = tick / 30
			state = send(state, scenario.cmd, time)
			state = Simulation.step(state, settings, config, 1 / 30, time, 0, false)
			expect.ok(
				state.motion.distanceStuds >= 0
					and state.motion.distanceStuds <= settings.trackLengthStuds
			)
		end
	end
end)

suite.test("TrainSimulation: rejects out-of-order command time", function()
	local state = send(Simulation.new(100, settings), brake, 10)
	local rejected = Simulation.submit(state, brake, 9)
	expect.equal(rejected, nil)
end)

suite.test(
	"TrainSimulation: stop margin prevents creeping toward the end and allows retreat",
	function()
		local state = Simulation.new(596, settings)
		for tick = 1, 120 do
			local now = tick / 30
			state = send(state, forward, now)
			state = Simulation.step(state, settings, config, 1 / 30, now, 0, false)
		end
		expect.equal(state.motion.distanceStuds, 596)
		expect.equal(state.motion.speedMs, 0)
		for tick = 121, 180 do
			local now = tick / 30
			state = send(state, reverse, now)
			state = Simulation.step(state, settings, config, 1 / 30, now, 0, false)
		end
		expect.ok(state.motion.distanceStuds < 596)
		expect.ok(state.motion.speedMs < 0)
	end
)
