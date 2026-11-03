--!strict
-- Control rules from docs/ui/UI-SPEC §7 and src/client/Input/Bindings.luau. The safety-critical
-- rules are the ones that matter most: the emergency brake must be reachable on every input.

local harness = require("../harness")
local Bindings = require("../../src/client/Input/Bindings")
local InputMode = require("../../src/client/Input/InputMode")

harness.suite("bindings")

local CAB_CONTROLS_NEEDING_TOUCH = {
	"throttleUp",
	"brakeService",
	"brakeEmergency",
	"reverserUp",
	"reverserDown",
	"horn",
	"doors",
}

harness.test(
	"every cab control has a keyboard key, a gamepad button and a touch control",
	function()
		local cab = Bindings.contexts.cab
		for _, name in CAB_CONTROLS_NEEDING_TOUCH do
			local binding = cab[name]
			harness.truthy(binding ~= nil, `cab is missing action {name}`)
			harness.truthy(#binding.keyboard >= 1, `{name} has no keyboard binding`)
			harness.truthy(#binding.gamepad >= 1, `{name} has no gamepad binding`)
			harness.truthy(binding.touch ~= nil, `{name} has no touch control`)
		end
	end
)

harness.test(
	"the emergency brake is never on Space or Enter, the keys pressed by accident",
	function()
		local emergency = Bindings.contexts.cab.brakeEmergency
		for _, key in emergency.keyboard do
			harness.truthy(key ~= "Space", "emergency brake must not be on Space")
			harness.truthy(key ~= "Return", "emergency brake must not be on Enter")
		end
	end
)

harness.test("no two actions in one context share a keyboard or gamepad input", function()
	for contextName, context in Bindings.contexts do
		local seenKeys: { [string]: string } = {}
		local seenPads: { [string]: string } = {}
		for actionName, binding in context do
			for _, key in binding.keyboard do
				local other = seenKeys[key]
				harness.truthy(
					other == nil,
					`{contextName}: {key} is bound to both {other} and {actionName}`
				)
				seenKeys[key] = actionName
			end
			for _, pad in binding.gamepad do
				local other = seenPads[pad]
				harness.truthy(
					other == nil,
					`{contextName}: {pad} is bound to both {other} and {actionName}`
				)
				seenPads[pad] = actionName
			end
		end
	end
end)

harness.test(
	"Escape means pause on foot and back in menus: separate contexts, both present",
	function()
		harness.equal(Bindings.contexts.onFoot.pause.keyboard[1], "Escape")
		harness.equal(Bindings.contexts.menu.back.keyboard[1], "Escape")
	end
)

harness.test(
	"every gamepad input has a printed-label glyph, so prompts match the controller",
	function()
		for contextName, context in Bindings.contexts do
			for actionName, binding in context do
				for _, pad in binding.gamepad do
					harness.truthy(
						Bindings.glyphs[pad] ~= nil,
						`{contextName}.{actionName} uses {pad} with no glyph`
					)
				end
			end
		end
	end
)

harness.test("PreferredInput maps to the right prompt family", function()
	harness.equal(InputMode.fromPreferred("Touch", false), "touch")
	harness.equal(InputMode.fromPreferred("Gamepad", false), "gamepad")
	harness.equal(InputMode.fromPreferred("MicroGamepad", false), "gamepad")
	harness.equal(
		InputMode.fromPreferred("KeyboardAndMouse", true),
		"keyboard",
		"a phone with a keyboard attached reads keyboard, not touch"
	)
end)

harness.test("an unknown PreferredInput falls back by touch capability", function()
	harness.equal(InputMode.fromPreferred("Mystery", true), "touch")
	harness.equal(InputMode.fromPreferred("Mystery", false), "keyboard")
end)

harness.test("prompts read the right glyph for each input family", function()
	local glyphs = Bindings.glyphs
	local throttle = Bindings.contexts.cab.throttleUp
	harness.equal(InputMode.promptFor("keyboard", throttle, glyphs), "W")
	harness.equal(InputMode.promptFor("gamepad", throttle, glyphs), "RT")
	harness.equal(InputMode.promptFor("touch", throttle, glyphs), "Throttle")

	local interact = Bindings.contexts.onFoot.interact
	harness.equal(InputMode.promptFor("gamepad", interact, glyphs), "X")
	harness.equal(InputMode.promptFor("keyboard", interact, glyphs), "E")
end)

harness.test(
	"a binding with no touch control returns no touch prompt rather than an empty label",
	function()
		local tab = Bindings.contexts.menu.tabPrevious
		harness.equal(InputMode.promptFor("touch", tab, Bindings.glyphs), nil)
	end
)
