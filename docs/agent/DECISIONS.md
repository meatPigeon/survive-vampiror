# Architecture Decisions

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
