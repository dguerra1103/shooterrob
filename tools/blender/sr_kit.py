# SHOOTERROB · kit de modelado de armas para Blender (se ejecuta sin interfaz).
#
#   blender -b -P tools/blender/build_weapon.py -- <arma> [--final] [--no-render]
#
# Convenciones (las mismas que usa el juego en Weapons.luau):
#   · Coordenadas DEL JUEGO, en studs: X = derecha, Y = arriba, Z = hacia atrás (el cañón apunta a -Z).
#     El origen es el Handle (centro del cajón de mecanismos). Aquí se modela SIEMPRE en esas
#     coordenadas; el kit las pasa a Blender (X, -Z, Y) al crear la geometría.
#   · Cada objeto lleva "role" (Body, Panel, Accent, Accent2, Dark, Metal, Rubber, Lens, Reticle, Trim:
#     los papeles que pintan las skins del juego) y, si se mueve en las animaciones, "piece"
#     (Mag, Charge, Bolt, Slide, Pump).
#   · Estilo: superficies duras con chaflán, sombreado plano por caras (sin suavizar entre planos).
import json
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

SHARP_ANGLE = math.radians(32)

# Colores de presentación por papel (los renders; en el juego los pone la skin)
DEFAULT_PALETTE = {
    "Body": (0.045, 0.05, 0.06),
    "Panel": (0.95, 0.42, 0.05),
    "Accent": (0.1, 0.85, 1.0),
    "Accent2": (1.0, 0.75, 0.1),
    "Dark": (0.018, 0.018, 0.022),
    "Metal": (0.55, 0.57, 0.62),
    "Rubber": (0.03, 0.03, 0.035),
    "Lens": (0.15, 0.45, 0.9),
    "Reticle": (1.0, 0.08, 0.05),
    "Trim": (0.95, 0.42, 0.05),
}
ROLE_SHADING = {
    # papel: (metallic, roughness, emisión)
    "Body": (0.55, 0.42, 0.0),
    "Panel": (0.25, 0.38, 0.0),
    "Accent": (0.0, 0.3, 4.0),
    "Accent2": (0.6, 0.3, 0.0),
    "Dark": (0.8, 0.35, 0.0),
    "Metal": (1.0, 0.22, 0.0),
    "Rubber": (0.0, 0.8, 0.0),
    "Lens": (0.2, 0.05, 0.6),
    "Reticle": (0.0, 0.3, 8.0),
    "Trim": (0.4, 0.35, 0.0),
}


def g2b(v):
    """Punto del juego (x, y, z) → Blender (x, -z, y)."""
    return Vector((v[0], -v[2], v[1]))


def b2g(v):
    """Punto de Blender → juego."""
    return (v.x, v.z, -v.y)


def _triangulate(points):
    """Triangulación por orejas de un polígono simple [(z, y), ...]. Devuelve triángulos de puntos."""
    pts = list(points)
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))
    if area < 0:
        pts.reverse()

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    def inside(p, a, b, c):
        return cross(a, b, p) >= -1e-9 and cross(b, c, p) >= -1e-9 and cross(c, a, p) >= -1e-9

    out = []
    guard = 0
    while len(pts) > 3 and guard < 1000:
        guard += 1
        n = len(pts)
        for i in range(n):
            a, b, c = pts[(i - 1) % n], pts[i], pts[(i + 1) % n]
            if cross(a, b, c) <= 1e-9:
                continue
            if any(inside(p, a, b, c) for p in pts if p not in (a, b, c)):
                continue
            out.append((a, b, c))
            del pts[i]
            break
        else:
            break
    if len(pts) == 3:
        out.append(tuple(pts))
    return out


class Weapon:
    def __init__(self, name, palette=None):
        self.name = name
        self.palette = dict(DEFAULT_PALETTE)
        self.palette.update(palette or {})
        self.objects = []
        self.solids = []  # primitivas (bloque, cuña, cilindro) equivalentes, para construir el arma en Roblox
        self.points = {}
        self.materials = {}
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.collection)

    # ----------------------------------------------------------------- materiales
    def material(self, role):
        if role in self.materials:
            return self.materials[role]
        mat = bpy.data.materials.new(f"SR_{role}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        color = self.palette.get(role, (0.5, 0.5, 0.5))
        metallic, roughness, emission = ROLE_SHADING.get(role, (0.2, 0.5, 0.0))
        # (PALETTE["Emission"] = {papel: fuerza}: papeles que en esta arma brillan, como el magma)
        emission = self.palette.get("Emission", {}).get(role, emission)
        bsdf.inputs["Base Color"].default_value = (*color, 1)
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission > 0:
            bsdf.inputs["Emission Color"].default_value = (*color, 1)
            bsdf.inputs["Emission Strength"].default_value = emission
        mat.diffuse_color = (*color, 1)
        self.materials[role] = mat
        return mat

    # ----------------------------------------------------------------- geometría
    def _finish(self, bm, name, role, piece, bevel):
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        if bevel and bevel > 0:
            edges = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > SHARP_ANGLE]
            if edges:
                bmesh.ops.bevel(bm, geom=edges, offset=bevel, offset_type="OFFSET", segments=1, profile=0.5, affect="EDGES", clamp_overlap=True)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        # Sombreado plano por planos: se parten los vértices en las aristas vivas
        sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > SHARP_ANGLE]
        if sharp:
            bmesh.ops.split_edges(bm, edges=sharp)
        for face in bm.faces:
            face.smooth = True
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        self.collection.objects.link(obj)
        obj.data.materials.append(self.material(role))
        obj["role"] = role
        if piece:
            obj["piece"] = piece
        self.objects.append(obj)
        return obj

    def box(self, name, center, size, role="Body", bevel=0.02, piece=None, rot=None, taper=None):
        """Caja con chaflán. center/size en coordenadas del juego. rot = (rx, ry, rz) en grados (ejes
        del juego). taper = (escala X, escala Y) de la cara delantera (-Z) respecto a la trasera."""
        bm = bmesh.new()
        sx, sy, sz = size[0] / 2, size[1] / 2, size[2] / 2
        corners = []
        for z in (sz, -sz):  # atrás, delante
            tx, ty = (1, 1) if z > 0 or not taper else taper
            for y in (-sy, sy):
                for x in (-sx, sx):
                    corners.append((x * tx, y * ty, z))
        m = Matrix.Identity(4)
        if rot:
            m = (Matrix.Rotation(math.radians(rot[2]), 4, "Z") @ Matrix.Rotation(math.radians(rot[1]), 4, "Y") @ Matrix.Rotation(math.radians(rot[0]), 4, "X"))
        verts = []
        for c in corners:
            p = m @ Vector(c)
            verts.append(bm.verts.new(g2b((p.x + center[0], p.y + center[1], p.z + center[2]))))
        for idx in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            bm.faces.new([verts[i] for i in idx])
        r3 = m.to_3x3()
        self._solid("B", role, piece, center, size, [r3[i][j] for i in range(3) for j in range(3)])
        return self._finish(bm, name, role, piece, bevel)

    def profile(self, name, points, width, role="Body", bevel=0.02, piece=None, x=0.0, width_front=None, z_split=None):
        """Silueta lateral extruida: points = [(z, y), ...] en el plano lateral del juego, en orden.
        width = grosor en X (centrado en x). width_front + z_split: más estrecha por delante de z_split."""
        bm = bmesh.new()

        def half(z):
            if width_front is None or z_split is None:
                return width / 2
            return (width_front if z < z_split else width) / 2

        left = [bm.verts.new(g2b((x - half(z), y, z))) for z, y in points]
        right = [bm.verts.new(g2b((x + half(z), y, z))) for z, y in points]
        bm.faces.new(left)
        bm.faces.new(list(reversed(right)))
        n = len(points)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((left[j], left[i], right[i], right[j]))
        for tri in _triangulate(points):
            self._wedges(role, piece, x, width, tri)
        return self._finish(bm, name, role, piece, bevel)

    def cyl(self, name, a, b, radius, role="Metal", segments=14, piece=None, radius_b=None, bevel=0.0):
        """Cilindro (o cono truncado) entre dos puntos del juego."""
        bm = bmesh.new()
        pa, pb = g2b(a), g2b(b)
        axis = pb - pa
        depth = axis.length
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments, radius1=radius, radius2=radius if radius_b is None else radius_b, depth=depth)
        rot = Vector((0, 0, 1)).rotation_difference(axis.normalized()).to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=Matrix.Translation((pa + pb) / 2) @ rot, verts=bm.verts)
        self._cylinder(role, piece, a, b, (radius + (radius if radius_b is None else radius_b)) / 2)
        return self._finish(bm, name, role, piece, bevel)

    def ring(self, name, a, b, radius, inner, role="Metal", segments=14, piece=None):
        """Tubo hueco (bocacha, anilla de mira) entre dos puntos del juego."""
        bm = bmesh.new()
        pa, pb = g2b(a), g2b(b)
        axis = pb - pa
        depth = axis.length
        rot = Vector((0, 0, 1)).rotation_difference(axis.normalized()).to_matrix().to_4x4()
        mat = Matrix.Translation((pa + pb) / 2) @ rot
        outer_a, outer_b, inner_a, inner_b = [], [], [], []
        for i in range(segments):
            ang = 2 * math.pi * i / segments
            c, s = math.cos(ang), math.sin(ang)
            outer_a.append(bm.verts.new(mat @ Vector((radius * c, radius * s, -depth / 2))))
            outer_b.append(bm.verts.new(mat @ Vector((radius * c, radius * s, depth / 2))))
            inner_a.append(bm.verts.new(mat @ Vector((inner * c, inner * s, -depth / 2))))
            inner_b.append(bm.verts.new(mat @ Vector((inner * c, inner * s, depth / 2))))
        for i in range(segments):
            j = (i + 1) % segments
            bm.faces.new((outer_a[i], outer_a[j], outer_b[j], outer_b[i]))
            bm.faces.new((inner_a[j], inner_a[i], inner_b[i], inner_b[j]))
            bm.faces.new((outer_a[j], outer_a[i], inner_a[i], inner_a[j]))
            bm.faces.new((outer_b[i], outer_b[j], inner_b[j], inner_b[i]))
        # (en Roblox: cilindro macizo y un núcleo oscuro que asoma por los dos extremos, como ánima)
        self._cylinder(role, piece, a, b, radius)
        ga, gb = Vector(a), Vector(b)
        d = (gb - ga).normalized() * 0.006
        self._cylinder("Dark", piece, tuple(ga - d), tuple(gb + d), inner)
        return self._finish(bm, name, role, piece, 0)

    # ----------------------------------------------------------------- primitivas para Roblox
    def _solid(self, shape, role, piece, center, size, rot9):
        if min(size) < 0.003:
            return
        self.solids.append({"s": shape, "role": role, "piece": piece, "c": [round(v, 4) for v in center], "size": [round(v, 4) for v in size], "r": [round(v, 5) for v in rot9]})

    def _cylinder(self, role, piece, a, b, radius):
        va, vb = Vector(a), Vector(b)
        axis = vb - va
        if axis.length < 0.003 or radius < 0.003:
            return
        xa = axis.normalized()
        # (el cilindro de Roblox va a lo largo de su eje X)
        helper = Vector((0, 1, 0)) if abs(xa.y) < 0.9 else Vector((1, 0, 0))
        za = xa.cross(helper).normalized()
        ya = za.cross(xa).normalized()
        rot = [xa.x, ya.x, za.x, xa.y, ya.y, za.y, xa.z, ya.z, za.z]
        self._solid("C", role, piece, tuple((va + vb) / 2), (axis.length, radius * 2, radius * 2), rot)

    def _wedges(self, role, piece, x, width, tri):
        """Triángulo de la silueta (puntos (z, y)) → dos cuñas (prismas de triángulo rectángulo)."""
        pts = [Vector((x, y, z)) for z, y in tri]
        # base = el lado más largo; pie de la altura desde el vértice opuesto
        best = max(range(3), key=lambda i: (pts[(i + 1) % 3] - pts[i]).length)
        p, q, r = pts[best], pts[(best + 1) % 3], pts[(best + 2) % 3]
        base = q - p
        t = (r - p).dot(base) / base.length_squared
        foot = p + base * t
        for end in (p, q):
            leg_a, leg_b = end - foot, r - foot
            if leg_a.length < 0.004 or leg_b.length < 0.004:
                continue
            ya = leg_b.normalized()
            za = -leg_a.normalized()
            xa = ya.cross(za)
            rot = [xa.x, ya.x, za.x, xa.y, ya.y, za.y, xa.z, ya.z, za.z]
            self._solid("W", role, piece, tuple((end + r) / 2), (width, leg_b.length, leg_a.length), rot)

    def mirror_x(self, builder):
        """Llama builder(lado) con lado = -1 y +1 (piezas simétricas a los dos lados)."""
        return [builder(-1), builder(1)]

    def point(self, name, position):
        """Punto de referencia (Muzzle, AimPoint, Eject, LeftHand, RightHand, CharmPoint)."""
        self.points[name] = tuple(position)
        empty = bpy.data.objects.new(name, None)
        empty.empty_display_type = "PLAIN_AXES"
        empty.empty_display_size = 0.08
        empty.location = g2b(position)
        self.collection.objects.link(empty)

    # ----------------------------------------------------------------- medidas
    def stats(self):
        tris = sum(len(o.data.polygons) for o in self.objects)
        verts = sum(len(o.data.vertices) for o in self.objects)
        lo = Vector((1e9, 1e9, 1e9))
        hi = Vector((-1e9, -1e9, -1e9))
        for o in self.objects:
            for v in o.data.vertices:
                g = b2g(v.co)
                for i in range(3):
                    lo[i] = min(lo[i], g[i])
                    hi[i] = max(hi[i], g[i])
        return {"objects": len(self.objects), "tris": tris, "verts": verts, "min": tuple(round(c, 3) for c in lo), "max": tuple(round(c, 3) for c in hi)}

    # ----------------------------------------------------------------- exportación
    def export(self, out_dir):
        os.makedirs(out_dir, exist_ok=True)
        # 1) Datos para el juego: una malla por objeto, en coordenadas del juego, centrada en su caja
        pieces = []
        for o in self.objects:
            mesh = o.data
            pts = [b2g(v.co) for v in mesh.vertices]
            lo = [min(p[i] for p in pts) for i in range(3)]
            hi = [max(p[i] for p in pts) for i in range(3)]
            center = [(lo[i] + hi[i]) / 2 for i in range(3)]
            pieces.append({
                "name": o.name,
                "role": o.get("role", "Body"),
                "piece": o.get("piece"),
                "center": [round(c, 5) for c in center],
                "size": [round(hi[i] - lo[i], 5) for i in range(3)],
                "verts": [round(p[i] - center[i], 5) for p in pts for i in range(3)],
                "tris": [i for poly in mesh.polygons for i in poly.vertices],
            })
        data = {"name": self.name, "points": self.points, "stats": self.stats(), "pieces": pieces, "solids": self.solids}
        with open(os.path.join(out_dir, self.name + ".mesh.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, separators=(",", ":"))
        # 2) Fuente editable y formatos de intercambio
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out_dir, self.name + ".blend"))
        bpy.ops.object.select_all(action="DESELECT")
        for o in self.collection.objects:
            o.select_set(True)
        try:
            bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, self.name + ".fbx"), use_selection=True, apply_scale_options="FBX_SCALE_ALL", object_types={"MESH", "EMPTY"}, mesh_smooth_type="FACE", add_leaf_bones=False)
        except Exception as error:  # noqa: BLE001
            print("FBX no exportado:", error)
        try:
            bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, self.name + ".glb"), use_selection=True, export_format="GLB")
        except Exception as error:  # noqa: BLE001
            print("glTF no exportado:", error)
        return data["stats"]

    # ----------------------------------------------------------------- renders
    def _look_at(self, obj, target):
        direction = Vector(target) - obj.location
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    def setup_studio(self, final=False):
        scene = bpy.context.scene
        for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
            try:
                scene.render.engine = engine
                break
            except TypeError:
                continue
        scene.render.resolution_x = 1920 if final else 1280
        scene.render.resolution_y = 1080 if final else 720
        scene.render.film_transparent = False
        # (Standard: colores saturados de arcade; AgX los apaga)
        scene.view_settings.view_transform = "Standard"
        for look in ("Medium High Contrast", "Standard - Medium High Contrast"):
            try:
                scene.view_settings.look = look
                break
            except TypeError:
                continue
        try:
            scene.eevee.taa_render_samples = 64 if final else 24
        except AttributeError:
            pass
        world = bpy.data.worlds.new("SR_World")
        world.use_nodes = True
        world.node_tree.nodes["Background"].inputs[0].default_value = (0.006, 0.007, 0.011, 1)
        world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
        scene.world = world
        st = self.stats()
        lo, hi = Vector(st["min"]), Vector(st["max"])
        center_g = (lo + hi) / 2
        self._center = g2b(center_g)
        self._length = hi.z - lo.z
        self._height = hi.y - lo.y
        # Suelo oscuro (recoge sombra y un reflejo suave)
        bpy.ops.mesh.primitive_plane_add(size=60, location=(self._center.x, self._center.y, g2b(lo).z - 0.35))
        floor = bpy.context.active_object
        fmat = bpy.data.materials.new("SR_Floor")
        fmat.use_nodes = True
        fb = fmat.node_tree.nodes["Principled BSDF"]
        fb.inputs["Base Color"].default_value = (0.012, 0.013, 0.02, 1)
        fb.inputs["Roughness"].default_value = 0.45
        fb.inputs["Metallic"].default_value = 0.2
        floor.data.materials.append(fmat)
        self._floor = floor

        def light(name, loc, energy, color, size):
            data = bpy.data.lights.new(name, "AREA")
            data.energy = energy
            data.color = color
            data.size = size
            obj = bpy.data.objects.new(name, data)
            bpy.context.scene.collection.objects.link(obj)
            obj.location = self._center + Vector(loc)
            self._look_at(obj, self._center)
            return obj

        s = max(self._length, 2.5)
        # (posiciones en ejes de Blender: X derecha del arma, Y hacia delante del cañón, Z arriba)
        light("Key", (s * 1.0, s * 0.9, s * 1.5), 170 * s, (1.0, 0.97, 0.92), s * 1.0)
        light("KeyLeft", (-s * 1.0, s * 0.9, s * 1.5), 170 * s, (1.0, 0.97, 0.92), s * 1.0)
        light("Fill", (s * 0.2, -s * 1.6, s * 0.6), 60 * s, (0.6, 0.75, 1.0), s * 1.6)
        light("RimWarm", (-s * 0.4, s * 1.7, s * 0.5), 240 * s, (1.0, 0.45, 0.12), s * 0.7)
        light("RimCool", (s * 0.2, -s * 0.3, s * 2.2), 150 * s, (0.3, 0.75, 1.0), s * 0.9)
        cam_data = bpy.data.cameras.new("Cam")
        cam_data.lens = 85
        self._cam = bpy.data.objects.new("Cam", cam_data)
        bpy.context.scene.collection.objects.link(self._cam)
        scene.camera = self._cam

    def render_view(self, path, direction, lens=85, margin=1.18, target_offset=(0, 0, 0)):
        """direction: vector (en coordenadas del juego) desde el arma hacia la cámara."""
        scene = bpy.context.scene
        cam = self._cam
        cam.data.lens = lens
        d = g2b(direction).normalized()
        target = self._center + g2b(target_offset)
        # Distancia para encuadrar la caja del arma
        st = self.stats()
        lo, hi = Vector(st["min"]), Vector(st["max"])
        corners = [g2b((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
        cam.location = target + d * 10
        self._look_at(cam, target)
        bpy.context.view_layer.update()
        inv = cam.matrix_world.inverted()
        aspect = scene.render.resolution_x / scene.render.resolution_y
        half_w = math.tan(cam.data.angle_x / 2)
        half_h = half_w / aspect
        need = 0.0
        for c in corners:
            p = inv @ c
            depth = -p.z
            need = max(need, abs(p.x) / half_w - depth + 10, abs(p.y) / half_h - depth + 10)
        cam.location = target + d * max(need * margin, 0.5)
        self._look_at(cam, target)
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)

    def render_set(self, out_dir, final=False):
        os.makedirs(out_dir, exist_ok=True)
        self.setup_studio(final)
        views = {
            "side": ((1, 0.06, 0.0), 110),
            "threequarter": ((0.85, 0.42, -0.7), 85),
            "back34": ((0.8, 0.4, 0.75), 85),
            "front": ((0.25, 0.2, -1), 70),
            "top": ((0.25, 1, 0.15), 100),
        }
        if final:
            views["hero"] = ((0.7, 0.22, -0.55), 60)
            views["left"] = ((-1, 0.1, -0.15), 110)
        done = []
        for key, (direction, lens) in views.items():
            path = os.path.join(out_dir, f"{self.name}_{key}.png")
            self.render_view(path, direction, lens)
            done.append(path)
        # Primera persona: desde detrás y arriba a la derecha, como se ve en el juego
        path = os.path.join(out_dir, f"{self.name}_firstperson.png")
        self.render_view(path, (-0.32, 0.38, 1), 35, margin=0.62, target_offset=(0, 0.1, -0.6))
        done.append(path)
        return done
