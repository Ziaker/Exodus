"""Valida a maquete do MCP e prepara as vistas da câmara."""
import bpy
from bpy_extras.object_utils import world_to_camera_view
import json
import math
from pathlib import Path
import sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
title='D01 · Ruptura · Interior'
scene=bpy.data.scenes.get(title+' · revisão') or bpy.data.scenes[title]
bpy.context.window.scene=scene
preview='preview' in sys.argv
views=('camara','limiar','sepulcro','gravidades','planta','geometria')
cameras=sorted((obj for obj in scene.objects if obj.type=='CAMERA'),key=lambda obj:obj.name)
assert len(cameras)==len(views)
assert all(math.isclose(c.data.angle_y,2*math.atan(245/304),abs_tol=1e-6) for c in cameras[:3])
entry=Vector(scene['entrada_exterior'])
assert abs(entry.x-7.1823)<.001 and abs(entry.y-17.7)<1e-6 and entry.z==0
gate=[obj for obj in scene.objects if obj.name.startswith(('Ombreira descalçada','Lintel sem metade'))]
assert len(gate)==3 and all(abs(obj.location.y-entry.y)<1e-5 for obj in gate)
deps=bpy.context.evaluated_depsgraph_get()
volume=next(obj for obj in scene.objects if obj.name.startswith('Volume de poeira'))


def floor(x,y):
    direction=Vector((0,0,-1))
    hit,loc,_,_,obj,_=scene.ray_cast(deps,entry+Vector((x,y,1.2)),direction,distance=6)
    if hit and obj==volume:
        hit,loc,_,_,obj,_=scene.ray_cast(deps,loc+direction*.05,direction,distance=6)
    assert hit,(x,y)
    return round(loc.z,3),obj.name


measured={str(y):floor(.29,y) for y in (2.3,6.2,10.1,14.6,19.1,24.2)}
assert all(abs(values[0])<.16 for values in measured.values())
pit=floor(-4.30,15.04)[0]
assert pit<-3.45,pit

camera=cameras[0]
sprite_slots=[]
for x in (-1.54,-.06,1.42,2.90):
    y=16.4
    assert abs(floor(x,y)[0])<.16
    outline=[]
    for dx,z in ((-.45,0),(.45,2.4)):
        location=entry+Vector((x+dx,y,z))
        p=world_to_camera_view(scene,camera,location)
        assert .04<p.x<.96 and .04<p.y<.96 and p.z>0,tuple(p)
        outline.append([round(p.x,3),round(p.y,3)])
    if sprite_slots:
        assert sprite_slots[-1][1][0]<outline[0][0],sprite_slots
    sprite_slots.append(outline)

triangles=0
for obj in scene.objects:
    if obj.type!='MESH':
        continue
    evaluated=obj.evaluated_get(deps)
    mesh=evaluated.to_mesh()
    assert all(math.isfinite(v) for vertex in mesh.vertices for v in vertex.co)
    mesh.calc_loop_triangles()
    triangles+=len(mesh.loop_triangles)
    evaluated.to_mesh_clear()
audit={'cameras':len(cameras),'pecas_do_portico':len(gate),'entrada_global':list(entry),
       'piso_do_percurso':measured,'fundo_do_corte':pit,'quadros_para_4_sprites':sprite_slots,
       'triangulos_avaliados':triangles}
print('AUDITORIA',audit,flush=True)

if not preview and Path(bpy.data.filepath).name!='Necropole_Saturnina_Interior.blend':
    target=ROOT/'Necropole_Saturnina_Interior.blend'
    assert not target.exists()
    for other in tuple(bpy.data.scenes):
        if other!=scene:
            bpy.data.scenes.remove(other)
    materials={slot.material for obj in scene.objects if obj.type=='MESH'
               for slot in obj.material_slots if slot.material}
    for mat in bpy.data.materials:
        if mat not in materials:
            mat.use_fake_user=False
    for doc in tuple(bpy.data.texts):
        if not doc.name.startswith('D01 · Interior · Revisão'):
            bpy.data.texts.remove(doc)
    bpy.data.orphans_purge(do_local_ids=True,do_linked_ids=False,do_recursive=True)
    assert len(bpy.data.scenes)==1 and len(bpy.data.libraries)==0
    scene.name=title
    scene.camera=cameras[0]
    scene.render.filepath='//'
    bpy.ops.wm.save_as_mainfile(filepath=str(target),compress=True)
    (ROOT/'auditoria.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')

folder=ROOT/('previa' if preview else 'raw')
folder.mkdir(exist_ok=True)
scene.render.resolution_percentage=67 if preview else 100
scene.eevee.taa_render_samples=16 if preview else 40
scene.render.threads_mode='FIXED'
scene.render.threads=8
roof=next(c for c in scene.collection.children if c.name.startswith('Interior · Teto removível'))

for key,camera in zip(views,cameras):
    scene.camera=camera
    for obj in roof.objects:
        obj.hide_render=key in {'planta','geometria'}
    if key=='planta':
        top=bpy.data.lights.new('Luz de inspeção da planta','AREA')
        top.energy=2400
        top.shape='DISK'
        top.size=26
        top.color=(.86,.80,.71)
        fill=bpy.data.objects.new(top.name,top)
        scene.collection.objects.link(fill)
        fill.location=entry+Vector((0,13,16))
    if key=='geometria':
        scene.render.engine='BLENDER_WORKBENCH'
        shade=scene.display.shading
        shade.light='STUDIO'
        shade.color_type='SINGLE'
        shade.single_color=(.51,.49,.46)
        shade.show_cavity=True
        shade.cavity_type='BOTH'
        shade.show_shadows=True
        shade.show_object_outline=True
        volume.hide_render=True
        for obj in scene.objects:
            if obj.name.startswith('Parede escavada em veios') and obj.location.x>entry.x:
                obj.hide_render=True
    scene.render.filepath=str(folder/(key+'.png'))
    bpy.ops.render.render(write_still=True,scene=scene.name)
