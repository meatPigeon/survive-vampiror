# Testing

Run from the project root with Godot 4.7. No external test addon is needed.

## Automated Checks

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/prototype_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_balance.gd --fixed-fps 60
godot --headless --path . --script res://tests/character_assets.gd
```

Import first on a fresh checkout to register classes. Each test must print PASS,
exit 0, and produce no script errors; exit status alone is insufficient because
Godot may continue after a script error.

- **Prototype smoke:** combat-disabled fixture for initial crowd, real mouse
  projection, rejected input, movement, redirect, separation, corner clamps,
  resize, model instances, facing and idle/run transitions.
- **Combat smoke:** health/death contract, bite range/cooldown, sweep arc,
  escaping a warning, charge movement and fixed warning, no repeated charge
  hits or hits beyond the rectangle, spin radius, HP phase thresholds, immediate
  death removal, reserve occupation/interruption/finite capacity, actual sprint
  speed and cooldown, first-command start, pause/resume, restart from pause
  including physical-key handling, both results and stopped combat.
- **Combat balance:** actual viewport mouse/keyboard input. Passive and reckless
  chasing must lose; active pilots with 0.37 and 0.50 s reaction delays must win
  within five minutes with at least five survivors, visit all phases/attacks and
  use finite reserves. The pilot reacts to visible warning geometry and named
  attack type, recruits when fewer than 26 zombies remain, and uses sprint when
  dodging charges/spins. It never teleports agents or changes HP in full runs.
- **Character assets:** unchanged GLB skin binding, idle/run names/durations,
  looping, root stability and foot/head motion.

Current headless results: passive defeat 71.0 s, reckless chase defeat 46.2 s;
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

Launch `godot --path .` or F5 in the editor.

1. Confirm the arena waits while you read controls; first click starts the fight.
2. Command/redirect the whole horde. Space accelerates toward its current target,
   and repeated presses do not bypass the cooldown.
3. Dodge the orange sector sideways, leave the yellow charge lane, and retreat
   outside the purple circle. Return during recovery to bite the knight.
4. Rally at a green site and hold for two seconds. Confirm recruits, depletion,
   cap 60, and preserved leftovers when full. Leave mid-summon to interrupt it.
5. Play through the HP phase thresholds; confirm the later attack patterns.
6. Pause during a warning and recruitment; verify gameplay/animations/timers
   freeze. Resume or restart. Test with a non-English keyboard layout too.
7. Finish or lose a run. Confirm statistics and no continued damage/recruitment.
8. Restart; verify full HP, 40 zombies, phase 1, all reserves and ready sprint.

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
