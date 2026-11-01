--!strict
--[[
	Deterministic layout maths. Pure: takes numbers in, returns numbers out, so every rule in the
	UI spec (anchor resolution, breakpoints, safe areas, touch minimums, cab thumb zones) is checked
	by lune on the desktop, not by eye in a device emulator.

	Roblox resolves a GuiObject's top-left corner as:
	    origin = parent.origin + (scale * parent.size + offset) - anchor * size
	`anchorOrigin` below is that exact formula, so the tests describe what Roblox will draw.
]]

-- No requires here on purpose. Roblox resolves modules through `script.Parent`, which lune cannot
-- follow, so pure modules stay dependency-free and take token values as arguments. The Roblox
-- components pass Theme values in; the lune tests pass the same Theme values from their side.

local Layout = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Insets = { top: number, bottom: number, left: number, right: number }
export type Vec2 = { x: number, y: number }
export type UDim = { scale: number, offset: number }
export type Breakpoint = {
	class: "phone" | "tablet" | "desktop",
	orientation: "portrait" | "landscape",
}

-- UDim resolution: scale is a fraction of the parent, offset is added in pixels.
function Layout.resolve(d: UDim, parentPx: number): number
	return d.scale * parentPx + d.offset
end

-- Breakpoints use the short side, so a phone is a phone in both orientations. Thresholds sit
-- between common device classes: 500 separates phones (≤ 430 pt short side) from tablets
-- (≥ 744 pt); 800 separates tablets from desktop windows.
function Layout.classify(width: number, height: number): Breakpoint
	assert(width > 0 and height > 0, "Layout.classify needs a positive viewport")
	local short = math.min(width, height)
	local class: "phone" | "tablet" | "desktop" = "desktop"
	if short < 500 then
		class = "phone"
	elseif short < 800 then
		class = "tablet"
	end
	return {
		class = class,
		orientation = if height > width then "portrait" else "landscape",
	}
end

-- Horizontal gutter between the screen edge and content. The caller passes the spacing tokens
-- (Theme.space) so the mapping from class to gutter stays visible at the call site.
function Layout.gutter(bp: Breakpoint, phone: number, tablet: number, desktop: number): number
	if bp.class == "phone" then
		return phone
	elseif bp.class == "tablet" then
		return tablet
	end
	return desktop
end

-- Text is never smaller than the design floor, whatever a size calculation produces.
function Layout.clampTextSize(requested: number, minSize: number, maxSize: number): number
	return math.clamp(requested, minSize, maxSize)
end

-- Tappable areas grow to the touch minimum but never shrink below the design size.
function Layout.touchSize(w: number, h: number, touchMin: number): (number, number)
	return math.max(w, touchMin), math.max(h, touchMin)
end

function Layout.meetsTouchMinimum(w: number, h: number, touchMin: number): boolean
	return w >= touchMin and h >= touchMin
end

-- The area left after safe-area insets (notches, the Roblox top bar, the home indicator).
-- Clamped at zero so a degenerate viewport cannot produce a negative size.
function Layout.safeRect(width: number, height: number, insets: Insets): Rect
	local w = math.max(0, width - insets.left - insets.right)
	local h = math.max(0, height - insets.top - insets.bottom)
	return { x = insets.left, y = insets.top, w = w, h = h }
end

-- Top-left corner of a GuiObject inside `parent`, using Roblox's anchor semantics.
-- `position` is the UDim pair Roblox stores in Position; `anchor` is AnchorPoint (0..1 each).
function Layout.anchorOrigin(
	parent: Rect,
	size: Vec2,
	anchor: Vec2,
	position: { x: UDim, y: UDim }
): Vec2
	local px = Layout.resolve(position.x, parent.w) + parent.x
	local py = Layout.resolve(position.y, parent.h) + parent.y
	return {
		x = px - anchor.x * size.x,
		y = py - anchor.y * size.y,
	}
end

-- Largest rectangle of a given aspect ratio (width / height) that fits in the available area.
-- Used for the map canvas and in-world sign apertures, which must never stretch.
function Layout.fitAspect(availW: number, availH: number, aspect: number): (number, number)
	assert(aspect > 0, "aspect must be positive")
	if availW <= 0 or availH <= 0 then
		return 0, 0
	end
	if availW / availH > aspect then
		return availH * aspect, availH
	end
	return availW, availW / aspect
end

-- Height of a vertical stack: `count` items of `itemH` with `gap` between them, no trailing gap.
function Layout.stackHeight(count: number, itemH: number, gap: number): number
	if count <= 0 then
		return 0
	end
	return count * itemH + (count - 1) * gap
end

-- Cab thumb zones for a landscape phone. The left thumb owns reverser, horn and doors; the right
-- thumb owns throttle, brake and emergency brake. Each zone sits in the bottom 45% of the safe
-- area and never overlaps the other. The default Roblox thumbstick is switched off in the cab.
function Layout.cabThumbZones(safe: Rect): { left: Rect, right: Rect }
	local zoneH = safe.h * 0.45
	local zoneY = safe.y + safe.h - zoneH
	local leftW = safe.w * 0.4
	local rightW = safe.w * 0.4
	return {
		left = { x = safe.x, y = zoneY, w = leftW, h = zoneH },
		right = { x = safe.x + safe.w - rightW, y = zoneY, w = rightW, h = zoneH },
	}
end

-- Splits a rect into cols × rows equal cells with `gap` between them. Cells are returned row by
-- row, left to right. Used to place cab controls inside a thumb zone without hand-tuned offsets.
function Layout.gridCells(area: Rect, cols: number, rows: number, gap: number): { Rect }
	assert(cols >= 1 and rows >= 1, "grid needs at least one row and one column")
	local cellW = (area.w - (cols - 1) * gap) / cols
	local cellH = (area.h - (rows - 1) * gap) / rows
	local cells: { Rect } = {}
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			table.insert(cells, {
				x = area.x + c * (cellW + gap),
				y = area.y + r * (cellH + gap),
				w = cellW,
				h = cellH,
			})
		end
	end
	return cells
end

return Layout
