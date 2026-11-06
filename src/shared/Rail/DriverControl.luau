--!strict
-- Pure command boundary for a future server-owned driving service. No remotes are installed here.
-- Authority, player identity, rate limiting, and platform detection MUST be supplied by the server.
-- Reject malformed inputs rather than coercing or accepting non-finite values.
local DriverControl = {}

export type Command = {
	throttle: number,
	brake: number,
	reverser: number,
	horn: boolean?,
	doors: string?,
}

local function finiteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function DriverControl.validate(raw: any): (Command?, string?)
	if type(raw) ~= "table" then
		return nil, "command must be a table"
	end
	if not finiteNumber(raw.throttle) or raw.throttle < -1 or raw.throttle > 1 then
		return nil, "throttle must be finite and between -1 and 1"
	end
	if not finiteNumber(raw.brake) or raw.brake < 0 or raw.brake > 1 then
		return nil, "brake must be finite and between 0 and 1"
	end
	if
		not finiteNumber(raw.reverser)
		or (raw.reverser ~= -1 and raw.reverser ~= 0 and raw.reverser ~= 1)
	then
		return nil, "reverser must be -1, 0 or 1"
	end
	if raw.horn ~= nil and type(raw.horn) ~= "boolean" then
		return nil, "horn must be boolean"
	end
	if
		raw.doors ~= nil
		and raw.doors ~= "open"
		and raw.doors ~= "close"
		and raw.doors ~= "hold"
	then
		return nil, "doors must be open, close or hold"
	end
	if raw.throttle ~= 0 and raw.throttle * raw.reverser <= 0 then
		return nil, "throttle direction must match reverser"
	end
	-- Copy only the recognised fields. No client-supplied position or unknown fields propagate.
	return {
		throttle = raw.throttle,
		brake = raw.brake,
		reverser = raw.reverser,
		horn = raw.horn,
		doors = raw.doors :: string?,
	},
		nil
end

return DriverControl
