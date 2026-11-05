--!strict
-- Deterministic, single-train driving prototype. It is NOT a Roblox service or signalling system.
-- Server callers must authenticate/rate-limit drivers, supply trustworthy platform/track state,
-- and run bounded fixed ticks. The hard end clamps are a prototype fallback, not real railway ATP.
local TrainSimulation = {}

export type MotionState = { speedMs: number, distanceStuds: number }
export type Command = {
	throttle: number,
	brake: number,
	reverser: number,
	horn: boolean?,
	doors: string?,
}
export type TrainConfig = {
	massKg: number,
	maxTractiveEffortN: number,
	serviceBrakeForceN: number,
	emergencyBrakeForceN: number,
	maxSpeedMs: number,
	rollingResistanceN: number,
	airResistanceCoeff: number,
}

export type Settings = {
	trackLengthStuds: number,
	marginStuds: number,
	commandTimeoutSeconds: number,
	maxSpeedMs: number,
}
export type State = {
	motion: MotionState,
	reverser: number,
	doorsOpen: boolean,
	lastCommand: Command?,
	commandTime: number?,
	intervention: string?,
}

local function finite(n: number): boolean
	return n == n and n ~= math.huge and n ~= -math.huge
end

function TrainSimulation.create(Kinematics: any, DriverControl: any)
	local Engine = {}

	function Engine.new(position: number, settings: Settings): State
		assert(
			finite(settings.trackLengthStuds) and settings.trackLengthStuds > 0,
			"invalid track length"
		)
		assert(finite(settings.marginStuds) and settings.marginStuds >= 0, "invalid safety margin")
		assert(
			finite(settings.commandTimeoutSeconds) and settings.commandTimeoutSeconds > 0,
			"invalid timeout"
		)
		assert(finite(settings.maxSpeedMs) and settings.maxSpeedMs > 0, "invalid speed limit")
		assert(
			finite(position) and position >= 0 and position <= settings.trackLengthStuds,
			"invalid position"
		)
		return {
			motion = Kinematics.stopped(position),
			reverser = 0,
			doorsOpen = false,
			lastCommand = nil,
			commandTime = nil,
			intervention = nil,
		}
	end

	-- The caller must perform authorization and rate limiting before this function.
	function Engine.submit(state: State, raw: any, now: number): (State?, string?)
		if not finite(now) or (state.commandTime ~= nil and now < state.commandTime) then
			return nil, "invalid or non-monotonic command time"
		end
		local command, reason = DriverControl.validate(raw)
		if command == nil then
			return nil, reason
		end
		return {
			motion = state.motion,
			reverser = state.reverser,
			doorsOpen = state.doorsOpen,
			lastCommand = command,
			commandTime = now,
			intervention = state.intervention,
		},
			nil
	end

	-- `atPlatform` is a SERVER-DERIVED alignment/permission decision, never a client assertion.
	-- A missing/stale command applies service brake; open doors inhibit traction and hold the brake.
	function Engine.step(
		state: State,
		settings: Settings,
		config: TrainConfig,
		dt: number,
		now: number,
		grade: number,
		atPlatform: boolean
	): State
		assert(finite(dt) and dt > 0 and dt <= 1 / 15, "step requires bounded fixed timestep")
		assert(finite(now) and finite(grade) and math.abs(grade) <= 1, "invalid time or grade")
		local speed = state.motion.speedMs
		local doorsOpen = state.doorsOpen
		local reverser = state.reverser
		local command = state.lastCommand
		local fresh = command ~= nil
			and state.commandTime ~= nil
			and now >= state.commandTime
			and now - state.commandTime <= settings.commandTimeoutSeconds
		local traction = 0
		local brake = 1
		local emergency = false
		local intervention: string? = nil

		if fresh and command then
			if math.abs(speed) <= 0.01 then
				reverser = command.reverser
			elseif command.reverser ~= reverser then
				intervention = "reverser change while moving"
			end
			if command.doors == "close" then
				doorsOpen = false
			elseif command.doors == "open" and math.abs(speed) <= 0.01 and atPlatform then
				doorsOpen = true
			end
			if intervention == nil then
				traction = command.throttle
				brake = command.brake
			end
		else
			intervention = "command timeout"
		end

		if doorsOpen then
			traction = 0
			brake = 1
			intervention = "doors open"
		end
		if math.abs(speed) > settings.maxSpeedMs then
			traction = 0
			brake = 1
			intervention = "speed limit"
		end

		local distanceToEnd = if speed < 0
			then state.motion.distanceStuds
			else settings.trackLengthStuds - state.motion.distanceStuds
		local emergencyStop = Kinematics.stopDistanceStuds(
			state.motion,
			{ tractive = 0, serviceBrake = 0, emergencyBrake = true },
			config,
			grade
		)
		if speed ~= 0 and distanceToEnd <= emergencyStop + settings.marginStuds then
			traction = 0
			brake = 1
			emergency = true
			intervention = "track end"
		end

		-- Do not repeatedly power toward an end while within the stop margin. Reverse power
		-- away from the end remains possible after stopping.
		if
			(state.motion.distanceStuds <= settings.marginStuds and traction < 0)
			or (
				state.motion.distanceStuds >= settings.trackLengthStuds - settings.marginStuds
				and traction > 0
			)
		then
			traction = 0
			brake = 1
			intervention = "track end"
		end

		local motion = Kinematics.integrate(state.motion, dt, {
			tractive = traction,
			serviceBrake = brake,
			emergencyBrake = emergency,
		}, config, grade)
		if motion.distanceStuds < 0 or motion.distanceStuds > settings.trackLengthStuds then
			motion = {
				distanceStuds = math.clamp(motion.distanceStuds, 0, settings.trackLengthStuds),
				speedMs = 0,
			}
			intervention = "track end hard clamp"
		end
		return {
			motion = motion,
			reverser = reverser,
			doorsOpen = doorsOpen,
			lastCommand = state.lastCommand,
			commandTime = state.commandTime,
			intervention = intervention,
		}
	end

	return Engine
end

return TrainSimulation
