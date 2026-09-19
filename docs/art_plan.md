# Art And Texture Plan

The game should stay procedural and placeholder-heavy until the layout rules are fun. Real generated art is useful, but only after the gameplay tells us what needs to be readable on a phone screen.

## When To Generate Art

### Phase 1: Fun Core

Use code-drawn placeholders only.

Reason:

- tile size and UI density are still changing
- we need to prove the catch -> store -> process -> sell loop first
- generated art would be replaced too quickly

### Phase 2: Layout Game

Start defining the visual language, but keep assets lightweight.

Generate or draw a first small texture set after the Phase 2 mechanics are playable:

- shallow water tile
- buildable land tile
- dock tile
- plaza tile
- road tile
- pool building
- cutter building
- market building
- simple fish icon
- money, meat, and buyer icons

The goal is readability, not final polish.

### Phase 3: Progression

Generate the first real content pack.

Needed assets:

- 3-5 fish types
- upgraded building variants
- storage, freezer, net, and dock buildings
- simple buyer figures
- resource icons for oil, bones, scales, fuel, and scrap

This is the right point to create a cohesive style sheet because the unlock tree will define what the player sees repeatedly.

### Phase 5: Danger

Generate threat and weather assets.

Needed assets:

- small pool-stealing monster
- cold crawler
- wall, fence, trap, and turret buildings
- frozen tile overlays
- warning markers
- damage and repair icons

### Living Base Pass

Generate this before final danger polish if the people layer becomes the main feel target:

- worker figure variants
- buyer figure variants
- staffed market/stall props
- dock order board sign
- hand cart or carrying pose
- dock lamps and signboards
- crates, fish racks, and small trade details
- simple path/plaza overlays so people movement reads clearly

### Active Fishing Readability Pass

Do this before final danger polish because fishing is now a signature interaction:

Status: core runtime sprite pass implemented.

- [x] small player boat
- [x] readable minnow, carp, and silverfish sprites
- [x] directional boat and fish rendering
- [x] wake, ripple, and net-fill feedback
- [x] visible trailing net with empty, partly full, and full states driven by real stock
- [x] dock-unload feedback from the existing popup and stock systems
- [x] shared water tile art with shallow, cold, deep, and monster zone tinting

The boat and fish are transparent runtime sprites. The net stays procedural for now: its radius, buoy count, fill tint, visible caught fish, and tow line all reflect its real capacity and stock. This is clearer than a fixed raster mesh while upgrades are still changing the net size.

### Phase 6: Automation And Trucks

Generate logistics assets.

Needed assets:

- worker figure
- cart or conveyor
- truck stop
- delivery truck
- bulk order UI icons
- advanced machine variants

### Phase 7: Mobile Release Polish

Replace or refine rough assets.

Needed polish:

- final tile atlas
- final UI icon set
- touch-friendly button icons
- animation frames
- splash and app icon assets
- store screenshots

## Style Direction

The style should be readable, cozy-gritty, and slightly strange:

- chunky shapes
- clear silhouettes
- cold water colors balanced with warm machine lights
- visible steam, bubbles, and chopping motion
- enough contrast for phone screens

Avoid tiny detail. Every asset must read at phone size.

## First Runtime Art Pack

Status: implemented as a focused visual upgrade, not a final atlas.

The generated images in `assets/pics/` are valuable art-direction boards. They establish the cold-blue water, warm timber, orange fishing gear, snowy dock pieces, character silhouettes, fish, and market style. They are not suitable for direct runtime use because each sheet contains labels, opaque presentation backgrounds, multiple scales, and several unrelated assets.

The first runtime sprites were generated from that direction, cleaned to transparent PNGs, resized to 384px sources, and placed in `assets/runtime_art/`:

- `fisherman.png` for the player and hired workers
- `villager.png` for visible buyers
- `live_pool.png` for pool buildings
- `cutter.png` for manual and staffed processing stations
- `market.png` for selling stalls
- `boat.png` for active offshore fishing
- `minnow.png`, `carp.png`, and `silverfish.png` for visible catches
- `tiles/water.png`, `tiles/dock.png`, `tiles/plaza.png`, `tiles/road.png`, `tiles/land.png`, and `tiles/frontier.png` for the live map surface
- `dock_lamp.png` and `dock_order_board.png` for the first dock landmarks

`scripts/main.gd` now draws these assets over the same entity and building positions that previously used procedural placeholders. Selection rings, carry bubbles, buyer wants, progress bars, rules, and touch controls remain code-drawn so the art does not obscure gameplay state.

The boat and fish now rotate from their real movement direction. The boat has code-drawn wake and upgrade indicators, while the net remains capacity-aware procedural rendering. The terrain pack is a shared visual baseline: zone tints preserve water gameplay readability, and the map remains clear at phone scale. Storage, smoker, production-level variants, and additional dock dressing still need their own production assets once their gameplay presentation and scale are proven in regular playtests.

Next art milestone:

Create upgrade-aware production art: visual levels for the pool, cutter, market, net, and boat, plus storage and smoker sprites. Follow with crates, fish racks, and market-stall dressing to make the growing base feel inhabited. Keep the larger concept sheets as reference only; runtime assets should remain isolated, transparent where appropriate, and sized for their gameplay footprint.
