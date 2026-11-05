--!strict
local suite = require("../support/suite")
local expect = suite.expect
local Gate = require("../../src/shared/Rail/ControlGate")

suite.test("ControlGate: only the seated character has authority", function()
	local alice, bob = {}, {}
	expect.equal(Gate.authorized(alice, alice), true)
	expect.equal(Gate.authorized(alice, bob), false)
	expect.equal(Gate.authorized(nil, nil), false)
	expect.equal(Gate.authorized(alice, nil), false)
end)

suite.test("ControlGate: independent per-player buckets enforce burst and refill", function()
	local first: Gate.Bucket? = nil
	local second: Gate.Bucket? = nil
	local ok: boolean
	for _ = 1, 20 do
		first, ok = Gate.consume(first, 1)
		expect.equal(ok, true)
	end
	first, ok = Gate.consume(first, 1)
	expect.equal(ok, false)
	second, ok = Gate.consume(second, 1)
	expect.equal(ok, true)
	first, ok = Gate.consume(first, 1.25)
	expect.equal(ok, true)
	first, ok = Gate.consume(first, 1.25)
	expect.equal(ok, true)
	first, ok = Gate.consume(first, 1.25)
	expect.equal(ok, false)
end)

suite.test("ControlGate: rejects invalid time and rollback without granting tokens", function()
	local bucket: Gate.Bucket?
	local allowed: boolean
	bucket, allowed = Gate.consume(nil, 10)
	expect.equal(allowed, true)
	local old = bucket
	bucket, allowed = Gate.consume(bucket, 9)
	expect.equal(allowed, false)
	expect.equal(bucket, old)
	bucket, allowed = Gate.consume(bucket, 0 / 0)
	expect.equal(allowed, false)
	bucket, allowed = Gate.consume(bucket, math.huge)
	expect.equal(allowed, false)
end)
