"""Refina a geometria de circulação e cinco câmaras laterais no Blender MCP."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Euler,Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/'expansao'))
from modelar_expansao import (Stage,EYE,library,material,boundary,floor,landmark,
                            sarcophagus,carved_vault)
sys.path.insert(0,str(ROOT.parent/'ruptura'))
from modelar import fracture
sys.path.insert(0,str(ROOT))
from planta import CELL,ZONES,adjacent,design,metrics,path_between

TITLE='D01 · Necrópole Saturnina · 55 salas refinadas'
SIDE_ROOMS=(
    ('I-C','Estela fendida'),
    ('II-E','Sarcófago destampado'),
    ('III-H','Oficina das figuras incompletas'),
    ('IV-H','Meridiano na parede'),
    ('V-G','Sino rachado'),
)


def placed(stage, x,y,forward,factory):
    before=set(stage.scene.objects)
    matrix=Euler((0,0,math.atan2(-forward[0],forward[1]))).to_matrix().to_4x4()
    matrix.translation=Vector((x,y,0))
    factory()
    for obj in stage.scene.objects:
        if obj not in before:
            obj.matrix_world=matrix @ obj.matrix_basis


def lateral(stage,kind):
    # A faixa central fica livre em todos os cinco enquadramentos.
    if kind==0:
        stele=fracture(stage,'Estela fendida · face antiga',(-3.34,3.52,.13),
            [(-.95,-.21),(.75,-.1),(.91,2.0),(.52,3.69),(-.23,4.30),(-.92,3.65)],1.05,
            'lime',(.21,-.20))
        stele.rotation_euler.y=-.18
        bit=fracture(stage,'Estela fendida · fragmento baixo',(-2.84,1.31,.46),
            [(-.93,-.38),(.71,-.4),(.32,.73),(-.68,.95)],1.09,'deep',(-.18,.03))
        bit.rotation_euler=(.16,-.41,.21)
        stage.block('Banco funerário recuado',(3.88,3.86,.46),(2.8,3.43,.91),'strata',wear=.14)
    elif kind==1:
        sarcophagus(stage,-3.32,2.51,True)
        lid=stage.block('Tampa apoiada fora da caixa',(-5.34,3.12,.76),(1.65,3.34,.40),'lime',wear=.11)
        lid.rotation_euler.y=.49
        carved_vault(stage,0,3.51,3.89,5.45,2.48)
        for side in (-1,1):
            stage.block('Apoio pétreo da arcada',(side*5.46,3.51,1.58),(1.73,3.41,3.22),
                        'deep',wear=.11)
        for x,z in ((-3.68,7.24),(3.88,7.39)):
            roof=stage.block('Cobertura abatida da cripta',(x,1.12,z),(7.21,18.21,1.28),
                             'strata',wear=.21,coll='Cobertura')
            roof.rotation_euler.y=.16 if x>0 else -.18
    elif kind==2:
        stage.statue(-3.93,4.73,.0,1.02,True)
        stage.statue(4.32,4.73,.0,.82)
        stage.block('Bancada desocupada',(-3.5,1.40,.75),(2.81,1.02,.24),'wood',wear=.09)
        for x in (-4.48,-2.62):
            stage.block('Pé da mesa de talhe',(x,1.40,.38),(.34,.62,.69),'wood',wear=.055)
        stage.shaft('Cinzel sobre a mesa',(-4.34,1.12,.91),(-3.52,1.39,.96),
                    .059,.024,'lead','Objetos')
    elif kind==3:
        stage.block('Parede de medição',(-3.91,5.2,2.41),(4.79,1.27,5.29),
                    'deep',taper=.96,wear=.11)
        stage.ring('Meridiano interrompido',(-3.77,4.45,2.65),1.99,.51,.22,'lime',
                   broken=(.37,1.11),tilt=(1.52,.06,-.23))
        stage.ring('Escala menor sem ponteiro',(-3.75,4.34,2.69),1.17,.13,.13,'lead',
                   broken=(1.70,.62),tilt=(1.57,0,0))
        stage.tomb(4.15,4.9,0,3.01,2.34,3.28)
        for x,z in ((-4.37,5.18),(4.32,5.53)):
            roof=stage.block('Teto quebrado do observatório lateral',(x,1.16,z),(7.46,19.25,1.07),
                             'strata',wear=.22,coll='Cobertura')
            roof.rotation_euler.y=.16 if x>0 else -.15
    else:
        for i,x in enumerate((-5.30,-1.74)):
            stage.pillar(x,3.67,0,3.42-.17*i,1.20,i==1)
        stage.block('Verga sobre o sino',(-3.37,3.67,4.21),(5.19,1.07,.58),'wood',wear=.14,rot=-.10)
        stage.shaft('Elo comprido do sino',(-3.37,3.67,4.08),(-3.37,3.67,3.28),.088,.085,'lead','Objetos')
        stage.lathe('Sino com a borda aberta',(-3.37,3.67,1.86),
                    [(.98,0),(.79,.27),(.58,.66),(.27,1.24),(.21,1.45),
                     (.12,1.45),(.18,1.22),(.45,.65),(.67,.26),(.83,0)],
                    'bronze','Objetos',44,(4.46,.63),(.12,-.14,.32))
        stage.block('Altar baixo ao lado do sino',(3.46,4.76,.52),(2.43,1.93,1.05),
                    'lime',taper=.76,wear=.10)
    stage.light('Luz rasante do marco lateral','AREA',(2.35,-1.30,4.8),(-3.35,3.42,1.97),
                (970,1150,915,790,1080)[kind],(.84,.78,.69),5.0)


def walls(stage,grid,start):
    south=min(y for x,y in grid if x==start[0] and y<=start[1])
    for i,(face,axis,a,b) in enumerate(boundary(grid)):
        if face==2 and axis==south and a<=start[0]<=b:
            spans=[(a,start[0]-1),(start[0]+1,b)]
        else:
            spans=[(a,b)]
        for first,last in spans:
            if first>last:
                continue
            where=(first+last)*CELL/2
            width=(last-first+1)*CELL+.18
            height=4.44+.94*math.sin(i*1.64)+.48*math.sin(i*.27)
            if face<2:
                loc=(axis*CELL+(-2.21 if face==0 else 2.21),where,height*.45)
                size=(1.12,width,height)
            else:
                loc=(where,axis*CELL+(-2.21 if face==2 else 2.21),height*.45)
                size=(width,1.12,height)
            stage.block('Parede funerária do perímetro',loc,size,'strata',
                        wear=.10,taper=.915,coll='Paredes')


def entrance_direction(room,centers,rooms,halls):
    here=centers[room]
    gates=sorted(n for pair,tiles in halls.items() if room in pair for n in tiles
                 if any(p in rooms[room] for p in adjacent(n)))
    entry=min(gates,key=lambda n:(abs(n[0]-here[0])+abs(n[1]-here[1]),n))
    rx,ry=here[0]-entry[0],here[1]-entry[1]
    if abs(rx)>abs(ry):
        return (1 if rx>0 else -1,0)
    return (0,1 if ry>0 else -1)


def main():
    snapshot=ROOT/'mcp_refinamento_2.blend'
    title=TITLE+' · revisão'
    assert not snapshot.exists() and bpy.data.scenes.get(title) is None
    centers,rooms,halls=design()
    grid=set().union(*rooms.values(),*halls.values())
    shortest,_=path_between(grid,centers['I-B'],centers['V-K'])
    assert all(not rooms[r]&set(shortest) for r,_ in SIDE_ROOMS)
    old=bpy.context.window.scene
    mats=library()
    mats['deep']=material('Rocha da cavidade',('221D18','514536','756751'),.96,0,.13,.16)
    mats['track']=material('Chão da passagem',('3D3328','71614C','9F8D73'),.94,0,.10,.16)
    mats['paving']=material('Lajes integradas à trilha',('352B23','594E40','826F55'),.96,0,.10,.13)
    mats['dust']=material('Poeira entre as lajes',('4C4134','77674F','A58D6A'),.97,0,.06,.12)
    stage=Stage('R55',title,873,mats)
    scene=stage.scene
    for k in ('Pisos','Paredes','Cobertura'):
        coll=bpy.data.collections.new('R55 · '+k)
        scene.collection.children.link(coll)
        stage.collections[k]=coll
    volume=next(iter(stage.collections['Atmosfera'].objects))
    volume.location=(58,325,9)
    volume.scale=(2.7,5.5,.91)
    next(n for n in volume.active_material.node_tree.nodes if n.type=='VOLUME_SCATTER').inputs['Density'].default_value=.006
    sun=next(o for o in stage.collections['Luzes'].objects if o.data.type=='SUN')
    sun.data.energy=1.44
    sun.data.color=(1.0,.88,.77)
    for i,zone in enumerate(ZONES):
        side_room,caption=SIDE_ROOMS[i]
        for r in zone.rooms:
            name=zone.roman+'-'+r
            cx,cy=centers[name]
            floor(stage,name+' · sala',rooms[name],('sand','track','lime','track','sand')[i],(cx,cy))
            if name==side_room:
                vector=entrance_direction(name,centers,rooms,halls)
                placed(stage,cx*CELL,cy*CELL,vector,lambda:lateral(stage,i))
            else:
                landmark(stage,i,zone,r,cx*CELL,cy*CELL)
        x,y=centers[zone.roman+'-'+zone.focus]
        cam=stage.camera(f'{2*i+1:02d} · {zone.roman} · {zone.title}',(x*CELL,y*CELL-(10.2 if i==0 else 7.15),EYE),
                         (x*CELL,y*CELL+5.8,EYE),player=True)
        cam.data.clip_end=70
        if i==0:
            scene.camera=cam
        x,y=centers[side_room]
        dx,dy=entrance_direction(side_room,centers,rooms,halls)
        cam=stage.camera(f'{2*i+2:02d} · {side_room} · {caption}',
                         (x*CELL-dx*5.82,y*CELL-dy*5.82,EYE),(x*CELL+dx*3.8,y*CELL+dy*3.8,EYE),
                         player=True)
        cam.data.clip_end=58
    for (a,b),cells in halls.items():
        floor(stage,'Passagem '+a+' / '+b,cells,'track')
    walls(stage,grid,centers['I-B'])
    x=(min(x for x,y in grid)+max(x for x,y in grid))*CELL*.5
    y=(min(y for x,y in grid)+max(y for x,y in grid))*CELL*.5
    top=stage.camera('11 · Planta 3D',(x,y,680),(x,y,0),ortho=730)
    top.rotation_euler.z=math.pi/2
    top.data.clip_end=1250
    for k,v in metrics().items():
        scene[k]=v
    scene.use_fake_user=True
    for file in ('planta.py','modelar.py'):
        src=bpy.data.texts.new('D01 · R55 · Revisão · '+file)
        src.write((ROOT/file).read_text(encoding='utf-8'))
        src.use_fake_user=True
    bpy.context.window.scene=scene
    try:
        bpy.ops.wm.save_as_mainfile(filepath=str(snapshot),copy=True,compress=True)
    finally:
        bpy.context.window.scene=old
    assert snapshot.exists()
    print(scene.name,len(scene.objects),metrics())


if __name__=='__main__':
    main()
