--!strict
-- Pure placement validation shared by headless audit and future runtime integration.
-- Does NOT create a SpawnLocation or claim a character has streamed in.
local Audit = require("../Walkability/Audit")
local Plan = {}
function Plan.validate(boxes: { Audit.Box }, point: Audit.Point): (boolean, number?)
	local y = Audit.surface(boxes, point.x, point.z)
	if y == nil then
		return false, nil
	end
	for _, dx in { -1, 0, 1 } do
		for _, dz in { -1, 0, 1 } do
			local h = Audit.surface(boxes, point.x + dx, point.z + dz)
			if h == nil or math.abs(h - y) > 0.01 then
				return false, y
			end
		end
	end
	local defects = Audit.route(boxes, { point, { x = point.x + 0.001, z = point.z } }, 0)
	return #defects == 0, y
end
return Plan
