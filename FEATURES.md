# Features & Roadmap

## Core mechanics

- **Thruster hop** — hold Space to fire thrusters, costs battery, clears gaps.
- **Kickflip tricks** — spin in the air (Left/Right); clean 360° landing scores, bad landing crashes.
- **Battery, not fuel** — drains while driving/thrusting; supercharger pads recharge + checkpoint.
- **Gaps** — can't be driven across, force deliberate thruster use.
- **Planet gravity** — Earth / Moon / Mars change gravity, terrain, gap width.
- **Docking finale** — land slow, level, and hold on the end pad to complete the run.
- **Ludicrous boost pads** — a second, free gap-crossing option on alternating gaps: hit a ground pad at speed for a forward+lift impulse, no battery cost, but less controllable than thrusting.

## Planets

| Planet | Gravity | Terrain | Gaps |
|---|---|---|---|
| Earth | 1.0x | moderate hills | narrow |
| Moon | 0.16x | gentle, long hangtime | wide |
| Mars | 0.38x | rough, uneven | medium |

## Build phases

- [x] **Phase 0 — Terrain**: `planet_data.gd`, `track_generator.gd`. Procedural ground, gaps, pad placement, per-planet visuals.
- [x] **Phase 1 — Car**: `car.gd`. Raycast-wheel suspension, driving, thrust, airborne/trick/crash detection, car-follow camera.
- [x] **Phase 2 — Pads & rules**: `pads.gd` + `main.gd` state machine. Recharge, checkpoints, respawn, dock success.
- [x] **Phase 3 — HUD & menu**: `hud.gd`, `menu.gd`. Planet-select screen, battery/score/distance display, trick popups, crash/dock overlays.
- [x] **Phase 4 — Polish**: ground shading/texture, car visual detail, thruster/trick/charge particles, crash screen shake, synthesized sound (`audio.gd`, no audio files needed).
- [x] **Phase 5 — Git**: `git init`, committed working baseline. (GitHub remote not set up — optional, needs your account.)
- [ ] **Phase 6 — Stretch**: more planets, car upgrades/cosmetics, best-score persistence, mobile touch controls.
  - [x] Second gap-crossing mechanic: Ludicrous boost pads (magenta), alternating with gaps alongside the existing charge pads.

Each phase is built, then tested in the Godot editor, before moving to the next.
