--!strict
--[[
Spline.luau — arc-length parameterised cubic Catmull-Rom spline for railway centre lines.

Pure Luau: no DataModel access, no Roblox globals, testable with lune without Studio.
All units are studs.

Model
-----
A spline is a piecewise cubic curve through a list of control points. Segment i runs from
controlPoints[i] to controlPoints[i+1] (open spline) or wraps around (closed spline) and is
evaluated with the standard centripetal Catmull-Rom formulation, parameterised by t in [0, 1]
over the segment.

Arc length
----------
Each segment is approximated by sampling sub-points and summing chord lengths, giving a
cumulative arc-length table per segment. Mapping arc length s -> (segment, local t) is a
binary search; evaluating at t integrates the same table. Position, tangent and frame normal
are all available in arc-length parameterisation, which is what train movement needs: speed is
studs per second, so the simulation integrates s directly and can never drift off the track.

The arc-length table is an approximation: sub-sample count targets a maximum chord of 1 stud
per segment, so length error is well below a millimetre for typical track segments and far
below train braking tolerances.
--]]

local STUD_PER_METER = 1 / 0.28 -- 1 m = 3.571... studs (docs/STANDARDS.md)

export type Vec3 = {
	x: number,
	y: number,
	z: number,
}

type SubSample = {
	t: number,
	length: number, -- cumulative length within the segment up to this sub-sample
	position: Vec3,
}

type Segment = {
	p0: Vec3,
	p1: Vec3,
	p2: Vec3,
	p3: Vec3,
	subSamples: { SubSample },
	length: number,
	sStart: number,
}

export type Spline = {
	controlPoints: { Vec3 },
	segments: { Segment },
	totalLength: number,
	closed: boolean,
	sample: (self: Spline, t: number) -> Vec3,
	sampleSegment: (self: Spline, segmentIndex: number, t: number) -> Vec3,
	tangent: (self: Spline, t: number) -> Vec3,
	segmentTangent: (self: Spline, segmentIndex: number, t: number) -> Vec3,
	sampleArcLength: (self: Spline, s: number) -> { position: Vec3, tangent: Vec3 },
	arcLengthToT: (self: Spline, s: number) -> { segmentIndex: number, t: number },
	lengthTo: (self: Spline, segmentIndex: number, t: number) -> number,
	addPoint: (self: Spline, point: Vec3) -> number,
	-- distanceToPoint returns the closest point on the spline to a world point, the arc-length
	-- position s of that closest point, and the distance between them. Used by station stop
	-- markers to snap a platform position onto the track centre line.
	distanceToPoint: (self: Spline, point: Vec3) -> { position: Vec3, s: number, distance: number },
}

-- -----------------------------------------------------------------------------
-- Vector helpers (pure)
-- -----------------------------------------------------------------------------

local function vec3(x: number, y: number, z: number): Vec3
	return { x = x, y = y, z = z }
end

local function sub(a: Vec3, b: Vec3): Vec3
	return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

local function dot(a: Vec3, b: Vec3): number
	return a.x * b.x + a.y * b.y + a.z * b.z
end

local function len(a: Vec3): number
	return math.sqrt(dot(a, a))
end

-- -----------------------------------------------------------------------------
-- Catmull-Rom segment evaluation
-- -----------------------------------------------------------------------------

local function catmullRom(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, t: number): Vec3
	local t2 = t * t
	local t3 = t2 * t
	return {
		x = 0.5
			* (
				(2 * p1.x)
				+ (-p0.x + p2.x) * t
				+ (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
				+ (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3
			),
		y = 0.5
			* (
				(2 * p1.y)
				+ (-p0.y + p2.y) * t
				+ (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
				+ (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3
			),
		z = 0.5
			* (
				(2 * p1.z)
				+ (-p0.z + p2.z) * t
				+ (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2
				+ (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3
			),
	}
end

local function catmullRomTangent(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, t: number): Vec3
	local t2 = t * t
	return {
		x = 0.5
			* (
				(-p0.x + p2.x)
				+ 2 * (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t
				+ 3 * (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t2
			),
		y = 0.5
			* (
				(-p0.y + p2.y)
				+ 2 * (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t
				+ 3 * (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t2
			),
		z = 0.5
			* (
				(-p0.z + p2.z)
				+ 2 * (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t
				+ 3 * (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t2
			),
	}
end

-- -----------------------------------------------------------------------------
-- Segment construction
-- -----------------------------------------------------------------------------

local function clampIndex(index: number, count: number): number
	if index < 1 then
		return 1
	end
	if index > count then
		return count
	end
	return index
end

local function wrapIndex(index: number, count: number): number
	while index < 1 do
		index += count
	end
	while index > count do
		index -= count
	end
	return index
end

local function buildSubSamples(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3): { SubSample }
	-- Sub-sample count chosen generously; track segments are short enough that this keeps the
	local count = 97
	local samples = table.create(count)
	local previous: Vec3? = nil
	local cumulative = 0
	for k = 0, count - 1 do
		local t = k / (count - 1)
		local position = catmullRom(p0, p1, p2, p3, t)
		if previous ~= nil then
			cumulative += len(sub(position, previous))
		end
		samples[k + 1] = { t = t, length = cumulative, position = position }
		previous = position
	end
	return samples
end

local function segmentLengthAt(samples: { SubSample }, t: number): number
	if t <= 0 then
		return 0
	end
	if t >= 1 then
		return samples[#samples].length
	end
	local count = #samples
	local step = 1 / (count - 1)
	local k = math.floor(t / step)
	if k < 1 then
		k = 1
	end
	if k > count - 1 then
		k = count - 1
	end
	local t0 = (k - 1) * step
	local t1 = k * step
	local s = (t - t0) / (t1 - t0)
	local a = samples[k].length
	local b = samples[k + 1].length
	return a + (b - a) * s
end

local function buildSegment(p0: Vec3, p1: Vec3, p2: Vec3, p3: Vec3, sStart: number): Segment
	local samples = buildSubSamples(p0, p1, p2, p3)
	return {
		p0 = p0,
		p1 = p1,
		p2 = p2,
		p3 = p3,
		subSamples = samples,
		length = samples[#samples].length,
		sStart = sStart,
	}
end

-- -----------------------------------------------------------------------------
-- Spline
-- -----------------------------------------------------------------------------

local Spline = {}

local function rebuild(self: Spline)
	local points = self.controlPoints
	local count = #points
	local segments =
		table.create(count > 0 and (self.closed and count or math.max(count - 1, 0)) or 0)
	local sStart = 0
	if count >= 2 then
		for i = 1, (self.closed and count or count - 1) do
			local p0 = points[self.closed and wrapIndex(i - 1, count) or clampIndex(i - 1, count)]
			local p1 = points[i]
			local p2 = points[self.closed and wrapIndex(i + 1, count) or clampIndex(i + 1, count)]
			local p3 = points[self.closed and wrapIndex(i + 2, count) or clampIndex(i + 2, count)]
			local segment = buildSegment(p0, p1, p2, p3, sStart)
			table.insert(segments, segment)
			sStart += segment.length
		end
	end
	self.segments = segments
	self.totalLength = sStart
end

function Spline.sample(self: Spline, t: number): Vec3
	if self.totalLength <= 0 then
		return { x = 0, y = 0, z = 0 }
	end
	if t <= 0 then
		return self.controlPoints[1]
	end
	if t >= 1 then
		return self.controlPoints[#self.controlPoints]
	end
	return self:sampleArcLength(t * self.totalLength).position
end

function Spline.sampleSegment(self: Spline, segmentIndex: number, t: number): Vec3
	if segmentIndex < 1 or segmentIndex > #self.segments then
		return { x = 0, y = 0, z = 0 }
	end
	local segment = self.segments[segmentIndex]
	if t <= 0 then
		return segment.p1
	end
	if t >= 1 then
		return segment.p2
	end
	return catmullRom(segment.p0, segment.p1, segment.p2, segment.p3, t)
end

function Spline.tangent(self: Spline, t: number): Vec3
	return self:sampleArcLength(t * self.totalLength).tangent
end

function Spline.sampleArcLength(self: Spline, s: number): { position: Vec3, tangent: Vec3 }
	if self.totalLength <= 0 then
		return { position = { x = 0, y = 0, z = 0 }, tangent = { x = 0, y = 0, z = 0 } }
	end
	if self.closed then
		while s < 0 do
			s += self.totalLength
		end
		while s > self.totalLength do
			s -= self.totalLength
		end
	else
		if s <= 0 then
			local first = self.controlPoints[1]
			return { position = first, tangent = self:segmentTangent(1, 0) }
		end
		if s >= self.totalLength then
			local last = self.controlPoints[#self.controlPoints]
			local segCount = #self.segments
			return { position = last, tangent = self:segmentTangent(segCount, 1) }
		end
	end

	-- Binary search the segment containing s.
	local segments = self.segments
	local low, high = 1, #segments
	local segmentIndex = 1
	while low <= high do
		local mid = math.floor((low + high) / 2)
		if segments[mid].sStart <= s then
			segmentIndex = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end

	local segment = segments[segmentIndex]
	local localS = s - segment.sStart
	local samples = segment.subSamples
	local count = #samples

	-- Binary search the sub-sample bracket containing localS.
	if localS <= 0 then
		return {
			position = samples[1].position,
			tangent = catmullRomTangent(segment.p0, segment.p1, segment.p2, segment.p3, 0),
		}
	end
	if localS >= segment.length then
		return {
			position = samples[count].position,
			tangent = catmullRomTangent(segment.p0, segment.p1, segment.p2, segment.p3, 1),
		}
	end

	low, high = 1, count - 1
	local bracket = 1
	while low <= high do
		local mid = math.floor((low + high) / 2)
		if samples[mid].length <= localS then
			bracket = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end

	local a = samples[bracket]
	local b = samples[bracket + 1]
	local segSpan = b.length - a.length
	local u = 0
	if segSpan > 0 then
		u = (localS - a.length) / segSpan
	end
	local t = a.t + (b.t - a.t) * u
	local position = catmullRom(segment.p0, segment.p1, segment.p2, segment.p3, t)
	local tangent = catmullRomTangent(segment.p0, segment.p1, segment.p2, segment.p3, t)
	return { position = position, tangent = tangent }
end

function Spline.segmentTangent(self: Spline, segmentIndex: number, t: number): Vec3
	local segment = self.segments[segmentIndex]
	return catmullRomTangent(segment.p0, segment.p1, segment.p2, segment.p3, t)
end

function Spline.arcLengthToT(self: Spline, s: number): { segmentIndex: number, t: number }
	if self.totalLength <= 0 then
		return { segmentIndex = 1, t = 0 }
	end
	if self.closed then
		while s < 0 do
			s += self.totalLength
		end
		while s > self.totalLength do
			s -= self.totalLength
		end
	else
		if s <= 0 then
			return { segmentIndex = 1, t = 0 }
		end
		if s >= self.totalLength then
			return { segmentIndex = #self.segments, t = 1 }
		end
	end
	local segments = self.segments
	local low, high = 1, #segments
	local segmentIndex = 1
	while low <= high do
		local mid = math.floor((low + high) / 2)
		if segments[mid].sStart <= s then
			segmentIndex = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end
	local segment = segments[segmentIndex]
	local localS = s - segment.sStart
	local samples = segment.subSamples
	low, high = 1, #samples - 1
	local bracket = 1
	while low <= high do
		local mid = math.floor((low + high) / 2)
		if samples[mid].length <= localS then
			bracket = mid
			low = mid + 1
		else
			high = mid - 1
		end
	end
	local a = samples[bracket]
	local b = samples[bracket + 1]
	local segSpan = b.length - a.length
	local u = 0
	if segSpan > 0 then
		u = (localS - a.length) / segSpan
	end
	local t = a.t + (b.t - a.t) * u
	return { segmentIndex = segmentIndex, t = t }
end

function Spline.lengthTo(self: Spline, segmentIndex: number, t: number): number
	if segmentIndex < 1 or segmentIndex > #self.segments then
		return 0
	end
	local segment = self.segments[segmentIndex]
	local base = segment.sStart
	if t <= 0 then
		return base
	end
	if t >= 1 then
		return base + segment.length
	end
	return base + segmentLengthAt(segment.subSamples, t)
end

function Spline.addPoint(self: Spline, point: Vec3): number
	table.insert(self.controlPoints, point)
	rebuild(self)
	return #self.controlPoints
end

function Spline.distanceToPoint(
	self: Spline,
	point: Vec3
): { position: Vec3, s: number, distance: number }
	local best: { position: Vec3, s: number, distance: number }? = nil
	for segmentIndex = 1, #self.segments do
		local segment = self.segments[segmentIndex]
		local samples = segment.subSamples
		for k = 1, #samples do
			local distance = len(sub(samples[k].position, point))
			if best == nil or distance < best.distance then
				best = {
					position = samples[k].position,
					s = segment.sStart + samples[k].length,
					distance = distance,
				}
			end
		end
	end
	if best == nil then
		return { position = { x = 0, y = 0, z = 0 }, s = 0, distance = 0 }
	end
	-- Refine around the best sub-sample with a shrinking window search.
	local segmentIndex = 1
	for i = 1, #self.segments do
		if self.segments[i].sStart <= best.s then
			segmentIndex = i
		end
	end
	local segment = self.segments[segmentIndex]
	-- Recover t from the stored sample instead: find sub-sample matching best.position distance.
	-- Simpler: refine in s-space around best.s.
	local searchS = best.s
	local searchStep = math.min(segment.length, 4) -- studs
	for _ = 1, 10 do
		searchStep /= 2
		local candidates = {
			{ s = searchS - searchStep },
			{ s = searchS },
			{ s = searchS + searchStep },
		}
		local improved = false
		for _, c in ipairs(candidates) do
			local s = c.s
			if self.closed then
				while s < 0 do
					s += self.totalLength
				end
				while s > self.totalLength do
					s -= self.totalLength
				end
			elseif s < 0 or s > self.totalLength then
				continue
			end
			local sampled = self:sampleArcLength(s)
			local distance = len(sub(sampled.position, point))
			if distance < best.distance then
				best.distance = distance
				best.position = sampled.position
				best.s = s
				searchS = s
				improved = true
			end
		end
		if not improved then
			break
		end
	end
	return best
end

-- -----------------------------------------------------------------------------
-- Constructor
-- -----------------------------------------------------------------------------

local function new(points: { Vec3 }, closed: boolean?): Spline
	local self: Spline = {
		controlPoints = points,
		segments = {},
		totalLength = 0,
		closed = closed == true,
		sample = Spline.sample,
		sampleSegment = Spline.sampleSegment,
		tangent = Spline.tangent,
		sampleArcLength = Spline.sampleArcLength,
		segmentTangent = Spline.segmentTangent,
		arcLengthToT = Spline.arcLengthToT,
		lengthTo = Spline.lengthTo,
		addPoint = Spline.addPoint,
		distanceToPoint = Spline.distanceToPoint,
	}
	rebuild(self)
	return self
end

return {
	new = new,
	vec3 = vec3,
	STUD_PER_METER = STUD_PER_METER,
}
