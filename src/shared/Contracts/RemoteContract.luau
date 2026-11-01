--!strict
--[[
RemoteContract.luau — PROPOSED remote table.

OWNERSHIP: src/shared/Contracts/** is Manager A-owned. This file is a PROPOSAL by CODE · vector;
it is not merged or frozen until the Manager ratifies it in the PR thread, after agreement with
CODE · lumen (who implements the client side).

CONTENTS: data only — remote names, directions, request/response shape references and per-player
rate limits. No implementation. Every remote is validated server-side on type, finite numbers,
bounds, rate limit, player state and authority (STANDARDS.md; Remote events/security resource).

RATE LIMITS are per player: maxPerSecond sustained, burst allowed.
--]]

export type RemoteDirection = "ClientToServer" | "ServerToClient"

export type RemoteRate = {
	maxPerSecond: number,
	burst: number,
}

export type RemoteEntry = {
	name: string,
	direction: RemoteDirection,
	request: string?, -- shape name in RailContract / GameplayContract, if any
	response: string?, -- shape name, if any
	rate: RemoteRate,
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
		State = {
			name = "Train.State",
			direction = "ServerToClient",
			request = nil,
			response = "TrainState[]",
			rate = { maxPerSecond = 30, burst = 60 },
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
		Observe = {
			name = "Signal.Observe",
			direction = "ServerToClient",
			request = nil,
			response = "SignalState[]",
			rate = { maxPerSecond = 10, burst = 20 },
		},
	},
}

return RemoteContract
