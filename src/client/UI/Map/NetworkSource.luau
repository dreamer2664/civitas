--!strict
--[[
	Where the map's network data comes from. The map asks a source for a table and validates it
	(MapModel.validate); it never reads a file, a remote or a Workspace instance itself.

	Sources in use or planned:
	- stub: UI/Map/StubNetwork.luau, synthetic, for building the map before the real network exists.
	- module: a generated Luau table from docs/rail/NETWORK.md. Roblox cannot read a Markdown file
	  at runtime, so a generator must produce the module. That generator is not built yet; see the
	  Phase 1 report, "What is not done".

	Pure: no requires, so lune can test every source. A caller builds the source and passes it in.
]]

local NetworkSource = {}

-- `load` returns the data, or nil and a reason. A reason is for the developer log, not the player.
export type Source = {
	name: string,
	load: () -> (any?, string?),
}

-- A source that returns the given table as is. Validation happens in the map, not here.
function NetworkSource.fromTable(name: string, data: any): Source
	return {
		name = name,
		load = function()
			return data, nil
		end,
	}
end

-- A source that always fails with a reason. Used to test the "unavailable" screen.
function NetworkSource.unavailable(name: string, reason: string): Source
	return {
		name = name,
		load = function()
			return nil, reason
		end,
	}
end

return NetworkSource
