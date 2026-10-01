# Testing

Run from the project root with Godot 4.7. No external test addon is needed.

## Automated Checks

Web release: `godot --headless --path . --export-release Web output/web/index.html`.
Serve `output/web` over HTTP (not file://) and check a fresh browser context:
menu/mode choice, WASD, Esc, R, readable arrow/diamond glyphs, audio after a user
gesture, and no console/resource errors. No isolation headers are required.
The October 1 ZIP was CRC-checked and matched against the browser-tested files.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/game_modes_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/mounted_rush_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/upgrade_cards_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/sprint_perk_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/zombie_identity_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/motion_air_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/manual_sling_smoke.gd
godot --headless --path . --script res://tests/round_rewards_smoke.gd
godot --headless --path . --script res://tests/horde_ability_smoke.gd
godot --headless --path . --script res://tests/camera_zoom_smoke.gd
godot --headless --path . --script res://tests/prototype_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/knight_waves_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/reinforcement_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/recruitment_flow.gd --fixed-fps 60
godot --headless --path . --script res://tests/reinforcement_visual_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/ui_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/zombie_animation_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/knight_animation_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/targeting_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_balance.gd --fixed-fps 60
godot --headless --path . --script res://tests/character_assets.gd
godot --headless --path . --script res://tests/audio_smoke.gd
godot --headless --path . --script res://tests/perk_audio_smoke.gd
godot --headless --path . --script res://tests/menu_smoke.gd
```

Import first on a fresh checkout to register classes. Each test must print PASS,
exit 0, and produce no script errors; exit status alone is insufficient because
Godot may continue after a script error.

Current accelerated headless runs intermittently report retained audio playback
resources during engine shutdown, including with explicit `--audio-driver Dummy`.
Record those separately from assertion results; do not treat a PASS line as a
clean log. The real-time audio check and rendered recruitment flow complete
without those shutdown warnings in the current verification.

- **Game modes smoke:** all five attacks in both modes against a permanent
  zombie and a 120-HP temporary zombie, unchanged warnings/misses, exclusive
  mouse/keyboard menu selection, all three knights, pause/result restart,
  immediate permanent-wipe cancellation, menu carryover and switching back to
  Newbie. Render with `-- --capture` for `/tmp/survive_modes_*.png`, including
  expanded audio at 960 × 600 and the in-game mode readout.
- **Mounted rush smoke:** wave-three-only selection, stationary warning,
  acceleration/turn limits, inertial reversal and running past the target,
  moving marker without mesh rebuilding, coarse/fine-step equivalence,
  once-per-zombie swept damage, wall and timed recovery, terminal cancellation,
  pause, death and restart. Actual WASD moves the crowd during the rendered
  pursuit. Render with `-- --capture` for
  `/tmp/survive_rush_{warning,pursuit,turn,overshoot}.png`.
- **Upgrade cards smoke:** both illustrated pairs, correct art/key badges,
  wrapped descriptions clear of footers, keyboard selection without immediate
  claiming, exclusive switching, confirmation and skip. Cards and the skip
  alternative fit 1280 × 800 and 960 × 600. Render with
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/upgrade_cards_smoke.gd --fixed-fps 60 -- --capture`
  for `/tmp/survive_cards_{pair_0,pair_2,selected_small}.png`.
  Regenerate the static illustrations with
  `godot --path . --script res://tools/render_upgrade_art.gd`, then reimport.
- **Sprint perk smoke:** no default input/HUD/pause hint, actual random reward
  selection through card clicks, Space ownership independent of Q/E, no duplicate
  offers/grants, cooldown, paused/intermission rejection, later-wave carryover,
  skip and restart reset. Render with `-- --capture` for
  `/tmp/survive_sprint_perk_{locked,card,unlocked}.png`.
- **Zombie identity smoke:** permanent/recruit material isolation, shared recruit
  overrides, solid/broken meshes, retained appearance under ability colors and
  hit flash, permanent reward spawning, attached-cloth pause and expiry cleanup.
  Render with `-- --capture` for `/tmp/survive_identity_*.png`: mixed 62-agent
  horde at 1280 x 800 and 960 x 600, back/front pairs, ability markers and bite.
- **Motion air smoke:** no idle/windup/crossbow arc, finite impact crescents,
  unchanged roots, pause freeze, charge/mounted travel, zombie sprint versus
  walking/blocked travel, stop/death and 60-agent cleanup. Render with
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/motion_air_smoke.gd --fixed-fps 60 -- --capture`
  for `/tmp/survive_air_{sweep,spin,charge,mounted,sprint,crowd,arena}.png`.
- **Knight waves smoke:** three-wave health/equipment progression, carryover of
  living horde objects and wounds, frozen intermission timers, pause/restart,
  no early victory, terminal loss during a break and final victory. Crossbow
  checks cover ranged selection, warning before launch, locked aim, dodging,
  lethal piercing through permanent/temporary/increased-HP targets, front-to-back
  hits independent of list order, safe live-list removal, side/range misses,
  pause, death cleanup and same-tick cancellation on permanent wipe.
  Mounted pursuit changes actual motion. Render with
  `-- --capture` for `/tmp/survive_waves_*.png` arena and equipment close-ups.
  Other component scenarios explicitly select the final wave when testing
  terminal behavior rather than exercising all transitions repeatedly.
  Capture mode also writes `/tmp/survive_piercing_{before,after}.png`.
- **Camera zoom smoke:** actual wheel events verify direction, smoothing,
  near/far limits, mobile-horde centering and following actual WASD movement,
  preserved angle/height, excluded detached mines, and holding focus without
  mobile agents. Also covers key release, pause during follow, resize retention,
  overview restoration, outcome zoom guards and restart position/scale reset.
  Render with `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/camera_zoom_smoke.gd -- --capture`
  for `/tmp/survive_zoom_{default,near,follow,follow_small,far}.png`.
  Run in real time for camera easing; manual sling smoke checks projection with
  the moving/zooming camera.
- **Manual sling smoke:** actual keyboard/mouse input verifies aim without firing,
  ground projection, circle visibility, range/arena-edge rejection, off-screen
  pointer, free cancel, independent movement/other ability, UI click isolation,
  pause/focus/wave/restart cleanup, stationary-cursor zoom and resized targeting.
  A seeded 32-shot sample checks landings stay in the indicated disk, vary, and
  produce both hits and misses; each damage result must match actual impact
  distance. Legacy ability smoke retains zero-spread hit/dodge/expiry fixtures.
  Render with `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/manual_sling_smoke.gd -- --capture`;
  inspect `/tmp/survive_sling_{aim,range,small,flight}.png`.
- **Horde ability smoke:** actual Q/HUD input, start/pause/cooldown guards,
  half-horde detachment, range damage and sacrifice counts, early death,
  sling hit/miss/ammo/expiry, feast cadence/healing/cap/no resurrection,
  intermission freeze and target rebinding, cleared selection on restart,
  last-permanent sacrifice defeat, and a full 40-agent fuse through normal
  Arena ticking. Focused fixtures stop automatic combat to isolate costs and
  timing. Render with `-- --capture` for `/tmp/survive_ability_*.png`.
- **Round rewards smoke:** first wave has no ability; exactly two distinct unowned
  cards appear after intermediate wins. Pointer selection/confirmation and skip,
  indefinite freeze, pause/resume with the same offer, one-time claims, and
  exactly +10 healthy permanent members above the grave cap are covered. Check
  retained wounds/lifetimes, second-card addition, physical Q/E and independent
  cooldowns, mine/sling ownership, feast marker restoration, final-win exclusion,
  permanent-wipe guards and complete restart reset. Wave cleared fade/scale and
  the large countdown freeze on pause; the number follows Arena time, remains
  hidden before reward resolution and clears on next wave/result/restart.
  Normal/small layout captures cover the announcement and countdown. Render with
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/round_rewards_smoke.gd -- --capture`;
  images are `/tmp/survive_rewards_{two_cards,selected_small,countdown,countdown_small,bonus_horde,second_ability,two_abilities_hud}.png`.
- **Prototype smoke:** real physical WASD press/release events verify start,
  whole-crowd movement, normalized diagonals, opposing keys, non-English layouts,
  immediate stopping/idle, sprint, pause/focus clearing and corner bounds.
  Floor clicks are rejected. Viewport checks cover 16:10, 16:9, 4:3 and 21:9,
  full-window rendering, visible arena corners/heads and unchanged key direction
  after resizing. Capture mode saves `/tmp/survive_vampiror_*.png`.
- **Combat smoke:** health/death contract, bite range/cooldown, sweep arc,
  escaping a warning, charge movement and fixed warning, no repeated charge
  hits or hits beyond the rectangle, spin radius, HP phase thresholds, immediate
  death removal, reserve occupation/interruption/capacity, actual sprint
  speed and cooldown, first-command start, pause/resume, restart from pause
  including physical-key handling, both results and stopped combat.
- **Reinforcement smoke:** permanent starters, first-command scheduling, inactive
  sites, random distinct next sites and skipped windows, discarded stock/progress,
  configurable post-summon delays including zero and fractional seconds,
  retained permanent HP, lifetime on-site and across switches, independent
  batches, simultaneous expiry, expiry before combat and same-tick recruitment,
  combat death versus expiry statistics, defeat with temporary survivors,
  immediate stop within a knight hit loop, pause/resume, victory freeze and reset.
  Render with `-- --capture` for `/tmp/survive_reinforcement_*.png`.
- **Recruitment flow:** real physical WASD events and normal horde movement drive
  successive summons of 12, 8 and 1. Verify cap-limited visits close completely,
  standing at a used site after a casualty cannot refill, cooldown pause/outcome
  freeze, a different next site and restart. Knight attacks alone are disabled
  in this focused fixture. Render with `-- --capture` for
  `/tmp/survive_recruitment_flow_*.png` closure and next-opening views.
- **Reinforcement visual smoke:** persistent inactive craters, staggered rise/sink,
  pause in both directions, repeated updates, full-cycle stock refresh, immediate
  closure, reversal, same-frame opening/exhaustion, retained stock at capacity,
  outcome settling and restart cleanup. Site roots and stock remain authoritative.
  Real occupation also drives quarter/half/nearly-full ring captures; interruption,
  pause, exhaustion and restart check indicator visibility/reset behavior.
  Render with `-- --capture` for close-ups at
  `/tmp/survive_graves_{inactive,rising,active,sinking,closed}.png`.
  Add `--wide` after `--capture` to retain the arena camera/HUD and write
  `/tmp/survive_graves_wide_*.png` instead.
- **Perk audio smoke:** finite assets/Effects routing, accepted versus rejected
  activation, one blast for a mine batch, no blast after early mine deaths,
  manual sling aim/cancel/launch/landing/miss/expiry, both slots, natural feast
  expiry without repeat, pause, wave break, next-wave continuation, outcome and
  restart cleanup. Run in real time, without `--fixed-fps`. Use
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/perk_audio_smoke.gd -- --record`
  for `/tmp/survive_perk_audio_check.wav` and three event frames
  `/tmp/survive_perk_audio_{mines,sling,feast}.png`. Inspect levels separately;
  signal assertions and recording are not subjective listening approval.
- **Audio smoke:** initial silence, loaded non-looping effects, one voice per
  category, distinct attack warnings, confirmed hits versus misses, one contact
  per multi-victim attack, throttled bites/casualties/recruitment, no combat grunt on expiry,
  grave rotation/depletion, actual-travel footsteps, command throttling, accepted
  versus rejected sprint, bite contact and batched expiry. Pause, both outcomes,
  one-shot result cues and restart cleanup are covered. Graveyard Groove starts
  with the first command, survives repeated commands without resetting, freezes
  on pause, resumes the same playback and wraps across its loop boundary.
  Outcome/restart checks include stopping music. Run without
  `--fixed-fps`: audio playback follows wall-clock time rather than accelerated
  simulation time. On the Linux test desktop, use
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/audio_smoke.gd -- --record`
  to record the Master bus through these scenarios and 12 seconds of actual
  keyboard-driven combat to `/tmp/survive_audio_check.wav`; the arena frame is
  `/tmp/survive_audio_battle.png`. No microphone or API call is used.
- **UI smoke (UI branch):** real viewport clicks for pause/resume/sprint/replay,
  modal command blocking, pre-start state, cooldown display, frozen gameplay,
  permanent-count warning, contextual visibility, health trail pause behavior,
  victory/defeat controls, reset and small-window layout.
  Render via `godot --path . --script res://tests/ui_smoke.gd --fixed-fps 60 -- --capture`;
  screenshots are `/tmp/survive_ui_{ready,pause,victory,critical,defeat,small}.png`.
- **Menu smoke:** actual startup scene, animated visual-only diorama, collapsed/
  expanded audio, Undead March on the title and Graveyard Groove after entry,
  Raise the horde directly into an unmodified horde,
  Quit and return from pause/result,
  music/effect bus routing, independent slider gain/mute, preservation through
  restart/scene changes, no ground-click leak, settings usable on pause, keyboard
  sprint after closing settings and control bounds at 1280 × 800 / 960 × 600.
  Run in real time. Render with
  `godot --display-driver x11 --disable-vsync --max-fps 60 --path . --script res://tests/menu_smoke.gd -- --capture`;
  captures are `/tmp/survive_menu_{main,main_small,pause_small,result}.png`.
  Crowded recruitment captures are `/tmp/survive_ui_recruitment.png` and
  `/tmp/survive_ui_recruitment_small.png`; inspect ring readability through
  characters and the compact diamond/stock/timer HUD without names/percentages.
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
- **Combat balance:** actual viewport physical WASD/Space input. Passive and reckless
  chasing must lose; active pilots with 0.37 and 0.50 s reaction delays must win
  within ten minutes with permanent survivors, clear all three waves, visit all
  HP phases and four attacks, and
  use temporary reinforcements. The pilot takes a card at each reward screen
  but does not activate Q/E. It begins without sprint, uses fixed reward seeds
  and prefers Sprint only when offered; later Space requests require ownership.
  The fixture registers its current scene, and
  the pilot releases held keys on outcome. The pilot reacts to visible warning geometry and named
  attack type, visits the active site when fewer than eight temporary zombies remain and
  the visible window allows travel/occupation, and uses sprint when dodging
  charges/spins and ranged warnings. It abandons a site when inactive, exhausted or the horde is full. It never teleports agents or changes HP in full runs.
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

Launch `godot --path .` or F5 in the editor. After each of the first two
knight defeats, confirm the countdown, surviving-horde carryover and new gear.
Wave two adds the cyan crossbow line; wave three adds the horse. Only the third
defeat should open Victory. Human feel and difficulty remain a manual check.

1. Confirm the arena waits while you read controls; first WASD movement starts the fight; floor clicks do nothing.
2. Hold WASD to direct the whole horde, release to stop. Space accelerates movement,
   and repeated presses do not bypass the cooldown.
3. Dodge the orange sector sideways, leave the yellow charge lane, and retreat
   outside the purple circle. Return during recovery to bite the knight.
4. Rally at the crater with raised gravestones for two seconds. Confirm blue-ring
   recruits, lifetime countdown and cap 60. A partial summon must also consume
   the site; freeing capacity cannot refill from it. Leave mid-summon to
   interrupt it.
   Check the configured post-summon gap (default 5 seconds), a random different
   next site and 30-second relocation for unused sites.
   Stones should rise on opening and sink on closure/exhaustion; empty craters
   remain on the floor and do not obstruct the horde.
   White-ring permanent zombies must retain health and never expire.
5. Play through the HP phase thresholds; confirm the later attack patterns.
6. Pause during a warning and recruitment; verify gameplay/animations/timers
   freeze, including recruit lifetimes and the site schedule. Resume or restart. Test with a non-English keyboard layout too.
7. Kill the knight, or lose the last permanent while temporary zombies survive.
   Confirm result, separate killed/expired statistics and stopped combat/timers.
8. Restart; verify full HP, 40 permanent zombies, zero temporary zombies, phase 1,
   inactive sites, cleared statistics and sprint locked again.
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
