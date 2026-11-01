--!strict
--[[
Tracks.luau — track line definitions (data, not code).

Sources: docs/rail/NETWORK.md §3 (waypoints in studs, frame: X east, Z south, Y up).
Control points feed `src/shared/Rail/Spline.luau` (Catmull-Rom interpolates them).
Y = 0 is the rail-top datum (GeometryContract §5).

Owned by CODE · vector (rail system). Config keys are vector's domain.
--]]

local Tracks = {}

-- Line 1 — "Coastal Spine": Airport Terminal ↔ Harbour End (through C and A;
-- central interchange at Civitas Central). Ground/elevated/underground mixed.
Tracks.Line1 = {
	lineId = "Line1",
	name = "Coastal Spine",
	-- Control points in studs: {x, y, z} in the world frame of docs/rail/NETWORK.md.
	controlPoints = {
		{ x = -4200, y = 0, z = -1800 }, -- Airport Terminal
		{ x = -3400, y = 0, z = -1600 },
		{ x = -2600, y = 0, z = -1400 }, -- Hillside Halt
		{ x = -1800, y = 0, z = -600 },
		{ x = -1100, y = 0, z = 200 }, -- Riverside (Line 3 divergence)
		{ x = -400, y = 0, z = 400 },
		{ x = 0, y = 0, z = 0 }, -- Civitas Central (Line 2 interchange, underground)
		{ x = 500, y = 0, z = 300 },
		{ x = 900, y = 0, z = 700 }, -- Old Town (elevated)
		{ x = 1600, y = 0, z = 1000 },
		{ x = 2500, y = 0, z = 1400 }, -- Harbour Gate
		{ x = 3100, y = 0, z = 1900 },
		{ x = 3600, y = 0, z = 2400 }, -- Container Terminal
		{ x = 4000, y = 0, z = 2800 },
		{ x = 4400, y = 0, z = 3200 }, -- Harbour End
	},
}

return Tracks
