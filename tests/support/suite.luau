--!strict
-- Minimal test suite: specs call suite.test(...) to register, then the runner runs all of them.
-- Pure Luau, no Roblox globals.

local assert = require("./assert")

local suite = {
	tests = {},
	expect = assert,
}

function suite.test(name: string, fn: () -> ())
	table.insert(suite.tests, { name = name, fn = fn })
end

function suite.run(): (number, number)
	local passed = 0
	local failed = 0
	for _, t in ipairs(suite.tests) do
		local ok, err = pcall(t.fn)
		if ok then
			passed += 1
			print(string.format("  ok   %s", t.name))
		else
			failed += 1
			print(string.format("  FAIL %s", t.name))
			print("    " .. tostring(err))
		end
	end
	return passed, failed
end

return suite
