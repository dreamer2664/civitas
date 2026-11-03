--!strict
-- Pure street-acceptance geometry. No synthetic paving or engine claims.
local Audit = require("./OrientedAudit")
local StreetChecks = {}
export type Intersection = { x: number, z: number, widthX: number, widthZ: number, radius: number }
export type Crossing = { axis: string, side: number, route: { Audit.Point } }

function StreetChecks.crossings(intersection: Intersection, sidewalkWidth: number): { Crossing }
	assert(sidewalkWidth >= 2 and sidewalkWidth < math.huge, "invalid sidewalk width")
	assert(intersection.widthX > 0 and intersection.widthZ > 0, "invalid crossing widths")
	local checks: { Crossing } = {}
	for _, axis in { "x", "z" } do
		local half = (if axis == "x" then intersection.widthX else intersection.widthZ) / 2
			+ sidewalkWidth / 2
		local offset = (if axis == "x" then intersection.widthZ else intersection.widthX) / 2
			+ sidewalkWidth / 2
		for side = -1, 1, 2 do
			local x = intersection.x + (if axis == "z" then side * offset else 0)
			local z = intersection.z + (if axis == "x" then side * offset else 0)
			table.insert(checks, {
				axis = axis,
				side = side,
				route = {
					{
						x = x - (if axis == "x" then half else 0),
						z = z - (if axis == "z" then half else 0),
					},
					{
						x = x + (if axis == "x" then half else 0),
						z = z + (if axis == "z" then half else 0),
					},
				},
			})
		end
	end
	return checks
end

return StreetChecks
