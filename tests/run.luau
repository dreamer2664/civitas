--!strict
-- Lune test runner for Phase 1 pure modules.
-- Usage: lune run tests/run.luau
--
-- Each spec file requires tests/support/suite and registers tests with suite.test(...).
-- This runner requires every spec, then runs the suite and reports pass/fail.

local suite = require("./support/suite")

local specFiles = {
	"rail/spline.spec",
	"rail/kinematics.spec",
	"rail/doors_backpressure_fixture.spec",
	"util/rate_limit.spec",
	"scheduling/timetable_scheduler.spec",
	"scheduling/headway_simulation.spec",
}

for _, specFile in ipairs(specFiles) do
	require("./" .. specFile)
end

local passed, failed = suite.run()
print(string.format("\n%d passed, %d failed", passed, failed))

if failed > 0 then
	error(string.format("test suite failed: %d failure(s)", failed))
end
