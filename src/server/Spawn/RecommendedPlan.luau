--!strict
-- LEGACY geometry fixture, superseded for naming/anchor decisions by root NAMES.md.
-- CanonicalPlan.luau is generated from NAMES.md. Neither fixture applies runtime spawning.
-- Retains >1500 studs to concourse and exposes Civic Archive Tower from the sidewalk.
-- Runtime integration must orient the spawn/camera and verify streamed support/first frame.
return table.freeze({
	city = table.freeze({ x = 136.75, z = -512 }),
	station = table.freeze({ x = 120, z = 925 }),
	lookAtLandmark = "Civic Archive Tower",
	lookAtPart = "Lantern",
	eyeOffsetAssumed = 4.5,
})
