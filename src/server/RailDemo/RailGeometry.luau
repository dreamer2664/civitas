--!strict
-- Shared geometry recipe used by the server and the offline Lune/Blender review pipeline.
-- Offline rendering executes this recipe; it does not imply Roblox runtime verification.
local RailGeometry = {}

function RailGeometry.build(station: any, rootParent: Instance)
	local MIN_X = station.railMinX
	local MAX_X = station.railMaxX
	local function part(
		parent: Instance,
		name: string,
		size: Vector3,
		position: Vector3,
		color: Color3,
		material: Enum.Material
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = position
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanTouch = false
		p.Parent = parent
		return p
	end

	local function visual(
		parent: Instance,
		name: string,
		size: Vector3,
		position: Vector3,
		color: Color3,
		material: Enum.Material
	): Part
		local p = part(parent, name, size, position, color, material)
		p.CanCollide = false
		p.CanQuery = false
		return p
	end

	local model = Instance.new("Model")
	model.Name = "ExperimentalRailway"
	model:SetAttribute("Status", "Single-track prototype; not the final Civitas network")
	model.Parent = rootParent
	local track = Instance.new("Model")
	track.Name = "TestTrack"
	track.Parent = model
	local centerX = (MIN_X + MAX_X) / 2
	visual(
		track,
		"Ballast",
		Vector3.new(MAX_X - MIN_X, 0.18, 12),
		Vector3.new(centerX, 0.09, station.railCenterZ),
		Color3.fromRGB(92, 86, 76),
		Enum.Material.Slate
	)
	for _, offset in ipairs({ -2.56285, 2.56285 }) do
		visual(
			track,
			"Rail",
			Vector3.new(MAX_X - MIN_X, 0.25, 0.25),
			Vector3.new(centerX, station.railTopY - 0.125, station.railCenterZ + offset),
			Color3.fromRGB(142, 146, 145),
			Enum.Material.Metal
		)
	end
	local sleeperSpacing = 2.1429
	for index = 0, math.floor((MAX_X - MIN_X) / sleeperSpacing) do
		visual(
			track,
			"Sleeper",
			Vector3.new(0.8, 0.22, 9),
			Vector3.new(MIN_X + index * sleeperSpacing, 0.21, station.railCenterZ),
			Color3.fromRGB(82, 68, 54),
			Enum.Material.WoodPlanks
		)
	end

	-- West Gardens is a second provisional halt, not part of the final city network.
	local halt = Instance.new("Model")
	halt.Name = "WestGardensHalt"
	halt.Parent = model
	local westX = station.westStopX
	local function slab(name: string, size: Vector3, pos: Vector3, color: Color3): Part
		return part(halt, name, size, pos, color, Enum.Material.Concrete)
	end
	slab(
		"WestPlatform",
		Vector3.new(200, 0.8, 21),
		Vector3.new(westX, station.platformTopY - 0.4, station.platformCenterZ),
		Color3.fromRGB(184, 179, 165)
	)
	visual(
		halt,
		"WestTactile",
		Vector3.new(200, 0.08, 2.14),
		Vector3.new(westX, station.platformTopY + 0.04, station.platformCenterZ + 9.4),
		Color3.fromRGB(211, 189, 130),
		Enum.Material.Concrete
	)
	-- A forecourt walk and west approach avoid the Central shell and running rail.
	slab(
		"GardenPromenade",
		Vector3.new(math.abs(station.centerX - westX) + 20, 0.5, 12),
		Vector3.new((westX + station.centerX) / 2, 0.38, station.forecourtZ),
		Color3.fromRGB(186, 177, 158)
	)
	local rise = station.platformTopY - 0.63
	local run = 34.5
	slab(
		"GardenAccessWalk",
		Vector3.new(12, 0.5, 1000 - run - station.forecourtZ + 0.2),
		Vector3.new(westX, 0.38, (station.forecourtZ + 1000 - run) / 2),
		Color3.fromRGB(186, 177, 158)
	)
	local angle = math.atan2(rise, run)
	local ramp = slab(
		"WestAccessRamp",
		Vector3.new(20, 0.4, math.sqrt(run * run + rise * rise) + 0.4),
		Vector3.new(
			westX,
			(station.platformTopY + 0.63) / 2 - 0.2 * math.cos(angle),
			1000 - run / 2
		),
		Color3.fromRGB(184, 179, 165)
	)
	ramp.Orientation = Vector3.new(-math.deg(angle), 0, 0)
	ramp:SetAttribute("Walkable", true)
	for _, stop in ipairs({
		{ x = westX, name = "WEST GARDENS" },
		{ x = station.centerX, name = "CIVITAS CENTRAL" },
	}) do
		local board = visual(
			halt,
			"StationName_" .. stop.name,
			Vector3.new(34, 4, 0.45),
			Vector3.new(stop.x, station.platformTopY + 8.5, station.platformCenterZ - 7),
			Color3.fromRGB(28, 51, 55),
			Enum.Material.Metal
		)
		board:SetAttribute("SignText", stop.name)
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.PixelsPerStud = 32
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.Parent = board
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.TextColor3 = Color3.fromRGB(239, 232, 210)
			text.Font = Enum.Font.BuilderSansBold
			text.TextScaled = true
			text.Text = stop.name
			text.Parent = gui
		end
	end
	for _, offset in ipairs({ -78, -38, 38, 78 }) do
		visual(
			halt,
			"WestCanopyPost",
			Vector3.new(1.2, 12, 1.2),
			Vector3.new(westX + offset, station.platformTopY + 6, station.platformCenterZ - 6),
			Color3.fromRGB(68, 83, 86),
			Enum.Material.Metal
		)
	end
	visual(
		halt,
		"WestCanopy",
		Vector3.new(196, 0.8, 16),
		Vector3.new(westX, station.platformTopY + 12.4, station.platformCenterZ),
		Color3.fromRGB(76, 92, 96),
		Enum.Material.Metal
	)
	for _, offset in ipairs({ -55, 55 }) do
		visual(
			halt,
			"WestBench",
			Vector3.new(9, 0.6, 2.2),
			Vector3.new(westX + offset, station.platformTopY + 1.8, station.platformCenterZ - 3),
			Color3.fromRGB(130, 97, 65),
			Enum.Material.WoodPlanks
		)
	end

	local train = Instance.new("Model")
	train.Name = "ExperimentalShuttle"
	train:SetAttribute("Status", "Prototype geometry; not the imported EMU-1")
	train.Parent = model
	local anchor = visual(
		train,
		"Pivot",
		Vector3.new(1, 1, 1),
		Vector3.new(station.centerX, 0, station.railCenterZ),
		Color3.new(),
		Enum.Material.SmoothPlastic
	)
	anchor.Transparency = 1
	train.PrimaryPart = anchor
	local bodyWidth = 10.1786
	local bodyBottom = station.railTopY + 3
	local bodyHeight = 11.1429
	local totalLength = 75 + 1.7857 + 71.4286
	local carCenters = {
		station.centerX - totalLength / 2 + 37.5,
		station.centerX - totalLength / 2 + 75 + 1.7857 + 71.4286 / 2,
	}
	local carLengths = { 75, 71.4286 }
	local doorLeaves: { { part: Part, closed: CFrame, slide: number } } = {}
	for index, carX in ipairs(carCenters) do
		local length = carLengths[index]
		local car = Instance.new("Model")
		car.Name = if index == 1 then "CabCar" else "IntermediateCar"
		car.Parent = train
		visual(
			car,
			"Floor",
			Vector3.new(length, 0.5, bodyWidth),
			Vector3.new(carX, bodyBottom, station.railCenterZ),
			Color3.fromRGB(81, 87, 84),
			Enum.Material.Metal
		)
		visual(
			car,
			"Roof",
			Vector3.new(length, 0.65, bodyWidth + 0.2),
			Vector3.new(carX, bodyBottom + bodyHeight + 0.325, station.railCenterZ),
			Color3.fromRGB(95, 106, 107),
			Enum.Material.Metal
		)
		for _, endSign in ipairs({ -1, 1 }) do
			visual(
				car,
				"EndWall",
				Vector3.new(0.45, bodyHeight, bodyWidth),
				Vector3.new(
					carX + endSign * length / 2,
					bodyBottom + bodyHeight / 2,
					station.railCenterZ
				),
				Color3.fromRGB(211, 216, 210),
				Enum.Material.Metal
			)
			visual(
				car,
				"EndGlazing",
				Vector3.new(0.5, 3.4, bodyWidth * 0.72),
				Vector3.new(
					carX + endSign * (length / 2 + 0.1),
					bodyBottom + 7.1,
					station.railCenterZ
				),
				Color3.fromRGB(29, 67, 75),
				Enum.Material.Glass
			)
		end
		for _, side in ipairs({ -1, 1 }) do
			local faceZ = station.railCenterZ + side * (bodyWidth / 2 + 0.1)
			local doorWidth = 4.6429
			local spans = {
				{ -length / 2, -length * 0.25 - doorWidth / 2 },
				{ -length * 0.25 + doorWidth / 2, length * 0.25 - doorWidth / 2 },
				{ length * 0.25 + doorWidth / 2, length / 2 },
			}
			for _, span in ipairs(spans) do
				local width = span[2] - span[1]
				local center = carX + (span[1] + span[2]) / 2
				visual(
					car,
					"SidePanel",
					Vector3.new(width, 4.5, 0.35),
					Vector3.new(center, bodyBottom + 2.25, faceZ),
					Color3.fromRGB(211, 216, 210),
					Enum.Material.Metal
				)
				visual(
					car,
					"Window",
					Vector3.new(width - 1, 3.6, 0.25),
					Vector3.new(center, bodyBottom + 6.4, faceZ),
					Color3.fromRGB(29, 67, 75),
					Enum.Material.Glass
				)
				visual(
					car,
					"UpperPanel",
					Vector3.new(width, 2.95, 0.35),
					Vector3.new(center, bodyBottom + 9.675, faceZ),
					Color3.fromRGB(211, 216, 210),
					Enum.Material.Metal
				)
				visual(
					car,
					"LiveryStripe",
					Vector3.new(width, 0.65, 0.38),
					Vector3.new(center, bodyBottom + 3.5, faceZ),
					Color3.fromRGB(155, 57, 48),
					Enum.Material.Metal
				)
			end
			for _, doorX in ipairs({ -length * 0.25, length * 0.25 }) do
				visual(
					car,
					"DoorHeader",
					Vector3.new(doorWidth, bodyHeight - 7.1, 0.35),
					Vector3.new(carX + doorX, bodyBottom + (bodyHeight + 7.1) / 2, faceZ),
					Color3.fromRGB(211, 216, 210),
					Enum.Material.Metal
				)
				for _, leaf in ipairs({ -1, 1 }) do
					local door = visual(
						car,
						"SlidingDoor",
						Vector3.new(doorWidth / 2 - 0.08, 7.1, 0.4),
						Vector3.new(
							carX + doorX + leaf * doorWidth / 4,
							bodyBottom + 3.55,
							faceZ + side * 0.2
						),
						Color3.fromRGB(155, 57, 48),
						Enum.Material.Metal
					)
					table.insert(doorLeaves, {
						part = door,
						closed = CFrame.new(door.Position - anchor.Position),
						slide = leaf * (doorWidth / 2 + 0.1),
					})
				end
			end
		end
		for _, offset in ipairs({ -length / 2 + 10.7143, length / 2 - 10.7143 }) do
			visual(
				car,
				"Bogie",
				Vector3.new(9, 2.5, 8),
				Vector3.new(carX + offset, station.railTopY + 1.5, station.railCenterZ),
				Color3.fromRGB(43, 48, 48),
				Enum.Material.Metal
			)
			for _, axle in ipairs({ -2.5, 2.5 }) do
				for _, side in ipairs({ -1, 1 }) do
					local wheel = visual(
						car,
						"Wheel",
						Vector3.new(0.6, 2.6, 2.6),
						Vector3.new(
							carX + offset + axle,
							station.railTopY + 1.3,
							station.railCenterZ + side * 3.6
						),
						Color3.fromRGB(39, 43, 43),
						Enum.Material.Metal
					)
					wheel.Shape = Enum.PartType.Cylinder
					wheel.Orientation = Vector3.new(0, 90, 0)
				end
			end
		end
	end
	local seat = Instance.new("Seat")
	seat.Name = "CivitasShuttleDriverSeat"
	seat.Size = Vector3.new(3, 1, 3)
	seat.Position = Vector3.new(station.centerX + 55, bodyBottom + 4, station.railCenterZ)
	seat.Anchored = true
	seat.CanCollide = false
	seat.Transparency = 1
	seat.Parent = train
	local passengerSeats: { Seat } = {}
	for index, carX in ipairs(carCenters) do
		for _, offset in ipairs({ -20, 0, 20 }) do
			local passengerSeat = Instance.new("Seat")
			passengerSeat.Name = "PassengerSeat_" .. tostring(index) .. "_" .. tostring(offset)
			passengerSeat.Size = Vector3.new(3, 1, 3)
			passengerSeat.Position = Vector3.new(carX + offset, bodyBottom + 3, station.railCenterZ)
			passengerSeat.Anchored = true
			passengerSeat.CanCollide = false
			passengerSeat.Transparency = 1
			passengerSeat.Parent = train
			visual(
				train,
				"PassengerCushion",
				Vector3.new(3.2, 0.6, 2.5),
				passengerSeat.Position - Vector3.new(0, 0.5, 0),
				Color3.fromRGB(55, 94, 95),
				Enum.Material.Fabric
			)
			visual(
				train,
				"PassengerBack",
				Vector3.new(0.5, 3.2, 2.5),
				passengerSeat.Position + Vector3.new(-1.4, 1, 0),
				Color3.fromRGB(55, 94, 95),
				Enum.Material.Fabric
			)
			table.insert(passengerSeats, passengerSeat)
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Board test shuttle"
	prompt.ObjectText = "Experimental driver seat"
	prompt.MaxActivationDistance = 24
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	local passengerPrompt = Instance.new("ProximityPrompt")
	passengerPrompt.Name = "PassengerBoarding"
	passengerPrompt.ActionText = "Board as passenger"
	passengerPrompt.ObjectText = "Experimental shuttle"
	passengerPrompt.MaxActivationDistance = 24
	passengerPrompt.RequiresLineOfSight = false
	passengerPrompt.Enabled = false
	passengerPrompt.Parent = anchor
	local generatedPartCount = 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			generatedPartCount += 1
		end
	end
	model:SetAttribute("GeneratedPartCount", generatedPartCount)
	print(
		string.format(
			"Civitas ExperimentalRailway: %d parts (separate from city count)",
			generatedPartCount
		)
	)

	return {
		model = model,
		train = train,
		anchor = anchor,
		seat = seat,
		passengerSeats = passengerSeats,
		prompt = prompt,
		passengerPrompt = passengerPrompt,
		doorLeaves = doorLeaves,
	}
end
return RailGeometry
