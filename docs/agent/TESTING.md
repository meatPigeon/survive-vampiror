# Testing

Run from the project root with Godot 4.7. No external test addon is needed.

## Automated Checks

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/prototype_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/reinforcement_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/reinforcement_visual_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/ui_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/zombie_animation_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/knight_animation_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/targeting_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_balance.gd --fixed-fps 60
godot --headless --path . --script res://tests/character_assets.gd
godot --headless --path . --script res://tests/audio_smoke.gd
```

Import first on a fresh checkout to register classes. Each test must print PASS,
exit 0, and produce no script errors; exit status alone is insufficient because
Godot may continue after a script error.

- **Prototype smoke:** combat-disabled fixture for initial crowd, real mouse
  projection, rejected input, movement, redirect, separation, corner clamps,
  resize, model instances, facing and idle/run transitions. Viewport checks at
  16:10, 16:9, 4:3 and 21:9 assert full-window rendering, visible arena corners
  and character heads, accurate clicks, and rejection of the visual surround.
  Capture mode also saves `/tmp/survive_vampiror_viewport_*.png`.
  Corner destinations/resize edges use actual floor bounds. The corner allows
  a 5.5-unit gathering radius because separation packs 40 agents into a quarter
  of the floor; central targets retain 5.0. Both retain minimum pair separation
  and per-agent boundary assertions.
- **Combat smoke:** health/death contract, bite range/cooldown, sweep arc,
  escaping a warning, charge movement and fixed warning, no repeated charge
  hits or hits beyond the rectangle, spin radius, HP phase thresholds, immediate
  death removal, reserve occupation/interruption/capacity, actual sprint
  speed and cooldown, first-command start, pause/resume, restart from pause
  including physical-key handling, both results and stopped combat.
- **Reinforcement smoke:** permanent starters, first-command scheduling, inactive
  sites, full rotation and skipped windows, discarded leftovers/progress,
  retained permanent HP, lifetime on-site and across switches, independent
  batches, simultaneous expiry, expiry before combat and same-tick recruitment,
  combat death versus expiry statistics, defeat with temporary survivors,
  immediate stop within a knight hit loop, pause/resume, victory freeze and reset.
  Render with `-- --capture` for `/tmp/survive_reinforcement_*.png`.
- **Reinforcement visual smoke:** persistent inactive craters, staggered rise/sink,
  pause in both directions, repeated updates, full-cycle stock refresh, immediate
  closure, reversal, same-frame opening/exhaustion, retained stock at capacity,
  outcome settling and restart cleanup. Site roots and stock remain authoritative.
  Render with `-- --capture` for close-ups at
  `/tmp/survive_graves_{inactive,rising,active,sinking,closed}.png`.
  Add `--wide` after `--capture` to retain the arena camera/HUD and write
  `/tmp/survive_graves_wide_*.png` instead.
- **Audio smoke:** initial silence, loaded non-looping clips, one voice per
  category, distinct attack warnings, confirmed hits versus misses, one contact
  per multi-victim attack, throttled bites/casualties/recruitment, no combat grunt on expiry,
  grave rotation/depletion, actual-travel footsteps, command throttling, accepted
  versus rejected sprint, bite contact and batched expiry. Pause, both outcomes,
  one-shot result cues and restart cleanup are covered. Run without
  `--fixed-fps`: audio playback follows wall-clock time rather than accelerated
  simulation time. On the Linux test desktop, use
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/audio_smoke.gd -- --record`
  to record the Master bus through these scenarios and 12 seconds of actual
  viewport-click combat to `/tmp/survive_audio_check.wav`; the arena frame is
  `/tmp/survive_audio_battle.png`. No microphone or API call is used.
- **UI smoke (UI branch):** real viewport clicks for pause/resume/sprint/replay,
  modal command blocking, pre-start state, cooldown display, frozen gameplay,
  permanent-count warning, contextual visibility, health trail pause behavior,
  victory/defeat controls, reset and small-window layout.
  Render via `godot --path . --script res://tests/ui_smoke.gd --fixed-fps 60 -- --capture`;
  screenshots are `/tmp/survive_ui_{ready,pause,victory,critical,defeat,small}.png`.
- **Zombie animation smoke:** movement/sprint lean and cadence, banking, idle
  settling, head/torso bite contact, recoil/flash cleanup, unchanged gameplay
  roots, pause freeze, immediate gameplay death and delayed visual cleanup for
  both damage and expiry. `--capture` writes close-up frames at 20 fps into
  `/tmp/survive_zombie_frames/`.
- **Knight animation smoke:** distinct loaded/contact poses, exact impact seek,
  preserved attack/follow-through during charge and recovery, locked facing,
  finite poses, rest restoration, pause and visual-only death. `--capture`
  writes pose sheets; add `--motion` for `/tmp/survive_knight_motion/` at 30 fps.
- **Targeting smoke:** nearby singleton versus larger reachable group for sweep
  and charge, unreachable distractions, matching knight/warning direction, actual
  group damage, aiming a sector between groups, and locked direction after the
  crowd moves during windup. `--capture` with a graphical Godot run saves
  `/tmp/survive_targeting_sweep.png` and `charge.png` (same filename prefix).
- **Combat balance:** actual viewport mouse/keyboard input. Passive and reckless
  chasing must lose; active pilots with 0.37 and 0.50 s reaction delays must win
  within five minutes with permanent survivors, visit all phases/attacks and
  use temporary reinforcements. The fixture registers its current scene, and
  the pilot stops sending commands immediately on outcome so a final ground
  click cannot activate replay through the result modal. The pilot reacts to visible warning geometry and named
  attack type, visits the active site when fewer than eight temporary zombies remain and
  the visible window allows travel/occupation, and uses sprint when dodging
  charges/spins. It abandons a site when inactive, exhausted or the horde is full. It never teleports agents or changes HP in full runs.
- **Character assets:** unchanged GLB skin binding, idle/run names/durations,
  looping, root stability and foot/head motion.

Prior jam baseline (`5064113`) headless results: passive defeat 71.0 s, reckless chase defeat 46.2 s;
active wins 174.5/178.6 s with 29/30 survivors and 24/36 recruits. Exact results
can differ with input projection or tick phase; the tests assert meaningful
outcomes rather than exact frame counts. This is a practical starting balance,
not an exhaustive optimization or a human playtest. The rendered run also
passed: passive loss at 71.0 s, active win at 178.4 s with 26 zombies and 24
recruits. All attack types, reserves and outcomes were visually inspected.

## Rendered Gameplay

```sh
godot --path . --script res://tests/combat_balance.gd --fixed-fps 60 -- --capture
```

Runs the passive case and one complete active run in the actual renderer.
Captures go to `/tmp/survive_jam_*.png`, including start, each attack type,
reinforcements and results. Inspect warning geometry, the charge's fixed lane
and moving knight, spin, readable recruitment state, crowded combat and outcomes.
These are temporary test artifacts, not shipped assets. Rendering with fixed
simulation FPS can take longer than the reported in-game time.

For the isolated crowd regression captures:

```sh
godot --path . --script res://tests/prototype_smoke.gd --fixed-fps 60 -- --capture
```

## Manual Check

Launch `godot --path .` or F5 in the editor.

1. Confirm the arena waits while you read controls; first click starts the fight.
2. Command/redirect the whole horde. Space accelerates toward its current target,
   and repeated presses do not bypass the cooldown.
3. Dodge the orange sector sideways, leave the yellow charge lane, and retreat
   outside the purple circle. Return during recovery to bite the knight.
4. Rally at the crater with raised gravestones for two seconds. Confirm blue-ring
   recruits, lifetime countdown, cap 60 and partial stock. Leave mid-summon to
   interrupt it.
   Check west/south/east rotation every 30 seconds and discarded old stock.
   Stones should rise on opening and sink on closure/exhaustion; empty craters
   remain on the floor and do not obstruct the horde.
   White-ring permanent zombies must retain health and never expire.
5. Play through the HP phase thresholds; confirm the later attack patterns.
6. Pause during a warning and recruitment; verify gameplay/animations/timers
   freeze, including recruit lifetimes and the site schedule. Resume or restart. Test with a non-English keyboard layout too.
7. Kill the knight, or lose the last permanent while temporary zombies survive.
   Confirm result, separate killed/expired statistics and stopped combat/timers.
8. Restart; verify full HP, 40 permanent zombies, zero temporary zombies, phase 1,
   inactive sites, cleared statistics and ready sprint.
9. Listen for distinct warning pulses, swing/hit/bite sounds, sparse grunts and
   grave motion. Steps follow movement; commands, sprint, recruitment and expiry
   have cues. Confirm pause freezes voices, outcome leaves only a result cue and
   restart clears it; assess the mix by ear.

Record actual results in [PROJECT_STATE.md](PROJECT_STATE.md). Distinguish
scripted input and screenshot inspection from human playtesting.

## Blender Sources

Only needed when changing the editable character sources:

```sh
blender --background --factory-startup --python tools/verify_characters.py
godot --path . --script res://tools/preview_characters.gd --fixed-fps 30
```

See [the asset guide](../../art/characters/README.md) for rebuild and preview
instructions. No Blender changes were needed for this gameplay iteration.


Targeting-fix verification (2026-09-30): all headless checks above pass, and the
focused targeting test also passes in the renderer with sweep/charge captures
inspected. Full-run outcomes are passive defeat 51.2 s, chase defeat 39.3 s,
active wins 184.4/186.6 s with 32/25 zombies and 36 recruits. Progression tuning
was not changed. Tests also cover visual facing after a charge endpoint clamps
at a corner. Earlier baseline numbers above remain historical comparisons.


Temporary-recruit verification (2026-09-30): current headless active wins take
206.8/226.4 s (0.37/0.50 s reactions), retaining 11/6 permanent zombies plus
11/12 temporary zombies; 48/60 recruited and 29/39 expired. Passive/reckless
runs lose at 51.2/39.3 s. Earlier results above describe the previous finite
reinforcement rules. Focused rendered checks and the complete rendered run
pass: passive defeat at 51.2 s, active victory at 201.5 s with 11 permanent and
10 temporary survivors, 48 recruits and 30 expirations. Startup, mixed kinds,
pause, all warnings, recruitment and both outcomes were inspected. The full
rendered and headless tests use scripted input, not a human playtest.


UI branch verification: import, UI/combat/movement checks, rendered reinforcement
checks and headless full balance pass. The rendered UI input test passes;
1280 × 800 and 960 × 600 layouts and all modal/critical states were inspected.
Gameplay tuning and headless full-run results match the temporary-recruit version.


Animation/HUD revision: focused animation and existing combat, recruitment,
movement, targeting and UI checks pass. Rendered close-up zombie gait/bite/hit/
death frames and all three knight attack comparisons were inspected. Headless
full-run results remain unchanged. Integrated rendered verification passes:
passive defeat at 51.2 s and active victory at 201.5 s with 11 permanent and
10 temporary survivors, 48 recruits and 30 expirations. Arena warnings,
recruitment and outcomes were inspected. The full rendered check used
`--disable-vsync` to avoid display throttling; project settings remain unchanged.


Larger-arena/environment verification: editor import, headless/rendered prototype
checks (including all four window ratios and the enlarged corner), combat,
targeting, reinforcement and rendered UI checks pass. All large rock mesh bounds
are outside the playable 60 × 44 rectangle. Headless active runs win at
210.2/202.8 s with 8/5 permanent and 12/10 temporary survivors; passive/chase
still lose at 51.2/39.3 s. The full rendered run passes at 209.3 s with 9 permanent
and 12 temporary survivors. Terrain, warning readability, recruitment, outcomes,
corner gathering and resized views were inspected. No human playtest is claimed.
