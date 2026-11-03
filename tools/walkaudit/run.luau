--!strict
-- Dynamic boundary is validated before entering pure typed auditing functions.
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local Audit = require("../../src/server/Walkability/Audit")
local Spawn = require("../../src/server/Spawn/Plan")
local modulePath = process.args[1] or "../../src/server/World/Geometry"
local function finite(n: any): boolean
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end
local function point(p: any)
	assert(type(p) == "table" and finite(p.x) and finite(p.z), "invalid point")
end
local function validate(data: any)
	assert(type(data) == "table", "generator must return an audit export table")
	assert(
		data.schema == "walk-boxes-v1",
		"unsupported geometry: explicit walk-boxes-v1 export required"
	)
	assert(type(data.boxes) == "table" and #data.boxes > 0, "empty geometry cannot pass")
	for _, b in data.boxes do
		assert(type(b.id) == "string", "box needs source part ID")
		for _, key in { "x0", "x1", "z0", "z1", "bottom", "top" } do
			assert(finite(b[key]), "nonfinite box coordinate: " .. b.id)
		end
		assert(b.x1 > b.x0 and b.z1 > b.z0 and b.top > b.bottom, "degenerate box: " .. b.id)
		assert(
			type(b.walk) == "boolean" and type(b.collide) == "boolean",
			"missing collision semantics"
		)
	end
	local b = data.bounds
	assert(
		type(b) == "table" and finite(b.x0) and finite(b.x1) and finite(b.z0) and finite(b.z1),
		"missing walkable bounds"
	)
	assert(b.x1 > b.x0 and b.z1 > b.z0, "empty walkable bounds")
	assert(type(data.route) == "table" and #data.route >= 2, "route required")
	for _, p in data.route do
		point(p)
	end
	point(data.citySpawn)
	point(data.stationSpawn)
end
local ok, data = pcall(function()
	local generator = require(modulePath)
	return generator.generateAuditData()
end)
if not ok then
	fs.writeFile(
		"docs/reports/walkability-results.json",
		serde.encode("json", {
			status = "BLOCKED",
			code = "WORLD_DATA_UNAVAILABLE",
			module = modulePath,
			detail = tostring(data),
			engineTested = false,
		}, true)
	)
	error("WORLD_DATA_UNAVAILABLE: " .. tostring(data))
end
validate(data)
local defects = Audit.seal(data.boxes, data.bounds)
local routeDefects, length = Audit.route(data.boxes, data.route, 1500)
for _, defect in routeDefects do
	table.insert(defects, defect)
end
for _, key in { "citySpawn", "stationSpawn" } do
	local valid = Spawn.validate(data.boxes, data[key])
	if not valid then
		table.insert(
			defects,
			{ code = "SPAWN_UNSAFE", x = data[key].x, z = data[key].z, detail = key }
		)
	end
end
fs.writeFile(
	"docs/reports/walkability-results.json",
	serde.encode("json", {
		status = if #defects == 0 then "GEOMETRY_CHECKS_PASS" else "FAIL",
		engineTested = false,
		parts = #data.boxes,
		boxes = data.boxes,
		route = data.route,
		bounds = data.bounds,
		routeLength = length,
		defects = defects,
		limitations = "Box-only geometry; centerline route; landmark, semantic destinations, slope and streaming runtime unverified",
	}, true)
)
print(string.format("parts=%d route=%g defects=%d", #data.boxes, length, #defects))
assert(#defects == 0, "geometry defects: see docs/reports/walkability-results.json")
