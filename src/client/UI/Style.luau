--!strict
--[[
	Roblox binding of the Theme tokens: Color3, Enum.Font, TextSize, reduced motion. This file only
	converts a token into a Roblox value. It decides nothing. A new value belongs in Theme.luau.

	Fonts are an explicit table rather than Enum.Font[name]: a misspelt face then fails analysis
	instead of silently falling back to the default look the directive forbids.
]]

local Theme = require(script.Parent.Theme)
local Layout = require(script.Parent.Layout)

local Style = {}

export type ColorName =
	"ink"
	| "surface"
	| "raised"
	| "pressed"
	| "hairline"
	| "text"
	| "textMuted"
	| "textFaint"
	| "accent"
	| "accentText"
	| "proceed"
	| "caution"
	| "stop"
	| "sign"
	| "signText"

export type TypeName =
	"display"
	| "title"
	| "heading"
	| "body"
	| "label"
	| "caption"
	| "sign"
	| "signLarge"
	| "numXL"
	| "numL"
	| "numM"

local FONTS: { [string]: Enum.Font } = {
	BuilderSansExtraBold = Enum.Font.BuilderSansExtraBold,
	BuilderSansBold = Enum.Font.BuilderSansBold,
	BuilderSansMedium = Enum.Font.BuilderSansMedium,
	BuilderSans = Enum.Font.BuilderSans,
	RobotoCondensed = Enum.Font.RobotoCondensed,
	RobotoMono = Enum.Font.RobotoMono,
}

-- Set by the settings screen. When true, every transition duration except `instant` is zero.
local reducedMotion = false

function Style.setReducedMotion(enabled: boolean)
	reducedMotion = enabled
end

function Style.hex(hex: string): Color3
	local r, g, b = Theme.rgb(hex)
	return Color3.fromRGB(r, g, b)
end

function Style.color(name: ColorName): Color3
	return Style.hex(Theme.palette[name])
end

-- Transition length in seconds for a motion token. Reduced motion collapses it to zero.
function Style.duration(name: "instant" | "fast" | "base" | "slow"): number
	if reducedMotion then
		return 0
	end
	return Theme.motion[name]
end

export type Elevation = "flat" | "raised" | "overlay"

-- Fill colour for a depth level. The level-to-token mapping is data in Theme.elevation.
function Style.elevation(level: Elevation): Color3
	return Style.color(Theme.elevation[level] :: ColorName)
end

function Style.font(name: TypeName): Enum.Font
	local face = Theme.type[name].face
	local font = FONTS[face]
	assert(font ~= nil, `Style has no Enum.Font mapping for '{face}'`)
	return font
end

-- Roblox class types are not structural tables, so TextLabel, TextButton and TextBox cannot be
-- passed as a `{ FontFace, TextSize }` table type. The one cast below is therefore guarded by an
-- explicit IsA check: anything that is not a text object is rejected before the cast happens.
type TextProperties = { FontFace: Font, TextSize: number }

-- Applies face and size from a type token. Size passes through the design floor and ceiling.
function Style.applyType(target: GuiObject, name: TypeName)
	if not (target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("TextBox")) then
		error(`Style.applyType needs a text object, got {target.ClassName}`)
	end
	local style = Theme.type[name]
	local text: TextProperties = target :: any
	text.FontFace = Font.fromEnum(Style.font(name))
	text.TextSize = Layout.clampTextSize(style.size, Theme.size.minTextSize, Theme.size.maxTextSize)

	-- The Roblox-side guard: reuse the constraint if the object already has one, so re-styling
	-- never stacks constraints. The floor is the design floor, not the platform minimum of 9.
	local existing = target:FindFirstChildOfClass("UITextSizeConstraint")
	local constraint: UITextSizeConstraint = existing or Instance.new("UITextSizeConstraint")
	if existing == nil then
		constraint.Parent = target
	end
	constraint.MinTextSize = Theme.size.minTextSize
	constraint.MaxTextSize = Theme.size.maxTextSize
end

return Style
