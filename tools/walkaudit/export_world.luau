--!strict
-- Execute the unmodified runtime builder with Lune's Roblox data model, NOT the engine.
-- Globals are supplied as datatypes only; there is no physics/streaming simulation.
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local config = require("../../src/server/World/CityConfig")
local generator = require("../../src/server/World/CityGenerator")
local builderSource = fs.readFile("src/server/World/CityBuilder.luau")
assert(
	not string.find(builderSource, "%.CFrame%s*=")
		and not string.find(builderSource, ":PivotTo%s*%("),
	"Builder placement changed to CFrame/PivotTo; update the audit adapter rather than reading stale Position"
)
local builder = luau.load(builderSource, {
	environment = {
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Color3 = roblox.Color3,
		Enum = roblox.Enum,
	},
})()
local plan = generator.generate(config)
local world = builder.build(plan, config, roblox.Instance.new("Workspace"))
local parts = {}
for _, part in world:GetDescendants() do
	if part:IsA("BasePart") then
		assert(
			part.ClassName == "Part" or part.ClassName == "SpawnLocation",
			"Unsupported generated BasePart class: " .. part.ClassName
		)
		-- Lune stores properties but does not synchronize Position/Orientation/CFrame.
		-- This source revision sets Position and optional Orientation explicitly, never CFrame.
		local _, orientation = pcall(function()
			return part.Orientation
		end)
		if typeof(orientation) ~= "Vector3" then
			orientation = roblox.Vector3.zero
		end
		local pos, size = part.Position, part.Size
		local _, shape = pcall(function()
			return part.Shape.Name
		end)
		if type(shape) ~= "string" then
			shape = "Block"
		end
		table.insert(parts, {
			id = part:GetFullName(),
			name = part.Name,
			x = pos.X,
			y = pos.Y,
			z = pos.Z,
			sx = size.X,
			sy = size.Y,
			sz = size.Z,
			rx = orientation.X,
			ry = orientation.Y,
			rz = orientation.Z,
			shape = shape,
			collide = part.CanCollide,
			anchored = part.Anchored,
			material = part.Material.Name,
			walk = part:GetAttribute("Walkable") == true
				or part.Name == "CollidableGround"
				or part.Name == "ConcourseFloor"
				or part.Name == "CoreSidewalkSpawn"
				or string.find(part.Name, "Carriageway") ~= nil,
		})
	end
end
fs.writeFile(
	"docs/reports/walkability-world.json",
	serde.encode("json", {
		parts = parts,
		route = plan.route,
		intersections = plan.intersections,
		sidewalkWidth = config.streets.sidewalkWidth,
		bounds = plan.districtBounds[1],
		stats = plan.stats,
		station = plan.station,
		configStreaming = config.streaming,
	}, true)
)
print(
	string.format(
		"Executed real CityBuilder in Lune: %d BaseParts; %.2f-stud route",
		#parts,
		plan.stats.routeLength
	)
)
