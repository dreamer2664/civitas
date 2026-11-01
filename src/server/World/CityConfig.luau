--!strict
-- All dimensions are Roblox studs. This intentionally describes a walkable slice, not a full city.
local CityConfig = {
	seed = 2664,
	ground = {
		centerX = 0,
		centerZ = 115,
		width = 1540,
		depth = 1880,
		thickness = 12,
	},
	streets = {
		localWidth = 18,
		arterialWidth = 30,
		sidewalkWidth = 3.5,
		curbWidth = 0.65,
		curbHeight = 0.28,
		cornerRadius = 11,
		gridX = { -600, -360, -120, 120, 360, 600 },
		gridZ = { -420, -210, 0, 210, 420, 630 },
		minX = -700,
		maxX = 700,
		minZ = -650,
		maxZ = 970,
		stationAvenueX = 120,
	},
	blocks = {
		streetInset = 19,
		lotsAcross = 4,
		lotsDeep = 3,
		lotGap = 8,
		minWidth = 28,
		maxWidth = 48,
		minDepth = 25,
		maxDepth = 43,
		minHeight = 18,
		maxHeight = 86,
	},
	square = {
		centerX = 250,
		centerZ = 105,
		width = 170,
		depth = 110,
	},
	station = {
		centerX = 120,
		forecourtZ = 810,
		entryZ = 858,
		concourseZ = 925,
		width = 176,
		depth = 150,
	},
	streaming = {
		minRadius = 64,
		targetRadius = 1024,
		districtEdgePadding = 96,
	},
	buildingBudget = {
		min = 200,
		max = 400,
		partTarget = 25000,
	},
}

return CityConfig
