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

-- The 3.5-stud District A floor is independent of the mutable declared width.
-- Three radius-1 swept lanes cover both edges plus the centre of each real slab.
function StreetChecks.sidewalk(part: Audit.Part, parts: { Audit.Part }, minimumWidth: number)
	local alongX = string.find(part.name, "^Sidewalk_x_") ~= nil
	local width = if alongX then part.sz else part.sx
	local length = if alongX then part.sx else part.sz
	local yaw = math.rad(part.ry)
	local dx = if alongX then math.cos(yaw) else math.sin(yaw)
	local dz = if alongX then -math.sin(yaw) else math.cos(yaw)
	local lanes = {}
	local passed = width + 1e-4 >= minimumWidth and width >= 2 and length > 2
	if width >= 2 and length > 2 then
		for side = -1, 1 do
			local offset = side * (width / 2 - 1)
			local x, z = part.x - dz * offset, part.z + dx * offset
			local half = length / 2 - 1
			local route = {
				{ x = x - dx * half, z = z - dz * half },
				{ x = x + dx * half, z = z + dz * half },
			}
			local result = Audit.route(parts, route, 0)
			if #result.defects > 0 then
				passed = false
			end
			table.insert(lanes, { side = side, route = route, result = result })
		end
	end
	return {
		source = part.id,
		nominalWidth = width,
		requiredWidth = minimumWidth,
		passed = passed,
		lanes = lanes,
	}
end

return StreetChecks
