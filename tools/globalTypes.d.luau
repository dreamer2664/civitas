--[[
globalTypes.d.luau — Roblox API type definitions (MINIMAL, hand-written).

Source of truth: Roblox's API dump (https://setup.rbxcdn.com/api_dump.json or a community
mirror). Provides the Roblox types used by src/server/Services/TrainService.luau:
Instance, ModuleScript, RBXScriptSignal, RBXScriptConnection, RemoteEvent,
RunService, ReplicatedStorage, Workspace, Game.

Global VALUES (game, Workspace, require, ...) are declared in .luaurc, not here —
.d.luau files cannot declare global values.

To regenerate from the full API dump, run tools/fetch_api_types.sh and convert JSON -> .d.luau.
Commit the regenerated file here.

NOT exhaustive. Do not declare types that conflict with GeometryContract or RailContract.
--]]

export type Instance = {
	Name: string,
	Parent: Instance?,
	Archivable: boolean,
	GetService: (className: string) -> Instance,
	FindFirstChild: (self: Instance, name: string) -> Instance?,
	WaitForChild: (self: Instance, name: string) -> Instance,
	FindFirstAncestor: (self: Instance, name: string) -> Instance?,
	Destroy: (self: Instance) -> nil,
	ClearAllChildren: (self: Instance) -> nil,
	GetChildren: (self: Instance) -> { Instance },
	IsA: (self: Instance, className: string) -> boolean,
	new: (className: string) -> Instance,
}

export type ModuleScript = Instance

export type RBXScriptSignal = {
	Connect: (callback: (any) -> any) -> any,
	Wait: () -> any,
	ConnectParallel: (callback: (any) -> any) -> any,
}

export type RBXScriptConnection = {
	Connected: boolean,
	Disconnect: (self: RBXScriptConnection) -> nil,
}

export type RemoteEvent = Instance & {
	FireAllClients: (any) -> nil,
	FireClient: (Instance, any) -> nil,
	OnServerEvent: RBXScriptSignal,
	OnClientEvent: RBXScriptSignal,
}

export type RunService = Instance & {
	Heartbeat: RBXScriptSignal,
	Stepped: RBXScriptSignal,
	RenderStepped: RBXScriptSignal,
}

export type ReplicatedStorage = Instance & {
	-- Shared modules live under ReplicatedStorage.Shared (see default.project.json).
}

export type Workspace = Instance & {
	StreamingEnabled: boolean,
}

export type Game = Instance & {
	GetService: (className: string) -> Instance,
}
