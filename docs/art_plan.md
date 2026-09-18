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

- small player boat
- visible trailing net in empty, partly full, and full states
- readable minnow, carp, and silverfish sprites
- simple wake, ripple, and net-catch effects
- dock-unload feedback
- shallow/cold/deep water tile variants once fishing zones exist

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

## Current Decision

Do not generate final textures yet.

Phase 2 layout mechanics are readable enough to support a first texture pass, and Phase 3 now has fish species, Storage, land expansion, and the Smoker branch. Phase 4 added workers, visible buyers, and dock orders. Phase 4.5 now has active boat fishing, so the first cohesive pack should include the boat, net, fish readability, workers, buyers, and market-life props instead of only tiles and machines.

The boat upgrade path currently uses procedural details only. Keep it that way until fishing zones prove what boat silhouettes and net states must communicate at phone size.

The generated images in `assets/pics/` are useful as style and asset-direction references. Treat them as concept boards for palette, fish silhouettes, boat/net states, water-zone treatments, dock pieces, people, and props. Do not use the full images directly in-game because they include labels, backgrounds, mixed scales, and multiple assets per sheet. The production version should be transparent PNG sprites or atlases made from this direction.

Next art milestone:

Generate a small prototype texture pack after active fishing zones and boat upgrade silhouettes are stable. The first pack should cover water, land, dock, plaza, road, expansion ground, pool, cutter, market, storage, smoker, dock order board, boat, net, worker, buyer, minnow, carp, silverfish, meat, smoked meat, money, crates, lamps, and market props.
