--!strict
--[[
	Network map view: draws a validated MapModel as Frames, one per segment, one marker and label
	per station, and one badge per line. Everything it draws comes from the data table. It never
	reads Workspace, so streamed-out stations cannot break it (docs/ARCHITECTURE.md rule 4).

	Lifecycle:
	- `new` validates the data and builds the view. Building is chunked: the work is split across
	  frames so opening the map cannot stall one frame (docs/RESOURCES.md, 16.67 ms budget).
	- Positions are recomputed only when the canvas size or the user's zoom or pan changes.
	- `destroy` disconnects everything. Closing the map must not leave listeners behind.

	Not verified here (no Studio): the sign convention of Frame.Rotation on screen (projection
	tests assume clockwise-positive), label overlap at low zoom, and touch drag feel. These are
	listed in docs/ui/UI-SPEC.md §13 for the Manager's device pass.
]]

local UserInputService = game:GetService("UserInputService")

local MapModel = require(script.Parent.MapModel)
local MapProjection = require(script.Parent.MapProjection)
local NetworkSource = require(script.Parent.NetworkSource)
local Label = require(script.Parent.Parent.Components.Label)
local Theme = require(script.Parent.Parent.Theme)
local Style = require(script.Parent.Parent.Style)

local MapView = {}

export type Placeable = { frame: GuiObject, place: (MapProjection.Transform) -> () }
export type View = {
	root: Frame,
	canvas: Frame,
	data: MapModel.MapData,
	bounds: MapModel.Bounds,
	items: { Placeable },
	transform: MapProjection.Transform?,
	userZoomed: boolean,
	connections: { RBXScriptConnection },
	destroyed: boolean,
}

local PADDING = 24
local MIN_SCALE_FACTOR = 0.5 -- zoom-out limit relative to the fitted scale
local MAX_SCALE_FACTOR = 6
local BUILD_BUDGET_S = 0.004 -- yield to the next frame after roughly a quarter of a frame
local SEGMENT_THICKNESS = 4
local STATION_SIZE = 12
local INTERCHANGE_SIZE = 18

local ALLOWED_COLOURS: { [string]: boolean } = {}
for name in Theme.lineColours do
	ALLOWED_COLOURS[name] = true
end

local function placeMarker(frame: GuiObject, x: number, y: number)
	frame.Position = UDim2.fromOffset(x, y)
end

-- Creates one placeable per drawable piece. Returns the list, so layout code can iterate it.
local function buildSegment(canvas: Frame, segment: MapModel.Segment): Placeable
	local frame = Instance.new("Frame")
	frame.Name = `Segment_{segment.lineId}`
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Style.hex(Theme.lineColours[segment.colour])
	-- Underground track is drawn at half strength. This is the only visual distinction between
	-- kinds in Phase 1, so it is also named in the spec's legend.
	frame.BackgroundTransparency = if segment.kind == "underground" then 0.5 else 0
	frame.Parent = canvas
	return {
		frame = frame,
		place = function(t: MapProjection.Transform)
			local d = MapProjection.drawSegment(t, segment)
			frame.Position = UDim2.fromOffset(d.cx, d.cy)
			frame.Size = UDim2.fromOffset(d.length + 1, SEGMENT_THICKNESS)
			frame.Rotation = d.angleDeg
		end,
	}
end

local function buildStation(canvas: Frame, station: MapModel.Station): { Placeable }
	local size = if station.interchange then INTERCHANGE_SIZE else STATION_SIZE
	local marker = Instance.new("Frame")
	marker.Name = `Station_{station.id}`
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(size, size)
	marker.BackgroundColor3 = Style.color("signText")
	marker.BorderSizePixel = 0
	marker.Parent = canvas

	local ring = Instance.new("UIStroke")
	ring.Color = Style.color("ink")
	ring.Thickness = 2
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent = marker

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = marker

	local label = Instance.new("TextLabel")
	label.Name = `Label_{station.id}`
	label.BackgroundTransparency = 1
	label.Text = station.name
	label.TextColor3 = Style.color("text")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromOffset(0, 16)
	label.Parent = canvas
	Style.applyType(label, "label")

	return {
		{
			frame = marker,
			place = function(t: MapProjection.Transform)
				local x, y = MapProjection.toScreen(t, station.x, station.z)
				placeMarker(marker, x, y)
			end,
		},
		{
			frame = label,
			place = function(t: MapProjection.Transform)
				local x, y = MapProjection.toScreen(t, station.x, station.z)
				label.Position = UDim2.fromOffset(x + size / 2 + 4, y - 8)
			end,
		},
	}
end

-- A line badge sits beside the first stop of the line, so the line can be identified without
-- relying on colour alone.
local function buildBadge(canvas: Frame, line: MapModel.Line, station: MapModel.Station?): Placeable
	local badge = Instance.new("TextLabel")
	badge.Name = `Badge_{line.id}`
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Size = UDim2.fromOffset(22, 22)
	badge.BackgroundColor3 = Style.hex(Theme.lineColours[line.colour])
	badge.BorderSizePixel = 0
	badge.Text = line.code
	badge.TextColor3 = Style.color("ink")
	badge.Parent = canvas
	Style.applyType(badge, "label")
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = badge

	return {
		frame = badge,
		place = function(t: MapProjection.Transform)
			if station == nil then
				return
			end
			local x, y = MapProjection.toScreen(t, station.x, station.z)
			badge.Position = UDim2.fromOffset(x - 16, y - 16)
		end,
	}
end

local function currentTransform(view: View): MapProjection.Transform
	local w = view.canvas.AbsoluteSize.X
	local h = view.canvas.AbsoluteSize.Y
	return MapProjection.fit(view.bounds, math.max(w, 1), math.max(h, 1), PADDING)
end

-- Repositions every item for `t`. Cheap enough to call on every pan event: it is one arithmetic
-- pass over at most `maxElements` items, with no instance creation.
local function applyTransform(view: View, t: MapProjection.Transform)
	view.transform = t
	for _, item in view.items do
		item.place(t)
	end
end

function MapView.relayout(view: View)
	if view.destroyed or #view.items == 0 then
		return
	end
	local fitted = currentTransform(view)
	if view.userZoomed and view.transform then
		-- Keep the user's zoom ratio when the window is resized, rather than snapping back.
		local ratio = view.transform.scale / fitted.scale
		local w = view.canvas.AbsoluteSize.X
		local h = view.canvas.AbsoluteSize.Y
		local rescaled = MapProjection.zoomAt(fitted, w / 2, h / 2, ratio, 0, math.huge)
		applyTransform(view, MapProjection.clampToView(rescaled, view.bounds, w, h))
	else
		applyTransform(view, fitted)
	end
end

function MapView.zoom(view: View, factor: number)
	if view.destroyed then
		return
	end
	local fitted = currentTransform(view)
	local current = view.transform or fitted
	local w = view.canvas.AbsoluteSize.X
	local h = view.canvas.AbsoluteSize.Y
	local zoomed = MapProjection.zoomAt(
		current,
		w / 2,
		h / 2,
		factor,
		fitted.scale * MIN_SCALE_FACTOR,
		fitted.scale * MAX_SCALE_FACTOR
	)
	view.userZoomed = true
	applyTransform(view, MapProjection.clampToView(zoomed, view.bounds, w, h))
end

function MapView.pan(view: View, dx: number, dy: number)
	if view.destroyed or view.transform == nil then
		return
	end
	local w = view.canvas.AbsoluteSize.X
	local h = view.canvas.AbsoluteSize.Y
	local panned = MapProjection.panBy(view.transform, dx, dy)
	view.userZoomed = true
	applyTransform(view, MapProjection.clampToView(panned, view.bounds, w, h))
end

-- Builds the map under `parent`. Errors on invalid data, listing every reason, so a bad network
-- file is a clear failure in tests and never a half-drawn map.
function MapView.new(parent: GuiObject, source: NetworkSource.Source): View
	local raw, reason = source.load()
	if raw == nil then
		warn(`MapView: source '{source.name}' has no data: {reason or "no reason given"}`)
		return MapView.unavailable(parent)
	end
	local ok, errors = MapModel.validate(raw, ALLOWED_COLOURS)
	if not ok then
		warn(`MapView: source '{source.name}' rejected: {table.concat(errors, "; ")}`)
		return MapView.unavailable(parent)
	end
	local data: MapModel.MapData = raw

	local root = Instance.new("Frame")
	root.Name = "NetworkMap"
	root.BackgroundColor3 = Style.color("surface")
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = true
	root.Parent = parent

	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.BackgroundTransparency = 1
	canvas.Size = UDim2.fromScale(1, 1)
	canvas.Parent = root

	local view: View = {
		root = root,
		canvas = canvas,
		data = data,
		bounds = MapModel.bounds(data),
		items = {},
		transform = nil,
		userZoomed = false,
		connections = {},
		destroyed = false,
	}

	-- Lines first, so stations draw on top of track.
	local stationById: { [string]: MapModel.Station } = {}
	for _, station in data.stations do
		stationById[station.id] = station
	end
	local queued: { () -> { Placeable } } = {}
	for _, line in data.lines do
		for _, section in line.sections do
			for i = 1, #section.points - 1 do
				local a = section.points[i]
				local b = section.points[i + 1]
				local segment: MapModel.Segment = {
					lineId = line.id,
					colour = line.colour,
					kind = section.kind,
					x1 = a.x,
					z1 = a.z,
					x2 = b.x,
					z2 = b.z,
				}
				table.insert(queued, function()
					return { buildSegment(canvas, segment) }
				end)
			end
		end
		local firstStop = if #line.stops > 0 then stationById[line.stops[1]] else nil
		table.insert(queued, function()
			return { buildBadge(canvas, line, firstStop) }
		end)
	end
	for _, station in data.stations do
		table.insert(queued, function()
			return buildStation(canvas, station)
		end)
	end

	-- Build in chunks. The task is cancelled by `destroy` setting view.destroyed.
	task.spawn(function()
		local started = os.clock()
		for _, make in queued do
			if view.destroyed then
				return
			end
			for _, item in make() do
				table.insert(view.items, item)
			end
			if os.clock() - started > BUILD_BUDGET_S then
				task.wait()
				started = os.clock()
			end
		end
		MapView.relayout(view)
	end)

	table.insert(
		view.connections,
		canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			MapView.relayout(view)
		end)
	)

	-- Drag to pan with mouse or touch. Pinch is not implemented in Phase 1 (see the spec).
	local dragging = false
	local lastX, lastY = 0, 0
	table.insert(
		view.connections,
		canvas.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				lastX = input.Position.X
				lastY = input.Position.Y
			end
		end)
	)
	table.insert(
		view.connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if not dragging then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				MapView.pan(view, input.Position.X - lastX, input.Position.Y - lastY)
				lastX = input.Position.X
				lastY = input.Position.Y
			end
		end)
	)
	table.insert(
		view.connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)
	)

	return view
end

-- The screen when no valid network exists (UI-SPEC §9.6). One sentence for the player; the reason
-- went to the developer log in `new`. The view is empty but fully destroyable, so the caller's
-- close path does not need a special case.
function MapView.unavailable(parent: GuiObject): View
	local root = Instance.new("Frame")
	root.Name = "NetworkMap"
	root.BackgroundColor3 = Style.color("surface")
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = true
	root.Parent = parent

	local message = Label.new({
		name = "Unavailable",
		text = "Network map unavailable.",
		type = "heading",
		color = "text",
		align = "center",
	})
	message.AnchorPoint = Vector2.new(0.5, 0.5)
	message.Position = UDim2.fromScale(0.5, 0.5)
	message.Size = UDim2.fromScale(0.8, 0.2)
	message.Parent = root

	local empty: MapModel.MapData = { stations = {}, lines = {} }
	local noBounds: MapModel.Bounds = { minX = 0, minZ = 0, maxX = 0, maxZ = 0 }
	return {
		root = root,
		canvas = root,
		data = empty,
		bounds = noBounds,
		items = {},
		transform = nil,
		userZoomed = false,
		connections = {},
		destroyed = false,
	}
end

function MapView.destroy(view: View)
	if view.destroyed then
		return
	end
	view.destroyed = true
	for _, connection in view.connections do
		connection:Disconnect()
	end
	table.clear(view.connections)
	view.root:Destroy()
	table.clear(view.items)
end

return MapView
