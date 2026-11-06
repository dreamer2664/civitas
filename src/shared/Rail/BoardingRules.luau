--!strict
-- Pure admission rule for the experimental shuttle, not a complete passenger service.
-- The server must derive every argument from its own train, platform and seat state.
local BoardingRules = {}

function BoardingRules.canBoard(
	doorsOpen: boolean,
	speedMs: number,
	atPlatform: boolean,
	seatFree: boolean
): boolean
	if
		type(speedMs) ~= "number"
		or speedMs ~= speedMs
		or speedMs == math.huge
		or speedMs == -math.huge
	then
		return false
	end
	return doorsOpen == true
		and atPlatform == true
		and seatFree == true
		and math.abs(speedMs) <= 0.01
end

-- `isPassenger` must be determined by finding this character in the server's passenger seats.
function BoardingRules.canAlight(
	doorsOpen: boolean,
	speedMs: number,
	atPlatform: boolean,
	isPassenger: boolean
): boolean
	return BoardingRules.canBoard(doorsOpen, speedMs, atPlatform, isPassenger)
end

return BoardingRules
