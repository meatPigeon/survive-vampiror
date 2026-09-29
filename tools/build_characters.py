"""Author the two toy-style characters, rigs, clips and GLB exports in Blender.

blender --background --factory-startup --python tools/build_characters.py -- --render
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/characters"
EXPORT = ROOT / "assets/characters"
TAU = math.tau
PARTS = []


def material(name, rgb, roughness=0.8):
    rgb = tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb)
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1)
    shader.inputs["Roughness"].default_value = roughness
    return mat


def torso_weights(point):
    z = point[2]
    if z < 1.15:
        t = max(0, min(1, (z - 0.86) / 0.29))
        return {"Hips": 1 - t, "Spine": t}
    t = max(0, min(1, (z - 1.15) / 0.4))
    return {"Spine": 1 - t, "Chest": t}


def mesh(name, verts, faces, mat, weights, material_indices=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    mats = mat if isinstance(mat, list) else [mat]
    for item in mats:
        data.materials.append(item)
    for polygon in data.polygons:
        polygon.use_smooth = True
        if material_indices:
            polygon.material_index = material_indices[polygon.index]
    for i, vertex in enumerate(data.vertices):
        assignment = {weights: 1.0} if isinstance(weights, str) else weights(vertex.co)
        for group, value in assignment.items():
            if value > 0:
                vg = obj.vertex_groups.get(group) or obj.vertex_groups.new(name=group)
                vg.add([i], value, "REPLACE")
    PARTS.append(obj)
    return obj


def ellipsoid(name, center, scale, mat, bone, segments=12, rings=8, rotation=None):
    center, scale = Vector(center), Vector(scale)
    rotation = rotation or Quaternion()
    verts = [center + rotation @ Vector((0, 0, scale.z))]
    for j in range(1, rings):
        t = math.pi * j / rings
        for i in range(segments):
            a = TAU * i / segments
            v = Vector((scale.x * math.sin(t) * math.cos(a),
                        scale.y * math.sin(t) * math.sin(a), scale.z * math.cos(t)))
            verts.append(center + rotation @ v)
    bottom = len(verts)
    verts.append(center + rotation @ Vector((0, 0, -scale.z)))
    faces = []
    for i in range(segments):
        faces.append((0, 1 + i, 1 + (i + 1) % segments))
    for j in range(rings - 2):
        first = 1 + j * segments
        for i in range(segments):
            n = (i + 1) % segments
            faces.append((first + i, first + segments + i, first + segments + n, first + n))
    last = 1 + (rings - 2) * segments
    for i in range(segments):
        faces.append((last + i, bottom, last + (i + 1) % segments))
    return mesh(name, verts, faces, mat, bone)


def limb(name, start, end, radius, mat, bone, depth=None):
    start, end = Vector(start), Vector(end)
    delta = end - start
    return ellipsoid(name, (start + end) * 0.5,
                     (radius, depth or radius, delta.length * 0.5 + radius * 0.4),
                     mat, bone, rotation=delta.to_track_quat("Z", "Y"))


def tube(name, points, radii, mat, bone, segments=8):
    points = [Vector(p) for p in points]
    verts, faces = [], []
    for j, point in enumerate(points):
        tangent = points[min(j + 1, len(points) - 1)] - points[max(0, j - 1)]
        rotation = tangent.to_track_quat("Z", "Y")
        for i in range(segments):
            a = TAU * i / segments
            verts.append(point + rotation @ Vector((radii[j] * math.cos(a), radii[j] * math.sin(a), 0)))
    for j in range(len(points) - 1):
        for i in range(segments):
            n = (i + 1) % segments
            faces.append((j * segments + i, (j + 1) * segments + i,
                          (j + 1) * segments + n, j * segments + n))
    faces += [tuple(reversed(range(segments))),
              tuple((len(points) - 1) * segments + i for i in range(segments))]
    return mesh(name, verts, faces, mat, bone)


def box(name, center, scale, mat, bone, bevel=0.025, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Soft toy edges", "BEVEL")
    modifier.width = bevel
    modifier.segments = 2
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    verts = [obj.matrix_world @ vertex.co for vertex in obj.data.vertices]
    faces = [tuple(p.vertices) for p in obj.data.polygons]
    bpy.data.objects.remove(obj, do_unlink=True)
    return mesh(name, verts, faces, mat, bone)


def lathe(name, sections, mat, weights, segments=24, torn=False, stripe=False):
    verts, faces, indices = [], [], []
    for j, (z, rx, ry) in enumerate(sections):
        for i in range(segments):
            a = TAU * i / segments
            notch = 0.045 * (1 - math.cos(a * 5)) if j == 0 and torn else 0
            verts.append((rx * math.sin(a), ry * math.cos(a), z + notch))
    for j in range(len(sections) - 1):
        for i in range(segments):
            n = (i + 1) % segments
            faces.append((j * segments + i, j * segments + n,
                          (j + 1) * segments + n, (j + 1) * segments + i))
            a = TAU * (i + 0.5) / segments
            indices.append(1 if stripe and abs(math.sin(a)) < 0.27 else 0)
    faces += [tuple(reversed(range(segments))),
              tuple((len(sections) - 1) * segments + i for i in range(segments))]
    indices += [0, 0]
    return mesh(name, verts, faces, mat, weights, indices)


HEAD_CENTER = Vector((0, 0.02, 2.10))
HEAD_SCALE = Vector((0.395, 0.325, 0.45))


def face_y(x, z, extra=0):
    t = 1 - (x / HEAD_SCALE.x) ** 2 - ((z - HEAD_CENTER.z) / HEAD_SCALE.z) ** 2
    return HEAD_CENTER.y + HEAD_SCALE.y * math.sqrt(max(0.02, t)) + extra


def face_patch(name, x, z, rx, rz, mat, bone="Head"):
    verts = [(x, face_y(x, z, 0.008), z)]
    for i in range(20):
        a = i * TAU / 20
        px, pz = x + rx * math.cos(a), z + rz * math.sin(a)
        verts.append((px, face_y(px, pz, 0.008), pz))
    faces = [(0, i + 1, (i + 1) % 20 + 1) for i in range(20)]
    return mesh(name, verts, faces, mat, bone)


def create_character(kind):
    zombie = kind == "zombie"
    skin = material("Olive skin" if zombie else "Warm skin",
                    (0.39, 0.43, 0.18) if zombie else (0.78, 0.46, 0.23))
    cream = material("Warm cream", (0.82, 0.71, 0.49))
    orange = material("Terracotta", (0.65, 0.18, 0.075))
    dark = material("Chocolate", (0.16, 0.095, 0.075))
    mint = material("Mint", (0.24, 0.58, 0.43))
    white = material("Eye ivory", (0.97, 0.91, 0.72), 0.3)
    black = material("Ink", (0.026, 0.020, 0.019), 0.4)
    mouth = material("Mouth", (0.10, 0.033, 0.026))
    steel = material("Matte blue-gray armor", (0.27, 0.30, 0.40), 0.65)

    ellipsoid("Trousers", (0, 0, 0.79), (0.37, 0.27, 0.235),
              orange if zombie else dark, "Hips")
    sections = [(0.75, .37, .27), (.87, .47, .34), (1.04, .52, .385),
                (1.22, .49, .37), (1.40, .405, .295), (1.54, .34, .24),
                (1.64, .21, .175), (1.65, .13, .13)]
    lathe("Tunic", sections, cream if zombie else [cream, orange], torso_weights,
          torn=zombie, stripe=not zombie)
    ellipsoid("Neck", (0, 0, 1.72), (.15, .145, .20), skin, "Neck")
    ellipsoid("Head", HEAD_CENTER, HEAD_SCALE, skin, "Head", 20, 12)
    if zombie:
        for sign in (-1, 1):
            ellipsoid("Ear", (sign * .39, .015, 2.09), (.08, .09, .115), skin, "Head")
    for sign in (-1, 1):
        x, z = sign * .175, 2.23 + sign * .025
        y = face_y(x, z) + .044
        ellipsoid("Googly eye", (x, y, z), (.145, .12, .16), white, "Head", 12, 8)
        ellipsoid("Pupil", (x + .025, y + .111, z + .015), (.037, .019, .046),
                  black, "Head", 10, 6)
    face_patch("Open mouth", 0, 1.962, .135, .105, mouth)
    box("Single tooth", (-.025, face_y(-.025, 2.04, .022), 2.025),
        (.059, .035, .092), white, "Head", .006)
    if zombie:
        face_patch("Nose", 0, 2.135, .028, .035, mouth)
        tube("Hair tuft top", [(-.06, .0, 2.51), (-.11, .0, 2.66), (-.24, .015, 2.69)],
             [.078, .060, .005], dark, "Head")
        tube("Hair tuft side", [(-.30, -.005, 2.40), (-.45, .01, 2.42), (-.50, .03, 2.30)],
             [.07, .055, .005], dark, "Head")
        # A single solid curved mask; straps are intentionally broad/simple.
        verts, faces = [], []
        for z in (1.77, 1.84):
            for i in range(13):
                x = -.24 + .48 * i / 12
                verts.append((x, face_y(x, z, .025), z + .035 * (x / .24) ** 2))
        for i in range(12):
            faces.append((i, i + 1, i + 14, i + 13))
        mesh("Mint mask", verts, faces, mint, "Head")
        for sign in (-1, 1):
            tube("Mask strap", [(sign * .24, face_y(.24, 1.84, .025), 1.86),
                               (sign * .32, .23, 1.99), (sign * .38, .10, 2.07)],
                 [.011, .011, .011], mint, "Head", 6)
    else:
        ellipsoid("Potato nose", (0, .354, 2.12), (.073, .09, .105), skin, "Head")
        lathe("Neck cloth", [(1.60, .22, .18), (1.66, .225, .18), (1.70, .18, .15)],
              mint, "Chest", 20)
        create_helmet(steel)
        lathe("Belt", [(1.045, .528, .396), (1.115, .526, .397)], dark, torso_weights)
        box("Buckle", (0, .408, 1.08), (.16, .05, .12), steel, "Spine", .016)
        box("Buckle inset", (0, .438, 1.08), (.105, .012, .066), dark, "Spine", .007)
        tube("Sword sheath", [(-.53, .03, 1.06), (-.58, .03, .79), (-.64, .03, .59)],
             [.065, .067, .031], dark, "Hips", 6)
        box("Sword guard", (-.515, .03, 1.105), (.21, .075, .05), steel, "Hips", .015,
            (0, .17, 0))
        limb("Sword grip", (-.52, .03, 1.10), (-.49, .03, 1.27), .038, dark, "Hips")
        ellipsoid("Pommel", (-.49, .03, 1.28), (.055, .052, .055), steel, "Hips", 10, 6)

    for sign, side in ((1, "L"), (-1, "R")):
        shoulder, elbow, wrist, hand_end, hip, knee, ankle = joints(sign)
        upper, lower, hand = "UpperArm." + side, "LowerArm." + side, "Hand." + side
        leg, shin, foot = "UpperLeg." + side, "LowerLeg." + side, "Foot." + side
        limb("Upper arm", shoulder, elbow, .135, skin if zombie else dark, upper)
        ellipsoid("Sleeve" if zombie else "Pauldron", shoulder,
                  (.205, .185, .15), cream if zombie else steel, upper)
        ellipsoid("Elbow", elbow, (.125, .12, .123), skin if zombie else steel, lower)
        limb("Forearm", elbow, wrist, .123, skin if zombie else steel, lower)
        ellipsoid("Palm", wrist.lerp(hand_end, .70), (.135, .095, .13),
                  skin if zombie else steel, hand)
        # Two broad fingers and a thumb, matching the deliberately simple toy style.
        for index in range(2):
            x = hand_end.x + sign * (-.042 + index * .095)
            tube("Finger", [(x, .105, hand_end.z + .015), (x + sign * .015, .12, hand_end.z - .085),
                            (x + sign * .009, .175, hand_end.z - .14)],
                 [.060, .061, .035], skin if zombie else steel, hand, 8)
        limb("Thumb", (wrist.x - sign * .075, .10, wrist.z - .012),
             (wrist.x - sign * .11, .20, wrist.z - .095), .065,
             skin if zombie else steel, hand)
        limb("Thigh", hip, knee, .17, orange if zombie else dark, leg)
        ellipsoid("Knee", knee, (.14, .14, .135), skin if zombie else steel, shin)
        limb("Shin", knee, ankle, .112, skin if zombie else dark, shin)
        ellipsoid("Shoe", (sign * .24, .095, .145), (.18, .285, .145),
                  dark if zombie else steel, foot, 16, 8)
        if not zombie:
            limb("Boot cuff", ankle, ankle + Vector((0, 0, .14)), .145, steel, foot)


def create_helmet(mat):
    verts, faces = [], []
    columns, rows = 24, 8
    for row in range(rows + 1):
        for col in range(columns):
            a = TAU * col / columns
            # Front brim clears the eyes; side and back panels cover the skull.
            front = max(0.0, min(1.0, (math.cos(a) - .30) / .32))
            limit = 2.04 - .97 * front
            t = .025 + (limit - .025) * row / rows
            verts.append((.435 * math.sin(t) * math.sin(a),
                          .02 + .371 * math.sin(t) * math.cos(a),
                          2.13 + .49 * math.cos(t)))
    for j in range(rows):
        for i in range(columns):
            n = (i + 1) % columns
            faces.append((j * columns + i, j * columns + n,
                          (j + 1) * columns + n, (j + 1) * columns + i))
    faces.append(tuple(reversed(range(columns))))
    obj = mesh("Open-face helmet", verts, faces, mat, "Head")
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new("Helmet thickness", "SOLIDIFY")
    modifier.thickness = .025
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    points = []
    for i in range(12):
        a = -1.95 + 3.01 * i / 11
        points.append((0, .02 + .385 * math.sin(a), 2.13 + .505 * math.cos(a)))
    tube("Helmet ridge", points, [.035] * len(points), mat, "Head", 6)


def joints(sign):
    return tuple(Vector(p) for p in [
        (sign * .39, 0, 1.54), (sign * .67, .018, 1.30),
        (sign * .80, .06, 1.10), (sign * .86, .11, .99),
        (sign * .24, 0, .88), (sign * .24, .07, .53), (sign * .24, 0, .22)])


def make_rig(kind):
    data = bpy.data.armatures.new(kind.title() + "Skeleton")
    rig = bpy.data.objects.new("CharacterRig", data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name, head, tail, parent=None, deform=True):
        b = data.edit_bones.new(name)
        b.head, b.tail = head, tail
        b.use_deform = deform
        if parent:
            b.parent = data.edit_bones[parent]
        return b

    bone("Root", (0, 0, 0), (0, 0, .18))
    bone("Hips", (0, 0, .88), (0, 0, 1.15), "Root")
    bone("Spine", (0, 0, 1.15), (0, 0, 1.43), "Hips")
    bone("Chest", (0, 0, 1.43), (0, 0, 1.65), "Spine")
    bone("Neck", (0, 0, 1.65), (0, 0, 1.86), "Chest")
    bone("Head", (0, 0, 1.86), (0, 0, 2.48), "Neck")
    for sign, side in ((1, "L"), (-1, "R")):
        shoulder, elbow, wrist, hand, hip, knee, ankle = joints(sign)
        bone("UpperArm." + side, shoulder, elbow, "Chest")
        bone("LowerArm." + side, elbow, wrist, "UpperArm." + side)
        bone("Hand." + side, wrist, hand, "LowerArm." + side)
        bone("UpperLeg." + side, hip, knee, "Hips")
        bone("LowerLeg." + side, knee, ankle, "UpperLeg." + side)
        bone("Foot." + side, ankle, (sign * .24, .22, .13), "LowerLeg." + side)
        bone("FootIK." + side, ankle, (sign * .24, .22, .13), "Root", False)
    bpy.ops.object.mode_set(mode="OBJECT")
    for side in ("L", "R"):
        ik = rig.pose.bones["LowerLeg." + side].constraints.new("IK")
        ik.name = "Plant foot"
        ik.target, ik.subtarget, ik.chain_count = rig, "FootIK." + side, 2
        ik.use_stretch = False
        constraint = rig.pose.bones["Foot." + side].constraints.new("COPY_ROTATION")
        constraint.name = "Keep sole level"
        constraint.target, constraint.subtarget = rig, "FootIK." + side
        constraint.target_space = constraint.owner_space = "WORLD"
    for b in data.bones:
        b.color.palette = "THEME04" if b.name.startswith("FootIK") else "THEME03"
    rig.show_in_front = True
    rig["Instructions"] = "Pose Mode: FootIK.L/R move the feet; hips/body/arms/head are FK. Actions: idle and run. +Y forward, Z up, meters. Exported clips are in-place."
    rig["Concept"] = "art/concepts/" + ("zombie-v4.png" if kind == "zombie" else "medieval_knight-v4.png")
    return rig


def join_and_bind(rig, kind):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in PARTS:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    body = bpy.context.object
    body.name = "Zombie" if kind == "zombie" else "MedievalKnight"
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    body.parent = rig
    modifier = body.modifiers.new("Character skin", "ARMATURE")
    modifier.object = rig
    return body


def reset_pose(rig):
    for pose in rig.pose.bones:
        pose.location = (0, 0, 0)
        pose.rotation_mode = "QUATERNION"
        pose.rotation_quaternion = Quaternion()
        pose.scale = (1, 1, 1)


def move(rig, name, offset):
    pose = rig.pose.bones[name]
    pose.location = pose.bone.matrix_local.to_3x3().inverted() @ Vector(offset)


def rotate(rig, name, x=0, y=0, z=0):
    pose = rig.pose.bones[name]
    rest = pose.bone.matrix_local.to_quaternion()
    pose.rotation_quaternion = rest.inverted() @ Euler((x, y, z)).to_quaternion() @ rest


def animate(rig, kind):
    zombie = kind == "zombie"
    scene = bpy.context.scene
    rig.animation_data_create()
    for name, end in (("idle", 61), ("run", 25)):
        action = bpy.data.actions.new(name)
        action.use_fake_user = True
        rig.animation_data.action = action
        for frame in range(1, end + 1):
            scene.frame_set(frame)
            reset_pose(rig)
            t = (frame - 1) / (end - 1)
            phase = TAU * t
            if name == "idle":
                move(rig, "Hips", (.012 * math.sin(phase), 0, -.014 + .005 * math.sin(phase)))
                move(rig, "Chest", (0, 0, .007 * math.sin(phase)))
                rotate(rig, "Head", x=.04 if zombie else 0,
                       y=.025 * math.sin(phase), z=.035 * math.sin(phase))
                for sign, side in ((1, "L"), (-1, "R")):
                    rotate(rig, "UpperArm." + side, x=.22 if zombie else .025,
                           y=-sign * .035, z=sign * .025 * math.sin(phase))
                    rotate(rig, "LowerArm." + side, x=.25 if zombie else .09)
            else:
                move(rig, "Hips", (.025 * math.sin(phase), 0, -.045 + .020 * math.cos(phase * 2)))
                rotate(rig, "Spine", x=-.07, y=.035 * math.sin(phase))
                rotate(rig, "Chest", x=-.08, z=.035 * math.cos(phase))
                rotate(rig, "Head", x=.13 if zombie else .06, z=-.035 * math.cos(phase))
                for sign, side in ((1, "L"), (-1, "R")):
                    u = (t + (0 if sign == 1 else .5)) % 1.0
                    stride = .225
                    if u < .5:
                        swing = u * 2
                        eased = swing * swing * (3 - 2 * swing)
                        forward = -stride + 2 * stride * eased
                        lift = .18 * math.sin(math.pi * swing)
                        pitch = .28 * math.sin(TAU * swing)
                    else:
                        forward = stride - 4 * stride * (u - .5)
                        lift, pitch = 0, 0
                    move(rig, "FootIK." + side, (0, forward, lift))
                    rotate(rig, "FootIK." + side, x=pitch)
                    swing = math.cos(phase + (0 if sign == 1 else math.pi))
                    rotate(rig, "UpperArm." + side,
                           x=(.30 + .24 * swing) if zombie else .52 * swing,
                           y=-sign * .10)
                    rotate(rig, "LowerArm." + side, x=.38 if zombie else .58)
                    rotate(rig, "Hand." + side, x=.06 * math.sin(phase))
            for pose in rig.pose.bones:
                pose.keyframe_insert("location", frame=frame, group=pose.name)
                pose.keyframe_insert("rotation_quaternion", frame=frame, group=pose.name)
        action.use_frame_range = True
        action.frame_start, action.frame_end = 1, end
        action.asset_mark()
        # Sampled channels keep the exported motion identical to the source.
        for layer in action.layers:
            for strip in layer.strips:
                bag = strip.channelbag(rig.animation_data.action_slot)
                for fcurve in bag.fcurves:
                    for key in fcurve.keyframe_points:
                        key.interpolation = "LINEAR"
                    fcurve.modifiers.new("CYCLES")
    rig.animation_data.action = None
    reset_pose(rig)
    scene.frame_set(1)


def studio():
    scene = bpy.context.scene
    collection = bpy.data.collections.new("Preview studio (not exported)")
    scene.collection.children.link(collection)

    def relocate(obj):
        for current in list(obj.users_collection):
            current.objects.unlink(obj)
        collection.objects.link(obj)
        obj.hide_select = True

    floor_mat = material("Preview golden yellow", (.96, .62, .18))
    bpy.ops.mesh.primitive_plane_add(size=200)
    floor = bpy.context.object
    floor.name = "Preview floor"
    floor.location.z = -.015
    floor.data.materials.append(floor_mat)
    relocate(floor)
    world = bpy.data.worlds.new("Studio world")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (.72, .76, .85, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = .45
    scene.world = world
    for name, loc, power, size in [
        ("Key", (-3, 4.5, 6), 650, 4),
        ("Fill", (4, 2, 3.5), 300, 5),
        ("Rim", (1, -4, 4.5), 500, 3)]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.shape, data.size = power, "DISK", size
        obj = bpy.data.objects.new(name, data)
        collection.objects.link(obj)
        obj.location = loc
        obj.rotation_euler = (Vector((0, 0, 1.3)) - obj.location).to_track_quat("-Z", "Y").to_euler()
        obj.hide_select = True
    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    collection.objects.link(camera)
    camera.location = (3.4, 6.5, 3.0)
    camera.rotation_euler = (Vector((0, 0, 1.35)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type, camera_data.ortho_scale = "ORTHO", 3.25
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.render.resolution_x = scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    return camera


def validate_source(body, rig):
    groups = {g.index: g.name for g in body.vertex_groups}
    for vertex in body.data.vertices:
        total = sum(group.weight for group in vertex.groups)
        assert abs(total - 1) < .0001, (vertex.index, total)
        assert all(groups[group.group] in rig.data.bones for group in vertex.groups)
    assert all(math.isfinite(v) for vertex in body.data.vertices for v in vertex.co)
    assert {a.name for a in bpy.data.actions} == {"idle", "run"}
    assert len(rig.data.bones) == 20
    rig.animation_data.action = bpy.data.actions["run"]
    bpy.context.scene.frame_set(7)
    evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    changed = max((a.co - b.co).length for a, b in zip(body.data.vertices, evaluated.data.vertices))
    assert changed > .05, "Rig did not deform the mesh"
    rig.animation_data.action = None
    reset_pose(rig)
    body.data.calc_loop_triangles()
    return {"vertices": len(body.data.vertices), "triangles": len(body.data.loop_triangles),
            "source_bones": len(rig.data.bones), "deform_bones": sum(b.use_deform for b in rig.data.bones),
            "clips": {"idle": 2.0, "run": .8}, "fps": 30}


def build(kind, render):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    PARTS.clear()
    scene = bpy.context.scene
    scene.render.fps = 30
    create_character(kind)
    rig = make_rig(kind)
    body = join_and_bind(rig, kind)
    animate(rig, kind)
    stats = validate_source(body, rig)
    camera = studio()
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    # Export only the model and rig; studio geometry and control bones stay in Blender.
    bpy.ops.export_scene.gltf(
        filepath=str(EXPORT / (kind + ".glb")), export_format="GLB",
        use_selection=True, export_animations=True, export_animation_mode="ACTIONS",
        export_force_sampling=True, export_def_bones=True, export_skins=True,
        export_rest_position_armature=True, export_yup=True, export_apply=False,
        export_cameras=False, export_lights=False, export_extras=True,
        export_anim_slide_to_zero=True)
    rig.animation_data.action = bpy.data.actions["idle"]
    scene.frame_start, scene.frame_end = 1, 60
    scene.frame_set(1)
    body.select_set(False)
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                area.spaces.active.region_3d.view_distance = 4.5
                area.spaces.active.region_3d.view_location = (0, 0, 1.3)
                area.spaces.active.region_3d.view_rotation = camera.rotation_euler.to_quaternion()
                area.spaces.active.shading.type = "SOLID"
                area.spaces.active.shading.color_type = "MATERIAL"
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / (kind + ".blend")))
    (SOURCE / (kind + "_stats.json")).write_text(json.dumps(stats, indent=2) + "\n")
    if render:
        for clip, frame in (("idle", 1), ("run", 7)):
            rig.animation_data.action = bpy.data.actions[clip]
            scene.frame_set(frame)
            scene.render.filepath = str(SOURCE / "previews" / (kind + "_" + clip + ".png"))
            bpy.ops.render.render(write_still=True)
    print("CHARACTER_COMPLETE", kind, json.dumps(stats), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", choices=("zombie", "medieval_knight", "both"), default="both")
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    SOURCE.mkdir(parents=True, exist_ok=True)
    (SOURCE / "previews").mkdir(exist_ok=True)
    EXPORT.mkdir(parents=True, exist_ok=True)
    for name in (("zombie", "medieval_knight") if args.character == "both" else (args.character,)):
        build(name, args.render)
