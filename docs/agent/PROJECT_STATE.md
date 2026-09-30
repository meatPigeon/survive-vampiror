# Project State

## Current Stage

Gameplay checkpoint `f6d4513` is preserved on `gpt-full-game-test`; the current
`ui-hud-prototype` branch adds the requested in-game interface and character
animation feel, plus simple low-poly arena surroundings.
Godot 4.7.2, typed GDScript, GL Compatibility,
1280 × 800 startup window. The earlier stationary-knight balance prototype is
preserved in the branch's initial commit `dc63168`.

## Implemented

- One complete encounter: ready state, first-click start, elapsed time,
  three knight phases, victory/defeat statistics, pause/resume and restart.
- A 60 × 44 arena (formerly 44 × 32), fixed-angle camera that fits the window,
  rigged knight and zombie GLBs. Ground continues behind the HUD to the window
  edges. Authored rock clusters frame the perimeter; scrub, low pebbles and
  muted ground patches break up the floor. The surround/props are visual only.
- 40 permanent starters, shared crowd commands/separation/bounds, automatic
  bites and death. Losing the last permanent immediately loses the run.
- Space sprint: 2× speed for 1.4 s, 7 s cooldown; actual run animation follows.
- Knight pursues nearby zombies, aims sweep/charge toward the largest reachable
  group, and warns before attacking. Spin remains omnidirectional. Locked warnings and recovery periods allow counterplay. His HP thresholds
  change attack patterns without interrupting an attack already underway.
- Rotating recruitment: one active site, west/south/east every 30 s, with a
  fresh batch of 12 temporary zombies. Recruits expire 45 s after spawn or die
  earlier from damage. Two-second occupation, cap 60, leftovers retained only
  until the next switch. Timers freeze before start, on pause and after outcome.
- Restrained HUD: slim knight HP/phase bar with a delayed damage trail, grouped
  horde counts, contextual expiry/recruitment info, and discreet sprint control.
  Empty temporary readouts and inactive/exhausted world-site labels are hidden.
  Clickable sprint/pause/resume/replay controls complement existing keyboard input.
  White/blue foot rings distinguish kinds. Results separate kills from expiry.
- Scene-owned state with explicit references/signals; no new framework or plugin.

Rules/tuning are in [SPEC_GAMEPLAY.md](SPEC_GAMEPLAY.md); code ownership is in
[SPEC_ARCHITECTURE.md](SPEC_ARCHITECTURE.md).

## Verification

- Editor import and headless startup pass without errors.
- Window-filling presentation: headless/rendered prototype checks pass at
  16:10, 16:9, 4:3 and 21:9, with corners/character heads visible and correct
  command projection. Rendered views and HUD were inspected; UI and combat
  smoke checks pass. The visual surround does not accept movement commands.
- `prototype_smoke.gd`: crowd command/projection, animation, bounds and separation
  regressions pass with arena combat disabled in that isolated fixture.
- `combat_smoke.gd`: health, bites, warning geometry/timing, charge movement and
  one-hit-per-charge, spin, phase thresholds, death removal, recruitment/cap,
  capacity, sprint speed/cooldown, waiting for input, pause, terminal states and
  replay pass. Restart was corrected to mark input handled before scene removal.
- `character_assets.gd`: source GLB idle/run bindings and animation checks pass.
- Prior jam baseline (`5064113`), `combat_balance.gd`: full mouse/keyboard-driven runs passed. Single-click passive
  play loses at 71 s; chasing without dodging loses at 46.2 s. Active runs with
  0.37/0.50 s reaction delay win at 174.5/178.6 s, with 29/30 surviving zombies
  and 24/36 recruits. Both wins visit every phase and all three attack types.

## Presentation And Limits

The UI branch has a quiet bone/charcoal HUD, serif titles, generous spacing and
modal pause/result screens. The earlier four-card dashboard has been replaced.
Combat markers remain technical placeholders. The arena now has a simple
low-poly environment pass with ordinary mesh materials; no sound or custom
shaders. Large rocks are outside movement bounds and walkable pebbles are only
0.1134 units tall. There is no obstacle collision or procedural map generation.
Blender assets remain
unchanged: one skinned mesh each, 18 deform bones, source foot IK, idle/run
Actions; runtime KnightVisual and ZombieVisual own the new animation responses. See
[the asset guide](../../art/characters/README.md).

The flat-floor/direct-position assumptions remain. Crowd steering is quadratic
and capped at 60; no larger-horde performance claim. Scripted winning runs are
not a human difficulty assessment. These boundaries are not a feature backlog.


The prior jam baseline rendered full-run verification passed under the Compatibility renderer: passive
play lost at 71.0 s; the active run won at 178.4 s with 26 zombies and 24 recruits.
All three attack warnings, reserves, and victory/defeat captures were inspected.
Final startup/pause captures verify the technical HUD, larger reserve labels,
and bottom controls text without covering the west reserve site. No human
playthrough or subjective difficulty approval is claimed.


## Directional Targeting Fix (2026-09-30)

Sweep and charge now select a candidate direction covering the most living,
reachable targets, rather than always aiming at the nearest individual. Sector
edge candidates allow aiming between groups; charge scoring uses its actual
floor-clamped lane. The warning remains locked during windup. Knight facing
matches the clamped charge direction. Pursuit, damage, phases and progression
are unchanged; waves/new weapons are explicitly discussion-only.

Editor import, `targeting_smoke.gd`, `combat_smoke.gd`, `prototype_smoke.gd` and
`combat_balance.gd` pass. Rendered targeting captures were inspected. New full-run
results: passive defeat 51.2 s, reckless chase defeat 39.3 s, active wins
184.4/186.6 s with 32/25 survivors and 36 recruits. Full-run results here are
headless scripted input; graphical inspection covered the focused aiming scenes.


## Permanent Horde And Temporary Recruits (2026-09-30)

The rules above supersede the previous finite-reserve version. Both zombie kinds
retain 30 HP and existing bite/movement stats; knight tuning remains unchanged.
New `reinforcement_smoke.gd` covers schedule cycling, stock discard, permanent
health retention, independent lifetime batches, expiry-before-bites/recruitment,
combat-versus-expiry accounting, immediate loss with temporary survivors,
stopping a strike mid-loop, pause, victory freeze and restart. It passes headless
and the focused rendered checks pass. Movement, combat and targeting checks pass.

Headless full runs pass with actual viewport input: passive loses at 51.2 s,
reckless chase at 39.3 s; active 0.37/0.50 s reaction runs win at 206.8/226.4 s,
with 11/6 permanent and 11/12 temporary survivors. They recruit 48/60 zombies,
with 29/39 expiring, and see all phases and attacks. Starting tuning (45 s life,
30 s windows, batches of 12, knight 3000 HP) required no balance changes.
Full rendered verification also passes: passive defeat at 51.2 s; active victory
at 201.5 s with 11 permanent and 10 temporary survivors, 48 recruits and 30
expirations. Startup, mixed crowd, pause, all attack warnings, recruitment and
both outcomes were inspected. Recruitment HUD was moved to the upper right to
avoid covering the west site. No human playtest is claimed.


## UI Branch Verification (2026-09-30)

`BattleHUD` is a reusable CanvasLayer scene with ordinary Godot controls and
shared StyleBox resources. Arena supplies current state; HUD emits explicit
pause/restart/sprint intent. The modal runs while paused and consumes mouse
clicks; passive HUD elements do not intercept floor commands. No gameplay
parameters changed.

Editor import, `ui_smoke.gd`, `combat_smoke.gd`, `prototype_smoke.gd`, rendered
`reinforcement_smoke.gd` and headless full balance pass. UI checks send actual
viewport mouse events to pause/resume/sprint/replay controls and verify command
blocking, cooldown, pause freeze, critical permanent count and result state.
Rendered ready, mixed, critical, paused, victory, defeat and 960 × 600 captures
were inspected. Full headless wins remain 206.8/226.4 s with 11/6 permanent
survivors; passive losses remain unchanged. No human playtest is claimed.


## Animation Feel And Quieter HUD (2026-09-30)

Knight attacks now have distinct whole-body anticipation, contact and recovery;
charge retains its braced torso over running legs, spin turns the rig below the
locked aiming transform, and combat transitions synchronize the visual clip to
the existing hit timing. Warm, brief hit flashes are throttled on the knight.
Zombies lean/bank with movement, compress/lift with stride, lunge when biting,
recoil on hits and tumble on combat death; expiry uses a softer collapse. Death
removes the agent immediately, with visual cleanup after at most 0.6 seconds.
Original GLBs/Blender sources and gameplay parameters remain unchanged.

Zombie/knight animation tests cover movement/pose changes, root invariance,
impact timing, preserved attack clips, pause and death cleanup. Close-up poses
and motion frames were inspected; clips are available as temporary artifacts.
Combat, movement, recruitment, targeting and UI checks pass. Full headless
results remain identical: passive/chase losses at 51.2/39.3 seconds, active wins
at 206.8/226.4 seconds with 11/6 permanent survivors. The integrated rendered
run also passes: passive defeat at 51.2 seconds and active victory at 201.5 seconds
with 11 permanent and 10 temporary survivors, 48 recruits and 30 expirations.
Arena attack warnings, recruitment and outcomes were inspected with the revised
HUD and motion. No human playtest or subjective feel approval is claimed.

## Larger Clearing And Surroundings (2026-09-30)

The walkable floor is now 60 × 44, 87.5% larger in area. Static environment scenes
add faceted rocks, scrub/grass, low pebbles and layered ground patches. Large rock
mesh bounds all stay outside the playable rectangle (minimum clearance 0.433).
Flat ground patches sit below foot markers and warning meshes. Combat parameters,
actor starts and recruitment positions are unchanged; camera framing follows
the larger floor and retains full-window coverage.

Editor import, headless/rendered movement and four-aspect resize checks, combat,
targeting, reinforcements and rendered UI checks pass. New-corner gathering
settles at 5.02 maximum distance with 0.58 minimum pair separation; all agents
stay inside bounds. Headless passive/chase losses remain 51.2/39.3 seconds;
active 0.37/0.50-second pilots win at 210.2/202.8 seconds with 8/5 permanent and
12/10 temporary survivors. Rendered passive loss is 51.2 seconds; active victory
is 209.3 seconds with 9 permanent and 12 temporary survivors, 48 recruits and
28 expirations. Startup, corner, resize, attack, recruitment and outcome views
were inspected. These are scripted runs and visual checks, not a human playtest.
