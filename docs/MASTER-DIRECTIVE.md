# PROJECT CIVITAS — Master Production Directive

*Transcribed from the Director, 2026-11-01. This document overrides every other document in this
repository. If anything here conflicts with a plan, a preference or a habit, this document wins.*

**Project type:** Large-scale passenger railway simulator + semi-open-world city exploration
**Platform:** Roblox
**Team:** 1 Manager + 4 specialist agents
**Budget:** Zero-budget development wherever possible
**Primary objective:** a genuinely high-quality, immersive, expansive, replayable Roblox game.

---

## 1. THE VISION

A large, sophisticated railway experience in an original fictional European coastal metropolis called
**Civitas**. Civitas must feel like a real, functioning city — not a collection of disconnected
Roblox buildings placed around railway tracks.

The central attraction is an extensive passenger railway network, but the surrounding city is equally
important. Players must be able to:

- Operate passenger trains.
- Travel as passengers.
- Explore the city on foot.
- Enter railway stations and selected buildings.
- Discover hidden locations and landmarks.
- Interact with other players and the environment.
- Complete railway-related jobs and activities.
- Progress, earn money and unlock new opportunities.

The game combines the atmosphere of a realistic railway simulator with the freedom of an open-world
exploration game. The city must feel alive even when the player is not operating a train.
**Do not build a simplistic train simulator with a few buildings around a track.**

## 2. WORLD DESIGN — CIVITAS

**Overall map.** Design target ~**10,000 × 8,000 studs**. Validate dimensions through blockout and
performance testing rather than blindly maximising size. Natural geographical boundaries, coherent
urban layout.

### District A — Historic City Centre
The architectural heart. A monumental central railway station; historic European architecture;
narrow streets and pedestrian areas; shops, cafés, restaurants; public squares; churches and civic
buildings; pedestrian bridges; bus stops and tram infrastructure; a dense network of streets and
alleys. The central station should be one of the most impressive structures in the game. Players must
be able to explore the station, access platforms, navigate concourses and walk directly into the city.

### District B — Modern Business District
Tall office buildings and skyscrapers; commercial avenues; shopping centres; modern railway stations;
underground pedestrian connections; public plazas; parking structures; modern architecture and
lighting. Must feel considerably different from the historic centre.

### District C — Residential Civitas
Apartment buildings; residential streets; small parks; schools; local shops; supermarkets; bus
connections; small railway stations; pedestrian pathways. It should feel like somewhere actual
citizens would live. **Avoid endless identical buildings** — vary style, height, street layout.

### District D — Industrial Harbour
Commercial harbour; freight warehouses; container terminals; railway freight infrastructure;
industrial buildings; cranes; waterfront roads; a promenade; a ferry terminal; abandoned industrial
locations. A distinctive atmosphere, particularly in the evening and at night.

### District E — Airport and Outer Suburbs
An airport; airport railway station; residential suburbs; logistics facilities; roads connecting to
the city; green spaces; hills and countryside; small settlements; railway infrastructure connecting
the outskirts to the centre. **The city must not abruptly end at its map boundaries** — use natural
terrain, distant infrastructure and carefully constructed transitions.

### World-building standards
1. A coherent road network. 2. Continuous sidewalks and pedestrian connections. 3. Consistent
architectural styles within districts. 4. A believable railway alignment. 5. Stations integrated into
their neighbourhoods. 6. Landmarks visible from multiple locations. 7. Environmental details that
reward exploration. 8. Different levels of density across the city.

Do not fill the map with empty space just to claim it is large. Do not make every building enterable
— prioritise exterior quality, accessible public spaces and selected detailed interiors.

## 3. RAILWAY SYSTEM

The primary gameplay system. Plan for approximately: **2–3 passenger lines**, **12–16 stations**, a
central interchange, a railway depot, multiple junctions, express and local services, and a mixture
of elevated, ground-level and underground sections where appropriate. These are full-project targets,
not first-prototype requirements.

The railway must be physically integrated into the city: tracks must not float over roads or pass
through buildings. Bridges, tunnels, crossings and embankments must be constructed appropriately.

**Train operation.** Players should eventually operate trains with an intuitive but meaningful
driving system: throttle, service brake, emergency brake, reverser, horn, doors, speedometer, speed
restrictions, station stopping markers, signal indicators, destination displays, passenger
announcements. Accessible through keyboard, controller and mobile-friendly UI. Responsive and
believable.

**Railway simulation.** Eventually support scheduled services, station stops, boarding and
disembarking, signals, switches, multiple simultaneous trains, speed limits, timetable adherence and
safe separation. Passengers must not be purely decorative — believable station activity and train
occupancy, using efficient NPC management rather than unlimited NPCs.

**Technical requirement.** Before developing the complete train system, Programmer A (**CODE ·
vector**) must investigate and prototype the best approach to train movement, comparing:
1. a track-following, server-controlled movement system, and
2. a physics-driven train system —

evaluating stability, multiplayer synchronisation, responsiveness, performance and implementation
complexity, then selecting and documenting the decision. **Do not sacrifice reliable multiplayer
operation for unnecessary physics complexity.**

## 4. PLAYER GAMEPLAY

**Railway operator**: select available services; operate trains; follow timetables; collect
passengers; stop accurately at platforms; obey signals and speed restrictions; earn rewards based on
service quality.

**Passenger**: purchase or select journeys; enter stations; board trains; travel between districts;
leave trains and explore; interact with station infrastructure.

**City exploration**: discover landmarks; find hidden locations; visit selected enterable buildings;
explore the harbour; walk through parks; discover unusual railway locations; use public transport;
find collectibles and environmental secrets.

**Progression**: operator ranks; new train unlocks; different services; cosmetic customisation;
exploration achievements; financial rewards; service ratings. **Do not create an excessively
grind-heavy progression system.** Enjoyable without payment.

## 5. FOUR-AGENT ORGANISATION

The Manager creates four independent assignments, prevents overlap and integration conflicts.

**Agent 1 — BLENDER · mason — Senior 3D Artist and Train Specialist.** Custom railway assets and
major architectural models: the initial train, locomotives and carriages, railway components, station
architecture, platforms and furniture, railway bridges and distinctive infrastructure. Detailed
Blender source files, Roblox-compatible exports. Quality: appropriate scale, consistent materials,
functional pivots, optimised geometry, appropriate collision meshes, reusable modular components.
**Train models are especially important — they must feel like actual designed railway vehicles, not
generic rectangular Roblox models.** Study Blender-to-Roblox workflows before production.

**Agent 2 — BLENDER · atlas — Environment Artist and Asset Researcher.** Research free, appropriately
licensed Creator Store assets; create an asset catalogue; identify reusable urban assets; construct
city districts; roads, pavements, vegetation; building exteriors; environmental details; coherent
streetscapes; coordinate with Agent 1 on major structures. **Do not blindly import free models** —
inspect scripts, permissions and dependencies; reject suspicious assets. Prioritise original work
and properly licensed resources. The environment must be visually cohesive, not a random combination.

**Agent 3 — CODE · vector — Senior Luau Gameplay Engineer.** Train movement, track infrastructure,
train controls, signalling, station systems, service scheduling, server-authoritative gameplay,
passenger management, multiplayer railway coordination, data persistence. Modular, extensible,
strict Luau typing where practical, meaningful error handling, documented interfaces. **Do not put
the entire game into one enormous script.**

**Agent 4 — CODE · lumen — Senior Luau Client and Systems Engineer.** Main menu, UI, train dashboard,
mobile controls, interaction systems, station interfaces, map interface, progression, economy,
exploration systems, client-side effects, integration with Agent 3. Professional, intuitive UI
consistent with the game's visual identity. **Avoid generic default-looking Roblox interfaces.**

## 6. PROJECT ARCHITECTURE

The Manager establishes the technical architecture before full production. Clear module boundaries
and shared interfaces. Suggested hierarchy (Workspace: World/City, Railway, Stations, Landmarks;
ActiveTrains; DynamicObjects — ReplicatedStorage: Shared/Modules, Configuration, Constants; Remotes;
ClientAssets — ServerScriptService: Services/Railway, Gameplay, Data — ServerStorage: AssetLibrary,
NPCStorage, TrainTemplates — StarterPlayer: StarterPlayerScripts, ClientControllers — StarterGui:
MainUI, TrainUI, MapUI, InteractionUI). Adjust when technically necessary.

Every major system must have a documented API. Example, illustrative not mandatory:
`TrainService: CreateTrain() · StartService() · StopService() · SetThrottle() · SetBrake() ·
GetTrainState()`. **Agents must agree on interfaces before implementing dependent systems.**

**Source control.** This repository is the source of truth. The Manager establishes folder ownership,
prevents concurrent edits to the same files, requires meaningful commits, reviews changes before
integration, maintains a working `main`, and keeps backups of milestones. Agents submit **source
files, not screenshots**. For Blender, preserve editable `.blend` files alongside exports. For code,
documented Luau sources. **Never overwrite another agent's completed work without coordination.**

## 7. PERFORMANCE REQUIREMENTS

Optimisation is mandatory from the beginning. Enable and configure instance streaming; use LOD
strategies; reuse modular assets; avoid excessive unique geometry; optimise mesh collision fidelity;
reduce unnecessary scripts and loops; avoid excessive NPC counts; keep ReplicatedStorage lean; manage
memory; test on lower-end devices; avoid excessive client-server traffic. **The game must remain
playable on ordinary mobile devices.** The Manager sets performance budgets and tests them regularly.
A beautiful city that causes severe lag is an unsuccessful city.

## 8. VISUAL DIRECTION

Grounded, atmospheric, coherent: modern European urban architecture plus realistic railway
infrastructure. Detailed trains; believable station interiors; attractive night lighting; realistic
road layouts; distinct neighbourhood architecture; carefully designed public spaces; atmospheric
environmental audio; convincing railway signage; cohesive textures and materials. **Avoid excessive
neon, random futuristic elements, cartoonish proportions and oversaturated colours** unless there is a
clear artistic reason. Produce an art bible: architectural style, material palette, lighting, train
design, signage, environmental detailing, UI appearance. The whole game must look like one product.

## 9. DEVELOPMENT PHASES

**Phase 1 — Technical foundation:** approved concept; world layout; railway network diagram; art
direction; technical architecture; agreed asset standards; initial train movement prototype; initial
city blockout. **No large-scale asset production until the core architecture is approved.**

**Phase 2 — Playable vertical slice:** one functioning train; one operational line; at least three
connected stations; a central station; a walkable city-centre environment; functional train controls;
basic timetable and station systems; basic UI; multiplayer testing. Polished enough to show a
stranger.

**Phase 3 — World expansion:** new districts, stations, railway sections, train models, activities,
enterable buildings, assets — without sacrificing existing functionality.

**Phase 4 — Systems and polish:** progression, economy, additional services, passenger improvements,
exploration activities, audio, weather/day-night where performance allows, UI refinement,
optimisation.

**Phase 5 — Testing and release preparation:** multiplayer testing, train-system testing, data
persistence testing, mobile testing, performance profiling, asset security audits, bug fixing,
onboarding testing. **Do not declare the game finished because the map looks complete.**

## 10. MANAGER REQUIREMENTS

The Manager is responsible for the entire development organisation and for producing a coherent
finished game, not merely assigning tasks. First actions: read this directive; inspect the
environment and repository; spawn the four specialist agents; give each the resources relevant to its
profession; require each to study them and produce an initial technical report; review all reports;
establish shared interfaces and technical standards; divide the project into independent tasks; track
deliverables and integration; **test completed work rather than trusting progress claims**.

**Autonomy:** agents work independently where possible — the train specialist models while the
gameplay engineer prototypes movement; the environment specialist blockouts while the client engineer
builds map UI. Do not create unnecessary dependencies. When one agent is blocked, reassign independent
work rather than stopping.

**Quality control:** every deliverable is reviewed. Reject broken scripts, unoptimised assets,
unusable models, inconsistent architecture, placeholder work presented as finished, unverified free
models and untested integrations. **Require evidence of testing.**

**Reporting:** completed work, current work, failed tests, outstanding bugs, blockers, next
milestones, repository changes. **Do not inflate progress estimates.**

## 11. FINAL QUALITY STANDARD

The objective is not the largest possible map. It is a world players want to spend time inside: trains
enjoyable to operate, a railway that feels interconnected, stations that are interesting places, a
city that rewards exploration, consistent visual quality, reliable multiplayer, meaningful activities
beyond driving from one station to another.

**Think like a professional game studio, not a group of agents completing isolated programming
exercises.** Design the architecture correctly, build incrementally, test continuously, maintain high
standards. Start with the initial technical reports and Phase 1. Do not skip the planning stage. The
final result should feel like a complete railway world, not a prototype surrounded by unfinished
scenery.
