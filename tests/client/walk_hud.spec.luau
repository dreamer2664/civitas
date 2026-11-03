--!strict
-- Scripted walk: a straight 200-stud walk east, with the compass maths checked at every 10-stud step.
-- This is pure maths. It does not spawn a character or draw anything: plates and the strip are only
-- drawn in Studio, which is not available to this check. What is tested is the visibility rule a
-- plate and its compass mark both depend on: a station is shown while its bearing is in the window.

local harness = require("../harness")
local Compass = require("../../src/client/UI/Hud/Compass")

harness.suite("hud walk")

-- World frame: X east, Z south. Compass: 0 = north, clockwise, degrees.
local function bearingFromTo(fromX: number, fromZ: number, toX: number, toZ: number): number
	return math.deg(math.atan2(toX - fromX, -(toZ - fromZ)))
end

local WALK_LENGTH = 200
local STEP = 10
local SPAN = 90
local STRIP_WIDTH = 1 -- the strip is a fraction of its own width, as CompassView uses it

-- Harbour sits north-east of the path; Lakeside sits directly behind a walker heading east.
local HARBOUR = { x = 150, z = -20 }
local LAKESIDE = { x = -100, z = 0 }

type Sample = { x: number, z: number, heading: number }

-- Walk the path and return, for each step: where the walker is and the heading it is facing.
local function scriptedWalk(): { Sample }
	local samples: { Sample } = {}
	local count = WALK_LENGTH // STEP
	for i = 0, count do
		local x = i * STEP
		local nextX = math.min(x + STEP, WALK_LENGTH)
		-- Heading comes from the direction of travel, not from a hard-coded value.
		local heading = bearingFromTo(x, 0, nextX, 0)
		table.insert(samples, { x = x, z = 0, heading = heading })
	end
	return samples
end

local function markFor(sample: Sample, station: { x: number, z: number }): number?
	local bearing = bearingFromTo(sample.x, sample.z, station.x, station.z)
	return Compass.offsetX(sample.heading, bearing, STRIP_WIDTH, SPAN)
end

harness.test("the scripted walk covers the full 200 studs in 10-stud steps", function()
	local samples = scriptedWalk()
	harness.equal(#samples, 21, "21 samples: start, 19 interior steps, end")
	harness.near(
		samples[#samples].x,
		WALK_LENGTH,
		1e-9,
		"the last sample is at the end of the walk"
	)
	harness.near(samples[1].heading, 90, 1e-9, "walking east faces 90 degrees (east)")
end)

harness.test(
	"harbour shows on the strip while it is ahead, and leaves it at the junction",
	function()
		local visible = 0
		local leftAt: number? = nil
		for _, sample in scriptedWalk() do
			local mark = markFor(sample, HARBOUR)
			if mark ~= nil then
				visible += 1
			elseif leftAt == nil and visible > 0 then
				leftAt = sample.x
			end
		end
		-- Harbour is inside the ±45° window while its bearing is at least 45° to the left, which happens
		-- from x = 0 up to x = 130 (14 samples); it falls off the left edge after that.
		harness.equal(visible, 14, "harbour visible at 14 of 21 samples")
		harness.equal(leftAt, 140, "harbour leaves the strip at the 140-stud sample")
	end
)

harness.test(
	"harbour's mark starts just left of centre and moves steadily to the left edge",
	function()
		local previous: number? = nil
		local first: number? = nil
		for _, sample in scriptedWalk() do
			local mark = markFor(sample, HARBOUR)
			if mark ~= nil then
				if first == nil then
					first = mark
				end
				if previous ~= nil then
					harness.equal(
						mark < previous,
						true,
						"each visible step moves the mark further left"
					)
				end
				previous = mark
			end
		end
		-- At the start the bearing to Harbour is atan2(150, 20) - 90 = -7.595 degrees: a small left offset.
		-- With width 1 and a 90 degree window, a fraction is degrees / 90.
		local expected = (math.deg(math.atan2(150, 20)) - 90) / 90
		harness.near(first :: number, expected, 1e-6, "first mark matches the bearing maths")
	end
)

harness.test("lakeside stays hidden the whole walk because it is behind the walker", function()
	for _, sample in scriptedWalk() do
		harness.equal(
			markFor(sample, LAKESIDE),
			nil,
			"lakeside is never on the strip while walking east"
		)
	end
end)

harness.test("the walk ends with harbour off the strip", function()
	local samples = scriptedWalk()
	harness.equal(
		markFor(samples[#samples], HARBOUR),
		nil,
		"at 200 studs harbour is behind-right, off the strip"
	)
end)
