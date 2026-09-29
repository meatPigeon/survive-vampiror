# Testing

Run commands from the project root with Godot 4.7. There are no external
dependencies, test addons, or configured standalone lint/build tools.

## Import And Automated Smoke Test

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/prototype_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_smoke.gd --fixed-fps 60
godot --headless --path . --script res://tests/combat_balance.gd --fixed-fps 60
```

Import first on a fresh checkout to register script classes. The smoke test
must exit with code 0 and print `Prototype smoke: PASS` without script errors.
It instantiates the main scene and injects mouse events through the viewport.
Coverage includes 40 zombie instances, a knight survivor, waiting before commands,
rejected off-floor/right clicks, ground projection, marker visibility, movement,
redirection, gathering, separation, corner bounds, the stationary survivor, and
targeting after window resizing. It also checks starting idle, run during
movement, facing the movement direction, returning to idle after gathering,
and uninterrupted knight idle playback. This fixture disables the arena combat
coordinator to isolate movement from casualties.

`combat_smoke.gd` must print `Combat smoke: PASS` and exit 0 without errors.
It checks health clamping, one-time death, bite range/cooldown, warned sword
swings, arc/range misses, retreat during windup, zombie removal/freeing, and a
complete fight commanded by a viewport mouse event. It also checks the HUD,
stopped combat/commands, R reload, and both victory and defeat independently
of balance tuning. Its real single-click fight must now end in defeat.

## Rendered Verification

```sh
godot --path . --script res://tests/prototype_smoke.gd --fixed-fps 60 -- --capture
godot --path . --script res://tests/combat_smoke.gd --fixed-fps 60 -- --capture
godot --path . --script res://tests/combat_balance.gd --fixed-fps 60 -- --capture
```

This requires a graphical display and runs the same assertions while saving
`/tmp/survive_vampiror_initial.png`, `moving.png`, `gathered.png`, `corner.png`, and
`survivor.png` with the same `survive_vampiror_` filename prefix. Inspect the
captures for visible entities, usable camera framing, and a readable crowd.
The combat test saves `/tmp/survive_combat_start.png`, `swing.png`, `fight.png`,
and `result.png` with the same `survive_combat_` prefix. Inspect the health/count
display, sword swing, warning arc, damage/death feedback and outcome.
Screenshots are temporary verification artifacts, not project assets.

## Manual Smoke Check

Launch with `godot --path .` or open `project.godot` and press F5.

1. Confirm a flat arena, an idle knight, and 40 idle zombies are visible.
2. Left-click open floor; confirm a yellow marker and collective movement.
3. Click elsewhere while moving; confirm agents redirect independently.
   Zombies should turn toward travel, run, then return to idle after gathering.
4. Command a corner; check agents stay on the floor and remain distinguishable.
5. Click around the survivor and resize the window; confirm targeting remains
   aligned with the pointer and the survivor remains stationary.
6. Command the crowd onto the knight. Confirm bites reduce his health, his
   warned sword swings hurt/kill nearby zombies, and the count decreases.
7. Redirect away during a windup; confirm the attack can miss. Return to finish
   the fight and confirm a result stops movement and damage.
8. Press R; confirm 40 zombies, full knight health, and working commands return.

Record actual results in [PROJECT_STATE.md](PROJECT_STATE.md). Distinguish
automated input and screenshot inspection from a human playthrough.

## Character Asset Checks

Blender 5.2 is needed only for authoring or checking the editable sources.
Godot can import the supplied GLB files without Blender.

```sh
blender --background --factory-startup --python tools/verify_characters.py
godot --headless --path . --script res://tests/character_assets.gd
```

Run the editor import command first after changing GLBs. The source check
reopens both files, verifies weights and IK, and samples clips for deformation,
loop closure and ground contact. The Godot check covers skin binding, the two
clips, their durations and loop settings, root stability, and foot/head motion.

For rendered exported-animation frames:

```sh
godot --path . --script res://tools/preview_characters.gd --fixed-fps 30
```

Frames go to `/tmp/survive_character_frames/`; supplied stills and MP4 previews
are in `art/characters/previews/`. See [the asset guide](../../art/characters/README.md)
for rebuild instructions and limitations.


## Balance Comparisons (2026-09-29)

Ran 23 parameter sets / 69 initial Godot battles. Health comparisons used knight
500/650/800/900/1000 HP and zombie 10/20/30 HP; sword damage 10/15/20, radius
1.65/2.2/2.6, angle 110/120/140/160/170 degrees. Warning/recovery combinations
were compared too. These were selected trials, not an exhaustive Cartesian search.
The experimental walking knight retreated from the closest nearby zombie during
recovery/idle, clamped to the floor, and stayed planted during the warned hit.
Movement speed was 0, 0.8, 1.2, or 1.5. The discarded walking implementation was
removed; the game retains only the selected settings.

Representative normal-start results (headless, 60 fixed physics steps/s):

| Change from original unless noted | Passive result | Active result |
| --- | --- | --- |
| Original 500 HP knight, 20 HP zombie, damage 10, radius 1.65, angle 110 | Win, 25 left | Win, 31 left |
| Knight HP 800 | Win, 14 left | Win, 22 left |
| Zombie HP 10 | Win, 3 left | Win, 13 left |
| Sword damage 20 | Win, 3 left | Win, 13 left |
| Radius 2.2 | Win, 13 left | Win, 16 left |
| Angle 160 | Win, 16 left | Win, 20 left |
| Walking at 0.8 | Win, 25 left | Win, 31 left |
| Walking at 1.5 | No end at 90 s; retargeting wins with 27 | Win, 28 left |
| 500 HP, damage 20, radius 2.2, angle 170, tell 0.9, recovery 1.2 | Loss | Loss |
| Selected 1000/30 HP, damage 15, radius 2.2, angle 160, tell 1.3, recovery 1.2 | Loss, knight 144 HP | Win, 12 left |

Initial active trials reacted after ~0.22 seconds to the visible arc, clicked
4.5 units to its side, and clicked back onto the knight after the arc vanished.
Selected settings were additionally tested from four starts, with static target
X offsets -0.8/0/+0.8 and response delays 0.22/0.37/0.5 s: 12 passive losses,
12 active wins, 5–18 survivors. The wider tell was retained to permit slower
reactions; a one-hit kill variant was less forgiving.

Permanent `combat_balance.gd` uses viewport mouse clicks, four starting
positions, and a ~0.37 s response delay. Passive cases must lose; active cases
must win with at least five zombies. The normal-start check produced 38.8 s /
knight 220 HP for passive, and 42.0 s / 14 surviving zombies for active. Small
changes in input projection/tick phase can alter exact casualties; assertions
check the tactical distinction, not exact frame counts or a fixed survivor count.

With `--capture`, only the normal start is played twice in the rendered game.
Captures use `/tmp/survive_balance_{passive,active}_{warning,fight,result}.png`.
Inspect the wider ground arc, raised sword during the tell, retreat/re-entry,
HUD and both outcomes. Automation does not establish human-perceived difficulty.

The rendered normal-start pair passed: passive defeat at 38.8 s (220 knight HP),
active victory at 42.7 s (16 zombies). Warning, fight, and outcome screenshots
were inspected. Editor import, `combat_smoke.gd`, and `prototype_smoke.gd` passed.
