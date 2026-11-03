--!strict
local Checks = require("../../src/server/Walkability/StreetChecks")
local Audit = require("../../src/server/Walkability/OrientedAudit")
local passed = 0
local function test(name: string, f: () -> ())
	f()
	passed += 1
	print("PASS " .. name)
end
local intersection = { x = 0, z = 0, widthX = 30, widthZ = 8.5, radius = 11 }
local function ground(): Audit.Part
	return {
		id = "base",
		name = "CollidableGround",
		x = 0,
		y = -1,
		z = 0,
		sx = 200,
		sy = 2,
		sz = 200,
		rx = 0,
		ry = 0,
		rz = 0,
		shape = "Block",
		collide = true,
		anchored = true,
		walk = true,
	}
end

test("four crossings follow sidewalk desire lines, not carriageway centre", function()
	local crossings = Checks.crossings(intersection, 3.5)
	assert(#crossings == 4, "street crossing regression")
	assert(
		crossings[1].route[1].x == -16.75 and crossings[1].route[1].z == -6,
		"street crossing regression"
	)
	assert(
		crossings[3].route[1].x == -16.75 and crossings[3].route[1].z == -6,
		"street crossing regression"
	)
end)
test("asymmetric widths are not swapped", function()
	local crossings = Checks.crossings(intersection, 3.5)
	assert(crossings[1].route[2].x - crossings[1].route[1].x == 33.5, "street crossing regression")
	assert(crossings[3].route[2].z - crossings[3].route[1].z == 12, "street crossing regression")
end)
test("off-centre crossing blocker cannot hide behind a centreline pass", function()
	local wall = ground()
	wall.id, wall.name, wall.walk = "wall", "wall", false
	wall.x, wall.z, wall.y, wall.sx, wall.sz, wall.sy = 0, -6, 3, 0.1, 1, 6
	local parts = { ground(), wall }
	assert(
		#Audit.route(parts, { { x = -16.75, z = 0 }, { x = 16.75, z = 0 } }, 0).defects == 0,
		"street crossing regression"
	)
	assert(
		#Audit.route(parts, Checks.crossings(intersection, 3.5)[1].route, 0).defects > 0,
		"street crossing regression"
	)
end)
print(string.format("%d street regression tests passed", passed))
