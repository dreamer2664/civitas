--!strict
-- Loading the exporter executes the game's unmodified generator AND builder in Lune.
require("./export_world")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Audit = require("../../src/server/Walkability/OrientedAudit")
-- JSON is genuinely dynamic; validate the boundary before passing to pure typed geometry.
local data: any = serde.decode("json", fs.readFile("docs/reports/walkability-world.json"))
assert(
	type(data) == "table" and type(data.parts) == "table" and #data.parts > 0,
	"missing real geometry"
)
local function finite(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end
for _, p in data.parts do
	for _, key in { "x", "y", "z", "sx", "sy", "sz", "rx", "ry", "rz" } do
		assert(finite(p[key]), "invalid geometry coordinate: " .. key)
	end
	for _, key in { "id", "name", "shape" } do
		assert(type(p[key]) == "string", "invalid part identity")
	end
	for _, key in { "collide", "walk", "anchored" } do
		assert(type(p[key]) == "boolean", "invalid collision flags")
	end
end
assert(type(data.route) == "table" and #data.route >= 2, "missing route")
for _, p in data.route do
	assert(finite(p.x) and finite(p.z), "invalid route point")
end
for _, key in { "minX", "maxX", "minZ", "maxZ" } do
	assert(finite(data.bounds[key]), "invalid world bounds")
end
assert(
	data.bounds.minX < data.bounds.maxX and data.bounds.minZ < data.bounds.maxZ,
	"empty ground domain"
)
local parts: { Audit.Part } = data.parts
local route: { Audit.Point } = data.route
local sealed = Audit.sealed(parts, data.bounds)
local main = Audit.route(parts, route, 1500)
local checks = {}
local blockedSidewalks = 0
local maximumSidewalkStep = 0
for _, p in parts do
	if string.find(p.name, "Sidewalk") == nil or p.name == "CoreSidewalkSpawn" then
		continue
	end
	local angle = math.rad(p.ry)
	local dx, dz, half
	if p.sx > p.sz then
		dx, dz, half = math.cos(angle), -math.sin(angle), p.sx / 2 - 1
	else
		dx, dz, half = math.sin(angle), math.cos(angle), p.sz / 2 - 1
	end
	local result = Audit.route(parts, {
		{ x = p.x - dx * half, z = p.z - dz * half },
		{ x = p.x + dx * half, z = p.z + dz * half },
	}, 0)
	if #result.defects > 0 then
		blockedSidewalks += 1
	end
	maximumSidewalkStep = math.max(maximumSidewalkStep, result.maxStep)
	table.insert(checks, { source = p.id, result = result })
end
-- Check both road-crossing axes at every declared grid intersection, not just
-- the acceptance route. No synthetic paving is created; all support is real parts.
assert(
	type(data.intersections) == "table" and #data.intersections > 0,
	"missing crossing inventory"
)
assert(finite(data.sidewalkWidth) and data.sidewalkWidth >= 2, "invalid sidewalk width")
local crossings = {}
local blockedCrossings = 0
local maximumCrossingStep = 0
for _, intersection in data.intersections do
	for _, key in { "x", "z", "widthX", "widthZ" } do
		assert(finite(intersection[key]), "invalid crossing coordinate/width")
	end
	assert(intersection.widthX > 0 and intersection.widthZ > 0, "invalid road width")
	for _, axis in { "x", "z" } do
		local half = (if axis == "x" then intersection.widthX else intersection.widthZ) / 2
			+ data.sidewalkWidth / 2
		local crossingRoute: { Audit.Point } = {
			{
				x = intersection.x - (if axis == "x" then half else 0),
				z = intersection.z - (if axis == "z" then half else 0),
			},
			{
				x = intersection.x + (if axis == "x" then half else 0),
				z = intersection.z + (if axis == "z" then half else 0),
			},
		}
		local result = Audit.route(parts, crossingRoute, 0)
		if #result.defects > 0 then
			blockedCrossings += 1
		end
		maximumCrossingStep = math.max(maximumCrossingStep, result.maxStep)
		table.insert(
			crossings,
			{ x = intersection.x, z = intersection.z, axis = axis, result = result }
		)
	end
end
local candidateRoute: { Audit.Point } = {}
for _, point in route do
	table.insert(candidateRoute, { x = point.x, z = point.z })
end
assert(
	finite(data.recommendedSpawn.city.x) and finite(data.recommendedSpawn.city.z),
	"invalid candidate spawn"
)
candidateRoute[1] = { x = data.recommendedSpawn.city.x, z = data.recommendedSpawn.city.z }
local candidate = Audit.route(parts, candidateRoute, 1500)
local categories: { [string]: number } =
	{ ROUTE_GAP = 0, STEP = 0, NONCOLLIDABLE_SURFACE = 0, BODY_BLOCKED = 0 }
for _, defect in main.defects do
	categories[defect.code] = (categories[defect.code] or 0) + 1
end
for _, check in checks do
	for _, defect in check.result.defects do
		categories[defect.code] = (categories[defect.code] or 0) + 1
	end
end
for _, crossing in crossings do
	for _, defect in crossing.result.defects do
		categories[defect.code] = (categories[defect.code] or 0) + 1
	end
end
fs.writeFile(
	"docs/reports/walkability-lune-results.json",
	serde.encode("json", {
		engineTested = false,
		categoryCounts = categories,
		partCount = #parts,
		groundSealed = sealed,
		mainRoute = main,
		sidewalkCount = #checks,
		blockedSidewalks = blockedSidewalks,
		maximumSidewalkStep = maximumSidewalkStep,
		sidewalks = checks,
		crossings = crossings,
		crossingCount = #crossings,
		blockedCrossings = blockedCrossings,
		maximumCrossingStep = maximumCrossingStep,
		recommendedSpawn = {
			runtimeApplied = false,
			point = data.recommendedSpawn.city,
			route = candidate,
		},
	}, true)
)
print(
	string.format(
		"LUNE REAL AUDIT: parts=%d route=%.6f maxStep=%.6f routeDefects=%d sealed=%s sidewalks=%d blocked=%d",
		#parts,
		main.length,
		main.maxStep,
		#main.defects,
		tostring(sealed),
		#checks,
		blockedSidewalks
	)
)
print(
	string.format(
		"LUNE CROSSINGS: checked=%d blocked=%d maxStep=%.6f",
		#crossings,
		blockedCrossings,
		maximumCrossingStep
	)
)
assert(#candidate.defects == 0, "recommended spawn route geometry fails")
assert(blockedCrossings == 0, "real crossing continuity fails; see walkability-lune-results.json")
assert(sealed, "ground seal unproven")
assert(
	#main.defects == 0,
	"real acceptance route has geometry defects; see walkability-lune-results.json"
)
assert(blockedSidewalks == 0, "real sidewalk continuity fails; see walkability-lune-results.json")
