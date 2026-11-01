--!strict
-- Exact rectangular cell decomposition, not a coarse ground sampling claim.
-- Supported boundary: anchored axis-aligned boxes only; adapters must reject other shapes.
local Audit = {}
export type Box = {
	id: string,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	bottom: number,
	top: number,
	collide: boolean,
	walk: boolean,
}
export type Point = { x: number, z: number }
export type Defect = { code: string, x: number, z: number, detail: string }

local function inside(b: Box, x: number, z: number): boolean
	return x >= b.x0 and x <= b.x1 and z >= b.z0 and z <= b.z1
end

function Audit.surface(boxes: { Box }, x: number, z: number): number?
	local height: number? = nil
	for _, b in boxes do
		if b.walk and b.collide and inside(b, x, z) then
			if height == nil or b.top > height then
				height = b.top
			end
		end
	end
	return height
end

-- Every open cell has constant rectangle membership. Checking one interior point
-- proves coverage throughout that cell, including holes narrower than 0.5 studs.
function Audit.seal(
	boxes: { Box },
	bounds: { x0: number, x1: number, z0: number, z1: number }
): { Defect }
	local xs, zs = { bounds.x0, bounds.x1 }, { bounds.z0, bounds.z1 }
	for _, b in boxes do
		for _, x in { b.x0, b.x1 } do
			if x > bounds.x0 and x < bounds.x1 then
				table.insert(xs, x)
			end
		end
		for _, z in { b.z0, b.z1 } do
			if z > bounds.z0 and z < bounds.z1 then
				table.insert(zs, z)
			end
		end
	end
	table.sort(xs)
	table.sort(zs)
	local defects: { Defect } = {}
	for i = 1, #xs - 1 do
		for j = 1, #zs - 1 do
			if xs[i + 1] > xs[i] and zs[j + 1] > zs[j] then
				local x, z = (xs[i] + xs[i + 1]) / 2, (zs[j] + zs[j + 1]) / 2
				if Audit.surface(boxes, x, z) == nil then
					table.insert(defects, {
						code = "GROUND_HOLE",
						x = x,
						z = z,
						detail = string.format(
							"uncovered rectangle x=[%g,%g] z=[%g,%g]",
							xs[i],
							xs[i + 1],
							zs[j],
							zs[j + 1]
						),
					})
				end
			end
		end
	end
	return defects
end

-- Split at every surface boundary AND expanded obstacle boundary. No thin wall
-- can hide between sample positions. Body envelope is 2 studs wide, 5 high.
function Audit.route(boxes: { Box }, points: { Point }, minimum: number): ({ Defect }, number)
	local defects: { Defect } = {}
	local length = 0
	local previous: number? = nil
	local function add(code: string, x: number, z: number, detail: string)
		table.insert(defects, { code = code, x = x, z = z, detail = detail })
	end
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local dx, dz = b.x - a.x, b.z - a.z
		local distance = math.sqrt(dx * dx + dz * dz)
		length += distance
		local ts = { 0, 1 }
		for _, box in boxes do
			local margin = if box.walk then 0 else 1
			for _, x in { box.x0 - margin, box.x1 + margin } do
				if dx ~= 0 then
					local t = (x - a.x) / dx
					if t > 0 and t < 1 then
						table.insert(ts, t)
					end
				end
			end
			for _, z in { box.z0 - margin, box.z1 + margin } do
				if dz ~= 0 then
					local t = (z - a.z) / dz
					if t > 0 and t < 1 then
						table.insert(ts, t)
					end
				end
			end
		end
		table.sort(ts)
		for j = 1, #ts - 1 do
			if ts[j + 1] == ts[j] then
				continue
			end
			local t = (ts[j] + ts[j + 1]) / 2
			local x, z = a.x + dx * t, a.z + dz * t
			local y = Audit.surface(boxes, x, z)
			if y == nil then
				add(
					"ROUTE_GAP",
					x,
					z,
					string.format(
						"unsupported interval %g studs (strict: any hole fails)",
						(ts[j + 1] - ts[j]) * distance
					)
				)
			else
				if previous ~= nil and math.abs(y - previous) > 1.2 then
					add(
						"STEP",
						x,
						z,
						string.format("height change %g studs", math.abs(y - previous))
					)
				end
				for _, box in boxes do
					if
						box.collide
						and box.top > y + 0.01
						and box.bottom < y + 5
						and x > box.x0 - 1
						and x < box.x1 + 1
						and z > box.z0 - 1
						and z < box.z1 + 1
					then
						add("BODY_BLOCKED", x, z, box.id)
					end
				end
				previous = y
			end
		end
	end
	if length < minimum then
		add("ROUTE_TOO_SHORT", 0, 0, string.format("%g < %g studs", length, minimum))
	end
	return defects, length
end
return Audit
