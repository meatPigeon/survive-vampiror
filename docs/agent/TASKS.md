# Tasks

## Active Work

Animation/HUD revision complete; no implementation task remains active.
Wave/progression changes are explicitly discussion-only.

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
