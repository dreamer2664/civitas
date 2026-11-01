--!strict
local Audit = require("../../src/server/Walkability/OrientedAudit")
local function part(): Audit.Part
	return {
		id = "floor",
		name = "CollidableGround",
		x = 800,
		y = -1,
		z = 0,
		sx = 1600,
		sy = 2,
		sz = 20,
		rx = 0,
		ry = 0,
		rz = 0,
		shape = "Block",
		collide = true,
		anchored = true,
		walk = true,
	}
end
local route = { { x = 2, z = 0 }, { x = 1598, z = 0 } }
local bounds = { minX = 0, maxX = 1600, minZ = -10, maxZ = 10 }
local passed = 0
local function test(name: string, f: () -> ())
	f()
	passed += 1
	print("PASS " .. name)
end
test("oriented audit exact base coverage", function()
	assert(Audit.sealed({ part() }, bounds), "closed base should contain domain")
	assert(#Audit.route({ part() }, route, 1500).defects == 0, "sealed route should pass")
end)
test("yaw 90 clipping is exact", function()
	local p = part()
	p.x = 0
	p.sx = 2
	p.sz = 10
	p.ry = 90
	local low, high = Audit.clip(p, { x = -10, z = 0 }, { x = 10, z = 0 }, 0)
	assert(low ~= nil and high ~= nil, "expected intersection")
	assert(math.abs(low - 0.25) < 1e-8 and math.abs(high - 0.75) < 1e-8, "wrong yaw transform")
end)
test("subsample thin wall is detected", function()
	local wall = part()
	wall.id = "wall"
	wall.name = "wall"
	wall.walk = false
	wall.sx = 0.001
	wall.y = 3
	wall.sy = 6
	assert(
		#Audit.route({ part(), wall }, route, 1500).defects > 0,
		"thin wall cannot hide between samples"
	)
end)
test("noncollidable walk surface fails despite sealed fallback base", function()
	local visual = part()
	visual.id = "visual"
	visual.name = "visual"
	visual.collide = false
	visual.y = 0.5
	local result = Audit.route({ part(), visual }, route, 1500)
	assert(
		#result.defects > 0 and result.defects[1].code == "NONCOLLIDABLE_SURFACE",
		"visual false floor must be rejected"
	)
end)
test("1.21 step fails", function()
	local raised = part()
	raised.id = "raised"
	raised.name = "raised"
	raised.x = 1200
	raised.sx = 800
	raised.y = 0.605
	raised.sy = 1.21
	local result = Audit.route({ part(), raised }, route, 1500)
	assert(result.maxStep > 1.2 and #result.defects > 0, "over-limit step must fail")
end)
test("footprint support cannot use narrow centerline", function()
	local narrow = part()
	narrow.sz = 1
	assert(#Audit.route({ narrow }, route, 1500).defects > 0, "unsupported foot width must fail")
end)
test("0.01 stud hole cannot hide between samples", function()
	local left, right = part(), part()
	left.x = 50
	left.sx = 100
	right.x = 850.005
	right.sx = 1499.99
	assert(#Audit.route({ left, right }, route, 1500).defects > 0, "narrow hole must fail")
end)
test("ground with missing collision cannot establish seal", function()
	local floor = part()
	floor.collide = false
	assert(not Audit.sealed({ floor }, bounds), "noncollidable base is no proof")
end)
print(string.format("%d oriented Luau tests passed, 0 failed", passed))
