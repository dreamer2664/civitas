--!strict
--[[
	Minimal test harness for lune. Specs register cases at load time; `run` executes them all,
	prints one line per failure, and returns the failure count. A non-zero count makes the runner
	exit non-zero, so `tools/verify.sh` fails on a broken rule.

	Deliberately tiny: a framework would be another dependency to version. Every assertion says
	what was expected, so a failing line reads like a bug report.
]]

local harness = {}

type Case = { name: string, run: () -> () }

local cases: { Case } = {}
local suite = ""

function harness.suite(name: string)
	suite = name
end

function harness.test(name: string, run: () -> ())
	table.insert(cases, { name = `{suite} > {name}`, run = run })
end

function harness.equal(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(
			`{message or "values differ"}: expected {tostring(expected)}, got {tostring(actual)}`,
			2
		)
	end
end

function harness.near(actual: number, expected: number, epsilon: number, message: string?)
	if actual ~= actual or math.abs(actual - expected) > epsilon then
		error(`{message or "numbers differ"}: expected {expected} ± {epsilon}, got {actual}`, 2)
	end
end

function harness.truthy(value: any, message: string?)
	if not value then
		error(message or "expected a truthy value", 2)
	end
end

function harness.falsy(value: any, message: string?)
	if value then
		error(message or "expected a falsy value", 2)
	end
end

-- Passes when `run` raises an error. If `fragment` is given, the error must contain it, so tests
-- also check that the message is useful and not just any failure.
function harness.raises(run: () -> (), fragment: string?)
	local ok, err = pcall(run)
	if ok then
		error("expected an error, but none was raised", 2)
	end
	if fragment ~= nil and not string.find(tostring(err), fragment, 1, true) then
		error(`error did not mention "{fragment}": {tostring(err)}`, 2)
	end
end

function harness.run(): number
	local failures = 0
	for _, case in cases do
		local ok, err = pcall(case.run)
		if not ok then
			failures += 1
			print(`FAIL  {case.name}\n      {tostring(err)}`)
		end
	end
	local passed = #cases - failures
	print(`{passed} passed, {failures} failed, {#cases} total`)
	return failures
end

return harness
