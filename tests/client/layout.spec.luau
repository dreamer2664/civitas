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
