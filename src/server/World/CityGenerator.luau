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

local function roadKind(
	value: number,
	index: number,
	count: number,
	stationCoordinate: number?,
	laneCoordinates: { number }
): string
	if index == 1 or index == count or value == stationCoordinate then
		return "arterial"
	end
	if table.find(laneCoordinates, value) ~= nil then
		return "lane"
	end
	return "local"
end

local function roadWidth(kind: string, streets: any): number
	if kind == "arterial" then
		return streets.arterialWidth
	elseif kind == "lane" then
		return streets.laneWidth
	end
	return streets.localWidth
end

local function distanceToSegment(
	px: number,
	pz: number,
	x1: number,
	z1: number,
	x2: number,
	z2: number
): number
	local dx = x2 - x1
	local dz = z2 - z1
	local lengthSquared = dx * dx + dz * dz
	local t = math.clamp(((px - x1) * dx + (pz - z1) * dz) / lengthSquared, 0, 1)
	local nearestX = x1 + t * dx
	local nearestZ = z1 + t * dz
	local offsetX = px - nearestX
	local offsetZ = pz - nearestZ
	return math.sqrt(offsetX * offsetX + offsetZ * offsetZ)
end

local function squareContains(x: number, z: number, config: any): boolean
	-- Reserve a small public-realm apron as well as the square footprint, so its approaches
	-- cannot be sealed off by a lot placed directly against the paving edge.
	if
		math.abs(x - config.square.centerX) < config.square.width / 2 + 38
		and math.abs(z - config.square.centerZ) < config.square.depth / 2 + 24
	then
		return true
	end
	for _, square in ipairs(config.pocketSquares) do
		if
			math.abs(x - square.centerX) < square.width / 2 + 12
			and math.abs(z - square.centerZ) < square.depth / 2 + 12
		then
			return true
		end
	end
	return false
end

local function stationContains(x: number, z: number, config: any): boolean
	return math.abs(x - config.station.centerX) < config.station.width / 2 + 20
		and z > config.station.forecourtZ - 18
		and z < config.station.entryZ + 28
end

function CityGenerator.generate(config: any): any
	local plan: any = {
		ground = config.ground,
		streets = {},
		intersections = {},
		streetGaps = {},
		blocks = {},
		buildings = {},
		landmarks = {},
		plaza = config.square,
		pocketSquares = config.pocketSquares,
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

	for index, x in ipairs(streets.gridX) do
		local kind = roadKind(x, index, #streets.gridX, streets.stationAvenueX, streets.laneX)
		table.insert(plan.streets, {
			axis = "z",
			center = x,
			start = streets.minZ,
			finish = streets.maxZ,
			width = roadWidth(kind, streets),
			kind = kind,
		})
	end
	for index, z in ipairs(streets.gridZ) do
		local kind = roadKind(z, index, #streets.gridZ, nil, streets.laneZ)
		table.insert(plan.streets, {
			axis = "x",
			center = z,
			start = streets.minX,
			finish = streets.maxX,
			width = roadWidth(kind, streets),
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
	for _, cut in ipairs(streets.cutSegments) do
		table.insert(plan.streets, {
			axis = "segment",
			startX = cut.x1,
			startZ = cut.z1,
			finishX = cut.x2,
			finishZ = cut.z2,
			width = streets.laneWidth,
			kind = "lane",
			name = cut.name,
		})
	end

	local landmarkLots: { { x: number, z: number, name: string, style: string, height: number } } =
		{
			{ x = -570, z = -375, name = "Old Town Clock Tower", style = "tower", height = 112 },
			{ x = -275, z = -375, name = "St. Elian's Church", style = "church", height = 78 },
			{ x = -120, z = -370, name = "Civic Archive Tower", style = "tower", height = 96 },
			{ x = 520, z = -370, name = "North Gate Hotel", style = "hotel", height = 64 },
			{ x = -570, z = -220, name = "Covered Market Hall", style = "market", height = 34 },
			{ x = -120, z = -220, name = "Guildhall", style = "civic", height = 58 },
			{ x = 520, z = -220, name = "Riverside Exchange", style = "tower", height = 105 },
			{ x = -570, z = 75, name = "Opera House", style = "civic", height = 48 },
			{ x = -120, z = 75, name = "South Arcade Tower", style = "tower", height = 88 },
			{ x = 520, z = 75, name = "Museum of Navigation", style = "civic", height = 42 },
			{ x = -570, z = 370, name = "West Bastion Tower", style = "tower", height = 72 },
			{ x = 520, z = 370, name = "East Gate Basilica", style = "church", height = 66 },
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
			local leftKind = roadKind(
				streets.gridX[xi],
				xi,
				#streets.gridX,
				streets.stationAvenueX,
				streets.laneX
			)
			local rightKind = roadKind(
				streets.gridX[xi + 1],
				xi + 1,
				#streets.gridX,
				streets.stationAvenueX,
				streets.laneX
			)
			local topKind = roadKind(streets.gridZ[zi], zi, #streets.gridZ, nil, streets.laneZ)
			local bottomKind =
				roadKind(streets.gridZ[zi + 1], zi + 1, #streets.gridZ, nil, streets.laneZ)
			local left = streets.gridX[xi]
				+ roadWidth(leftKind, streets) / 2
				+ config.blocks.streetInset
			local right = streets.gridX[xi + 1]
				- roadWidth(rightKind, streets) / 2
				- config.blocks.streetInset
			local top = streets.gridZ[zi]
				+ roadWidth(topKind, streets) / 2
				+ config.blocks.streetInset
			local bottom = streets.gridZ[zi + 1]
				- roadWidth(bottomKind, streets) / 2
				- config.blocks.streetInset
			local block = {
				id = blockIndex + 1,
				xi = xi,
				zi = zi,
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
					for _, street in ipairs(plan.streets) do
						if street.axis == "segment" then
							local clearance = street.width / 2
								+ streets.sidewalkWidth
								+ math.max(config.blocks.maxWidth, config.blocks.maxDepth) / 2
								+ config.blocks.lotGap
							if
								distanceToSegment(
									x,
									z,
									street.startX,
									street.startZ,
									street.finishX,
									street.finishZ
								) < clearance
							then
								reserved = true
							end
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
							frontage = if h % 5 == 0
								then "shopfront"
								elseif h % 4 == 1 then "recessed-entry"
								elseif h % 3 == 0 then "awning"
								else "stone-plinth",
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

	-- Merge adjacent cells into explicit larger parcels and remove their shared road runs.
	-- Freed road footprints become open courtyard space within each irregular superblock.
	local cellBlocks = plan.blocks
	local cellByKey = {}
	for _, cell in ipairs(cellBlocks) do
		cellByKey[tostring(cell.xi) .. ":" .. tostring(cell.zi)] = cell
	end
	local mergedBlocks = {}
	local claimedCells = {}
	local function key(xi: number, zi: number): string
		return tostring(xi) .. ":" .. tostring(zi)
	end
	for _, group in ipairs(config.blocks.superblocks) do
		local groupedCells = {}
		local memberSet = {}
		local minX = math.huge
		local maxX = -math.huge
		local minZ = math.huge
		local maxZ = -math.huge
		for _, reference in ipairs(group.cells) do
			local cellKey = key(reference[1], reference[2])
			local cell = cellByKey[cellKey]
			if cell == nil or claimedCells[cellKey] then
				error("Invalid or overlapping superblock cell " .. cellKey)
			end
			claimedCells[cellKey] = true
			memberSet[cellKey] = true
			table.insert(groupedCells, cell)
			minX = math.min(minX, cell.minX)
			maxX = math.max(maxX, cell.maxX)
			minZ = math.min(minZ, cell.minZ)
			maxZ = math.max(maxZ, cell.maxZ)
		end
		for _, cell in ipairs(groupedCells) do
			local eastKey = key(cell.xi + 1, cell.zi)
			if memberSet[eastKey] then
				table.insert(plan.streetGaps, {
					axis = "z",
					center = streets.gridX[cell.xi + 1],
					start = streets.gridZ[cell.zi],
					finish = streets.gridZ[cell.zi + 1],
				})
			end
			local southKey = key(cell.xi, cell.zi + 1)
			if memberSet[southKey] then
				table.insert(plan.streetGaps, {
					axis = "x",
					center = streets.gridZ[cell.zi + 1],
					start = streets.gridX[cell.xi],
					finish = streets.gridX[cell.xi + 1],
				})
			end
		end
		table.insert(mergedBlocks, {
			id = #mergedBlocks + 1,
			name = group.name,
			superblock = true,
			cells = groupedCells,
			minX = minX,
			maxX = maxX,
			minZ = minZ,
			maxZ = maxZ,
		})
	end
	for _, cell in ipairs(cellBlocks) do
		if not claimedCells[key(cell.xi, cell.zi)] then
			table.insert(mergedBlocks, {
				id = #mergedBlocks + 1,
				name = "Block " .. tostring(cell.id),
				superblock = false,
				cells = { cell },
				minX = cell.minX,
				maxX = cell.maxX,
				minZ = cell.minZ,
				maxZ = cell.maxZ,
			})
		end
	end
	plan.blocks = mergedBlocks

	local originalStreets = plan.streets
	local openStreetRuns = {}
	for _, street in ipairs(originalStreets) do
		if street.axis == "segment" then
			table.insert(openStreetRuns, street)
		else
			local gaps = {}
			for _, gap in ipairs(plan.streetGaps) do
				if gap.axis == street.axis and gap.center == street.center then
					table.insert(gaps, gap)
				end
			end
			table.sort(gaps, function(a, b)
				return a.start < b.start
			end)
			local cursor = street.start
			for _, gap in ipairs(gaps) do
				local gapStart = math.max(street.start, gap.start)
				local gapFinish = math.min(street.finish, gap.finish)
				if gapStart > cursor then
					local run = table.clone(street)
					run.start = cursor
					run.finish = gapStart
					table.insert(openStreetRuns, run)
				end
				cursor = math.max(cursor, gapFinish)
			end
			if cursor < street.finish then
				local run = table.clone(street)
				run.start = cursor
				run.finish = street.finish
				table.insert(openStreetRuns, run)
			end
		end
	end
	plan.streets = openStreetRuns

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
	-- Exact Part count for the current builder recipe, including facade accents and
	-- radius-cut curb segments; diagonal lanes use five Parts each.
	local streetPartCount = 0
	for _, street in ipairs(plan.streets) do
		if street.axis == "segment" then
			streetPartCount += 5
		else
			local curbGaps = {}
			for _, intersection in ipairs(plan.intersections) do
				if
					(street.axis == "z" and intersection.x == street.center)
					or (street.axis == "x" and intersection.z == street.center)
				then
					local coordinate = if street.axis == "z" then intersection.z else intersection.x
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
			streetPartCount += 3 + 2 * curbPieces
		end
	end
	local ordinaryPartCount = 0
	for _, building in ipairs(plan.buildings) do
		local facadeParts = if building.frontage == "shopfront"
			then 4
			elseif building.frontage == "recessed-entry" then 2
			elseif building.frontage == "awning" then 1
			else 0
		ordinaryPartCount += 3 + facadeParts
	end
	local estimatedParts = 1
		+ streetPartCount
		+ ordinaryPartCount
		+ #plan.landmarks * 3
		+ extraTowerParts
		+ 2
		+ #plan.pocketSquares
		+ 8
		+ (#plan.route - 1)
		+ 1
	plan.stats = {
		blockCount = #plan.blocks,
		superblockCount = #config.blocks.superblocks,
		pocketSquareCount = #plan.pocketSquares,
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
