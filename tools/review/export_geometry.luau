--!nocheck
-- Executes the production geometry builders in Lune's Roblox data model, NOT a game engine.
-- Exports authored sizes, positions, orientations, colours and collision flags for Blender review.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local config = require("../../src/server/World/CityConfig")
local generator = require("../../src/server/World/CityGenerator")
local facadeMath = require("../../src/server/World/FacadeMath")
local function loadBuilder(path: string, facade: boolean)
	return luau.load(fs.readFile(path), {
		debugName = path,
		environment = {
			Instance = roblox.Instance,
			Vector3 = roblox.Vector3,
			Color3 = roblox.Color3,
			CFrame = roblox.CFrame,
			UDim2 = roblox.UDim2,
			Enum = roblox.Enum,
			script = { Parent = { FacadeMath = "FacadeMath" } },
			require = function(name)
				assert(facade and name == "FacadeMath", "unexpected dependency")
				return facadeMath
			end,
		},
	})()
end
local world = roblox.Instance.new("Folder")
world.Name = "ReviewRoot"
local city = loadBuilder("src/server/World/CityBuilder.luau", true).build(
	generator.generate(config),
	config,
	world
)
local railway =
	loadBuilder("src/server/RailDemo/RailGeometry.luau", false).build(config.station, world)
local parts = {}
local function xyz(v)
	return { v.X, v.Y, v.Z }
end
for _, p in world:GetDescendants() do
	if p:IsA("BasePart") then
		-- Production code authors Position/Orientation, except door transforms at runtime.
		-- Lune models data properties; no physics, constraints or scripting is simulated here.
		local path = p:GetFullName()
		local hasOrientation, orientation = pcall(function()
			return p.Orientation
		end)
		if not hasOrientation then
			orientation = roblox.Vector3.zero
		end
		if p.Transparency < 1 then
			table.insert(parts, {
				name = p.Name,
				path = path,
				size = xyz(p.Size),
				position = xyz(p.Position),
				orientation = xyz(orientation),
				color = { p.Color.R, p.Color.G, p.Color.B },
				material = p.Material.Name,
				collide = p.CanCollide,
				shape = if p:IsA("Part") then p.Shape.Name else "Block",
				sign = p:GetAttribute("SignText"),
			})
		end
	end
end
local function countParts(root)
	local count = 0
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			count += 1
		end
	end
	return count
end
local cityParts = countParts(city)
local railParts = countParts(railway.model)
assert(cityParts == city:GetAttribute("GeneratedPartCount"), "city runtime count differs")
assert(railParts == railway.model:GetAttribute("GeneratedPartCount"), "rail runtime count differs")
assert(railway.model:FindFirstChild("WestGardensHalt"), "second halt missing")
local manifest = {
	formatVersion = 1,
	provenance = "Executed CityBuilder and RailGeometry in Lune; not a Roblox runtime capture",
	cityParts = cityParts,
	railParts = railParts,
	visibleParts = #parts,
	parts = parts,
}
fs.writeDir("build/review")
fs.writeFile("build/review/geometry.json", serde.encode("json", manifest))
fs.writeDir("evidence/norman")
fs.writeFile(
	"evidence/norman/geometry-summary.json",
	serde.encode("json", {
		cityParts = cityParts,
		railParts = railParts,
		visibleParts = #parts,
		provenance = manifest.provenance,
	}, true)
)
print(
	string.format(
		"Exact builder export: %d city + %d railway parts; %d visible",
		cityParts,
		railParts,
		#parts
	)
)
