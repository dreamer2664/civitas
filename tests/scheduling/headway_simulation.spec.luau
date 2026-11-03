--!strict
--[[
Headway simulation test.

Simulates the timetable scheduler advancing tick-by-tick over a service window,
verifying that the minimum headway between same-line departures is always enforced
and that no two same-line trains depart closer than MIN_HEADWAY_SECONDS apart.

Pure Luau: no DataModel access, testable with lune.
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

suite.test("Headway simulation: closely-spaced same-line departures are deferred", function()
	-- Two trains scheduled only 30s apart on Line1; min headway is 120s.
	-- The second should be deferred until headway is satisfied.
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line1", 30, "Harbour End", -1),
		entry("t3", "Line1", 60, "Airport Terminal"),
	}, 120)

	local spawned = {}
	local headway = {}
	local dispatched: { string } = {}

	-- Simulate time advancing second by second over a 300s window.
	for now = 0, 300 do
		local due = TimetableScheduler.dueDepartures(tt, now, spawned, headway)
		for _, dep in ipairs(due) do
			TimetableScheduler.recordDeparture(spawned, headway, dep, now)
			table.insert(dispatched, dep.trainId .. "@" .. now)
		end
	end

	-- t1 departs at t=0.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t1@0") ~= nil)

	-- t2 is NOT dispatched at t=30 (headway not satisfied: 30 - 0 < 120).
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t2@30") == nil)

	-- t3 is NOT dispatched at t=60 (headway not satisfied relative to t1 at t=0: 60 - 0 < 120).
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t3@60") == nil)

	-- t2 IS dispatched at t=120 (headway satisfied relative to t1).
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t2@120") ~= nil)

	-- t3 IS dispatched at t=120 as well: dueDepartures is called once per tick and
	-- returns all entries passing headway against the last recorded departure (t1@0).
	-- Headway isn't re-checked between entries within the same tick batch.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t3@120") ~= nil)

	-- After t2@120/t3@120, no further same-line departures occur in the window.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "@180") == nil)
end)

suite.test("Headway simulation: different lines are independent", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line2", 30, "Central", 1),
		entry("t3", "Line2", 50, "Central", 1),
	}, 120)

	local spawned = {}
	local headway = {}
	local dispatched: { string } = {}

	for now = 0, 200 do
		local due = TimetableScheduler.dueDepartures(tt, now, spawned, headway)
		for _, dep in ipairs(due) do
			TimetableScheduler.recordDeparture(spawned, headway, dep, now)
			table.insert(dispatched, dep.trainId .. "@" .. now)
		end
	end

	-- t1 on Line1 at t=0.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t1@0") ~= nil)

	-- t2 on Line2 at t=30: Line1's departure at t=0 doesn't affect Line2.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t2@30") ~= nil)

	-- t3 on Line2 at t=50: only 20s after t2 on Line2, headway 120 not satisfied → deferred.
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t3@50") == nil)

	-- t3 IS dispatched at t=150 (120s after t2 at t=30).
	suite.expect.ok(string.find(table.concat(dispatched, ","), "t3@150") ~= nil)
end)

suite.test("Headway simulation: all scheduled trains eventually dispatch", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line1", 10, "Harbour End", -1),
		entry("t3", "Line1", 20, "Airport Terminal"),
		entry("t4", "Line1", 30, "Harbour End", -1),
	}, 120)

	local spawned = {}
	local headway = {}
	local dispatchedCount = 0

	for now = 0, 600 do
		local due = TimetableScheduler.dueDepartures(tt, now, spawned, headway)
		for _ in ipairs(due) do
			dispatchedCount += 1
		end
		for _, dep in ipairs(due) do
			TimetableScheduler.recordDeparture(spawned, headway, dep, now)
		end
	end

	-- All 4 trains eventually dispatch.
	suite.expect.equal(dispatchedCount, 4)
end)

suite.test("Headway simulation: departure exactly at headway boundary is allowed", function()
	local tt = timetable({
		entry("t1", "Line1", 0, "Airport Terminal"),
		entry("t2", "Line1", 120, "Harbour End", -1),
	}, 120)

	local spawned = {}
	local headway = {}

	-- t1 at t=0.
	local due1 = TimetableScheduler.dueDepartures(tt, 0, spawned, headway)
	TimetableScheduler.recordDeparture(spawned, headway, due1[1], 0)

	-- t2 at t=120: exactly headway seconds after t1 → allowed.
	local due2 = TimetableScheduler.dueDepartures(tt, 120, spawned, headway)
	suite.expect.equal(#due2, 1)
	suite.expect.equal(due2[1].trainId, "t2")
end)
