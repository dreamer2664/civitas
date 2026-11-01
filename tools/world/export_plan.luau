--!strict
-- Exports the same plan consumed by the server builder for deterministic renders and audits.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local config = require("../../src/server/World/CityConfig")
local generator = require("../../src/server/World/CityGenerator")

local plan = generator.generate(config)
local output = "tools/world/generated-plan.json"
fs.writeFile(output, serde.encode("json", plan, true))
print(
	string.format(
		"Exported %s: %d buildings, %d landmarks, %.1f route studs, %d estimated parts",
		output,
		plan.stats.buildingCount,
		plan.stats.landmarkCount,
		plan.stats.routeLength,
		plan.stats.estimatedParts
	)
)
