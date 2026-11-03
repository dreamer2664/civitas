--!strict
--[[
	Which input family the UI should speak: keyboard, gamepad or touch. Pure, and dependency-free:
	the binding and glyph tables are passed in, because Roblox resolves requires through
	`script.Parent`, which lune cannot follow (see Layout.luau for the same rule).

	The rule comes from Roblox's own guidance: UserInputService.PreferredInput follows the player's
	most recent interaction, so a phone with a Bluetooth gamepad reports Gamepad, and a tablet with
	a keyboard reports KeyboardAndMouse. Checking TouchEnabled alone would show touch prompts to a
	player who is holding a controller.
]]

local InputMode = {}

export type Mode = "keyboard" | "gamepad" | "touch"

-- Shape of one entry in Bindings.contexts. Declared again here rather than imported, for the reason
-- above; tests/client/bindings.spec.luau checks that the two stay compatible.
export type Binding = {
	keyboard: { string },
	gamepad: { string },
	touch: { id: string, label: string }?,
}

-- `preferred` is the name of a PreferredInput member. `hasTouch` only matters when the value is
-- unknown: a touch-capable device then falls back to touch, anything else to keyboard.
function InputMode.fromPreferred(preferred: string, hasTouch: boolean): Mode
	if preferred == "Touch" then
		return "touch"
	elseif preferred == "Gamepad" or preferred == "MicroGamepad" then
		return "gamepad"
	elseif preferred == "KeyboardAndMouse" then
		return "keyboard"
	end
	return if hasTouch then "touch" else "keyboard"
end

-- The text a player should read for a binding, e.g. "E", "RT" or "Brake". Returns nil when the
-- binding has nothing for this mode, so a missing prompt shows up in tests rather than as an empty
-- label on screen.
function InputMode.promptFor(mode: Mode, binding: Binding, glyphs: { [string]: string }): string?
	if mode == "touch" then
		local touch = binding.touch
		return if touch then touch.label else nil
	end
	local keys = if mode == "gamepad" then binding.gamepad else binding.keyboard
	local first = keys[1]
	if first == nil then
		return nil
	end
	return glyphs[first] or first
end

return InputMode
