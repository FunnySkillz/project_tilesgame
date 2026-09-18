# Graphify Evaluation

Graphify is a good fit for the long-term goal of keeping the project understandable as it grows, but it has an important limitation for this project today.

## What Was Tested

Installed locally:

- `uv`
- `graphifyy`, which provides the `graphify` CLI

Command tested:

```powershell
graphify extract . --code-only --no-cluster
```

Result:

- Graphify produced an empty code graph.
- It skipped the Godot files because `.gd`, `.tscn`, and `project.godot` are not currently supported code formats.

Skipped files included:

- `scripts/main.gd`
- `scenes/Main.tscn`
- `project.godot`

## Why This Matters

The project's core logic is currently in GDScript. Graphify's local AST extraction is useful when the code is in a supported language, but it cannot currently see the structure of our main gameplay script.

Out of the box, Graphify can still help with:

- Markdown design docs
- future JSON sidecar architecture files
- supported tooling scripts, if we add them
- cross-repo/project documentation maps

But it should not be treated as the source of truth for GDScript structure yet.

## How We Should Use It

Use Graphify as a project-map companion, not as the only architecture tool.

Recommended workflow:

1. Keep high-level design and implementation phases in `docs/`.
2. Add lightweight architecture documents before major refactors.
3. Split the current one-file prototype into smaller Godot scripts once Phase 3 stabilizes.
4. Add explicit `# WHY:` or `# NOTE:` comments only around important design decisions, because Graphify can promote rationale comments into graph nodes in supported files and docs.
5. Optionally create a generated JSON architecture sidecar later, such as `docs/architecture_graph.json`, so Graphify and other tools have a stable, language-neutral view of systems.

## Refactor Targets

The graphing need confirms that the current `scripts/main.gd` should eventually split into:

- `GameState.gd`
- `GridManager.gd`
- `Simulation.gd`
- `FishCatalog.gd`
- `BuildingCatalog.gd`
- `HudController.gd`
- `DrawDebugView.gd` or dedicated scene/node drawing scripts

Do not do this too early. The prototype is still changing quickly. The right time is after the Phase 3 progression loop has land expansion and the first 30-minute goal chain.

## Decision

Use Graphify later, but do not depend on it for GDScript code mapping yet.

Near-term architecture hygiene should come from:

- smaller scripts after Phase 3 stabilizes
- data-driven catalogs for fish/buildings
- explicit docs for systems and unlocks
- regular Godot headless load checks
