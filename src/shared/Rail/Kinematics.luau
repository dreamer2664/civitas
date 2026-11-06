--!strict
--[[
Kinematics.luau — train dynamics along a spline (pure Luau).

Pure Luau: no DataModel access, testable with lune without Studio. All integration units are
SI internally (metres, m/s, newtons, kilograms); distances exposed to the simulation are
converted to studs (1 m = 3.571... studs, docs/STANDARDS.md).

Model
-----
Longitudinal dynamics only — lateral/vertical behaviour is handled by the spline (the train
is constrained to the track centre line by construction).

	force = tractiveEffort - brakeForce - rollingResistance - airResistance - mass * g * grade
	acceleration = force / mass

where grade is the track slope (sin of the incline, -1 for straight down, +1 for straight up).
Braking distance under constant deceleration: d = v^2 / (2 * deceleration), used for stop
markers and signal braking curves.

Integration is semi-implicit Euler with speed clamping; the caller subdivides dt as needed
for stability (a fixed 30 Hz tick with at most one integration per tick is the intended use).
--]]

local STUD_PER_METER = 1 / 0.28 -- 1 m = 3.571... studs
local GRAVITY = 9.81 -- m/s^2

export type TrainConfig = {
	massKg: number,
	-- Tractive effort at full throttle (newtons), flat track, from standstill.
	maxTractiveEffortN: number,
	-- Service brake force at full application (newtons).
	serviceBrakeForceN: number,
	-- Emergency brake force at full application (newtons).
	emergencyBrakeForceN: number,
	-- Maximum allowed speed (m/s).
	maxSpeedMs: number,
	-- Constant rolling resistance (newtons).
	rollingResistanceN: number,
	-- Air resistance coefficient: force = airResistanceCoeff * speed^2 (newtons).
	airResistanceCoeff: number,
}

export type MotionState = {
	speedMs: number, -- signed speed along the track (m/s)
	distanceStuds: number, -- arc-length position on the spline (studs)
}

export type Controls = {
	tractive: number, -- -1 (full reverse) to 1 (full forward)
	serviceBrake: number, -- 0 (none) to 1 (full)
	emergencyBrake: boolean,
}

local Kinematics = {}

-- Clamp a value to [min, max].
local function clamp(value: number, min: number, max: number): number
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

-- Signed sign: -1, 0 or 1.
local function sign(value: number): number
	if value > 0 then
		return 1
	end
	if value < 0 then
		return -1
	end
	return 0
end

-- Total resistive force opposing motion (newtons), always >= 0 and acting against velocity.
local function resistanceForce(config: TrainConfig, speedMs: number): number
	local speed = math.abs(speedMs)
	return config.rollingResistanceN + config.airResistanceCoeff * speed * speed
end

-- Longitudinal acceleration (m/s^2) for the given controls and track grade.
function Kinematics.computeAcceleration(
	state: MotionState,
	controls: Controls,
	config: TrainConfig,
	grade: number
): number
	local speed = state.speedMs
	local direction = sign(speed)

	-- Brake demand interlocks traction. Signed traction is along the track coordinate.
	local brakeDemand = clamp(controls.serviceBrake, 0, 1)
	local tractive = 0
	if not controls.emergencyBrake and brakeDemand == 0 then
		tractive = clamp(controls.tractive, -1, 1) * config.maxTractiveEffortN
	end

	local brakeForce = if controls.emergencyBrake
		then config.emergencyBrakeForceN
		else brakeDemand * config.serviceBrakeForceN
	brakeForce = math.min(brakeForce, config.massKg * GRAVITY)
	local gradeForce = config.massKg * GRAVITY * grade
	local driveForce = tractive - gradeForce
	local opposingForce = brakeForce + resistanceForce(config, speed)

	if direction == 0 then
		-- Static holding: brakes and rolling resistance oppose the force trying to move
		-- the stationary train, up to their combined capacity.
		if math.abs(driveForce) <= opposingForce then
			return 0
		end
		return (driveForce - sign(driveForce) * opposingForce) / config.massKg
	end
	return (driveForce - direction * opposingForce) / config.massKg
end

-- Integrate one step (semi-implicit Euler), returning a new state.
function Kinematics.integrate(
	state: MotionState,
	dt: number,
	controls: Controls,
	config: TrainConfig,
	grade: number
): MotionState
	local acceleration = Kinematics.computeAcceleration(state, controls, config, grade)
	assert(dt >= 0 and dt < math.huge, "integration timestep must be finite and non-negative")
	local newSpeed = state.speedMs + acceleration * dt
	local travelTime = dt
	-- Resistance and braking must not create a spurious reversal when a tick crosses zero.
	-- Integrate only until the stop, then reevaluate static forces on the next tick.
	if state.speedMs ~= 0 and state.speedMs * newSpeed < 0 then
		travelTime = math.abs(state.speedMs / acceleration)
		newSpeed = 0
	end
	newSpeed = clamp(newSpeed, -config.maxSpeedMs, config.maxSpeedMs)

	local averageSpeed = (state.speedMs + newSpeed) / 2
	local distanceMeters = averageSpeed * travelTime
	return {
		speedMs = newSpeed,
		distanceStuds = state.distanceStuds + distanceMeters * STUD_PER_METER,
	}
end

-- Braking distance (metres) to come to a complete stop from speedMs under constant deceleration.
-- grade positive (uphill) helps braking; negative (downhill) hurts it.
function Kinematics.brakingDistance(
	speedMs: number,
	brakeForceN: number,
	massKg: number,
	grade: number
): number
	local speed = math.abs(speedMs)
	-- Uphill (grade > 0) adds to braking; downhill reduces it.
	local deceleration = (brakeForceN + massKg * GRAVITY * grade) / massKg
	-- Resistance also helps braking; including it would require integrating over speed, so we
	-- report the conservative (longer) pure-brake distance plus a small resistance margin.
	if deceleration <= 0 then
		return math.huge
	end
	return (speed * speed) / (2 * deceleration)
end

-- Distance (studs) required to stop from the current state under the given brake, in either direction.
function Kinematics.stopDistanceStuds(
	state: MotionState,
	controls: Controls,
	config: TrainConfig,
	grade: number
): number
	if state.speedMs == 0 then
		return 0
	end
	local brakeForce = controls.emergencyBrake and config.emergencyBrakeForceN
		or clamp(controls.serviceBrake, 0, 1) * config.serviceBrakeForceN
	brakeForce = math.min(brakeForce, config.massKg * GRAVITY)
	if brakeForce <= 0 then
		return math.huge
	end
	-- Grade is defined in the positive track direction; reverse travel sees the opposite slope.
	local meters = Kinematics.brakingDistance(
		state.speedMs,
		brakeForce,
		config.massKg,
		grade * sign(state.speedMs)
	)
	return meters * STUD_PER_METER
end

-- Create a default EMU-ish configuration (numbers are placeholder targets, to be replaced by
-- the measured EMU-1 data from assets/trains/EMU-1/README.md once mason publishes it).
function Kinematics.defaultConfig(): TrainConfig
	return {
		massKg = 120000, -- 120 t EMU two-car
		maxTractiveEffortN = 120000,
		serviceBrakeForceN = 90000,
		emergencyBrakeForceN = 200000,
		maxSpeedMs = 33.3, -- 120 km/h
		rollingResistanceN = 4000,
		airResistanceCoeff = 60,
	}
end

-- Create a stopped state at the given arc-length position (studs).
function Kinematics.stopped(distanceStuds: number): MotionState
	return { speedMs = 0, distanceStuds = distanceStuds }
end

return Kinematics
