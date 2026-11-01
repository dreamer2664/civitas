--!strict
--[[
RemoteContract.luau — PROVISIONALLY RATIFIED remote table (Manager A, 2026-11-01).

OWNERSHIP: src/shared/Contracts/** is Manager A-owned. This file is PROVISIONALLY RATIFIED:
shape of TrainState is now FROZEN — additive changes only, no renames, no field removals.
CODE · vector implements the server side; CODE · lumen implements the client side. Neither
invents its own field names.

CONTENTS: data only — remote names, directions, request/response shape references and per-player
rate limits. No implementation. Every remote is validated server-side on type, finite numbers,
bounds, rate limit, player state and authority (STANDARDS.md; Remote events/security resource).

RATE LIMITS are per player: maxPerSecond sustained, burst allowed.

TICK BUDGET: the server simulation runs at a fixed 30 Hz tick (~33.3 ms per tick). All of
train integration, signal evaluation, scheduling and boarding/alighting must complete within
one tick. Remote publication (Train.State, Signal.Observe) happens once per tick and is
accounted inside that budget. A client that cannot keep up is throttled, not allowed to starve
the schedule feed for other players.
--]]

export type RemoteDirection = "ClientToServer" | "ServerToClient"

export type RemoteRate = {
	maxPerSecond: number,
	burst: number,
}

-- Backpressure for server->client feeds. Protects the schedule feed from a slow or spammy
-- client starving other players.
export type RemoteBackpressure = {
	enabled: boolean,
	-- Maximum number of unacknowledged/unsent updates to queue per player.
	maxQueued: number,
	-- What to do when the queue is full: drop the oldest or the newest pending update.
	onOverflow: "dropOldest" | "dropNewest",
	-- If true, a client falling behind is muted (no further sends) until it catches up.
	muteIfBehind: boolean,
}

export type RemoteEntry = {
	name: string,
	direction: RemoteDirection,
	request: string?, -- shape name in RailContract / GameplayContract, if any
	response: string?, -- shape name, if any
	rate: RemoteRate,
	backpressure: RemoteBackpressure?, -- only meaningful for ServerToClient feeds
}

local RemoteContract = {
	Train = {
		-- Player drives a train: intent only; the server applies it at the fixed tick.
		Control = {
			name = "Train.Control",
			direction = "ClientToServer",
			request = "TrainCommand",
			response = nil,
			rate = { maxPerSecond = 30, burst = 60 }, -- one per client tick at 30 Hz
		},
		-- Server publishes authoritative train state at the fixed tick.
		-- FROZEN shape: additive changes only.
		State = {
			name = "Train.State",
			direction = "ServerToClient",
			request = nil,
			response = "TrainState[]",
			rate = { maxPerSecond = 30, burst = 60 },
			backpressure = {
				enabled = true,
				maxQueued = 2,
				onOverflow = "dropOldest",
				muteIfBehind = false,
			},
		},
	},
	Station = {
		-- Player requests to board/alight at a station (Phase 2 passenger system).
		Board = {
			name = "Station.Board",
			direction = "ClientToServer",
			request = "StationBoardRequest",
			response = "StationBoardResponse",
			rate = { maxPerSecond = 2, burst = 4 },
		},
	},
	Signal = {
		-- Server pushes current signal aspects for the lines relevant to a player.
		-- Backpressure prevents a slow client from starving the schedule feed.
		Observe = {
			name = "Signal.Observe",
			direction = "ServerToClient",
			request = nil,
			response = "SignalState[]",
			rate = { maxPerSecond = 10, burst = 20 },
			backpressure = {
				enabled = true,
				maxQueued = 1,
				onOverflow = "dropNewest", -- latest aspect matters; stale aspects are waste
				muteIfBehind = false,
			},
		},
	},
}

return RemoteContract
