--!strict
local Audit = require("../../src/server/Walkability/Audit")
local Spawn = require("../../src/server/Spawn/Plan")
local passed = 0
local function box(x0: number, x1: number, z0: number, z1: number, top: number): Audit.Box
	return {
		id = "fixture",
		x0 = x0,
		x1 = x1,
		z0 = z0,
		z1 = z1,
		bottom = -2,
		top = top,
		collide = true,
		walk = true,
	}
end
local function test(name: string, f: () -> ())
	f()
	passed += 1
	print("PASS " .. name)
end
local bounds = { x0 = 0, x1 = 1600, z0 = 0, z1 = 10 }
local route = { { x = 2, z = 5 }, { x = 1598, z = 5 } }
local floor = box(0, 1600, 0, 10, 0)
test("sealed 1596-stud fixture", function()
	assert(#Audit.seal({ floor }, bounds) == 0, "fixture expectation failed")
	local defects, length = Audit.route({ floor }, route, 1500)
	assert(#defects == 0 and length == 1596, "fixture expectation failed")
end)
test("0.01 stud hole missed by coarse sampling is detected", function()
	local boxes = { box(0, 100, 0, 10, 0), box(100.01, 1600, 0, 10, 0) }
	assert(#Audit.seal(boxes, bounds) == 1, "fixture expectation failed")
	assert(#Audit.route(boxes, route, 1500) > 0, "fixture expectation failed")
end)
test("noncollidable floor fails", function()
	local b = box(0, 1600, 0, 10, 0)
	b.collide = false
	assert(#Audit.seal({ b }, bounds) == 1, "fixture expectation failed")
end)
test("1.21 stud curb fails", function()
	assert(
		#Audit.route({ box(0, 800, 0, 10, 0), box(800, 1600, 0, 10, 1.21) }, route, 1500) > 0,
		"fixture expectation failed"
	)
end)
test("1.2 stud boundary is permitted", function()
	assert(
		#Audit.route({ box(0, 800, 0, 10, 0), box(800, 1600, 0, 10, 1.2) }, route, 1500) == 0,
		"fixture expectation failed"
	)
end)
test("thin invisible wall fails", function()
	local wall = box(800, 800.001, 0, 10, 8)
	wall.walk = false
	wall.bottom = 0
	assert(#Audit.route({ floor, wall }, route, 1500) > 0, "fixture expectation failed")
end)
test("overhead canopy does not block body", function()
	local canopy = box(800, 810, 0, 10, 12)
	canopy.walk = false
	canopy.bottom = 8
	assert(#Audit.route({ floor, canopy }, route, 1500) == 0, "fixture expectation failed")
end)
test("decorative noncollidable detail is ignored", function()
	local prop = box(800, 801, 0, 10, 8)
	prop.walk = false
	prop.collide = false
	assert(#Audit.route({ floor, prop }, route, 1500) == 0, "fixture expectation failed")
end)
test("spawn requires footprint support", function()
	assert(Spawn.validate({ floor }, { x = 2, z = 5 }), "fixture expectation failed")
	assert(not Spawn.validate({ floor }, { x = 0, z = 5 }), "fixture expectation failed")
	assert(not Spawn.validate({}, { x = 2, z = 5 }), "fixture expectation failed")
end)
test("short route rejected", function()
	assert(
		#Audit.route({ floor }, { { x = 2, z = 5 }, { x = 20, z = 5 } }, 1500) == 1,
		"fixture expectation failed"
	)
end)
print(string.format("%d passed, 0 failed (synthetic fixtures, NOT city acceptance)", passed))
