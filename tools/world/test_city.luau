--!strict
-- Lune acceptance test: validates the generator's actual route geometry and reserved massing.
local suite = require("../../tests/support/suite")
local expect = suite.expect
local config = require("../../src/server/World/CityConfig")
local generator = require("../../src/server/World/CityGenerator")

local plan = generator.generate(config)

local function pointInsideBuilding(x: number, z: number, building: any, margin: number): boolean
	local dx = x - building.x
	local dz = z - building.z
	local width = if building.rotation == 90 then building.depth else building.width
	local depth = if building.rotation == 90 then building.width else building.depth
	return math.abs(dx) < width / 2 + margin and math.abs(dz) < depth / 2 + margin
end

suite.test("city slice has the required varied massing and landmarks", function()
	expect.ok(plan.stats.buildingCount >= config.buildingBudget.min)
	expect.ok(plan.stats.buildingCount <= config.buildingBudget.max)
	expect.equal(plan.stats.landmarkCount, 12)
	expect.equal(plan.stats.superblockCount, #config.blocks.superblocks)
	expect.equal(plan.stats.pocketSquareCount, #config.pocketSquares)
	expect.ok(plan.stats.blockCount >= 20)
	local heights = {}
	for _, building in ipairs(plan.buildings) do
		heights[building.height] = true
	end
	local uniqueHeights = 0
	for _ in pairs(heights) do
		uniqueHeights += 1
	end
	expect.ok(uniqueHeights >= 20, "building heights must vary, not repeat as a wall of boxes")
	local frontages = {}
	for _, building in ipairs(plan.buildings) do
		frontages[building.frontage] = true
	end
	for _, frontage in ipairs({ "shopfront", "recessed-entry", "awning", "stone-plinth" }) do
		expect.ok(frontages[frontage], "missing ground-floor treatment: " .. frontage)
	end
end)

suite.test("walk acceptance route is continuous and exceeds 1500 studs", function()
	expect.ok(
		plan.stats.routeLength >= 1500,
		"route is shorter than the 1500-stud acceptance floor"
	)
	expect.equal(plan.stats.routeLinkCount, #plan.route - 1)
	expect.ok(#plan.route >= 8)
	expect.ok(
		plan.ground.thickness > 0,
		"ground must be a physical slab, not an infinite visual plane"
	)
	local expectedLabels = {
		"sidewalk spawn",
		"historic grid sidewalk",
		"public square",
		"station forecourt",
		"concourse",
		"test platform",
	}
	local labels = {}
	for _, point in ipairs(plan.route) do
		labels[point.label] = true
		expect.ok(
			point.x >= plan.ground.centerX - plan.ground.width / 2
				and point.x <= plan.ground.centerX + plan.ground.width / 2
				and point.z >= plan.ground.centerZ - plan.ground.depth / 2
				and point.z <= plan.ground.centerZ + plan.ground.depth / 2,
			"route point falls beyond the collidable ground footprint"
		)
	end
	for _, label in ipairs(expectedLabels) do
		expect.ok(labels[label], "missing route stage: " .. label)
	end
	for index = 2, #plan.route do
		local prior = plan.route[index - 1]
		local current = plan.route[index]
		local dx = current.x - prior.x
		local dz = current.z - prior.z
		expect.ok(
			math.sqrt(dx * dx + dz * dz) > 0,
			"duplicate route waypoint creates a zero-length link"
		)
	end
	expect.near(plan.stats.routeLength, generator.routeLength(plan.route), 1e-6)
end)

suite.test(
	"route centerline stays clear of all building and landmark collision footprints",
	function()
		for segmentIndex = 2, #plan.route do
			local first = plan.route[segmentIndex - 1]
			local last = plan.route[segmentIndex]
			local dx = last.x - first.x
			local dz = last.z - first.z
			local length = math.sqrt(dx * dx + dz * dz)
			local steps = math.max(1, math.ceil(length / 2))
			for step = 0, steps do
				local t = step / steps
				local x = first.x + dx * t
				local z = first.z + dz * t
				for _, buildingList in ipairs({ plan.buildings, plan.landmarks }) do
					for _, building in ipairs(buildingList) do
						expect.ok(
							not pointInsideBuilding(x, z, building, 4),
							"route intersects massing at "
								.. building.name
								.. " on segment "
								.. tostring(segmentIndex - 1)
						)
					end
				end
			end
		end
	end
)

suite.test("diagonal and jog lanes stay clear of building collision footprints", function()
	for _, street in ipairs(plan.streets) do
		if street.axis == "segment" then
			local dx = street.finishX - street.startX
			local dz = street.finishZ - street.startZ
			local length = math.sqrt(dx * dx + dz * dz)
			local steps = math.max(1, math.ceil(length / 3))
			local margin = street.width / 2 + config.streets.sidewalkWidth / 2
			for step = 0, steps do
				local t = step / steps
				local x = street.startX + dx * t
				local z = street.startZ + dz * t
				for _, buildingList in ipairs({ plan.buildings, plan.landmarks }) do
					for _, building in ipairs(buildingList) do
						expect.ok(
							not pointInsideBuilding(x, z, building, margin),
							street.name .. " overlaps massing at " .. building.name
						)
					end
				end
			end
		end
	end
end)

suite.test("superblocks merge cells and junction squares clear conflicting street runs", function()
	local expectedBlocks = (#config.streets.gridX - 1) * (#config.streets.gridZ - 1)
	for _, group in ipairs(config.blocks.superblocks) do
		expectedBlocks -= #group.cells - 1
	end
	expect.equal(plan.stats.blockCount, expectedBlocks)
	expect.equal(plan.stats.superblockCount, 4)
	expect.equal(plan.stats.pocketSquareCount, 2)
	expect.equal(#plan.squareStreetCuts, 5)
	for _, gap in ipairs(plan.streetGaps) do
		for _, street in ipairs(plan.streets) do
			if street.axis == gap.axis and street.center == gap.center then
				expect.ok(
					street.finish <= gap.start or street.start >= gap.finish,
					"merged cell edge still has a road through it"
				)
			end
		end
	end
	for _, square in ipairs(plan.pocketSquares) do
		for _, street in ipairs(plan.streets) do
			if street.axis == "segment" then
				local dx = street.finishX - street.startX
				local dz = street.finishZ - street.startZ
				local length = math.sqrt(dx * dx + dz * dz)
				local edgeRadius = street.width / 2
					+ config.streets.sidewalkWidth
					+ config.streets.curbWidth
				local insetX = edgeRadius * math.abs(dz) / length
				local insetZ = edgeRadius * math.abs(dx) / length
				local minX = square.centerX - square.width / 2 + insetX
				local maxX = square.centerX + square.width / 2 - insetX
				local minZ = square.centerZ - square.depth / 2 + insetZ
				local maxZ = square.centerZ + square.depth / 2 - insetZ
				local steps = math.max(1, math.ceil(length))
				for step = 0, steps do
					local t = step / steps
					local x = street.startX + dx * t
					local z = street.startZ + dz * t
					expect.ok(
						x <= minX or x >= maxX or z <= minZ or z >= maxZ,
						street.name .. " still cuts through " .. square.name
					)
				end
			else
				local profileHalfWidth = street.width / 2
					+ config.streets.sidewalkWidth
					+ config.streets.curbWidth
				local transverseCenter = if street.axis == "z"
					then square.centerX
					else square.centerZ
				local transverseHalfSize = if street.axis == "z"
					then square.width / 2
					else square.depth / 2
				if
					math.abs(street.center - transverseCenter) + profileHalfWidth
					<= transverseHalfSize
				then
					local squareCenter = if street.axis == "z"
						then square.centerZ
						else square.centerX
					local squareHalfSize = if street.axis == "z"
						then square.depth / 2
						else square.width / 2
					local cutStart = squareCenter - squareHalfSize
					local cutFinish = squareCenter + squareHalfSize
					expect.ok(
						street.finish <= cutStart or street.start >= cutFinish,
						"orthogonal street still crosses " .. square.name
					)
				end
			end
		end
	end
end)

suite.test("route follows the long sidewalk and every grid crossing has a radius cut", function()
	local avenue = nil
	for _, street in ipairs(plan.streets) do
		if street.axis == "z" and street.center == config.streets.stationAvenueX then
			avenue = street
		end
	end
	expect.ok(avenue ~= nil, "missing station avenue")
	expect.ok(avenue.start <= plan.route[1].z and avenue.finish >= plan.route[7].z)
	local eastSidewalkCenter = avenue.center + avenue.width / 2 + config.streets.sidewalkWidth / 2
	expect.near(plan.route[1].x, eastSidewalkCenter, 1e-6)
	expect.near(plan.route[2].x, eastSidewalkCenter, 1e-6)
	expect.near(plan.route[6].x, eastSidewalkCenter, 1e-6)
	expect.equal(#plan.intersections, #config.streets.gridX * #config.streets.gridZ)
	expect.equal(#config.streets.cutSegments, 6)
	local xSpacings = {}
	for index = 2, #config.streets.gridX do
		xSpacings[config.streets.gridX[index] - config.streets.gridX[index - 1]] = true
	end
	local spacingVariety = 0
	for _ in pairs(xSpacings) do
		spacingVariety += 1
	end
	expect.ok(spacingVariety >= 4, "historic blocks need irregular street spacing")
	for _, intersection in ipairs(plan.intersections) do
		expect.equal(intersection.radius, config.streets.cornerRadius)
	end
end)

suite.test(
	"walk surfaces are parameterized and the estimated slice stays within phone budget",
	function()
		expect.equal(config.streets.sidewalkWidth, 3.5)
		expect.ok(config.streets.cornerRadius > 0)
		expect.ok(plan.stats.estimatedParts < plan.stats.partBudget)
		expect.equal(plan.stats.partBudget, 25000)
		local streetParts = 0
		for _, street in ipairs(plan.streets) do
			expect.ok(
				street.width == config.streets.localWidth
					or street.width == config.streets.laneWidth
					or street.width == config.streets.arterialWidth
			)
			if street.axis == "segment" then
				streetParts += 5
			else
				local curbGaps = {}
				for _, intersection in ipairs(plan.intersections) do
					if
						(street.axis == "z" and intersection.x == street.center)
						or (street.axis == "x" and intersection.z == street.center)
					then
						local coordinate = if street.axis == "z"
							then intersection.z
							else intersection.x
						local crossingWidth = if street.axis == "z"
							then intersection.widthZ
							else intersection.widthX
						local halfGap = crossingWidth / 2 + intersection.radius
						table.insert(
							curbGaps,
							{ start = coordinate - halfGap, finish = coordinate + halfGap }
						)
					end
				end
				table.sort(curbGaps, function(a, b)
					return a.start < b.start
				end)
				local cursor = street.start
				local curbPieces = 0
				for _, gap in ipairs(curbGaps) do
					local gapStart = math.max(street.start, gap.start)
					local gapFinish = math.min(street.finish, gap.finish)
					if gapStart > cursor then
						curbPieces += 1
					end
					cursor = math.max(cursor, gapFinish)
				end
				if cursor < street.finish then
					curbPieces += 1
				end
				streetParts += 3 + 2 * curbPieces
			end
		end
		local ordinaryParts = 0
		for _, building in ipairs(plan.buildings) do
			local facadeParts = if building.frontage == "shopfront"
				then 4
				elseif building.frontage == "recessed-entry" then 2
				elseif building.frontage == "awning" then 1
				else 0
			local upperHeight = building.height - math.min(10, building.height / 3)
			local windowRows = math.max(1, math.floor((upperHeight - 2) / 8))
			ordinaryParts += 3 + facadeParts + 6 * windowRows
		end
		local landmarkParts = #plan.landmarks * 3
		for _, landmark in ipairs(plan.landmarks) do
			if landmark.style == "tower" then
				landmarkParts += 1
			end
		end
		local expectedParts = 1
			+ streetParts
			+ ordinaryParts
			+ landmarkParts
			+ 2
			+ #plan.pocketSquares
			+ 24
			+ plan.stats.routeLinkCount
			+ 1
		expect.equal(
			plan.stats.estimatedParts,
			expectedParts,
			"part budget estimate must match the builder recipe"
		)
		expect.ok(expectedParts < plan.stats.partBudget)
	end
)

suite.test("experimental platform connects the concourse and matches rail datum", function()
	local station = config.station
	local rampRun = station.rampEndZ - station.rampStartZ
	local rise = station.platformTopY - 0.63
	local rearWallZ = station.concourseZ + station.depth * 0.275
	expect.ok(station.rampStartZ < rearWallZ and station.rampEndZ > rearWallZ)
	expect.ok(rampRun > 0 and rise / rampRun < 1 / 12, "ramp slope exceeds 1:12")
	expect.ok(station.rampEndZ >= station.platformCenterZ - station.platformDepth / 2 - 1)
	expect.near(station.platformTopY - station.railTopY, 2.7142857, 1e-5)
	expect.near(
		station.railCenterZ - (station.platformCenterZ + station.platformDepth / 2),
		6.0714,
		1e-5
	)
	expect.ok(
		station.platformCenterZ + station.platformDepth / 2
			< plan.ground.centerZ + plan.ground.depth / 2
	)
	local trainLength = 75 + 1.7857 + 71.4286
	expect.ok(station.platformWidth > trainLength, "prototype does not fit platform")
	expect.ok(station.railMinX >= plan.ground.centerX - plan.ground.width / 2)
	expect.ok(station.railMaxX <= plan.ground.centerX + plan.ground.width / 2)
	expect.ok(station.railCenterZ + 6 < plan.ground.centerZ + plan.ground.depth / 2)
	expect.ok(station.centerX - station.railMinX > trainLength / 2)
	expect.ok(station.railMaxX - station.centerX > trainLength / 2)
end)

suite.test("facade offsets follow Roblox Y-axis rotation", function()
	local facade = require("../../src/server/World/FacadeMath")
	local x0, z0 = facade.worldPoint(100, 200, 0, 3, -10)
	expect.near(x0, 103, 1e-9)
	expect.near(z0, 190, 1e-9)
	local x90, z90 = facade.worldPoint(100, 200, 90, 3, -10)
	expect.near(x90, 90, 1e-9)
	expect.near(z90, 197, 1e-9)
end)

local passed, failed = suite.run()
print(string.format("\nCity acceptance: %d passed, %d failed", passed, failed))
if failed > 0 then
	error(string.format("city acceptance failed: %d failure(s)", failed))
end
