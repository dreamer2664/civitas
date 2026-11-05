--!strict
--[[
	Runs every unit test in the repository. Usage: `lune run tests/run.luau` (from the repository root).
	Two registries exist side by side: vector's rail specs register with tests/support/suite, and
	client specs register with tests/harness. Both run here and either one failing fails the run.
	Add a spec by requiring it here: the list is explicit so a missing spec is visible in review.
]]

local process = require("@lune/process")
local harness = require("./harness")
local suite = require("./support/suite")

-- Shared rail specs (CODE · vector), registered with tests/support/suite.
require("./rail/spline.spec")
require("./rail/kinematics.spec")

-- Client specs (CODE · lumen), registered with tests/harness.
require("./client/theme.spec")
require("./client/text.spec")
require("./client/layout.spec")
require("./client/format.spec")
require("./client/navigation.spec")
require("./client/bindings.spec")
require("./client/map.spec")
require("./client/map-labels.spec")
require("./client/gauge.spec")
require("./client/compass.spec")

local railPassed, railFailed = suite.run()
print(string.format("\n%d passed, %d failed (rail)", railPassed, railFailed))

local clientFailures = harness.run()
if railFailed > 0 or clientFailures > 0 then
	process.exit(1)
end
