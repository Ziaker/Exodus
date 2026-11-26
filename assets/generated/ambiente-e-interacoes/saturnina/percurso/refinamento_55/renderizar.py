"""Audita conectividade física da maquete e renderiza as onze câmeras."""
from collections import deque
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from planta import CELL,adjacent,design,metrics

NAME='D01 · Necrópole Saturnina · 55 salas refinadas'
FINAL=ROOT/'Necropole_Saturnina_55_Salas_Refinadas.blend'
scene=bpy.data.scenes.get(NAME+' · revisão') or bpy.data.scenes[NAME]
bpy.context.window.scene=scene
centers,rooms,halls=design()
cameras=sorted((obj for obj in scene.objects if obj.type=='CAMERA'),key=lambda o:o.name)
assert len(cameras)==11
assert all(math.isclose(c.data.angle_y,2*math.atan(245/304),abs_tol=1e-6) for c in cameras[:10])
root_floor=next(c for c in scene.collection.children if c.name.startswith('R55 · Pisos'))
floor_names={obj.name for obj in root_floor.objects}
assert len(floor_names)==122
deps=bpy.context.evaluated_depsgraph_get()


def face_to_face(room_obstacles=()):
    tiles=set().union(*rooms.values(),*halls.values())-set(room_obstacles)
    start=centers['I-B']
    on_floor=set()
    for x,y in tiles:
        hit,loc,_,_,obj,_=scene.ray_cast(deps,Vector((x*CELL,y*CELL,1.43)),
                                      Vector((0,0,-1)),distance=1.47)
        if hit and abs(loc.z)<.03 and obj.name in floor_names:
            on_floor.add((x,y))
    assert start in on_floor
    distances={start:1}
    todo=deque([start])
    while todo:
        current=todo.popleft()
        pos=Vector((current[0]*CELL,current[1]*CELL,.8421))
        for nxt in adjacent(current):
            if nxt not in on_floor or nxt in distances:
                continue
            delta=Vector(((nxt[0]-current[0])*CELL,(nxt[1]-current[1])*CELL,0))
            if scene.ray_cast(deps,pos,delta.normalized(),distance=delta.length-.022)[0]:
                continue
            distances[nxt]=distances[current]+1
            todo.append(nxt)
    return distances


route=face_to_face()
unreachable=[room for room,cell in centers.items() if cell not in route]
assert not unreachable,unreachable
assert centers['V-K'] not in face_to_face(rooms['I-F'])
report=metrics()
report.update({'cameras':len(cameras),'salas_alcancadas_por_raios':55,
               'menor_trajeto_na_malha':route[centers['V-K']],
               'passagens_com_dobras':sum(len({x for x,y in hall})>1 and len({y for x,y in hall})>1 for hall in halls.values())})
print('AUDITORIA',report,flush=True)

if 'auditar' in sys.argv:
    assert bpy.data.filepath==str(FINAL) and len(bpy.data.scenes)==1 and not bpy.data.libraries
    sys.exit(0)

if bpy.data.filepath!=str(FINAL):
    assert not FINAL.exists(),FINAL
    for other in tuple(bpy.data.scenes):
        if other!=scene:
            bpy.data.scenes.remove(other)
    materials={slot.material for obj in scene.objects if obj.type=='MESH'
               for slot in obj.material_slots if slot.material}
    for mat in bpy.data.materials:
        if mat not in materials:
            mat.use_fake_user=False
    for d in tuple(bpy.data.texts):
        if not d.name.startswith('D01 · R55 · Revisão'):
            bpy.data.texts.remove(d)
    bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=False,do_recursive=True)
    assert len(bpy.data.scenes)==1 and not bpy.data.libraries
    scene.name=NAME
    scene.camera=cameras[0]
    scene.render.filepath='//'
    bpy.ops.wm.save_as_mainfile(filepath=str(FINAL),compress=True)
    (ROOT/'auditoria.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

folder=ROOT/'raw'
folder.mkdir(exist_ok=True)
scene.render.threads_mode='FIXED'
scene.render.threads=8
scene.eevee.taa_render_samples=26
for i,cam in enumerate(cameras,1):
    scene.camera=cam
    if i==11:
        scene.render.engine='BLENDER_WORKBENCH'
        shade=scene.display.shading
        shade.light='STUDIO'
        shade.color_type='MATERIAL'
        shade.show_shadows=True
        for obj in scene.objects:
            if obj.name.startswith('Volume de poeira') or any(c.name.startswith('R55 · Cobertura') for c in obj.users_collection):
                obj.hide_render=True
    output=folder/(f'{i:02d}.png')
    if not output.exists():
        scene.render.filepath=str(output)
        bpy.ops.render.render(write_still=True,scene=scene.name)
