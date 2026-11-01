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
	expect.equal(#plan.intersections, 36)
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
		for _, street in ipairs(plan.streets) do
			expect.ok(
				street.width == config.streets.localWidth
					or street.width == config.streets.arterialWidth
			)
		end
	end
)

local passed, failed = suite.run()
print(string.format("\nCity acceptance: %d passed, %d failed", passed, failed))
if failed > 0 then
	error(string.format("city acceptance failed: %d failure(s)", failed))
end
