--!strict
--[[
RateLimit.luau — pure token-bucket rate limiter for remote validation.

Pure Luau: no DataModel access, testable with lune without Studio.

A token bucket refills at `maxPerSecond` tokens per second, up to `burst` capacity.
Each request consumes one token; if none are available the request is rejected.
This is what protects the schedule feed (Train.State, Signal.Observe) from a
spam client starving other players.

CONFIG (from RemoteContract.luau, per player):
  Train.Control:   maxPerSecond = 30, burst = 60   (one per client tick)
  Train.State:     maxPerSecond = 30, burst = 60   (server->client, backpressure)
  Station.Board:   maxPerSecond = 2,  burst = 4
  Signal.Observe:  maxPerSecond = 10, burst = 20   (server->client, backpressure)
--]]

export type RateLimitConfig = {
	maxPerSecond: number,
	burst: number,
}

export type Bucket = {
	tokens: number,
	lastRefill: number,
}

local RateLimit = {}

function RateLimit.new(config: RateLimitConfig): Bucket
	return {
		tokens = config.burst,
		lastRefill = 0,
	}
end

-- Refill tokens based on elapsed time, capped at burst.
local function refill(bucket: Bucket, config: RateLimitConfig, now: number): Bucket
	local elapsed = now - bucket.lastRefill
	if elapsed <= 0 then
		return bucket
	end
	local newTokens = bucket.tokens + elapsed * config.maxPerSecond
	if newTokens > config.burst then
		newTokens = config.burst
	end
	return {
		tokens = newTokens,
		lastRefill = now,
	}
end

-- Try to consume one token. Returns { allowed, bucket }.
-- If allowed, the bucket has been updated with one fewer token.
function RateLimit.tryConsume(
	bucket: Bucket,
	config: RateLimitConfig,
	now: number
): { allowed: boolean, bucket: Bucket }
	local refilled = refill(bucket, config, now)
	if refilled.tokens >= 1 then
		return {
			allowed = true,
			bucket = {
				tokens = refilled.tokens - 1,
				lastRefill = refilled.lastRefill,
			},
		}
	end
	return { allowed = false, bucket = refilled }
end

-- Check whether a request would be allowed without consuming a token.
function RateLimit.check(bucket: Bucket, config: RateLimitConfig, now: number): boolean
	local refilled = refill(bucket, config, now)
	return refilled.tokens >= 1
end

-- Maximum sustainable requests per second (for documentation/sanity).
function RateLimit.sustainableRate(config: RateLimitConfig): number
	return config.maxPerSecond
end

return RateLimit
