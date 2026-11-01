--!strict
--[[
	GeometryContract — ratified dimensional constants (Manager A, 2026-11-01).

	Single source of truth for every physical interface between art and code.
	Mirrors docs/ASSET-INTERFACES.md. Change only by PR with Manager approval.

	Units: all values are in ROBLOX STUDS unless the field name ends in `M` (metres).
]]

local GeometryContract = {}

-- 1 m = 3.5714286 studs (Roblox default 0.28 m/stud)
GeometryContract.STUDS_PER_METRE = 1 / 0.28 :: number

-- §2 Permanent way -----------------------------------------------------------
GeometryContract.RAIL_GAUGE = 1.435 * GeometryContract.STUDS_PER_METRE -- 5.1257
GeometryContract.RAIL_HEAD_WIDTH = 0.07 * GeometryContract.STUDS_PER_METRE
GeometryContract.SLEEPER_SPACING = 0.6 * GeometryContract.STUDS_PER_METRE
GeometryContract.MIN_CURVE_RADIUS_RUNNING = 120 * GeometryContract.STUDS_PER_METRE
GeometryContract.MIN_CURVE_RADIUS_DEPOT = 60 * GeometryContract.STUDS_PER_METRE
GeometryContract.MAX_GRADIENT = 0.025
GeometryContract.TRACK_CENTRE_SPACING = 3.4 * GeometryContract.STUDS_PER_METRE

-- §3 Platforms ---------------------------------------------------------------
GeometryContract.PLATFORM_TOP_ABOVE_RAIL = 0.76 * GeometryContract.STUDS_PER_METRE
GeometryContract.PLATFORM_EDGE_SETBACK = 1.7 * GeometryContract.STUDS_PER_METRE
GeometryContract.PLATFORM_MIN_ISLAND_WIDTH = 6.0 * GeometryContract.STUDS_PER_METRE
GeometryContract.CANOPY_CLEARANCE = 3.2 * GeometryContract.STUDS_PER_METRE
GeometryContract.TACTILE_STRIP_WIDTH = 0.6 * GeometryContract.STUDS_PER_METRE

-- §4 Rolling stock -----------------------------------------------------------
GeometryContract.CAR_WIDTH = 2.85 * GeometryContract.STUDS_PER_METRE
GeometryContract.CAR_HEIGHT_ABOVE_RAIL = 4.1 * GeometryContract.STUDS_PER_METRE
GeometryContract.CLEARANCE_WIDTH = 3.2 * GeometryContract.STUDS_PER_METRE
GeometryContract.CLEARANCE_HEIGHT = 4.6 * GeometryContract.STUDS_PER_METRE
GeometryContract.CAB_CAR_LENGTH = 21.0 * GeometryContract.STUDS_PER_METRE
GeometryContract.INTERMEDIATE_CAR_LENGTH = 20.0 * GeometryContract.STUDS_PER_METRE
GeometryContract.INTER_CAR_GAP = 0.5 * GeometryContract.STUDS_PER_METRE
GeometryContract.DOOR_WIDTH = 1.3 * GeometryContract.STUDS_PER_METRE
GeometryContract.DOOR_HEIGHT = 1.95 * GeometryContract.STUDS_PER_METRE
GeometryContract.DOOR_TRAVEL = 1.35 * GeometryContract.STUDS_PER_METRE
GeometryContract.BOGIE_CENTRES_FROM_END = 3.0 * GeometryContract.STUDS_PER_METRE
GeometryContract.WHEEL_DIAMETER = 0.84 * GeometryContract.STUDS_PER_METRE
GeometryContract.KIT_MODULE_LENGTH = 4.0 * GeometryContract.STUDS_PER_METRE

-- §5 Pivots: car root is at rail-top level on the centreline at the leading
-- coupling face. Expressed here so code and art agree without interpretation.
GeometryContract.CAR_ROOT_Y = 0 -- rail top datum
GeometryContract.BOGIE_PIVOT_Y = 0

export type Geometry = typeof(GeometryContract)

return table.freeze(GeometryContract)
