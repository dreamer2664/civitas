--!strict
-- Pure helpers for a server-owned driver's remote. The server supplies identity and time;
-- clients never choose the character or occupant used by `authorized`.
local ControlGate = {}

export type Bucket = { tokens: number, time: number }
local RATE = 10
local CAPACITY = 20

function ControlGate.authorized(character: any, occupantCharacter: any): boolean
	return character ~= nil and occupantCharacter ~= nil and character == occupantCharacter
end

-- Per-player token bucket. Rejected requests do not spend a token. Clock rollback and non-finite
-- time fail closed; the service must remove a player's bucket when that player leaves.
function ControlGate.consume(bucket: Bucket?, now: number): (Bucket?, boolean)
	if type(now) ~= "number" or now ~= now or now == math.huge or now == -math.huge then
		return bucket, false
	end
	if bucket == nil then
		return { tokens = CAPACITY - 1, time = now }, true
	end
	if now < bucket.time then
		return bucket, false
	end
	local tokens = math.min(CAPACITY, bucket.tokens + (now - bucket.time) * RATE)
	if tokens < 1 then
		return { tokens = tokens, time = now }, false
	end
	return { tokens = tokens - 1, time = now }, true
end

return ControlGate
