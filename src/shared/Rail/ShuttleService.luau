--!strict
-- Experimental two-stop automatic service. Pure rules, not signalling or production ATP.
-- The server supplies motion and fixed dt, and applies commands through TrainSimulation.
local ShuttleService = {}
export type Stop = { id: string, name: string, distanceStuds: number }
export type Route = { stops: { Stop }, dwellSeconds: number, maxSpeedMs: number }
export type State = {
	target: number,
	phase: string,
	remaining: number,
	completedLegs: number,
}
export type Motion = { distanceStuds: number, speedMs: number }
export type Command = { throttle: number, brake: number, reverser: number, doors: string }

local function finite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

function ShuttleService.validate(route: Route)
	assert(#route.stops == 2, "experimental service requires exactly two stops")
	assert(finite(route.dwellSeconds) and route.dwellSeconds >= 5, "invalid dwell")
	assert(
		finite(route.maxSpeedMs) and route.maxSpeedMs > 0 and route.maxSpeedMs <= 10,
		"invalid speed"
	)
	for _, stop in route.stops do
		assert(finite(stop.distanceStuds), "invalid stop position")
		assert(#stop.id > 0 and #stop.name > 0, "missing stop identity")
	end
	assert(route.stops[2].distanceStuds - route.stops[1].distanceStuds > 160, "stops overlap")
	assert(route.stops[1].id ~= route.stops[2].id, "duplicate stop id")
end

function ShuttleService.new(route: Route, motion: Motion): State
	ShuttleService.validate(route)
	local a = math.abs(motion.distanceStuds - route.stops[1].distanceStuds)
	local b = math.abs(motion.distanceStuds - route.stops[2].distanceStuds)
	-- Recover toward the current direction when moving; choose the nearest stop when stopped.
	local target = if math.abs(motion.speedMs) > 0.01
		then (if motion.speedMs > 0 then 2 else 1)
		else (if a < b then 1 else 2)
	return { target = target, phase = "approaching", remaining = 0, completedLegs = 0 }
end

function ShuttleService.atStop(route: Route, distance: number): Stop?
	if not finite(distance) then
		return nil
	end
	for _, stop in route.stops do
		if math.abs(distance - stop.distanceStuds) <= 2 then
			return stop
		end
	end
	return nil
end

-- A docking correction is returned only inside 0.6 studs and below 0.12 m/s. It is a
-- documented prototype snap, not proof of real stopping accuracy or passenger transport.
function ShuttleService.step(
	state: State,
	route: Route,
	motion: Motion,
	dt: number
): (State, Command, number?)
	assert(finite(dt) and dt > 0 and dt <= 1 / 15, "requires bounded fixed dt")
	assert(finite(motion.distanceStuds) and finite(motion.speedMs), "invalid motion")
	local nextState: State = {
		target = state.target,
		phase = state.phase,
		remaining = state.remaining,
		completedLegs = state.completedLegs,
	}
	local target = route.stops[state.target]
	local error = target.distanceStuds - motion.distanceStuds
	local direction = if error >= 0 then 1 else -1
	local hold: Command = { throttle = 0, brake = 1, reverser = 0, doors = "open" }
	if state.phase == "dwelling" then
		nextState.remaining = math.max(0, state.remaining - dt)
		if nextState.remaining == 0 then
			nextState.phase = "closing"
			nextState.remaining = 1.5
			hold.doors = "close"
		end
		return nextState, hold, nil
	end
	if state.phase == "closing" then
		hold.doors = "close"
		nextState.remaining = math.max(0, state.remaining - dt)
		if nextState.remaining == 0 then
			nextState.target = 3 - state.target
			nextState.phase = "approaching"
		end
		return nextState, hold, nil
	end
	if math.abs(error) <= 0.6 and math.abs(motion.speedMs) <= 0.12 then
		nextState.phase = "dwelling"
		nextState.remaining = route.dwellSeconds
		nextState.completedLegs += 1
		return nextState, hold, target.distanceStuds
	end
	-- Conservative flat-track braking envelope, well below the prototype's service brake.
	local desired =
		math.min(route.maxSpeedMs, math.sqrt(2 * 0.4 * math.max(0, math.abs(error) * 0.28 - 0.1)))
	local speed = math.abs(motion.speedMs)
	local wrongWay = motion.speedMs * direction < -0.01
	local brake = if wrongWay then 1 else math.clamp((speed - desired) * 3, 0, 1)
	local throttle = if brake > 0 or wrongWay
		then 0
		else direction * math.clamp((desired - speed) * 0.9 + 0.04, 0, 0.65)
	-- Never change reverser in motion, including recovery after a manual overshoot.
	local reverser = if speed > 0.01 then (if motion.speedMs > 0 then 1 else -1) else direction
	return nextState,
		{ throttle = throttle, brake = brake, reverser = reverser, doors = "close" },
		nil
end

return ShuttleService
