--!strict
-- Pure deterministic city plan. Roblox instance creation lives in CityBuilder, so the exact
-- geometry used by the server can also be tested and rendered headlessly with Lune/Python.
local CityGenerator = {}

export type Segment = {
	axis: string,
	center: number,
	start: number,
	finish: number,
	width: number,
	kind: string,
}

export type Building = {
	x: number,
	z: number,
	width: number,
	depth: number,
	height: number,
	rotation: number,
	style: string,
	landmark: boolean,
	name: string,
}

export type Point = { x: number, z: number, label: string }

local function hash(a: number, b: number, seed: number): number
	local value = (a * 73856093 + b * 19349663 + seed * 83492791) % 2147483647
	value = (value * 48271) % 2147483647
	return value
end

local function range(value: number, minimum: number, maximum: number): number
	return minimum + (value % (maximum - minimum + 1))
end

local function squareContains(x: number, z: number, config: any): boolean
	-- Reserve a small public-realm apron as well as the square footprint, so its approaches
	-- cannot be sealed off by a lot placed directly against the paving edge.
	return math.abs(x - config.square.centerX) < config.square.width / 2 + 38
		and math.abs(z - config.square.centerZ) < config.square.depth / 2 + 24
end

local function stationContains(x: number, z: number, config: any): boolean
	return math.abs(x - config.station.centerX) < config.station.width / 2 + 20
		and z > config.station.forecourtZ - 18
		and z < config.station.entryZ + 28
end

function CityGenerator.generate(config: any): any
	local plan = {
		ground = config.ground,
		streets = {},
		intersections = {},
		blocks = {},
		buildings = {},
		landmarks = {},
		plaza = config.square,
		station = config.station,
		route = {},
		districtBounds = {
			{
				name = "District A — Historic Centre slice",
				minX = config.ground.centerX - config.ground.width / 2,
				maxX = config.ground.centerX + config.ground.width / 2,
				minZ = config.ground.centerZ - config.ground.depth / 2,
				maxZ = config.ground.centerZ + config.ground.depth / 2,
			},
		},
	}
	local streets = config.streets

	for _, x in ipairs(streets.gridX) do
		local kind = if x == streets.stationAvenueX then "arterial" else "local"
		table.insert(plan.streets, {
			axis = "z",
			center = x,
			start = streets.minZ,
			finish = streets.maxZ,
			width = if kind == "arterial" then streets.arterialWidth else streets.localWidth,
			kind = kind,
		})
	end
	for _, z in ipairs(streets.gridZ) do
		local kind = if z == 0 then "arterial" else "local"
		table.insert(plan.streets, {
			axis = "x",
			center = z,
			start = streets.minX,
			finish = streets.maxX,
			width = if kind == "arterial" then streets.arterialWidth else streets.localWidth,
			kind = kind,
		})
	end
	for _, vertical in ipairs(plan.streets) do
		if vertical.axis == "z" then
			for _, horizontal in ipairs(plan.streets) do
				if
					horizontal.axis == "x"
					and vertical.center >= horizontal.start
					and vertical.center <= horizontal.finish
					and horizontal.center >= vertical.start
					and horizontal.center <= vertical.finish
				then
					table.insert(plan.intersections, {
						x = vertical.center,
						z = horizontal.center,
						radius = streets.cornerRadius,
						widthX = vertical.width,
						widthZ = horizontal.width,
					})
				end
			end
		end
	end

	local landmarkLots: { { x: number, z: number, name: string, style: string, height: number } } =
		{
			{ x = -480, z = -315, name = "Old Town Clock Tower", style = "tower", height = 112 },
			{ x = -240, z = -315, name = "St. Elian's Church", style = "church", height = 78 },
			{ x = 0, z = -315, name = "Civic Archive Tower", style = "tower", height = 96 },
			{ x = 480, z = -315, name = "North Gate Hotel", style = "hotel", height = 64 },
			{ x = -480, z = -105, name = "Covered Market Hall", style = "market", height = 34 },
			{ x = 0, z = -105, name = "Guildhall", style = "civic", height = 58 },
			{ x = 480, z = -105, name = "Riverside Exchange", style = "tower", height = 105 },
			{ x = -480, z = 105, name = "Opera House", style = "civic", height = 48 },
			{ x = 0, z = 105, name = "South Arcade Tower", style = "tower", height = 88 },
			{ x = 480, z = 105, name = "Museum of Navigation", style = "civic", height = 42 },
			{ x = -480, z = 315, name = "West Bastion Tower", style = "tower", height = 72 },
			{ x = 480, z = 315, name = "East Gate Basilica", style = "church", height = 66 },
		}
	for _, item in ipairs(landmarkLots) do
		table.insert(plan.landmarks, {
			x = item.x,
			z = item.z,
			width = if item.style == "market" then 86 else 44,
			depth = if item.style == "market" then 58 else 42,
			height = item.height,
			rotation = 0,
			style = item.style,
			landmark = true,
			name = item.name,
		})
	end

	local blockIndex = 0
	for xi = 1, #streets.gridX - 1 do
		for zi = 1, #streets.gridZ - 1 do
			local left = streets.gridX[xi] + streets.localWidth / 2 + config.blocks.streetInset
			local right = streets.gridX[xi + 1] - streets.localWidth / 2 - config.blocks.streetInset
			local top = streets.gridZ[zi] + streets.localWidth / 2 + config.blocks.streetInset
			local bottom = streets.gridZ[zi + 1]
				- streets.localWidth / 2
				- config.blocks.streetInset
			local block = {
				id = blockIndex + 1,
				minX = left,
				maxX = right,
				minZ = top,
				maxZ = bottom,
			}
			table.insert(plan.blocks, block)
			blockIndex += 1

			for lotX = 1, config.blocks.lotsAcross do
				for lotZ = 1, config.blocks.lotsDeep do
					local cellWidth = (right - left) / config.blocks.lotsAcross
					local cellDepth = (bottom - top) / config.blocks.lotsDeep
					local x = left + (lotX - 0.5) * cellWidth
					local z = top + (lotZ - 0.5) * cellDepth
					local reserved = squareContains(x, z, config) or stationContains(x, z, config)
					for _, landmark in ipairs(plan.landmarks) do
						if
							math.abs(x - landmark.x) < landmark.width / 2 + 23
							and math.abs(z - landmark.z) < landmark.depth / 2 + 23
						then
							reserved = true
						end
					end
					if not reserved then
						local h = hash(blockIndex, lotX * 17 + lotZ, config.seed)
						local plotWidth = math.min(
							cellWidth - config.blocks.lotGap,
							range(h, config.blocks.minWidth, config.blocks.maxWidth)
						)
						local plotDepth = math.min(
							cellDepth - config.blocks.lotGap,
							range(
								math.floor(h / 17),
								config.blocks.minDepth,
								config.blocks.maxDepth
							)
						)
						table.insert(plan.buildings, {
							x = x,
							z = z,
							width = plotWidth,
							depth = plotDepth,
							height = range(
								math.floor(h / 31),
								config.blocks.minHeight,
								config.blocks.maxHeight
							),
							rotation = if h % 4 == 0 then 90 else 0,
							style = if h % 5 == 0 then "corner-shop" else "historic-terrace",
							landmark = false,
							name = "Block "
								.. tostring(blockIndex)
								.. " Plot "
								.. tostring(lotX)
								.. "-"
								.. tostring(lotZ),
						})
					end
				end
			end
		end
	end

	-- An unbroken pedestrian spine: north sidewalk, square connection, forecourt, then concourse.
	-- Waypoints are centers of physical walk surfaces, not decorative route annotations.
	local sidewalkX = streets.stationAvenueX + streets.arterialWidth / 2 + streets.sidewalkWidth / 2
	local squareWest = config.square.centerX - config.square.width / 2
	local squareSouth = config.square.centerZ + config.square.depth / 2
	plan.route = {
		{ x = sidewalkX, z = -640, label = "sidewalk spawn" },
		{
			x = sidewalkX,
			z = config.square.centerZ - config.square.depth / 2,
			label = "historic grid sidewalk",
		},
		{
			x = squareWest,
			z = config.square.centerZ - config.square.depth / 2,
			label = "square north-west walk",
		},
		{ x = config.square.centerX, z = config.square.centerZ, label = "public square" },
		{ x = squareWest, z = squareSouth, label = "square south-west walk" },
		{ x = sidewalkX, z = squareSouth, label = "square south sidewalk return" },
		{ x = sidewalkX, z = config.station.forecourtZ, label = "station forecourt" },
		{ x = config.station.centerX, z = config.station.entryZ, label = "station entrance" },
		{ x = config.station.centerX, z = config.station.concourseZ, label = "concourse" },
	}

	local extraTowerParts = 0
	for _, landmark in ipairs(plan.landmarks) do
		if landmark.style == "tower" then
			extraTowerParts += 1
		end
	end
	-- Exact Part count for the current builder recipe: ground, road + two sidewalks +
	-- corner-radius curb segments per street, two per ordinary building, massing/crown per landmark (+ tower lanterns), plaza,
	-- fountain, eight station shell/colonnade Parts, one per route link, and spawn.
	local streetPartCount = 0
	for _, street in ipairs(plan.streets) do
		local crossingCount = 0
		for _, intersection in ipairs(plan.intersections) do
			if
				(street.axis == "z" and intersection.x == street.center)
				or (street.axis == "x" and intersection.z == street.center)
			then
				crossingCount += 1
			end
		end
		streetPartCount += 3 + 2 * (crossingCount + 1)
	end
	local estimatedParts = 1
		+ streetPartCount
		+ #plan.buildings * 2
		+ #plan.landmarks * 2
		+ extraTowerParts
		+ 2
		+ 8
		+ (#plan.route - 1)
		+ 1
	plan.stats = {
		blockCount = #plan.blocks,
		buildingCount = #plan.buildings,
		landmarkCount = #plan.landmarks,
		streetSegmentCount = #plan.streets,
		routeLength = CityGenerator.routeLength(plan.route),
		routeLinkCount = #plan.route - 1,
		estimatedParts = estimatedParts,
		partBudget = config.buildingBudget.partTarget,
	}
	return plan
end

function CityGenerator.routeLength(route: { Point }): number
	local distance = 0
	for index = 2, #route do
		local previous = route[index - 1]
		local current = route[index]
		local dx = current.x - previous.x
		local dz = current.z - previous.z
		distance += math.sqrt(dx * dx + dz * dz)
	end
	return distance
end

return CityGenerator
