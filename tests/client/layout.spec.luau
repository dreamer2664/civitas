--!strict
-- Layout maths for phone portrait, phone landscape, tablet and desktop. These numbers are what
-- the UI spec (§6 Layout) promises. They are checked here, not in an emulator.

local harness = require("../harness")
local Layout = require("../../src/client/UI/Layout")
local Theme = require("../../src/client/UI/Theme")

harness.suite("layout")

-- Device sizes in Roblox viewport points (short side and long side).
local IPHONE_PORTRAIT = { w = 390, h = 844 }
local IPHONE_LANDSCAPE = { w = 844, h = 390 }
local TABLET_PORTRAIT = { w = 768, h = 1024 }
local DESKTOP = { w = 1920, h = 1080 }

harness.test("UDim resolves as scale × parent plus offset", function()
	harness.equal(Layout.resolve({ scale = 0.5, offset = 10 }, 800), 410)
	harness.equal(Layout.resolve({ scale = 0, offset = -16 }, 800), -16)
	harness.equal(Layout.resolve({ scale = 1, offset = -5 }, 200), 195)
end)

harness.test("anchorOrigin centres a centred object in its parent", function()
	local origin = Layout.anchorOrigin(
		{ x = 0, y = 0, w = 400, h = 300 },
		{ x = 100, y = 50 },
		{ x = 0.5, y = 0.5 },
		{ x = { scale = 0.5, offset = 0 }, y = { scale = 0.5, offset = 0 } }
	)
	harness.equal(origin.x, 150)
	harness.equal(origin.y, 125)
end)

harness.test("anchorOrigin honours a parent offset and a right-edge anchor", function()
	local origin = Layout.anchorOrigin(
		{ x = 10, y = 20, w = 200, h = 100 },
		{ x = 40, y = 40 },
		{ x = 1, y = 0 },
		{ x = { scale = 1, offset = -5 }, y = { scale = 0, offset = 0 } }
	)
	-- Anchor lands at parent.x + 200 - 5 = 205; the right edge of the object sits there.
	harness.equal(origin.x, 165)
	harness.equal(origin.y, 20)
end)

harness.test("classify: iPhone portrait and landscape are both phones", function()
	local p = Layout.classify(IPHONE_PORTRAIT.w, IPHONE_PORTRAIT.h)
	harness.equal(p.class, "phone")
	harness.equal(p.orientation, "portrait")
	local l = Layout.classify(IPHONE_LANDSCAPE.w, IPHONE_LANDSCAPE.h)
	harness.equal(l.class, "phone")
	harness.equal(l.orientation, "landscape")
end)

harness.test("classify: tablet portrait, desktop landscape", function()
	local t = Layout.classify(TABLET_PORTRAIT.w, TABLET_PORTRAIT.h)
	harness.equal(t.class, "tablet")
	harness.equal(t.orientation, "portrait")
	local d = Layout.classify(DESKTOP.w, DESKTOP.h)
	harness.equal(d.class, "desktop")
	harness.equal(d.orientation, "landscape")
end)

harness.test("classify: a square 800 pt short side is desktop, 799 is tablet", function()
	harness.equal(Layout.classify(800, 900).class, "desktop")
	harness.equal(Layout.classify(799, 900).class, "tablet")
end)

harness.test("classify refuses a zero-size viewport instead of guessing", function()
	harness.raises(function()
		Layout.classify(0, 600)
	end, "positive viewport")
end)

harness.test("gutter follows the breakpoint class", function()
	local phone = Layout.classify(IPHONE_PORTRAIT.w, IPHONE_PORTRAIT.h)
	local desk = Layout.classify(DESKTOP.w, DESKTOP.h)
	harness.equal(Layout.gutter(phone, 12, 16, 24), 12)
	harness.equal(Layout.gutter(desk, 12, 16, 24), 24)
end)

harness.test("text sizes are clamped to the design floor and ceiling", function()
	harness.equal(Layout.clampTextSize(8, Theme.size.minTextSize, Theme.size.maxTextSize), 12)
	harness.equal(Layout.clampTextSize(100, Theme.size.minTextSize, Theme.size.maxTextSize), 72)
	harness.equal(Layout.clampTextSize(16, Theme.size.minTextSize, Theme.size.maxTextSize), 16)
end)

harness.test("touch sizes grow to the minimum and never shrink", function()
	local w, h = Layout.touchSize(30, 60, Theme.size.touchMin)
	harness.equal(w, 48)
	harness.equal(h, 60)
	harness.truthy(Layout.meetsTouchMinimum(w, h, Theme.size.touchMin))
	harness.falsy(Layout.meetsTouchMinimum(47, 48, Theme.size.touchMin))
end)

harness.test("safe rect removes notch and home-bar insets on a landscape phone", function()
	local safe = Layout.safeRect(IPHONE_LANDSCAPE.w, IPHONE_LANDSCAPE.h, {
		top = 0,
		bottom = 21,
		left = 47,
		right = 47,
	})
	harness.equal(safe.x, 47)
	harness.equal(safe.w, 750)
	harness.equal(safe.h, 369)
end)

harness.test("safe rect never goes negative when insets exceed the viewport", function()
	local safe = Layout.safeRect(40, 40, { top = 30, bottom = 30, left = 30, right = 30 })
	harness.equal(safe.w, 0)
	harness.equal(safe.h, 0)
end)

harness.test("fitAspect keeps the ratio inside the available area", function()
	local w, h = Layout.fitAspect(800, 600, 16 / 9)
	harness.near(w, 800, 0.001)
	harness.near(h, 450, 0.001)
	local sw, sh = Layout.fitAspect(600, 800, 1)
	harness.near(sw, 600, 0.001)
	harness.near(sh, 600, 0.001)
	local zw, zh = Layout.fitAspect(0, 600, 2)
	harness.equal(zw, 0)
	harness.equal(zh, 0)
end)

harness.test("stack height counts gaps between items, not after the last", function()
	harness.equal(Layout.stackHeight(3, 48, 8), 160)
	harness.equal(Layout.stackHeight(1, 48, 8), 48)
	harness.equal(Layout.stackHeight(0, 48, 8), 0)
end)

harness.test("grid cells tile the area with gaps and stay inside it", function()
	local area = { x = 0, y = 0, w = 300, h = 166 }
	local cells = Layout.gridCells(area, 2, 2, 8)
	harness.equal(#cells, 4)
	for _, c in cells do
		harness.truthy(
			c.x >= area.x and c.x + c.w <= area.x + area.w + 0.001,
			"cell leaves area horizontally"
		)
		harness.truthy(
			c.y >= area.y and c.y + c.h <= area.y + area.h + 0.001,
			"cell leaves area vertically"
		)
	end
	harness.near(cells[2].x, 154, 0.001, "second column starts after one width and one gap")
end)

harness.test(
	"cab thumb zones on a landscape phone are disjoint, anchored bottom, and big enough",
	function()
		local safe = Layout.safeRect(IPHONE_LANDSCAPE.w, IPHONE_LANDSCAPE.h, {
			top = 0,
			bottom = 21,
			left = 47,
			right = 47,
		})
		local zones = Layout.cabThumbZones(safe)
		local left, right = zones.left, zones.right

		harness.truthy(left.x + left.w <= right.x, "left and right thumb zones overlap")
		harness.near(left.y + left.h, safe.y + safe.h, 0.001, "left zone is not bottom-anchored")
		harness.near(right.y + right.h, safe.y + safe.h, 0.001, "right zone is not bottom-anchored")

		-- Each zone must hold a 2 × 2 grid of comfortable controls on a phone in landscape.
		for _, zone in { left, right } do
			for _, cell in Layout.gridCells(zone, 2, 2, Theme.space.s2) do
				harness.truthy(cell.w >= Theme.size.touchComfort, `cab cell is {cell.w} px wide`)
				harness.truthy(cell.h >= Theme.size.touchComfort, `cab cell is {cell.h} px tall`)
			end
		end
	end
)

-- Device profiles (UI-SPEC §6). Each named profile must give every menu column a touch target of
-- at least the touch minimum, and the cab must be unavailable wherever its thumb zones would be
-- too narrow to use. These are the claims the Manager's device table repeats.
local SAMPLES: { [string]: { w: number, h: number } } = {
	["phone-portrait"] = IPHONE_PORTRAIT,
	["phone-landscape"] = IPHONE_LANDSCAPE,
	["tablet-portrait"] = TABLET_PORTRAIT,
	["tablet-landscape"] = { w = 1024, h = 768 },
	["desktop"] = DESKTOP,
}

harness.test("each sample viewport maps to its named profile", function()
	for name, size in SAMPLES do
		harness.equal(Layout.profileFor(size.w, size.h).name, name, name)
	end
end)

harness.test("every profile keeps menu columns at or above the touch minimum", function()
	local gap = Theme.space.s4
	for name, size in SAMPLES do
		local profile = Layout.profileFor(size.w, size.h)
		local area = { x = 0, y = 0, w = size.w - 2 * profile.gutter, h = size.h }
		local cells = Layout.gridCells(area, profile.columns, 1, gap)
		for _, cell in cells do
			harness.truthy(
				Layout.meetsTouchMinimum(cell.w, cell.h, Theme.size.touchMin),
				`{name}: a menu column is {cell.w}×{cell.h}, below the touch minimum`
			)
		end
	end
end)

harness.test("the cab is available in landscape and on desktop, never in portrait", function()
	harness.falsy(Layout.profileFor(390, 844).cabAvailable, "phone portrait")
	harness.falsy(Layout.profileFor(768, 1024).cabAvailable, "tablet portrait")
	harness.truthy(Layout.profileFor(844, 390).cabAvailable, "phone landscape")
	harness.truthy(Layout.profileFor(1920, 1080).cabAvailable, "desktop")
end)

harness.test("phone landscape cab thumb cells reach the comfort size", function()
	local safe = Layout.safeRect(844, 390, { top = 0, bottom = 0, left = 44, right = 44 })
	local zones = Layout.cabThumbZones(safe)
	for _, zone in { zones.left, zones.right } do
		local cells = Layout.gridCells(zone, 2, 2, Theme.space.s2)
		for _, cell in cells do
			harness.truthy(
				cell.w >= Theme.size.touchComfort and cell.h >= Theme.size.touchComfort,
				`thumb cell {cell.w}×{cell.h} is below the comfort size`
			)
		end
	end
end)

harness.test("a centred control lands in the middle of a phone portrait screen", function()
	local origin = Layout.anchorOrigin(
		{ x = 0, y = 0, w = 390, h = 844 },
		{ x = 200, y = 56 },
		{ x = 0.5, y = 0.5 },
		{ x = { scale = 0.5, offset = 0 }, y = { scale = 0.5, offset = 0 } }
	)
	harness.near(origin.x, 95, 1e-9)
	harness.near(origin.y, 394, 1e-9)
end)

harness.test("a bottom-right control on phone landscape keeps its 16 px margin", function()
	local origin = Layout.anchorOrigin(
		{ x = 0, y = 0, w = 844, h = 390 },
		{ x = 120, y = 56 },
		{ x = 1, y = 1 },
		{ x = { scale = 1, offset = -16 }, y = { scale = 1, offset = -16 } }
	)
	harness.near(origin.x, 708, 1e-9)
	harness.near(origin.y, 318, 1e-9)
end)

-- Walk-mode touch controls. The 8 px gap comes from Theme.space; the safe areas are the insets a
-- notched phone reports (landscape side insets 47 pt, portrait top 47 and bottom 34 pt).
harness.suite("layout touch controls")

local TOUCH_GAP = Theme.space.s2
local TOUCH_ACTIONS = 4 -- interact, jump, sprint, menu

local function safeFor(size: { w: number, h: number }, insets: Layout.Insets): Layout.Rect
	return Layout.safeRect(size.w, size.h, insets)
end

local function allRects(controls: { pad: Layout.Rect, actions: { Layout.Rect } }): { Layout.Rect }
	local out = { controls.pad }
	for _, r in controls.actions do
		table.insert(out, r)
	end
	return out
end

local function overlaps(a: Layout.Rect, b: Layout.Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

local function inside(outer: Layout.Rect, r: Layout.Rect): boolean
	return r.x >= outer.x
		and r.y >= outer.y
		and r.x + r.w <= outer.x + outer.w
		and r.y + r.h <= outer.y + outer.h
end

local PHONE_PORTRAIT_INSETS = { top = 47, bottom = 34, left = 0, right = 0 }
local PHONE_LANDSCAPE_INSETS = { top = 0, bottom = 21, left = 47, right = 47 }

harness.test(
	"touch controls: every control reaches the 56 px comfort size on a phone in portrait",
	function()
		local safe = safeFor(IPHONE_PORTRAIT, PHONE_PORTRAIT_INSETS)
		local controls = Layout.touchControls(safe, TOUCH_GAP, TOUCH_ACTIONS)
		for i, r in allRects(controls) do
			harness.truthy(r.w >= Theme.size.touchComfort, `portrait control {i} is {r.w} px wide`)
			harness.truthy(r.h >= Theme.size.touchComfort, `portrait control {i} is {r.h} px tall`)
		end
	end
)

harness.test(
	"touch controls: every control reaches the 56 px comfort size on a phone in landscape",
	function()
		local safe = safeFor(IPHONE_LANDSCAPE, PHONE_LANDSCAPE_INSETS)
		local controls = Layout.touchControls(safe, TOUCH_GAP, TOUCH_ACTIONS)
		for i, r in allRects(controls) do
			harness.truthy(r.w >= Theme.size.touchComfort, `landscape control {i} is {r.w} px wide`)
			harness.truthy(r.h >= Theme.size.touchComfort, `landscape control {i} is {r.h} px tall`)
		end
	end
)

harness.test(
	"touch controls: the smallest supported phone (320 px wide) still meets the 48 px minimum",
	function()
		local safe = safeFor({ w = 320, h = 568 }, { top = 20, bottom = 0, left = 0, right = 0 })
		local controls = Layout.touchControls(safe, TOUCH_GAP, TOUCH_ACTIONS)
		for i, r in allRects(controls) do
			harness.truthy(
				Layout.meetsTouchMinimum(r.w, r.h, Theme.size.touchMin),
				`small phone control {i} is {r.w}×{r.h}`
			)
		end
	end
)

harness.test("touch controls stay inside the safe area and never overlap", function()
	for _, case in
		{ { IPHONE_PORTRAIT, PHONE_PORTRAIT_INSETS }, { IPHONE_LANDSCAPE, PHONE_LANDSCAPE_INSETS } }
	do
		local safe = safeFor(case[1], case[2])
		local rects = allRects(Layout.touchControls(safe, TOUCH_GAP, TOUCH_ACTIONS))
		for i, r in rects do
			harness.truthy(inside(safe, r), `control {i} leaves the safe area`)
			for j = i + 1, #rects do
				harness.falsy(overlaps(r, rects[j]), `controls {i} and {j} overlap`)
			end
		end
	end
end)

harness.test("the movement pad is in the left thumb zone and the actions in the right", function()
	local safe = safeFor(IPHONE_LANDSCAPE, PHONE_LANDSCAPE_INSETS)
	local controls = Layout.touchControls(safe, TOUCH_GAP, TOUCH_ACTIONS)
	local midX = safe.x + safe.w / 2
	harness.truthy(controls.pad.x + controls.pad.w <= midX, "pad crosses into the right half")
	for i, r in controls.actions do
		harness.truthy(r.x >= midX, `action {i} sits in the left half`)
	end
	harness.equal(#controls.actions, TOUCH_ACTIONS)
end)

harness.test(
	"with no actions the layout returns the pad alone, and a partial row fills in order",
	function()
		local safe = safeFor(IPHONE_LANDSCAPE, PHONE_LANDSCAPE_INSETS)
		harness.equal(#Layout.touchControls(safe, TOUCH_GAP, 0).actions, 0)
		harness.equal(#Layout.touchControls(safe, TOUCH_GAP, 3).actions, 3)
		harness.raises(function()
			Layout.touchControls(safe, TOUCH_GAP, 1.5)
		end, "whole number")
	end
)

harness.test(
	"pad vector: the centre is zero, the edge is unit length, beyond the edge is clamped",
	function()
		local pad = { x = 0, y = 0, w = 100, h = 100 }
		local x, y = Layout.padVector(pad, 50, 50)
		harness.near(x, 0, 1e-9)
		harness.near(y, 0, 1e-9)
		x, y = Layout.padVector(pad, 100, 50)
		harness.near(x, 1, 1e-9, "right edge")
		harness.near(y, 0, 1e-9)
		x, y = Layout.padVector(pad, 500, 50)
		harness.near(x, 1, 1e-9, "far beyond the edge is still full speed, not more")
		harness.near(y, 0, 1e-9)
	end
)

harness.test(
	"pad vector: up on screen is negative y, and the diagonal stays unit length",
	function()
		local pad = { x = 0, y = 0, w = 100, h = 100 }
		local _, up = Layout.padVector(pad, 50, 0)
		harness.near(up, -1, 1e-9, "top edge should be -1 (screen y grows downward)")
		local dx, dy = Layout.padVector(pad, 200, 200)
		harness.near(
			math.sqrt(dx * dx + dy * dy),
			1,
			1e-9,
			"diagonal beyond the edge is unit length"
		)
	end
)
