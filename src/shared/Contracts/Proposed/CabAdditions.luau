--!strict
--[[
	PROPOSED by CODE · lumen, answering CODE · vector's request in
	docs/reports/vector-phase1-report.md §3 (client input and dashboard fields).
	Not merged. Lives in src/shared/Contracts/Proposed/ until Manager A ratifies it; then the fields
	below are merged into RailContract.luau and this file is removed.

	This amends RailContract.luau (on main). It does not define a second cab protocol.
	RailContract already carries the cab's core: TrainCommand has throttle, brake, reverser, horn and
	doors; TrainState has speed, direction, door state and signal aspect. This file adds only what the
	cab needs and RailContract does not have.

	Not proposed, and why:
	- Notches. The cab shows eight notches. The client sends throttle = notch / 8 and brake = notch / 8
	  within RailContract's ranges. The notch count is a cab-display choice and stays in the client.
	- Speed units. TrainState.speedStudsPerS is used as it is. km/h = studs per s × 0.28 m per stud ×
	  3.6 (docs/ASSET-INTERFACES.md: 1 m = 3.5714286 studs). No new speed field.
	- Signal aspects. The cab uses RailContract's SignalAspect (red, yellow, green). A missing aspect
	  is an error in the cab, never a default colour.
]]

-- Merged into TrainCommand when ratified. Sent as the Train.Control request.
export type CabCommandAdditions = {
	sequence: number, -- integer from 1, never reused in a session; the server drops stale or
	-- duplicate commands
	emergencyBrake: boolean, -- latched by the server until a stopped train releases it
}

-- Merged into TrainState when ratified. Sent as the Train.State response.
export type CabDisplayAdditions = {
	sequence: number, -- echoes the last CabCommandAdditions.sequence the server applied
	nextStationName: string, -- display name, at most 40 characters, as in docs/rail/NETWORK.md §2
	destinationName: string, -- display name, at most 40 characters
	delaySeconds: number, -- signed; negative is early
	emergencyBrake: boolean,
}

return {}
