--!strict
local suite = require("../support/suite")
local expect = suite.expect
local Service = require("../../src/shared/Rail/ShuttleService")
local Kinematics = require("../../src/shared/Rail/Kinematics")
local Driver = require("../../src/shared/Rail/DriverControl")
local Engine = require("../../src/shared/Rail/TrainSimulation").create(Kinematics, Driver)
local route = {
	stops = {
		{ id = "garden", name = "West Gardens", distanceStuds = 200 },
		{ id = "central", name = "Civitas Central", distanceStuds = 770 },
	},
	dwellSeconds = 18,
	maxSpeedMs = 6,
}
local settings =
	{ trackLengthStuds = 1350, marginStuds = 80, commandTimeoutSeconds = 0.6, maxSpeedMs = 20 }

suite.test("ShuttleService: rejects invalid routes and recognizes only aligned stops", function()
	Service.validate(route)
	expect.equal(Service.atStop(route, 770).id, "central")
	expect.equal(Service.atStop(route, 773), nil)
	expect.equal(Service.atStop(route, 0 / 0), nil)
	local ok = pcall(Service.validate, { stops = route.stops, dwellSeconds = 0, maxSpeedMs = 6 })
	expect.equal(ok, false)
end)

suite.test("ShuttleService: docking opens doors and honours full dwell and closing time", function()
	local motion = { distanceStuds = 770, speedMs = 0 }
	local service = Service.new(route, motion)
	local docked, command, correction = Service.step(service, route, motion, 1 / 30)
	expect.equal(docked.phase, "dwelling")
	expect.equal(command.doors, "open")
	expect.equal(correction, 770)
	for _ = 1, 539 do
		docked, command = Service.step(docked, route, motion, 1 / 30)
		expect.equal(command.throttle, 0)
		expect.equal(command.doors, "open")
	end
	for _ = 1, 48 do
		docked, command = Service.step(docked, route, motion, 1 / 30)
	end
	expect.equal(docked.target, 1)
	expect.equal(docked.phase, "approaching")
end)

suite.test(
	"ShuttleService: 12 minutes of actual TrainSimulation round trips remain safe",
	function()
		local motion = Engine.new(770, settings)
		local service = Service.new(route, motion.motion)
		local config = Kinematics.defaultConfig()
		local visited = { garden = 0, central = 0 }
		for tick = 1, 21600 do
			local now = tick / 30
			local command, correction
			service, command, correction = Service.step(service, route, motion.motion, 1 / 30)
			if correction then
				expect.equal(math.abs(motion.motion.distanceStuds - correction) <= 0.6, true)
				expect.equal(math.abs(motion.motion.speedMs) <= 0.12, true)
				motion.motion = { distanceStuds = correction, speedMs = 0 }
				local stop = Service.atStop(route, correction)
				visited[stop.id] += 1
			end
			local accepted = Engine.submit(motion, command, now)
			expect.equal(accepted ~= nil, true)
			motion = Engine.step(
				accepted,
				settings,
				config,
				1 / 30,
				now,
				0,
				Service.atStop(route, motion.motion.distanceStuds) ~= nil
			)
			expect.equal(
				motion.motion.distanceStuds >= 190 and motion.motion.distanceStuds <= 780,
				true
			)
			expect.equal(math.abs(motion.motion.speedMs) <= 6.2, true)
			if motion.doorsOpen then
				expect.equal(math.abs(motion.motion.speedMs) <= 0.01, true)
				expect.equal(Service.atStop(route, motion.motion.distanceStuds) ~= nil, true)
			end
		end
		expect.equal(visited.garden >= 4, true)
		expect.equal(visited.central >= 4, true)
	end
)

suite.test(
	"ShuttleService: recovery never reverses a moving train or docks at high speed",
	function()
		local moving = { distanceStuds = 770, speedMs = -3 }
		local state = Service.new(route, moving)
		expect.equal(state.target, 1)
		state.target = 2
		local _, command, correction = Service.step(state, route, moving, 1 / 30)
		expect.equal(command.brake, 1)
		expect.equal(command.throttle, 0)
		expect.equal(command.reverser, -1)
		expect.equal(correction, nil)
	end
)
