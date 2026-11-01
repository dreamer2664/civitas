--!strict
-- Converts the pure city plan into anchored, collidable Roblox geometry. No per-frame work.
local CityBuilder = {}

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	material: Enum.Material,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material
	part.Color = color
	part.Parent = parent
	return part
end

local function makeModel(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function axisSize(axis: string, length: number, width: number, height: number): Vector3
	if axis == "x" then
		return Vector3.new(length, height, width)
	end
	return Vector3.new(width, height, length)
end

local function buildStreet(parent: Instance, street: any, config: any, intersections: { any })
	if street.axis == "segment" then
		local dx = street.finishX - street.startX
		local dz = street.finishZ - street.startZ
		local length = math.sqrt(dx * dx + dz * dz)
		local yaw = math.deg(math.atan2(dx, dz))
		local midpointX = (street.startX + street.finishX) / 2
		local midpointZ = (street.startZ + street.finishZ) / 2
		local perpendicularX = dz / length
		local perpendicularZ = -dx / length
		local road = createPart(
			parent,
			street.name .. "_Carriageway",
			Vector3.new(street.width, 0.3, length),
			Vector3.new(midpointX, 0.15, midpointZ),
			Enum.Material.Asphalt,
			Color3.fromRGB(72, 75, 77)
		)
		road.Orientation = Vector3.new(0, yaw, 0)
		road:SetAttribute("StreetKind", "narrow diagonal lane")
		for side = -1, 1, 2 do
			local sidewalkOffset = street.width / 2 + config.streets.sidewalkWidth / 2
			local curbOffset = street.width / 2
				+ config.streets.sidewalkWidth
				+ config.streets.curbWidth / 2
			local sidewalk = createPart(
				parent,
				street.name .. "_Sidewalk_" .. tostring(side),
				Vector3.new(config.streets.sidewalkWidth, 0.4, length),
				Vector3.new(
					midpointX + side * perpendicularX * sidewalkOffset,
					0.2,
					midpointZ + side * perpendicularZ * sidewalkOffset
				),
				Enum.Material.Concrete,
				Color3.fromRGB(184, 179, 165)
			)
			sidewalk.Orientation = Vector3.new(0, yaw, 0)
			sidewalk:SetAttribute("Walkable", true)
			local curb = createPart(
				parent,
				street.name .. "_Curb_" .. tostring(side),
				Vector3.new(config.streets.curbWidth, config.streets.curbHeight, length),
				Vector3.new(
					midpointX + side * perpendicularX * curbOffset,
					0.18,
					midpointZ + side * perpendicularZ * curbOffset
				),
				Enum.Material.Concrete,
				Color3.fromRGB(126, 124, 117)
			)
			curb.Orientation = Vector3.new(0, yaw, 0)
			curb:SetAttribute("AccessibleCornerRadius", config.streets.cornerRadius)
		end
		return
	end

	local length = street.finish - street.start
	local center = (street.start + street.finish) / 2
	local roadColor = if street.kind == "arterial"
		then Color3.fromRGB(62, 66, 69)
		else Color3.fromRGB(72, 75, 77)
	local road = createPart(
		parent,
		"Carriageway_" .. street.axis .. "_" .. tostring(street.center),
		axisSize(street.axis, length, street.width, 0.3),
		if street.axis == "x"
			then Vector3.new(center, 0.15, street.center)
			else Vector3.new(street.center, 0.15, center),
		Enum.Material.Asphalt,
		roadColor
	)
	road:SetAttribute("StreetKind", street.kind)

	for side = -1, 1, 2 do
		local offset = street.width / 2 + config.streets.sidewalkWidth / 2
		local curbOffset = street.width / 2
			+ config.streets.sidewalkWidth
			+ config.streets.curbWidth / 2
		local sidewalkCenter = street.center + side * offset
		local curbCenter = street.center + side * curbOffset
		local sidewalk = createPart(
			parent,
			"Sidewalk_" .. street.axis .. "_" .. tostring(street.center) .. "_" .. tostring(side),
			axisSize(street.axis, length, config.streets.sidewalkWidth, 0.4),
			if street.axis == "x"
				then Vector3.new(center, 0.2, sidewalkCenter)
				else Vector3.new(sidewalkCenter, 0.2, center),
			Enum.Material.Concrete,
			Color3.fromRGB(184, 179, 165)
		)
		sidewalk:SetAttribute("Walkable", true)
		local curbGaps = {}
		for _, intersection in ipairs(intersections) do
			local matches = if street.axis == "z"
				then intersection.x == street.center
				else intersection.z == street.center
			if matches then
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
		local piece = 0
		for _, gap in ipairs(curbGaps) do
			local gapStart = math.max(street.start, gap.start)
			local gapFinish = math.min(street.finish, gap.finish)
			if gapStart > cursor then
				piece += 1
				local curbLength = gapStart - cursor
				local curbCenterline = (gapStart + cursor) / 2
				local curb = createPart(
					parent,
					"CurbReturn_"
						.. street.axis
						.. "_"
						.. tostring(street.center)
						.. "_"
						.. tostring(side)
						.. "_"
						.. tostring(piece),
					axisSize(
						street.axis,
						curbLength,
						config.streets.curbWidth,
						config.streets.curbHeight
					),
					if street.axis == "x"
						then Vector3.new(curbCenterline, 0.18, curbCenter)
						else Vector3.new(curbCenter, 0.18, curbCenterline),
					Enum.Material.Concrete,
					Color3.fromRGB(126, 124, 117)
				)
				curb:SetAttribute("AccessibleCornerRadius", config.streets.cornerRadius)
			end
			cursor = math.max(cursor, gapFinish)
		end
		if cursor < street.finish then
			piece += 1
			local curbLength = street.finish - cursor
			local curbCenterline = (street.finish + cursor) / 2
			local curb = createPart(
				parent,
				"CurbReturn_"
					.. street.axis
					.. "_"
					.. tostring(street.center)
					.. "_"
					.. tostring(side)
					.. "_"
					.. tostring(piece),
				axisSize(
					street.axis,
					curbLength,
					config.streets.curbWidth,
					config.streets.curbHeight
				),
				if street.axis == "x"
					then Vector3.new(curbCenterline, 0.18, curbCenter)
					else Vector3.new(curbCenter, 0.18, curbCenterline),
				Enum.Material.Concrete,
				Color3.fromRGB(126, 124, 117)
			)
			curb:SetAttribute("AccessibleCornerRadius", config.streets.cornerRadius)
		end
	end
end

local function buildBuilding(parent: Instance, building: any, palette: any)
	local model = makeModel(parent, building.name)
	model:SetAttribute("Typology", building.style)
	model:SetAttribute("Landmark", building.landmark)
	model:SetAttribute("Frontage", building.frontage or "monumental-entry")
	local color = palette[building.style] or Color3.fromRGB(181, 164, 139)
	local groundHeight = math.min(10, building.height / 3)
	local upperHeight = building.height - groundHeight
	local groundColor = if building.frontage == "shopfront"
		then Color3.fromRGB(83, 104, 106)
		elseif building.frontage == "recessed-entry" then Color3.fromRGB(112, 98, 80)
		elseif building.frontage == "awning" then Color3.fromRGB(151, 119, 84)
		else Color3.fromRGB(139, 129, 111)
	local groundStorey = createPart(
		model,
		"GroundStorey_DarkerStreetBand",
		Vector3.new(building.width, groundHeight, building.depth),
		Vector3.new(building.x, groundHeight / 2, building.z),
		Enum.Material.Brick,
		groundColor
	)
	groundStorey.Orientation = Vector3.new(0, building.rotation, 0)
	local upper = createPart(
		model,
		"UpperMassing",
		Vector3.new(building.width, upperHeight, building.depth),
		Vector3.new(building.x, groundHeight + upperHeight / 2, building.z),
		Enum.Material.Brick,
		color
	)
	upper.Orientation = Vector3.new(0, building.rotation, 0)

	local function facadePart(
		name: string,
		localX: number,
		localY: number,
		localZ: number,
		size: Vector3,
		partColor: Color3,
		material: Enum.Material
	)
		local angle = math.rad(building.rotation)
		local worldX = building.x + localX * math.cos(angle) - localZ * math.sin(angle)
		local worldZ = building.z + localX * math.sin(angle) + localZ * math.cos(angle)
		local part =
			createPart(model, name, size, Vector3.new(worldX, localY, worldZ), material, partColor)
		part.Orientation = Vector3.new(0, building.rotation, 0)
		return part
	end

	if not building.landmark then
		if building.frontage == "shopfront" then
			facadePart(
				"DisplayWindow_Left",
				-building.width * 0.24,
				groundHeight * 0.58,
				-building.depth / 2 - 0.15,
				Vector3.new(building.width * 0.28, 4, 0.35),
				Color3.fromRGB(104, 145, 148),
				Enum.Material.Glass
			)
			facadePart(
				"DisplayWindow_Right",
				building.width * 0.24,
				groundHeight * 0.58,
				-building.depth / 2 - 0.15,
				Vector3.new(building.width * 0.28, 4, 0.35),
				Color3.fromRGB(104, 145, 148),
				Enum.Material.Glass
			)
			facadePart(
				"RecessedShopDoor",
				0,
				groundHeight * 0.42,
				-building.depth / 2 - 0.22,
				Vector3.new(4, groundHeight * 0.72, 0.45),
				Color3.fromRGB(54, 63, 62),
				Enum.Material.WoodPlanks
			)
			facadePart(
				"CanvasAwning",
				0,
				groundHeight * 0.96,
				-building.depth / 2 - 1.35,
				Vector3.new(building.width * 0.88, 1, 2.4),
				Color3.fromRGB(154, 91, 68),
				Enum.Material.Fabric
			)
		elseif building.frontage == "recessed-entry" then
			facadePart(
				"RecessedDoor",
				0,
				groundHeight * 0.4,
				-building.depth / 2 - 0.15,
				Vector3.new(4, groundHeight * 0.72, 0.3),
				Color3.fromRGB(63, 58, 52),
				Enum.Material.WoodPlanks
			)
			facadePart(
				"EntryLintel",
				0,
				groundHeight * 0.88,
				-building.depth / 2 - 0.22,
				Vector3.new(7, 1.3, 0.45),
				Color3.fromRGB(157, 142, 116),
				Enum.Material.Slate
			)
		elseif building.frontage == "awning" then
			facadePart(
				"SingleShopAwning",
				0,
				groundHeight * 0.9,
				-building.depth / 2 - 1.1,
				Vector3.new(building.width * 0.58, 0.8, 2),
				Color3.fromRGB(114, 124, 102),
				Enum.Material.Fabric
			)
		end
	end

	if not building.landmark then
		local roof = createPart(
			model,
			"RoofCap",
			Vector3.new(math.max(4, building.width - 2), 1.5, math.max(4, building.depth - 2)),
			Vector3.new(building.x, building.height + 0.75, building.z),
			Enum.Material.Slate,
			Color3.fromRGB(80, 70, 65)
		)
		roof.Orientation = Vector3.new(0, building.rotation, 0)
	else
		local roofHeight = if building.style == "tower" then 8 else 3
		createPart(
			model,
			"Crown",
			Vector3.new(building.width * 0.42, roofHeight, building.depth * 0.42),
			Vector3.new(building.x, building.height + roofHeight / 2, building.z),
			Enum.Material.Slate,
			Color3.fromRGB(104, 76, 54)
		)
		if building.style == "tower" then
			createPart(
				model,
				"Lantern",
				Vector3.new(7, 12, 7),
				Vector3.new(building.x, building.height + 14, building.z),
				Enum.Material.Metal,
				Color3.fromRGB(73, 82, 84)
			)
		end
	end
	return model
end

local function buildWalkLink(parent: Instance, first: any, last: any, index: number)
	local dx = last.x - first.x
	local dz = last.z - first.z
	local length = math.sqrt(dx * dx + dz * dz)
	local midpoint = Vector3.new((first.x + last.x) / 2, 0.43, (first.z + last.z) / 2)
	local slab = createPart(
		parent,
		"RouteLink_" .. tostring(index) .. "_" .. first.label,
		Vector3.new(7, 0.25, length + 0.25),
		midpoint,
		Enum.Material.Concrete,
		Color3.fromRGB(195, 190, 176)
	)
	slab.Orientation = Vector3.new(0, math.deg(math.atan2(dx, dz)), 0)
	slab:SetAttribute("Walkable", true)
end

local function buildStation(parent: Instance, station: any, palette: any)
	local model = makeModel(parent, "CentralStation_WalkablePlaceholder")
	model:SetAttribute("InterfaceStatus", "City shell only; station architecture handoff pending")
	local x = station.centerX
	local entry = station.entryZ
	createPart(
		model,
		"ConcourseFloor",
		Vector3.new(station.width - 20, 0.5, station.depth * 0.55),
		Vector3.new(x, 0.38, station.concourseZ),
		Enum.Material.Marble,
		Color3.fromRGB(186, 177, 158)
	)
	for side = -1, 1, 2 do
		createPart(
			model,
			"ConcourseSideWall_" .. tostring(side),
			Vector3.new(8, 19, station.depth * 0.55),
			Vector3.new(x + side * (station.width / 2 - 7), 9.5, station.concourseZ),
			Enum.Material.Brick,
			palette.civic
		)
	end
	createPart(
		model,
		"StationRearWall",
		Vector3.new(station.width - 20, 19, 8),
		Vector3.new(x, 9.5, station.concourseZ + station.depth * 0.275),
		Enum.Material.Brick,
		palette.civic
	)
	for _, offset in ipairs({ -56, -28, 28, 56 }) do
		createPart(
			model,
			"ForecourtColonnade_" .. tostring(offset),
			Vector3.new(5, 20, 5),
			Vector3.new(x + offset, 10, entry - 18),
			Enum.Material.Marble,
			Color3.fromRGB(206, 196, 174)
		)
	end
	return model
end

function CityBuilder.build(plan: any, config: any, rootParent: Instance): Model
	local old = rootParent:FindFirstChild("CivitasWorld")
	if old then
		old:Destroy()
	end
	local world = makeModel(rootParent, "CivitasWorld")
	world:SetAttribute("GeneratorVersion", "0.1.0")
	world:SetAttribute("Slice", "District A Historic Centre + central station approach")
	world:SetAttribute("PlannedBuildingCount", plan.stats.buildingCount)

	local city = makeModel(world, "City")
	local district = makeModel(city, "DistrictA_HistoricCentreSlice")
	district:SetAttribute("MinX", plan.districtBounds[1].minX)
	district:SetAttribute("MaxX", plan.districtBounds[1].maxX)
	district:SetAttribute("MinZ", plan.districtBounds[1].minZ)
	district:SetAttribute("MaxZ", plan.districtBounds[1].maxZ)
	local terrain = createPart(
		district,
		"CollidableGround",
		Vector3.new(config.ground.width, config.ground.thickness, config.ground.depth),
		Vector3.new(config.ground.centerX, -config.ground.thickness / 2, config.ground.centerZ),
		Enum.Material.Ground,
		Color3.fromRGB(91, 113, 76)
	)
	terrain:SetAttribute("GroundCoverage", "continuous slice base; no void beneath roads or plots")

	local streetsModel = makeModel(district, "Streets")
	for _, street in ipairs(plan.streets) do
		buildStreet(streetsModel, street, config, plan.intersections)
	end
	local buildingsModel = makeModel(district, "BuildingMassing")
	local palette = {
		["historic-terrace"] = Color3.fromRGB(186, 164, 133),
		["corner-shop"] = Color3.fromRGB(195, 177, 148),
		church = Color3.fromRGB(177, 166, 145),
		market = Color3.fromRGB(162, 131, 99),
		civic = Color3.fromRGB(194, 182, 155),
		tower = Color3.fromRGB(174, 157, 131),
		hotel = Color3.fromRGB(184, 168, 144),
	}
	for _, building in ipairs(plan.buildings) do
		buildBuilding(buildingsModel, building, palette)
	end
	for _, landmark in ipairs(plan.landmarks) do
		buildBuilding(buildingsModel, landmark, palette)
	end

	local publicRealm = makeModel(district, "PublicRealm")
	local plaza = createPart(
		publicRealm,
		"OldTownSquare",
		Vector3.new(plan.plaza.width, 0.45, plan.plaza.depth),
		Vector3.new(plan.plaza.centerX, 0.35, plan.plaza.centerZ),
		Enum.Material.Cobblestone,
		Color3.fromRGB(151, 143, 125)
	)
	plaza:SetAttribute("Walkable", true)
	local fountain = createPart(
		publicRealm,
		"SquareFountainBasin",
		Vector3.new(18, 1.1, 18),
		Vector3.new(plan.plaza.centerX, 0.95, plan.plaza.centerZ + 28),
		Enum.Material.Slate,
		Color3.fromRGB(112, 126, 128)
	)
	fountain.Shape = Enum.PartType.Cylinder
	fountain:SetAttribute("CollisionNote", "Low decorative basin; route passes west of basin")
	local station = buildStation(makeModel(district, "Stations"), plan.station, palette)
	local walkways = makeModel(publicRealm, "AcceptanceWalkRoute")
	for index = 2, #plan.route do
		buildWalkLink(walkways, plan.route[index - 1], plan.route[index], index - 1)
	end
	walkways:SetAttribute("AcceptanceLengthStuds", plan.stats.routeLength)
	walkways:SetAttribute(
		"AcceptanceSequence",
		"sidewalk > grid > public square > forecourt > concourse"
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CoreSidewalkSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(plan.route[1].x, 0.65, plan.route[1].z)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Material = Enum.Material.Concrete
	spawn.Color = Color3.fromRGB(176, 166, 145)
	spawn.Parent = publicRealm
	spawn:SetAttribute("AcceptanceStart", true)
	station:SetAttribute("AcceptanceDestination", "concourse")

	local actualPartCount = 0
	for _, descendant in ipairs(world:GetDescendants()) do
		if descendant:IsA("BasePart") then
			actualPartCount += 1
		end
	end
	world:SetAttribute("EstimatedGeneratedParts", plan.stats.estimatedParts)
	world:SetAttribute("GeneratedPartCount", actualPartCount)
	return world
end

return CityBuilder
