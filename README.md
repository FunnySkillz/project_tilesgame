# Coldwater Catch

A Godot 4 mobile prototype for a character-driven fishing and processing game.

## Run

Open this folder in Godot 4.7.2 or newer and press Play.

The current prototype focuses on the core systems:

- use Walk to move the fisherman across land, docks, plazas, and roads
- use Fish at the dock to catch nearby visible fish into the fisherman's basket
- walk to the pool to drop fish, the cutter to process them, and the market to hand meat to waiting buyers
- the fisherman visibly carries fish and meat; hired fishers visibly carry catches to the pool
- select Map and drag the board to pan around the 16x18 fishery; Center returns to the starter district
- Net level 2 unlocks the boat, then Fish can steer it offshore with drag controls
- a starter pool, cutter, and market are already placed
- build extra pools, cutters, and markets on buildable land, dock, and plaza tiles
- dock and plaza tiles make the base read like a working wharf
- pools accept hand-carried fish; fishers also carry their own catches to pools
- cutters and markets run automatically only when a worker is assigned
- follow the goal line to complete the Phase 1 loop
- use Move and Remove to improve your tile layout
- pools work better beside water, cutters work better beside pools, markets work better beside roads
- markets get extra flow from plaza access too
- buyers now walk to markets as visible people, wait, buy, and leave
- villagers, cooks, and merchants have different visible wants
- cooks pay more for smoked meat, while merchants buy bulk orders
- a dock order board posts timed larger orders after merchant trade is proven
- hire is locked until Net 2 and four hand sales; workers are earned automation
- use the People tool to select and assign workers after hiring them
- workers can auto-fish, staff pools, run cutters/smokers, and serve market buyers
- unaffordable build and upgrade buttons are tinted, and upgrade buttons show current prices
- water now has visible swimming minnows, carp, and later silverfish
- shallow, open, cold, deep, and monster water affect fish mix and movement
- cold, deep, and monster routes give one-time discovery bonuses; monster water shows a warning meter
- minnows wiggle, carp cruise, and silverfish dart away from the boat
- fish species use different colors and produce different meat yields
- Net level 2 unlocks the boat, silverfish, and offshore fishing; later net levels increase boat net capacity/size
- Boat upgrades improve travel speed, increase the net hold, and add small visual details
- catching silverfish unlocks Storage, which increases meat capacity
- building Storage unlocks Expand, which claims connected frontier ground into buildable land
- steady sales unlock the Smoker, which turns meat into higher-value smoked meat
- the goal chain now carries the player through the first progression branch

## Design Docs

- `docs/design_plan.md` defines the game plan.
- `docs/progression_pivot.md` defines the manual-first progression direction.
- `docs/implementation_phases.md` tracks the build phases.
- `docs/art_plan.md` explains when generated figures and textures should happen.
- `docs/graphify_evaluation.md` records the Graphify test and current GDScript limitation.

## Local Godot Install

Godot was installed through WinGet as `GodotEngine.GodotEngine`.

If the `godot` alias is not visible in an already-open terminal, restart the terminal or use the installed executable under:

`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe`
