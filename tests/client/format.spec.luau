--!strict
-- Display rules for the departure board, the cab and the timetable. Each expected string is what
-- a passenger should read, so a change here is a visible change to the product.

local harness = require("../harness")
local Format = require("../../src/client/UI/Format")

harness.suite("format")

harness.test("clock is 24-hour HH:MM and wraps past midnight", function()
	harness.equal(Format.clock(0), "00:00")
	harness.equal(Format.clock(3599), "00:59")
	harness.equal(Format.clock(86399), "23:59")
	harness.equal(Format.clock(90000), "01:00", "past midnight wraps to the next service day")
	harness.equal(Format.clock(-60), "23:59", "a negative offset wraps backwards")
end)

harness.test("clock shows a placeholder for NaN and infinity, never a bogus time", function()
	harness.equal(Format.clock(0 / 0), "--:--")
	harness.equal(Format.clock(math.huge), "--:--")
end)

harness.test("delay within ±60 s reads On time", function()
	local text, tone = Format.delay(0)
	harness.equal(text, "On time")
	harness.equal(tone, "onTime")
	local t60, tone60 = Format.delay(60)
	harness.equal(t60, "On time")
	harness.equal(tone60, "onTime")
end)

harness.test("a 61 second delay is +1 min and late, not On time", function()
	local text, tone = Format.delay(61)
	harness.equal(text, "+1 min")
	harness.equal(tone, "late")
end)

harness.test("early running is shown as a number of minutes early", function()
	local text, tone = Format.delay(-180)
	harness.equal(text, "3 min early")
	harness.equal(tone, "early")
end)

harness.test("delays above five minutes are severe", function()
	local atFive, toneAtFive = Format.delay(300)
	harness.equal(atFive, "+5 min")
	harness.equal(toneAtFive, "late", "exactly five minutes is still late")
	local over, toneOver = Format.delay(301)
	harness.equal(over, "+5 min")
	harness.equal(toneOver, "severelyLate")
end)

harness.test("an unknown delay reads as unknown", function()
	local text, tone = Format.delay(0 / 0)
	harness.equal(text, "--")
	harness.equal(tone, "unknown")
end)

harness.test("speed converts from metres per second to whole km/h and mph", function()
	harness.equal(Format.speedText(100 / 3.6, "kmh"), "100")
	harness.equal(Format.speedText(10, "kmh"), "36")
	harness.equal(Format.speedText(10, "mph"), "22")
end)

harness.test(
	"speed is shown as magnitude; reverse direction does not print a minus sign",
	function()
		harness.equal(Format.speedText(-10, "kmh"), "36")
	end
)

harness.test("speed shows a placeholder for invalid input", function()
	harness.equal(Format.speedText(0 / 0, "kmh"), "---")
end)

harness.test("duration formats as m:ss and clamps negatives to zero", function()
	harness.equal(Format.duration(0), "0:00")
	harness.equal(Format.duration(75.4), "1:15")
	harness.equal(Format.duration(3599), "59:59")
	harness.equal(Format.duration(-5), "0:00")
end)
