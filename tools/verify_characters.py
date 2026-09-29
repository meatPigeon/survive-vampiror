"""Reopen each Blender source and check skinning, animation loops and foot plants."""

import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]


def poses(rig):
    return {bone.name: bone.matrix.copy() for bone in rig.pose.bones}


for character in ("zombie", "medieval_knight"):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / "art/characters" / (character + ".blend")))
    rig = bpy.data.objects["CharacterRig"]
    mesh_name = "Zombie" if character == "zombie" else "MedievalKnight"
    body = bpy.data.objects[mesh_name]
    assert len(rig.data.bones) == 20
    assert {action.name for action in bpy.data.actions} == {"idle", "run"}
    assert body.modifiers[0].type == "ARMATURE" and body.modifiers[0].object == rig
    for vertex in body.data.vertices:
        assert abs(sum(group.weight for group in vertex.groups) - 1) < 0.0001
    for clip, frames in (("idle", 61), ("run", 25)):
        action = bpy.data.actions[clip]
        rig.animation_data.action = action
        bpy.context.scene.frame_set(1)
        first = poses(rig)
        min_z = math.inf
        max_deformation = 0.0
        for frame in range(1, frames + 1):
            bpy.context.scene.frame_set(frame)
            current = poses(rig)
            assert current["Root"].translation.length < 0.0001
            for matrix in current.values():
                assert all(math.isfinite(value) for row in matrix for value in row)
            evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
            min_z = min(min_z, min(v.co.z for v in evaluated.data.vertices))
            max_deformation = max(max_deformation, max(
                (v.co - source.co).length for v, source in zip(evaluated.data.vertices, body.data.vertices)))
        assert min_z > -0.005, (character, clip, "floor penetration", min_z)
        assert max_deformation > .01, (character, clip, "no skin deformation")
        last = poses(rig)
        for bone in first:
            assert (first[bone].translation - last[bone].translation).length < .002, (clip, bone)
            assert first[bone].to_quaternion().rotation_difference(last[bone].to_quaternion()).angle < .01, (clip, bone)
        print("SOURCE_CLIP_PASS", character, clip, "min_z", round(min_z, 5),
              "skin motion", round(max_deformation, 3), flush=True)
    # Exercise an editable control independently of the authored actions.
    rig.animation_data.action = None
    for bone in rig.pose.bones:
        bone.location = (0, 0, 0)
        bone.rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()
    before = rig.pose.bones["Foot.L"].matrix.translation.copy()
    control = rig.pose.bones["FootIK.L"]
    control.location = control.bone.matrix_local.to_3x3().inverted() @ Vector((0, .08, .09))
    bpy.context.view_layer.update()
    after = rig.pose.bones["Foot.L"].matrix.translation
    assert (after - before).length > .09, (character, "foot control does not work")
    print("SOURCE_RIG_PASS", character, flush=True)

print("Blender source checks: PASS", flush=True)
