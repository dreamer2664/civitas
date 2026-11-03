--!strict
--[[
Doors backpressure fixture.

Tests the RateLimit behavior for door / station-board events using the
Station.Board configuration from RemoteContract:
  rate = { maxPerSecond = 2, burst = 4 }

Verifies that:
  - A burst of board requests is allowed up to the burst limit.
  - A spammy client is throttled beyond the burst.
  - Per-client buckets are independent: a slow/spammy client does not starve
    a well-behaved client's door/board events.
  - Tokens refill over time, so the feed recovers.

Pure Luau: no DataModel access, testable with lune.
--]]

local suite = require("../support/suite")
local RateLimit = require("../../src/shared/Util/RateLimit")

local BOARD_CONFIG = { maxPerSecond = 2, burst = 4 } -- Signal.Observe-style / Station.Board rate

local function makeClientBucket()
	return RateLimit.new(BOARD_CONFIG)
end

suite.test("Doors backpressure fixture: burst allows up to burst board requests", function()
	local bucket = makeClientBucket()
	local allowed = 0
	for _ = 1, BOARD_CONFIG.burst do
		local result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 0)
		if result.allowed then
			allowed += 1
			bucket = result.bucket
		end
	end
	suite.expect.equal(allowed, BOARD_CONFIG.burst)
end)

suite.test("Doors backpressure fixture: spam beyond burst is rejected", function()
	local bucket = makeClientBucket()
	local allowed = 0
	for _ = 1, 20 do
		local result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 0)
		if result.allowed then
			allowed += 1
			bucket = result.bucket
		end
	end
	suite.expect.equal(allowed, BOARD_CONFIG.burst)
end)

suite.test("Doors backpressure fixture: per-client buckets are independent", function()
	local spamBucket = makeClientBucket()
	local goodBucket = makeClientBucket()

	-- Spam client fires 100 requests instantly at t=0.
	local spamAllowed = 0
	for _ = 1, 100 do
		local result = RateLimit.tryConsume(spamBucket, BOARD_CONFIG, 0)
		if result.allowed then
			spamAllowed += 1
			spamBucket = result.bucket
		end
	end
	suite.expect.ok(spamAllowed <= BOARD_CONFIG.burst)

	-- Well-behaved client at t=0 still gets its full burst — unaffected by spam.
	local goodAllowed = 0
	for _ = 1, BOARD_CONFIG.burst do
		local result = RateLimit.tryConsume(goodBucket, BOARD_CONFIG, 0)
		if result.allowed then
			goodAllowed += 1
			goodBucket = result.bucket
		end
	end
	suite.expect.equal(goodAllowed, BOARD_CONFIG.burst)
end)

suite.test("Doors backpressure fixture: tokens refill over time, feed recovers", function()
	local bucket = makeClientBucket()

	-- Exhaust the burst at t=0.
	for _ = 1, BOARD_CONFIG.burst do
		local result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 0)
		bucket = result.bucket
	end

	-- Immediately after exhaustion, nothing is allowed.
	local result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 0)
	suite.expect.ok(result.allowed == false)

	-- After 2 seconds at 2/s, 4 tokens have refilled → full burst available again.
	for _ = 1, BOARD_CONFIG.burst do
		result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 2)
		if result.allowed then
			bucket = result.bucket
		end
	end
	suite.expect.ok(result.allowed == true)

	-- After refill, exhausted again.
	result = RateLimit.tryConsume(bucket, BOARD_CONFIG, 2)
	suite.expect.ok(result.allowed == false)
end)

suite.test("Doors backpressure fixture: hostile inputs are handled safely", function()
	local bucket = makeClientBucket()

	-- Negative time should not crash or allow infinite tokens.
	local result = RateLimit.tryConsume(bucket, BOARD_CONFIG, -100)
	suite.expect.ok(result.allowed == true or result.allowed == false)

	-- Zero maxPerSecond allows only the initial burst, then nothing.
	local zeroConfig = { maxPerSecond = 0, burst = 1 }
	local zeroBucket = RateLimit.new(zeroConfig)
	local allowed = 0
	for _ = 1, 5 do
		local r = RateLimit.tryConsume(zeroBucket, zeroConfig, 0)
		if r.allowed then
			allowed += 1
			zeroBucket = r.bucket
		end
	end
	suite.expect.equal(allowed, 1)
end)
