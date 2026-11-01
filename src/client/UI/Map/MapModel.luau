--!strict
--[[
	Network map data: validation, bounds and segment extraction. Pure.

	The data is the network from docs/rail/NETWORK.md (CODE · vector), not anything read from
	Workspace. Under instance streaming a station model may not exist on the client, so the map is
	built entirely from this table. Everything arriving here is untrusted until `validate` passes:
	it is the boundary between the network data and the drawing code.

	Coordinates are world X and Z in studs, in the frame of docs/rail/NETWORK.md §1: X east, Z south.
	The map draws north at the top, so -Z is up the screen. Until BLENDER · atlas's WORLD-MAP.md
	exists, that frame is vector's provisional one; UI-SPEC §8 says so.
]]

local MapModel = {}

export type Point = { x: number, z: number }
export type SectionKind = "surface" | "elevated" | "underground"
export type Section = { kind: SectionKind, points: { Point } }
export type Line = {
	id: string,
	code: string,
	colour: string,
	stops: { string },
	sections: { Section },
}
export type Station = { id: string, name: string, x: number, z: number, interchange: boolean }
export type MapData = { stations: { Station }, lines: { Line } }
export type Segment = {
	lineId: string,
	colour: string,
	kind: SectionKind,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
}
export type Bounds = { minX: number, minZ: number, maxX: number, maxZ: number }

-- Hard limits that keep the map inside its element budget (UI-SPEC §9). Values above these are
-- rejected, not truncated, so an oversized network fails loudly in tests.
MapModel.limits = {
	maxLines = 8,
	maxStations = 32,
	maxSectionsPerLine = 12,
	maxPointsPerSection = 64,
	maxNameLength = 40,
	maxCodeLength = 4,
	maxElements = 300,
}

local SECTION_KINDS: { [string]: boolean } = { surface = true, elevated = true, underground = true }
local COORD_LIMIT = 100000

local function isFinite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- Returns (true, {}) when valid, or (false, reasons). Every reason is a sentence a data author can
-- act on. `allowedColours` is the set of colour tokens the theme defines.
function MapModel.validate(data: any, allowedColours: { [string]: boolean }): (boolean, { string })
	local errors: { string } = {}
	local function fail(message: string)
		table.insert(errors, message)
	end

	if type(data) ~= "table" then
		return false, { "map data must be a table with 'stations' and 'lines'" }
	end

	-- Stations.
	local stationIds: { [string]: boolean } = {}
	local stations = data.stations
	if type(stations) ~= "table" or #stations == 0 then
		fail("'stations' must be a non-empty array")
	elseif #stations > MapModel.limits.maxStations then
		fail(`{#stations} stations exceeds the limit of {MapModel.limits.maxStations}`)
	else
		for index, station in stations do
			local where = `stations[{index}]`
			if type(station) ~= "table" then
				fail(`{where} must be a table`)
				continue
			end
			if type(station.id) ~= "string" or station.id == "" then
				fail(`{where}.id must be a non-empty string`)
			elseif stationIds[station.id] then
				fail(`station id '{station.id}' is used more than once`)
			else
				stationIds[station.id] = true
			end
			if type(station.name) ~= "string" or #station.name == 0 then
				fail(`{where}.name must be a non-empty string`)
			elseif #station.name > MapModel.limits.maxNameLength then
				fail(`{where}.name is longer than {MapModel.limits.maxNameLength} characters`)
			end
			if not isFinite(station.x) or not isFinite(station.z) then
				fail(`{where} needs finite numeric x and z`)
			elseif math.abs(station.x) > COORD_LIMIT or math.abs(station.z) > COORD_LIMIT then
				fail(`{where} lies outside the ±{COORD_LIMIT} stud coordinate range`)
			end
			if type(station.interchange) ~= "boolean" then
				fail(`{where}.interchange must be true or false`)
			end
		end
	end

	-- Lines.
	local lines = data.lines
	local lineIds: { [string]: boolean } = {}
	if type(lines) ~= "table" or #lines == 0 then
		fail("'lines' must be a non-empty array")
	elseif #lines > MapModel.limits.maxLines then
		fail(`{#lines} lines exceeds the limit of {MapModel.limits.maxLines}`)
	else
		for index, line in lines do
			local where = `lines[{index}]`
			if type(line) ~= "table" then
				fail(`{where} must be a table`)
				continue
			end
			if type(line.id) ~= "string" or line.id == "" or lineIds[line.id] then
				fail(`{where}.id must be a unique non-empty string`)
			else
				lineIds[line.id] = true
			end
			if
				type(line.code) ~= "string"
				or #line.code == 0
				or #line.code > MapModel.limits.maxCodeLength
			then
				fail(`{where}.code must be 1 to {MapModel.limits.maxCodeLength} characters`)
			end
			if type(line.colour) ~= "string" or not allowedColours[line.colour] then
				fail(`{where}.colour '{tostring(line.colour)}' is not a colour token in Theme`)
			end
			if type(line.stops) ~= "table" then
				fail(`{where}.stops must be an array of station ids`)
			else
				for _, stopId in line.stops do
					if not stationIds[stopId] then
						fail(`{where} stops at unknown station '{tostring(stopId)}'`)
					end
				end
			end
			if type(line.sections) ~= "table" or #line.sections == 0 then
				fail(`{where}.sections must be a non-empty array`)
				continue
			end
			if #line.sections > MapModel.limits.maxSectionsPerLine then
				fail(`{where} has more than {MapModel.limits.maxSectionsPerLine} sections`)
			end
			for sIndex, section in line.sections do
				local sWhere = `{where}.sections[{sIndex}]`
				if type(section) ~= "table" or not SECTION_KINDS[section.kind] then
					fail(`{sWhere}.kind must be surface, elevated or underground`)
					continue
				end
				if type(section.points) ~= "table" or #section.points < 2 then
					fail(`{sWhere} needs at least two points`)
					continue
				end
				if #section.points > MapModel.limits.maxPointsPerSection then
					fail(`{sWhere} has more than {MapModel.limits.maxPointsPerSection} points`)
				end
				for pIndex, point in section.points do
					if type(point) ~= "table" or not isFinite(point.x) or not isFinite(point.z) then
						fail(`{sWhere}.points[{pIndex}] needs finite numeric x and z`)
					end
				end
			end
		end
	end

	-- Budget: the map must stay inside its element limit. Checked here so it fails in tests.
	if #errors == 0 then
		local count = MapModel.elementCount(data)
		if count > MapModel.limits.maxElements then
			fail(`map needs {count} elements, the budget is {MapModel.limits.maxElements}`)
		end
	end

	return #errors == 0, errors
end

-- Every drawn piece of a valid map: one Frame per segment, one marker and one label per station,
-- and one badge per line. The view creates exactly this many GuiObjects.
function MapModel.elementCount(data: MapData): number
	local count = 0
	for _, line in data.lines do
		count += 1 -- badge
		for _, section in line.sections do
			count += #section.points - 1
		end
	end
	count += #data.stations * 2 -- marker + label
	return count
end

-- Each section is split into straight segments: the drawable unit in the view.
function MapModel.segments(data: MapData): { Segment }
	local out: { Segment } = {}
	for _, line in data.lines do
		for _, section in line.sections do
			for i = 1, #section.points - 1 do
				local a = section.points[i]
				local b = section.points[i + 1]
				table.insert(out, {
					lineId = line.id,
					colour = line.colour,
					kind = section.kind,
					x1 = a.x,
					z1 = a.z,
					x2 = b.x,
					z2 = b.z,
				})
			end
		end
	end
	return out
end

-- Bounding box of stations and every line point, so the whole network fits on screen.
function MapModel.bounds(data: MapData): Bounds
	local minX, minZ = math.huge, math.huge
	local maxX, maxZ = -math.huge, -math.huge
	local function include(x: number, z: number)
		minX = math.min(minX, x)
		minZ = math.min(minZ, z)
		maxX = math.max(maxX, x)
		maxZ = math.max(maxZ, z)
	end
	for _, station in data.stations do
		include(station.x, station.z)
	end
	for _, line in data.lines do
		for _, section in line.sections do
			for _, point in section.points do
				include(point.x, point.z)
			end
		end
	end
	return { minX = minX, minZ = minZ, maxX = maxX, maxZ = maxZ }
end

return MapModel
