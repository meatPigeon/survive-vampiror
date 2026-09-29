# Rigged Character Assets

Blender 5.2 sources based on the simplified, chubby v4 character concepts.
Both are modeled geometry with solid-color materials, one joined skinned mesh,
and an editable armature. No generated image is used as a character texture.

| Character | Editable source | Godot/glTF export | Triangles |
| --- | --- | --- | --- |
| Zombie | [zombie.blend](zombie.blend) | [zombie.glb](../../assets/characters/zombie.glb) | 6,000 |
| Medieval knight | [medieval_knight.blend](medieval_knight.blend) | [medieval_knight.glb](../../assets/characters/medieval_knight.glb) | 7,804 |

## Animations

Both files contain only these two Actions, authored at 30 fps:

| Action | Source frames | Duration | Motion |
| --- | --- | --- | --- |
| `idle` | 1–61 | 2 seconds | Small weight shift, breathing and head movement; planted feet |
| `run` | 1–25 | 0.8 seconds | Alternating steps, body bounce and arm movement |

The last source frame duplicates the first pose to close the loop. Both actions
have cyclic curves. The Blender timeline opens on idle at frames 1–60; press
Space to play. To preview run, select `CharacterRig`, switch the Dope Sheet to
Action Editor, select `run`, and set the timeline end to 24.

Motion is in place: the `Root` stays at the origin. Animation does not move the
gameplay entity. These source assets contain no attack clip. The arena adds a
small runtime arm-swing animation and a hand-attached sword in `KnightVisual`;
health and melee rules belong to the gameplay scenes.

## Editing The Rig

- `CharacterRig` has 18 deform bones and two source-only `FootIK.L/R` controls.
- In Pose Mode, translate a `FootIK` control to position its foot; rotating it
  changes foot pitch. The two-bone IK chains do not stretch.
- Hips, spine, chest, neck, head, arms and hands use direct FK posing.
- Vertex weights are normalized. The torso blends between body bones; toy-like
  limb pieces use rigid weights around overlapping joints.
- Face features follow `Head`. There is no facial rig or individual finger rig.
- Dimensions are in meters, with Blender Z up and +Y forward. The character is
  about 2.7 units tall. GLB conversion gives Godot Y up and -Z forward.

The preview floor, lights and camera stay in a separate source collection and
are excluded from the GLB. `art/characters/.gdignore` keeps Blender sources and
previews outside Godot's import pipeline.

## Export And Rebuild

Use the supplied GLBs in Godot. They import with an `AnimationPlayer` containing
looping `idle` and `run` clips and a `CharacterRig/Skeleton3D` skeleton.
The `.glb.import` sidecars set loop modes; retain them when copying the assets.
The arena instances these exports beneath each entity's `Visual` node. Zombies
use a 0.5 visual scale and turn/run based on actual movement, returning to idle
when settled. The knight uses a 0.75 visual scale, idles, runs during pursuit
and charge, and swings during attacks. Gameplay scripts move the entity roots;
all imported and generated clips remain in place.

The authoring script regenerates both source files and exports:

```sh
blender --background --factory-startup --python tools/build_characters.py -- --render
```

Run from the project root. `--character zombie` or `--character medieval_knight`
limits the rebuild; omit `--render` to skip stills. Rebuilding overwrites the
generated `.blend` and `.glb` files, so save manual edits under another name first.
If manually exporting instead, select only the rig and mesh, use glTF Actions,
sample animations, export deform bones/skins, and slide animation time to zero.
The source IK is baked into deform-bone animation for export.

## Previews And Verification

- [Zombie idle](previews/zombie_idle.png) / [run pose](previews/zombie_run.png)
- [Knight idle](previews/medieval_knight_idle.png) / [run pose](previews/medieval_knight_run.png)
- [Idle video](previews/idle.mp4) / [run video](previews/run.mp4), captured from the GLBs in Godot.

Source and export checks:

```sh
blender --background --factory-startup --python tools/verify_characters.py
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/character_assets.gd
```

The Blender check reopens each source, exercises its foot control, checks weights,
samples every animation frame, checks loop closure, and checks for floor
penetration. The Godot check verifies binding, clip names/durations/loop modes,
finite poses, stationary roots, foot movement, and animated upper bodies.

`godot --path . --script res://tools/preview_characters.gd --fixed-fps 30`
captures both animations into `/tmp/survive_character_frames/` using a graphical
display. Rendered poses were visually inspected. The arena instances these assets; no
retargeting is implemented.
