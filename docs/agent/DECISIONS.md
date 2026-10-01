# Architecture Decisions

## Export A Single-Threaded Web Release With Bundled Fonts

Status: accepted, 2026-10-01

Decision: Use Godot's matching 4.7.2 single-threaded Web release template with
PWA disabled, packaging index.html and its generated companions at ZIP root.
Ship Noto Sans/Serif with DejaVu glyph fallbacks and license notices rather than
relying on native system-font lookup. Hide Quit only on web.

Reason: The user needs an immediately uploadable itch.io build. Single-threaded
Web avoids host isolation/header requirements. Browser verification exposed
missing system fonts/symbols, and excluding all of art would omit the runtime
hit-flash material, so only authoring subdirectories are excluded.

## Keep Difficulty In The Current Scene

Status: accepted, 2026-10-01

Decision: Offer Newbie and Normal on the title, with Newbie preserving the
previous balance as the startup default. Normal resolves every knight hit as
the target's remaining HP; the crossbow remains lethal in both modes. Pass a
single mode flag into freshly instantiated menu/arena scenes using Godot's
native scene replacement, and apply it whenever Arena prepares a knight.

Reason: The user requested two starting modes distinguished by knight
lethality. Keeping this rule at knight damage resolution preserves Health,
zombie abilities, warnings and hit shapes. Explicit scene handoff retains the
selection through replay and menu return without an autoload or saved settings.

## Animate Wave Text Without Delaying Rewards

Status: accepted, 2026-10-01

Decision: Use the reward screen's heading for a fade/scale "Wave cleared"
announcement. Display the real intermission timer in a separate large HUD
readout after the choice, pulsing only when the integer second changes. Pause
both native tweens explicitly because their parent HUD processes during pause.

Reason: The user requested animated wave-clear text and a larger waiting label.
This preserves immediate card interaction and existing round timing, without
adding a transition state, duplicate timer or blocking cinematic.

## Give Perks Bounded Audio And Separate Menu/Battle Music

Status: accepted, 2026-10-01; supersedes March as battle music

Decision: Reuse existing recordings with offline synthesis for six sub-second
perk cues. HordeAbility emits accepted activation, batched impact and natural
feast expiry signals; BattleAudio binds both slots to one cast/one impact voice.
Keep Sprint's existing cue. Undead March stays on the menu; Graveyard Groove
loops in battle from a committed lossless render, using the existing Music bus.

Reason: The user requested perk sounds, limited credit use and this explicit
music split. Current scene ownership and audio buses already supply pause,
cleanup, independent volume and bounded playback. No new service is needed.

## Put Existing Characters On The Title Screen

Status: accepted, 2026-10-01

Decision: Frame the title and main action beside a small graveyard diorama built
from imported character visuals and existing props. Run only their idle clips
inside a noninteractive SubViewport. Reveal the reused volume controls with
Audio instead of keeping a settings column on the initial screen.

Reason: The user wants the menu to feel more like the game. Reusing its models,
materials and typography establishes that identity without new art dependencies,
custom shaders or an active combat world behind the menu.

## Add An Inertial Mounted Pursuit Attack

Status: accepted, 2026-10-01

Decision: Add Stampede alongside the existing mounted attacks. A stationary
warning precedes 4.2 seconds of forward travel, with linear acceleration,
bounded turn rate and angular acceleration toward the live horde center. The
horse does not stop at its target. A boundary contact ends the attack and
exposes the knight for the same 2.8-second recovery as a normal timeout.
Damage is 20 once per zombie per attack. Keep selection, steering, swept hits,
timers and cancellation inside Survivor; reuse native preview/animation/audio.

Reason: The user requested a long pursuit like the described Minotaur attack,
where momentum permits sharp evasive turns. A tracking lock-on or repeated
contact damage would undermine that counterplay. Moving chevrons show heading
without suggesting the straight lane guaranteed by the separate short charge.


## Use Shipped Models For Static Reward Illustrations

Status: accepted, 2026-10-01

Decision: Render mines, sling, feast and sprint artwork offline from the actual
zombie models and simple native meshes. Load the four PNGs in reusable Button
cards; keep selection in ZombieUpgrades and reward rules in Arena. Retain the
existing serif/bone/dark-green UI, with individual accents and explicit selection.

Reason: The user wants proper illustrated cards that match the game. Reusing
its characters preserves their proportions and materials without an external
asset pipeline, generation credits or four live 3D viewports in the interface.

## Make Sprint A Between-Wave Perk

Status: accepted, 2026-10-01; supersedes default sprint access

Decision: Add Sprint to the same random unowned reward pool as mines, sling and
feast. It consumes that wave's choice and unlocks the existing Space/HUD action,
without consuming Q/E. Keep 2x speed, 1.4-second duration and seven-second cooldown.
Hide its control and reject requests before acquisition. Ownership survives
later waves, disappears from future offers and resets with a new run.

Reason: The user explicitly moved sprint out of the default kit and into perks.
Retaining its familiar movement shortcut avoids a duplicate active-skill button
or moving a previously learned Q/E skill. Existing horde-owned timers and scene
restart already provide the required lifecycle; no perk framework is needed.

## Follow The Mobile Horde At Close Zoom

Status: accepted, 2026-10-01; supersedes arena-centered zoom at close distances

Decision: Below zoom factor 1.0, ease the existing camera's X/Z position toward
the mean mobile-agent position. At the default scale or farther out, ease back
to the authored overview. Preserve rotation/height and native pause. Exclude
ability-locked agents, matching the crowd controlled by movement; hold position
when none remain. Use an explicit HordeController export, with no camera rig or
new controller layer.

Reason: The user wants zoomed camera tracking. This keeps the commanded crowd
in view while retaining the existing wide arena view and mouse-ground projection.

## Distinguish Zombie Kinds Through Appearance And Ring Shape

Status: accepted, 2026-10-01; supersedes color-only kind markers

Decision: Keep permanent zombies' warm original palette with a solid ivory ring.
Give temporary recruits pale-blue skin, dark-blue clothing, a ragged shoulder
mantle and a four-part cyan ring. Match both shapes in the HUD count legends.
Ability feedback may recolor/scale rings but never changes their geometry or outfit.

Reason: Foot-ring color alone disappears under a crowd and is overridden by
abilities. The user requested clearer identification. Body palette, a distinct
garment and ring shape remain useful together at gameplay distance, without
floating nameplates, shader effects or gameplay differences.

## Aim The Zombie Sling Manually With Visible Scatter

Status: accepted, 2026-10-01; supersedes automatic shots at the knight

Decision: Its Q/E key or HUD button enters mouse aim; LMB fires, RMB or the same
key cancels. A cyan radius-2.5 ground disk shows possible landing positions;
invalid range/bounds turns it red. Sample one uniform random point inside it
at firing and retain the existing flight, impact damage/radius and cooldown.
Select the nearest available temporary zombie whose range covers the whole disk.

Reason: The user wants manual mouse targeting with a small area of possible
hits. Actual randomized landing supports leading the knight without a separate
probability calculation, targeting framework or change to knight behavior.

## Acquire Additional Zombie Abilities Between Rounds

Status: accepted, 2026-10-01; supersedes pre-battle selection and retained abilities on restart

Decision: Start with ordinary zombies. After each of the first two knight defeats,
offer two different random unowned abilities, or skip for exactly +10 permanent
zombies. Later choices add a second skill; they do not enhance or replace the
first. Reuse two HordeAbility nodes with separate Q/E input and cooldowns.
Restart restores the original horde and empty slots.

Reason: The user chose between-round progression, two cards or a permanent-horde
bonus, and explicitly requested another ability at the later choice. Arena owns
one-time claims and waits indefinitely, then starts its existing countdown.
No ability framework, save state or knight changes are needed.

Consequences: A bonus bypasses the grave recruitment cap so its full amount is
honored. It cannot resurrect an ended run. Surviving wounds/lifetimes remain.
Mine selection excludes a flying recruit; feast preserves committed markers.

## Make Crossbow Bolts Lethal And Piercing

Status: accepted, 2026-10-01; supersedes the original first-target 20-damage bolt

Decision: Each bolt removes the current HP of every intercepted living zombie
and continues along its locked line until its existing range ends. Resolve
swept hits in travel order from a separate list, stopping immediately if a
death ends the run. Preserve warning, width, speed, range and firing cadence.

Reason: The user explicitly requested one-shot kills and multiple casualties
per bolt. Current-HP damage keeps this rule true for upgraded zombies while
using the existing health/death contract and preserving sideways evasion.

## Draw Air Motion Within Existing Character Visuals

Status: accepted, 2026-10-01

Decision: Reuse a small MotionAir scene under each character Visual. Built-in
transparent, unshaded ribbons draw a moving crescent at knight melee impact
and two staggered side streaks for fast travel. Visuals enable them at existing
attack/movement transitions; actual world displacement gates the speed effect.

Reason: The user requested a sense of cutting through air during knight attacks
and acceleration and zombie sprinting. Brief pale strokes preserve the stronger
colored ground warnings without adding shaders, particle textures, spawned
effect nodes or combat authority. Pause and cleanup inherit scene ownership.

## Three Scene-Owned Zombie Abilities

Status: accepted mechanics, 2026-09-30; acquisition/restart superseded by the between-round decision

Decision: Implement delayed half-horde explosions, one-temporary-zombie sling
shots and Blood feast (faster bites with self-healing). The user confirmed the
explosion cost includes permanent zombies and delegated the third mechanic.
Keep one selected ability on Horde/Ability, activated by Q or HUD. The fourth
card is the unmodified baseline. Pass the enum into Arena before scene entry;
retain it across waves/restart, without a service or save system.

Reason: These give different uses for positioning and expendable recruits.
Blood feast rewards a close attack window and lives entirely in zombie bite
logic, keeping the parallel knight work independent. Existing permanent-wipe
defeat, expiry, health and explicit scene composition remain authoritative.

## Escalate The Knight Across Three Waves

Status: accepted, 2026-09-30; supersedes discussion-only waves and one-knight victory

Decision: Implement three waves: halberd, added crossbow, then mounted with both
weapons. The user confirmed surviving horde carryover and warned ranged shots
alongside melee. Arena replaces only the defeated knight after a configurable
four-second break, preserving the horde and freezing combat/lifetime/site/sprint
timers. A new knight appears away from the surviving group. Victory requires
all three; permanent wipe remains an immediate loss.

Reason: Successive equipment changes give each wave a different threat. A cyan
locked lane precedes a finite, non-homing bolt that hits the first zombie along
its swept segment. The mount increases pursuit and charge speed; a simple native
mesh horse and riding pose make the upgrade visible without a new asset pipeline.
Initial health is tuned for the existing unupgraded horde and remains exported.
Zombie modifications and their selection screen belong to the parallel session.


## Preview Zombie Modifications Before Battle

Status: superseded by between-round acquisition on 2026-10-01; historical UI scope

Decision: Main-menu Play opens a scene-owned screen with four numbered cards,
one local UI selection and Begin battle. Reuse a simple native Button scene
and ButtonGroup; keep menu music running. No modifier data model, stat changes,
gameplay hooks or persistence until the user specifies actual zombie mechanics.

Reason: The user requested selectable placeholders and chose placement before
battle. Knight work belongs to a separate session.

## Direct The Horde With Physical WASD

Status: accepted, 2026-09-30; supersedes left-click movement and target markers

Decision: Hold physical WASD for normalized camera-relative movement of the
whole horde; release to stop. Keep loose crowd cohesion/separation and arena
bounds. First nonzero movement starts the battle; Space remains sprint.
Recruitment depends on actual occupation, including standing still with keys
released. Pause and focus loss clear held movement. Input remains scene-owned.

Reason: The user requested WASD horde control and removal of mouse movement.
A shared direction alone stretched the crowd and failed the full-run check;
cohesion keeps the commanded group together without formation slots or tuning
knight damage, attack timing, zombie stats or recruitment parameters.


## Continue Development On Main

Status: accepted, 2026-09-30; supersedes the separate UI experiment branch workflow

Decision: Consolidate all current gameplay, presentation, menu and audio work
on `main` and use it for further development. Preserve the existing commits
and prototype branches as historical checkpoints.

Reason: The user requested that all current work move to `main`.


## Consume Each Recruitment Visit; Delay The Next Random Site

Status: accepted, 2026-09-30; supersedes preserved leftover stock and fixed
west/south/east cycling in the earlier temporary-reinforcement decision

Decision: Any successful summon consumes the site's current activation, even
when only part of its batch fits. Hide its ring immediately and sink the graves.
Arena waits an exported `site_respawn_delay` (default 5 seconds), then randomly
opens one of the other two sites. Keep the first West opening and 30-second
unused-site lifetime; unused timeout also chooses a different location.

Reason: The user reported repeat recruitment from a still-visible used ring and
specified disappearance, random next selection and an adjustable pause. A real
viewport-input reproduction confirmed that 52 zombies became 60 with four stock
left, then another casualty triggered another summon from that same site.

Consequences: No site is available during the gap. Existing availability drives
ring visibility, graves and audio. The HUD reads the actual deadline; pause,
outcomes and restart keep all scheduling within scene-owned battle time.

## Main Menu With Native Audio Bus Controls

Status: accepted, 2026-09-30

Decision: Use a separate title scene and one reusable AudioControls scene on
the title and pause screens. Two authored Godot audio buses own music/effect
gain and mute for the application session. Return-to-menu is an explicit HUD
signal handled by Arena; no active arena is hidden behind the title.

Reason: The user requested a main menu and independent volume adjustment.
Native audio buses preserve levels across reloads without adding a singleton,
persistence service or a broader options system. Gameplay rules stay separate.

## Show Recruitment Progress At The Crater

Status: accepted, 2026-09-30

Decision: Replace floating site names/percentages with a shallow annular progress
mesh. A dark track and pale mint clockwise fill surround the active crater;
a diamond marks its start and matches the HUD stock readout. Keep rotation time
in the HUD but remove its duplicate progress bar. Built-in unshaded materials
draw the indicator over characters so an occupying crowd cannot hide feedback.

Reason: The user requested a circular fill and simpler symbolic identification.
Only one site is available at a time, so the marker and raised graves identify
the destination without West/South/East labels or another text layer.

Consequences: ReinforcementVisual consumes normalized occupation progress from
its site; it owns no timer, recruitment rules or collision. No custom shader,
dependency or gameplay-tuning change is needed.

## Compare Music Before Runtime Integration

Status: accepted, 2026-09-30

Decision: Deliver three short, original MIDI-based music sketches rendered
offline, keeping them in `art/audio/music_concepts/` outside Godot import.
Wait for the user's selection before adding background playback.

Reason: The user requested three alternatives and conservative credit use.
ElevenLabs rejected the Music API request with `paid_plan_required`; the local
sketches allow comparison without a subscription change or further API calls.

Follow-up: The user selected concept 1, Undead March. Its lossless render is now
processed into one looping Ogg, played by the existing scene-owned BattleAudio.
The first ground command starts it; pause, outcome and restart share the existing
audio lifecycle. Concepts 2/3 remain unused; no wave/screen music system is added.

## Add A Small Scene-Owned Gameplay Sound Set

Status: accepted, 2026-09-30

Decision: Use five short generated sources and offline synthesis/processing
for essential combat and recruitment cues. A BattleAudio scene receives explicit
gameplay/visual signals, with eleven bounded players and shared voice/bite cooldowns.
Keep audio independent of combat timing, and keep API calls out of the game.

Reason: The user authorized sound implementation and stressed limited credits.
The first three one-second requests reported 30 credits total; the requested
second pass added two half-second recordings for 10 more. Reusing recordings
and synthesizing warning/swing/notification cues supplies feedback with sparse
crowd audio. Movement cues follow actual travel; rejected sprint stays silent.
Music remains outside this pass.

## Show Recruitment Availability With Animated Gravestones

Status: accepted, 2026-09-30

Decision: Keep a shallow crater at every recruitment site; raise three stones
while the site has stock and sink them when unavailable. A separate visual
component owns interrupted/pause-safe tweens; gameplay changes state immediately.

Reason: The user requested animated crater/grave landmarks. Persistent meshes
and local visual transforms fit the current flat arena without terrain cutting,
collision, navigation or changes to recruitment timing and stock.

## Enlarge The Clearing With Static Decorative Surroundings

Status: accepted, 2026-09-30

Decision: Use a 60 × 44 flat floor, shared low-poly prop scenes and authored
placements. Put large rocks outside the playable bounds; keep only low scrub,
pebbles and ground patches inside. Retain the window-fitted camera, combat
tuning and recruitment-site positions.

Reason: The user requested a larger map and simple surroundings. This provides
space and environmental landmarks while preserving the current steering and
encounter, without introducing navigation or procedural generation.

## Use Godot 4.7, Typed GDScript, And Reusable 3D Scenes

Status: accepted

Decision: Use reusable Node3D entity scenes and simple materials with the
Compatibility renderer. Arena geometry remains primitive; entity visuals use
the requested rigged zombie and knight assets.

Reason: This meets the requested 3D prototype with the installed engine and no
external runtime dependencies.

Consequences: Keep the survivor as a standalone scene. Its script owns the requested nearby-target melee response and visual playback;
it has no roaming or general AI framework.

## Separate Input, Horde Intent, And Agent Movement

Status: accepted

Decision: GroundCommand emits movement intent; HordeController owns the shared
target and calls HordeAgent movement through direct references.

Reason: This adapts the sibling project's signal-up/call-down and reusable-scene
conventions to a small 3D prototype.

Consequences: Keep scene-bound logic in `scripts/gameplay/` and input in
`scripts/input/`. No autoload, event bus, service layer, or pure-core abstraction
is needed for this slice.

## Use Planar Steering And Local Separation

Status: accepted

Decision: Combine attraction to the shared target with short-range repulsion,
limit movement speed, and clamp agent bodies inside the floor.

Reason: An empty flat arena needs neither a navigation system nor formations.

Consequences: Agents have no assigned destination slots. Neighbour checks are
quadratic in crowd size. Ground transforms and obstacle handling remain limited
as documented in [SPEC_ARCHITECTURE.md](SPEC_ARCHITECTURE.md).

## Keep Agent Documentation Split By Responsibility

Status: accepted

Decision: Follow `../sumdyq-sozdik` with a root `AGENTS.md`, canonical
`docs/agent/` state/tasks/decisions, and focused architecture/gameplay specs.
Keep testing instructions and terminology in dedicated small references.

Reason: Agents can find current facts without turning permanent instructions
into a development diary.

Consequences: Adapt content to this game; do not copy the sibling's word-game
rules, services, backlog, or approval workflow. README remains the player-facing
launch guide and documentation entry point.

## Keep Editable Blender Sources Separate From Engine Exports

Status: accepted

Decision: Store the requested zombie/knight sources and previews in
`art/characters/`, ignored by Godot, and GLB exports in `assets/characters/`.
Use simple custom armatures with source foot IK and baked in-place idle/run clips.

Reason: The assets can be edited and animated in Blender and imported by Godot
without making Blender a runtime or import dependency for the game.

Consequences: Preserve loop settings in the GLB import sidecars. The authoring
script overwrites generated sources when explicitly run; protect manual edits
before regeneration. The separately requested scene integration instances GLBs
under entity visuals, with animation driven by movement rather than root motion.
The later combat request adds a runtime sword swing without rebuilding these
source clips. See [the asset guide](../../art/characters/README.md).

## Resolve The Requested Melee Fight Through Explicit Scene References

Status: accepted

Decision: Compose a small Health node into both entity scenes. Zombies own bite
range/cooldown; the knight owns nearest-target selection and a locked, warned
sword arc. The arena ticks combat after movement, updates the HUD, stops the
fight on death of either side, and reloads the scene on R.

Reason: Health, damage and a knight that kills zombies are now explicitly
requested. A stationary melee response supplies that loop without navigation,
a state-machine framework, or global combat services.

Consequences: Damage uses distance/angle checks, not sword mesh collisions.
Dead zombies leave the active crowd immediately and are freed after a short
fall/shrink. The knight has a simple runtime arm animation and hand-held sword;
the Blender files retain their original idle/run Actions. The small HUD and
restart expose the fight's result; they are not a menu/UI framework.


## Make The Existing Warned Swing Matter Before Adding More AI

Status: superseded on the jam branch; retained in baseline commit dc63168

Decision: Use 1000 knight HP, 30 zombie HP, and a 15-damage, 160-degree,
2.2-radius sword swing. Windup is 1.3 seconds; recovery is 1.2 seconds. Keep
his position fixed. No new combat system or movement framework is retained.

Reason: Larger HP alone and slower retreat still allowed passive wins. Faster
retreat defeated a stale click but lost easily to simple retargeting; some
stronger moving variants stalled against the last zombie. The selected stationary
fight distinguishes staying in the arc from reacting to the existing tell.

Consequences: Health and damage preserve two hits per zombie. A wider arc raises
crowd losses while a longer windup allows deliberate commands. Regression tests
compare actual mouse-driven passive and active play from four starts. This is
an initial tested balance, not a global optimum. See [TESTING.md](TESTING.md).


## Ship One Complete Encounter For The Gameplay-Only Jam Request

Status: accepted for `gpt-full-game-test`

Decision: One roughly three-minute knight encounter with three health phases,
warned sweep/charge/spin attacks, deliberate pursuit, a horde sprint and three
finite reinforcement sites. Start waits for a command; pause/restart and both
outcomes are complete. Technical HUD and geometry communicate the rules.

Reason: This supplies a beginning, changing tactical decisions, recoverable
losses, limited resources, and a final win/loss without adding a campaign,
upgrade tree, new character assets or unrelated systems. The user authorized
finishing the gameplay and explicitly excluded presentation polish.

Consequences: Knight movement now pursues/charges rather than retreats, avoiding
the earlier fleeing-last-zombie stall. Warning origin/direction stays fixed.
Animation and warning drawing were separated from knight combat to keep it
readable. All state remains scene-owned; a small enum is sufficient for the
three attacks. Reserve sites request recruitment through HordeController and
preserve unused stock at the cap. Presentation can change independently later.

Validation: Actual viewport-driven full runs lose with passive/reckless play
and win with delayed reactions, sprint and reserves. Unit/scenario checks cover
pause/replay, death, attack geometry and finite resource rules. See
[TESTING.md](TESTING.md) for evidence and limits.


## Aim Directional Attacks At The Larger Reachable Group

Status: accepted, 2026-09-30

Decision: At attack selection, score candidate sweep sectors and charge lanes
by living targets covered. Consider center and edge directions rather than only
headings directly toward a zombie. Reuse the charge endpoint calculation for
scoring and execution. Keep pursuit, attack patterns and locked windup unchanged.

Reason: The closest individual previously distracted the knight from a nearby
crowd. Scoring the actual attack footprint avoids targeting an unreachable mass
or averaging opposing clusters into empty space. The check only runs when an
attack begins; no new AI framework is needed for the capped crowd.

Consequences: Spin remains omnidirectional. The knight/preview agree on direction
after floor clamping. Wave-based progression and new weapons are discussion-only;
this fix does not implement or change progression.


## Preserve The Starting Horde; Make Reinforcements Temporary

Status: accepted, 2026-09-30; supersedes finite per-run reserves and total-wipe
loss in the earlier jam encounter decision

Decision: Keep 40 permanent starters and shared movement/sprint. Defeat is the
loss of the last permanent zombie, regardless of temporary survivors. Recruits
live for 45 seconds from spawn, with the same combat stats. One of the existing
three sites is active per 30-second window, west/south/east in order, each with
12 recruits. Unused stock is lost on rotation; total living cap remains 60.

Reason: The user wants irreversible losses in the original army and expendable
short-lived reinforcements, without splitting controls or implementing waves yet.
Fixed windows encourage movement and bounded batches prevent stock accumulation.

Consequences: Arena owns the schedule and permanent-wipe outcome; the controller
owns composition and lifetime ticking; agents retain ordinary Health/death
handling and identify expiry for statistics. Ordinary colored rings and existing
HUD labels expose the rules. No new infrastructure or art is required. Knight
HP, attack geometry, targeting and HP-phase progression remain unchanged.


## Isolate The Requested UI Experiment

Status: accepted, 2026-09-30

Decision: Preserve the verified gameplay in `f6d4513` on `gpt-full-game-test` and
build the UI on `ui-hud-prototype`. Use a reusable Godot Control/CanvasLayer
scene with a presentation script, shared built-in styles and explicit signals
to existing gameplay handlers. Keep tuning and game rules unchanged.

Reason: The user requested a UI draft on its own branch. Moving display strings
out of Arena keeps presentation changes separate from combat ownership, without
a UI framework or dependency. Earlier no-UI-polish scope is superseded only for
this authorized HUD and pause/result exploration.


## Add Character Weight Without Changing Combat; Reduce HUD Density

Status: accepted, 2026-09-30

Decision: Answer the animation/cheap-crowded-UI feedback on the current UI branch.
Add runtime pose/secondary-motion responses under the existing visual nodes;
keep attack impact synchronized to gameplay, preserve locked aim and leave
movement/damage parameters unchanged. Retain authored idle/run source assets.
Replace the numbered dashboard with a slim boss bar, grouped horde counts,
contextual recruitment/sprint information and fewer world labels.

Reason: Anticipation, sharp contact, recoil and follow-through make the existing
combat readable; context and hierarchy reduce persistent UI noise. Separate
visual components follow the existing KnightVisual precedent without a new
animation framework, global time manipulation, shader or dependency.
