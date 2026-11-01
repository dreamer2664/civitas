--!strict
--[[
RailContract.luau — PROPOSED rail types.

OWNERSHIP: src/shared/Contracts/** is Manager A-owned. This file is a PROPOSAL by CODE · vector;
it is not merged or frozen until the Manager ratifies it in the PR thread, after agreement with
CODE · lumen (who implements the client side).

CONTENTS: types only — TrainState, TrainCommand, TrackSegment, SignalState. No implementation.

NOTE: selene 0.32.0's parser does not accept inline literal types (e.g. `"closed" | "open"`)
inside type tables, so literal domains are declared as aliases first and referenced by name.
--]]

export type Direction = number -- train direction along the line: -1 backward, 1 forward (validated at the remote boundary)
export type Reverser = number -- reverser handle: -1, 0 (neutral), or 1 (validated at the remote boundary)
export type DoorState = "closed" | "opening" | "open" | "closing"
export type DoorCommand = "open" | "close" | "hold"
export type SignalAspect = "red" | "yellow" | "green"

-- Server-authoritative snapshot of one train, replicated at the fixed tick.
-- All distances are studs along the train's current line (arc-length position).
export type TrainState = {
	trainId: string,
	lineId: string,
	distanceStuds: number,
	speedStudsPerS: number,
	direction: Direction,
	doorState: DoorState,
	signalAspect: SignalAspect,
	speedLimitKph: number,
	updatedAt: number, -- server os.clock() when this state was computed
}

-- Driving intent sent by the client. The server validates and decides; the client never sends
-- position. Numeric fields are bounded (-1..1 or 0..1) — see RemoteContract validators.
export type TrainCommand = {
	throttle: number, -- -1 (full reverse power) .. 1 (full forward power)
	brake: number, -- 0 (none) .. 1 (full service brake)
	reverser: Reverser,
	horn: boolean?,
	doors: DoorCommand?,
}

-- One tracked section of the network. Control points are studs in the world frame defined by
-- docs/rail/NETWORK.md. The server holds the authoritative spline; clients interpolate visually.
export type TrackSegment = {
	segmentId: string,
	lineId: string,
	-- Cubic Catmull-Rom control points defining the centre line, in order.
	spline: { { x: number, y: number, z: number } },
	lengthStuds: number,
	speedLimitKph: number,
	-- Track grade (slope sine, -1 = straight down, 1 = straight up), used by Kinematics.luau.
	grade: number,
}

export type SignalState = {
	segmentId: string,
	aspect: SignalAspect,
}

-- A scheduled stop marker on a line (timetable data, Phase 2).
export type StationStop = {
	stationId: string,
	lineId: string,
	distanceStuds: number, -- stop marker arc-length position on the line
	platformLengthStuds: number,
}
