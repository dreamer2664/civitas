--!strict
-- Compass strip maths: where a bearing lands on the strip, and how the window wraps at 360 degrees.

local harness = require("../harness")
local Compass = require("../../src/client/UI/Hud/Compass")

harness.suite("compass")

harness.test("a bearing equal to the heading sits at the centre of the strip", function()
	local x = Compass.offsetX(120, 120, 400, 90)
	harness.near(x :: number, 0, 1e-9)
end)

harness.test("a bearing at the edge of the window sits at the strip edge", function()
	-- span 90 means ±45 degrees; a bearing 45 to the right is the right edge (width / 2 = 200 px).
	harness.near(Compass.offsetX(0, 45, 400, 90) :: number, 200, 1e-9)
	harness.near(Compass.offsetX(0, -45, 400, 90) :: number, -200, 1e-9)
end)

harness.test("a bearing outside the window is not drawn", function()
	harness.equal(Compass.offsetX(0, 90, 400, 90), nil)
	harness.equal(Compass.offsetX(0, 180, 400, 90), nil)
end)

harness.test("the window wraps across north: heading 350 shows bearing 10 to the right", function()
	local x = Compass.offsetX(350, 10, 400, 90) :: number
	harness.near(x, 200 * 20 / 45, 1e-9, "20 degrees right of centre on a 90 degree window")
end)

harness.test(
	"the wrap also works the other way: heading 10 shows bearing 350 to the left",
	function()
		local x = Compass.offsetX(10, 350, 400, 90) :: number
		harness.near(x, -200 * 20 / 45, 1e-9)
	end
)

harness.test("wrap normalises any angle into [-180, 180)", function()
	harness.near(Compass.wrap(0), 0, 1e-9)
	harness.near(Compass.wrap(180), -180, 1e-9)
	harness.near(Compass.wrap(-180), -180, 1e-9)
	harness.near(Compass.wrap(725), 5, 1e-9)
	harness.near(Compass.wrap(-725), -5, 1e-9)
end)

harness.test("a non-positive window is refused with a message", function()
	harness.raises(function()
		Compass.offsetX(0, 0, 0, 90)
	end, "positive width and span")
end)
