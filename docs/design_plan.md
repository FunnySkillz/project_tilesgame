# Coldwater Catch Design Plan

## Core Promise

Coldwater Catch is a portrait-first character-driven fishing-business game about starting as one person with a basket and growing a tiny hand-run fishing spot into a strange, efficient, dangerous cold-water fishery.

The player fantasy is:

> I started by doing every job myself. Now I can see the fishery working because of the people and machines I earned.

The stronger visual target is a living coldwater dock settlement: workers hauling fish, buyers walking in, lamps glowing, stalls trading, and the base feeling like a small hard-working community at the edge of dangerous water.

The game should become enjoyable when the player constantly thinks:

- I can do this job faster with one more upgrade.
- I have earned someone or something that can take this job over.
- I can expand into danger now, or prepare first.
- This base feels like mine.
- My people are busy, useful, and worth protecting.

## Main Fun Pillars

### 1. Manual Work Becomes Automation

The player begins as the worker. The first loop must be readable enough to do with almost no UI friction:

Walk to water -> catch fish -> carry fish -> cut fish -> carry meat -> hand it to a buyer.

Only after the player understands and feels that loop should automation arrive:

Player fishing -> hired fisher -> processing worker -> staffed market -> boat -> industrial line.

Even simple visuals should communicate state:

- fish appear in water
- the player visibly carries fish and meat
- fish visibly enter a basket or net
- pools visibly fill and empty
- a cutter visibly works while a person is there
- buyers arrive, wait, buy, and leave
- money and resources pop with clear feedback

The base should feel alive, even before advanced automation exists.

### 2. Place And Expand, Do Not Spreadsheet

The grid is a world and placement scaffold, not the main challenge. The game should not ask the player to solve exact adjacency puzzles before they have a working business.

The playable world should feel like a settlement site, not one static screen. The current prototype uses a 16x18 world viewed through a phone-sized camera: the player begins around the dock and plaza, then pans outward and claims connected frontier tiles. This leaves genuine room for later industrial yards, defensible shorelines, truck access, and specialized districts without reducing every tile to an unreadable speck.

Good placement should be visually natural and lightly rewarding:

- pools near water reduce handling friction
- cutters near pools make processing feel natural
- markets near roads improve sales
- freezers near storage reduce spoilage risk
- heaters protect cold-sensitive production zones
- defenses cover monster paths and vulnerable pools

The main spatial decision is when to buy a new usable area. Each expansion should reveal a concrete next piece of the fishery rather than merely one more empty square: processing yard, second dock, freezer yard, truck loading, then deep-water access.

### 3. Living People And Trade

The base should feel populated early.

The player character is the first person the player cares about. Other people should then repeat the work the player has already done:

- the player walks, carries, cuts, and sells at the start
- fishers visibly walk to the dock, catch, carry, and unload after being hired
- processing and market workers take over familiar manual handoffs
- buyers physically arrive, wait, buy, and leave
- more successful selling attracts more foot traffic
- later, different buyers should want different goods

The player should read the economy by watching people move through the fishery.

### 4. Meaningful Upgrades

Upgrades should change how the game feels, not only increase numbers.

Examples:

- better net catches multiple fish
- better boat moves faster and holds more fish before docking
- reinforced pool can hold aggressive fish
- larger cutter can process bigger fish
- freezer prevents spoilage
- road unlocks truck buyers
- heater allows frozen tiles to keep working
- harpoon unlocks dangerous fish
- trap or turret protects pools from attacks

Each upgrade should answer a real pain point the player has felt.

### 5. Pressure Without Annoyance

The game needs tension, but not constant punishment.

Pressure systems can include:

- fish and meat spoil if not processed, frozen, or sold
- cold slows machines
- monsters attack at night
- storms damage water-side buildings
- buyers leave if waiting too long
- bigger fish require stronger equipment

The player should feel challenged, not bullied. Early pressure should be soft, readable, and recoverable.

### 6. Discovery

New zones and fish types should unlock new possibilities.

Small fish are mostly meat. Later fish can provide:

- oil
- bones
- scales
- teeth
- monster meat
- rare organs
- cold-resistant materials

New catches should create new production questions instead of just being worth more money.

## Progression Spine

The main release sequence is intentionally simple and physical:

1. Manual fisherman: catch, carry, cut, and sell everything personally.
2. Net upgrade: a visibly larger basket or net carries more fish.
3. First fisherman: repeats the manual fishing route automatically.
4. Processing worker: keeps the cutter working while the player handles trade.
5. Customer crowd: visible buyer flow makes a staffed market worthwhile.
6. Area expansion: unlock a named usable district rather than a disconnected optimisation puzzle.
7. Boat and larger net: reach fish schools farther from shore.
8. Storage, smoker, and freezer: turn volume into better goods.
9. Truck orders: sell large prepared batches.
10. Deep water: introduce valuable fish, cold, and then danger.
11. Monster fishing: unlock special resources and defensive choices.
12. Industrial fishery: multiple crews, large pools, cranes, vessels, and long trade routes.

The rule for every unlock is: the player should manually feel the pain point before the upgrade or person removes it.

## First 30 Minutes

The first 30 minutes are the most important part of the game. The goal is to teach the core loop, create the first interesting decisions, and show the larger promise.

### Minute 0-3: Be The Fisherman

The player starts with water, land, one pool, one cutter, and one market.

They learn:

- walk the fisherman to the dock
- catch a nearby visible fish into a small basket
- bring catches to the pool or cutter
- wait at the cutter while fish becomes meat
- hand meat to a waiting buyer
- money buys upgrades

### Minute 3-8: First Automation

The player earns enough money to feel the first relief:

- upgrade net
- hire the first fisherman after proving hand sales
- watch the fisherman repeat the route the player has been doing

This is the first moment where the player feels that the base is beginning to work for them.

### Minute 8-15: First Area And Boat

The player earns an area unlock and a boat, which opens larger catches and a longer production route:

- a larger net catches whole schools
- a storage or smoker yard opens
- a boat reaches offshore fish that cannot be reached from the dock

This gives the player a visible reason to grow the operation.

### Minute 15-25: First New Mechanic

Unlock cold or spoilage gently.

Example:

- raw meat spoils after a while
- freezer unlocks to slow spoilage
- cold weather reduces machine speed
- heater unlocks to protect nearby tiles

The mechanic should create a clear problem with a clear tool to solve it.

### Minute 25-30: First Threat

A small monster tries to steal fish from pools at night.

The player can respond with:

- fence
- trap
- basic weapon
- light

This shows that the game is not only a factory. It is also a survival fishery in a dangerous place.

## Core Systems

### Grid And Tiles

Tile types:

- shallow water
- deep water
- shore
- buildable land
- frozen land
- road
- resource tile
- monster nest
- dock tile

Each tile needs clear placement rules. The player should understand why something can or cannot be built there.

Current prototype layout rules:

- dock tiles mark the working shoreline and can hold buildings
- plaza tiles mark the trade lane and can hold buildings
- markets gain extra sale capacity from road access and plaza access
- expansion still turns locked edge ground into buildable land

### Buildings

Core buildings:

- Pool: stores live fish
- Cutter: turns fish into meat
- Market: sells goods to walk-in buyers
- Storage: holds processed goods
- Freezer: slows or prevents spoilage
- Net Station: improves catching
- Dock: gives access to deeper water
- Heater: protects nearby tiles from cold
- Wall or Fence: blocks monsters
- Trap or Turret: damages monsters
- Road or Truck Stop: enables bulk selling

Later buildings:

- Smoker: turns meat into smoked meat
- Oil Press: turns fatty fish into oil
- Bone Mill: turns bones into fertilizer or crafting parts
- Bait Maker: turns scraps into bait
- Hatchery: breeds fish
- Repair Station: fixes machines and defenses

### Fish Types

Fish should create different production decisions.

Tier 1:

- Minnow: common, quick to process
- Carp: basic meat
- Silverfish: slightly more valuable

Tier 2:

- Tuna-like fish: larger, needs better cutter
- Eel: valuable but escapes weak pools
- Icefish: cold-resistant and valuable

Tier 3:

- Armored fish: gives scales
- Oilfish: gives oil
- Fangfish: dangerous, gives teeth

Monster tier:

- cold leviathan spawn
- crab beasts
- mutant fish
- night predators

Each new fish should force the player to adapt at least one part of the base.

### Active Fishing

Fishing should be a signature interaction, not only a resource button.

Current direction:

- visible fish swim in the water
- the player begins on foot at the dock with a small basket
- tapping a nearby fish is the first shore-fishing interaction
- Net 2 unlocks the boat, then dragging on water steers it with tap-to-target as a fallback
- the boat drags a visible net behind it
- fish entering the net are caught up to net capacity
- returning to the dock unloads live fish into pools
- net upgrades should visibly increase net capacity and net size
- minnows, carp, and silverfish have different movement personalities
- boat upgrades improve speed and net hold capacity, with small visual details on the boat
- water is split into shallow, open, cold, deep, and monster zones
- water zones affect fish mix, spawn location, and movement pressure
- cold, deep, and monster water pay first-catch route bonuses
- monster water builds a visible warning before real danger systems exist

Later active-fishing depth:

- smoother steering and possible drawn path feedback
- deeper species behavior such as minnow schools, lure/bait reactions, and predator avoidance
- real zone hazards, counterplay, and monster pressure
- boat upgrades for lights, net strength, storage, sonar, and armor

### Buyers And Selling

Buyers create demand and prevent selling from feeling automatic.

Buyer types:

- villagers: buy cheap meat
- cooks: prefer quality cuts
- merchants: buy bulk
- hunters: buy monster parts
- doctors: buy rare organs or oil
- truck buyers: request large timed orders

Markets should not instantly sell everything forever. Demand, waiting, movement, staffing, and preferences make production planning matter.

Buyers should become more visible over time:

- early buyers are simple villagers buying any meat
- cooks prefer smoked meat or high-value fish
- merchants buy in small bulk batches
- later trucks create timed orders

Selling should feel like people coming to the dock, not invisible conversion into money.

Current prototype buyer rules:

- the first villager must be served by the fisherman carrying meat to the market
- villagers want meat and will buy smoked meat only if regular meat is unavailable
- cooks want smoked meat and pay a premium for it
- merchants want several goods and can be served over multiple sale ticks
- visible want bubbles show what each buyer expects before they leave
- the dock order board posts timed larger orders after merchant trade is proven
- staffed markets use spare sales capacity to fill dock orders and earn completion bonuses

### Progression Tracks

Progression should be split into multiple tracks:

- Catching: nets, rods, traps, boats
- Processing: cutters, smokers, oil presses
- Storage: pools, freezers, warehouses
- Base: land expansion, roads, docks
- Survival: heaters, clothing, repairs
- Defense: walls, traps, weapons
- Logistics: workers, carts, conveyors, trucks

Multiple tracks let players choose what kind of problem they want to solve next.

### Automation

Automation should arrive after the manual loop is already fun.

Possible automation:

- auto-net catches fish every few seconds
- worker moves fish from pool to cutter
- conveyor moves meat to storage
- market auto-sells goods
- truck stop handles bulk orders
- repair bot fixes damaged machines

Automation is the reward for understanding the system.

### Threats

Threats should attack the player's economy, not only the player's health.

Monster examples:

- thief creature steals fish from pools
- cold crawler freezes machines
- shell beast breaks walls
- deep-water predator attacks docks
- swarm enemy overwhelms weak defenses

Defense should remain tile-based:

- walls redirect enemies
- traps trigger on paths
- turrets need power or ammo
- lights reduce night attacks
- heaters weaken cold monsters

### Cold System

Cold can become a signature mechanic.

Simple version:

- frozen tiles reduce machine speed
- some buildings stop working if too cold
- heaters warm nearby tiles
- storms increase cold temporarily
- some fish and monsters only appear in cold areas

The cold system should create layout planning without becoming tedious.

## Mobile UX Requirements

The game must feel smooth on a phone.

Requirements:

- portrait-first layout
- one-thumb actions
- large buttons
- tap tile to inspect
- drag to place buildings
- simple build menu
- clear resource bar
- no tiny text
- autosave always
- offline play
- sessions that work for 2 minutes or 30 minutes

The player should never fight the interface. Every common action should be fast and readable.

## Game Feel And Polish

The game needs satisfying feedback:

- water ripples
- fish wiggle
- pool bubbles
- cutter chopping animation
- coins pop when selling
- buyers visibly leave happy or angry
- machines steam in the cold
- warning lights before monster attacks
- clear sound effects for catching, processing, selling, upgrading, and danger

A simple system with strong feedback will feel better than a complex system with dead visuals.

## Development Roadmap

### Milestone 1: Fun Core

Goal: prove the basic loop is enjoyable.

Needs:

- polished tile tapping
- catching fish
- pool storage
- cutter processing
- market selling
- money and upgrades
- simple tutorial prompts

### Milestone 2: Layout Game

Goal: make placement matter.

Needs:

- build, remove, and move buildings
- building ranges
- storage limits
- machine speed differences
- buyer waiting
- better tile inspector

### Milestone 3: Progression

Goal: give the player reasons to continue.

Needs:

- unlock tree
- multiple fish types
- new buildings
- land expansion
- first 30-minute goal chain

### Milestone 4: Living Base And Demand

Goal: make the base feel populated and interactive.

Needs:

- selectable workers
- worker assignment
- visible buyer movement
- buyer patience and preferences
- staffed markets
- richer selling moments

### Milestone 4.5: Active Fishing

Goal: make catching fish as tactile as processing and selling them.

Needs:

- visible swimming fish
- player boat
- visible net
- net capacity
- dock unloading
- net size upgrades
- fish behavior differences
- boat speed and hold upgrades
- fishing zones
- zone-specific hazards and rewards

### Milestone 5: Danger

Goal: make the world memorable.

Needs:

- cold system
- night attacks
- fences, traps, and weapons
- repair mechanic
- rare monster resources

### Milestone 6: Automation And Trucks

Goal: make the base feel like a growing business.

Needs:

- workers or conveyors
- truck stop
- bulk orders
- advanced machines
- production planning

### Milestone 7: Mobile Release Polish

Goal: make it feel like a real phone game.

Needs:

- saving and loading
- settings
- balancing
- sound and music
- animations
- Android export
- performance checks
- tutorial polish

## Avoid Early

Do not add everything at once.

Avoid early:

- huge maps
- complex combat
- too many fish types
- deep story scenes
- multiplayer
- ads or in-app purchases
- complicated crafting trees
- realistic simulation

First make the loop fun. Then add depth.

## Success Test

The prototype is successful if the player says:

> I know exactly what I want to upgrade next.

That feeling is the heart of this game.
