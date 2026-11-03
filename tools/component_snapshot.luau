--!strict
--[[
	Records which design tokens each UI component reads, and fails the build when:
	  - a component reads a Theme token that Theme does not define (the component would render nil),
	  - a component names a colour or font literally instead of going through Theme or Style,
	  - the recorded snapshot no longer matches the source (a token-use change must be reviewed).

	Lune cannot create Roblox instances, so this is the snapshot that can run here: it is a record
	of token use, not of pixels. Components that pick a token from a variable (for example
	`Style.color(look.fill)`) are counted as "dynamic" and cannot be checked statically; the count
	is part of the snapshot so a new dynamic reference shows up in review.

	Usage (from the repo root):
	  lune run tools/component_snapshot.luau           -- check sources, then compare snapshot
	  lune run tools/component_snapshot.luau -- --update -- rewrite the snapshot file
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Theme = require("../src/client/UI/Theme")

local SNAPSHOT = "tests/snapshots/components.snap"

-- Lune passes arguments differently with and without a "--" separator, so look for the flag anywhere.
local function hasFlag(flag: string): boolean
	for _, arg in process.args do
		if arg == flag then
			return true
		end
	end
	return false
end
local DIRS = { "src/client/UI/Components", "src/client/UI/Hud" }

-- Theme and Style are the only places allowed to name colours, fonts or hex values.
local EXEMPT: { [string]: boolean } = {
	["Theme.luau"] = true,
	["Style.luau"] = true,
}

local failures = 0
local function fail(message: string)
	failures += 1
	print(`component_snapshot: FAIL {message}`)
end

-- Walk a dotted token path through Theme. Returns true if every segment exists.
local function tokenExists(path: string): boolean
	local node: any = Theme
	for segment in string.gmatch(path, "[^%.]+") do
		if type(node) ~= "table" then
			return false
		end
		node = node[segment]
		if node == nil then
			return false
		end
	end
	return true
end

-- Strip Luau comments so tokens named in prose do not count as references.
local function code(source: string): string
	local out = {}
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		local stripped = string.gsub(line, "%-%-.*$", "")
		table.insert(out, stripped)
	end
	return table.concat(out, "\n")
end

local function sortedKeys(set: { [string]: boolean }): { string }
	local list = {}
	for key in set do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

local snapshot: { string } = {}

local files: { string } = {}
for _, dir in DIRS do
	for _, name in fs.readDir(dir) do
		if string.sub(name, -5) == ".luau" and not EXEMPT[name] then
			table.insert(files, `{dir}/{name}`)
		end
	end
end
table.sort(files)

for _, path in files do
	local source = code(fs.readFile(path))
	local tokens: { [string]: boolean } = {}
	local colours: { [string]: boolean } = {}
	local types: { [string]: boolean } = {}
	local dynamicColour = 0

	-- Theme token references, e.g. Theme.size.touchMin or Theme.space.s3.
	for token in string.gmatch(source, "Theme%.([%a][%w_%.]*)") do
		local clean = string.gsub(token, "%.+$", "")
		if tokenExists(clean) then
			tokens[clean] = true
		else
			fail(`{path} reads Theme.{clean}, which Theme does not define`)
		end
	end

	-- Literal colour names passed to Style.color("name"); each must be a palette key.
	for name in string.gmatch(source, 'Style%.color%("([%w]+)"%)') do
		colours[name] = true
		if Theme.palette[name] == nil then
			fail(`{path} asks Style.color for "{name}", which is not a palette token`)
		end
	end
	-- Colour references through a variable or expression cannot be resolved statically.
	for _ in string.gmatch(source, 'Style%.color%([^"%)]') do
		dynamicColour += 1
	end

	-- Literal type styles passed to Style.applyType(target, "name").
	for name in string.gmatch(source, 'Style%.applyType%([%w_%.]+, "([%w]+)"%)') do
		types[name] = true
		if Theme.type[name] == nil then
			fail(`{path} applies type style "{name}", which Theme.type does not define`)
		end
	end

	-- Forbidden: literal colours and fonts anywhere outside Theme and Style.
	if string.find(source, "Color3%.") then
		fail(`{path} builds a Color3 directly; use Style.color`)
	end
	local hexLiteral = string.find(source, "#%x%x%x%x%x%x") ~= nil
	for quoted in string.gmatch(source, '"([^"\n]*)"') do
		if string.match(quoted, "^%x%x%x%x%x%x$") ~= nil then
			hexLiteral = true
		end
	end
	if hexLiteral then
		fail(`{path} contains a hex colour literal; move it to Theme.palette`)
	end
	if string.find(source, "Enum%.Font%.") then
		fail(`{path} names Enum.Font directly; use Style.font or Style.applyType`)
	end

	table.insert(snapshot, path)
	table.insert(snapshot, `  tokens: {table.concat(sortedKeys(tokens), ", ")}`)
	table.insert(snapshot, `  colours: {table.concat(sortedKeys(colours), ", ")}`)
	table.insert(snapshot, `  dynamic colours: {dynamicColour}`)
	table.insert(snapshot, `  type styles: {table.concat(sortedKeys(types), ", ")}`)
end

local text = table.concat(snapshot, "\n") .. "\n"

if failures > 0 then
	print(
		`component_snapshot: {failures} problem(s); fix the components before the snapshot is compared`
	)
	process.exit(1)
end

if hasFlag("--update") then
	fs.writeFile(SNAPSHOT, text)
	print(`component_snapshot: wrote {SNAPSHOT} ({#files} components)`)
elseif not fs.isFile(SNAPSHOT) then
	print(`component_snapshot: {SNAPSHOT} does not exist; create it with -- --update and review it`)
	process.exit(1)
else
	local current = fs.readFile(SNAPSHOT)
	if current ~= text then
		print(
			`component_snapshot: {SNAPSHOT} is out of date; token use changed. Review, then run with -- --update`
		)
		process.exit(1)
	end
	print(`component_snapshot: {#files} components checked, snapshot current`)
end
