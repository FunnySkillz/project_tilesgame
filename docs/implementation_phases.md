# Implementation Phases

This file tracks how the design plan is being turned into playable builds.

## Tooling And Architecture Notes

Implemented:

- Graphify CLI evaluated locally
- Graphify limitation for Godot/GDScript documented in `docs/graphify_evaluation.md`
- generated Graphify output ignored in Git

Decision:

Use Graphify later as a documentation and architecture-map companion, but do not depend on it for GDScript code structure until `.gd` support exists or we add language-neutral architecture sidecars.

## Phase 1: Fun Core

Status: playable baseline complete.

Goal: prove that the core loop is satisfying on a phone-sized screen.

Implemented:

- starter working fishery with pool, cutter, and market already placed
- tap water to catch fish
- tap pool to store carried fish
- cutter automatically processes live fish into meat
- market automatically sells meat to waiting customers
- money, customers, carried fish, live fish, and meat HUD
- net, pool, and cutter upgrades
- guided objective chain for the first loop
- selected tile feedback
- floating reward and production popups

Next:

- tune timings and costs after playtesting
- replace temporary visuals after Phase 2 stabilizes

## Phase 2: Layout Game

Status: playable baseline complete.

Goal: make tile placement matter.

Needs:

- build, remove, and move buildings
- building ranges and adjacency bonuses
- storage limits
- market/customer waiting pressure
- better tile inspector
- basic path or adjacency rules for production flow

Implemented:

- road tiles as sell-side anchors
- market road-adjacency sales bonus
- pool water-adjacency capacity bonus
- cutter pool-adjacency work-rate bonus
- meat storage limit
- move building tool
- remove building tool with partial refund
- inspector text for local layout bonuses
- button affordability tinting and dynamic upgrade prices
- timed market sales instead of instant frame-by-frame selling
- customer patience timer and lost-customer pressure
- visible waiting customers on the road row

Next:

- tune customer arrival, patience, sale speed, and sale value after playtesting
- add a first lightweight texture pack once the layout loop feels readable

Decision:

Use adjacency rules for Phase 2. They are readable on a small phone grid and fast to tune. Save explicit pathfinding for later workers, monsters, carts, and trucks, where routes become part of the fantasy instead of extra friction in the first layout loop.

## Phase 3: Progression

Status: playable baseline complete.

Goal: give the player reasons to keep expanding.

Needs:

- [x] first unlock panel and gated unlock
- [x] broader unlock tree
- [x] multiple fish types
- [x] first new building
- [x] more buildings
- [x] first land expansion mechanic
- [x] first 30-minute goal chain

Next:

- tune the first progression branch after playtesting for pacing and reward values
- begin Phase 4 with a soft cold-pressure system before adding monster attacks

Implemented:

- minnow, carp, and silverfish as distinct early fish types
- water tiles now spawn and display a specific fish species
- carried and live fish are tracked by species
- compact fish stock summaries in the HUD
- fish species have different meat yields
- fish species use different placeholder colors
- Net level 2 unlocks silverfish spawns
- Net level 3 improves the better-fish spawn mix
- post-Phase-1 goal text now points the player toward Net 2 and silverfish
- unlock line shows the next progression target
- Storage unlocks after catching silverfish
- Storage building adds meat capacity
- Storage gets bonus capacity beside markets
- storage removal and movement are blocked when the building is needed for current meat capacity
- edge expansion tiles start locked
- Expand tool unlocks after building Storage
- expansion converts edge ground into buildable land for money
- goal and unlock text now guide the player through Storage into land expansion
- goal chain now continues through Net 2, silverfish, Storage, land expansion, and steady sales
- goal rewards continue through the first progression arc
- Smoker unlocks after land expansion and steady sales
- Smoker turns 2 meat into 1 smoked meat over time
- smoked meat sells before raw meat for a higher price
- smokers gain speed from adjacent cutters and storage
- storage and smoker movement/removal respect smoked meat capacity
- HUD, inspector, labels, and goal text support the smoked meat branch

## Phase 4: Danger

Status: planned.

Goal: make the world feel dangerous and memorable.

Needs:

- cold system
- night attacks
- fences, traps, and weapons
- repair mechanic
- rare monster resources

Next:

- add a visible cold meter or cold-wave timer
- make cold temporarily slow cutters and smokers
- unlock the first heater as the clear counterplay
- keep cold pressure soft and reversible before monster attacks arrive

## Phase 5: Automation And Trucks

Status: planned.

Goal: make the base feel like a growing business.

Needs:

- workers or conveyors
- truck stop
- bulk orders
- advanced machines
- production planning

## Phase 6: Mobile Release Polish

Status: planned.

Goal: make it feel ready for real phone testing.

Needs:

- saving and loading
- settings
- sound and music
- animations
- Android export setup
- performance checks
- tutorial polish
