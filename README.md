# Coldwater Catch

A Godot 4 mobile prototype for a tile-based fishing and processing game.

## Run

Open this folder in Godot 4.7.2 or newer and press Play.

The current prototype is intentionally small:

- tap water with the Catch tool to collect fish
- a starter pool, cutter, and market are already placed
- build extra pools, cutters, and markets on land
- tap a pool with Catch selected to deposit carried fish
- cutters automatically process live fish into meat
- markets automatically sell meat to customers
- follow the goal line to complete the Phase 1 loop
- use Move and Remove to improve your tile layout
- pools work better beside water, cutters work better beside pools, markets work better beside roads

## Design Docs

- `docs/design_plan.md` defines the game plan.
- `docs/implementation_phases.md` tracks the build phases.
- `docs/art_plan.md` explains when generated figures and textures should happen.

## Local Godot Install

Godot was installed through WinGet as `GodotEngine.GodotEngine`.

If the `godot` alias is not visible in an already-open terminal, restart the terminal or use the installed executable under:

`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe`
