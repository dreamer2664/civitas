--!strict
-- Roblox Y-axis yaw transforms a local building offset into world X/Z.
local FacadeMath = {}

function FacadeMath.worldPoint(
	x: number,
	z: number,
	rotation: number,
	localX: number,
	localZ: number
): (number, number)
	local angle = math.rad(rotation)
	local c, s = math.cos(angle), math.sin(angle)
	return x + localX * c + localZ * s, z - localX * s + localZ * c
end

return FacadeMath
