"""Exporta a geometria da Necrópole para um projeto Godot isolado."""
from collections import defaultdict
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.noise import noise

ROOT=Path(__file__).resolve().parent
TARGET=ROOT/'ensaio_godot'
sys.path.insert(0,str(ROOT))
from planta import CELL,ZONES,design

source=bpy.context.scene
assert source['salas']==55
assert not (TARGET/'necropole.glb').exists()
deps=bpy.context.evaluated_depsgraph_get()
chunks=defaultdict(list)
terrain_names=('R55 · Pisos','R55 · Paredes')
sky_objects=('Volume de poeira',)
for obj in source.objects:
    if obj.type!='MESH' or obj.name.startswith(sky_objects):
        continue
    kind='base' if any(c.name.startswith(terrain_names) for c in obj.users_collection) else 'detalhe'
    pts=[obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    center=sum(pts,Vector())/8
    chunk=(math.floor(center.x/(CELL*14)),math.floor(center.y/(CELL*14)),kind)
    chunks[chunk].append(obj)

test=bpy.data.scenes.new('Exportação isolada · Compatibility')
materials={}


def flat_material(mat):
    if mat in materials:
        return materials[mat]
    base=bpy.data.materials.new('Ensaio · '+mat.name)
    base.use_nodes=True
    base.use_backface_culling=False
    core=next(node for node in base.node_tree.nodes if node.type=='BSDF_PRINCIPLED')
    core.inputs['Base Color'].default_value=(.67,.67,.67,1)
    original=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if mat.node_tree else None
    core.inputs['Roughness'].default_value=original.inputs['Roughness'].default_value if original else .91
    core.inputs['Metallic'].default_value=0.0
    materials[mat]=base
    return base


tri_count=0
for (x,y,kind),objs in sorted(chunks.items()):
    verts=[]
    faces=[]
    face_material=[]
    face_color=[]
    output_mats=[]
    for original in objs:
        eval_obj=original.evaluated_get(deps)
        mesh=eval_obj.to_mesh()
        matrix=original.matrix_world
        mesh.calc_loop_triangles()
        offset=len(verts)
        coords=[matrix @ v.co for v in mesh.vertices]
        verts.extend((p/CELL for p in coords))
        palette={}
        for tri in mesh.loop_triangles:
            slot=tri.material_index
            mat=mesh.materials[slot]
            assert mat is not None,original.name
            if slot not in palette:
                simple=flat_material(mat)
                if simple not in output_mats:
                    output_mats.append(simple)
                palette[slot]=(output_mats.index(simple),tuple(mat.diffuse_color))
            index,color=palette[slot]
            faces.append(tuple(offset+i for i in tri.vertices))
            face_material.append(index)
            face_color.append(color)
        eval_obj.to_mesh_clear()
    name=f'{kind}_{x}_{y}'
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    for mat in output_mats:
        mesh.materials.append(mat)
    tint=mesh.color_attributes.new(name='Ensaio',type='FLOAT_COLOR',domain='CORNER')
    mesh.color_attributes.active_color=tint
    # Paleta aproximada do Blender, com variação mineral por vértice para o ensaio.
    for polygon,index,color in zip(mesh.polygons,face_material,face_color):
        polygon.material_index=index
        for i in polygon.loop_indices:
            pt=mesh.vertices[mesh.loops[i].vertex_index].co
            tone=.92+.24*noise(Vector((pt.x*4.7,pt.y*4.4,pt.z*7.9)))+.085*math.sin(pt.z*16.1)
            tint.data[i].color=tuple(max(0,min(1,v*tone)) for v in color[:3])+(1,)
    obj=bpy.data.objects.new(name,mesh)
    test.collection.objects.link(obj)
    tri_count+=len(faces)

opts=bpy.ops.export_scene.gltf.get_rna_type().properties
bpy.context.window.scene=test
kw={'filepath':str(TARGET/'necropole.glb'),'export_format':'GLB',
    'export_cameras':False,'export_lights':False,'export_animations':False,
    'use_active_scene':True,'export_yup':True}
if 'export_vertex_color' in opts:
    kw['export_vertex_color']='ACTIVE'
assert bpy.ops.export_scene.gltf(**kw)=={'FINISHED'}
centers,rooms,halls=design()
grid=set().union(*rooms.values(),*halls.values())
data={'grid':sorted(grid),'centers':centers,'checkpoints':[z.roman+'-'+z.focus for z in ZONES],
      'start':'I-B','end':'V-K','ruptura':sorted(rooms['I-F']),
      'meshes':len(chunks),'triangles':tri_count}
(TARGET/'mapa.json').write_text(json.dumps(data,separators=(',',':'))+'\n',encoding='utf-8')
print(f'EXPORTADO {len(chunks)} blocos, {tri_count} triângulos, {len(grid)} células e {len(rooms)} centros')
