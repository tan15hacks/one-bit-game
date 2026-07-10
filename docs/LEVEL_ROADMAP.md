# One Bit Escape — Level Progression Roadmap

The game should introduce one idea at a time, let the player practice it safely, then combine it with previously learned mechanics.

## Tutorial Phase — The First Escape

**Purpose:** Teach the complete basic gameplay loop.

- Objective 1: Move left and right
- Objective 2: Perform a jump
- Objective 3: Collect every bit while avoiding spikes
- Objective 4: Reach the unlocked exit
- Track deaths and objective progress
- Finish with a tutorial-complete summary

## World 1 — Broken Foundations

**Theme:** Basic platforming mastery.

### Level 1: First Steps
- Longer jumps
- More spike patterns
- Optional bit placed on a riskier route

### Level 2: Moving Ground
- Introduce moving platforms
- Teach waiting and timing

### Level 3: Weak Blocks
- Introduce crumbling platforms
- Combine crumbling blocks with moving platforms

### Level 4: The Walker
- Introduce a simple ground-patrol enemy
- Player defeats it by jumping on top or avoids it

### Level 5: Foundation Trial
- Combines spikes, moving platforms, crumbling blocks, and walkers

## World 2 — Locked Circuits

**Theme:** Puzzle-platforming and route planning.

- Floor switches
- Toggle switches
- Colored doors
- Timed gates
- Pushable crates
- Patrolling flying enemy
- Levels with more than one possible route

## World 3 — Light and Shadow

**Theme:** The signature one-bit world mechanic.

- Toggle between black and white world states
- Black platforms are solid in one state
- White platforms are solid in the other state
- State-specific hazards and enemies
- Mid-air switching challenges

## World 4 — Machine Depths

**Theme:** Faster hazards and precision.

- Conveyor belts
- Fans and wind zones
- Lasers with readable timing
- Crushers
- Dash ability
- Armored enemy that requires using hazards against it

## World 5 — The Glitched Core

**Theme:** Mastery and remixing mechanics.

- Corrupted tiles that change behavior
- Teleport gates
- Gravity-flip zones
- Enemy combinations
- Multi-stage final escape
- Boss built from the same readable one-bit mechanics

## Difficulty Rules

1. Introduce only one major mechanic per early level.
2. Show the mechanic safely before using it over hazards.
3. Combine the new mechanic with one older mechanic.
4. End each world with a level that tests everything learned there.
5. Difficult sections should be short and restart quickly.
6. Optional bits may be difficult, but the required route must remain fair.
7. Every death must teach the player what went wrong.

## Planned Level Data Architecture

Each level should eventually define:

- TMX map path
- Level name and world number
- Ordered objectives
- Player spawn and checkpoints
- Required and optional collectibles
- Enabled mechanics
- Enemy spawn types
- Exit requirements
- Best-time and best-death targets

This allows new levels to be added through data and Tiled maps instead of rewriting the core game loop.
