--!strict
--[[
	Where the map's network data comes from. The map asks a source for a table and validates it
	(MapModel.validate); it never reads a file, a remote or a Workspace instance itself.

	Sources in use or planned:
	- module: UI/Map/NetworkData.luau, generated from docs/rail/NETWORK.md by tools/gen_network.py.
	  This is what the client ships. Roblox cannot read a Markdown file at runtime, so it is generated.
	- stub: tests/fixtures/network-stub.luau, synthetic. Used only to test the source boundary.

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
