import bpy, math, os, sys

OUT = os.path.abspath("assets/models/dinosaurs")
os.makedirs(OUT, exist_ok=True)

SPECIES = {
    "velociraptor": ((0.25,0.48,0.72), (0.92,0.78,0.30), "biped"),
    "triceratops": ((0.55,0.42,0.28), (0.92,0.78,0.38), "quad"),
    "ankylosaurus": ((0.35,0.48,0.28), (0.84,0.70,0.30), "quad"),
    "psittacosaurus": ((0.42,0.68,0.34), (0.95,0.72,0.32), "small"),
    "dryosaurus": ((0.36,0.58,0.30), (0.85,0.90,0.42), "small"),
    "parasaurolophus": ((0.40,0.55,0.65), (0.95,0.72,0.35), "large"),
    "dilophosaurus": ((0.62,0.30,0.28), (0.95,0.70,0.25), "large"),
    "carnotaurus": ((0.48,0.24,0.18), (0.92,0.55,0.25), "large"),
    "allosaurus": ((0.30,0.30,0.36), (0.88,0.42,0.28), "large"),
}

def mat(name, color, emission=False):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*color,1); bs.inputs['Roughness'].default_value=.84
    if emission: bs.inputs['Emission Color'].default_value=(*color,1); bs.inputs['Emission Strength'].default_value=1.4
    return m

def add_ico(name, loc, scale, material, root):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1, location=loc); o=bpy.context.object; o.name=name; o.scale=scale; o.data.materials.append(material); o.parent=root; return o

def add_cone(name, loc, r1, r2, depth, material, root, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=r1, radius2=r2, depth=depth, location=loc, rotation=rot); o=bpy.context.object; o.name=name; o.data.materials.append(material); o.parent=root; return o

def build(species, colors, kind):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    body=mat('Body', colors[0]); accent=mat('Accent', colors[1]); eyes=mat('Eyes',(0.02,.02,.015),True)
    root=bpy.data.objects.new(species.title(),None); bpy.context.collection.objects.link(root)
    scale={'small':.72,'biped':.9,'large':1.15,'quad':1.0}[kind]
    add_ico('Body',(0,0.9*scale,0),(0.62*scale,0.55*scale,1.0*scale),body,root)
    add_ico('Head',(0,1.35*scale,-.9*scale),(.42*scale,.38*scale,.52*scale),body,root)
    add_ico('Snout',(0,1.22*scale,-1.25*scale),(.34*scale,.24*scale,.38*scale),accent,root)
    add_cone('Tail',(0,.78*scale,1.35*scale),.34*scale,.03*scale,2.4*scale,body,root,(math.pi/2,0,0))
    for side in (-1,1):
        add_ico('Eye',(side*.25*scale,1.48*scale,-1.27*scale),(.065*scale,)*3,eyes,root)
        if kind in ('quad','small'):
            for z in (-.32,.36): add_cone('Leg',(side*.38*scale,.38*scale,z*scale),.14*scale,.09*scale,.72*scale,body,root)
        else:
            add_cone('Leg',(side*.36*scale,.38*scale,-.12*scale),.16*scale,.10*scale,.82*scale,body,root)
            add_cone('Arm',(side*.42*scale,.92*scale,-.52*scale),.08*scale,.035*scale,.42*scale,body,root,(0,side*.35,0))
    # Species-readable crest/horns.
    if species in ('triceratops','carnotaurus'):
        for side in (-1,1): add_cone('Horn',(side*.25*scale,1.48*scale,-1.35*scale),.10*scale,0,.46*scale,accent,root,(math.pi/2,0,0))
    if species == 'parasaurolophus': add_cone('Crest',(0,1.72*scale,-.92*scale),.20*scale,.03*scale,.75*scale,accent,root,(0,0,math.pi/2))
    if species == 'dilophosaurus':
        for side in (-1,1): add_ico('Frill',(side*.22*scale,1.45*scale,-.98*scale),(.16*scale,.32*scale,.08*scale),accent,root)
    bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active=root
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,species+'.glb'), export_format='GLB', export_animations=True, export_materials='EXPORT')

for name, (colors, accent, kind) in SPECIES.items(): build(name,(colors,accent),kind)
print('Exported', len(SPECIES), 'dinosaur GLBs to', OUT)
