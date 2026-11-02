--!strict
--[[
Signals.luau — signal placement config (data, not code).

One stop signal per station on Line 1, protecting the block from that station to the next.
Aspect logic lives in src/shared/Rail/Signalling.luau (pure, unit-testable).

Block layout: station N's signal protects block [stationN.distance, stationN+1.distance).
The last station (Harbour End) is the terminus — its signal protects nothing beyond.

Owned by CODE · vector (rail system). Signal IDs are vector's domain.
--]]

local Signals = {}

-- Line 1 — stop signals at each station, protecting the block ahead.
Signals.Line1 = {
	{
		signalId = "L1-S-Airport",
		stationId = "Airport Terminal",
		distanceStuds = 0,
		blockTo = "Hillside Halt",
	},
	{
		signalId = "L1-S-Hillside",
		stationId = "Hillside Halt",
		distanceStuds = 1649,
		blockTo = "Riverside",
	},
	{
		signalId = "L1-S-Riverside",
		stationId = "Riverside",
		distanceStuds = 3844,
		blockTo = "Civitas Central",
	},
	{
		signalId = "L1-S-Central",
		stationId = "Civitas Central",
		distanceStuds = 5137,
		blockTo = "Old Town",
	},
	{
		signalId = "L1-S-OldTown",
		stationId = "Old Town",
		distanceStuds = 6286,
		blockTo = "Harbour Gate",
	},
	{
		signalId = "L1-S-HarbourGate",
		stationId = "Harbour Gate",
		distanceStuds = 8033,
		blockTo = "Container Terminal",
	},
	{
		signalId = "L1-S-Container",
		stationId = "Container Terminal",
		distanceStuds = 9521,
		blockTo = "Harbour End",
	},
	{
		signalId = "L1-S-HarbourEnd",
		stationId = "Harbour End",
		distanceStuds = 10652,
		blockTo = nil,
	}, -- terminus
}

return Signals
