# Project State

## Current Stage

Development continues on `main`, consolidating gameplay, the in-game interface,
character animation, low-poly surroundings, audio and the main menu. Gameplay
checkpoint `f6d4513` is preserved on `gpt-full-game-test`; the presentation work
was developed on `ui-hud-prototype` before consolidation.
Godot 4.7.2, typed GDScript, GL Compatibility,
1280 × 800 startup window. The earlier stationary-knight balance prototype is
preserved in commit `dc63168`.

## Implemented

- Main menu with Play, Quit and independent music/effect volume controls.
  The same controls appear on pause; pause/results offer a return to the menu.
  Levels and mute persist across scenes/restarts within the application session.
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
- Knight carries a low-poly halberd with a long wooden shaft, axe/spear head
  and folded crimson pennant, attached to the original right-hand bone.
- Recruitment: West opens first; later sites are random with no immediate repeat.
  Every successful two-second summon consumes its activation, discarding recruits
  that do not fit under cap 60. A configurable gap (5 s by default) precedes
  the next site; unused sites move after 30 s. Each opening offers 12 temporary
  zombies, which expire 45 s after spawn or die earlier from damage.
  Timers freeze before start, on pause and after outcome.
- Recruitment sites are persistent shallow craters. Three gravestones rise in
  sequence while a site has available recruits and sink on closure/exhaustion.
  A dark ring fills clockwise in mint during occupation; a diamond identifies
  the available crater. The ring remains visible through a gathered horde.
  These non-colliding visual props do not change occupation or stock rules.
- Restrained HUD: slim knight HP/phase bar with a delayed damage trail, grouped
  horde counts, contextual expiry/recruitment info, and discreet sprint control.
  Empty temporary readouts are hidden. Recruitment uses a diamond/stock/timer
  readout; world labels, percentages and the duplicate HUD progress bar are removed.
  Clickable sprint/pause/resume/replay controls complement existing keyboard input.
  White/blue foot rings distinguish kinds. Results separate kills from expiry.
- Scene-owned state with explicit references/signals; no new framework or plugin.
- Essential sound effects: distinct sweep/charge/spin warning patterns, swing
  noise, confirmed weapon contact, sparse zombie grunts and grave rise/sink.
  Shared footsteps, bites, command/sprint, recruitment/expiry and outcome cues
  complete the feedback. Eleven bounded scene-owned voices pause with gameplay;
  outcomes stop gameplay sounds and play a short result cue.
- The selected Undead March loops quietly during battle in the same audio scene.
  First command starts it once; pause freezes it and outcome/restart stops it.
  Two other music concepts remain unused alternatives.

Rules/tuning are in [SPEC_GAMEPLAY.md](SPEC_GAMEPLAY.md); code ownership is in
[SPEC_ARCHITECTURE.md](SPEC_ARCHITECTURE.md).

## One Summon Per Activation And Delayed Random Sites (2026-09-30)

The old behavior was reproduced with viewport input: 52 living zombies received
8, leaving stock 4 and the ring visible; one casualty then allowed another summon
from the same point. Successful summons now close that activation completely,
discard excess stock and hide the ring immediately. After `site_respawn_delay`
(Main Inspector, default 5 seconds), Arena opens a random different site. During
the gap no site is active and the HUD counts down to the next opening. The first
site stays West; unused points relocate after 30 seconds. This supersedes earlier
notes about preserved partial batches and fixed west/south/east rotation.

`recruitment_flow.gd` passes headless and rendered with actual viewport clicks,
ordinary travel and successive additions of 12, 8 and 1. The used site stays
closed after a casualty; pause/outcome freeze the gap and restart clears it.
Rendered closure, countdown and a different opening were inspected. Scenario
checks also cover 0- and 2.5-second settings and no immediate location repeats.
Editor import, reinforcement/combat/grave-visual/UI/movement assertions and the
real-time audio check pass. Two seeded full active runs win at 186.2/189.1 s,
with 9/8 permanent survivors and 48 recruits; passive/chase losses remain
51.2/39.3 s. These are scripted runs, not human playtesting.

Some accelerated headless runs finish with audio-stream/playback resource warnings
at shutdown despite passing their assertions, also seen in the pre-fix probe.
Verbose output identifies WAV/Ogg playback resources; explicit Dummy did not
eliminate the issue. The real-time audio and rendered recruitment-flow runs
finish cleanly. No audio-lifecycle change was made as part of this recruitment fix.

## Circular Recruitment Indicator (2026-09-30)

Recruitment now uses a shallow mint-filled ring around the active crater and a
diamond marker. It fills clockwise from actual occupation progress, resets when
occupation stops, freezes on pause and disappears on closure/exhaustion. The
indicator draws over the horde to remain readable. Floating labels and numerical
percentages are removed; the HUD retains a matching diamond, stock, short state
hint and rotation countdown, with no compass names or duplicate progress bar.
Combat and recruitment parameters are unchanged.

Editor import, headless movement/combat/recruitment/audio checks and focused
headless/rendered grave-visual and UI checks pass. Quarter/half/nearly-full
close-ups, inactive/closed states and crowded arena views at 1280 × 800 and
960 × 600 were inspected. Full balance was not rerun for this presentation change;
no human playtest is claimed.

## Verification

- Main menu/audio settings: editor import, headless/rendered `menu_smoke.gd`,
  HUD, audio and combat smoke checks pass. Real mouse clicks verify independent
  gain/mute, setting retention through restart and menu transitions, no command
  leak from Play/sliders, frozen gameplay on pause, restored keyboard sprint,
  return from pause/result and the Quit button. Main menu at 1280 × 800 and
  960 × 600, small-window pause and results were inspected. A test teardown now
  frees its active arena; Quit stops audio and gives the mixer a brief release
  interval before shutdown. There is no disk settings persistence or subjective
  listening approval; no full balance rerun was needed for the menu changes.

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

Selected music integration: editor import, real-time headless/rendered audio
smoke and combat smoke pass. Checks cover initial silence, first-command start,
repeated commands, pause/resume, seeking across the loop boundary, both outcomes
and restart. The 26.181837-second Ogg has no clipped samples and a decoded seam
jump of 0.00042 full-scale. The rendered Master-bus recording is 30.75 seconds,
peaks at -7.45 dBFS and has no clipping; the arena frame was inspected. Gameplay
tuning is unchanged; no full balance rerun or subjective mix approval is claimed.

Three standalone [music sketches](../../art/audio/music_concepts/README.md)
are available for comparison: Undead March, Graveyard Groove and Tiny Siege.
They are original locally authored MIDI compositions rendered with FluidSynth
and GeneralUser GS, not ElevenLabs outputs. Music API returned HTTP 402
`paid_plan_required`; no successful music generation or retry occurred.
Local previews use zero API credits and remain outside Godot import/runtime.
The user selected Undead March; a separate looping Ogg is now used during battle.

The MP3s decode correctly and last 27.48/26.56/29.54 seconds. Measured loudness
is -18.26/-18.30/-18.37 LUFS with no clipped samples. MIDI, composition source,
instrument provenance and license are retained beside them. These are faded
comparison sketches, not final seamless loops; no subjective listening approval
is claimed. Gameplay is unchanged, so gameplay tests were not rerun for this pass.

The UI branch has a quiet bone/charcoal HUD, serif titles, generous spacing and
modal pause/result screens. The earlier four-card dashboard has been replaced.
Combat markers remain technical placeholders. The arena now has a simple
low-poly environment pass with ordinary mesh materials and short gameplay sound
effects and the selected march; no custom shaders. Large rocks are outside movement bounds and
walkable pebbles are only
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

## Flagged Halberd (2026-09-30)

The hand-held sword scene has been replaced by `components/halberd.tscn`: a
wooden shaft, faceted axe head/cutting edge, rear spike, spear tip and crimson
swallowtail pennant with a gold band. KnightVisual reuses the right-hand bone
attachment and existing animation clips. The pennant is folded mesh geometry,
not cloth simulation. Original GLBs, combat parameters and hit shapes are unchanged.

Editor import, headless/rendered knight-animation checks, combat and rendered UI
checks pass. Idle/run close-ups, all three attack pose sets/motion frames and
the arena view were inspected. The long shaft clears the floor across sampled
idle/run/attack poses. Full balance was not rerun for this visual-only replacement;
no human playtest is claimed.

## Animated Recruitment Craters (2026-09-30)

Crater/tombstone scenes replace the green recruitment rings. ReinforcementVisual
animates only gravestone transforms; site state controls availability immediately.
Transitions pause with the tree, reverse safely, and are freed on restart. The
craters are shallow mesh props above the existing floor, not terrain holes.
Recruitment timing, stock, cap, combat and movement tuning are unchanged.

Editor import, headless/rendered visual and reinforcement checks, headless combat
and rendered UI checks pass. Inactive, rising, available, sinking and closed close-ups
and full-arena views were inspected. Full balance was not rerun for this
visual-only change; no human playtest is claimed.

## Essential Gameplay Audio (2026-09-30)

Three one-second ElevenLabs sources cost 30 credits in total according to the
API response headers. Raw sources/prompts/receipts live in `art/audio/`; eight
processed or locally synthesized WAVs live in `assets/audio/`. The offline build
script never calls the API. Credentials remain outside the repository.

BattleAudio listens to explicit knight attack signals, existing health/count
signals and grave availability. It gives one contact per attack and one shared
zombie voice with cooldown; expiry does not emit a combat grunt. Warning patterns
are fixed, while impact/voice pitches use a separate random generator. Game rules,
damage timing and balance parameters are unchanged.

Editor import, real-time headless/rendered `audio_smoke.gd`, combat, movement,
recruitment, grave-visual and rendered UI checks pass. Audio checks cover missed
attacks, multiple victims, distinct warnings, pause, depletion/rotation, expiry,
both outcomes and restart. A rendered fixture plus 12 seconds of viewport-click
combat produced a 29.65-second Master-bus recording with a -7.1 dBFS peak and no
clipped samples; its arena frame was inspected. This is signal/recording
verification, not subjective listening approval or a human playthrough.

## Additional Gameplay Audio (2026-09-30)

Two half-second ElevenLabs sources (footstep and bite) cost 10 additional credits,
40 total across five requests. Command, sprint, recruitment, expiry and both
outcome cues are synthesized offline. There are now sixteen WAVs and eleven
single-voice players, with no runtime API dependency or music.

Footsteps follow mean actual horde travel. Accepted sprint has a distinct cue;
rejected sprint is silent. Commands and bites are throttled, simultaneous expiry
is batched, and recruitment takes priority over expiry. Outcomes stop gameplay
voices and play one ending cue. Restart explicitly stops audio before reloading,
including when an ending cue is still playing. Gameplay tuning is unchanged.

Editor import, real-time headless/rendered audio checks, movement, combat and
recruitment checks pass. The rendered test records event scenarios and twelve
seconds of actual viewport-click combat. The final 30.57-second recording peaks
at -7.67 dBFS with no clipped samples; the arena frame was inspected. One repeated
windowed run hit the test's wall-clock settling timeout during render stalls;
the final X11 run with VSync disabled passes (command in TESTING.md).
Rapid outcome/restart cleanup passes without leaked
audio resources. Full balance was not rerun; these are automated event/recording
checks, not subjective listening approval or a human playthrough.
