--!strict
--[[
Signalling.luau — pure block signalling logic.

Given signal definitions and train positions, compute each signal's aspect
(red / yellow / green) based on block occupancy.

Rules:
  - A signal protects the block from its position to the next signal's position.
  - Red:   the protected block is occupied by any train.
  - Yellow: the protected block is clear, but the block immediately ahead of it is occupied.
  - Green:  all blocks ahead are clear.

A train occupies the block whose [start, end) range contains its distanceStuds.
The train's own position counts as occupancy (so signals behind a train show red for
other trains; a train at or past a signal is considered clear of it).

Pure Luau: no DataModel access, testable with lune.
--]]

export type SignalAspect = "red" | "yellow" | "green"

export type SignalDefinition = {
	signalId: string,
	distanceStuds: number,
	blockTo: string?, -- stationId of the block's end station, or nil for terminus
}

export type TrainPosition = {
	trainId: string,
	distanceStuds: number,
}

local Signalling = {}

-- Sort signals by distanceStuds ascending (stable).
local function sortSignals(signals: { SignalDefinition }): { SignalDefinition }
	local ordered = {}
	for _, s in ipairs(signals) do
		table.insert(ordered, s)
	end
	table.sort(ordered, function(a, b)
		return a.distanceStuds < b.distanceStuds
	end)
	return ordered
end

-- Return the index of the block containing distance s, given sorted signal positions.
-- Block i spans [signals[i].distanceStuds, signals[i+1].distanceStuds).
-- The last block spans [lastSignal.distanceStuds, math.huge).
-- Returns nil if s is before the first signal.
local function blockIndexFor(sorted: { SignalDefinition }, s: number): number?
	if #sorted == 0 then
		return nil
	end
	if s < sorted[1].distanceStuds then
		return nil
	end
	for i = 1, #sorted - 1 do
		if s >= sorted[i].distanceStuds and s < sorted[i + 1].distanceStuds then
			return i
		end
	end
	if s >= sorted[#sorted].distanceStuds then
		return #sorted
	end
	return nil
end

-- Compute signal aspects.
-- trains: all train positions (including self — self occupancy makes signals behind red).
-- Returns a map of signalId -> aspect.
function Signalling.computeAspects(
	signals: { SignalDefinition },
	trains: { TrainPosition }
): { [string]: SignalAspect }
	local sorted = sortSignals(signals)
	local aspects: { [string]: SignalAspect } = {}

	-- Pre-compute which block each train occupies.
	-- A train at distance s occupies block i if blockIndexFor(s) == i.
	-- Trains before the first signal occupy no block.
	local trainBlocks: { [string]: number? } = {}
	for _, train in ipairs(trains) do
		trainBlocks[train.trainId] = blockIndexFor(sorted, train.distanceStuds)
	end

	for i, signal in ipairs(sorted) do
		local protectedBlock = i -- signal i protects block i
		local nextBlock = i + 1

		-- Is the protected block occupied by any train?
		local protectedOccupied = false
		for _, train in ipairs(trains) do
			if trainBlocks[train.trainId] == protectedBlock then
				protectedOccupied = true
				break
			end
		end

		if protectedOccupied then
			aspects[signal.signalId] = "red"
		else
			-- Is the next block ahead occupied? (yellow = caution)
			local nextOccupied = false
			if nextBlock <= #sorted then
				for _, train in ipairs(trains) do
					if trainBlocks[train.trainId] == nextBlock then
						nextOccupied = true
						break
					end
				end
			end

			if nextOccupied then
				aspects[signal.signalId] = "yellow"
			else
				aspects[signal.signalId] = "green"
			end
		end
	end

	return aspects
end

-- Find the first signal at or ahead of the given distance.
-- Returns the signal definition, or nil if none ahead.
function Signalling.signalAhead(
	sorted: { SignalDefinition },
	distanceStuds: number
): SignalDefinition?
	for _, signal in ipairs(sorted) do
		if signal.distanceStuds >= distanceStuds then
			return signal
		end
	end
	return nil
end

-- Find the last signal at or behind the given distance (the signal the train just passed).
function Signalling.signalBehind(
	sorted: { SignalDefinition },
	distanceStuds: number
): SignalDefinition?
	local last: SignalDefinition? = nil
	for _, signal in ipairs(sorted) do
		if signal.distanceStuds <= distanceStuds then
			last = signal
		else
			break
		end
	end
	return last
end

return Signalling
