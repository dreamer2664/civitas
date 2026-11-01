--!strict
-- Unit tests for src/shared/Rail/Spline.luau (pure maths, runs under lune without Studio).

local suite = require("../support/suite")
local expect = suite.expect
local Spline = require("../../src/shared/Rail/Spline")

local function vec(x: number, y: number, z: number)
	return Spline.vec3(x, y, z)
end

local function nearVec(
	actual: { x: number, y: number, z: number },
	expectedX: number,
	expectedY: number,
	expectedZ: number,
	tolerance: number
)
	expect.near(actual.x, expectedX, tolerance)
	expect.near(actual.y, expectedY, tolerance)
	expect.near(actual.z, expectedZ, tolerance)
end

suite.test("Spline: two points give a straight line of exactly their distance", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	expect.equal(#spline.controlPoints, 2)
	expect.near(spline.totalLength, 100, 0.01)
end)

suite.test("Spline: arc length interpolates endpoints exactly", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local start = spline:sampleArcLength(0).position
	local finish = spline:sampleArcLength(spline.totalLength).position
	nearVec(start, 0, 0, 0, 1e-6)
	nearVec(finish, 100, 0, 0, 1e-6)
end)

suite.test("Spline: sample(t) covers the full spline", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	nearVec(spline:sample(0), 0, 0, 0, 1e-6)
	nearVec(spline:sample(1), 100, 0, 0, 1e-6)
	nearVec(spline:sample(0.5), 50, 0, 0, 0.5)
end)

suite.test("Spline: tangent along a straight line is the line direction", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local tan = spline:tangent(0.5)
	-- Catmull-Rom tangents are raw derivatives: direction is exact, magnitude is not unit.
	expect.near(tan.y, 0, 1e-6)
	expect.near(tan.z, 0, 1e-6)
	expect.ok(tan.x > 0)
end)

suite.test("Spline: arc length matches independent numerical integration", function()
	-- Quarter circle of radius 100, five control points at 0..90 degrees.
	local r = 100
	local points = {}
	for k = 0, 4 do
		local angle = (k / 4) * (math.pi / 2)
		table.insert(points, vec(r * math.cos(angle), r * math.sin(angle), 0))
	end
	local spline = Spline.new(points)

	-- Brute force: sample the curve densely and sum chords.
	local samples = 2000
	local brute = 0
	local previous = spline:sample(0)
	for k = 1, samples do
		local point = spline:sample(k / samples)
		brute += math.sqrt(
			(point.x - previous.x) ^ 2 + (point.y - previous.y) ^ 2 + (point.z - previous.z) ^ 2
		)
		previous = point
	end

	local expected = math.pi * r / 2
	expect.near(spline.totalLength, expected, 2) -- spline length ~ quarter circle
	expect.near(spline.totalLength, brute, 0.02 * brute) -- table matches direct integration
end)

suite.test("Spline: arcLengthToT then lengthTo round-trips", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0), vec(100, 100, 0) })
	for s = 0, spline.totalLength, spline.totalLength / 8 do
		local mapping = spline:arcLengthToT(s)
		local back = spline:lengthTo(mapping.segmentIndex, mapping.t)
		expect.near(back, s, 0.5)
	end
end)

suite.test("Spline: sampleArcLength is monotonic in position along a line", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local p25 = spline:sampleArcLength(25).position
	local p75 = spline:sampleArcLength(75).position
	expect.near(p25.x, 25, 0.01)
	expect.near(p75.x, 75, 0.01)
	expect.ok(p75.x > p25.x)
end)

suite.test("Spline: distanceToPoint snaps to the nearest point on a line", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local result = spline:distanceToPoint(vec(50, 5, 0))
	expect.near(result.distance, 5, 1)
	expect.near(result.s, 50, 2)
	nearVec(result.position, 50, 0, 0, 1)
end)

suite.test("Spline: degenerate all-points-identical spline is safe", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(0, 0, 0), vec(0, 0, 0) })
	expect.near(spline.totalLength, 0, 1e-9)
	local s = spline:sampleArcLength(0).position
	nearVec(s, 0, 0, 0, 1e-6)
	local d = spline:distanceToPoint(vec(10, 10, 10))
	expect.near(d.distance, math.sqrt(300), 1)
end)

suite.test("Spline: duplicate adjacent control points do not crash", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(0, 0, 0), vec(100, 0, 0) })
	expect.ok(spline.totalLength > 0)
	expect.ok(spline.totalLength < 200)
	local mid = spline:sampleArcLength(spline.totalLength / 2).position
	expect.ok(mid.x >= 0 and mid.x <= 100)
end)

suite.test("Spline: 180-degree reversal backtracks exactly", function()
	-- Points go out and back along the same line, so total length is ~200 and the midpoint
	-- returns to the origin.
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0), vec(0, 0, 0) })
	expect.near(spline.totalLength, 200, 1)
	local mid = spline:sampleArcLength(100).position
	nearVec(mid, 100, 0, 0, 1)
	local end_ = spline:sampleArcLength(200).position
	nearVec(end_, 0, 0, 0, 1)
end)

suite.test("Spline: endpoint behaviour clamps at the ends", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local before = spline:sampleArcLength(-10).position
	local after = spline:sampleArcLength(spline.totalLength + 10).position
	nearVec(before, 0, 0, 0, 1e-6)
	nearVec(after, 100, 0, 0, 1e-6)
end)

suite.test("Spline: closed spline wraps and endpoints coincide", function()
	local spline =
		Spline.new({ vec(0, 0, 0), vec(100, 0, 0), vec(100, 100, 0), vec(0, 100, 0) }, true)
	expect.ok(spline.totalLength > 350 and spline.totalLength < 450)
	expect.equal(#spline.segments, 4)
	local start = spline:sampleArcLength(0).position
	local finish = spline:sampleArcLength(spline.totalLength).position
	nearVec(start, finish.x, finish.y, finish.z, 1e-6)
end)

suite.test("Spline: addPoint grows the control point list and rebuilds", function()
	local spline = Spline.new({ vec(0, 0, 0), vec(100, 0, 0) })
	local before = spline.totalLength
	spline:addPoint(vec(100, 100, 0))
	expect.equal(#spline.controlPoints, 3)
	expect.ok(spline.totalLength > before)
end)

suite.test("Spline: empty spline has zero length and safe samples", function()
	local spline = Spline.new({})
	expect.near(spline.totalLength, 0, 1e-9)
	local sample = spline:sampleArcLength(0)
	expect.equal(sample.position.x, 0)
	expect.equal(sample.tangent.x, 0)
end)
