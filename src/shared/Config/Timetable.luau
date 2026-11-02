--!strict
--[[
Timetable.luau — scheduled train departures (data, not code).

departAt is seconds after service start. direction: 1 = forward along the line
(Airport Terminal -> Harbour End), -1 = backward (Harbour End -> Airport Terminal).

A train can only be spawned if its scheduled trainId is not already active — the
scheduler enforces this and the caller should also guard against duplicates.

Owned by CODE · vector (rail system). Timetable keys are vector's domain.
--]]

local Timetable = {}

-- Line 1 — "Coastal Spine": scheduled departures.
-- Initial service: one train every 5 minutes from each terminal.
Timetable.Line1 = {
	{
		trainId = "train-1",
		lineId = "Line1",
		departAt = 0,
		startStationId = "Airport Terminal",
		direction = 1,
	},
	{
		trainId = "train-2",
		lineId = "Line1",
		departAt = 300,
		startStationId = "Harbour End",
		direction = -1,
	},
	{
		trainId = "train-3",
		lineId = "Line1",
		departAt = 600,
		startStationId = "Airport Terminal",
		direction = 1,
	},
	{
		trainId = "train-4",
		lineId = "Line1",
		departAt = 900,
		startStationId = "Harbour End",
		direction = -1,
	},
}

-- Minimum headway between trains on the same line (seconds). The scheduler will
-- delay a departure if a previous train hasn't cleared this headway yet.
Timetable.MIN_HEADWAY_SECONDS = 120

return Timetable
