--!strict
-- Pure yawed-box geometry audit. Used in Lune against the actual runtime builder export.
-- Body/support margins are conservative: a valid union-supported edge may be rejected.
local OrientedAudit = {}
export type Point = { x: number, z: number }
export type Part = {
	id: string,
	name: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	rx: number,
	ry: number,
	rz: number,
	shape: string,
	collide: boolean,
	anchored: boolean,
	walk: boolean,
}
export type Bounds = { minX: number, maxX: number, minZ: number, maxZ: number }
export type Defect = { code: string, x: number, z: number, detail: string }
type Interval = { part: Part, low: number, high: number }

local function localPoint(part: Part, point: Point): (number, number)
	local angle = math.rad(part.ry)
	local dx, dz = point.x - part.x, point.z - part.z
	return dx * math.cos(angle) - dz * math.sin(angle), dx * math.sin(angle) + dz * math.cos(angle)
end

function OrientedAudit.clip(part: Part, a: Point, b: Point, margin: number): (number?, number?)
	local ax, az = localPoint(part, a)
	local bx, bz = localPoint(part, b)
	local low, high = 0, 1
	for _, axis in { { ax, bx - ax, part.sx / 2 + margin }, { az, bz - az, part.sz / 2 + margin } } do
		local origin, delta, half = axis[1], axis[2], axis[3]
		if half < 0 then
			return nil, nil
		end
		if math.abs(delta) < 1e-12 then
			if math.abs(origin) > half then
				return nil, nil
			end
		else
			local u, v = (-half - origin) / delta, (half - origin) / delta
			if u > v then
				u, v = v, u
			end
			low, high = math.max(low, u), math.min(high, v)
			if low > high then
				return nil, nil
			end
		end
	end
	return math.max(0, low), math.min(1, high)
end

-- Convex containment proves every coordinate, not just regularly spaced samples.
function OrientedAudit.sealed(parts: { Part }, bounds: Bounds): boolean
	for _, part in parts do
		if
			part.name ~= "CollidableGround"
			or not part.collide
			or not part.anchored
			or part.shape ~= "Block"
			or part.rx ~= 0
			or part.rz ~= 0
			or part.sy <= 0
		then
			continue
		end
		local covers = true
		for _, x in { bounds.minX, bounds.maxX } do
			for _, z in { bounds.minZ, bounds.maxZ } do
				local p = { x = x, z = z }
				if OrientedAudit.clip(part, p, p, 0) == nil then
					covers = false
				end
			end
		end
		if covers then
			return true
		end
	end
	return false
end

function OrientedAudit.route(parts: { Part }, route: { Point }, minimum: number)
	local defects: { Defect } = {}
	local length, maxStep, intervalCount = 0, 0, 0
	local previous: number? = nil
	local function add(code: string, x: number, z: number, detail: string)
		table.insert(defects, { code = code, x = x, z = z, detail = detail })
	end
	for _, part in parts do
		if not part.anchored then
			add("UNANCHORED", part.x, part.z, part.id)
		end
		if part.walk and not part.collide then
			add("NONCOLLIDABLE_SURFACE", part.x, part.z, part.id)
		end
		if part.rx ~= 0 or part.rz ~= 0 or (part.shape ~= "Block" and part.shape ~= "Cylinder") then
			add("UNSUPPORTED_GEOMETRY", part.x, part.z, part.id)
		end
		if part.sx <= 0 or part.sy <= 0 or part.sz <= 0 then
			add("DEGENERATE_GEOMETRY", part.x, part.z, part.id)
		end
	end
	for i = 1, #route - 1 do
		local a, b = route[i], route[i + 1]
		local dx, dz = b.x - a.x, b.z - a.z
		local distance = math.sqrt(dx * dx + dz * dz)
		length += distance
		local ts = { 0, 1 }
		local supports: { Interval } = {}
		local blockers: { Interval } = {}
		for _, part in parts do
			if part.collide then
				local low, high = OrientedAudit.clip(part, a, b, 1)
				if low ~= nil and high ~= nil then
					table.insert(blockers, { part = part, low = low, high = high })
					table.insert(ts, low)
					table.insert(ts, high)
				end
				if part.walk and part.shape == "Block" and part.rx == 0 and part.rz == 0 then
					local u, v = OrientedAudit.clip(part, a, b, -1)
					if u ~= nil and v ~= nil then
						table.insert(supports, { part = part, low = u, high = v })
						table.insert(ts, u)
						table.insert(ts, v)
					end
				end
			end
		end
		table.sort(ts)
		for j = 1, #ts - 1 do
			local low, high = ts[j], ts[j + 1]
			if high - low < 1e-10 then
				continue
			end
			intervalCount += 1
			local t = (low + high) / 2
			local x, z = a.x + t * dx, a.z + t * dz
			local top: number? = nil
			for _, support in supports do
				if t >= support.low - 1e-12 and t <= support.high + 1e-12 then
					local y = support.part.y + support.part.sy / 2
					if top == nil or y > top then
						top = y
					end
				end
			end
			if top == nil then
				add(
					"ROUTE_GAP",
					x,
					z,
					string.format(
						"unsupported radius-1 footprint interval %.6f studs",
						(high - low) * distance
					)
				)
				previous = nil
				continue
			end
			if previous ~= nil then
				local step = math.abs(top - previous)
				maxStep = math.max(maxStep, step)
				if step > 1.2 + 1e-5 then
					add("STEP", a.x + low * dx, a.z + low * dz, string.format("%.6f studs", step))
				end
			end
			previous = top
			for _, blocker in blockers do
				local p = blocker.part
				if
					t > blocker.low + 1e-10
					and t < blocker.high - 1e-10
					and p.y - p.sy / 2 < top + 5 - 1e-5
					and p.y + p.sy / 2 > top + 1.2 + 1e-5
				then
					add("BODY_BLOCKED", x, z, p.id)
				end
			end
		end
	end
	if length < minimum then
		add("ROUTE_TOO_SHORT", 0, 0, string.format("%.6f < %.6f", length, minimum))
	end
	return { defects = defects, length = length, maxStep = maxStep, intervals = intervalCount }
end
return OrientedAudit
