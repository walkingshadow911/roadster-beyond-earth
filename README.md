# Roadster: Orbital Drift

2D physics driving game (Hill Climb Racing-style) starring a flying Tesla Roadster. Drive alien terrain, thrust over gaps, kickflip for points, recharge at supercharger pads, dock at the end to finish.

**Status:** 🚧 in development.

## Run it

1. Install Godot 4.7+.
2. Open this folder in Godot (`project.godot`).
3. Press F5.

## Controls

| Key | Grounded | Airborne |
|---|---|---|
| Right | Accelerate | Flip forward |
| Left | Reverse/brake | Flip backward |
| Space (hold) | Thrust (costs battery) | Thrust (costs battery) |

## Rules

- Battery drains while driving/thrusting. Supercharger pads recharge it and set your respawn point.
- Gaps can't be driven across — thrust over them, or hit a magenta boost pad (on alternating gaps) at speed for a free launch.
- Spin in the air; land wheels-down on a clean 360° multiple to score. Land mid-spin and you crash.
- Earth/Moon/Mars differ in gravity, terrain, and gap width.
- Finish by landing slow and level on the dock pad and holding briefly.

## Where to make changes

| File | Controls |
|---|---|
| `scenes/Main.tscn` | Empty root scene; `main.gd` builds everything else at runtime. |
| `scripts/main.gd` | Game state machine — menu, playing, crash, dock, respawn. |
| `scripts/planet_data.gd` | Per-planet data: gravity, terrain shape, gap width, colors. Edit to tune or add a planet. |
| `scripts/track_generator.gd` | Terrain height, gaps, pad placement. Edit for level/terrain design. |
| `scripts/car.gd` | Driving, thrust, suspension, airborne detection, trick/crash/score logic. Edit for car feel or scoring. |
| `scripts/pads.gd` | Supercharger/dock pad behavior and dock success conditions. |
| `scripts/hud.gd` | Battery bar, score/speed/distance, trick popups. Visual only. |
| `scripts/menu.gd` | Planet-select and crash/dock overlay screens. Visual only. |
| `scripts/audio.gd` | Synthesized sound effects (no audio files) — engine hum, thrust, crash, trick, charge, dock. Edit to change tones/pitches or add new sounds. |

Tunable values (drive force, thrust power, spring stiffness, scoring, etc.) are constants at the top of the file that owns that system.

## Non-code files

- `project.godot` — project settings, start scene.
- `icon.svg` / `icon.svg.import` — project icon.
- `.godot/` — editor cache, not committed.
