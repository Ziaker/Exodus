"""Bloco contínuo das cinco zonas. O detalhamento da Ruptura fica nos .blend próprios."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from construir import EYE, Stage, library, material
sys.path.insert(0,str(ROOT))
from mapa import CELL, ZONES, audit_layout, layout, main_route

TITLE='D01 · Necrópole Saturnina · Percurso'


def terrain(stage,zones):
    scene=stage.scene
    for i,cells in enumerate(zones):
        verts=[]
        faces=[]
        for x,y in sorted(cells):
            index=len(verts)
            verts.extend(((x*CELL-2,y*CELL-2,0),(x*CELL+2,y*CELL-2,0),
                          (x*CELL+2,y*CELL+2,0),(x*CELL-2,y*CELL+2,0)))
            faces.append(tuple(range(index,index+4)))
        stage.mesh(f'Zona {ZONES[i][0]} · Piso caminhável',verts,faces,
                   ('sand','sand','lime','strata','sand')[i],'Geologia')
    all_cells=set().union(*zones)
    for x,y in sorted(all_cells):
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            if (x+dx,y+dy) in all_cells or (x,y,dx,dy)==(0,0,0,-1):
                continue
            # O perímetro contínuo deixa explícitas as entradas e as desconexões da malha.
            z=1.38 if y>=7 else .75
            variation=.48*math.sin((x*7+y*3+dx*2+dy)*.67)
            stage.block('Limite leste/oeste' if dx else 'Limite norte/sul',
                        (x*CELL+dx*2.10,y*CELL+dy*2.10,z*.44),
                        ((.95,3.98,z+variation) if dx else (3.98,.95,z+variation)),
                        'strata',taper=.91,wear=.062)
    for x,y in main_route():
        for k in range(3):
            offset=-.57+k*.57+.06*math.sin(y)
            stage.block('Laje do percurso',(x*CELL+offset,y*CELL,.008),
                        (.51,3.29+.34*math.sin(y+k),.12),'route',
                        wear=.056,rot=.029*math.sin(y*.7+k))


def gate(s):
    for side in (-1,1):
        s.block('Ombreira funerária',(side*3.1,20,3.15),(2.2,3.4,6.4),'lime',taper=.88,wear=.13)
        s.block('Costado escavado',(side*6.4,19.6,2.8),(4.38,5.75,5.7),'strata',taper=.85,wear=.24)
    s.block('Limiar superior sem a ponta',(0,19.85,6.29),(8.55,3.1,1.12),'deep',taper=.91,wear=.22)
    # Peças de leitura no blockout. As versões detalhadas ficam no exterior e no interior da Ruptura.
    support=s.block('Base suspensa da Ruptura',(-2.9,14.75,7.95),(13.77,3.66,2.04),
                    'strata',wear=.36,rot=-.14)
    support.rotation_euler.y=-.115
    for i,(x,h) in enumerate(((-7.4,2.5),(-4.15,3.03),(-.71,2.24),(2.55,1.93))):
        lintel=s.block('Portal voltado para baixo',(x,13.47,7.00-h),(2.52,.95,.56),'lime',wear=.11)
        lintel.rotation_euler.y=-.115
        for side in (-1,1):
            beam=s.block('Coluna do portal invertido',(x+side*1.01,13.5,7-h/2),
                         (.48,1.11,h),'lime',wear=.053,taper=.92)
            beam.rotation_euler.y=-.115
    for i in range(8):
        step=s.block('Degrau rompido sobre a fenda',(-11.4+.74*i,8.8+.46*i,.27+.50*i),
                     (1.72,.63,.48),'deep',wear=.068,rot=-.94)
        step.rotation_euler.y=-.12
    for j,(x,y,w,d,h) in enumerate(((-14,17,14,13,15),(15,16,15,18,17),(-17,26,17,20,19),
        (17,29,14,16,15))):
        s.cliff('Contraforte da entrada',(x,y,-1),w,d,h,63+j*9,asym=(-1)**j*.19)


def sarcophagus(s,x,y,length,open_lid):
    s.block('Base sob o sarcófago',(x,y,.17),(1.9,length,.37),'strata',wear=.031)
    s.block('Leito do sarcófago',(x,y,.39),(1.65,length-.18,.32),'deep',wear=.049)
    for side in (-1,1):
        s.block('Lateral do sarcófago',(x+side*.70,y,.66),(.28,length-.26,.42),'lime',wear=.052)
        s.block('Fecho menor do sarcófago',(x,y+side*(length-.51)*.5,.66),
                (1.30,.31,.45),'lime',wear=.044)
    if not open_lid:
        s.block('Tampa maciça',(x,y,.98),(1.74,length-.12,.22),'lime',taper=.84,wear=.05)


def vault(stage, name, y, depth, seed):
    """Segmento de abóbada com intradorso visível e emendas no comprimento."""
    steps=16
    verts=[]
    for edge in (-1,1):
        for radius in (5.84,6.72):
            for i in range(steps+1):
                a=.10+(math.pi-.20)*i/steps
                irregularity=.21*math.sin(i*2.03+seed+edge)
                verts.append((math.cos(a)*(radius+irregularity),
                              y+edge*depth*.5+.13*math.sin(i*.37+seed),
                              2.43+math.sin(a)*(radius+irregularity)*.76))
    n=steps+1
    faces=[]
    for i in range(steps):
        k=i+1
        faces.extend(((i,k,k+2*n,i+2*n),(i+n,i+3*n,k+3*n,k+n),
                      (i,i+n,k+n,k),(i+2*n,k+2*n,k+3*n,i+3*n)))
    faces.extend(((0,2*n,3*n,n),(steps,steps+n,steps+3*n,steps+2*n)))
    stage.mesh(name,verts,faces,'deep','Arquitetura',.048)


def avenue(s):
    for y in (34,45.6,51.48,58.27,64.5,74.65):
        for side in (-1,1):
            x=side*(8.28+.41*math.sin(y*.32))
            s.tomb(x,y,0,3.89,4.08,4.52+.59*math.sin(y))
            incline=.11*side*math.cos(y)
            stele=s.block('Estela inclinada',(x-side*2.55,y-1.17,1.02),
                          (.7,.5,2.53),'deep',taper=.79,wear=.12)
            stele.rotation_euler.y=incline
    for y in (44.82,56.86,64.75):
        s.block('Entablamento funerário interrompido',(-6.8,y,5.15),(5.11,1.37,.63),
                'deep',wear=.09,rot=.12)
    for j,y in enumerate((40.4,47,53.6,60.1,66.9)):
        vault(s,'Trecho conservado da avenida' if j!=3 else 'Arco isolado na fenda da abóbada',
              y,5.45 if j!=3 else 1.57,81+j*11)
        for side in (-1,1):
            s.block('Sustentação da abóbada',(side*6.15,y,1.28),(1.55,2.43,2.57),
                    'strata',taper=.92,wear=.07)
    sarcophagus(s,4.18,50.51,3.66,True)
    sarcophagus(s,-4.1,59.12,3.45,False)
    sarcophagus(s,-18,50.2,2.75,True)
    sarcophagus(s,19.0,58.6,2.82,False)
    for y in (44,62):
        s.light('Luz rasante na avenida','AREA',(3.8,y-4.5,4.1),(0,y+3,1.5),575,(.89,.74,.58),5)


def cloister(s):
    for side in (-1,1):
        for j,y in enumerate((88.17,94.2,101.5,107.07)):
            h=(5.7,5.5,4.87,3.3)[j]
            s.pillar(side*(13.3-.62*math.sin(y)),y,0,h,1.3,j==3)
            if j<2:
                s.block('Travessa de oficina',(side*13.3,y+2.80,6.73),
                        (1.82,7.15,.57),'strata',wear=.12)
    s.polyhedron((-8.75,98.8,2.5),3.35)
    s.statue(7.3,102.7,.13,1.62,True)
    s.block('Bancada de talhe',(6.26,98.85,.79),(3.25,1.15,.29),'wood',wear=.11)
    for x in (5.28,7.25):
        s.block('Pé da bancada',(x,98.85,.38),(.35,.61,.73),'wood',wear=.066)
    s.shaft('Ferramenta largada',(5.29,98.53,1.01),(6.47,98.85,1.0),.075,.038,'lead','Objetos')
    s.stair(103.3,0,4.65,.42,.86,9,-8.51,'Escada sem chegada da oficina')
    s.block('Viga que perdeu o apoio',(-9.24,111.6,5.87),(6.23,1.57,.81),'deep',wear=.23)
    for i,x in enumerate((-10,-4,2.4,7.9)):
        s.block('Parede cega por trás das oficinas',(x,113.29,3.28),(6.12,2.2,6.57),
                'deep',taper=.86,wear=.18,rot=.03*math.sin(i))
    s.light('Iluminação lateral das oficinas','AREA',(-18,90,11),(0,104,3),2800,(.89,.80,.65),16)


def ossuary(s):
    x=16.
    for side in (-1,1):
        for j,y in enumerate((135,141,147,154.1)):
            s.tomb(x+side*(8.23+j%2*1.81),y,0,3.71,2.88,3.62+j%3*.61)
    for i in range(14):
        t=math.tau*i/16
        if i in (4,12):
            continue
        px=x+12.3*math.cos(t)
        py=144+12.3*math.sin(t)
        s.pillar(px,py,0,4.42+.59*math.sin(i),.90,i%4==0)
    s.ring('Meridiano suspenso sobre a passagem',(x,149,6.88),5.85,.55,.58,'lime',
           broken=(.54,1.21),tilt=(1.53,.18,-.18))
    s.ring('Círculo incompleto menor',(x,149.7,7.32),4.37,.29,.29,'bronze',
           broken=(1.55,1.66),tilt=(1.61,-.36,.31))
    for side in (-1,1):
        s.block('Apoio do meridiano',(x+side*4.86,149.23,2.21),(1.95,2.89,4.39),
                'strata',taper=.78,wear=.13)
        for i,y in enumerate((140.82,148.71,156.35)):
            slab=s.block('Abóbada em torno da abertura do ossuário',(x+side*(9.1+i*.46),y,8.05+i*.13),
                         (7.63,7.67,1.13),'deep',taper=.95,wear=.26,rot=side*.08*(i-1))
            slab.rotation_euler.y=side*.16
    s.ring('Marcas orbitais no percurso',(x,143.9,.031),10.26,.18,.037,'lead',
           broken=(1.22,.31),tilt=(0,0,0))
    s.light('O céu pela abertura do teto','AREA',(12,151,13),(16,140,3),3850,(1,.59,.40),12)


def sepulchre(s):
    x=16.
    for j,(px,py,h) in enumerate(((-11,185,7.6),(11.9,187,8.45),(-15.5,195,7.18),(15.8,198,9.37),
        (-10.5,204.78,9.42),(10.4,206,9.10),(-6.8,211,8.01),(6.8,210,7.8))):
        s.pillar(x+px,py,0,h,2.12,j%3==0)
    s.block('Plataforma ampla de fundo',(x,202.3,.27),(14.61,4.82,.54),'strata',taper=.95,wear=.12)
    s.block('Altar isolado',(x,204,1.06),(4.88,2.55,1.42),'lime',taper=.86,wear=.055)
    s.ring('Abertura orbital do santuário',(x,209,7.52),9.18,.94,1.13,'deep',
           broken=(.31,.77),tilt=(1.57,.12,-.13))
    s.ring('Vestígio interno do santuário',(x,209.7,7.52),6.63,.29,.34,'bronze',
           broken=(1.19,1.02),tilt=(1.57,-.17,.21))
    for side in (-1,1):
        s.lathe('Sino rachado no santuário',(x+side*9.47,204.60,6.48),
                [(.82,0),(.69,.14),(.54,.46),(.26,1.0),(.20,1.23),(.13,1.25),
                 (.15,.98),(.44,.39),(.73,0)],'bronze','Objetos',40,(4.68,.32))
    for j,(px,y,h) in enumerate(((-24,218,19),(21,224,32),(-13,240,27),(29,239,30))):
        s.cliff('Perfil distante do santuário',(x+px,y,-.4),19.8,19.4,h,123+j*8,
                asym=.22*(-1)**j,strata=.14,erosion=.31)
    s.light('Reflexo sobre altar e montanhas','AREA',(28,192,14),(14,209,4.8),4650,(.84,.74,.62),18)


def build():
    file=ROOT/'mcp_percurso_refinado.blend'
    assert not file.exists(), file
    title=TITLE+' · revisão'
    assert bpy.data.scenes.get(title) is None
    zones=layout()
    metrics=audit_layout(zones)
    old=bpy.context.window.scene
    mats=library()
    mats['route']=material('Laje do caminho principal',('423728','8A7651','B6A173'),.94,0,.09,.18)
    mats['deep']=material('Fratura da Necrópole',('241E16','5C4A30','806B4E'),.94,0,.14,.17)
    stage=Stage('P',title,741,mats)
    scene=stage.scene
    for volume in stage.collections['Atmosfera'].objects:
        volume.location.y=108
        volume.scale.y=2.9
        scatter=next(n for n in volume.active_material.node_tree.nodes if n.type=='VOLUME_SCATTER')
        scatter.inputs['Density'].default_value=.008
    terrain(stage,zones)
    gate(stage)
    avenue(stage)
    cloister(stage)
    ossuary(stage)
    sepulchre(stage)
    for i,(roman,name,_,__,(x,y)) in enumerate(ZONES):
        px,py=x*CELL,y*CELL
        cam=stage.camera(f'{i+1:02d} · {roman} · {name}',(px,py,EYE),(px,py+6,EYE),player=True)
        if i==0:
            scene.camera=cam
    top=stage.camera('06 · Planta das cinco zonas',(8,108,170),(8,108,0),ortho=243)
    top.rotation_euler.z=math.pi/2
    top.data.clip_end=320
    for key,value in metrics.items():
        scene[key]=value
    scene['status']='Maquete de circulação · caminho principal atravessa a Ruptura'
    for name in ('mapa.py','modelar.py'):
        source=bpy.data.texts.new('D01 · Percurso · Revisão · '+name)
        source.write((ROOT/name).read_text(encoding='utf-8'))
        source.use_fake_user=True
    scene.use_fake_user=True
    bpy.context.window.scene=scene
    try:
        bpy.ops.wm.save_as_mainfile(filepath=str(file),copy=True,compress=True)
    finally:
        bpy.context.window.scene=old
    assert file.exists()
    print(scene.name,len(scene.objects),metrics)


if __name__=='__main__':
    build()
