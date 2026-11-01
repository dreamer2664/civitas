--!strict
-- Unit tests for src/shared/Rail/Kinematics.luau (pure maths, runs under lune without Studio).

local suite = require("../support/suite")
local expect = suite.expect
local Kinematics = require("../../src/shared/Rail/Kinematics")

local function config(overrides)
	local c = {
		massKg = 100000,
		maxTractiveEffortN = 100000,
		serviceBrakeForceN = 80000,
		emergencyBrakeForceN = 160000,
		maxSpeedMs = 30,
		rollingResistanceN = 2000,
		airResistanceCoeff = 30,
	}
	if overrides then
		for k, v in pairs(overrides) do
			c[k] = v
		end
	end
	return c
end

local function fullMotoring()
	return { tractive = 1, serviceBrake = 0, emergencyBrake = false }
end

local function coasting()
	return { tractive = 0, serviceBrake = 0, emergencyBrake = false }
end

suite.test("Kinematics: constant acceleration from rest matches v = a * t", function()
	local c = config({
		massKg = 1000,
		maxTractiveEffortN = 10000,
		maxSpeedMs = 100,
		rollingResistanceN = 0,
		airResistanceCoeff = 0,
	})
	local state = Kinematics.stopped(0)
	local controls = fullMotoring()
	for _ = 1, 5 do
		state = Kinematics.integrate(state, 1, controls, c, 0)
	end
	-- a = 10000 N / 1000 kg = 10 m/s^2; after 5 s: v = 50 m/s
	expect.near(state.speedMs, 50, 0.01)
	-- distance = 0.5 * a * t^2 = 125 m -> studs
	expect.near(state.distanceStuds, 125 * (1 / 0.28), 0.5)
end)

suite.test("Kinematics: speed is clamped at maxSpeedMs", function()
	local c = config({ maxSpeedMs = 25 })
	local state = Kinematics.stopped(0)
	local controls = fullMotoring()
	for _ = 1, 100 do
		state = Kinematics.integrate(state, 1, controls, c, 0)
	end
	expect.ok(state.speedMs <= c.maxSpeedMs + 0.01)
end)

suite.test("Kinematics: braking distance formula matches d = v^2 / (2 * dec)", function()
	local v = 20
	local brakeForce = 5000
	local mass = 1000
	local dec = brakeForce / mass -- 5 m/s^2
	local expected = (v * v) / (2 * dec) -- 40 m
	expect.near(Kinematics.brakingDistance(v, brakeForce, mass, 0), expected, 0.01)
end)

suite.test("Kinematics: uphill grade shortens braking distance, downhill lengthens it", function()
	local v = 20
	local brakeForce = 5000
	local mass = 1000
	local flat = Kinematics.brakingDistance(v, brakeForce, mass, 0)
	local uphill = Kinematics.brakingDistance(v, brakeForce, mass, 0.1)
	local downhill = Kinematics.brakingDistance(v, brakeForce, mass, -0.1)
	expect.ok(uphill < flat)
	expect.ok(downhill > flat)
end)

suite.test("Kinematics: emergency brake stops in less distance than service brake", function()
	local state = { speedMs = 30, distanceStuds = 0 }
	local c = config()
	local service = Kinematics.stopDistanceStuds(
		state,
		{ tractive = 0, serviceBrake = 1, emergencyBrake = false },
		c,
		0
	)
	local emergency = Kinematics.stopDistanceStuds(
		state,
		{ tractive = 0, serviceBrake = 0, emergencyBrake = true },
		c,
		0
	)
	expect.ok(emergency < service)
	expect.ok(emergency > 0)
end)

suite.test("Kinematics: coasting slows the train down (resistance)", function()
	local c = config()
	local state = { speedMs = 20, distanceStuds = 0 }
	state = Kinematics.integrate(state, 5, coasting(), c, 0)
	expect.ok(state.speedMs < 20)
	expect.ok(state.speedMs >= 0)
end)

suite.test("Kinematics: stopped state has zero speed and the given position", function()
	local state = Kinematics.stopped(42 * (1 / 0.28))
	expect.equal(state.speedMs, 0)
	expect.near(state.distanceStuds, 42 * (1 / 0.28), 1e-9)
end)

suite.test("Kinematics: default config is a self-consistent EMU target", function()
	local c = Kinematics.defaultConfig()
	expect.ok(c.massKg > 0)
	expect.ok(c.maxTractiveEffortN > 0)
	expect.ok(c.emergencyBrakeForceN >= c.serviceBrakeForceN)
	expect.ok(c.maxSpeedMs > 0)
	local accel =
		Kinematics.computeAcceleration({ speedMs = 0, distanceStuds = 0 }, fullMotoring(), c, 0)
	expect.ok(accel > 0)
	expect.ok(accel < c.maxTractiveEffortN / c.massKg + 1) -- resistance reduces it slightly
end)
