# Gameplay Spec

## Game Modes

Before starting, the title offers two exclusive choices. Newbie is selected on
fresh application startup. It preserves the existing 15-damage sweep and
20-damage charge, spin and mounted stampede. Normal makes every knight hit kill
any zombie immediately, regardless of kind or current/max HP. Crossbow bolts
remain lethal and piercing in both modes. Warnings, hit shapes, timing, knight
health, movement, rewards and reinforcement rules are identical.

The scene owns the choice and applies it to each wave's new knight. Restart
resets the run while retaining its mode; returning to the title restores that
selection and allows changing it before the next run. No disk persistence.
The HUD identifies the mode beside the wave/phase readout.

## Complete Run

Main-menu Play opens the ready arena with no ability and sprint locked. After waves 1 and 2,
present two distinct random perks not already owned, from Sprint, Corpse mines,
Zombie sling and Blood feast. Select one card and
confirm, or skip both for exactly 10 healthy permanent zombies. The first
acquired active ability uses Q; a second adds E without replacing or upgrading Q.
Sprint unlocks Space and does not occupy Q/E. Skipping or choosing Sprint leaves
Q available for a later active skill. No rewards after the final victory.
Restart clears all perks, including sprint ownership, and reward zombies.

The reward screen has no timeout. Battle elapsed time, lifetimes, sites,
movement, sprint and ability timers freeze until a decision, then remain frozen
during the normal four-second countdown. Esc opens pause and resumes the same
cards/selection. Each intermission accepts only one reward; invalid, paused,
repeated or post-outcome requests cannot grant anything. Skip adds the full ten
even at/above the grave recruitment cap of 60. Survivors keep existing wounds
and lifetimes; new permanent members have full health and no expiry.

One flat 60 × 44 arena, one knight, 40 player-controlled zombies. The camera has
a fixed angle; wheel up/down smoothly zooms in/out. Below the default zoom
factor 1.0, the camera smoothly follows the mean position of mobile horde
members. Planted mines and flying sling zombies do not pull it away from the
controlled crowd. With no mobile members it holds its last position. At 1.0
or farther out, it eases back to the authored arena overview.
View size ranges from 0.45 to 1.25 times the window-fitted default. Zoom alone
does not start combat; pause/results block zoom input, and pause freezes follow.
Resize preserves zoom and focus; restart resets both to the arena overview. The run waits for the first movement command. Defeat all three knight waves
to win; zero living permanent zombies loses immediately, even with temporary survivors
or an available recruitment site.
A technical result display shows elapsed time, combat casualties, expired
temporary zombies and recruited count.
R resets gameplay while retaining the selected mode; Esc pauses/resumes the scene tree. Input remains
available for resume/restart while paused. Physical key positions support
non-English keyboard layouts.

## Horde

- Hold physical WASD to move the entire horde relative to the camera. Release
  to stop immediately. Opposing keys cancel; diagonals are normalized. Floor
  clicks do not move the horde or start combat. Pause/focus loss clears held keys.
- Each zombie follows that direction with crowd cohesion, local separation and
  bounds clamps. Cohesion preserves a loose group without assigned slots.
  The living knight's body excludes zombies from its center. No formations,
  obstacles, navigation, or per-unit selection are implemented.
- The 40 starting zombies and round-reward additions are permanent: no lifetime
  limit or resurrection. Olive skin, warm clothes and solid ivory foot rings
  identify them. Recruits have pale-blue skin, dark-blue clothes, a short ragged
  mantle and broken cyan rings, with 45 seconds of life from their individual spawn time. Returning
  to a site does not pause or reset this lifetime.
- 30 HP per zombie. In range 1.15, it bites for 4 damage once per 0.8 seconds.
- Only after choosing the Sprint perk, Space gives 2× movement speed for 1.4 seconds, with a 7-second cooldown from
  activation. Requires the run to have started with movement; cannot refresh early.
  No invulnerability or damage bonus. Timers freeze during pause. Before the
  perk, Space/direct requests do nothing and the HUD control is hidden.
- Run/idle and facing follow actual movement. Dead zombies leave the active
  list immediately, tumble/shrink (or softly collapse on expiry), then are freed within 0.6 seconds. Death emits once.

## Zombie Abilities

Physical Q/E or the corresponding HUD button activates the first/second owned
ability once the run starts. Each has independent state and cooldown. Invalid requests cost nothing and do not start a cooldown.
Cooldowns begin at activation, except sling starts its cooldown only on firing.
Pause and wave breaks freeze all ability timers
and reject activation; outcomes cancel pending effects. Ordinary movement and
the acquired Space sprint remain independent. No ability changes the knight's attack tuning.

| Card | Effect | Cooldown |
| --- | --- | --- |
| Sprint | Unlock Space/HUD for 2x movement speed for 1.4 s; leaves Q/E slots free. | 7 s |
| Corpse mines | Arm floor(living horde / 2) agents spread through the group, excluding any flying recruit. They stop moving/biting; after 2 s, each dies and deals 45 damage within radius 2.8. | 8 s |
| Zombie sling | Q/E enters mouse aim; LMB fires a temporary zombie into a uniform random point within the indicated radius 2.5 disk. The whole disk must lie within 22 units of an available recruit. A 0.8 s, 3.5-unit-high arc ends with its death and 100 damage within radius 2.0 of landing. | 2.5 s from firing |
| Blood feast | For 5 s, bites use a 0.4 s interval instead of 0.8 s and heal their owner by 2 HP, capped at max. New recruits join the active effect. | 15 s |

Sling's cyan outline/fill shows the possible landing area under the cursor.
Red means no available temporary zombie can reach the whole disk, or the disk
crosses playable bounds; off-viewport aim is hidden. Invalid clicks cost nothing.
It chooses the nearest unlocked temporary recruit to the aim point when fired.
RMB or the same Q/E key cancels aim. Pause, focus loss, wave transition, outcome,
restart and loss of all available ammo also cancel aim without spending a zombie.
Aiming does not pause combat or block WASD, sprint or the other ability. UI clicks
do not fire through controls. Zoom/resize reproject the ground under the cursor.

Spread is sampled uniformly over disk area. Damage follows actual distance to
the landing point, with no second hit-chance roll and no homing after launch.
The radius exceeds the impact radius, so even centered aim can miss a stationary
knight; movement during flight can also dodge it. No damage/range/flight/cooldown
tuning changed with the manual-aim conversion.

Armed/launched zombies stay in the living list and capacity until killed;
their temporary lifetime continues. They cannot recruit or bite while committed
to an ability. Early death or expiry cancels that zombie's pending damage.
The remaining horde's cohesion excludes committed zombies. Sling locks its
landing point, so movement can dodge it. Only the model rises/spins in flight;
the gameplay root stays planar and can still take damage. Mines have no friendly
fire. Sacrifices count as killed; natural expiry still counts as expired.
Healing cannot resurrect or extend a recruit's lifetime. Losing the final
permanent zombie resolves defeat before any queued sacrifice damage.

Feast applies to the horde without overwriting the orange mine or cyan flight
marker. Locked zombies still cannot bite. Releasing a lock restores violet if
feast remains active; canceling another ability does not end feast.

Ability tuning is exported on Horde/Ability and Horde/SecondAbility; feast bite
interval/healing are exported on HordeAgent. Orange/cyan/violet foot rings and brief ground markers
show commitment/impact; the HUD displays the active timer or cooldown.

## Knight Waves

Three waves share the same surviving horde and recruitment schedule. Wave one
has 800 HP and the halberd; wave two has 1000 HP and adds a crossbow; wave three
has 1200 HP and a horse while retaining both weapons. Arena exports wave count
(1–3), base HP, HP increase and break duration (default 4 seconds).

A defeat before the last wave opens the reward screen described above. Resolving
it starts a short visible countdown. Movement, sprint, lifetime, combat and site
timers freeze during the break;
menu pause also freezes the countdown. The next knight spawns at the interior
corner farthest from the crowd center, with full health and reset HP phase.
The same horde objects, wounds, composition, upgrades and statistics continue.
Restart resets the entire run; only defeating the last wave is victory.

## Knight

On foot: body radius 0.55, pursuit speed 1.5. He approaches the closest living
zombie and attacks when in range. Before each sweep/charge he compares candidate
directions and chooses one covering the most living zombies inside the actual
sector/lane. Candidates include directions between zombies; unreachable groups
do not draw his aim. Equal scores keep the initial nearest-target choice.
Charge scoring accounts for its floor-clamped endpoint. Spin is omnidirectional.
From wave two, a ready crossbow takes priority over melee at distances 3.5–16, with a
six-second cooldown. It adds to the existing melee pattern. A cyan lane locks
for 1.2 seconds, then a visible bolt travels at 16 units/second up to 16 units.
Its 0.4-radius swept collision instantly kills every intercepted living zombie,
including increased-HP and temporary zombies, and continues through the line.
Hits resolve front to back even over a large tick; deaths remove targets from
the horde once. It never homes or extends past its range. Recovery lasts 1.6 seconds.
Pause freezes the bolt; knight death and run outcomes cancel it.

From wave three, pursuit doubles to 3.0, charge speed multiplies by 1.4 and body
radius becomes 0.75. Windup durations and melee damage remain unchanged.
The horse is visual; the knight's existing planar body remains authoritative.

Mounted knights additionally use **Stampede** (`RUSH`). When its cooldown is
ready and a living target is within 16 units, it takes priority over crossbow
and melee. It begins with a 1.4-second stationary warning and locked initial
heading. The first opportunity is after 3 seconds; cooldown is 14 seconds from
attack selection. Red double chevrons identify the current heading rather than
claiming a fixed future path.

During the 4.2-second pursuit, he aims toward the current center of living zombies.
Speed accelerates from mounted pursuit speed to 8 units/s at 12 units/s².
Steering caps at 50°/s and changes angular velocity at no more than 100°/s².
There is no target prediction, instant reversal or braking at the target, so
crossing behind him or changing direction can make him overshoot. The existing
floor boundary ends the attack early without sliding; decorative props still
have no collision. Timeout or boundary contact starts a full 2.8-second stationary
recovery. All these parameters are exported on Survivor.

Swept contact uses a 2-unit-wide moving body and hits once per zombie per
stampede (20 damage in Newbie, instant death in Normal). Curved movement is
substepped at at most 1/60 second for contact
and steering even on a slow frame. Permanent wipe, knight death and outcomes
cancel remaining movement/hits immediately. Pause freezes momentum and timers.

Windups lock the attack's direction and origin;
he does not track targets during the warning. A distant target inside charge
range triggers a charge; a farther target is approached on foot. He remains
inside floor bounds. He stays still during recovery, giving the horde a bite
window. He does not flee the final zombie.

The damage column below describes Newbie; all Normal hits are lethal.

| Attack | Warning | Damage shape | Damage | Strike | Recovery |
| --- | --- | --- | --- | --- | --- |
| Sweep | 1.3 s, orange sector | Radius 2.2, angle 160° | 15 | 0.18 s | 1.4 s |
| Charge | 1.5 s, yellow lane | Width 2.0, up to 8.0 long, locked endpoint | 20, once per zombie | 0.7 s movement | 2.0 s |
| Spin | 1.8 s, purple circle | Radius 3.2, all directions | 20 | 0.5 s | 2.4 s |
| Stampede (mounted) | 1.4 s, red double chevrons | Width 2.0, moving curved path | 20, once per zombie | Up to 4.2 s | 2.8 s |

Sweep/spin damage resolves once when the warning ends, using current positions.
Charge checks the swept path each tick, excludes positions beyond the displayed
lane endpoints, and remembers already-hit zombies until that charge ends. The
warning stays fixed in world space while the knight moves. A charge with no
usable movement at a boundary falls back to a sweep. These are geometric damage
checks, not collisions with the visible halberd. The flagged halberd replaces
the hand-held sword visually; its length does not change these damage shapes.

Phase patterns change at HP thresholds; an attack already in progress finishes
with its original timing and shape:

1. Above two-thirds HP: sweep, sweep, charge.
2. At/below two-thirds: sweep, charge, spin.
3. At/below one-third: charge, spin, sweep, spin.

Patterns cycle; a distant target can substitute a charge. HUD text names the
phase, warning type and recovery window. Both sides briefly flash on damage.

## Rotating Temporary Reinforcements

Three sites: west (-14, -8), south (-10, 10), east (14, 8) on the X/Z plane.
All are inactive before the first command. West opens at battle time 0.
Each activation has 12 temporary recruits and lasts at most 30 seconds.
A successful summon closes the used site immediately, then waits for Arena's
exported `site_respawn_delay` (default 5 seconds; zero allows immediate reopening
elsewhere). After the delay, choose randomly between the other two locations;
never choose the just-used site. No site is available during the delay.
An unused site's 30-second deadline selects a random different site immediately.
Every opening gets a full new window; there is no global modulo schedule.

Recruitment requires at least one living zombie within radius 2.4 of the
site for 2 uninterrupted seconds. Stopping there with WASD released is sufficient.
Either kind can occupy it while permanent zombies remain alive. Leaving or
reaching capacity resets progress.
Grave recruitment cap is 60; permanent round rewards may exceed it. Add only as
many grave recruits as capacity permits, then discard the
rest of the batch and consume that activation. For example, 52 living zombies
receive 8, and the remaining 4 are discarded. Losses/expiry cannot reopen a used
site. Arriving already at capacity cannot start a summon or consume the site.

Arena ticks lifetime expiration before combat and recruitment. Expired zombies
leave the active list immediately and cannot bite that tick. Expiration uses
the normal death feedback but counts separately from combat casualties. Losing
the last permanent stops the current attack's remaining hits, bites and hiring
immediately. Once an outcome is set it cannot be reversed.

Pause freezes lifetimes and the site schedule; both also stop after an outcome.
Restart restores 40 full-health permanent zombies, empty statistics and the
pre-command state. HUD shows permanent/temporary counts, the next expiration,
the active site's remaining batch and time to the next switch. Each site has a
persistent shallow crater. Three gravestones rise in sequence when recruits are
available and sink when the window closes or stock is exhausted. An available
crater has a dark ring and mint diamond; occupation fills the ring clockwise.
The indicator remains visible through the horde. Leaving resets the fill;
closure/exhaustion hides the indicator immediately. There are no floating names
or percentages. A full horde leaves an unused site available until its deadline;
a completed partial summon closes it. Visual transitions do not delay
activation/deactivation, add collision or affect recruitment. Pause freezes them;
an in-progress transition may settle after the outcome without changing stock.
The HUD reports the next opening during the post-summon pause. Pause and outcomes
freeze this countdown; restart clears it and returns to the first-command state.

## Presentation Boundary

Startup opens a main menu with an animated decorative character diorama,
Raise the horde, Quit, and an Audio button revealing music/effect volume
sliders. Raise the horde opens the ready arena; the first WASD movement still starts
combat. Pause contains the same sliders and a Main menu button; both outcomes
also offer Main menu. Returning discards the run and clears pause. Zero volume
mutes its category. Levels survive replay and scene changes in the current
application session only. The title plays the selected march for volume preview.

The separate UI branch adds a styled in-game HUD and pause/result overlays
with mouse buttons for the existing sprint, pause, resume and replay actions.
Permanent count warns at 20% of the initial army or below; this is presentation
only. The temporary readout appears only while recruits live and shows the
earliest expiry. Recruitment progress stays on the crater ring. A matching
diamond and remaining batch appear in the HUD with time until rotation, a short
occupation hint or a full-horde notice; compass names and the duplicate HUD
progress bar are omitted. Empty panels, persistent instructions and branding
are omitted. Modal overlays block gameplay movement while paused or after an outcome.
The arena has authored low-poly rocks outside its playable bounds, low scrub and
pebbles, and flat ground patches. These are decorative, with no collision or
pathfinding; the full 60 × 44 floor remains available for horde movement.
Short non-positional sound cues accompany grave transitions, confirmed weapon
contact and sparse zombie combat/recruitment. One, two and three metallic pulses
distinguish sweep, charge and spin windups. Each attack sounds one swing and at
most one contact, even across multiple victims. Pausing freezes sounds; either
outcome stops gameplay voices and plays a distinct short victory/defeat cue.
Restart creates silent fresh players. Actual horde travel drives shared footsteps;
successful commands/sprint, bite contact, recruitment and temporary expiry have
bounded cues. Expiry batches coalesce, and rejected sprint requests stay silent.
Mines have an arming cue and one explosion per batch; the sling sounds on actual
launch and landing, including misses. Blood feast has start/natural-expiry cues.
These add no damage or timer changes. Cancelled/rejected actions stay silent.
Undead March stays in the menu; Graveyard Groove starts with the first command
and loops quietly during battle. It pauses/resumes with gameplay and stops at
the outcome or restart. Tiny Siege remains unused.
No custom shaders, saves, multiplayer,
upgrades or other modes are part of this version. Runtime whole-body attacks,
bites, movement lean and hit/death responses remain separate from the source
Blender idle/run Actions. These change visual transforms only, not movement,
damage, recovery windows or attack targeting.
