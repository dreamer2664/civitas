--!strict
--[[
	PROPOSED by CODE · lumen for CODE · vector. Not merged. Lives in
	src/shared/Contracts/Proposed/ until Manager A ratifies it; then it moves to
	src/shared/Contracts/ and this folder is removed.

	Types only, no implementation. The server owns every balance and every decision; the client
	reads snapshots and sends requests it may be refused. Money is always integer minor units so the
	client never does currency arithmetic on floats.
]]

-- Whole minor units, never negative. 1250 is 12.50 in the currency named alongside it.
export type Minor = number

export type Balance = {
	minor: Minor,
	-- ISO 4217 code. Open question for the Manager: the place's currency, not a per-player choice.
	currency: string,
}

-- Server-owned snapshot, sent on join and after each change. The client never edits it locally.
export type EconomySnapshot = {
	balance: Balance,
	-- Server clock, seconds since the Unix epoch, for "updated 2 min ago" text only.
	updatedAt: number,
}

-- A price the server has promised for a short window. The client shows it and asks to buy it.
export type FareQuote = {
	quoteId: string, -- opaque, server-generated, at most 64 characters
	fromStation: string, -- station code, 4 characters at most, as in docs/rail/NETWORK.md
	toStation: string,
	price: Minor,
	currency: string,
	expiresAt: number, -- server clock; the server refuses a purchase after this time
}

export type PurchaseDenied =
	"insufficientFunds"
	| "quoteExpired"
	| "unknownQuote" -- never issued, or already spent
	| "rateLimited"

export type PurchaseResult =
	{ ok: true, balanceAfter: Balance }
	| { ok: false, reason: PurchaseDenied }

-- Remote shapes. The names go into RemoteContract when the Manager merges it.
-- Economy.GetSnapshot    client -> server request, returns EconomySnapshot
-- Economy.BalanceChanged server -> client event, carries EconomySnapshot
-- Economy.RequestQuote   client -> server request, carries { fromStation, toStation }
--                           returns FareQuote | PurchaseDenied
-- Economy.Purchase       client -> server request, carries { quoteId }, returns PurchaseResult

-- Limits the server enforces. The client mirrors them only to disable buttons early.
local limits = {
	maxQuoteIdLength = 64,
	maxStationCodeLength = 4,
	maxMinor = 100_000_000, -- 1,000,000.00 in the place currency; far above any real fare
	quoteWindowSeconds = 60,
	purchasesPerMinute = 20, -- rate limit per player, per RemoteContract
}

return { limits = limits }
