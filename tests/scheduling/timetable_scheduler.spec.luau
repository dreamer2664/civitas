--!strict
--[[
TimetableScheduler unit tests.
--]]

local suite = require("../support/suite")
local TimetableScheduler = require("../../src/shared/Scheduling/TimetableScheduler")

local function entry(trainId, lineId, departAt, startStationId, direction)
	return {
		trainId = trainId,
		lineId = lineId,
		departAt = departAt,
		startStationId = startStationId,
		direction = direction or 1,
	}
end

local function timetable(entries, minHeadway)
	local t = {}
	for _, e in ipairs(entries) do
		t[e.lineId] = t[e.lineId] or {}
		table.insert(t[e.lineId], e)
	end
	t.MIN_HEADWAY_SECONDS = minHeadway or 120
	return t
end

suite.test("TimetableScheduler: entries due at nowSeconds are returned", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line1", 300, "Harbour End", -1),
		entry("t3", "Line1", 600, "Airport Terminal"),
	}, 120)

	local spawned = {}
	local headway = {}
	local due = TimetableScheduler.dueDepartures(tt, 0, spawned, headway)

	suite.expect.equal(#due, 1)
	suite.expect.equal(due[1].trainId, "t1")
end)

suite.test("TimetableScheduler: entries not yet due are skipped", function()
	local tt = timetable({
		entry("t1", "Line1", 300, "Airport Terminal"),
	}, 120)

	local spawned = {}
	local headway = {}
	local due = TimetableScheduler.dueDepartures(tt, 100, spawned, headway)

	suite.expect.equal(#due, 0)
end)

suite.test("TimetableScheduler: already-spawned train IDs are skipped", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
	}, 120)

	local spawned = { t1 = true }
	local headway = {}
	local due = TimetableScheduler.dueDepartures(tt, 0, spawned, headway)

	suite.expect.equal(#due, 0)
end)

suite.test("TimetableScheduler: headway defers departures too soon after previous", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line1", 60, "Harbour End", -1), -- only 60s after t1, min headway 120
	}, 120)

	local spawned = {}
	local headway = {}

	-- t1 is due at t=0
	local due1 = TimetableScheduler.dueDepartures(tt, 0, spawned, headway)
	suite.expect.equal(#due1, 1)
	TimetableScheduler.recordDeparture(spawned, headway, due1[1], 0)

	-- t2 is NOT due at t=60 because headway not satisfied (60 < 120)
	local due2 = TimetableScheduler.dueDepartures(tt, 60, spawned, headway)
	suite.expect.equal(#due2, 0)

	-- t2 IS due at t=120 (headway satisfied)
	local due3 = TimetableScheduler.dueDepartures(tt, 120, spawned, headway)
	suite.expect.equal(#due3, 1)
	suite.expect.equal(due3[1].trainId, "t2")
end)

suite.test("TimetableScheduler: different lines have independent headways", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line2", 30, "Central", 1),
	}, 120)

	local spawned = {}
	local headway = {}

	-- Dispatch t1 on Line1 at t=0.
	local due1 = TimetableScheduler.dueDepartures(tt, 0, spawned, headway)
	suite.expect.equal(#due1, 1)
	TimetableScheduler.recordDeparture(spawned, headway, due1[1], 0)

	-- At t=30, t2 on Line2 is due: Line1's headway doesn't affect Line2.
	local due2 = TimetableScheduler.dueDepartures(tt, 30, spawned, headway)
	suite.expect.equal(#due2, 1)
	suite.expect.equal(due2[1].trainId, "t2")
end)

suite.test("TimetableScheduler: recordDeparture marks train and updates headway", function()
	local spawned = {}
	local headway = {}
	local e = entry("t1", "Line1", 100, "Airport Terminal")

	TimetableScheduler.recordDeparture(spawned, headway, e, 100)

	suite.expect.ok(spawned["t1"] == true)
	suite.expect.equal(headway["Line1"], 100)
end)
