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
assert(sealed, "ground seal unproven")
assert(
	#main.defects == 0,
	"real acceptance route has geometry defects; see walkability-lune-results.json"
)
assert(blockedSidewalks == 0, "real sidewalk continuity fails; see walkability-lune-results.json")
