--!strict
-- Consumes the same real-builder export validated by check_world.luau.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Audit = require("../../src/server/Walkability/OrientedAudit")
local Checks = require("../../src/server/Walkability/StreetChecks")
local data: any = serde.decode("json", fs.readFile("docs/reports/walkability-world.json"))
local parts: { Audit.Part } = data.parts
local crossings = {}
local failures = 0
for _, intersection in data.intersections do
	for _, crossing in Checks.crossings(intersection, data.sidewalkWidth) do
		local result = Audit.route(parts, crossing.route, 0)
		if #result.defects > 0 then
			failures += 1
		end
		table.insert(crossings, {
			x = intersection.x,
			z = intersection.z,
			axis = crossing.axis,
			side = crossing.side,
			route = crossing.route,
			result = result,
		})
	end
end
local sidewalks = {}
local widthFailures = 0
for _, part in parts do
	if string.find(part.name, "Sidewalk") and part.name ~= "CoreSidewalkSpawn" then
		local result = Checks.sidewalk(part, parts, 3.5)
		if not result.passed then
			widthFailures += 1
		end
		table.insert(sidewalks, result)
	end
end
fs.writeFile(
	"docs/reports/walkability-street-fixes.json",
	serde.encode("json", {
		engineTested = false,
		sidewalkCount = #sidewalks,
		failedSidewalkWidths = widthFailures,
		sidewalks = sidewalks,
		crossingCount = #crossings,
		failedCrossings = failures,
		crossings = crossings,
	}, true)
)
print(string.format("STREET CROSSINGS: %d checked, %d failed", #crossings, failures))
assert(failures == 0, "sidewalk-aligned crossing audit failed")

print(string.format("STREET WIDTHS: %d checked, %d failed", #sidewalks, widthFailures))
assert(widthFailures == 0, "full sidewalk width audit failed")
