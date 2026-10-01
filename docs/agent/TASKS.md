# Tasks

## Task: Package The Current Web Build For Itch.io

Status: complete; clean release export, browser smoke and archive integrity pass
Priority: urgent

Deliverable: `output/SurviveVampiror-web-2026-10-01.zip` (13.1 MB), with upload
instructions in `output/ITCH_UPLOAD.txt`. Bundled fonts fix web fallback/glyphs;
retain runtime hit-flash material. Single-threaded export needs no special
hosting headers. Fresh-context Chromium menu/input/pause/restart was checked.
Publishing and anonymous verification on itch.io are the user's next step.

## Task: Select Newbie Or Normal Before A Run

Status: complete; import, focused headless/rendered, combat, waves, rush and menu checks pass
Priority: normal

Scope: Newbie keeps existing damage; Normal makes all knight hits lethal.
Crossbow remains lethal in both. Choose on the title; retain the mode through
all waves, restart and menu return, without persistent settings or global state.

Acceptance: All five attacks verified against permanent and high-HP temporary
zombies in both modes. Warnings and misses preserved. Mouse/keyboard selection,
wave carryover, pause/result restart, immediate wipe cancellation, switching
back to Newbie and normal/small rendered layouts verified. Human balance and a
complete Normal victory remain unverified.

## Task: Animate Wave Cleared And Enlarge The Countdown

Status: complete; import, cards, rewards, HUD and rendered transition checks pass
Priority: normal

Scope: A tweened Wave cleared heading on the existing reward screen and a large
next-wave countdown. Preserve cards, pause controls and the four-second timer.

Acceptance: Pause freezes animation and timer; resume retains selection. Count
only after reward resolution; clear on next wave, result and restart. Verify
readability and card bounds at normal/small window sizes.

## Task: Perk Sounds, Split Music And A Game-Like Title Screen

Status: complete; import, perk/audio, ability/sling and rendered menu checks pass
Priority: normal

Scope: Six short cues for the three active zombie abilities, preserving Sprint's
sound and combat tuning. Reuse existing recordings/local synthesis without
additional API credits. Keep Undead March on the menu; loop Graveyard Groove in
battle. Improve the title with existing characters/props and collapsible audio.

Acceptance: Accepted actions sound at the actual event; rejected/cancelled
actions stay silent. Mine batches share one burst. Pause, intermission, outcome,
restart, both slots and music transitions remain correct. Menu controls work at
normal/small sizes and retain volume. Inspect renders and recorded mix levels.

## Task: Mounted Stampede With Steering Inertia

Status: complete; focused headless/rendered, combat, waves, targeting, air effects and full-run checks pass
Priority: normal

Scope: Give only the mounted knight an additional warned pursuit with gradual
acceleration, limited turning and angular inertia, followed by a longer recovery.
Preserve the ordinary short charge and previous waves. Make the changing
heading, gallop and opportunity to counterattack readable.

Acceptance: Wave gating, inertial reversal/overshoot, sustained pursuit,
coarse/fine-step equivalence, swept single-hit damage, bounds, recovery,
pause, death, permanent-wipe cancellation and restart. Rendered turns inspected;
both keyboard pilots win while encountering stampedes without changing other
combat parameters. Human feel/playtesting remains separate.


## Task: Audit Jam Materials And Update Presentation

Status: complete for audit/PDF update; submission package remains incomplete
Priority: high

Scope: Locate the previous deliverables, compare them with the organizer's
checklist and current game, update the official seven-slide PDF for **Go K**,
and correct AI disclosure, including ElevenLabs effects and Codex-authored music.

Result: Updated PDF/disclosure/audit in
[`output/submission-2026-10-01/`](../../output/submission-2026-10-01/).
All slides and QR checked; cover logo bands preserved. Public site and existing
video are old, ZIP absent, repository inaccessible anonymously. Incognito input
and form submission remain unverified. No deployment, recording replacement,
GitHub access changes or form submission were performed in this task.


## Active Work

Main menu and audio-volume controls are complete.
All current work is consolidated on `main`; use it for further development.
Zombie abilities now accumulate through two-card choices between rounds,
with a +10 permanent-zombie skip option. This session owns zombie abilities
and their UI; the knight session owns knight equipment/behavior. This reward
change is complete. The sling now uses manual mouse aim and visible scatter.
No further progression feature is queued.

## Task: Illustrate And Refine The Reward Cards

Status: complete; import, headless/rendered cards, reward and Sprint checks pass
Priority: normal

Scope: Four illustrations using the game's actual models and palette, compact
portrait cards, clear selection/confirmation and a separate +10 permanent-zombie
alternative. Preserve reward rules, input bindings and knight behavior.

Acceptance: Inspect both illustration pairs and the small-window selected state;
verify correct art/bindings, readable descriptions, keyboard/mouse selection,
confirmation and skip. Static art is reproducible with the offline render tool.

## Task: Move Sprint Into The Reward Pool

Status: complete; import, focused headless/rendered perk, reward, combat, movement, HUD and full-run checks pass
Priority: normal

Scope: No default sprint. Add Sprint to the two-card random reward pool, unlocking
the existing Space/HUD control without occupying Q/E. Preserve sprint tuning.

Acceptance: Locked input/HUD before ownership; actual card acquisition, no
duplicate offers/grants, coexistence with active skills, pause/intermission,
cooldown, skip and restart. Inspect the card and both HUD states; verify full
keyboard-driven runs begin without sprint and can still clear all three waves.

## Task: Follow The Horde When Zoomed In

Status: complete; import, headless/rendered camera, movement and manual-sling checks pass
Priority: normal

Scope: Smoothly follow the mobile horde below default zoom; restore the overview
when zoomed back out. Preserve tilt, height, WASD direction and mouse aiming.
Ignore detached mine/projectile agents and hold focus if no mobile members remain.

Acceptance: Actual movement shifts camera focus without snapping; pause freezes
it, resize retains focus/scale, and restart resets both. Inspect normal/small
zoomed views and the restored full-arena view; verify sling projection.

## Task: Distinguish Permanent Zombies And Temporary Recruits

Status: complete; import, headless/rendered identity, reinforcement, reward and HUD checks pass
Priority: normal

Scope: Preserve warm permanent zombies and add a pale-blue/dark-cloth recruit
palette with a short ragged mantle. Use solid ivory versus broken cyan rings
and matching HUD symbols. Preserve gameplay, source assets and ability feedback.

Acceptance: Identify kinds in a mixed horde at normal/small window sizes, including
when abilities recolor rings. Verify material isolation, bonus/recruit spawning,
hit restoration, pose attachment, pause, expiry and existing ability contracts.

## Task: Manual Zombie Sling Aiming

Status: complete; import, focused headless/rendered aiming, abilities, rewards,
movement, zoom and combat checks pass
Priority: normal

Scope: Enter aim with the sling's Q/E key or HUD button, choose the ground point
with the mouse, show a small scatter disk and fire with LMB. Random landing
within that disk determines actual hit/miss. RMB/repeated ability key cancels.
Keep flight/damage/cooldown parameters and knight behavior unchanged.

Acceptance: No automatic knight targeting, visible valid/invalid area, no cost
before a valid shot, no UI click leak, independent movement/other skill, bounded
scatter and lifecycle cleanup. Inspect normal/small/zoomed aim and flight.

## Task: Choose Zombie Rewards Between Rounds

Status: complete; import, focused headless/rendered rewards, ability, menu, wave,
combat, reinforcement and full-run checks pass
Priority: high

Scope: First wave starts unmodified. After waves 1 and 2, offer two distinct
random unowned abilities or skip for exactly +10 permanent zombies. A second
card adds a new skill on E while the first remains on Q. Separate cooldowns;
no stacking upgrades, pre-battle selection, persistence or knight tuning changes.

Acceptance: Stable offers until a decision, one reward per break, full bonus at
the grave cap, retained wounds/lifetimes/abilities, independent Q/E and compatible
mine/sling/feast states. Pause, terminal loss/final victory and restart reset are
verified. Cards and two ability buttons fit regular and small rendered windows.

## Task: Lethal Piercing Crossbow

Status: complete; import, headless/rendered wave checks, combat and both full-run pilots pass
Priority: normal

Scope: Bolts kill each intercepted zombie in one hit and continue through
multiple targets. Preserve warning, width, speed, range, cadence and melee.

Acceptance: Permanent, temporary and increased-HP targets die on impact;
near-to-far resolution tolerates removal from the horde. Sideways evasion,
range expiry, pause and terminal cancellation remain correct. Inspect the
rendered multi-kill and run wave/combat/full-run checks.

## Task: Air Trails On Attacks And Fast Movement

Status: complete; import, focused headless/rendered effects and animation/combat/movement checks pass
Priority: normal

Scope: Brief tapered crescents on knight sweep/spin impacts and narrow wind
streaks during charge, mounted pursuit and zombie sprint. Keep damage, timing,
movement and parallel zombie progression work unchanged.

Acceptance: Effects follow actual movement, remain absent during warnings and
ordinary zombie walking, freeze on pause and clear on stop/death/intermission.
Inspect individual attacks and a full sprinting horde at gameplay zoom.

## Task: Implement The Three Zombie Upgrades

Status: complete; acquisition/restart policy superseded by the between-round reward task
Priority: high

Scope: Half-horde delayed sacrifice explosions, temporary-zombie sling shots,
and an invented third ability (Blood feast: faster healing bites). Pre-battle
selection feeds a scene-owned HordeAbility; Q/HUD activates it with cooldowns.
Keep the fourth card as ordinary horde. User confirmed mines spend permanent
zombies too. Do not change knight AI, equipment or attack tuning.

Acceptance: Real damage and costs, movement of the remaining half, missed shots,
temporary expiry in flight, bounded healing, input/start gating, pause, waves,
outcomes and restart. Preserve permanent-wipe defeat. Inspect rendered cards,
armed/exploded zombies, flight and feast feedback; run relevant regressions.

## Task: Three Escalating Knight Waves

Status: complete; import, focused/rendered wave checks and full three-wave runs pass
Priority: high

Scope: Three waves: halberd, additional warned crossbow shot, then a mounted
knight retaining both weapons. Preserve the same surviving horde, health,
lifetimes and statistics between waves. A configurable short break precedes
fresh knight health and equipment; only the last defeat ends the run.
Use a simple visible horse and faster pursuit/charge. Keep zombie mechanics
and the parallel upgrade-selection work under their existing owner.

Acceptance: Wave transitions, stronger successive health/equipment, no early
victory, locked projectile warning/first-target collision, pause/restart,
carryover and terminal cleanup. Inspect rendered crossbow/mount poses and
verify complete keyboard-driven runs without changing zombie stats.

## Task: Zombie Upgrade Selection Before Battle

Status: superseded by the between-round reward task; retained as historical scope
Priority: normal

Scope: Play opens a separate zombie-upgrade screen with four numbered placeholder
cards. Select exactly one to enable Begin battle; Back/Esc returns to the menu.
No effects, invented mechanics, persistence or changes to knight/gameplay code.

Acceptance: All four cards are selectable, changing choice clears the previous
highlight, and entering battle works without leaking input. Verify back/reopen,
audio continuity, fresh choice after returning from battle and small-window
layout. Selection belongs to the current menu instance only.

## Task: Replace Mouse Movement With WASD

Status: complete; import, keyboard movement, combat, recruitment, menu, UI and audio checks pass
Priority: normal

Scope: Physical WASD directly steers the whole horde relative to the camera.
Release stops it, diagonal speed is normalized, and floor clicks no longer move
or start the run. Keep crowd cohesion/separation, bounds, Space sprint and the
recruitment cooldown. Occupying a site starts recruitment without a destination
command. Clear held input on pause/focus loss and restart.

Acceptance: Keyboard-driven travel and summons, release/opposing-key behavior,
non-English physical layouts, pause/resume, focus loss, bounds, HUD hints and
full runs verified. Earlier mouse-command verification below is historical.

## Task: Mouse Wheel Camera Zoom

Status: complete; import and headless/rendered camera zoom smoke pass
Priority: normal

Scope: Smooth bounded wheel zoom around the arena center using the current
input component. Preserve default framing and existing working-copy controls.

Acceptance: Wheel up/down changes scale without starting combat. Pause/results
block zoom; resize retains scale and restart resets it. Verify movement at zoom
and inspect default, near and far rendered views.

## Task: Consume Recruitment Sites And Randomize The Next Opening

Status: complete; viewport-input and rendered flow checks pass; mechanics/full-run
assertions pass, with accelerated audio-shutdown warnings recorded in PROJECT_STATE
Priority: high

Scope: A successful summon closes its point, discards any excess batch at the
horde cap, then opens a random different point after a configurable pause.
Default pause is 5 seconds. Keep first-command start, 30-second unused windows,
45-second recruit lifetimes, capacity, combat parameters and pause/restart.

Acceptance: Full and partial summons hide the used ring; losses cannot trigger
another summon there. No active site during the delay, no immediate location
repeat, and timers freeze/reset correctly. Verify real viewport-click travel,
rendered closure/reopening, configurable delays and full-run balance.

## Task: Main Menu And Audio Volume

Status: complete; import, headless/rendered menu, HUD, audio and combat checks pass
Priority: normal

Scope: Launch into a simple main menu with Play, Quit and music/effect sliders.
Reuse the volume controls on pause; allow returning to the main menu from pause
and either result. Keep volume levels through scene changes and restart for the
current application session. No disk persistence or additional menu systems.

Acceptance: Separate effective music/effect gain and mute; playable title-to-battle
flow; no menu-click command leak; pause remains frozen while adjusting; returning
to menu clears pause and frees battle audio. Inspect normal/small window layouts
and run menu, HUD, audio and combat checks.

## Task: Play The Selected March During Battle

Status: complete; import, headless/rendered audio checks and combat smoke pass
Priority: normal

Scope: Use music concept 1 as a quiet battle loop. Start with the first command,
pause/resume with gameplay, stop at the outcome and clear on restart. Preserve
concepts 2 and 3 as unused alternatives; no wave or screen music system.

Acceptance: Clean loop boundary, no restart from repeated movement commands,
correct lifecycle and no clipping in a rendered combat recording. No API calls.

## Task: Circular Recruitment Indicator

Status: complete; import, movement, combat, recruitment, audio, grave-visual and
UI checks pass; close-ups and crowded 1280 × 800 / 960 × 600 views inspected
Priority: normal

Scope: Replace recruitment percentages and compass-name labels with a filling
ring around the active crater and a matching diamond marker. Keep stock and
rotation time in a compact HUD readout; remove its duplicate progress bar.
Preserve recruitment, combat and audio timing.

Acceptance: The ring reads from the arena camera even beneath a gathered horde,
follows occupation, freezes on pause, resets on interruption and disappears on
closure/exhaustion. Check recruitment, grave visuals, UI, combat and rendered
views at regular/small window sizes.

## Task: Three Music Concepts

Status: complete; three previews rendered and decoded, levels checked
Priority: normal

Scope: Three short instrumental alternatives: a comic undead march, a medieval
groove and a tense siege rhythm. Keep generation spending conservative. The
ElevenLabs Music request was rejected because the account requires a paid plan;
compose and render local sketches instead. Do not add runtime music yet.

Acceptance: Three distinct playable previews, editable composition sources and
clear provenance. Verify audio files and levels; the user chooses a direction.

## Task: Additional Gameplay Sound Feedback

Status: complete; import, real-time headless/rendered audio checks, movement,
combat and recruitment checks pass
Priority: normal

Scope: Horde movement, bite contact, command/sprint feedback, successful
recruitment, temporary expiry and victory/defeat cues. Generate only two short
new source recordings; synthesize other cues locally. Keep sounds bounded and
gameplay rules unchanged; no music.

Acceptance: Steps follow actual motion, invalid sprint stays silent, repeated
commands/hits/expiry cannot stack audio, outcome plays once and restart clears
it. Check pause, rendered audio capture and existing gameplay regressions.

## Task: Essential Gameplay Sounds

Status: complete; import, real-time headless/rendered audio checks, movement,
combat, recruitment, grave visuals and rendered UI checks pass
Priority: normal

Scope: Generate three short source effects (gravestone, halberd impact, zombie
grunt), derive variants locally, and add clear attack warnings without further
API calls. Attach sounds to actual gameplay events with bounded playback.
No music or combat tuning changes. Keep credentials outside the repository.

Acceptance: Grave transitions and combat events trigger their sounds once;
crowd sounds stay sparse, warnings remain clear, and pause/outcome/restart stop
or freeze playback appropriately. Verify credit receipts, audio assets, event
timing and a recorded rendered run.

## Task: Animated Recruitment Craters

Status: complete; editor import, headless/rendered visual and recruitment checks,
headless combat and rendered UI pass; transitions and full-arena views inspected
Priority: normal

Scope: Replace recruitment circles with persistent shallow craters and three
gravestones that rise on availability and sink on window expiry or exhaustion.
Preserve recruitment rules, combat tuning and unobstructed movement. Audio is
discussion-only, with no sound or music implementation.

Acceptance: Availability remains clear, transitions freeze on pause and handle
interruption/restart, and depletion/rotation still change gameplay immediately.
Inspect rendered transitions and run focused visual/recruitment regressions.

## Task: Give The Knight A Flagged Halberd

Status: complete; import, headless/rendered animation, combat and rendered UI
checks pass; idle/run, all three attacks and arena views inspected
Priority: normal

Scope: Replace the hand-held sword with a simple low-poly halberd: long shaft,
axe blade, spear point and small pennant. Reuse the hand attachment and existing
attack clips; keep combat timing, damage and warning geometry unchanged.

Acceptance: The weapon is held correctly and reads as a flagged polearm in the
arena and close-ups; inspect idle/run and all three attacks, run animation and
combat regression checks.

## Task: Larger Arena And Simple Surroundings

Status: complete; import, movement/resize, combat, targeting, reinforcement and
UI checks pass; headless/rendered full runs pass and environment views inspected
Priority: normal

Scope: Enlarge the floor from 44 × 32 to 60 × 44 and add authored low-poly rocks,
scrub, low pebbles and ground patches. Keep combat tuning, initial actors and
recruitment sites unchanged. Preserve full-window framing and direct steering.

Acceptance: The extra ground accepts commands and remains visible on resize;
large props do not obstruct the walkable floor; actors and warnings remain
readable. Verify movement to new edges, combat, UI and complete encounter runs.

## Task: Fill The Game Window

Status: complete; import, headless/rendered movement and resize checks, rendered
UI and headless combat checks pass; four aspect ratios visually inspected
Priority: normal

Scope: Remove the apparent black inset around gameplay, fit the camera on resize,
and keep the HUD over the world. Preserve arena bounds and command projection.

Acceptance: Ground reaches every window edge, the full playable arena remains
visible, resized views have no letterboxing, and UI/ground clicks still work.

## Task: Character Animation Feel And HUD Simplification

Status: complete; focused motion/UI checks and headless full runs pass;
integrated rendered full run passes, close-up motion and arena states inspected
Priority: high

Scope: Whole-body knight anticipation/strikes/recovery, zombie gait/bite/hit/death
responses, and a less crowded HUD on the existing UI branch. Preserve gameplay
parameters and damage timing. No audio, shaders, world-art pass or new mechanics.

Acceptance: Actions read distinctly in motion; hit poses match gameplay timing;
visuals never move gameplay roots; pause and cleanup remain correct. HUD reduces
persistent cards/copy, retains working controls and communicates actual state.
Inspect close-up motion and arena gameplay; run existing regression checks.

## Task: In-Game UI Prototype On A Separate Branch

Status: complete; import, viewport-click UI checks, combat/movement regression,
reinforcement checks and full headless balance pass; rendered states inspected
Priority: normal

Scope: `ui-hud-prototype`, based on gameplay checkpoint `f6d4513`. Styled knight
health/phase, horde composition, temporary expiry, recruitment window and sprint
HUD; working pause/resume/restart/sprint buttons and result overlay. Keep combat,
models and tuning unchanged. No new game modes, audio or shaders.

Acceptance: HUD reflects real gameplay, modal clicks never command the floor,
buttons work during pause, replay resets the scene, and ready/mixed/critical/
pause/win/loss views fit the tested 1280 × 800 and 960 × 600 windows.

## Task: Permanent Horde And Rotating Temporary Reinforcements

Status: complete; mechanics, headless full runs and rendered full run pass;
HUD, mixed crowd, recruitment, warnings and outcomes inspected
Priority: high

Scope: Permanent starters, 45-second temporary recruits, immediate defeat on
permanent wipe, one active recruitment site rotating every 30 seconds with a
fresh batch of 12. Shared controls, cap 60, functional kind/count/timer feedback,
pause/restart and separate killed/expired statistics. Preserve the targeting fix.
Waves, weapons and progression changes remain discussion-only.

Acceptance: Both expiry and combat death remove agents exactly once; temporary
survivors cannot prevent defeat. Site rotation, partial batches/cap and timers
work through pause/restart/outcomes. Passive play loses and active viewport-input
runs win with permanent survivors. Inspect rendered grouping, HUD and outcomes.

## Task: Aim At The Larger Zombie Group

Status: complete; focused headless/rendered checks, editor import, combat,
movement and full-run balance regressions pass
Priority: high

Scope: Sweep and charge should favor the largest reachable group instead of the
nearest singleton. Preserve the locked warning/dodge window, damage and existing
progression. Verify a nearby singleton against a crowd, out-of-range distractions,
a sector aimed between groups, actual damage, and no tracking during windup.


## Task: Finish The Jam Gameplay Loop

Status: complete; headless mechanics, full runs, character and movement checks
pass; rendered full run and gameplay captures inspected
Priority: high

Scope: One knight fight with three health phases, warned sweep/charge/spin
attacks, purposeful knight movement, horde sprint, and finite reinforcement
sites. Complete start, win/loss, pause, restart and functional feedback. Keep
existing models, simple arena, scene composition, and direct references.

Acceptance: A complete active run can win; passive play loses; all attack shapes
and phase transitions work; sprint and reserves are bounded and reset on replay;
no combat continues after the outcome or while paused. Test actual viewport
input and inspect rendered fights. No presentation polish or unrelated systems.

## Task: Tune Health, Knight Movement, And Sword Attacks

Status: complete; headless and rendered balance checks, combat and movement
regressions, and editor import passed
Priority: high

Scope: Experiment with both sides' HP, standing versus walking knight, and sword
sector area/damage. Select a harder fight with a demonstrated active win.

Result: Stationary knight, 1000 HP; zombies 30 HP; sword 15 damage, 2.2 radius,
160-degree sector; 1.3 s tell and 1.2 s recovery. Walking was tested and rejected
because it either only demanded retargeting or stalled late fights. Ordinary
viewport-click tests cover four approach directions and show passive losses
versus active wins. Detailed evidence is in [TESTING.md](TESTING.md).

## Task: Add Health And Reciprocal Melee Combat

Status: complete; headless and rendered combat checks passed
Priority: high

Scope: Zombies automatically bite the knight in range; the knight turns and
swings at nearby zombies. Both sides have health and death. Show knight health,
remaining zombies, a victory/defeat result, and R to restart. Preserve horde
commands and separation. No roaming AI, progression, or other gameplay systems.

Verification: Import/startup, movement smoke, character checks, and combat smoke
pass. Combat checks cover ranges, cooldowns, warned/locked swing, retreat,
death/removal, both outcomes, stopping and restart. The initial commanded battle
ended in about 20 seconds with 25 zombies remaining; later balance work above
supersedes those parameters. Rendered battle, HUD,
result, and close-up sword poses were inspected; no human playthrough.

## Task: Replace Arena Capsules With Animated Characters

Status: complete; headless and rendered smoke tests passed
Priority: high

Scope: Instance zombies for the horde and the knight for the survivor. Keep
existing steering and bounds; drive run/idle and visual facing from actual agent
movement. The stationary knight plays idle.

Verification: Character asset checks and the extended prototype smoke test pass.
Rendered initial, moving, gathered, corner, and survivor captures were inspected.
No attack animation or gameplay system was added.

## Task: Build And Animate The Two Character Concepts

Status: complete; source, export, and rendered checks passed
Priority: high

Scope: Create editable Blender zombie and medieval knight assets based on the
approved v4 concepts, with rigs and looping idle/run animations. Export GLB
assets and verify their animation playback in Godot. Keep arena gameplay intact.

Acceptance criteria: Both source files open, meshes are weighted to usable rigs,
both clips animate and loop, exported assets retain their materials and skinning,
and rendered poses have been inspected. No attack animation is requested.

## Adding A Requested Task

Record only user-authorized work with a short title, status, priority, scope,
observable acceptance criteria, and verification steps. Keep each task small
enough for one focused implementation pass. Current implementation and completed
verification belong in [PROJECT_STATE.md](PROJECT_STATE.md).
