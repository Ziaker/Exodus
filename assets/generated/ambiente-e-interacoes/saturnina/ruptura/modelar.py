"""Estudo da Necrópole com o terreno e a arquitetura em orientações distintas."""
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Euler, Vector
from mathutils.noise import noise

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
from construir import CELL, EYE, Stage, color, library, material

SCENE = 'D01 · Necrópole Saturnina · Ruptura'


def edges(y):
    middle = -2.3 + 2.50 * math.sin((y - 2) * .093) + .048 * y
    half = 3.20 + .66 * math.sin(y * .39) + .46 * math.sin(y * 1.18)
    return middle - half, middle + half


def rock(stage, name, origin, layers, seed, mat='strata'):
    """Um maciço com anéis deslocados e cicatrizes contínuas entre as faces."""
    rng = random.Random(seed)
    count = 18
    ribs = [rng.uniform(.65, 1.20) for _ in range(count)]
    verts = []
    for level, (z, cx, cy, rx, ry) in enumerate(layers):
        for i, rib in enumerate(ribs):
            a = math.tau * i / count
            irregularity = rib * (1 + .13 * math.sin(level * .87 + i))
            verts.append((cx + math.cos(a) * rx * irregularity, cy + math.sin(a) * ry * irregularity,
                          z + .32 * math.sin(i * .8 + level * .68)))
    faces = [tuple(reversed(range(count))), tuple(range(len(verts)-count,len(verts)))]
    for j in range(len(layers)-1):
        for i in range(count):
            a,b=j*count+i,j*count+(i+1)%count
            faces.extend(((a,b,b+count),(a,b+count,a+count)))
    obj = stage.mesh(name, verts, faces, mat, 'Geologia')
    obj.location = origin
    obj['semente'] = seed
    return obj


def fracture(stage, name, location, contour, thickness, mat, lean=(0,0), coll='Arquitetura'):
    """Extrusão fechada de uma silhueta desenhada, com lâmina posterior irregular."""
    n = len(contour)
    verts = [(x,-thickness*.5,z) for x,z in contour]
    verts += [(x+lean[0],thickness*.5+math.sin(i*1.9)*thickness*.13,z+lean[1])
              for i,(x,z) in enumerate(contour)]
    faces = [tuple(range(n)), tuple(reversed(range(n,n*2)))]
    faces.extend((i,i+n,(i+1)%n+n,(i+1)%n) for i in range(n))
    obj = stage.mesh(name,verts,faces,mat,coll,.042)
    obj.location = location
    return obj


def transformed(stage, label, loc, rotation, factory):
    """Transforma uma unidade arquitetônica em conjunto, preservando seus encaixes."""
    before = {obj for obj in stage.scene.objects}
    factory()
    matrix = Euler(rotation).to_matrix().to_4x4()
    matrix.translation = Vector(loc)
    for obj in (obj for obj in stage.scene.objects if obj not in before):
        obj.matrix_world = matrix @ obj.matrix_basis
        obj.name = label + ' · ' + obj.name


def ravine(stage):
    ymin,ymax,step=-28,84,.72
    rows = round((ymax-ymin)/step)+1
    for side in (-1,1):
        # A borda existe na malha. O espaço negro entre as margens é visível de cima.
        widths=(0,.46,1.25,2.6,4.2,6.5,9,13,20,31,45,58)
        n=len(widths)
        beach=[]
        wall=[]
        depths=(0,1.15,2.8,5.2,8.6,12.4,18.0)
        for j in range(rows):
            y=ymin+j*step
            edge=edges(y)[side==1]
            for w in widths:
                x=edge+side*w
                height=.020*noise(Vector((x*.53,y*.44,2)))
                shoulder=max(0,min(1,(w-4)/4))
                height+=.66*shoulder*noise(Vector((x*.13,y*.18,6)))
                beach.append((x,y,height))
            for i,d in enumerate(depths):
                recess=side*(d*.09+.57*math.sin(y*.63+i*.9)*(d>0))
                wall.append((edge+recess,y+.22*math.sin(i*.74+j)*(d>0),-d))
        faces = [(j*n+i,j*n+i+1,(j+1)*n+i+1,(j+1)*n+i)
                 for j in range(rows-1) for i in range(n-1)]
        if side<0:
            faces=[tuple(reversed(f)) for f in faces]
        stage.mesh('Margem oriental' if side>0 else 'Margem oposta',beach,faces,'sand','Geologia',smooth=True)
        n=len(depths)
        faces=[(j*n+i,(j+1)*n+i,(j+1)*n+i+1,j*n+i+1)
               for j in range(rows-1) for i in range(n-1)]
        if side>0:
            faces=[tuple(reversed(f)) for f in faces]
        stage.mesh('Face exposta da falha',wall,faces,'deep','Geologia')
    course=stage.block('Sedimento ao fundo',(0,23,-17.8),(23,115,.7),'dark',coll='Geologia')
    course.display_type='WIRE'
    for i,(x,y,w,d,h) in enumerate(((-30,29,21,18,16),(25,36,17,24,17),(-23,49,23,23,23),
        (42,55,26,26,20),(-11,67,23,22,20),(22,69,29,21,25),(-35,75,28,27,25))):
        stage.cliff('Esporão fossilizado',(x,y,-.5),w,d,h,13+i*11,
                    asym=(-1)**i*.22,strata=.20,erosion=.29)
    for side in (-1,1):
        for i in range(28):
            y=-14+i*1.40+stage.random.uniform(-.24,.24)
            x=edges(y)[side==1]+side*stage.random.uniform(.13,1.35)
            size=stage.random.uniform(.18,.68)
            stage.block('Lasca da falha',(x,y,-.02),(size,size*1.35,size*.49),
                        'deep' if i%3==0 else 'strata',wear=.08,rot=i*.84,coll='Geologia')


def causeway(stage):
    for j in range(28):
        y=-13+j*1.24
        x=edges(y)[1]+2.2
        for i in range(-1,2):
            if (i,j) in ((-1,3),(1,8),(-1,12),(1,18),(-1,21)):
                continue
            w=stage.random.uniform(.90,1.16)
            stage.block('Laje cortada pela erosão',(x+i*1.16+.15*math.sin(j+i),y,.008),
                        (w,stage.random.uniform(.78,1.20),.11),'trail',
                        wear=.08,rot=stage.random.uniform(-.15,.15))
    for y,h,dir in ((-3.7,1.23,-.26),(1.9,.82,-.43),(9.4,1.51,.20),(17.8,1.00,-.34)):
        x=edges(y)[1]+.38
        obj=fracture(stage,'Dente da mureta',(x,y,0),
                     [(-.30,-.29),(.40,-.29),(.37,h*.52),(-.08,h),(-.49,h*.75)],.61,
                     'deep',(.07,-.09))
        obj.rotation_euler.y=dir
    # O arco de chão conduz à margem segura, enquanto umbrais suspensos pertencem ao outro nível.
    x=edges(17.0)[1]+2.35
    for side in (-1,1):
        fracture(stage,'Ombreira descalçada',(x+side*2.68,17.7,0),
                 [(-.75,-.35),(.80,-.35),(.59,4.7),(.11,5.1),(-.58,4.88)],1.95,
                 'lime',(.08,.02))
    fracture(stage,'Lintel sem metade',(x,17.7,4.65),
             [(-3.39,0),(1.52,-.07),(1.93,.31),(1.26,.79),(-1.67,.86),(-3.53,.68)],1.97,'deep',(-.23,.12))
    # A moldura no primeiro plano está em pé, mas perdeu o lado junto à fenda.
    fracture(stage,'Costado do vestíbulo',(10.08,-.1,0),
             [(-.88,-.6),(3.91,-.6),(3.65,7.0),(1.13,8.73),(-.14,7.92),(-.98,4.83)],
             3.05,'deep',(.47,-.74))
    fracture(stage,'Marca funerária sem escrita',(10.4,-1.72,3.72),
             [(-1.10,-.85),(-.28,-.97),(.49,-.66),(.78,.19),(.32,.91),(-.55,.78)],
             .14,'dark',(.01,.02))


def stair_and_door(stage):
    rock(stage,'Margem arrancada',(-10.4,9.4,0),[(-3,-.3,0,4.4,6.9),
          (.4,0,0,4.6,6.0),(2.65,-.24,.8,3.8,5.0),(4.22,-1.53,1.3,2.7,3.7)],28)

    def flight():
        n=12
        for i in range(n):
            offset=.33*math.sin(i*.62)
            width=4.9-i*.14-(.82 if i>8 else 0)
            stage.block('Piso funerário',(offset,i*.96,i*.49),(width,1.0,.42),
                     'lime' if i%5 != 0 else 'trail',wear=.105,rot=.043*math.sin(i))
        beam=fracture(stage,'Longarina seccionada',(-.05,5.12,-.63),
                 [(-2.5,-.43),(2.4,-.56),(2.30,.45),(-1.87,.53)],10.6,'deep')
        # Bases profundas e a última fiada exposta separam o lance do chão.
        beam.rotation_euler.x=.47
    transformed(stage,'Escadaria sem destino',(-12.20,6.0,1.22),(0,0,-1.09),flight)

    def inverse_flight():
        for i in range(9):
            width=4.68-i*.21-(.76 if i>6 else 0)
            stage.block('Degrau suspenso',(.22*math.sin(i*.68),i*.87,i*.37),
                        (width,.91,.37),'lime' if i%4 else 'trail',wear=.073)
        beam=fracture(stage,'Apoio partido',(-.14,2.95,-.54),
                      [(-2.36,-.28),(1.39,-.52),(1.96,.29),(-1.91,.36)],
                      6.28,'deep',(.35,-.05))
        beam.rotation_euler.x=.38
    transformed(stage,'Escadaria com teto por piso',(1.83,23.45,13.37),
                (.11,math.pi+.06,1.98),inverse_flight)

    def sealed():
        stage.tomb(0,0,0,5.4,4.1,6.05)
        stage.block('Placa de obstrução',(.42,-1.71,2.15),(2.89,.43,3.27),'deep',
                    taper=.79,rot=.032)
        for i in range(4):
            stage.block('Ranhura talhada',(-1.27+i*.76,-1.89,2.52),(.12,.09,1.78),
                        'bone',wear=.024)
    transformed(stage,'Sepultura que virou parede',(-13.8,17.9,7.32),(0,-1.16,-.15),sealed)


def hanging_necropolis(stage):
    def gallery():
        # Em coordenadas locais é um trecho coerente de rua. Só o conjunto muda de orientação.
        fracture(stage,'Rua arrancada',(0,.15,-.12),
                 [(-11.65,-1.48),(-8.23,-1.83),(-4.13,-1.1),(-1.2,-2.02),(1.40,-1.50),
                  (5.30,-2.34),(8.43,-.84),(12.22,-1.64),(11.19,.25),
                  (5.17,.38),(1.53,.57),(-3.95,.30),(-8.33,.61),(-10.53,.19)],6.2,
                 'strata',(-.82,.18))
        for i,(x,h,w) in enumerate(((-8.4,4.3,3.5),(-3.2,6.9,5.3),(3.65,5.15,4.3),(8.75,3.8,3.6))):
            stage.tomb(x,-.65,.22,w,3.6,h)
            if i in (1,2):
                stage.pillar(x+w*.51,-2.45,.1,h*.67,1.02,True)
        for i,x in enumerate((-9.7,-6.1,-1.7,1.82,5.4,9.7)):
            stage.block('Mureta erosionada',(x,-3.20,.64),(1.46,.60,.85+math.sin(i)*.23),
                        'deep',taper=.74,rot=.082*math.sin(i))
        stage.statue(-6.17,-3.0,.26,1.04,True)
        stage.statue(6.68,-2.7,.22,.96)
    transformed(stage,'Galeria sepulcral invertida',(1.7,24.95,17.35),
                (-.13,math.pi+.21,-.18),gallery)
    rock(stage,'Maciço que carrega o teto',(1.65,27.25,17.75),
         [(-1.56,-.30,.77,8.5,3.55),(.20,.14,0,11.83,5.63),
          (2.75,1.17,.38,13.75,7.11),(4.90,2.45,1.63,8.65,4.2),(7.25,4.73,2.96,4.51,3.03)],
          59,'strata')
    # Poucos fragmentos desenhados a partir do plano rasgado da rua.
    for i,(x,y,z,w,h) in enumerate(((-10.62,24.3,18.15,3.25,1.64),
        (-12.83,23.55,17.57,1.15,.58),(12.8,27.6,17.05,2.51,1.15),
        (14.75,29.35,16.49,1.07,.53))):
        shard=fracture(stage,'Fragmento suspenso na linha da ruptura',(x,y,z),
            [(-w*.6,-h*.23),(.29*w,-h*.51),(w*.51,h*.31),(.19*w,h*.63),(-w*.49,h*.61)],
            h*1.62,'deep',(.13,.34),coll='Geologia')
        shard.rotation_euler=(.26*i,-.19+.17*i,.22*i)


def vertical_observatory(stage):
    # Duas superfícies abrigam a mesma linguagem de marcas e degraus com gravidades diferentes.
    rock(stage,'Dobra fossilizada atrás do disco',(20.9,37,-.5),
        [(-1,0,0,7,6),(.4,0,0,7.2,7.12),(5,-.55,.25,5.4,6.47),
        (9.7,-1.96,.70,5.63,4.0),(14.,-4.38,1.30,4.20,3.07),
        (16.3,-5.3,2.3,2.03,1.5)],93)
    centre=(16.06,31.85,8.05)
    ring=stage.ring('Meridiano fissurado e preso à rocha',centre,5.87,1.04,.72,'trail',
                    broken=(.62,1.31),tilt=(1.58,.10,-.36))
    stage.ring('Vestígio interno do meridiano',(15.91,31.52,7.93),4.10,.27,.25,'lead',
               broken=(1.32,.87),tilt=(1.57,.10,-.36))
    ring['Nota'] = 'Disco de pedra escavado na dobra do terreno'
    for i in range(7):
        z=1.2+i*.96
        step=stage.block('Degrau voltado para a parede',(14.10-.34*i,31.0-.15*i,z),
            (2.22,.47,.24),'lime',wear=.09)
        step.rotation_euler.y=-.27+i*.09


def build():
    backup = ROOT/'mcp_ruptura_revisao.blend'
    scene_name = SCENE+' · revisão'
    assert not backup.exists(), backup
    window = bpy.context.window
    current = window.scene
    original_file = bpy.data.filepath
    assert bpy.data.scenes.get(scene_name) is None
    before = set(obj.as_pointer() for obj in current.objects)
    mats = library()
    mats['deep']=material('Fratura de xisto',('211B16','594630','8D7350'),.95,0,.15,.23)
    mats['trail']=material('Calcário cortado',('423529','9A8158','BAA170'),.92,0,.09,.19)
    stage=Stage('R',scene_name,254,mats)
    scene=stage.scene
    scene['rota_de_teste']='Margem direita entre o vestíbulo e o pórtico. Sem integração de navegação.'
    scene.eevee.taa_render_samples=32
    scene.view_settings.exposure=.12
    ravine(stage)
    causeway(stage)
    stair_and_door(stage)
    hanging_necropolis(stage)
    vertical_observatory(stage)
    fog=next(obj for obj in stage.collections['Atmosfera'].objects)
    density=next(node for node in fog.active_material.node_tree.nodes if node.type=='VOLUME_SCATTER').inputs['Density']
    density.default_value=.011
    sun=next(obj for obj in stage.collections['Luzes'].objects if obj.data.type=='SUN')
    sun.data.energy=1.81
    sun.data.color=(1.0,.87,.72)
    sun.rotation_euler=(Vector((0,26,0))-Vector((-20,-12,12))).to_track_quat('-Z','Y').to_euler()
    stage.light('Luz rubra repicada na falha','AREA',(4.0,16.0,-7.5),(0,13,-2),770,(.88,.49,.31),10)
    stage.light('Claridade refletida sob a necrópole','AREA',(-3.0,12.0,4.5),(1.6,25,15.4),
                1450,(.95,.83,.67),11)
    stage.light('Névoa no corte do penhasco','AREA',(15,26,4),(0,20,4),900,(.92,.62,.49),10)
    scene.camera=stage.camera('01 · Exploração', (2.85,-5.8,EYE),(.45,18,EYE),player=True)
    stage.camera('02 · Margem', (5.37,3.3,EYE),(3.0,24,EYE),player=True)
    stage.camera('03 · Fenda', (4.95,2.3,3.15),(-4.75,9.5,.6),25)
    stage.camera('04 · Geral', (29,-32,28),(1.1,15.6,8.6),31)
    stage.camera('05 · Planta', (1.4,11.0,77),(1.4,11.0,0),ortho=63)
    stage.camera('06 · Geometria', (25,-21,30),(1.4,14.0,8.0),ortho=62)
    stage.camera('07 · Rua invertida', (6.8,10.20,4.4),(1.2,24.1,15.1),29)
    document=bpy.data.texts.new('D01 · Ruptura · Revisão da modelagem')
    document.write(Path(__file__).read_text(encoding='utf-8'))
    document.use_fake_user=True
    scene.use_fake_user=True
    assert {obj.as_pointer() for obj in current.objects} == before
    window.scene=scene
    try:
        bpy.ops.wm.save_as_mainfile(filepath=str(backup),copy=True,compress=True)
    finally:
        window.scene=current
    assert bpy.data.filepath==original_file
    assert backup.is_file()
    print(f'{scene.name}: {len(scene.objects)} objetos; {backup}; cena anterior preservada.')


if __name__=='__main__':
    build()
