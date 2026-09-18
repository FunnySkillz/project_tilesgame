# Implementation Phases

This file tracks how the design plan is being turned into playable builds.

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

Status: in progress.

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

Next:

- add clearer affordability states
- add stronger market/customer pressure
- add optional building move cost or late-game free relocation
- decide whether production should use adjacency only or explicit paths

## Phase 3: Progression

Status: planned.

Goal: give the player reasons to keep expanding.

Needs:

- unlock tree
- multiple fish types
- new buildings
- land expansion
- first 30-minute goal chain

## Phase 4: Danger

Status: planned.

Goal: make the world feel dangerous and memorable.

Needs:

- cold system
- night attacks
- fences, traps, and weapons
- repair mechanic
- rare monster resources

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
