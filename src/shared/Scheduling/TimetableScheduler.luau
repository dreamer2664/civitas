--!strict
--[[
TimetableScheduler.luau — pure timetable dispatch logic.

Given the timetable, the current time since service start, and the set of already-spawned
train IDs, returns the list of departures that are due now. Pure Luau: no DataModel access,
testable with lune.

Dispatch rules:
  - A departure is due when nowSeconds >= departAt.
  - A departure is skipped if its trainId is already spawned.
  - MIN_HEADWAY_SECONDS: if the previous departure on the same line hasn't had at least
    this many seconds since its own departure, the current departure is deferred (not
    skipped — it will be due on a later tick).
--]]

export type TimetableEntry = {
	trainId: string,
	lineId: string,
	departAt: number,
	startStationId: string,
	direction: number,
}

export type TimetableData = any -- { [lineId: string]: { TimetableEntry }, MIN_HEADWAY_SECONDS: number }

local TimetableScheduler = {}

-- Return entries due at nowSeconds that aren't already spawned and meet headway.
-- headwayLastDeparture: lineId -> time of last dispatched departure on that line.
function TimetableScheduler.dueDepartures(
	timetable: TimetableData,
	nowSeconds: number,
	spawnedTrainIds: { [string]: boolean },
	headwayLastDeparture: { [string]: number }
): { TimetableEntry }
	local due: { TimetableEntry } = {}

	for lineId, entries in pairs(timetable) do
		if lineId ~= "MIN_HEADWAY_SECONDS" then
			for _, entry in ipairs(entries) do
				-- Skip if already spawned.
				if spawnedTrainIds[entry.trainId] then
					continue
				end

				-- Skip if not yet due.
				if nowSeconds < entry.departAt then
					continue
				end

				-- Headway check: enough time since last departure on this line?
				local lastDepart = headwayLastDeparture[lineId]
				local minHeadway = timetable.MIN_HEADWAY_SECONDS
				if lastDepart ~= nil and (nowSeconds - lastDepart) < minHeadway then
					continue -- defer until headway is satisfied
				end

				table.insert(due, entry)
			end
		end
	end

	return due
end

-- Record a departure as dispatched: mark trainId spawned and update headway time.
function TimetableScheduler.recordDeparture(
	spawnedTrainIds: { [string]: boolean },
	headwayLastDeparture: { [string]: number },
	entry: TimetableEntry,
	nowSeconds: number
)
	spawnedTrainIds[entry.trainId] = true
	headwayLastDeparture[entry.lineId] = nowSeconds
end

return TimetableScheduler
