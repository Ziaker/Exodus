"""Reabre a cópia do MCP e renderiza o estudo em uma sessão isolada."""
import bpy
import json
import math
import os
from pathlib import Path
import sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
SCENE='D01 · Necrópole Saturnina · Ruptura'
VIEWS=('exploracao','margem','fenda','geral','planta','geometria','rua_invertida')
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
preview='preview' in args
scene=bpy.data.scenes.get(SCENE+' · revisão') or bpy.data.scenes[SCENE]
bpy.context.window.scene=scene
scene.render.threads_mode='FIXED'
scene.render.threads=min(8,os.cpu_count() or 4)
cameras=sorted((obj for obj in scene.objects if obj.type=='CAMERA'),key=lambda obj:obj.name)
assert len(cameras)==len(VIEWS)
assert all(math.isclose(camera.data.angle_y,2*math.atan(245/304),abs_tol=1e-6)
           for camera in cameras[:2])
depsgraph=bpy.context.evaluated_depsgraph_get()
volume=next(obj for obj in scene.objects if obj.name.startswith('Volume de poeira'))


def depth_at(x,y):
    start=2.0
    direction=Vector((0,0,-1))
    hit,loc,_,_,obj,_=scene.ray_cast(depsgraph,Vector((x,y,start)),direction,distance=24)
    # A caixa de espalhamento não é piso nem geometria sólida da fissura.
    if hit and obj==volume:
        hit,loc,_,_,obj,_=scene.ray_cast(depsgraph,loc+direction*.05,direction,distance=24)
    assert hit,(x,y)
    return round(loc.z,3),obj.name


measurements={
    'exploracao': depth_at(*cameras[0].location.xy),
    'margem': depth_at(*cameras[1].location.xy),
    'eixo_da_fenda': depth_at(-2.25,2.0),
}
assert abs(measurements['exploracao'][0])<.27
assert abs(measurements['margem'][0])<.27
assert measurements['eixo_da_fenda'][0]<-12,measurements
audit={'cameras':len(cameras),'medicoes':measurements,'triangulos_avaliados':0,'malhas':0}
for obj in scene.objects:
    if obj.type!='MESH':
        continue
    audit['malhas']+=1
    item=obj.evaluated_get(depsgraph)
    mesh=item.to_mesh()
    assert all(math.isfinite(v) for vertex in mesh.vertices for v in vertex.co),obj.name
    mesh.calc_loop_triangles()
    audit['triangulos_avaliados']+=len(mesh.loop_triangles)
    item.to_mesh_clear()
print('AUDITORIA',audit,flush=True)

if not preview:
    output=ROOT/'Necropole_Saturnina_Ruptura.blend'
    assert not output.exists(),output
    for other in tuple(bpy.data.scenes):
        if other!=scene:
            bpy.data.scenes.remove(other)
    used_materials={slot.material for obj in scene.objects if obj.type=='MESH'
                    for slot in obj.material_slots if slot.material}
    for material in bpy.data.materials:
        if material not in used_materials:
            material.use_fake_user=False
    for doc in tuple(bpy.data.texts):
        if not doc.name.startswith('D01 · Ruptura · Revisão'):
            bpy.data.texts.remove(doc)
    bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=False,do_recursive=True)
    assert len(bpy.data.scenes)==1 and not bpy.data.libraries
    scene.name=SCENE
    scene.camera=cameras[0]
    scene.render.resolution_percentage=100
    scene.render.filepath='//'
    bpy.ops.wm.save_as_mainfile(filepath=str(output),compress=True)
    assert output.is_file()
    (ROOT/'auditoria.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')

render_dir=ROOT/('previa' if preview else 'raw')
render_dir.mkdir(exist_ok=True)
scene.render.resolution_percentage=67 if preview else 100
scene.eevee.taa_render_samples=14 if preview else 32
for key,camera in zip(VIEWS,cameras):
    scene.camera=camera
    if key=='geometria':
        scene.render.engine='BLENDER_WORKBENCH'
        shade=scene.display.shading
        shade.light='STUDIO'
        shade.color_type='SINGLE'
        shade.single_color=(.48,.48,.46)
        shade.show_cavity=True
        shade.cavity_type='BOTH'
        shade.show_shadows=True
        shade.show_object_outline=True
        volume.hide_render=True
    scene.render.filepath=str(render_dir/(key+'.png'))
    bpy.ops.render.render(write_still=True,scene=scene.name)
    if key=='geometria':
        volume.hide_render=False
        scene.render.engine='BLENDER_EEVEE'
