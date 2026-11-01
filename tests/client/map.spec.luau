--!strict
-- Network map rules: the data boundary (MapModel.validate), the element budget, and the projection
-- maths that the map view depends on. The fixture is the synthetic stub in tests/fixtures.

local harness = require("../harness")
local MapModel = require("../../src/client/UI/Map/MapModel")
local MapProjection = require("../../src/client/UI/Map/MapProjection")
local Theme = require("../../src/client/UI/Theme")
local fixture = require("../fixtures/network-stub")
local network = require("../../src/client/UI/Map/NetworkData")
local NetworkSource = require("../../src/client/UI/Map/NetworkSource")

local ALLOWED: { [string]: boolean } = {}
for name in Theme.lineColours do
	ALLOWED[name] = true
end

local function errorsOf(data: any): { string }
	local ok, errors = MapModel.validate(data, ALLOWED)
	harness.truthy(not ok, "expected validation to fail")
	return errors
end

local function mentions(errors: { string }, fragment: string): boolean
	for _, e in errors do
		if string.find(e, fragment, 1, true) then
			return true
		end
	end
	return false
end

-- Deep copy so each negative test starts from the valid fixture.
local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[k] = copy(v)
	end
	return out
end

harness.suite("map model")

harness.test("the synthetic fixture is valid", function()
	local ok, errors = MapModel.validate(fixture, ALLOWED)
	harness.truthy(ok, `fixture rejected: {table.concat(errors, "; ")}`)
end)

harness.test("validation refuses non-table input with a clear reason", function()
	local errors = errorsOf("not a map")
	harness.truthy(mentions(errors, "must be a table"))
end)

harness.test("a duplicate station id is named in the error", function()
	local data = copy(fixture)
	data.stations[2].id = "central"
	harness.truthy(mentions(errorsOf(data), "'central' is used more than once"))
end)

harness.test("a line stopping at an unknown station is rejected", function()
	local data = copy(fixture)
	table.insert(data.lines[1].stops, "nowhere")
	harness.truthy(mentions(errorsOf(data), "unknown station 'nowhere'"))
end)

harness.test("a colour that is not a theme token is rejected", function()
	local data = copy(fixture)
	data.lines[1].colour = "neon-pink"
	harness.truthy(mentions(errorsOf(data), "not a colour token"))
end)

harness.test("NaN and infinite coordinates are rejected, not drawn", function()
	local nan = copy(fixture)
	nan.stations[1].x = 0 / 0
	harness.truthy(mentions(errorsOf(nan), "finite numeric"))
	local inf = copy(fixture)
	inf.lines[1].sections[1].points[1].z = math.huge
	harness.truthy(mentions(errorsOf(inf), "finite numeric"))
end)

harness.test("coordinates beyond the world range are rejected", function()
	local data = copy(fixture)
	data.stations[1].x = 1e9
	harness.truthy(mentions(errorsOf(data), "coordinate range"))
end)

harness.test("a section with a single point cannot form a segment", function()
	local data = copy(fixture)
	data.lines[1].sections[1].points = { { x = 0, z = 0 } }
	harness.truthy(mentions(errorsOf(data), "at least two points"))
end)

harness.test("an unknown section kind is rejected", function()
	local data = copy(fixture)
	data.lines[1].sections[1].kind = "flying"
	harness.truthy(mentions(errorsOf(data), "surface, elevated or underground"))
end)

harness.test("overlong station names are rejected", function()
	local data = copy(fixture)
	data.stations[1].name = string.rep("x", 41)
	harness.truthy(mentions(errorsOf(data), "longer than 40"))
end)

harness.test("more stations than the limit is rejected with the numbers", function()
	local data = copy(fixture)
	data.stations = {}
	for i = 1, MapModel.limits.maxStations + 1 do
		table.insert(
			data.stations,
			{ id = `s{i}`, name = `S{i}`, x = i, z = i, interchange = false }
		)
	end
	harness.truthy(mentions(errorsOf(data), "exceeds the limit of 32"))
end)

harness.test("a network over the element budget is rejected, not truncated", function()
	local points = {}
	for i = 1, 64 do
		table.insert(points, { x = i, z = (i % 2) * 10 })
	end
	local sections = {}
	for _ = 1, 12 do
		table.insert(sections, { kind = "surface", points = points })
	end
	local lines = {}
	for i = 1, 8 do
		table.insert(
			lines,
			{ id = `L{i}`, code = "X", colour = "teal", stops = {}, sections = sections }
		)
	end
	local data = { stations = fixture.stations, lines = lines }
	harness.truthy(mentions(errorsOf(data), "budget is 300"))
end)

harness.test(
	"the fixture has 29 drawable elements: 12 segments, 3 badges, 14 station pieces",
	function()
		harness.equal(MapModel.elementCount(fixture), 29)
		harness.equal(#MapModel.segments(fixture), 12)
	end
)

harness.test("bounds cover every station and every line point", function()
	local b = MapModel.bounds(fixture)
	harness.equal(b.minX, -1200)
	harness.equal(b.minZ, -400)
	harness.equal(b.maxX, 1400)
	harness.equal(b.maxZ, 900)
end)

harness.suite("generated network (docs/rail/NETWORK.md)")

harness.test("the generated network passes the same validation as any source", function()
	local ok, errors = MapModel.validate(network, ALLOWED)
	harness.truthy(ok, `generated network rejected: {table.concat(errors, "; ")}`)
end)

harness.test("it has the 14 stations and 3 lines NETWORK.md describes", function()
	harness.equal(#network.stations, 14)
	harness.equal(#network.lines, 3)
end)

harness.test("Civitas Central and Riverside are the interchanges", function()
	local interchanges = {}
	for _, station in network.stations do
		if station.interchange then
			table.insert(interchanges, station.id)
		end
	end
	table.sort(interchanges)
	harness.equal(table.concat(interchanges, ","), "civitas-central,riverside")
end)

harness.test("line 1 runs underground from Riverside to Old Town (NETWORK.md §6)", function()
	local line1 = network.lines[1]
	local found = false
	for _, section in line1.sections do
		if section.kind == "underground" then
			local first, last = section.points[1], section.points[#section.points]
			if first.x == -1100 and first.z == 200 and last.x == 900 and last.z == 700 then
				found = true
			end
		end
	end
	harness.truthy(found, "no underground section from (-1100, 200) to (900, 700)")
end)

harness.test(
	"the map is north-up on real data: Airport Terminal top-left, Lakeside at the bottom",
	function()
		-- Airport Terminal is at (-4200, -1800): west and north. Harbour End is at (4400, 3200): east
		-- and south. Lakeside is at (-600, 3000): south. If Z were drawn upward these would invert.
		local t = MapProjection.fit(MapModel.bounds(network), 800, 600, 16)
		local function at(id: string): (number, number)
			for _, s in network.stations do
				if s.id == id then
					return MapProjection.toScreen(t, s.x, s.z)
				end
			end
			error(`no station '{id}' in the generated network`)
		end
		local ax, ay = at("airport-terminal")
		local hx, hy = at("harbour-end")
		local _, ly = at("lakeside")
		harness.truthy(ax < hx and ay < hy, "Airport Terminal should be north-west of Harbour End")
		harness.truthy(
			ly > ay,
			"Lakeside is south of Airport Terminal and must sit lower on screen"
		)
	end
)

harness.test("the generated network fits the element budget with its real count", function()
	-- 26 segments (14 + 6 + 6), 3 badges, and 14 stations × 2 pieces = 57.
	harness.equal(MapModel.elementCount(network), 57)
	harness.equal(#MapModel.segments(network), 26)
end)

harness.suite("map projection")

local FIT_BOUNDS = { minX = 0, minZ = 0, maxX = 100, maxZ = 50 }
local function fixtureBounds()
	return MapModel.bounds(fixture)
end

harness.test("fit scales to the tighter axis and centres the spare space", function()
	-- 300×200 view, 10 px padding: avail 280×180. Width allows 2.8, height allows 3.6 → 2.8.
	local t = MapProjection.fit(FIT_BOUNDS, 300, 200, 10)
	harness.near(t.scale, 2.8, 1e-9)
	harness.near(t.ox, 10, 1e-9)
	harness.near(t.oy, 30, 1e-9, "140 px of content centred in 180 px")
	local x1, y1 = MapProjection.toScreen(t, 0, 0)
	harness.near(x1, 10, 1e-9)
	harness.near(y1, 30, 1e-9, "north-west corner (least X, least Z) is top-left")
	local x2, y2 = MapProjection.toScreen(t, 100, 50)
	harness.near(x2, 290, 1e-9)
	harness.near(y2, 170, 1e-9)
end)

harness.test("a single point (zero extent) still projects without dividing by zero", function()
	local t = MapProjection.fit({ minX = 5, minZ = 5, maxX = 5, maxZ = 5 }, 200, 200, 0)
	local x, y = MapProjection.toScreen(t, 5, 5)
	harness.truthy(x == x and y == y, "projection produced NaN")
end)

harness.test("toScreen and fromScreen are inverses", function()
	local t = MapProjection.fit(fixtureBounds(), 800, 600, 16)
	for _, p in
		{ { x = -1200, z = 200 }, { x = 0, z = 0 }, { x = 1400, z = 900 }, { x = 333, z = -77 } }
	do
		local sx, sy = MapProjection.toScreen(t, p.x, p.z)
		local x, z = MapProjection.fromScreen(t, sx, sy)
		harness.near(x, p.x, 1e-6)
		harness.near(z, p.z, 1e-6)
	end
end)

harness.test("zoom keeps the point under the finger or cursor fixed on screen", function()
	local t = MapProjection.fit(FIT_BOUNDS, 300, 200, 10)
	local px, py = 120, 90
	local wx, wz = MapProjection.fromScreen(t, px, py)
	local zoomed = MapProjection.zoomAt(t, px, py, 2.5, 0.5, 20)
	local sx, sy = MapProjection.toScreen(zoomed, wx, wz)
	harness.near(sx, px, 1e-6, "anchor moved horizontally")
	harness.near(sy, py, 1e-6, "anchor moved vertically")
	harness.near(zoomed.scale, t.scale * 2.5, 1e-9)
end)

harness.test("zoom is clamped to the allowed scale range", function()
	local t = MapProjection.fit(FIT_BOUNDS, 300, 200, 10)
	harness.near(MapProjection.zoomAt(t, 0, 0, 1000, 0.5, 4).scale, 4, 1e-9)
	harness.near(MapProjection.zoomAt(t, 0, 0, 0.0001, 0.5, 4).scale, 0.5, 1e-9)
end)

harness.test("pan shifts the offsets and nothing else", function()
	local t = MapProjection.fit(FIT_BOUNDS, 300, 200, 10)
	local p = MapProjection.panBy(t, 15, -5)
	harness.near(p.ox, t.ox + 15, 1e-9)
	harness.near(p.oy, t.oy - 5, 1e-9)
	harness.near(p.scale, t.scale, 1e-9)
end)

harness.test("clampToView stops the network leaving the screen entirely", function()
	local t = MapProjection.fit(FIT_BOUNDS, 300, 200, 10)
	local flung = MapProjection.panBy(t, 10000, 10000)
	local clamped = MapProjection.clampToView(flung, FIT_BOUNDS, 300, 200)
	-- At least a quarter of the view stays covered, so the right edge of content sits at or
	-- after the clamp boundary, never past it.
	harness.truthy(clamped.ox <= 300 - math.min(100 * t.scale, 300 * 0.25) + 1e-9)
	harness.truthy(clamped.oy <= 200 - math.min(50 * t.scale, 200 * 0.25) + 1e-9)
end)

harness.test("a horizontal segment has angle 0 and its length in pixels", function()
	local t = { minX = 0, minZ = 0, scale = 1, ox = 0, oy = 0 }
	local d = MapProjection.drawSegment(t, { x1 = 0, z1 = 0, x2 = 10, z2 = 0 })
	harness.near(d.length, 10, 1e-9)
	harness.near(d.angleDeg, 0, 1e-9)
	harness.near(d.cx, 5, 1e-9)
end)

harness.test("north is up: a line running north-east (east, and -Z) rises on the map", function()
	-- Z grows south, so north-east is +X and -Z. From (0,10) to (10,0) the screen goes right and up.
	local t = { minX = 0, minZ = 0, scale = 1, ox = 0, oy = 0 }
	local d = MapProjection.drawSegment(t, { x1 = 0, z1 = 10, x2 = 10, z2 = 0 })
	harness.near(d.angleDeg, -45, 1e-9, "north-east should be -45° in screen space")
	harness.near(d.length, math.sqrt(200), 1e-9)
end)

harness.test("a source hands back the table it was given", function()
	local source = NetworkSource.fromTable("stub", fixture)
	local data, reason = source.load()
	harness.truthy(data == fixture, "the same table, not a copy")
	harness.falsy(reason, "no reason when loading succeeds")
end)

harness.test("an unavailable source returns no data and a reason", function()
	local source = NetworkSource.unavailable("missing", "docs/rail/NETWORK.md not generated")
	local data, reason = source.load()
	harness.falsy(data, "no data")
	harness.equal(reason, "docs/rail/NETWORK.md not generated")
end)
