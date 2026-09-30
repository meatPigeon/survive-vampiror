# Gameplay Spec

## Complete Run

One flat 60 × 44 arena, one knight, 40 player-controlled zombies. The camera is
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
  list immediately, tumble/shrink (or softly collapse on expiry), then are freed within 0.6 seconds. Death emits once.

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

Recruitment requires a command within radius 2.4 and at least one living zombie
inside the site for 2 uninterrupted seconds. Either kind can occupy it while
permanent zombies remain alive. Leaving or reaching capacity resets progress.
Horde cap is 60. Add only as many zombies as capacity permits, then discard the
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

Startup opens a main menu with Play, Quit and separate music/effect volume
sliders. Play opens the ready arena; the first ground command still starts
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
are omitted. Modal overlays block floor clicks.
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
Undead March starts with the first command and loops quietly during battle.
It pauses/resumes with gameplay and stops at the outcome or restart. The two
other music sketches remain unused alternatives.
No custom shaders, saves, multiplayer,
upgrades or other modes are part of this version. Runtime whole-body attacks,
bites, movement lean and hit/death responses remain separate from the source
Blender idle/run Actions. These change visual transforms only, not movement,
damage, recovery windows or attack targeting.
