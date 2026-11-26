"""Audita e renderiza o arquivo salvo, sem abrir ou modificar o projeto Godot."""
import bpy
import json
import math
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent
VIEWS = ('pov', 'geral', 'aproximacao', 'materiais', 'geometria', 'interesse', 'planta')
PRESETS = (('mineral_silence', .007), ('saturnine_haze', .019), ('ashen_eternity', .035))
argv = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
preview = 'preview' in argv
camera_filter = {arg for arg in argv if arg not in {'preview'}}
if not preview:
    (ROOT/'raw').mkdir(exist_ok=True)
else:
    (ROOT/'previews').mkdir(exist_ok=True)


def render(scene, name):
    output = ROOT/('previews' if preview else 'raw')/(name+'.png')
    if output.exists():
        return
    scene.render.filepath = str(output)
    bpy.ops.render.render(write_still=True, scene=scene.name)
    assert output.is_file(), output


assert len(bpy.data.scenes) == 3
assert len(bpy.data.libraries) == 0
assert any('Geradores editáveis' in text.name for text in bpy.data.texts)
audit = {}
for scene in sorted(bpy.data.scenes, key=lambda item: item.name):
    bpy.context.window.scene=scene
    slug=scene['estudo']
    assert slug in 'ABC'
    cams=sorted((obj for obj in scene.objects if obj.type=='CAMERA'),key=lambda obj: obj.name)
    assert len(cams)==7
    assert math.isclose(cams[0].data.angle_y,2*math.atan(245/304),abs_tol=1e-6)
    assert math.isclose(cams[0].location.z,4*64/304,abs_tol=1e-6)
    raw_triangles=0
    evaluated_triangles=0
    mesh_objects=0
    depsgraph=bpy.context.evaluated_depsgraph_get()
    for obj in scene.objects:
        if obj.type!='MESH': continue
        mesh_objects+=1
        assert all(math.isfinite(v) for vertex in obj.data.vertices for v in vertex.co)
        obj.data.calc_loop_triangles()
        raw_triangles+=len(obj.data.loop_triangles)
        eval_obj=obj.evaluated_get(depsgraph)
        mesh=eval_obj.to_mesh()
        mesh.calc_loop_triangles()
        evaluated_triangles+=len(mesh.loop_triangles)
        eval_obj.to_mesh_clear()
    audit[slug] = {
        'cameras': len(cams), 'meshes': mesh_objects, 'triangulos': raw_triangles,
        'triangulos_avaliados': evaluated_triangles, 'fov_vertical': math.degrees(cams[0].data.angle_y),
        'altura_olho': round(cams[0].location.z,4),
    }
    print('AUDIT',slug,audit[slug],flush=True)
    scene.render.threads_mode='FIXED'
    scene.render.threads=min(8,os.cpu_count() or 4)
    scene.eevee.taa_render_samples=12 if preview else 24
    if preview:
        scene.render.resolution_percentage=65
    volume=next(obj for obj in scene.objects if obj.name.startswith('Volume de poeira'))
    density=next(node for node in volume.active_material.node_tree.nodes if node.type=='VOLUME_SCATTER').inputs['Density']
    if not preview:
        scene.render.resolution_percentage=100
    for i,(key,cam) in enumerate(zip(VIEWS,cams)):
        if preview and key not in ('pov','geral','interesse'): continue
        if camera_filter and slug.lower()+'_'+key not in camera_filter: continue
        scene.camera=cam
        if key == 'geometria':
            scene.render.engine='BLENDER_WORKBENCH'
            shade=scene.display.shading
            shade.light='STUDIO'
            shade.color_type='SINGLE'
            shade.single_color=(.49,.48,.44)
            shade.show_cavity=True
            shade.cavity_type='BOTH'
            shade.show_shadows=True
            shade.show_object_outline=True
            shade.background_type='WORLD'
            volume.hide_render=True
        render(scene,slug.lower()+'_'+key)
        if key == 'geometria':
            volume.hide_render=False
            scene.render.engine='BLENDER_EEVEE'
    if not preview and slug=='B' and not camera_filter:
        scene.camera=cams[0]
        for key,value in PRESETS:
            density.default_value=value
            render(scene,'atmosfera_'+key)
        density.default_value=PRESETS[1][1]

if not preview:
    (ROOT/'auditoria.json').write_text(json.dumps(audit,indent=2),encoding='utf-8')
