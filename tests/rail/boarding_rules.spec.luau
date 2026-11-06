--!strict
local suite = require("../support/suite")
local expect = suite.expect
local BoardingRules = require("../../src/shared/Rail/BoardingRules")

suite.test(
	"BoardingRules: requires platform, open doors, a free seat and a stopped train",
	function()
		expect.equal(BoardingRules.canBoard(true, 0, true, true), true)
		expect.equal(BoardingRules.canBoard(false, 0, true, true), false)
		expect.equal(BoardingRules.canBoard(true, 0, false, true), false)
		expect.equal(BoardingRules.canBoard(true, 0, true, false), false)
		expect.equal(BoardingRules.canBoard(true, 0.02, true, true), false)
		expect.equal(BoardingRules.canBoard(true, -0.02, true, true), false)
		expect.equal(BoardingRules.canBoard(true, 0 / 0, true, true), false)
		expect.equal(BoardingRules.canBoard(true, math.huge, true, true), false)
	end
)

suite.test("BoardingRules: alighting requires a seated passenger and a safe stop", function()
	expect.equal(BoardingRules.canAlight(true, 0, true, true), true)
	expect.equal(BoardingRules.canAlight(true, 0, true, false), false)
	expect.equal(BoardingRules.canAlight(false, 0, true, true), false)
	expect.equal(BoardingRules.canAlight(true, 3, true, true), false)
	expect.equal(BoardingRules.canAlight(true, 0, false, true), false)
end)
