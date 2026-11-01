--!strict
--[[
	Display formatting rules for departure boards, the cab and timetables. Pure, so the rules are
	tested: a delay of 61 seconds must read "+1 min", not "+0 min" or "On time".

	Clock values are seconds since local midnight of the service day, as the server sends them.
	Civitas uses a 24-hour clock, the convention on European railway signage.
]]

local Format = {}

export type DelayTone = "onTime" | "early" | "late" | "severelyLate" | "unknown"

local DAY_S = 86400
-- Services within ±60 s of the timetable count as on time. This matches the tolerance most
-- European operators publish, and it stops the board flickering between "On time" and "+1 min".
local ON_TIME_TOLERANCE_S = 60
-- Beyond five minutes a delay stops being a timing note and becomes a service disruption.
local SEVERE_DELAY_S = 300

local function isFinite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- "HH:MM" for a seconds value. Wraps past midnight, so 90 000 s reads "01:00".
function Format.clock(seconds: number): string
	if not isFinite(seconds) then
		return "--:--"
	end
	local s = math.floor(seconds) % DAY_S
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	return string.format("%02d:%02d", h, m)
end

-- Delay text and its tone. Negative values are early running.
function Format.delay(deltaS: number): (string, DelayTone)
	if not isFinite(deltaS) then
		return "--", "unknown"
	end
	if math.abs(deltaS) <= ON_TIME_TOLERANCE_S then
		return "On time", "onTime"
	end
	local minutes = math.floor(math.abs(deltaS) / 60 + 0.5)
	if deltaS < 0 then
		return `{minutes} min early`, "early"
	end
	if deltaS > SEVERE_DELAY_S then
		return `+{minutes} min`, "severelyLate"
	end
	return `+{minutes} min`, "late"
end

-- Speed as a whole number in the requested unit. Speed is sent in metres per second (SI); only
-- the view converts. A negative input is treated as magnitude, since the reverser sets direction.
function Format.speedText(mps: number, unit: "kmh" | "mph"): string
	if not isFinite(mps) then
		return "---"
	end
	local magnitude = math.abs(mps)
	local value = if unit == "kmh" then magnitude * 3.6 else magnitude * 2.236936
	return tostring(math.floor(value + 0.5))
end

-- Journey or dwell duration as "m:ss". Negative input is clamped to zero.
function Format.duration(seconds: number): string
	if not isFinite(seconds) then
		return "--:--"
	end
	local total = math.max(0, math.floor(seconds + 0.5))
	return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

return Format
