--!strict
--[[
	Screen navigation as an immutable stack. Pure: every operation returns a new value, so a test
	can replay any sequence of presses and check the result.

	Rules (the spec in UI-SPEC §6 is the source of truth):
	- Pushing the screen already on top does nothing (double taps must not stack screens).
	- Pushing a screen already in the stack pops back to it. The stack never holds duplicates, so
	  "back" always returns to a screen the player has actually seen, in order.
	- Back at the root reports "atRoot". The caller then opens the pause menu, rather than the
	  navigation layer deciding what the game does.
]]

local Navigation = {}

export type Stack = { ids: { string } }
export type BackResult = "popped" | "atRoot"

function Navigation.new(root: string): Stack
	assert(root ~= "", "Navigation root must be a non-empty screen id")
	return { ids = { root } }
end

function Navigation.top(nav: Stack): string
	return nav.ids[#nav.ids]
end

function Navigation.depth(nav: Stack): number
	return #nav.ids
end

function Navigation.contains(nav: Stack, id: string): boolean
	for _, existing in nav.ids do
		if existing == id then
			return true
		end
	end
	return false
end

function Navigation.push(nav: Stack, id: string): Stack
	assert(id ~= "", "screen id must be non-empty")
	if Navigation.top(nav) == id then
		return nav
	end
	-- Revisiting a screen pops back to it, so the stack holds no duplicates.
	local ids = {}
	for _, existing in nav.ids do
		table.insert(ids, existing)
		if existing == id then
			return { ids = ids }
		end
	end
	table.insert(ids, id)
	return { ids = ids }
end

function Navigation.replace(nav: Stack, id: string): Stack
	assert(id ~= "", "screen id must be non-empty")
	local ids = table.clone(nav.ids)
	ids[#ids] = id
	return { ids = ids }
end

function Navigation.back(nav: Stack): (Stack, BackResult)
	if #nav.ids <= 1 then
		return nav, "atRoot"
	end
	local ids = table.clone(nav.ids)
	table.remove(ids)
	return { ids = ids }, "popped"
end

return Navigation
