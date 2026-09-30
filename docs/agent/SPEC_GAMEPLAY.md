# Gameplay Spec

## Complete Run

One flat 44 × 32 arena, one knight, 40 player-controlled zombies. The camera is
fixed and angled. The run waits for the first ground command. Kill the knight
to win; zero living permanent zombies loses immediately, even with temporary survivors
or an available recruitment site.
A technical result display shows elapsed time, combat casualties, expired
temporary zombies and recruited count.
R reloads every gameplay state; Esc pauses/resumes the scene tree. Input remains
available for resume/restart while paused. Physical key positions support
non-English keyboard layouts.

## Horde

- Left click selects a shared ground position; invalid/off-floor/right clicks
  do nothing. Commands can change during combat.
- Each zombie steers toward that point with local separation and bounds clamps.
  The living knight's body excludes zombies from its center. No formations,
  obstacles, navigation, or per-unit selection are implemented.
- The 40 starting zombies are permanent: no lifetime limit, healing, resurrection
  or replacement. White foot rings identify them. Recruits are temporary, with
  blue rings and 45 seconds of life from their individual spawn time. Returning
  to a site does not pause or reset this lifetime.
- 30 HP per zombie. In range 1.15, it bites for 4 damage once per 0.8 seconds.
- Space gives 2× movement speed for 1.4 seconds, with a 7-second cooldown from
  activation. Requires an existing movement command; cannot refresh early.
  No invulnerability or damage bonus. Timers freeze during pause.
- Run/idle and facing follow actual movement. Dead zombies leave the active
  list immediately, briefly fall/shrink, then are freed. Death emits once.

## Knight

3000 HP, body radius 0.55, pursuit speed 1.5. He approaches the closest living
zombie and attacks when in range. Before each sweep/charge he compares candidate
directions and chooses one covering the most living zombies inside the actual
sector/lane. Candidates include directions between zombies; unreachable groups
do not draw his aim. Equal scores keep the initial nearest-target choice.
Charge scoring accounts for its floor-clamped endpoint. Spin is omnidirectional.
Windups lock the attack's direction and origin;
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

## Rotating Temporary Reinforcements

Three sites: west (-14, -8), south (-10, 10), east (14, 8) on the X/Z plane.
All are inactive before the first command. West opens at battle time 0; activity
moves to south at 30 s, east at 60 s, west at 90 s, and repeats every 30 s.
Only one site is active. Each activation starts with 12 temporary recruits;
unused stock and occupation progress are discarded on switching. An exhausted
site waits for the fixed schedule, rather than advancing it early.

Recruitment requires a command within radius 2.4 and at least one living zombie
inside the site for 2 uninterrupted seconds. Either kind can occupy it while
permanent zombies remain alive. Leaving or reaching capacity resets progress.
Horde cap is 60. Add only as many zombies as capacity permits and retain the
rest of the batch for the current window. There is no stock accumulation.

Arena ticks lifetime expiration before combat and recruitment. Expired zombies
leave the active list immediately and cannot bite that tick. Expiration uses
the normal death feedback but counts separately from combat casualties. Losing
the last permanent stops the current attack's remaining hits, bites and hiring
immediately. Once an outcome is set it cannot be reversed.

Pause freezes lifetimes and the site schedule; both also stop after an outcome.
Restart restores 40 full-health permanent zombies, empty statistics and the
pre-command state. HUD shows permanent/temporary counts, the next expiration,
the active site's remaining batch and time to the next switch. Site labels
show inactive/exhausted status or recruitment progress.

## Presentation Boundary

The separate UI branch adds a styled in-game HUD and pause/result overlays
with mouse buttons for the existing sprint, pause, resume and replay actions.
Permanent count warns at 20% of the initial army or below; this is presentation
only. The temporary bar shows the earliest remaining lifetime; the recruitment
bar shows time left in the active site window. Modal overlays block floor clicks.
No title menu, audio, custom shaders, decorative environment, saves, multiplayer,
upgrades or other modes are part of this version. Runtime attack animation remains separate
from the source Blender idle/run Actions.
