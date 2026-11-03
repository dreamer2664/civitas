--!strict
--[[
	PROPOSED by CODE · lumen for CODE · vector. Not merged. Lives in
	src/shared/Contracts/Proposed/ until Manager A ratifies it; then it moves to
	src/shared/Contracts/ and this folder is removed.

	Types only. XP is granted by the server from validated events (journeys, punctuality, station
	visits, exploration). The client only shows the result. It never sends an XP amount.
]]

export type XpReason = "journeyCompleted" | "onTime" | "stationVisited" | "areaExplored"

-- Server-owned. Sent on join and after each change.
export type ProgressionSnapshot = {
	level: number, -- 1 or more, integer
	xp: number, -- XP into the current level, integer, never negative
	xpToNext: number, -- XP needed to reach level + 1, integer, at least 1
	-- Ids of unlocked things. Each id is a key in the server config table, not free text.
	unlocks: { string },
}

-- One line for the progression toast. Sent as an event, not as a full snapshot.
export type XpGranted = {
	amount: number, -- integer, 1 to limits.maxXpPerGrant
	reason: XpReason,
	newLevel: number?, -- present only when this grant levelled the player up
}

-- Remote shapes. The names go into RemoteContract when the Manager merges it.
-- Progression.GetSnapshot  client -> server request, returns ProgressionSnapshot
-- Progression.XpGranted    server -> client event, carries XpGranted
-- Progression.Unlocked     server -> client event, carries { id: string } for a newly unlocked item

local limits = {
	maxXpPerGrant = 500,
	maxUnlocksListed = 200, -- the snapshot is bounded so it fits one Remote payload comfortably
	maxLevel = 99,
}

return { limits = limits }
