# Coldwater Catch

A Godot 4 mobile prototype for a tile-based fishing and processing game.

## Run

Open this folder in Godot 4.7.2 or newer and press Play.

The current prototype is intentionally small:

- drag on water with the Catch tool to steer the boat
- sweep visible fish into the net, then tap the dock to unload into pools
- a starter pool, cutter, and market are already placed
- build extra pools, cutters, and markets on buildable land, dock, and plaza tiles
- dock and plaza tiles make the base read like a working wharf
- tap a pool with Catch selected to deposit any carried fish
- cutters automatically process live fish into meat
- markets automatically serve waiting buyers
- follow the goal line to complete the Phase 1 loop
- use Move and Remove to improve your tile layout
- pools work better beside water, cutters work better beside pools, markets work better beside roads
- markets get extra flow from plaza access too
- buyers now walk to markets as visible people, wait, buy, and leave
- villagers, cooks, and merchants have different visible wants
- cooks pay more for smoked meat, while merchants buy bulk orders
- a dock order board posts timed larger orders after merchant trade is proven
- use the People tool to select and assign workers
- hire more workers with the Hire button
- workers can auto-fish, staff pools, speed cutters/smokers, and serve more market buyers
- unaffordable build and upgrade buttons are tinted, and upgrade buttons show current prices
- water now has visible swimming minnows, carp, and later silverfish
- shallow, open, cold, deep, and monster water affect fish mix and movement
- minnows wiggle, carp cruise, and silverfish dart away from the boat
- fish species use different colors and produce different meat yields
- Net level 2 unlocks silverfish and increases the visible boat net capacity/size
- Boat upgrades improve travel speed, increase the net hold, and add small visual details
- catching silverfish unlocks Storage, which increases meat capacity
- building Storage unlocks Expand, which buys edge ground into buildable land
- steady sales unlock the Smoker, which turns meat into higher-value smoked meat
- the goal chain now carries the player through the first progression branch

## Design Docs

- `docs/design_plan.md` defines the game plan.
- `docs/implementation_phases.md` tracks the build phases.
- `docs/art_plan.md` explains when generated figures and textures should happen.
- `docs/graphify_evaluation.md` records the Graphify test and current GDScript limitation.

## Local Godot Install

Godot was installed through WinGet as `GodotEngine.GodotEngine`.

If the `godot` alias is not visible in an already-open terminal, restart the terminal or use the installed executable under:

`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe`
