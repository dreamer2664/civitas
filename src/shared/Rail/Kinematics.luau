--!strict
--[[
Kinematics.luau — train dynamics along a spline (pure Luau).

Pure Luau: no DataModel access, testable with lune without Studio. All integration units are
SI internally (metres, m/s, newtons, kilograms); distances exposed to the simulation are
converted to studs using the ratified 1 m = 3.5714286 studs from GeometryContract
(docs/ASSET-INTERFACES.md §1).

Real EMU-1 geometry (mason, merged at aea6701; docs/ASSET-INTERFACES.md §4) is used for
the physical constants below. Dynamics parameters (mass, tractive effort, brake force) are
engineering estimates pending measured EMU-1 performance data; they are clearly marked and
can be swapped in a one-line config change.

Model
-----
Longitudinal dynamics only — lateral/vertical behaviour is handled by the spline (the train
is constrained to the track centre line by construction).

\tforce = tractiveEffort - brakeForce - rollingResistance - airResistance - mass * g * grade
\tacceleration = force / mass

where grade is the track slope (sin of the incline, -1 for straight down, +1 for straight up).
Braking distance under constant deceleration: d = v^2 / (2 * deceleration), used for stop
markers and signal braking curves.

Integration is semi-implicit Euler with speed clamping; the caller subdivides dt as needed
for stability (a fixed 30 Hz tick with at most one integration per tick is the intended use).
--]]

local GeometryContract = require("../Contracts/GeometryContract")

local STUD_PER_METER = GeometryContract.STUDS_PER_METRE -- 3.5714286 studs/m (ratified)
local GRAVITY = 9.81 -- m/s^2

-- EMU-1 real geometry, studs (docs/ASSET-INTERFACES.md §4; assets/trains/EMU-1/README.md).
-- These are the ratified physical dimensions; dynamics params below them are estimates.
local EMU1_GEOMETRY = {
	-- Two-car EMU: cab + intermediate, coupled with the inter-car gap.
	cabCarLengthStuds = GeometryContract.CAB_CAR_LENGTH, -- 75.0
	intermediateCarLengthStuds = GeometryContract.INTERMEDIATE_CAR_LENGTH, -- 71.4286
	trainLengthStuds = GeometryContract.CAB_CAR_LENGTH
		+ GeometryContract.INTERMEDIATE_CAR_LENGTH
		+ GeometryContract.INTER_CAR_GAP, -- ~148.2143
	doorTravelStuds = GeometryContract.DOOR_TRAVEL, -- 4.8214 (1.35 m)
	doorWidthStuds = GeometryContract.DOOR_WIDTH, -- 4.6429 (1.30 m)
	doorHeightStuds = GeometryContract.DOOR_HEIGHT, -- 6.9643 (1.95 m)
	bogieCentresFromEndStuds = GeometryContract.BOGIE_CENTRES_FROM_END, -- 10.7143 (3.0 m)
	wheelDiameterStuds = GeometryContract.WHEEL_DIAMETER, -- 3.0 (0.84 m)
	carWidthStuds = GeometryContract.CAR_WIDTH, -- 10.1786 (2.85 m)
}

export type TrainConfig = {
	massKg: number, -- ESTIMATE: 120 t two-car EMU; replace with measured value
	-- Tractive effort at full throttle (newtons), flat track, from standstill.
	maxTractiveEffortN: number, -- ESTIMATE; replace with measured EMU-1 tractive curve
	-- Service brake force at full application (newtons).
	serviceBrakeForceN: number, -- ESTIMATE; replace with measured EMU-1 brake curve
	-- Emergency brake force at full application (newtons).
	emergencyBrakeForceN: number, -- ESTIMATE; replace with measured EMU-1 brake curve
	-- Maximum allowed speed (m/s).
	maxSpeedMs: number, -- ESTIMATE: 33.3 m/s = 120 km/h
	-- Constant rolling resistance (newtons).
	rollingResistanceN: number, -- ESTIMATE
	-- Air resistance coefficient: force = airResistanceCoeff * speed^2 (newtons).
	airResistanceCoeff: number, -- ESTIMATE
}

export type MotionState = {
	speedMs: number, -- signed speed along the track (m/s)
	distanceStuds: number, -- arc-length position on the spline (studs)
}

export type Controls = {
	tractive: number, -- 0 (none) to 1 (full)
	serviceBrake: number, -- 0 (none) to 1 (full)
	emergencyBrake: boolean,
}

-- Expose the real geometry so services can size stop markers, door animations and platform
-- clearings without duplicating constants.
export type EMU1Geometry = typeof(EMU1_GEOMETRY)

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

	-- Tractive effort only applies when motoring (not braking).
	local tractive = 0
	if controls.tractive > 0 and not controls.emergencyBrake then
		tractive = controls.tractive * config.maxTractiveEffortN
	end

	local brakeForce = 0
	if controls.emergencyBrake then
		brakeForce = config.emergencyBrakeForceN
	else
		brakeForce = controls.serviceBrake * config.serviceBrakeForceN
	end
	-- Brake only opposes motion; never accelerates backwards from a standstill.
	brakeForce = math.min(brakeForce, config.massKg * GRAVITY) -- physical upper bound sanity
	local brake = direction * brakeForce
	if speed == 0 and direction == 0 then
		brake = 0 -- holding brake handled by the service layer; dynamics stay at zero
	end

	local resist = direction * resistanceForce(config, speed)
	local gradeForce = config.massKg * GRAVITY * grade

	local force = tractive - brake - resist - gradeForce
	return force / config.massKg
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
	local newSpeed = state.speedMs + acceleration * dt
	newSpeed = clamp(newSpeed, -config.maxSpeedMs, config.maxSpeedMs)

	-- Use the average speed over the step for distance (trapezoid, better than explicit Euler).
	local averageSpeed = (state.speedMs + newSpeed) / 2
	local distanceMeters = averageSpeed * dt
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

-- Distance (studs) required to stop from the current state under the given brake, forward only.
function Kinematics.stopDistanceStuds(
	state: MotionState,
	controls: Controls,
	config: TrainConfig,
	grade: number
): number
	if state.speedMs <= 0 then
		return 0
	end
	local brakeForce = controls.emergencyBrake and config.emergencyBrakeForceN
		or controls.serviceBrake * config.serviceBrakeForceN
	if brakeForce <= 0 then
		return math.huge
	end
	local meters = Kinematics.brakingDistance(state.speedMs, brakeForce, config.massKg, grade)
	return meters * STUD_PER_METER
end

-- Create a default EMU-1 configuration. Geometry is real (from GeometryContract / mason's
-- EMU-1 at aea6701); dynamics parameters are engineering estimates pending measured data.
function Kinematics.defaultConfig(): TrainConfig
	return {
		massKg = 120000, -- ESTIMATE: 120 t two-car EMU
		maxTractiveEffortN = 120000, -- ESTIMATE
		serviceBrakeForceN = 90000, -- ESTIMATE
		emergencyBrakeForceN = 200000, -- ESTIMATE
		maxSpeedMs = 33.3, -- ESTIMATE: 120 km/h
		rollingResistanceN = 4000, -- ESTIMATE
		airResistanceCoeff = 60, -- ESTIMATE
	}
end

-- Real EMU-1 geometry (studs), ratified via GeometryContract / mason EMU-1 (aea6701).
function Kinematics.emu1Geometry(): EMU1Geometry
	return EMU1_GEOMETRY
end

-- Create a stopped state at the given arc-length position (studs).
function Kinematics.stopped(distanceStuds: number): MotionState
	return { speedMs = 0, distanceStuds = distanceStuds }
end

return Kinematics
