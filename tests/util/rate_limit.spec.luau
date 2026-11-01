--!strict
-- Unit tests for src/shared/Util/RateLimit.luau — proves a spam client cannot
-- starve the schedule feed (Train.State / Signal.Observe) because each client
-- has an independent token bucket that rejects excess requests.

local suite = require("../support/suite")
local expect = suite.expect
local RateLimit = require("../../src/shared/Util/RateLimit")

local CONTROL_CONFIG = { maxPerSecond = 30, burst = 60 } -- Train.Control / Train.State
local OBSERVE_CONFIG = { maxPerSecond = 10, burst = 20 } -- Signal.Observe
local BOARD_CONFIG = { maxPerSecond = 2, burst = 4 } -- Station.Board

suite.test("RateLimit: burst allows a short burst then rejects spam", function()
	local config = CONTROL_CONFIG
	local bucket = RateLimit.new(config)
	local now = 0

	-- Burst of 60 should all be allowed.
	local allowed = 0
	for _ = 1, config.burst do
		local result = RateLimit.tryConsume(bucket, config, now)
		if result.allowed then
			allowed += 1
			bucket = result.bucket
		end
	end
	expect.equal(allowed, config.burst)

	-- The next request should be rejected (bucket empty).
	local result = RateLimit.tryConsume(bucket, config, now)
	expect.equal(result.allowed, false)
end)

suite.test(
	"RateLimit: spam client cannot starve the schedule feed — per-client buckets are independent",
	function()
		local config = OBSERVE_CONFIG -- Signal.Observe: 10/s, burst 20

		-- Spam client: 100 requests instantly.
		local spamBucket = RateLimit.new(config)
		local spamAllowed = 0
		for _ = 1, 100 do
			local result = RateLimit.tryConsume(spamBucket, config, 0)
			if result.allowed then
				spamAllowed += 1
				spamBucket = result.bucket
			end
		end
		expect.ok(spamAllowed <= config.burst) -- at most the burst

		-- A different (well-behaved) client still gets its own full burst.
		local goodBucket = RateLimit.new(config)
		local goodAllowed = 0
		for _ = 1, config.burst do
			local result = RateLimit.tryConsume(goodBucket, config, 0)
			if result.allowed then
				goodAllowed += 1
				goodBucket = result.bucket
			end
		end
		expect.equal(goodAllowed, config.burst) -- unaffected by spam client
	end
)

-- Helper: refill without consuming.
local function refillHelper(
	bucket: { tokens: number, lastRefill: number },
	config: { maxPerSecond: number, burst: number },
	now: number
): { tokens: number, lastRefill: number }
	local elapsed = now - bucket.lastRefill
	if elapsed <= 0 then
		return bucket
	end
	local newTokens = bucket.tokens + elapsed * config.maxPerSecond
	if newTokens > config.burst then
		newTokens = config.burst
	end
	return { tokens = newTokens, lastRefill = now }
end

suite.test("RateLimit: tokens refill over time, so the feed recovers", function()
	local config = BOARD_CONFIG -- 2/s, burst 4
	local bucket = RateLimit.new(config)
	local now = 0

	-- Drain the bucket.
	for _ = 1, config.burst do
		local result = RateLimit.tryConsume(bucket, config, now)
		if result.allowed then
			bucket = result.bucket
		end
	end
	expect.equal(RateLimit.check(bucket, config, now), false)

	-- Wait 1 second: 2 tokens refill.
	bucket = refillHelper(bucket, config, 1)
	expect.ok(RateLimit.check(bucket, config, 1))

	-- Consume those 2, then wait another second.
	local r1 = RateLimit.tryConsume(bucket, config, 1)
	expect.ok(r1.allowed)
	bucket = r1.bucket
	local r2 = RateLimit.tryConsume(bucket, config, 1)
	expect.ok(r2.allowed)
	bucket = r2.bucket
	expect.equal(RateLimit.check(bucket, config, 1), false)

	-- After another second, back to 2 tokens.
	expect.ok(RateLimit.check(bucket, config, 2))
end)

suite.test("RateLimit: hostile inputs are handled safely", function()
	local config = CONTROL_CONFIG
	local bucket = RateLimit.new(config)

	-- now = 0 is fine.
	local r = RateLimit.tryConsume(bucket, config, 0)
	expect.ok(type(r.allowed) == "boolean")

	-- now < lastRefill (clock skew) is treated as no refill.
	bucket = { tokens = 0, lastRefill = 100 }
	r = RateLimit.tryConsume(bucket, config, 0)
	expect.equal(r.allowed, false)

	-- Huge now value doesn't overflow or misbehave.
	r = RateLimit.tryConsume(bucket, config, 1e12)
	expect.ok(type(r.allowed) == "boolean")
end)

suite.test("RateLimit: zero burst rejects everything", function()
	local config = { maxPerSecond = 30, burst = 0 }
	local bucket = RateLimit.new(config)
	local r = RateLimit.tryConsume(bucket, config, 0)
	expect.equal(r.allowed, false)
end)

suite.test("RateLimit: maxPerSecond zero allows only the initial burst", function()
	local config = { maxPerSecond = 0, burst = 5 }
	local bucket = RateLimit.new(config)
	local allowed = 0
	for _ = 1, 5 do
		local r = RateLimit.tryConsume(bucket, config, 0)
		if r.allowed then
			allowed += 1
			bucket = r.bucket
		end
	end
	expect.equal(allowed, 5)
	-- No refill, so everything after is rejected.
	r = RateLimit.tryConsume(bucket, config, 100)
	expect.equal(r.allowed, false)
end)
