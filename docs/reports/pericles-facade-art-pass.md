# District A facade blockout pass

2026-11-05. The ordinary building massing now has height-scaled rows of simple window overlays on its front and rear faces; these do not collide or participate in ray queries and do not create interiors. Existing facade overlays on 90-degree buildings now use the Roblox yaw convention rather than the opposite rotation, so they sit on the intended face. `FacadeMath` has a pure rotation test.

The regenerated street-level images have been inspected. The repetitive windows improve the legibility of storeys, but the world is still a blockout, not finished architecture, and the Python renders are illustrative rather than Studio screenshots. There are no detailed side elevations, interiors, human-scale decor or production lighting.

Cost matters: the plan recipe now estimates **10,326** parts, up from **1,920**, versus a nominal 25,000-part budget. This is a recipe count, not a measured runtime count, draw-call count, memory use, or frame rate. The window approach must be profiled on a representative phone and may need instancing, mesh/texture atlases, fewer windows, LOD or removal if it performs badly. Do not treat a passing arithmetic budget as proof of mobile performance.
