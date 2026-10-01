# Project State

## Current Web Release For Itch.io (2026-10-01)

`output/SurviveVampiror-web-2026-10-01.zip` contains the current game (13.1 MB,
nine files, index.html at the root), including Newbie/Normal and mounted rush.
`export_presets.cfg` exports Web release with the matching official 4.7.2
single-threaded template cached in `output/.web-templates/`. PWA and threads
are disabled; itch.io SharedArrayBuffer support is unnecessary. Keep the
runtime `art/hit_flash.tres` in the export while excluding authoring sources.

Noto Sans/Serif and DejaVu symbol fallback fonts are bundled with their licenses
so web retains the typography and arrow/diamond glyphs. Web hides Quit because
it cannot close the host page. Native Quit remains available.

Release export completes cleanly. A fresh Chromium context served from plain
localhost (crossOriginIsolated=false) renders the title, selects Normal, enters
battle, moves with WASD, pauses and restarts with Normal retained. Screenshots
were inspected; no console/page/resource errors. Native mode smoke also passes
after bundling fonts. ZIP CRC and all archived bytes match the tested directory;
hashes are in `output/web-build-info.json`. `output/ITCH_UPLOAD.txt` provides
upload settings and page copy. No itch.io upload or public-site verification
has been performed; the previous published demo remains unchanged.

## Newbie And Normal Modes (2026-10-01)

The title now offers Newbie (default, existing damage) and Normal (any knight
hit instantly kills a zombie). The crossbow stays lethal/piercing in both.
The mode is scene-owned, passed before arena entry and reapplied to each wave's
knight. Restart resets the run but keeps the mode; returning to the title keeps
the selection and allows changing it. The HUD names the active mode.

Editor import, focused mode checks, combat, waves, mounted-rush and real-time
menu checks pass. Focused mode checks also pass in a rendered window, covering
both damage rules for all five attacks, 120-HP recruits, warnings/misses,
mouse/keyboard selection, all waves, pause/result restart, a permanent wipe and
mode switching. Menu frames at 1280 × 800 and 960 × 600 (audio expanded) and the
HUD were visually inspected. Mode/combat/rush/menu logs are clean; accelerated
waves retain the known shutdown warning (6 instances / 3 resources). These
checks do not establish human balance or a full Normal-mode victory.

## Wave Announcements (2026-10-01)

Intermediate victories show a 48 px "Wave cleared" title on the reward screen,
with a short fade/scale overshoot and settle. Choosing a card or skipping reveals
a centered 42 px next-wave heading, 80 px pulsing countdown and enemy caption.
Numbers come from Arena's existing four-second timer; reward selection still
waits indefinitely. Small combat hints are hidden during this intermission.

Both tweens explicitly stop during tree pause, despite the HUD's always-process
mode. Resume retains the current animation/selection; next wave, terminal
outcome and restart clear the countdown. No combat or transition timing changed.
Import, card layout, reward and HUD assertions pass. Rendered rewards/countdown
at 1280 × 800 and 960 × 600 were inspected; the rendered reward log is clean.
Accelerated reward/HUD runs retain known audio shutdown warnings (14/7 and 16/8
ObjectDB instances/resources). No human playthrough is claimed.

## Perk Audio And A Character-Based Main Menu (2026-10-01)

Six short effects now accompany mine arming/batched explosion, sling firing/
landing and Blood feast activation/natural expiry. Sprint keeps its existing
cue. Both ability slots feed two bounded Effects-bus voices; rejected actions,
cancelled aim and destroyed projectiles stay silent. Pause freezes playback;
intermission/outcome/restart stop the voices. Existing gameplay timing and
damage are unchanged. Offline reuse/synthesis spends zero additional API credits.

Undead March remains on the title screen. Graveyard Groove is the battle loop,
built from the second sketch's MIDI using the same instrument-bank checksum and
render settings. Its new committed lossless source makes rebuilding independent
of that bank. The 25.263175-second loop measures -18.36 LUFS / -2.09 dBTP.
Tiny Siege remains unused. Both active tracks use the existing Music volume.

The title now presents an animated low-poly graveyard diorama, prominent serif
title and crimson Raise the horde button. Audio sliders are tucked behind an
Audio toggle; Quit and keyboard focus remain available. Imported visual models
idle in a noninteractive SubViewport; no combat scene runs behind the menu.

Import, real-time headless/rendered perk audio, existing real-time audio,
manual-sling and rendered menu checks pass with clean logs. Ability-mechanics
assertions also pass, with the known accelerated audio shutdown retention
warning (12 ObjectDB instances / 6 resources). The rendered perk mix records
12.52 seconds with a -11.96 dBFS peak and no clipped samples. Final menu frames
at 1280 × 800 and 960 × 600 were inspected, including expanded volume controls.
Checks cover actual reward-slot events, pause, natural/cancelled resolutions,
wave transitions, music loop wrapping, volume retention, menu return and restart.
These are scripted/rendered and signal-level checks, not listening approval or
a human playthrough. Earlier entries describing March as battle music are historical.

## Mounted Stampede (2026-10-01)

Wave three adds a sustained pursuit attack to the knight's previous moves.
A 1.4-second warning precedes up to 4.2 seconds of travel at up to 8 units/s.
Turn speed (50°/s) and angular acceleration (100°/s²) prevent instant tracking
or reversals. He runs past a reached target; a floor edge stops the rush.
Timeout/edge contact gives 2.8 seconds of recovery. Each zombie takes at most
one 20-damage hit per rush. Red double chevrons follow the real heading,
with gallop, a small rider/mount bank, air trails and a lower warning sound.
All tuning lives on Survivor; earlier waves and short charges are unchanged.

Editor import, mounted-rush headless/rendered assertions, combat, waves,
targeting and air-effect checks pass. Rendered warning/pursuit/turn frames
were inspected. Full runs with 0.37/0.50-second input reaction win in
272.2/327.2 seconds with 9/2 permanent survivors, seeing 9/13 stampedes.
Passive/chasing still lose. The full pilot follows the changing visible
heading during this attack rather than parking at a straight-charge endpoint.
Focused rush/combat/air logs are clean. Accelerated wave/targeting/full-run
checks retain known audio shutdown warnings (6/3, 6/3 and 20/10 instances/resources).
These are automated and rendered checks, not a human balance/feel playthrough.


## Jam Submission Audit And Updated Deck (2026-10-01)

Submission materials from an earlier session were found in the sibling
`../survive-vampiror-jam-submission/output/`. The user confirmed team name
**Go K**. The updated seven-slide PDF, AI disclosure and detailed audit are in
[`output/submission-2026-10-01/`](../../output/submission-2026-10-01/).
The original sibling files remain unchanged. The revised PDF covers the current
three waves, WASD, reward perks and audio; all pages were visually inspected,
the QR matches the public URL, and mandatory cover logo bands are preserved.

The submission itself is **not ready**: anonymous HTTP reads confirm the public
site still serves the old September 30 PCK (matching its recorded SHA-256).
No submission ZIP was found. The existing 55.07-second video meets the duration
limit but shows that old version and has no audio track. GitHub returns 404
anonymously. Browser/incognito gameplay was not verified because no browser
surface is connected. Google Forms requires login; no submission was made.
The PDF explicitly labels the old online demo until deployment is updated.
See the audit for exact links, paths, checks and remaining submission steps.


## Current Stage

Development continues on `main`, consolidating gameplay, the in-game interface,
character animation, low-poly surroundings, audio and the main menu. Gameplay
checkpoint `f6d4513` is preserved on `gpt-full-game-test`; the presentation work
was developed on `ui-hud-prototype` before consolidation.
Godot 4.7.2, typed GDScript, GL Compatibility,
1280 × 800 startup window. The earlier stationary-knight balance prototype is
preserved in commit `dc63168`.

## Implemented

- Illustrated between-wave cards for mines, sling, feast and sprint use the
  actual zombie models, restrained per-perk colors and visible key badges.
  Centered portrait cards have hover/focus feedback and explicit selection;
  the +10 permanent-zombie alternative is a separate full-width button.
- Permanent zombies retain olive skin/warm clothes and a solid ivory foot ring.
  Temporary recruits use pale blue skin, dark blue clothes, a ragged shoulder
  mantle and a four-part cyan ring. Matching HUD symbols link counts to these
  shapes. Ability colors preserve ring geometry and the character appearance.
- Zombie sling now aims manually: Q/E or HUD opens a mouse-following scatter
  circle, LMB fires a temporary zombie, RMB/same key cancels. Cyan is valid;
  red rejects range/bounds. Radius-2.5 random landing creates actual hit/miss;
  cooldown starts only on firing. Existing flight, impact and ammo costs remain.

- Crossbow bolts pierce and instantly kill every zombie intercepted along
  their locked line, including increased-HP targets. Their original warning,
  width, speed, range and cooldown remain; terminal defeat cancels further hits.
- Short ivory crescents follow knight sweep/spin impacts; narrow air streaks
  accompany charges, mounted pursuit and actual zombie sprint travel. They are
  visual only, pause with the tree, and clear on stop/death without covering
  the colored attack warnings. Native meshes/materials require no shaders.
- Play enters an unmodified first wave. After waves 1 and 2, choose one of two
  random unowned perks or skip for exactly +10 permanent zombies, including
  above the grave cap. Sprint unlocks Space; active skills fill Q then E, with
  independent cooldowns. Choices wait indefinitely; restart clears all rewards.
- Smooth mouse-wheel zoom, bounded to 0.45–1.25 times the fitted camera size.
  Zooming closer than the default follows the mobile horde; zooming back out
  restores the arena overview. Detached mines/projectiles do not pull the camera.
  Pause freezes it; resize retains focus/scale and restart restores the overview.
- Main menu with Play, Quit and independent music/effect volume controls.
  The same controls appear on pause; pause/results offer a return to the menu.
  Levels and mute persist across scenes/restarts within the application session.
- A three-wave encounter: ready state, first-WASD start, elapsed time,
  three HP phases per knight, victory/defeat statistics, pause/resume and restart.
  Waves have 800/1000/1200 HP: halberd, additional crossbow, then mounted.
  A configurable four-second break preserves the same surviving horde and wounds,
  freezing lifetimes/site/sprint timers. Only the third knight defeat is victory.
- A 60 × 44 arena (formerly 44 × 32), fixed-angle camera that fits the window,
  rigged knight and zombie GLBs. Ground continues behind the HUD to the window
  edges. Authored rock clusters frame the perimeter; scrub, low pebbles and
  muted ground patches break up the floor. The surround/props are visual only.
- 40 permanent starters, shared crowd commands/separation/bounds, automatic
  bites and death. Losing the last permanent immediately loses the run.
- Sprint is locked at run start and acquired as a between-wave perk. Once owned,
  Space gives 2× speed for 1.4 s, 7 s cooldown; actual run animation follows.
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
  Solid/broken foot rings and warm/cool character palettes distinguish kinds.
  Results separate kills from expiry.
- Scene-owned state with explicit references/signals; no new framework or plugin.
- Essential sound effects: distinct sweep/charge/spin warning patterns, swing
  noise, confirmed weapon contact, sparse zombie grunts and grave rise/sink.
  Shared footsteps, bites, command/sprint, recruitment/expiry and outcome cues
  complete the feedback. Six perk cues cover arming, launch, impacts and feast
  start/end. Thirteen bounded scene-owned voices pause with gameplay;
  outcomes stop gameplay sounds and play a short result cue.
- Graveyard Groove loops quietly during battle in the same audio scene.
  First command starts it once; pause freezes it and outcome/restart stops it.
  Undead March plays on the title screen; Tiny Siege remains unused.

Rules/tuning are in [SPEC_GAMEPLAY.md](SPEC_GAMEPLAY.md); code ownership is in
[SPEC_ARCHITECTURE.md](SPEC_ARCHITECTURE.md).

## Illustrated Upgrade Cards (2026-10-01)

The two-card reward screen now uses compact portrait cards, individual art,
role/key badges, a selected rim/check and a short staggered reveal. The opaque
background keeps the paused HUD out of the reading area. Existing serif, bone
and dark-green styling carries over from the rest of the interface.

`tools/render_upgrade_art.gd` renders four static PNGs from shipped character
models and native meshes. Runtime cards load those images; no 3D card viewport,
external generator or gameplay change is required. Arena passes reward IDs and
bound descriptions so Q/E/Space labels follow the offered ability.

Editor import, focused card checks in headless/rendered modes, round-reward and
Sprint-perk checks pass with clean logs. Both illustration pairs at 1280 × 800
and selected cards at 960 × 600 were visually inspected. Keyboard selection,
exclusive switching, confirmation and skip are covered by the card check;
existing reward checks cover mouse selection and paused intermissions. These
are scripted/rendered checks, not a human playthrough.

## Follow The Horde While Zoomed In (2026-10-01)

ArenaCamera now reads the horde through an explicit scene reference. At zoom
factor below 1.0 it smoothly translates to center the mobile crowd; at 1.0 or
above it returns to the authored overview. Angle and height stay fixed. Agents
locked by mines/sling are excluded, matching movement cohesion. An empty mobile
group holds the last view. Follow response is exported; no gameplay tuning changed.

Editor import, extended camera zoom, physical movement and manual sling checks
pass with clean logs. The rendered camera check also passes: ordinary movement,
settling, detached agents, empty mobile set, pause, resize, zoom-out restoration
and restart are covered. Follow views at 1280 × 800 and 960 × 600 plus restored
overview were inspected. These are scripted interaction/render checks, not a
human camera-feel playthrough. The older arena-centered zoom entry is historical.

## Sprint As A Reward (2026-10-01)

Sprint joins the random unowned perk pool. It unlocks the existing Space/HUD
action, keeping Q/E free for active skills. Before acquisition input is inert,
its HUD control is hidden and pause omits the shortcut. Duplicate offers/grants
are excluded; skipping does not unlock it. Restart resets ownership and timers.

Import, focused headless/rendered Sprint checks, reward, combat, movement and
HUD assertions pass. The actual reward card and locked/unlocked HUD states were
inspected. Full keyboard pilots start with no sprint, prefer it only when offered,
and win all three waves in 238.0/264.3 seconds with two permanent survivors each.
Passive/chasing still lose. Sprint tuning and knight parameters are unchanged.
The focused rendered/headless perk, import, combat and movement logs are clean;
accelerated reward/UI/full-run tests retain known audio shutdown warnings
(14/7, 16/8 and 18/9 ObjectDB instances/resources). No human balance playthrough
is claimed; earlier full-run evidence below used default sprint.

## Permanent And Temporary Zombie Identity (2026-10-01)

Temporary recruits have cached material overrides and a small chest-bone mantle;
the imported mesh/materials, rig, hit flash and death/expiry paths remain intact.
Permanent rewards retain the original appearance. KindMarker remains the ability
marker contract: its geometry stays solid or broken while mine/sling/feast code
changes color and scale. Cleanup restores each type's base color. HUD legends use
matching native SVG icons; there are no per-agent labels or custom shaders.

Editor import and focused headless/rendered identity checks pass cleanly, covering
shared-material isolation, recruit/permanent reward spawning, ability restoration,
hit flash, attached-cloth pause and expiry cleanup. Mixed 62-agent views at
1280 x 800 and 960 x 600, close-ups and ability-colored rings were inspected.
Reinforcement and HUD checks pass cleanly. Round-reward and zombie-animation
assertions pass with the previously documented accelerated audio shutdown
warnings (2/1 and 4/2 ObjectDB instances/resources respectively). Checks are
scripted; no human playthrough is claimed.

## Manual Sling Aim (2026-10-01)

Mouse targeting replaces automatic shots at the knight. The possible landing
disk stays on the floor and inside an available recruit's 22-unit range; invalid
clicks cost nothing. The player can keep moving and using the other ability.
Ground projection follows zoom/resize. Pause/focus loss/round transition and
lost ammo cancel uncommitted aim; shots already flying keep existing lifecycle.
Input emits intent, Arena applies run guards and HordeAbility owns the shot.

Editor import and focused headless/rendered manual-sling checks pass cleanly.
The seeded sample produced 18 hits from 32 centered shots, with varied landings
inside the disk and damage matching impact distance. This verifies randomness,
not balance. Normal/invalid/960 × 600 zoomed aim and flight captures were inspected.
Ability, reward, zoom and combat regressions also pass cleanly. Movement assertions
pass with the existing accelerated shutdown warning (7 ObjectDB instances / 3
resources). No human feel/balance playthrough is claimed.

## Between-Round Zombie Rewards (2026-10-01)

The existing two-card HUD screen now opens on intermediate knight defeats.
Battle timers and commands stay frozen until one card is confirmed or skipped;
only then does the four-second countdown begin. Pause/resume keeps the same
cards and selection. Each break grants once; final victory and permanent wipe
cannot yield a reward. Skip adds ten full-health permanent members around the
surviving crowd without healing veterans or changing temporary lifetimes.

Two existing HordeAbility components retain separate Q/E state. Owned skills
are excluded from offers. Mines cannot take over a flying recruit, and feast
preserves mine/flight markers and restores violet when their locks end. Menu
Play and restart both begin with 40 permanent zombies and no ability. Earlier
pre-battle selection and retained-on-restart descriptions are historical.

Editor import; reward, ability, menu, knight-wave, combat and reinforcement
checks pass. The rendered reward test also passes cleanly; 1280 × 800 and
960 × 600 cards, bonus-horde and dual-ability HUD views were inspected.
Full scripted runs pass: passive/chasing lose; ordinary-horde active pilots
win in 241.1/249.0 seconds with 6/4 permanent survivors. They claim cards but do
not activate them, so this checks progression without claiming ability balance.
The latest full-run log is clean; an earlier accelerated run reported the known
audio shutdown retention warning (20 ObjectDB instances / 10 resources).
These are automated scenarios and rendered inspection, not a human playtest.

## Lethal Piercing Crossbow (2026-10-01)

Bolts now kill every intercepted zombie using its remaining HP and keep flying.
Ordered swept hits handle multiple targets within one tick without skipping
zombies removed by death signals. If a front target is the last permanent,
defeat cancels the bolt before farther same-tick hits. Warning/width/speed/range,
cooldown, melee and zombie stats are unchanged.

Editor import, combat smoke and headless/rendered knight-wave assertions pass.
The focused test kills three targets in one shot, including a 120-HP zombie and
a temporary recruit; it verifies death order, live-list mutation, side/range
misses, pause, expiry and terminal cancellation. Before/after rendered multi-kill
views were inspected. Both full keyboard pilots win all three waves in
243.7/236.6 seconds with 5/6 permanent and 12 temporary survivors, recruiting
60 and encountering all four attacks. Passive/reckless runs still lose.
Rendered wave and combat logs are clean; accelerated headless wave/balance
runs retain the known audio shutdown warnings (6/3 and 18/9 ObjectDB
instances/resources). No human difficulty playthrough is claimed.

## Motion Air Effects (2026-10-01)

KnightVisual triggers the slash at the existing strike transition, with a
0.14-second fade after its strike duration. Charge and mounted pursuit enable
two tapered side streaks; ZombieVisual enables smaller, staggered streaks only
during sprint. Actual displacement gates their visibility, so blocked movement
and spawn teleports do not create wind. One scene-owned ImmediateMesh per
character and a shared native material bound the effect; no particles spawn.
Stop, intermission and death clear it; tree pause freezes it. Combat tuning,
hit timing, movement and the original character assets are unchanged.

Editor import and focused headless/rendered `motion_air_smoke.gd` pass, including
warning/impact separation, finite fade, pause, charge/mount travel, stopped
sprints, death and full-crowd cleanup. Sweep/spin, charge, mounted and zombie
close-ups plus 60-zombie/default-camera views were inspected. Knight animation
and combat checks pass cleanly. Zombie animation and keyboard movement checks
pass assertions, with the existing accelerated audio shutdown warnings
(4/2 and 7/3 retained ObjectDB instances/resources respectively). These are
scripted checks and rendered inspection, not a human playthrough.

## Working Zombie Abilities (2026-09-30)

Historical verification: acquisition and restart behavior below was superseded
by the between-round reward change above; the three mechanics remain implemented.

The user confirmed sacrificing half the entire horde, including permanent
zombies. Corpse mines arm alternating members (floor of half); orange rings
pulse while they stay behind for 2 seconds, then die and damage only a nearby
knight. The mobile half's cohesion ignores armed zombies. Sling spends one
temporary zombie, locks a landing point and animates its model along an arc;
the knight can dodge and damage/expiry can cancel the shot. Blood feast grants
5 seconds of twice-frequency bites and 2 HP healing per successful bite, capped
at maximum health. New recruits join an ongoing feast; no resurrection or
lifetime extension. Detailed tuning lives in SPEC_GAMEPLAY.

HordeAbility owns timers and special movement; Arena ticks it only during
active battle and forwards Q/HUD requests. Wave breaks freeze state and rebind
the next knight through HordeController's existing survivor reference. Terminal
outcomes cancel pending effects; sacrificing the last permanent still loses.
Menu and restart instantiate the arena with the chosen enum before scene entry;
no global selection service or knight AI changes are involved.

Editor import, focused headless/rendered ability checks and menu flow pass.
Combat, recruitment and knight-wave regressions pass with clean logs. Movement
assertions pass with the pre-existing accelerated shutdown warning (7 ObjectDB
instances / 3 retained resources). Cards at 1280 × 800 and 960 × 600, armed and
exploded mines, sling flight/impact and feast markers/HUD were inspected.
Tests cover costs, hit/miss, early death/expiry, healing, wave pause/resume,
restart and last-permanent defeat; checks are scripted, not a full human
playthrough or a claim that all three abilities are balance-tuned.

## Three Knight Waves (2026-09-30)

Historical initial wave tuning; the 2026-10-01 lethal-piercing change supersedes
the original bolt damage and first-target behavior described below.

The user confirmed surviving-horde carryover and a crossbow added to melee.
Wave two gains a locked cyan warning and a visible finite bolt: 1.2-second
windup, 20 damage to the first intercepted zombie, 16-unit range, six-second
cooldown. Wave three keeps both weapons and adds a simple native mesh horse,
riding poses, 2x pursuit speed and 1.4x charge speed. Original GLBs and zombie
mechanics are unchanged. Arena exports wave count, health and break tuning.
Intermediate death starts a countdown; the knight alone is replaced away from
the horde, with explicit references rebound. Pause/restart and final defeat
cancel progression and projectiles. Music continues across the wave breaks.

Editor import, focused wave/projectile checks, melee/targeting/knight-animation,
recruitment, UI/menu and real-time audio assertions pass. Rendered wave checks
cover equipment, intermission and final outcome. Crossbow and mounted close-ups
were inspected. Full keyboard pilots (0.37/0.50-second reactions) clear all three
waves in 241.1/249.0 seconds with 6/4 permanent and 12 temporary survivors.
Both recruit 60 and see all three HP phases and all four attacks. Passive and
reckless chase lose at 68.2/29.0 seconds. The full balance run finishes cleanly;
some accelerated UI/menu/targeting runs retain the previously documented audio
shutdown warnings. These are scripted runs, not human difficulty approval.

## Zombie Upgrade Screen (2026-09-30)

Historical placeholder step; superseded by Working Zombie Abilities above.

MainMenu owns a separate `ui/zombie_upgrades.tscn` screen, built from four
instances of `components/upgrade_card.tscn`. Choosing one enables Begin battle;
Back/Esc restores the menu and its focus. Menu music continues on the screen.
Reopening before battle retains the choice; a fresh menu resets it. The screen
has no gameplay connection beyond requesting battle entry. Existing in-arena
restart remains a direct restart.

Editor import and the extended real-time `menu_smoke.gd` pass headless and
rendered with clean logs. Actual pointer input selects all four cards and
verifies exclusivity, back/reopen, battle entry, menu return and audio controls;
Escape is exercised too. The 1280 × 800 selected view and 960 × 600 unselected
view were inspected. These are scripted checks, not a human playthrough.

## Camera Zoom (2026-09-30)

Editor import and `camera_zoom_smoke.gd` pass headless and rendered without
script errors or shutdown warnings. Actual wheel events verify smooth bounded
zoom, no accidental battle start, retained scale on resize, pause/outcome guards
and reset on restart. WASD movement/key release is verified against the current
working-copy controls. Default/near/far rendered views were inspected; no human
playthrough was performed. Earlier click-based test evidence below describes
the previous control implementation.
The current WASD prototype smoke assertions also pass; its accelerated shutdown
reports 7 leaked ObjectDB instances and 3 retained resources. The real-time
camera checks above finish cleanly.

## WASD Horde Control (2026-09-30)

Physical WASD now moves the whole horde relative to the camera. Diagonals are
normalized; releasing keys stops all zombies. Opposing keys cancel, and pause
or window focus loss clears held intent. Floor clicks neither move the horde
nor start the run; the destination marker is removed. First movement starts
combat/music and opens West. Cohesion keeps the loose crowd together while
moving; bounds, separation, Space sprint and combat tuning are retained.
Recruitment now needs actual two-second occupation only, so release WASD at
the active crater to summon. The existing one-use/random-delay rule remains.

Import and headless keyboard, combat, recruitment, grave-visual, UI, menu and
real-time audio assertions pass. Full physical WASD/Space pilots win at
176.5/170.9 seconds with 12/6 permanent survivors and 60/48 recruits; passive
and reckless chasing lose at 64.2/46.7 seconds. Both wins see all phases and
attacks. Older mouse-driven results below describe earlier controls. Some
accelerated UI/menu/prototype runs retain the previously recorded audio resource
shutdown warnings; the real-time audio and full balance runs finish cleanly.
Rendered keyboard-driven recruitment and UI checks pass cleanly. Ready/pause
WASD hints and the gathered crowd at a consumed crater were visually inspected.
These are scripted checks, not a human playtest.

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
