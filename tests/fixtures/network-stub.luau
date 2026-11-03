--!strict
--[[
	SYNTHETIC STUB. NOT GAME DATA.

	A three-line network invented to test the map's data boundary and the swappable source. Only
	tests use it (tests/client/map.spec). The client ships the generated network from
	docs/rail/NETWORK.md (UI/Map/NetworkData.luau). Coordinates are arbitrary studs. Do not copy these
	names or positions into game data.
]]

local fixture = {
	stations = {
		{ id = "central", name = "Central", x = 0, z = 0, interchange = true },
		{ id = "harbour", name = "Harbour", x = -600, z = -300, interchange = false },
		{ id = "airport", name = "Airport", x = 1400, z = 500, interchange = false },
		{ id = "northgate", name = "Northgate", x = 200, z = 900, interchange = false },
		{ id = "eastfield", name = "Eastfield", x = 800, z = -400, interchange = false },
		{ id = "westbrook", name = "Westbrook", x = -1200, z = 200, interchange = false },
		{ id = "market", name = "Market", x = -200, z = 200, interchange = false },
	},
	lines = {
		{
			id = "harbour-airport",
			code = "A",
			colour = "teal",
			stops = { "harbour", "central", "airport" },
			sections = {
				{
					kind = "surface",
					points = { { x = -600, z = -300 }, { x = -300, z = -150 }, { x = 0, z = 0 } },
				},
				{
					kind = "elevated",
					points = { { x = 0, z = 0 }, { x = 700, z = 250 }, { x = 1400, z = 500 } },
				},
			},
		},
		{
			id = "northgate-eastfield",
			code = "N",
			colour = "ochre",
			stops = { "northgate", "central", "eastfield" },
			sections = {
				{
					kind = "underground",
					points = { { x = 200, z = 900 }, { x = 100, z = 450 }, { x = 0, z = 0 } },
				},
				{
					kind = "surface",
					points = { { x = 0, z = 0 }, { x = 400, z = -200 }, { x = 800, z = -400 } },
				},
			},
		},
		{
			id = "westbrook-central",
			code = "W",
			colour = "slate",
			stops = { "westbrook", "market", "central" },
			sections = {
				{
					kind = "surface",
					points = {
						{ x = -1200, z = 200 },
						{ x = -700, z = 200 },
						{ x = -200, z = 200 },
					},
				},
				{
					kind = "surface",
					points = { { x = -200, z = 200 }, { x = -100, z = 100 }, { x = 0, z = 0 } },
				},
			},
		},
	},
}

return fixture
