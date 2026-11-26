"""Isola a maquete criada via MCP, mede o percurso e renderiza suas câmeras."""
import math
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from mapa import CELL,ZONES,audit_layout,layout,main_route

title='D01 · Necrópole Saturnina · Percurso'
scene=bpy.data.scenes.get(title+' · revisão') or bpy.data.scenes[title]
bpy.context.window.scene=scene
preview='preview' in sys.argv
cameras=sorted((o for o in scene.objects if o.type=='CAMERA'),key=lambda o:o.name)
assert len(cameras)==6
cameras[-1].data.clip_end=320
assert all(math.isclose(o.data.angle_y,2*math.atan(245/304),abs_tol=1e-6) for o in cameras[:5])
deps=bpy.context.evaluated_depsgraph_get()


def validate_route():
    heights=[]
    for x,y in main_route():
        origin=Vector((x*CELL,y*CELL,1.35))
        hit,loc,_,_,obj,_=scene.ray_cast(deps,origin,Vector((0,0,-1)),distance=1.41)
        assert hit and -.029<=loc.z<=.16,(x,y,loc.z,obj.name if obj else None)
        heights.append(loc.z)
    return [round(min(heights),3),round(max(heights),3)]


report=audit_layout(layout())
report['altura_do_piso_da_rota']=validate_route()
report['cameras']=len(cameras)
print('AUDITORIA',report,flush=True)

stage_name='Necropole_Saturnina_Percurso.blend'
if not preview and Path(bpy.data.filepath).name!=stage_name:
    output=ROOT/stage_name
    assert not output.exists(),output
    for other in tuple(bpy.data.scenes):
        if other!=scene:
            bpy.data.scenes.remove(other)
    mats={slot.material for obj in scene.objects if obj.type=='MESH'
          for slot in obj.material_slots if slot.material}
    for mat in bpy.data.materials:
        if mat not in mats:
            mat.use_fake_user=False
    for doc in tuple(bpy.data.texts):
        if not doc.name.startswith('D01 · Percurso · Revisão'):
            bpy.data.texts.remove(doc)
    bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=False,do_recursive=True)
    assert len(bpy.data.scenes)==1 and len(bpy.data.libraries)==0
    scene.name=title
    scene.camera=cameras[0]
    scene.render.filepath='//'
    bpy.ops.wm.save_as_mainfile(filepath=str(output),compress=True)
    (ROOT/'auditoria.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

folder=(ROOT/'raw') if not preview else Path(sys.argv[-1]).resolve()
folder.mkdir(exist_ok=True)
scene.render.resolution_percentage=67 if preview else 100
scene.eevee.taa_render_samples=14 if preview else 32
scene.render.threads_mode='FIXED'
scene.render.threads=8
for name,cam in zip(('portico','avenida','claustro','ossuario','sepulcro','planta'),cameras):
    scene.camera=cam
    if name=='planta':
        scene.render.engine='BLENDER_WORKBENCH'
        shade=scene.display.shading
        shade.light='STUDIO'
        shade.color_type='MATERIAL'
        shade.show_shadows=True
        shade.show_cavity=True
        shade.cavity_type='BOTH'
        sha=next(obj for obj in scene.objects if obj.name.startswith('Volume de poeira'))
        sha.hide_render=True
    scene.render.filepath=str(folder/(name+'.png'))
    bpy.ops.render.render(write_still=True,scene=scene.name)
