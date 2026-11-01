--!strict
--[[
Stops.luau — station stop markers (data, not code).

Stop positions are arc-length distances (studs) along each line, computed from the
waypoints in docs/rail/NETWORK.md §3. These are APPROXIMATE — the spline's
distanceToPoint() should be used to snap platform positions to the track centre line
once the platform meshes are placed (mason's platform kit) and the exact stop markers
are surveyed.

Owned by CODE · vector (rail system). Config keys are vector's domain.

Platform interface (GeometryContract §3 / §5):
  - Platform top above rail: PLATFORM_TOP_ABOVE_RAIL = 2.7143 studs (0.760 m)
  - Car root is at rail-top datum (CAR_ROOT_Y = 0)
  - Door-open and stop-position logic lives in TrainService.tick() so the
    carriage-floor-to-platform seam lines up (level boarding, no step up).
--]]

local Stops = {}

-- Line 1 station stops. distanceStuds = arc-length position on Line 1 spline.
Stops.Line1 = {
	{ stationId = "Airport Terminal", lineId = "Line1", distanceStuds = 0 },
	{ stationId = "Hillside Halt", lineId = "Line1", distanceStuds = 1649 },
	{ stationId = "Riverside", lineId = "Line1", distanceStuds = 3844 },
	{ stationId = "Civitas Central", lineId = "Line1", distanceStuds = 5137 },
	{ stationId = "Old Town", lineId = "Line1", distanceStuds = 6286 },
	{ stationId = "Harbour Gate", lineId = "Line1", distanceStuds = 8033 },
	{ stationId = "Container Terminal", lineId = "Line1", distanceStuds = 9521 },
	{ stationId = "Harbour End", lineId = "Line1", distanceStuds = 10652 },
}

-- Dwell time at each station (seconds).
Stops.DWELL_SECONDS = 6

return Stops
