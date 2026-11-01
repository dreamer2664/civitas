--!strict
-- Minimal assertion support for lune specs. Pure Luau, no Roblox globals.
-- All checks are plain functions: Assert.equal(actual, expected, message?).

local Assert = {}

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	local countA = 0
	for k, v in pairs(a) do
		if type(b[k]) ~= type(v) or not deepEqual(v, b[k]) then
			return false
		end
		countA += 1
	end
	local countB = 0
	for _ in pairs(b) do
		countB += 1
	end
	return countA == countB
end

local function valueToString(v: any): string
	if type(v) == "table" then
		local parts = {}
		for k, val in pairs(v) do
			table.insert(parts, string.format("[%s]=%s", tostring(k), valueToString(val)))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(v)
end

function Assert.equal(actual: any, expected: any, message: string?): ()
	if not deepEqual(actual, expected) then
		error(
			message
				or string.format(
					"expected %s, got %s",
					valueToString(expected),
					valueToString(actual)
				),
			2
		)
	end
end

function Assert.near(actual: number, expected: number, tolerance: number, message: string?): ()
	if math.abs(actual - expected) > tolerance then
		error(
			message
				or string.format(
					"expected %s within %s, got %s",
					valueToString(expected),
					tostring(tolerance),
					valueToString(actual)
				),
			2
		)
	end
end

function Assert.ok(condition: boolean, message: string?): ()
	if not condition then
		error(message or "expected truthy condition", 2)
	end
end

local function expect(actual: any)
	return setmetatable({ actual = actual }, { __index = Assert })
end

return {
	equal = Assert.equal,
	near = Assert.near,
	ok = Assert.ok,
	expect = expect,
	deepEqual = deepEqual,
}
