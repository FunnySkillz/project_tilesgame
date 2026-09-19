# Implementation Phases

This file tracks how the design plan is being turned into playable builds.

## Tooling And Architecture Notes

Implemented:

- Graphify CLI evaluated locally
- Graphify limitation for Godot/GDScript documented in `docs/graphify_evaluation.md`
- generated Graphify output ignored in Git

Decision:

Use Graphify later as a documentation and architecture-map companion, but do not depend on it for GDScript code structure until `.gd` support exists or we add language-neutral architecture sidecars.

## Direction Pivot: Manual First, Automation Earned

Decision: the earlier tile-strategy prototype work remains useful foundation work, but it is no longer the main game direction. Coldwater Catch is now a character-driven fishing-business progression game:

Manual fishing -> carrying -> manual processing -> hand sale -> upgrade -> hired automation -> area unlock -> offshore fishing -> industrial fishery.

The player should begin as one visible fisherman doing every job. Workers, cutters, markets, boats, and trucks become satisfying because they visibly take over work the player has already performed. Individual tile adjacency remains a light presentation and placement aid, not the primary optimisation challenge. Danger is delayed until this progression loop is compelling.

## Phase 1: Fun Core

Status: playable baseline complete.

Goal: prove that the core loop is satisfying on a phone-sized screen.

Implemented:

- starter working fishery with pool, cutter, and market already placed
- tap water to catch fish in the first prototype loop, later replaced by Phase 4.5 boat fishing
- tap pool to store carried fish
- cutter automatically processed live fish into meat in the original prototype; Phase 4.7 restores manual cutting until staffed
- market automatically sold meat in the original prototype; Phase 4.7 restores hand sales until staffed
- money, buyers, carried fish, live fish, and meat HUD
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
- market/buyer waiting pressure
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
- buyer patience timer and lost-buyer pressure
- initial visible waiting buyers on the road row, later replaced by Phase 4 buyer agents

Next:

- tune buyer arrival, patience, sale speed, and sale value after playtesting
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
- build the living-base layer before adding cold and monster pressure

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
- first board-edge expansion tiles started locked, later replaced by the larger connected frontier in Phase 4.6
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

## Phase 4: Living Base And Demand

Status: fourth playable slice complete.

Goal: make the fishery feel like a busy, interactive place instead of only a resource board.

Needs:

- [x] visible buyer agents walking to markets
- [x] visible worker agents on the grid
- [x] People tool for selecting and assigning workers
- [x] hire-worker command and crew cap
- [x] worker jobs that affect production
- [x] richer buyer types and preferences
- [x] visible buyer wants
- [x] trade stalls or order board
- [ ] more expressive worker/buyer animations
- [x] clearer paths, docks, and walkable plaza layout

Implemented:

- buyers now spawn as moving people, walk to markets, wait, buy, and leave
- buyer patience is tracked per person instead of only as a shared queue timer
- more markets and staffed markets increase buyer flow
- one starter worker appeared on the board in the original living-base prototype; Phase 4.7 removes it so automation is earned
- workers can be hired up to the current crew cap
- People tool lets the player select a worker and assign them to water, land, or buildings
- water workers catch fish and carry them directly to pools
- pool workers add live-fish capacity
- cutter, market, and smoker workers boost production or sales capacity
- HUD, tile inspector, footer hints, and placeholders now support the people layer
- villagers, cooks, and merchants now appear as distinct buyer types
- buyer want bubbles show M for meat, S for smoked meat, and x3-style bulk demand
- villagers buy regular meat first, cooks wait for smoked meat, and merchants buy bulk orders over multiple sale ticks
- cooks pay a premium for smoked meat
- completed merchant orders pay a small bulk bonus
- goal text now guides the player through cook and merchant demand
- dock order board unlocks after the first merchant bulk order
- road-side order board posts timed larger orders
- market spare sales capacity fills dock orders after serving buyers
- dock orders can ask for meat, smoked meat, or mixed goods
- completing a dock order pays an additional bonus
- order board has a visible road sign, inspector text, unlock text, and a guided goal
- starting board now has dock tiles along the working shoreline
- starting board now has plaza tiles connecting the trade lane, market, and order board
- land, dock, and plaza are all buildable surfaces
- dock and plaza tiles have distinct placeholder visuals
- starter pool and cutter now sit on the dock, while the starter market sits on the plaza
- markets gain extra sale capacity from plaza access as well as road access
- build, move, footer, inspector, and layout hint text now describe buildable surfaces instead of only land

Next:

- add more expressive worker/buyer animation states
- add richer order-board, lamp, crate, and path presentation around the runtime market art
- consider a first texture pass for dock/plaza readability

## Phase 4.5: Active Fishing

Status: zone reward and warning bridge complete.

Goal: make catching fish as satisfying and readable as processing and selling them.

Needs:

- [x] visible swimming fish agents
- [x] player boat at the dock
- [x] tap water to target the boat as a fallback
- [x] visible net behind the boat
- [x] fish collision with the net
- [x] net capacity
- [x] return-to-dock unloading into pools
- [x] net upgrades that visibly increase capacity/size
- [x] drag boat steering
- [x] fish species-specific movement personalities
- [x] boat upgrades beyond net level
- [x] split more fishing code out of `main.gd`
- [x] fishing zones such as shallow, cold, deep, and monster water
- [x] zone-specific rewards and warnings before danger

Implemented:

- added first dedicated fishing helper script at `scripts/fishing/FishAgent.gd`
- water now has continuous swimming fish agents drawn over the tile grid
- Catch tool now steers the boat to tapped water instead of instantly collecting from a water tile
- drag input on water now continuously updates the boat target for phone-friendly steering
- boat pulls a visible circular net behind it
- fish entering the net are collected into boat stock up to net capacity
- HUD shows boat/net stock as `Boat:x/y`
- tapping the dock returns the boat; docked boat unloads live fish into pools when there is capacity
- net level now increases active net capacity and visible net size
- minnows wiggle, carp cruise, and silverfish dart away from the boat
- `scripts/fishing/BoatAgent.gd` now owns boat movement, target, direction, stock, level, speed, and net capacity math
- Boat upgrades now cost money, count as upgrades, improve movement speed, improve net hold capacity, and add small visual boat details
- water tiles now have shallow, open, cold, deep, and monster zones
- zones use distinct procedural placeholder visuals inspired by the generated water reference sheet
- zones affect active fish spawn position, fish species mix, and fish movement speed pressure
- water inspector text explains each zone's current gameplay meaning
- cold, deep, and monster routes now pay one-time first-catch exploration bonuses
- monster water now builds a visible warning meter near the boat without damaging the player yet
- catch and store goals work through active fishing because net catches count as caught fish and dock unloading counts as stored fish

Next:

- tune fishing-zone layout, fish mix, and spawn weights after playtesting
- start Phase 5 with a visible cold meter or cold-wave timer
- connect monster-water warning to the first real monster/counterplay loop later
- keep boat, net, fish, and water-zone graphics procedural until their active-fishing silhouettes are ready for the next runtime art pack

## Phase 4.6: Larger World And Territorial Expansion

Status: first large-map slice complete.

Goal: make the fishery feel like a place that can grow into a settlement, not a single-screen puzzle board.

Needs:

- [x] larger world with room for future production, trade, defense, and trucks
- [x] readable phone-sized map viewport instead of tiny full-map tiles
- [x] map panning controls
- [x] central starter district with a working shore, plaza, and trade lane
- [x] a broad expansion frontier
- [x] connected territorial expansion rules

Implemented:

- the board grew from 8x10 to a 16x18 world map
- the player now sees a readable camera-sized slice of the world rather than a shrunken full board
- the Map tool pans across the fishery; Center returns to the starter district
- the starting layout now has four rows of water, a dedicated dock, a central starter district, a plaza-to-market route, and a road trade lane
- most land outside the starter district begins as locked frontier, leaving substantial space for the later industry, defenses, and truck systems
- expansions must connect to owned land, dock, plaza, or road, so the base grows outward as a coherent territory
- all existing boat, fish, worker, buyer, building, and order-board logic now uses world coordinates and follows the camera

Next:

- playtest camera size, panning feel, starter-district size, frontier prices, and fish-zone placement
- add a minimap or landmark navigation only after the world becomes large enough to justify it
- begin Phase 5 cold pressure after this spatial foundation has settled

## Phase 4.7: Manual Fisherman Foundation

Status: first manual-first slice complete.

Goal: make the player character and physical handoffs the heart of the first minutes.

Needs:

- [x] one visible player character on the map
- [x] tap-to-move walking on owned land, dock, plaza, and road
- [x] manual shore catches with a small fish basket
- [x] visible carried fish and meat state
- [x] player-delivered pool handoff
- [x] player-operated cutter before cutter automation
- [x] player-to-buyer hand sale before market automation
- [x] no starter worker
- [x] worker hiring delayed until the manual loop is proven
- [x] boat hidden until its progression unlock
- [x] fisher worker visibly catches, carries, and unloads fish

Implemented:

- added `scripts/people/PlayerAgent.gd` for the controllable fisherman
- Walk sends the fisherman to a tapped walkable surface
- Fish catches a visible nearby fish while the fisherman is at the dock; the basket holds three fish
- pools accept hand-carried fish automatically when the player arrives
- the player manually operates cutters and carries up to three meat to a market
- a waiting villager receives hand-delivered meat and pays the fisherman directly
- the starter cutter and market no longer run automatically; a worker assigned to each station is now the automation switch
- the first worker starts absent, costs $150, and unlocks only after Net 2 plus four hand sales
- Net 2 now unlocks the boat and offshore fishing; the boat does not render or respond before that point
- early prices now support the intended rhythm: $12 hand sales and a $50 first net upgrade
- water workers now walk to the dock, fish, visibly carry their catch, walk to the nearest pool, unload, and return to the water
- worker state text and carry bubbles show fishing, delivery, and blocked-pool states
- first runtime art pack now replaces procedural people, pool, cutter, and market placeholders with transparent generated sprites directed by the supplied visual boards; selection, wants, carry state, and progress remain readable code-drawn overlays

Next:

- refine player movement into path-aware movement around buildings and visible interaction ranges
- add level-specific visual variants for the pool, cutter, market, net, and boat upgrades
- replace individual frontier purchases with named area-unlock gates and visible reveal moments
- delay Phase 5 danger until these manual and automation handoffs feel good in playtesting

## Phase 5: Danger

Status: deferred until the manual-first progression loop is proven.

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

## Phase 6: Automation And Trucks

Status: planned.

Goal: make the base feel like a growing business.

Needs:

- workers or conveyors
- truck stop
- bulk orders
- advanced machines
- production planning

## Phase 7: Mobile Release Polish

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
