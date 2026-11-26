"""Gera o mapa de circulação e as vistas filtradas do blockout."""
from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from galeria import board,filter_image
from mapa import ZONES,audit_layout,layout,main_route

VIEWS=(('portico','I · Pórtico e Ruptura'),('avenida','II · Avenida Sepulcral'),
       ('claustro','III · Claustro da Melancolia'),('ossuario','IV · Ossuário dos Astrônomos'),
       ('sepulcro','V · Sepulcro do Sétimo Peso'),('planta','Maquete vista de cima'))
FONT=Path('C:/Windows/Fonts/segoeui.ttf')


def font(size):
    return ImageFont.truetype(str(FONT),size) if FONT.exists() else ImageFont.load_default(size=size)


def map_image():
    zones=layout()
    audit_layout(zones)
    canvas=Image.new('RGB',(778,1110),'#191713')
    draw=ImageDraw.Draw(canvas)
    draw.text((36,24),'Necrópole Saturnina',fill='#e6d7b7',font=font(34))
    draw.text((38,70),'Percurso das cinco zonas',fill='#b7a68d',font=font(18))
    tile=16
    ox,oy=404,124
    palette=('#55382d','#49433a','#584633','#4a4845','#66533b')
    subtitles=('Ruptura no caminho principal','Dois laços pelos túmulos','Oficinas e pátio aberto',
               'Circular, com nichos laterais','Área do guardião')
    for i,((roman,name,y0,y1,_),cells) in enumerate(zip(ZONES,zones)):
        for x,y in sorted(cells):
            left,upper=ox+x*tile,oy+y*tile
            draw.rectangle((left,upper,left+tile-1,upper+tile-1),fill=palette[i],outline='#73624e')
        row=oy+y0*tile+12
        draw.text((37,row),roman+' · '+name,fill='#e6d7b7',font=font(19))
        draw.text((37,row+29),subtitles[i],fill='#b7a68d',font=font(15))
    route=[(ox+x*tile+tile//2,oy+y*tile+tile//2) for x,y in main_route()]
    draw.line(route,fill='#e6c579',width=4,joint='curve')
    for px,py in (route[0],route[-1]):
        draw.ellipse((px-5,py-5,px+5,py+5),fill='#e6c579')
    draw.line((37,1054,77,1054),fill='#e6c579',width=4)
    draw.text((90,1042),'Caminho principal',fill='#dfcfaf',font=font(18))
    draw.text((37,1074),'Cada quadrado representa uma célula de referência.',fill='#ab9b84',font=font(14))
    canvas.save(ROOT/'mapa_percurso.png')


def main():
    preview='preview' in sys.argv
    source=Path(sys.argv[-1]) if preview else ROOT/'raw'
    dest=source if preview else ROOT/'galeria'
    dest.mkdir(exist_ok=True)
    tiles=[]
    for view,label in VIEWS:
        with Image.open(source/(view+'.png')) as frame:
            rgb=frame.convert('RGB')
            if preview:
                rgb=rgb.resize((804,490),Image.Resampling.LANCZOS)
            assert rgb.size==(804,490)
            output=dest/(view+'_filtro.png' if preview else view+'.png')
            (rgb if view=='planta' else filter_image(rgb)).save(output)
        with Image.open(output) as test:
            test.verify()
        tiles.append((output,label))
    board(dest/'prancha.png','Necrópole Saturnina · maquete das cinco zonas',tiles,2,(389,236))
    if not preview:
        map_image()
    print('6 PNGs conferidos · 804 × 490 · 5 vistas filtradas')


if __name__=='__main__':
    main()
