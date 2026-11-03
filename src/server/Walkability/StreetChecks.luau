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

-- Check actual curb solids against promised return openings. An attribute alone
-- does not prove an opening, and a low curb can pass the ordinary step-height gate.
function StreetChecks.curbReturn(
	part: Audit.Part,
	intersections: { Intersection },
	sidewalkWidth: number
)
	local axis, rawCenter = string.match(part.name, "^CurbReturn_([xz])_([%-%d%.]+)_")
	local center = tonumber(rawCenter)
	assert(axis ~= nil and center ~= nil, "unrecognized curb-return identity")
	local alongX = axis == "x"
	local coordinate = if alongX then part.x else part.z
	local length = if alongX then part.sx else part.sz
	local transverse = if alongX then part.sz else part.sx
	local actualOffset = math.abs((if alongX then part.z else part.x) - center)
	local low, high = coordinate - length / 2, coordinate + length / 2
	local passed = part.collide
		and part.anchored
		and part.shape == "Block"
		and part.rx == 0
		and part.ry == 0
		and part.rz == 0
	local windows = 0
	local overlaps = {}
	for _, intersection in intersections do
		if (if alongX then intersection.z else intersection.x) ~= center then
			continue
		end
		windows += 1
		local roadWidth = if alongX then intersection.widthZ else intersection.widthX
		local expectedOffset = roadWidth / 2 + sidewalkWidth + transverse / 2
		if math.abs(actualOffset - expectedOffset) > 1e-3 then
			passed = false
		end
		assert(intersection.radius >= sidewalkWidth + 1, "return radius leaves no body-width apron")
		local crossingWidth = if alongX then intersection.widthX else intersection.widthZ
		local crossingCenter = if alongX then intersection.x else intersection.z
		local halfGap = crossingWidth / 2 + intersection.radius
		local gapLow, gapHigh = crossingCenter - halfGap, crossingCenter + halfGap
		local overlap = math.min(high, gapHigh) - math.max(low, gapLow)
		-- Roblox export coordinates are float32; tolerate sub-millistud quantization only.
		if overlap > 1e-4 then
			passed = false
			table.insert(overlaps, {
				x = intersection.x,
				z = intersection.z,
				gapStart = gapLow,
				gapFinish = gapHigh,
				intrusionStuds = overlap,
			})
		end
	end
	return {
		source = part.id,
		passed = passed and windows > 0,
		checkedOpeningCount = windows,
		overlaps = overlaps,
	}
end

return StreetChecks
