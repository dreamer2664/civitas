--!strict
--[[
	World (X, Z) to map-canvas pixels, plus zoom and pan. Pure.

	Frame: NETWORK.md §1 gives X east and Z south, in studs. The map draws north at the top, so the
	anchor is the minimum Z (the northmost point) and screen y grows with Z.

	Model: screen x = (x - minX) * scale + ox ; screen y = (z - minZ) * scale + oy
	- The anchors (minX, minZ) are stored in the transform, so zooming and panning change only the
	  scale and the offset. That keeps the zoom-about-a-point maths in one place.
	- Roblox GUI y also grows downward, so no flip is needed: the orientation comes from the anchor.

	Rotations follow the same screen convention: a Frame's Rotation is clockwise, and atan2 in
	screen space gives clockwise-positive angles, so the two agree. Verifying that Roblox draws a
	rotated segment exactly where the maths says is listed as unverified in the report.
]]

local MapProjection = {}

export type Bounds = { minX: number, minZ: number, maxX: number, maxZ: number }
export type Transform = {
	minX: number,
	minZ: number,
	scale: number,
	ox: number,
	oy: number,
}
export type Segment = { x1: number, z1: number, x2: number, z2: number }
export type Drawn = { cx: number, cy: number, length: number, angleDeg: number }

-- Fits the whole network inside a view of `viewW` × `viewH` pixels, keeping the aspect ratio and
-- centring the leftover space. A degenerate extent (one station) is widened to one stud so the
-- division is defined.
function MapProjection.fit(bounds: Bounds, viewW: number, viewH: number, padding: number): Transform
	assert(viewW > 0 and viewH > 0, "map view must have a positive size")
	local contentW = math.max(bounds.maxX - bounds.minX, 1)
	local contentH = math.max(bounds.maxZ - bounds.minZ, 1)
	local availW = math.max(viewW - 2 * padding, 1)
	local availH = math.max(viewH - 2 * padding, 1)
	local scale = math.min(availW / contentW, availH / contentH)
	return {
		minX = bounds.minX,
		minZ = bounds.minZ,
		scale = scale,
		ox = padding + (availW - contentW * scale) / 2,
		oy = padding + (availH - contentH * scale) / 2,
	}
end

function MapProjection.toScreen(t: Transform, x: number, z: number): (number, number)
	return (x - t.minX) * t.scale + t.ox, (z - t.minZ) * t.scale + t.oy
end

function MapProjection.fromScreen(t: Transform, sx: number, sy: number): (number, number)
	return (sx - t.ox) / t.scale + t.minX, (sy - t.oy) / t.scale + t.minZ
end

-- Zoom by `factor` while keeping the world point under (px, py) fixed on screen. That is what a
-- pinch or a wheel tick should feel like. The scale is clamped, and the anchor stays exact.
function MapProjection.zoomAt(
	t: Transform,
	px: number,
	py: number,
	factor: number,
	minScale: number,
	maxScale: number
): Transform
	assert(factor > 0, "zoom factor must be positive")
	local wx, wz = MapProjection.fromScreen(t, px, py)
	local scale = math.clamp(t.scale * factor, minScale, maxScale)
	return {
		minX = t.minX,
		minZ = t.minZ,
		scale = scale,
		ox = px - (wx - t.minX) * scale,
		oy = py - (wz - t.minZ) * scale,
	}
end

function MapProjection.panBy(t: Transform, dx: number, dy: number): Transform
	return {
		minX = t.minX,
		minZ = t.minZ,
		scale = t.scale,
		ox = t.ox + dx,
		oy = t.oy + dy,
	}
end

-- Stops the network being dragged off screen. At least a quarter of the view, or the whole
-- content if it is smaller, has to stay visible on each axis.
function MapProjection.clampToView(
	t: Transform,
	bounds: Bounds,
	viewW: number,
	viewH: number
): Transform
	local cw = (bounds.maxX - bounds.minX) * t.scale
	local ch = (bounds.maxZ - bounds.minZ) * t.scale
	local keepX = math.min(cw, viewW * 0.25)
	local keepY = math.min(ch, viewH * 0.25)
	return {
		minX = t.minX,
		minZ = t.minZ,
		scale = t.scale,
		ox = math.clamp(t.ox, keepX - cw, viewW - keepX),
		oy = math.clamp(t.oy, keepY - ch, viewH - keepY),
	}
end

-- Screen-space placement of one straight segment: its midpoint, length and angle.
function MapProjection.drawSegment(t: Transform, seg: Segment): Drawn
	local ax, ay = MapProjection.toScreen(t, seg.x1, seg.z1)
	local bx, by = MapProjection.toScreen(t, seg.x2, seg.z2)
	local dx = bx - ax
	local dy = by - ay
	return {
		cx = (ax + bx) / 2,
		cy = (ay + by) / 2,
		length = math.sqrt(dx * dx + dy * dy),
		angleDeg = math.deg(math.atan2(dy, dx)),
	}
end

return MapProjection
