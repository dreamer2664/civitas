--!strict
-- Greedy label decluttering. Input rectangles must already be in map-canvas pixels.
-- Earlier labels win; markers and tracks remain visible even when a label is omitted.
local LabelLayout = {}
export type Rect = { x: number, y: number, w: number, h: number }

function LabelLayout.accept(rect: Rect, accepted: { Rect }, width: number, height: number): boolean
	if rect.x < 0 or rect.y < 0 or rect.x + rect.w > width or rect.y + rect.h > height then
		return false
	end
	for _, other in accepted do
		if
			rect.x < other.x + other.w
			and rect.x + rect.w > other.x
			and rect.y < other.y + other.h
			and rect.y + rect.h > other.y
		then
			return false
		end
	end
	table.insert(accepted, rect)
	return true
end

return LabelLayout
