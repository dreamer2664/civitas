--!strict
-- Server bootstraps one deterministic world build; no Studio placement or ticking is required.
local Workspace = game:GetService("Workspace")
local config = require(script.Parent.CityConfig)
local generator = require(script.Parent.CityGenerator)
local builder = require(script.Parent.CityBuilder)

-- Workspace streaming properties are NotScriptable in Roblox's current API. They are
-- authored in default.project.json; the district model carries explicit stream-in bounds.

local plan = generator.generate(config)
local world = builder.build(plan, config, Workspace)
world:SetAttribute("StreamingBoundaryPadding", config.streaming.districtEdgePadding)
world:SetAttribute("WalkRouteStuds", plan.stats.routeLength)
world:SetAttribute("GeneratedPartEstimate", plan.stats.estimatedParts)
local generatedPartCount = world:GetAttribute("GeneratedPartCount")
if typeof(generatedPartCount) ~= "number" then
	error("CityBuilder did not report a numeric generated-part count")
end
print(
	string.format(
		"Civitas World: %d buildings, %d landmarks, %.0f-stud acceptance route, %d parts",
		plan.stats.buildingCount,
		plan.stats.landmarkCount,
		plan.stats.routeLength,
		generatedPartCount
	)
)
