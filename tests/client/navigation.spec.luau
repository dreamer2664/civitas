--!strict
-- The navigation stack rules from UI-SPEC §6. Every operation returns a new stack, so the
-- assertions also check that the previous value is untouched.

local harness = require("../harness")
local Navigation = require("../../src/client/UI/Navigation")

harness.suite("navigation")

harness.test("a new stack has the root on top at depth one", function()
	local nav = Navigation.new("mainMenu")
	harness.equal(Navigation.top(nav), "mainMenu")
	harness.equal(Navigation.depth(nav), 1)
end)

harness.test("an empty root id is refused", function()
	harness.raises(function()
		Navigation.new("")
	end, "non-empty")
end)

harness.test("pushing the screen already on top changes nothing (double taps)", function()
	local nav = Navigation.push(Navigation.new("mainMenu"), "cab")
	local again = Navigation.push(nav, "cab")
	harness.equal(again, nav, "same stack value expected")
	harness.equal(Navigation.depth(again), 2)
end)

harness.test("revisiting a screen pops back to it instead of stacking a duplicate", function()
	local nav = Navigation.new("mainMenu")
	nav = Navigation.push(nav, "cab")
	nav = Navigation.push(nav, "map")
	nav = Navigation.push(nav, "cab")
	harness.equal(Navigation.depth(nav), 2)
	harness.equal(Navigation.top(nav), "cab")
	harness.falsy(Navigation.contains(nav, "map"))
end)

harness.test("back unwinds in order and then reports atRoot without changing the stack", function()
	local nav = Navigation.new("mainMenu")
	nav = Navigation.push(nav, "cab")
	nav = Navigation.push(nav, "map")
	nav = Navigation.push(nav, "pause")

	local result: "popped" | "atRoot"
	nav, result = Navigation.back(nav)
	harness.equal(result, "popped")
	harness.equal(Navigation.top(nav), "map")
	nav, result = Navigation.back(nav)
	harness.equal(Navigation.top(nav), "cab")
	nav, result = Navigation.back(nav)
	harness.equal(Navigation.top(nav), "mainMenu")
	local before = nav
	nav, result = Navigation.back(nav)
	harness.equal(result, "atRoot", "the caller decides what back means at the root")
	harness.equal(nav, before)
end)

harness.test("push and back never mutate the stack they were given", function()
	local base = Navigation.push(Navigation.new("mainMenu"), "cab")
	local pushed = Navigation.push(base, "map")
	harness.equal(Navigation.depth(base), 2, "base must not grow")
	local _, _ = Navigation.back(pushed)
	harness.equal(Navigation.depth(pushed), 3, "pushed must not shrink")
end)

harness.test("replace swaps the top screen without changing depth", function()
	local nav = Navigation.push(Navigation.new("mainMenu"), "cab")
	local replaced = Navigation.replace(nav, "station")
	harness.equal(Navigation.top(replaced), "station")
	harness.equal(Navigation.depth(replaced), 2)
end)
