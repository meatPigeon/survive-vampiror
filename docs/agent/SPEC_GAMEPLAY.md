# Gameplay Spec

## Complete Run

One flat 44 × 32 arena, one knight, 40 player-controlled zombies. The camera is
fixed and angled. The run waits for the first ground command. Kill the knight
to win; zero living zombies loses immediately, including with unused reserves.
A technical result display shows elapsed time, casualties and recruited count.
R reloads every gameplay state; Esc pauses/resumes the scene tree. Input remains
available for resume/restart while paused. Physical key positions support
non-English keyboard layouts.

## Horde

- Left click selects a shared ground position; invalid/off-floor/right clicks
  do nothing. Commands can change during combat.
- Each zombie steers toward that point with local separation and bounds clamps.
  The living knight's body excludes zombies from its center. No formations,
  obstacles, navigation, or per-unit selection are implemented.
- 30 HP per zombie. In range 1.15, it bites for 4 damage once per 0.8 seconds.
- Space gives 2× movement speed for 1.4 seconds, with a 7-second cooldown from
  activation. Requires an existing movement command; cannot refresh early.
  No invulnerability or damage bonus. Timers freeze during pause.
- Run/idle and facing follow actual movement. Dead zombies leave the active
  list immediately, briefly fall/shrink, then are freed. Death emits once.

## Knight

3000 HP, body radius 0.55, pursuit speed 1.5. He approaches the closest living
zombie and attacks when in range. Windups lock the attack's direction and origin;
he does not track targets during the warning. A distant target inside charge
range triggers a charge; a farther target is approached on foot. He remains
inside floor bounds. He stays still during recovery, giving the horde a bite
window. He does not flee the final zombie.

| Attack | Warning | Damage shape | Damage | Strike | Recovery |
| --- | --- | --- | --- | --- | --- |
| Sweep | 1.3 s, orange sector | Radius 2.2, angle 160° | 15 | 0.18 s | 1.4 s |
| Charge | 1.5 s, yellow lane | Width 2.0, up to 8.0 long, locked endpoint | 20, once per zombie | 0.7 s movement | 2.0 s |
| Spin | 1.8 s, purple circle | Radius 3.2, all directions | 20 | 0.5 s | 2.4 s |

Sweep/spin damage resolves once when the warning ends, using current positions.
Charge checks the swept path each tick, excludes positions beyond the displayed
lane endpoints, and remembers already-hit zombies until that charge ends. The
warning stays fixed in world space while the knight moves. A charge with no
usable movement at a boundary falls back to a sweep. These are geometric damage
checks, not collisions with the visible sword.

Phase patterns change at HP thresholds; an attack already in progress finishes
with its original timing and shape:

1. Above two-thirds HP: sweep, sweep, charge.
2. At/below two-thirds: sweep, charge, spin.
3. At/below one-third: charge, spin, sweep, spin.

Patterns cycle; a distant target can substitute a charge. HUD text names the
phase, warning type and recovery window. Both sides briefly flash on damage.

## Finite Reinforcements

Three green sites, 12 zombies each: west (-14, -8), south (-10, 10), east (14, 8)
on the X/Z plane. A site recruits only when the command is within its radius 2.4
and at least one living zombie occupies it for 2 seconds. Leaving or reaching
capacity resets progress. A full horde does not consume reserves.

Horde cap is 60. Recruitment adds as many as capacity permits and subtracts only
that number from the site's reserve. Partly unused reserves can be collected
later. Spent sites cannot refill or resurrect a fully dead horde. New zombies
use the same movement, health and combat scripts as the starting crowd.

## Presentation Boundary

Gameplay is the current deliverable. HUD labels, colored attack shapes, reserve
rings and existing characters are sufficient to operate it. No polished menus,
audio, custom shaders, decorative environment, saves, multiplayer, upgrades or
other modes are part of this version. Runtime attack animation remains separate
from the source Blender idle/run Actions.
