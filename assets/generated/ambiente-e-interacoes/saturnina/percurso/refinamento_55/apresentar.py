"""Plantas comparáveis e seis vistas dos marcos, com filtro nas vistas do jogador."""
from pathlib import Path
import sys

from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parents[2]/'assets/generated/ambiente-e-interacoes/saturnina'))
from galeria import board, filter_image
from planta import ZONES,design,path_between
from mapa_expandido import layout as older_layout

LABELS=(
    ('Pórtico e Ruptura','I-C · Estela fendida'),
    ('Avenida Sepulcral','II-E · Sarcófago destampado'),
    ('Claustro da Melancolia','III-H · Oficina de figuras'),
    ('Ossuário dos Astrônomos','IV-H · Meridiano na parede'),
    ('Sepulcro do Sétimo Peso','V-G · Sino rachado'),
)
FONT=Path('C:/Windows/Fonts/segoeui.ttf')


def font(size):
    return ImageFont.truetype(str(FONT),size) if FONT.exists() else ImageFont.load_default(size=size)


def checked_save(img,name):
    target=ROOT/name
    img.save(target)
    with Image.open(target) as check:
        check.verify()


def plans():
    c,rooms,h=design()
    all_tiles=set().union(*rooms.values(),*h.values())
    trace,_=path_between(all_tiles,c['I-B'],c['V-K'])
    floors,_,joins=older_layout()
    old=set().union(*floors,*joins)
    previous,_=path_between(old,ZONES[0].center('B'),ZONES[-1].center('K'))

    wide=Image.new('RGB',(716,692),'#191713')
    draw=ImageDraw.Draw(wide)
    draw.text((28,19),'As mesmas 55 salas',font=font(28),fill='#eee1c5')
    for x,title,tiles,path in ((38,'Maquete anterior',old,previous),(365,'Planta refinada',all_tiles,trace)):
        scale=3
        dx=min(i for i,j in tiles)
        dy=min(j for i,j in tiles)
        draw.text((x,65),title,font=font(18),fill='#eee1c5')
        draw.text((x,91),f'{len(path)} células no menor trajeto',font=font(14),fill='#c4b093')
        for a,b in tiles:
            px,py=x+scale*(a-dx),126+scale*(b-dy)
            draw.rectangle((px,py,px+scale-1,py+scale-1),fill='#6f5e48')
        draw.line([(x+scale*(i-dx),126+scale*(j-dy)) for i,j in path],fill='#dfbf7b',width=2)
    checked_save(wide,'comparacao_de_planta.png')

    detailed=Image.new('RGB',(700,1210),'#191713')
    pen=ImageDraw.Draw(detailed)
    pen.text((26,20),'Necrópole Saturnina · 55 salas',font=font(28),fill='#eee1c5')
    pen.text((28,62),'Planta refinada e marcos das câmaras laterais',font=font(17),fill='#c4b093')
    sz=6
    dx,dy=min(i for i,j in all_tiles),min(j for i,j in all_tiles)

    def cell(x,y):
        return 327+(x-dx)*sz,112+(y-dy)*sz

    for x,y in all_tiles:
        px,py=cell(x,y)
        pen.rectangle((px,py,px+sz-1,py+sz-1),fill='#514439')
    colors=('#69483d','#59504a','#6c593f','#50545d','#6d5b46')
    landmarks=('I-C','II-E','III-H','IV-H','V-G')
    for i,zone in enumerate(ZONES):
        y=cell(*zone.origin)[1]+14
        pen.text((29,y),zone.roman+' · '+zone.title,font=font(17),fill='#ede0c5')
        pen.text((29,y+29),LABELS[i][1],font=font(13),fill='#bdab8f')
        for node,area in rooms.items():
            if node.partition('-')[0]!=zone.roman:
                continue
            for x0,y0 in area:
                x1,y1=cell(x0,y0)
                pen.rectangle((x1,y1,x1+sz-1,y1+sz-1),fill=colors[i])
    pen.line([(x+3,y+3) for x,y in (cell(*p) for p in trace)],fill='#e4c683',width=3,joint='curve')
    for name,center in c.items():
        x,y=cell(*center)
        side=name in landmarks
        if side:
            pen.ellipse((x-5,y-5,x+12,y+12),fill='#433723',outline='#edd39b',width=2)
        pen.text((x+1,y-4),name.partition('-')[2],font=font(12),
                 fill='#fff1d5',stroke_fill='#26221c',stroke_width=1)
    pen.line((29,1159,61,1159),fill='#e4c683',width=3)
    pen.text((69,1149),'Menor trajeto',font=font(14),fill='#c4b093')
    pen.ellipse((27,1180,44,1197),outline='#edd39b',width=2)
    pen.text((69,1178),'Marcos laterais da galeria',font=font(14),fill='#c4b093')
    checked_save(detailed,'planta_55_salas.png')


def gallery():
    dest=ROOT/'galeria'
    dest.mkdir(exist_ok=True)
    titles=[s for pair in LABELS for s in pair]+['Planta 3D']
    entries=[]
    for i,title in enumerate(titles,1):
        name=f'{i:02d}.png'
        target=dest/name
        with Image.open(ROOT/'raw'/name) as raw:
            assert raw.size==(804,490)
            img=filter_image(raw) if i<=10 else raw.convert('RGB')
            img.save(target)
        with Image.open(target) as check:
            check.verify()
        entries.append((target,title))
    board(dest/'marcos_laterais.png','Cinco câmaras laterais',entries[1:10:2],2,(363,221))
    board(dest/'zonas.png','Pórtico, Avenida, Claustro, Ossuário e Sepulcro',
          entries[0:10:2]+entries[10:],2,(363,221))
    print('11 capturas verificadas, 10 com o filtro do jogo')


if __name__=='__main__':
    plans()
    if 'plantas' not in sys.argv:
        gallery()
