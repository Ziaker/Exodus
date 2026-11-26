"""Maquete da câmara atrás do pórtico da Ruptura."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector
from mathutils.noise import noise

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
from modelar import Stage, EYE, library, material, fracture, transformed, edges

SCENE = 'D01 · Ruptura · Interior'
ENTRY = Vector((edges(17.0)[1] + 2.35, 17.7, 0))
EXTERIOR = ROOT.parent / 'Necropole_Saturnina_Ruptura.blend'


def enclosure(s):
    roof = bpy.data.collections.new('Interior · Teto removível para inspeção')
    s.scene.collection.children.link(roof)
    for side in (-1,1):
        fracture(s,'Parede do vestíbulo',(side*2.86,3.25,0),
            [(-3.8,-.5),(3.75,-.5),(3.63,5.5),(1.9,5.88),(-.8,5.32),(-3.44,5.61)],
            2.02,'strata',(.33,.10)).rotation_euler.z=side*math.pi/2
        for i,(y,z,w) in enumerate(((9.2,8.1,3.45),(13.3,10.4,5.19),
            (18.35,11.24,5.99),(24.4,10.8,6.57),(29.0,8.62,5.0))):
            x=side*(7.53+.57*math.sin(i*.76))
            face=fracture(s,'Parede escavada em veios',(x,y,0),
                [(-w*.63,-3),(w*.60,-2.7),(w*.52,z*.64),(w*.39,z),(w*.11,z+.68),
                 (-w*.29,z-.43),(-w*.58,z+.21)],3.92,'strata',
                 (.44*side,.79),coll='Geologia')
            face.rotation_euler.z=side*(math.pi/2+.085*math.sin(i))
    for x,w,z in ((-6.70,4.61,9.18),(-2.34,5.3,11.36),(2.73,5.39,11.07),(7.45,4.8,9.45)):
        fracture(s,'Parede final cega',(x,31.1,-.38),
            [(-w*.61,-1.8),(w*.58,-1.8),(w*.54,z*.84),(w*.27,z),
             (-w*.14,z+.53),(-w*.50,z*.76)],4.02,'deep',(.46,.61),coll='Geologia')
    slabs=(
        ('Cobertura baixa do pórtico',(0,2.4,5.55),[(-4,-.55),(3.9,-.36),(4,.60),(.32,1.21),(-3.65,.92)],8.65),
        ('Abóbada longa oeste',(-4.2,18.8,9.85),[(-5.4,-.51),(2.7,-.32),(3.63,.49),(2.81,1.48),
                                                (-2.45,1.75),(-5.60,.67)],25.57),
        ('Abóbada longa leste',(5.76,18.9,9.63),[(-3.36,-.14),(4.65,-.42),(4.62,1.28),(.72,2.23),
                                                (-2.52,1.28)],25.55),
        ('Trecho colapsado da abóbada',(.42,9.2,10.02),[(-3.21,-.78),(3.36,-.25),(3.50,.83),(-2.06,1.21)],6.74),
        ('Fecho superior da câmara',(.73,28.5,10.44),[(-5.09,-.52),(5.17,-.09),(4.73,1.34),(-4.8,1.16)],5.8),
    )
    for name,loc,profile,thickness in slabs:
        obj=fracture(s,name,loc,profile,thickness,'strata',(.22,.38),coll='Geologia')
        roof.objects.link(obj)
        s.collections['Geologia'].objects.unlink(obj)


def floor_patch(s,name,xs,ys,level,mat,void_side=None):
    verts=[]
    for j,y in enumerate(ys):
        for i,x in enumerate(xs):
            if void_side and i==len(xs)-1:
                x = void_side(y)
            z=level+.041*noise(Vector((x*.36,y*.39,3)))+.017*math.sin(y*.8+i)
            verts.append((x,y,z))
    n=len(xs)
    faces=[(j*n+i,j*n+i+1,(j+1)*n+i+1,(j+1)*n+i)
           for j in range(len(ys)-1) for i in range(n-1)]
    s.mesh(name,verts,faces,mat,'Geologia',smooth=True)


def floor_and_channel(s):
    rows=[-1+i*.45 for i in range(74)]
    floor_patch(s,'Piso contínuo da passagem',[-3.28,-2.2,-1.1,0,1.25,2.7,4,5.65,7.8],
                rows,0,'sand')
    pit_edge=lambda y:-5.3+.41*math.sin(y*.73)+.29*math.sin(y*1.30)
    floor_patch(s,'Piso recuado além da abertura',[-9,-8.3,-7.15,-6.4,-5.5],
                rows,.052,'strata',pit_edge)
    floor_patch(s,'Leito sob as fundações',[-6,-5.5,-5,-4.45,-3.9,-3.12],rows,-3.8,'dark')
    for x,sign in ((-3.27,1),(-5.28,-1)):
        for i in range(12):
            y=2.4+i*2.43
            edge=x+.18*math.sin(i*1.69)
            fracture(s,'Face quebrada do corte',(edge,y,-1.72),
                [(-1.55,-2.0),(1.55,-2.08),(1.41,1.48),(.58,1.78),(-.67,1.66),(-1.52,1.43)],
                .84,'deep',(-.33,.17),coll='Geologia').rotation_euler.z=sign*math.pi/2
    for i in range(24):
        y=.90+i*1.18
        bend=.69*math.sin(y*.13)
        span=range(-2,3) if i>6 else range(-1,2)
        for j in span:
            edge=abs(j)>1
            if edge and (int(y)+j*2)%5 in (0,1):
                continue
            x=bend+j*1.26
            s.block('Laje côncava da via',(x+.06*math.sin(i+j),y,.014),
                    (1.12 if not edge else .98,1.08,.11),'tile',
                    wear=.04,rot=s.random.uniform(-.095,.095))
    for i in range(4):
        y=11.4+i*.63
        s.block('Borda recolhida junto ao corte',(-2.90,y,.08),
                (.53,.54,.19),'bone',wear=.044,rot=.067*math.sin(i))
    for i,(x,y,r) in enumerate(((-2.35,6.9,.22),(2.37,8.6,.24),(-2.8,10.26,.43),(3.20,13.7,.27),
        (3.78,16.26,.68),(-3.02,19.7,.47),(3.82,23.4,.57),(6.15,19.1,.65),(-5.58,23.9,.48),
        (-3.05,26.4,.52),(2.8,27.35,.38))):
        s.block('Escombro ao lado da via',(x,y,r*.08),(r,r*.77,r*.5),'deep',
                wear=.08,rot=i*1.61,coll='Geologia')


def rock_ribs(s):
    # Ombreiras talhadas, com juntas grandes e poucos relevos distintos.
    for i,y in enumerate((5.5,10.25,15.9,22.6)):
        width=2.99 if i==0 else 6.65-.27*i
        height=5.45 if i==0 else 8.18+.43*math.sin(i)
        for side in (-1,1):
            x=side*width+.34*(i>1)
            if i==2 and side<0:
                continue
            points=[(-.70,-1.18),(.73,-.91),(.76,height*.60),(.57,height),
                    (-.13,height+.36),(-.64,height*.86),(-.79,height*.43)]
            pier=fracture(s,'Nervura fundida à parede',(x,y,0),points,2.28,'lime',(.19,.19))
            pier.rotation_euler.y=.104*side
            s.block('Sapata gasta',(x,y,.25),(1.77,2.52,.52),'deep',taper=.91,wear=.11)
            s.block('Corte que interrompe o friso',(x,y-1.13,height*.51),(1.04,.12,.22),
                    'dark',wear=.027,rot=.06*(side+i))
        if i in (0,1,3):
            z=height+(.10 if i==0 else -.2)
            contour=[(-width-.9,-.49),(-width+.5,-.68),(-width*.48,.05),(-.24,.29),
                     (width*.52,.14),(width+.78,-.37),(width+1.05,.72),
                     (width*.37,1.39),(-width*.51,1.39),(-width-1.02,.67)]
            fracture(s,'Cinta de pedra abatida',(0,y,z),contour,2.47,'deep',(.32,.20))


def wrong_gravity(s):
    def sideways_gallery():
        fracture(s,'Piso lateral de túmulos',(0,1.8,-.32),
                 [(-3.58,-.89),(3.47,-.89),(3.38,-.21),(1.32,.27),(-3.19,.04)],
                 10.95,'deep',(.16,.32))
        for j,(x,y,h) in enumerate(((-1.9,-1.24,4.96),(.91,2.32,4.24),(-1.13,5.59,3.68))):
            for side in (-1,1):
                fracture(s,'Pilar preso à laje lateral',(x+side*1.17,y,0),
                    [(-.51,-.16),(.52,-.18),(.47,h*.63),(.29,h*.96),(-.18,h),(-.49,h*.89)],
                    2.68,'lime',(.12*side,.10))
                s.block('Base do túmulo lateral',(x+side*1.24,y-.2,.24),
                        (1.17,2.92,.46),'deep',wear=.08)
            fracture(s,'Verga quebrada de túmulo lateral',(x,y,h-.33),
                     [(-1.67,-.29),(1.68,-.14),(1.73,.33),(.66,.78),(-1.17,.5)],
                     3.01,'strata',(-.11,.09))
            s.block('Fundo estreito do túmulo',(x,y+1.07,h*.41),(1.91,.35,h*.69),'dark')
            s.block('Laje deixada junto ao umbral',(x+.37,y-1.95,.36),(2.26,1.5,.38),
                    'tile',wear=.075,rot=.065*(j-1))
    transformed(s,'Galeria da parede esquerda',(-6.14,18.46,5.69),
                (.05,math.pi*.49,-.055),sideways_gallery)

    def inverted_steps():
        for i in range(10):
            tread=s.block('Degrau sem encontro',(0,i*.73,i*.29),
                         (2.22-.08*i,.74,.31),'lime' if i%4 else 'deep',
                         wear=.073,rot=.038*math.sin(i*.6))
            tread.rotation_euler.x=.068*math.sin(i)
        fracture(s,'Nervura arrancada do lance',(-1.32,3.0,.46),
                 [(-.27,-.42),(.17,-.46),(.28,.35),(-.12,.54)],6.1,'deep').rotation_euler.x=.31
    transformed(s,'Escada com o teto por piso',(2.61,25.86,8.26),
                (.02,math.pi,2.32),inverted_steps)

    def inverted_tomb():
        s.tomb(0,0,0,4.55,2.75,3.88)
        fracture(s,'Rocha que sustenta o piso invertido',(0,1.2,-.62),
            [(-2.92,-1.02),(-1.31,-1.19),(.25,-1.56),(2.77,-.81),(2.3,.26),
             (.38,.25),(-2.54,.26)],3.73,'strata',(.18,.17))
        s.block('Dente que restou do relevo',(1.11,-1.51,.81),
                (.47,.25,1.23),'bone',wear=.078)
    transformed(s,'Sepulcro voltado para o teto',(2.56,27.25,9.82),
                (-.10,math.pi+.16,-.20),inverted_tomb)

    # O altar de chão e a estátua a meio talhe deixam o centro da sala disponível aos sprites.
    s.block('Patamar do sepulcro',(1.74,27.64,.25),(7.37,4.91,.50),'deep',taper=.97,wear=.12)
    s.block('Ombreira partida do sepulcro',(-.82,29.85,2.35),(1.16,1.71,4.47),'lime',taper=.61,wear=.15)
    s.block('Ombreira soterrada do sepulcro',(4.27,29.77,2.45),(1.68,1.68,4.92),'lime',taper=.66,wear=.13)
    s.block('Lintel com seção faltante',(2.04,29.8,4.91),(5.84,1.69,.89),'strata',taper=.76,wear=.19)
    s.block('Placa selada com a face para dentro',(1.82,30.02,2.23),(3.36,.66,4.08),'dark',taper=.90,wear=.11)
    s.statue(5.23,24.15,.06,1.12,True)
    s.block('Bancada junto à estátua',(5.2,21.26,.69),(2.4,.83,.28),'wood',wear=.065,coll='Objetos')
    for x in (4.40,6.0):
        s.block('Pé da bancada',(x,21.26,.32),(.31,.42,.66),'wood',coll='Objetos')
    s.shaft('Cinzel abandonado',(4.39,21.04,.86),(5.23,21.19,.87),.067,.029,'lead','Objetos')


def lights(s):
    for obj in tuple(s.collections['Luzes'].objects):
        bpy.data.objects.remove(obj,do_unlink=True)
    sky=next(n for n in s.scene.world.node_tree.nodes if n.type=='BACKGROUND')
    sky.inputs['Strength'].default_value=.145
    volume=next(obj for obj in s.collections['Atmosfera'].objects)
    volume.location=(0,15.0,4.1)
    volume.scale=(.24,.31,.68)
    fog=next(n for n in volume.active_material.node_tree.nodes if n.type=='VOLUME_SCATTER')
    fog.inputs['Density'].default_value=.013
    s.light('Última luz do pórtico','AREA',(0,-1.42,3.8),(0,8.9,1.1),550,(.82,.45,.26),4.0)
    s.light('Luz rubra pela fratura da abóbada','AREA',(.10,19.1,10.95),(-2.51,15.3,-.31),
            1650,(1.0,.31,.22),5.3)
    s.light('Reflexo mineral do corredor','AREA',(4.79,11.75,4.9),(-4.42,18.55,4.2),
            720,(.81,.78,.68),5.25)
    s.light('Luz mate de fundo','AREA',(-2.78,26.4,6.72),(2.72,29.15,2.04),780,(.84,.77,.65),4.2)
    s.light('Reflexo baixo na escadaria','AREA',(1.8,19.9,1.56),(1.43,22.0,7.77),630,(.87,.79,.67),5.5)
    s.light('Sulco da passagem','AREA',(-3.92,16.3,-2.75),(-3.1,11.7,1.1),120,(.79,.31,.15),3.2)


def matching_gate(scene):
    with bpy.data.libraries.load(str(EXTERIOR),link=False) as (source, target):
        target.objects=[name for name in source.objects
                        if name.startswith(('Ombreira descalçada','Lintel sem metade'))]
    assert len(target.objects)==3
    collection=bpy.data.collections.new('Pórtico · mesmas três peças da Ruptura')
    scene.collection.children.link(collection)
    for obj in target.objects:
        collection.objects.link(obj)


def build():
    output=ROOT/'mcp_interior_refinado.blend'
    assert not output.exists()
    window=bpy.context.window
    previous=window.scene
    scene_name=SCENE+' · revisão'
    assert bpy.data.scenes.get(scene_name) is None
    mats=library()
    mats['deep']=material('Rocha cortada em sombra',('211B16','504338','806945'),.94,0,.08,.20)
    mats['tile']=material('Piso funerário apisoado',('43382C','786646','A89B75'),.94,0,.075,.18)
    s=Stage('I',scene_name,611,mats)
    scene=s.scene
    scene.view_settings.exposure=.24
    enclosure(s)
    floor_and_channel(s)
    rock_ribs(s)
    wrong_gravity(s)
    lights(s)
    scene.camera=s.camera('01 · Câmara',(0.91,11.15,EYE),(.41,25,EYE),player=True)
    s.camera('02 · Limiar',(.17,2.18,EYE),(.68,23,EYE),player=True)
    s.camera('03 · Sepulcro',(2.96,18.8,EYE),(2.26,29.5,EYE),player=True)
    s.camera('04 · Gravidades trocadas',(2.95,15.80,2.86),(-.77,23.5,5.99),23)
    s.camera('05 · Planta',(.1,15.25,56.5),(.1,15.25,0),ortho=55)
    s.camera('06 · Geometria',(27,-13,31),(0,15.4,3.2),ortho=48)
    for obj in scene.objects:
        obj.location+=ENTRY
    source=bpy.data.texts.new('D01 · Interior · Revisão da modelagem')
    source.write(Path(__file__).read_text(encoding='utf-8'))
    source.use_fake_user=True
    scene.use_fake_user=True
    scene['entrada_exterior']=tuple(ENTRY)
    matching_gate(scene)
    window.scene=scene
    try:
        bpy.ops.wm.save_as_mainfile(filepath=str(output),copy=True,compress=True)
    finally:
        window.scene=previous
    assert output.is_file()
    print(scene.name,len(scene.objects),tuple(round(v,4) for v in ENTRY),output)


if __name__=='__main__':
    build()
