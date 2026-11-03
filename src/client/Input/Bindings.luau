--!strict
--[[
	The control table: which physical input, and which on-screen control, triggers each action in
	each context. Pure data. Key names are Enum.KeyCode member names as strings, so this file has no
	Roblox dependency; tools/check_enums.py verifies every name against the Roblox API dump, so a
	typo cannot ship silently.

	Contexts are separate because the same key means different things on foot and in the cab
	(Escape is "pause" on foot and "back" in menus). Conflicts are only checked inside a context.

	Safety rules that tests enforce (tests/client/bindings.spec.luau):
	- Every cab action that matters while moving has a binding on keyboard, gamepad and touch.
	- The emergency brake is never on Space or Enter, which are reached by accident.
]]

local Bindings = {}

export type Touch = { id: string, label: string }
export type Action = {
	keyboard: { string },
	gamepad: { string },
	touch: Touch?,
}
export type Context = { [string]: Action }

Bindings.contexts = {
	cab = {
		throttleUp = {
			keyboard = { "W" },
			gamepad = { "ButtonR2" },
			touch = { id = "throttleSlider", label = "Throttle" },
		},
		brakeService = {
			keyboard = { "S" },
			gamepad = { "ButtonL2" },
			touch = { id = "brakeSlider", label = "Brake" },
		},
		brakeEmergency = {
			keyboard = { "Backspace" },
			gamepad = { "ButtonB" },
			touch = { id = "emergencyBrake", label = "Emergency" },
		},
		reverserUp = {
			keyboard = { "Q" },
			gamepad = { "DPadUp" },
			touch = { id = "reverserUp", label = "Reverser" },
		},
		reverserDown = {
			keyboard = { "Z" },
			gamepad = { "DPadDown" },
			touch = { id = "reverserDown", label = "Reverser" },
		},
		horn = {
			keyboard = { "H" },
			gamepad = { "ButtonL3" },
			touch = { id = "horn", label = "Horn" },
		},
		doors = {
			keyboard = { "C" },
			gamepad = { "ButtonL1" },
			touch = { id = "doors", label = "Doors" },
		},
		map = {
			keyboard = { "M" },
			gamepad = { "ButtonSelect" },
			touch = { id = "map", label = "Map" },
		},
		pause = {
			keyboard = { "Escape" },
			gamepad = { "ButtonStart" },
			touch = { id = "menu", label = "Menu" },
		},
	} :: Context,
	onFoot = {
		interact = {
			keyboard = { "E" },
			gamepad = { "ButtonX" },
			touch = { id = "interact", label = "Interact" },
		},
		map = {
			keyboard = { "M" },
			gamepad = { "ButtonSelect" },
			touch = { id = "map", label = "Map" },
		},
		pause = {
			keyboard = { "Escape" },
			gamepad = { "ButtonStart" },
			touch = { id = "menu", label = "Menu" },
		},
	} :: Context,
	menu = {
		select = {
			keyboard = { "Return" },
			gamepad = { "ButtonA" },
			touch = { id = "tap", label = "Select" },
		},
		back = {
			keyboard = { "Escape" },
			gamepad = { "ButtonB" },
			touch = { id = "back", label = "Back" },
		},
		tabPrevious = {
			keyboard = { "LeftBracket" },
			gamepad = { "ButtonL1" },
			touch = nil,
		},
		tabNext = {
			keyboard = { "RightBracket" },
			gamepad = { "ButtonR1" },
			touch = nil,
		},
	} :: Context,
}

-- Short glyph text for prompts. Gamepad names are printed as the labels on the controller, so a
-- player reads "A" and sees the same button.
Bindings.glyphs = {
	ButtonA = "A",
	ButtonB = "B",
	ButtonX = "X",
	ButtonY = "Y",
	ButtonL1 = "LB",
	ButtonR1 = "RB",
	ButtonL2 = "LT",
	ButtonR2 = "RT",
	ButtonL3 = "LS",
	ButtonR3 = "RS",
	ButtonStart = "Menu",
	ButtonSelect = "View",
	DPadUp = "D-Up",
	DPadDown = "D-Down",
	Escape = "Esc",
	Backspace = "Backspace",
	Return = "Enter",
	LeftBracket = "[",
	RightBracket = "]",
} :: { [string]: string }

return Bindings
