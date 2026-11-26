"""Gera as três maquetes da Necrópole em cenas isoladas no Blender."""
import bpy
import math
import random
from mathutils import Vector
from mathutils.noise import noise_vector, noise
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CELL = 4.0
EYE = CELL * 64 / 304
FOV = 2 * math.atan(245 / 304)
PRESETS = {"Mineral Silence": .007, "Saturnine Haze": .019, "Ashen Eternity": .035}


def linear(value):
    return value / 12.92 if value < .04045 else ((value + .055) / 1.055) ** 2.4


def color(value):
    return tuple(linear(int(value[i:i+2], 16) / 255) for i in (0, 2, 4)) + (1,)


def material(name, tones, roughness, metal, strata, bump):
    mat = bpy.data.materials.new("D01 · " + name)
    mat.use_nodes = True
    mat.use_fake_user = True
    mat.asset_mark()
    mat.diffuse_color = color(tones[1])
    tree = mat.node_tree
    nodes, links = tree.nodes, tree.links
    bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Metallic'].default_value = metal
    bsdf.inputs['Roughness'].default_value = roughness
    tex = nodes.new('ShaderNodeTexCoord')
    grain = nodes.new('ShaderNodeTexNoise')
    grain.label = 'Granulação mineral'
    grain.inputs['Scale'].default_value = 5.1
    grain.inputs['Detail'].default_value = 3.3
    links.new(tex.outputs['Object'], grain.inputs['Vector'])
    wave = nodes.new('ShaderNodeTexWave')
    wave.wave_type = 'BANDS'
    wave.bands_direction = 'Z' if name != 'Madeira morta' else 'X'
    wave.inputs['Scale'].default_value = .23
    wave.inputs['Distortion'].default_value = 8.7
    wave.inputs['Detail Scale'].default_value = .31
    links.new(tex.outputs['Object'], wave.inputs['Vector'])
    mix = nodes.new('ShaderNodeMixRGB')
    mix.label = 'Força da estratificação'
    mix.inputs[0].default_value = strata
    links.new(grain.outputs['Fac'], mix.inputs[1])
    links.new(wave.outputs['Color'], mix.inputs[2])
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.label = 'Sombra · cor principal · luz'
    ramp.color_ramp.elements.new(.54)
    for element, value, position in zip(ramp.color_ramp.elements, tones, (.17, .54, .86)):
        element.position = position
        element.color = color(value)
    links.new(mix.outputs[0], ramp.inputs[0])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    relief = nodes.new('ShaderNodeBump')
    relief.inputs['Strength'].default_value = bump
    relief.inputs['Distance'].default_value = .11
    links.new(mix.outputs[0], relief.inputs['Height'])
    links.new(relief.outputs[0], bsdf.inputs['Normal'])
    for node, position in zip((tex, grain, wave, mix, ramp, relief, bsdf), (
        (-780, 110), (-560, 220), (-560,-80), (-300,100), (-80,220), (-80,-50), (225,200)
    )):
        node.location = position
    return mat


def library():
    specs = {
        'lime': ('Calcário funerário', ('4C4639','968562','B5A17C'), .92, 0, .11, .22),
        'strata': ('Rocha sedimentar', ('312A1E','6C5D42','9C895F'), .96, 0, .17, .27),
        'bronze': ('Bronze saturnino', ('302A20','605137','817359'), .69, .48, .10, .24),
        'lead': ('Chumbo ritual', ('292824','55565A','79736A'), .82, .44, .12, .23),
        'bone': ('Osso fossilizado', ('594C38','AD9B7B','C8BBA0'), .96, 0, .12, .31),
        'sand': ('Areia funerária', ('4B412D','8D774C','B5A17C'), .98, 0, .07, .21),
        'gold': ('Dourado morto', ('32291B','7F6B41','958052'), .72, .44, .12, .24),
        'wood': ('Madeira morta', ('231B13','4B3B25','735A36'), .94, 0, .59, .32),
        'dark': ('Cavidades', ('171511','302A20','4B3B30'), .99, 0, .20, .23),
    }
    return {key: material(*values) for key, values in specs.items()}


class Stage:
    def __init__(self, slug, title, seed, mats):
        self.scene = bpy.data.scenes.new(title)
        self.scene.render.engine = 'BLENDER_EEVEE'
        self.scene.render.resolution_x = 804
        self.scene.render.resolution_y = 490
        self.scene.render.resolution_percentage = 100
        self.scene.render.image_settings.file_format = 'PNG'
        self.scene.render.image_settings.color_mode = 'RGB'
        self.scene.render.film_transparent = False
        self.scene.view_settings.view_transform = 'AgX'
        self.scene.view_settings.exposure = .15
        self.scene['estudo'] = slug
        self.scene['unidades_por_celula'] = CELL
        self.scene['altura_olhos'] = EYE
        self.scene['corte_jogo_unidades'] = CELL * 5.5
        self.scene['status'] = 'Estudo experimental · sujeito a aprovação artística'
        root = bpy.data.collections.new("EXODUS_D01_SATURNINE_NECROPOLIS · " + slug)
        self.scene.collection.children.link(root)
        self.collections = {}
        for key in ('Geologia','Arquitetura','Escultura','Instrumentos','Objetos','Atmosfera','Luzes','Câmeras'):
            collection = bpy.data.collections.new(slug + ' · ' + key)
            root.children.link(collection)
            self.collections[key] = collection
        self.mats = mats
        self.random = random.Random(seed)
        self.scene['seed'] = seed
        self.sky()

    def mesh(self, name, vertices, faces, mat, coll='Arquitetura', bevel=0, smooth=False):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        self.collections[coll].objects.link(obj)
        if mat:
            mesh.materials.append(self.mats[mat] if isinstance(mat, str) else mat)
        for face in mesh.polygons:
            face.use_smooth = smooth
        if bevel:
            mod = obj.modifiers.new('Arestas desgastadas', 'BEVEL')
            mod.width = bevel
            mod.segments = 2
            mod = obj.modifiers.new('Normais de pedra', 'WEIGHTED_NORMAL')
            mod.keep_sharp = True
        return obj

    def block(self, name, loc, dim, mat='lime', *, taper=1, wear=.07, rot=0, coll='Arquitetura'):
        w,d,h = (v/2 for v in dim)
        cut = min(w,d) * .19
        shape = [(-w+cut,-d),(w-cut,-d),(w,-d+cut),(w,d-cut),(w-cut,d),(-w+cut,d),(-w,d-cut),(-w,-d+cut)]
        verts = [(x*ratio+self.random.uniform(-wear,wear), y*ratio+self.random.uniform(-wear,wear),
                  z+self.random.uniform(-wear,wear))
                 for z,ratio in ((-h,1),(h,taper)) for x,y in shape]
        faces = [tuple(reversed(range(8))), tuple(range(8,16))]
        faces.extend((i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8))
        obj = self.mesh(name, verts, faces, mat, coll, min(.07,min(dim)*.15))
        obj.location = loc
        obj.rotation_euler.z = rot
        return obj

    def lathe(self, name, loc, profile, mat, coll='Instrumentos', sides=48, gap=(0,0), rotation=(0,0,0)):
        start, span = gap[0], math.tau-gap[1]
        closed = gap[1] == 0
        n = sides if closed else sides + 1
        verts = [(r*math.cos(start+span*k/sides), r*math.sin(start+span*k/sides), z)
                 for r,z in profile for k in range(n)]
        faces = []
        for p in range(len(profile)):
            after = (p+1)%len(profile)
            for k in range(sides):
                j = (k+1)%n
                faces.append((p*n+k,p*n+j,after*n+j,after*n+k))
        if not closed:
            faces.extend((tuple(reversed([p*n for p in range(len(profile))])),
                          tuple(p*n+n-1 for p in range(len(profile)))))
        obj = self.mesh(name, verts, faces, mat, coll, smooth=True)
        obj.location = loc
        obj.rotation_euler = rotation
        return obj

    def ring(self, name, loc, r, width, depth, mat='bronze', broken=(0,0), tilt=(math.pi/2,0,0)):
        return self.lathe(name, loc, [(r-width,-depth/2),(r,-depth/2),(r,depth/2),(r-width,depth/2)],
                          mat, gap=broken, rotation=tilt)

    def sphere(self, name, loc, radii, mat, coll='Escultura', tilt=(0,0,0)):
        u,v = 24,12
        verts = [(0,0,-radii[2])]
        for j in range(1,v):
            a = math.pi*j/v
            for i in range(u):
                t = math.tau*i/u
                verts.append((radii[0]*math.sin(a)*math.cos(t),radii[1]*math.sin(a)*math.sin(t),-radii[2]*math.cos(a)))
        verts.append((0,0,radii[2]))
        faces = []
        for i in range(u):
            nxt = (i+1)%u
            faces.append((0,nxt+1,i+1))
            for j in range(v-2):
                k=1+j*u
                faces.append((k+i,k+nxt,k+u+nxt,k+u+i))
            k=1+(v-2)*u
            faces.append((k+i,k+nxt,len(verts)-1))
        obj = self.mesh(name,verts,faces,mat,coll,smooth=True)
        obj.location = loc
        obj.rotation_euler = tilt
        return obj

    def shaft(self,name,a,b,r1,r2,mat,coll='Escultura',sides=12):
        vec = Vector(b)-Vector(a)
        length = vec.length
        obj = self.lathe(name,(Vector(a)+Vector(b))/2,[(.0001,-length/2),(r1,-length/2),
            (r2,length/2),(.0001,length/2)],mat,coll,sides)
        obj.rotation_euler = vec.to_track_quat('Z','Y').to_euler()
        return obj

    def cliff(self,name,loc,w,d,h,seed,asym=.25,strata=.21,erosion=.22):
        # Closed rings with directional ribs and coherent offsets from foot to crest.
        rng = random.Random(seed)
        sides, tiers = 27, 11
        ribs = [rng.uniform(.71,1.15) for _ in range(sides)]
        rings = []
        for j in range(tiers+1):
            t = j/tiers
            for i in range(sides):
                a = math.tau*i/sides
                field = noise(Vector((math.cos(a)*2+seed,math.sin(a)*2,t*2.1)))
                layer = 1 + strata*math.sin(j*1.26+1.4*math.cos(a*2))*(1-t)*.12
                r=(1-.52*t**1.58)*ribs[i]*layer + erosion*field*.34
                x = math.cos(a)*r*w/2 + (t*t)*w*asym
                y = math.sin(a)*r*d/2 + t*d*.12
                z = h*(t+field*.33*t**2 + .15*math.sin(a*3+t)*t)
                rings.append((x,y,z))
        faces=[tuple(reversed(range(sides))),tuple(range(tiers*sides,(tiers+1)*sides))]
        faces.extend((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i)
                      for j in range(tiers) for i in range(sides))
        obj=self.mesh(name,rings,faces,'strata','Geologia',smooth=False)
        obj.location=loc
        for key,value in dict(seed=seed,width=w,depth=d,height=h,asymmetry=asym,
                              stratification=strata,erosion=erosion).items():
            obj[key]=value
        return obj

    def terrain(self):
        nx,ny=88,100
        verts=[]
        for j in range(ny+1):
            y=-29+1.25*j
            for i in range(nx+1):
                x=-55+1.25*i
                off=min(1,max(0,(abs(x)-2)/4))
                z=.025*noise(Vector((x*.3,y*.3,2)))+off*.42*noise(Vector((x*.11,y*.12,1)))
                verts.append((x,y,z))
        faces=[(j*(nx+1)+i,j*(nx+1)+i+1,(j+1)*(nx+1)+i+1,(j+1)*(nx+1)+i)
               for j in range(ny) for i in range(nx)]
        self.mesh('Bacia sedimentar · passagem mantida livre',verts,faces,'sand','Geologia',smooth=True)
        for j,(x,y,w,d,h) in enumerate([(-23,28,22,29,14),(24,35,27,33,15),
            (-35,44,30,31,23),(39,55,28,33,21),(3,61,55,23,18),
            (-35,75,62,27,23),(29,77,44,26,29),(-5,85,49,25,22)]):
            self.cliff('Cordilheira fossilizada %02d'%j,(x,y,-.22),w,d,h,31+j*9,asym=(-1)**j*.18)
        for side in (-1,1):
            for i in range(21):
                y=-10+i*1.53+self.random.uniform(-.5,.5)
                x=side*(2.2+self.random.uniform(-.25,2.2))
                radius=self.random.uniform(.10,.60)
                self.block('Fragmento nas margens',(x,y,.01),(radius,radius*self.random.uniform(.65,1.7),radius*.31),
                           'strata',wear=.04,rot=self.random.random()*math.tau,coll='Geologia')

    def pavement(self, y0,y1,half=2):
        rows = int((y1-y0)/1.5)
        for j in range(rows):
            y=y0+j*1.5+self.random.uniform(-.14,.14)
            for i,x in enumerate((-half*.64,0,half*.64)):
                if (j*7+i*3)%13==0:
                    continue
                self.block('Laje processional',(x+.23*math.sin(j+i*.31),y+self.random.uniform(-.12,.12),.025),
                           (half*self.random.uniform(.51,.64),self.random.uniform(1.08,1.45),self.random.uniform(.09,.18)),
                           'lime' if (j+i*3)%7==0 else 'strata',
                           wear=.052,rot=self.random.uniform(-.095,.095))

    def stair(self,y,z,width,rise,tread,steps,x=0,name='Escada gasta'):
        for i in range(steps):
            h=rise*(i+1)
            self.block(name,(x,y+tread*i,z+h/2),(width*(1-.014*i),tread+.065,h),
                        wear=.05)

    def pillar(self,x,y,z,h,wide,unfinished=False):
        self.block('Embasamento',(x,y,z+.24),(wide*1.52,wide*1.39,.48),'strata')
        self.block('Soco',(x,y,z+.58),(wide*1.23,wide*1.13,.22))
        self.block('Pilar maciço',(x,y,z+.69+h*.5),(wide,wide*.97,h),
                   'lime',taper=.79,wear=.09 if unfinished else .045)
        if not unfinished:
            self.block('Abaco erosionado',(x,y,z+.69+h+.16),(wide*1.38,wide*1.22,.31),'strata')

    def tomb(self,x,y,z,w,d,h):
        self.block('Plinto funerário',(x,y,z+.26),(w+.30,d,.52),'strata')
        jamb=w*.25
        self.block('Ombreira esquerda',(x-w*.36,y,z+h*.57),(jamb,d,h-.33))
        self.block('Ombreira direita',(x+w*.36,y,z+h*.57),(jamb,d,h-.33))
        self.block('Lintel',(x,y,z+h),(w+.16,d+.20,.46),'lime')
        self.block('Câmara em sombra',(x,y+d*.35,z+h*.40),(w*.60,.28,h*.67),'dark')
        self.block('Cornija gasta',(x,y,z+h+.37),(w+.39,d+.32,.34),'strata',taper=.77)

    def statue(self,x,y,z,s=1,fused=False):
        def p(a,b,c): return (x+s*a,y+s*b,z+s*c)
        self.block('Base da escultura',p(0,0,.20),(2.35*s,1.85*s,.42*s),'strata',coll='Escultura')
        mat='bone' if fused else 'lime'
        # Weight is carried through the seat, bent legs, and elbow resting on the knee.
        self.block('Assento mineral',p(.05,.25,.81),(1.65*s,1.20*s,1.02*s),mat,coll='Escultura')
        profile=[(0,.11,2.93,.32,.25),(.05,.14,2.73,.72,.43),
            (.03,.19,2.26,.78,.54),(.07,.07,1.84,.72,.68),
            (.04,-.19,1.39,.94,.76),(.06,-.13,.63,.92,.52),(.08,-.10,.45,.96,.44)]
        sides=32
        cloth=[]
        for row,(cx,cy,cz,rx,ry) in enumerate(profile):
            for i in range(sides):
                a=math.tau*i/sides
                fold=1+.061*math.cos(a*9+row*.34)+.045*math.sin(a*5)
                cloth.append(p(cx+rx*math.cos(a)*fold,cy+ry*math.sin(a)*fold,cz+.045*math.sin(a*3+row)))
        faces=[tuple(range(sides)),tuple(reversed(range((len(profile)-1)*sides,len(profile)*sides)))]
        for row in range(len(profile)-1):
            for i in range(sides):
                a,b=row*sides+i,row*sides+(i+1)%sides
                faces.append((a,a+sides,b+sides,b))
        self.mesh('Manto mineral · dobras contínuas da pedra',cloth,faces,mat,'Escultura',smooth=True)
        self.sphere('Cabeça inclinada',p(-.23,-.40,2.91),(.38*s,.32*s,.50*s),mat,tilt=(-.34,-.47,-.18))
        for side in (-1,1):
            self.shaft('Perna sob o manto',p(side*.45,-.03,1.63),p(side*.56,-.60,1.23),.43*s,.35*s,mat)
            self.shaft('Canela mineral',p(side*.56,-.60,1.23),p(side*.58,-.81,.48),.35*s,.26*s,mat)
            self.sphere('Pé esculpido',p(side*.58,-.90,.44),(.29*s,.45*s,.18*s),mat)
        self.shaft('Braço apoiado',p(-.50,.02,2.55),p(-.62,-.62,1.55),.26*s,.20*s,mat)
        self.shaft('Antebraço sob a testa',p(-.62,-.62,1.55),p(-.47,-.64,2.67),.19*s,.17*s,mat)
        self.shaft('Braço caído',p(.69,.10,2.52),p(.82,-.59,1.42),.27*s,.18*s,mat)
        if fused:
            self.block('Maciço ainda por escavar',p(.74,.55,1.91),(1.40*s,1.00*s,3.00*s),'bone',
                       taper=.95,wear=.14,coll='Escultura')
        else:
            for side in (-1,1):
                for i in range(4):
                    self.shaft('Asa erodida · pena mineral',p(side*.39,.43,2.61-i*.11),
                               p(side*(1.44-i*.12),.50+i*.14,2.48-i*.43),.22*s,.08*s,mat)

    def polyhedron(self,loc,r):
        verts=[]
        for j,(z,scale,shift) in enumerate(((-.76,.48,.2),(-.36,1,.2),(.39,.85,-.27),(.91,.39,-.27))):
            for i in range(6):
                a=math.tau*i/6+shift
                verts.append((r*(scale*math.cos(a)+.14*j),r*scale*math.sin(a),r*z))
        faces=[tuple(reversed(range(6))),tuple(range(18,24))]
        for j in range(3):
            for i in range(6):
                a,b=j*6+i,j*6+(i+1)%6
                faces.extend(((a,b,b+6),(a,b+6,a+6)))
        obj=self.mesh('Poliedro em talhe interrompido',verts,faces,'bone','Escultura',.055)
        obj.location=loc

    def sky(self):
        world=bpy.data.worlds.new(self.scene.name+' · Céu rubro')
        world.use_nodes=True
        tree=world.node_tree
        nodes,links=tree.nodes,tree.links
        bg=next(n for n in nodes if n.type=='BACKGROUND')
        coords=nodes.new('ShaderNodeTexCoord')
        v=nodes.new('ShaderNodeVectorMath')
        v.operation='MULTIPLY'
        v.inputs[1].default_value=(3.4,4.2,8.0)
        n=nodes.new('ShaderNodeTexNoise')
        n.inputs['Scale'].default_value=1.7
        n.inputs['Detail'].default_value=4.0
        n.inputs['Roughness'].default_value=.66
        ramp=nodes.new('ShaderNodeValToRGB')
        ramp.color_ramp.elements.new(.43)
        ramp.color_ramp.elements.new(.64)
        for stop,value,pos in zip(ramp.color_ramp.elements,('170D0C','311210','722218','A8382A'),(.13,.46,.67,.88)):
            stop.position=pos
            stop.color=color(value)
        links.new(coords.outputs['Normal'],v.inputs[0])
        links.new(v.outputs[0],n.inputs[0])
        links.new(n.outputs['Fac'],ramp.inputs[0])
        links.new(ramp.outputs[0],bg.inputs['Color'])
        bg.inputs['Strength'].default_value=.95
        self.scene.world=world
        atmosphere=bpy.data.materials.new(self.scene.name+' · Poeira mineral')
        atmosphere.use_nodes=True
        nodes=atmosphere.node_tree.nodes
        nodes.clear()
        output=nodes.new('ShaderNodeOutputMaterial')
        volume=nodes.new('ShaderNodeVolumeScatter')
        volume.inputs['Color'].default_value=color('A68F6F')
        volume.inputs['Anisotropy'].default_value=.12
        volume.inputs['Density'].default_value=PRESETS['Saturnine Haze']
        atmosphere.node_tree.links.new(volume.outputs[0],output.inputs['Volume'])
        box=self.block('Volume de poeira',(0,34,9),(114,132,20),atmosphere,
                       wear=0,coll='Atmosfera')
        box.display_type='WIRE'
        for key,value in PRESETS.items():
            box[key]=value
        self.light('Sol baixo difuso','SUN',(-18,-19,13),(0,10,0),2.25,(.98,.86,.68),.20)
        self.light('Preenchimento mineral','AREA',(12,-13,10),(0,15,3),1700,(.81,.78,.66),19)
        self.light('Luz filtrada pelo céu','AREA',(1,25,17),(0,11,1),1950,(.91,.52,.33),24)

    def light(self,name,kind,loc,target,power,rgb,size):
        data=bpy.data.lights.new(name,kind)
        data.energy=power
        data.color=rgb
        if kind=='SUN':
            data.angle=size
        else:
            data.shape='DISK'
            data.size=size
        obj=bpy.data.objects.new(name,data)
        self.collections['Luzes'].objects.link(obj)
        obj.location=loc
        obj.rotation_euler=(Vector(target)-Vector(loc)).to_track_quat('-Z','Y').to_euler()

    def camera(self,name,loc,target,lens=33,ortho=0,player=False):
        data=bpy.data.cameras.new(name)
        data.lens=lens
        data.clip_end=160
        if player:
            data.sensor_fit='VERTICAL'
            data.angle_y=FOV
            data.clip_start=.01*CELL
            data['corte_do_jogo']=5.5*CELL
        if ortho:
            data.type='ORTHO'
            data.ortho_scale=ortho
        obj=bpy.data.objects.new(name,data)
        self.collections['Câmeras'].objects.link(obj)
        obj.location=loc
        obj.rotation_euler=(Vector(target)-Vector(loc)).to_track_quat('-Z','Y').to_euler()
        return obj

    def cameras(self,pov,wide,approach,material,interest,center):
        self.scene.camera=self.camera('01 · Exploração',pov,(pov[0],pov[1]+8,pov[2]),player=True)
        self.camera('02 · Geral',*wide)
        self.camera('03 · Aproximação',*approach)
        self.camera('04 · Materiais',*material)
        self.camera('05 · Geometria',(center[0]+14,center[1]-24,18),(center[0],center[1]+2,3),ortho=37)
        self.camera('06 · Ponto de interesse',*interest)
        self.camera('07 · Planta',(center[0],center[1],58),(center[0],center[1],0),ortho=42)


def stone(mats):
    s=Stage('A','A · Necropolis of Stone',92,mats)
    s.terrain()
    s.pavement(-12,17)
    for i,(x,y,w,d,h) in enumerate(((-10,15,17,14,13),(11,18,15,19,15),
        (-18,21,17,14,13),(17,25,19,21,18),(-9,25,17,18,17),
        (9,30,16,24,16),(0,28,15,14,12))):
        s.cliff('Paredão estratificado %02d'%i,(x,y,-.30),w,d,h,103+i*11,asym=.15*(-1)**i)
    # Real opening, with rock flanks and lintel over a readable passage.
    s.block('Massa atrás do lintel',(0,15.7,8.45),(13.6,5.5,4.5),'strata',taper=.77,wear=.33)
    s.stair(5.8,0,5.6,.17,.86,6)
    s.block('Patamar funerário',(0,12,0.48),(6.8,4.0,.96),'strata')
    s.tomb(0,13.2,1.0,6.2,4.8,5.8)
    # Remove the individual rear infill of the portal to leave a traverse before the cliff.
    s.collections['Arquitetura'].objects.unlink(next(o for o in s.collections['Arquitetura'].objects
        if o.name.startswith('Câmara em sombra') and abs(o.location.x)<.01))
    for x,y,h in [(-6.5,9,3.7),(6.6,11,4.6),(-10.3,12,4.4),(10.5,12.7,3.5)]:
        s.tomb(x,y,.08,3.35,3.0,h)
    s.statue(-3.95,12.0,.63,1.19)
    s.statue(4.12,12.3,.60,1.12,True)
    for x,y,h,angle in [(-4.0,2.2,2.9,-.16),(4.7,4.6,2.05,.26)]:
        ob=s.block('Estela quebrada',(x,y,h*.43),(.84,.64,h),'strata',taper=.60,wear=.13,rot=angle)
        ob.rotation_euler.y=angle
    s.light('Rebatimento no pórtico','AREA',(-3.0,7.1,3.3),(-3.95,12,2.4),90,(.95,.78,.55),3.5)
    s.cameras((0,-3.8,EYE),((-18,-16,10),(0,13,4),30),((.5,2,1.2),(0,13,4.2),30),
        ((2.7,7.4,1.75),(3.4,10.5,.95),32),((-.65,7.15,2.55),(-3.95,12,2.55),28),(0,9))
    return s


def melancholy(mats):
    s=Stage('B','B · Necropolis of Melancholy',132,mats)
    s.terrain()
    s.pavement(-12,23,2.05)
    for sign in (-1,1):
        for i in range(4):
            s.pillar(sign*(6.8 if sign < 0 else 7.9),4+i*4.6,0,4.5 if i<3 else 3.7,1.28,i==3)
        for i in range(3):
            if sign>0 and i==1: continue
            s.block('Viga do claustro',(sign*(6.8 if sign<0 else 7.9),6.3+i*4.6,5.64),
                    (1.7,4.85,.73),'strata',wear=.13)
        for i in range(3):
            s.tomb(sign*10.1,7+i*4.7,-.02,3.4,2.1,3.0)
    s.block('Oficina abandonada',(-4.6,12.2,.27),(4.4,5,.54),'strata')
    s.statue(-4.7,13,.56,1.48,True)
    s.polyhedron((3.9,10.4,1.56),2.12)
    s.block('Base de talhe',(3.85,10.5,.21),(4.0,3.6,.46),'strata')
    s.block('Bancada de cinzelagem',(-4.5,8.05,.66),(2.25,.83,.26),'wood',coll='Objetos')
    for x in (-5.29,-3.75):
        s.block('Pé da bancada',(x,8.05,.33),(.25,.42,.67),'wood',coll='Objetos')
    s.shaft('Cinzel deixado sobre a bancada',(-4.9,7.83,.85),(-4.29,8.03,.88),.06,.028,'lead','Objetos')
    s.shaft('Cabo do malho',(-4.2,7.8,.86),(-3.69,8.12,.89),.058,.046,'wood','Objetos')
    s.block('Cabeça do malho',(-3.66,8.13,.91),(.25,.36,.20),'strata',coll='Objetos')
    s.stair(15.5,0,3.5,.40,.86,10,3.5,'Escada que termina no vazio')
    s.pillar(-3.5,24.8,0,6.9,1.65,True)
    s.pillar(3.8,27.5,0,7.2,1.85,True)
    s.block('Travessa suspensa sem ligação',(-5.1,25.46,7.89),(5.0,1.95,.85),'lime',wear=.15)
    s.light('Luz rebatida na bancada','AREA',(-2.7,6.5,3.2),(-4.6,8.05,.76),63,(.94,.82,.63),2.0)
    s.cameras((0,1.5,EYE),((-16,-13,12),(0,14,3.2),31),((1.0,5.3,1.6),(-.3,15,2.5),30),
        ((-3.6,5,1.95),(-4.72,8.1,.88),37),((-.3,6.0,2.5),(-4.7,12.7,2.6),26),(0,13))
    return s


def saturn(mats):
    s=Stage('C','C · Necropolis of Saturn',173,mats)
    s.terrain()
    s.pavement(-12,12)
    for x,y,h in ((-8,8,3.7),(8,8,3.35),(-11,17,4.7),(10,18,4.8),(-12,24,5),(13,24,5.3)):
        s.pillar(x,y,0,h,1.6,True)
        s.tomb(x+(-2.2 if x<0 else 2.2),y+2.6,.1,3.5,2.3,2.65)
    s.stair(6.9,0,5.3,.18,.75,6)
    for j,(r,top) in enumerate(((8.8,.58),(8.25,.88),(7.6,1.12))):
        s.lathe('Terraço de observação · nível %s'%j,(0,19,0),
                [(.001,top-.22),(r,top-.22),(r,top),(r-.16,top+.13),(.001,top+.13)],
                'strata' if j%2==0 else 'lime','Arquitetura',sides=48)
    for radius in (3.7,5.8,7.0):
        s.ring('Trajetória gravada no terraço',(0,19,1.27),radius,.11,.03,'lead',
               broken=(.15,.36),tilt=(0,0,0))
    for i in range(16):
        if i in (10,11,12,13): continue
        a=math.tau*i/16
        s.block('Marco de observação', (7.0*math.cos(a),19+7.0*math.sin(a),1.56),
                (.46,.64,.62),'bronze',wear=.045,rot=a,coll='Instrumentos')
    for x in (-4.9,4.9):
        s.block('Contraforte orbital',(x,22.05,3.18),(2.80,4.75,4.0),'strata',taper=.79,wear=.13)
        s.block('Berço dos anéis',(x*.82,20.4,3.1),(1.22,2.15,4.1),'lime',taper=.72)
    s.ring('Anel orbital partido',(0,22,6.36),6.05,.62,.55,'lime',broken=(.44,.97),tilt=(1.47,.03,.14))
    s.ring('Arco de bronze escurecido',(0,21.6,6.22),4.95,.23,.27,'bronze',broken=(.1,.5),
           tilt=(1.19,.54,-.28))
    s.ring('Círculo de chumbo inclinado',(0,21.0,5.95),4.12,.30,.30,'lead',broken=(.5,.88),
           tilt=(.74,-.39,.23))
    s.sphere('Esfera mineral',(0,21,4.61),(2.26,2.18,2.26),'strata','Instrumentos')
    s.block('Base do meridiano',(0,21,2.17),(3.30,3.0,1.80),'lime',taper=.68)
    s.pillar(-5,15.8,1.28,2.83,1.03,True)
    s.pillar(-8,15.8,.10,3.95,1.30,True)
    s.block('Travessão do sino',(-6.55,15.8,5.46),(4.27,.62,.53),'wood',coll='Objetos')
    s.shaft('Suspensão do sino',(-6.56,15.8,5.34),(-6.56,15.8,4.67),.073,.078,'lead','Objetos')
    s.lathe('Sino inutilizado por fratura',(-6.56,15.8,3.55),[
        (.84,0),(.76,.12),(.64,.42),(.42,.92),(.22,1.10),(.22,1.26),
        (.13,1.25),(.16,1.07),(.34,.88),(.56,.37),(.67,.09),(.72,0)],
        'bronze','Objetos',48,(4.69,.38))
    s.cameras((0,.1,EYE),((19,-13,13),(0,18,4),32),((0,5.7,1.7),(0,22.1,5.4),31),
        ((-3.6,11.6,3.1),(-6.55,15.8,4.0),36),((2.7,9.0,2.35),(0,21.5,6.55),24),(0,17))
    return s


def build(target=None):
    target=Path(target) if target else ROOT/'Sloth_The_Saturnine_Necropolis.blend'
    if target.exists():
        raise FileExistsError(target)
    startup = bpy.context.scene
    assert not bpy.data.filepath and len(bpy.data.scenes)==1, (
        'Execute numa sessão Blender de fábrica, dedicada às maquetes.'
    )
    assert set(o.name for o in startup.objects).issubset({'Cube','Camera','Light'})
    mats=library()
    stages=[]
    for factory in (stone,melancholy,saturn):
        print("Modelando", factory.__name__, flush=True)
        stages.append(factory(mats))
    print("Maquetes modeladas", flush=True)
    assert all(len(s.collections['Câmeras'].objects)==7 for s in stages)
    source=bpy.data.texts.new('D01 · Geradores editáveis · construir.py')
    source.write(Path(__file__).read_text(encoding='utf-8'))
    source.use_fake_user = True
    bpy.context.window.scene = stages[0].scene
    for obj in tuple(startup.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.scenes.remove(startup)
    for stage in stages:
        stage.scene.use_fake_user = True
    print("Salvando cenas", flush=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(target), compress=True)
    print(target)
    for s in stages:
        print(s.scene.name, len(s.scene.objects), s.scene.camera.name)


if __name__ == '__main__':
    import sys
    output = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else None
    build(output)
