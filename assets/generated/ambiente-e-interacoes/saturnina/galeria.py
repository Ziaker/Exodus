"""Replica o filtro do protótipo nas capturas em 804 × 490 e monta pranchas."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
LUT = np.asarray(Image.open(ROOT/'lut.png').convert('RGB'),dtype=np.float32)/255
assert LUT.shape==(512,512,3)
W,H = 804,490
GRID_W,GRID_H = 288,176
X,Y = np.meshgrid(np.arange(GRID_W),np.arange(GRID_H))
BAYER = np.array([[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]])
DITHER = ((BAYER[3-Y%4,X%4]+.5)/16-.5)*.012
CELL_X = np.minimum(((np.arange(W)+.5)*GRID_W/W).astype(int),GRID_W-1)
CELL_Y = np.minimum(((np.arange(H)+.5)*GRID_H/H).astype(int),GRID_H-1)
GAIN = np.where(np.arange(H)%3==0,.85,1)[:,None,None]


def sample(im,x,y):
    x0,y0=np.floor(x).astype(int),np.floor(y).astype(int)
    x1,y1=np.minimum(x0+1,im.shape[1]-1),np.minimum(y0+1,im.shape[0]-1)
    a,b=(x-x0)[...,None],(y-y0)[...,None]
    return ((im[y0,x0]*(1-a)+im[y0,x1]*a)*(1-b)+(im[y1,x0]*(1-a)+im[y1,x1]*a)*b)


def lookup(rgb,blue):
    return sample(LUT,(blue%8)*64+rgb[...,0],(blue//8)*64+rgb[...,1])


def filter_image(raw):
    src=np.asarray(raw.convert('RGB'),dtype=np.float32)/255
    assert src.shape==(H,W,3)
    rgb=sample(src,(X+.5)*W/GRID_W-.5,(Y+.5)*H/GRID_H-.5)*63
    blue=np.floor(rgb[...,2]).astype(int)
    frac=(rgb[...,2]-blue)[...,None]
    graded=lookup(rgb,blue)*(1-frac)+lookup(rgb,np.minimum(blue+1,63))*frac
    quant=np.clip(np.floor((graded+DITHER[...,None])*26+.5)/26,0,1)
    base=quant[CELL_Y[:,None],CELL_X[None,:]]
    scan=np.where(base<.04045,base*GAIN,(base+.055)*GAIN**(1/2.4)-.055)
    return Image.fromarray(np.rint(np.clip(scan,0,1)*255).astype(np.uint8))


def board(target,title,entries,cols=2,thumb=(388,236)):
    rows=(len(entries)+cols-1)//cols
    gap,pad,caption=12,16,23
    frame=Image.new('RGB',(cols*thumb[0]+(cols-1)*gap+pad*2, 
                             rows*(thumb[1]+caption)+(rows-1)*gap+pad*2+34),'#191713')
    draw=ImageDraw.Draw(frame)
    font_path=Path('C:/Windows/Fonts/segoeui.ttf')
    font=lambda size: ImageFont.truetype(str(font_path),size) if font_path.exists() else ImageFont.load_default(size=size)
    draw.text((pad,pad),title,font=font(20),fill='#d3c9ad')
    for i,(path,label) in enumerate(entries):
        x=pad+(i%cols)*(thumb[0]+gap)
        y=pad+34+(i//cols)*(thumb[1]+gap+caption)
        image=Image.open(path).convert('RGB')
        image.thumbnail(thumb,Image.Resampling.LANCZOS)
        frame.paste(image,(x,y))
        draw.text((x,y+thumb[1]+3),label,font=font(14),fill='#d3c9ad')
    frame.save(target)


if __name__=='__main__':
    folder=ROOT/'galeria'
    folder.mkdir(exist_ok=True)
    rendered=sorted((ROOT/'raw').glob('*.png'))
    assert len(rendered)==24,len(rendered)
    for path in rendered:
        with Image.open(path) as raw:
            assert raw.size==(W,H)
            output=folder/path.name
            if path.stem.endswith('_geometria'):
                raw.save(output)
            else:
                filter_image(raw).save(output)
        with Image.open(output) as img:
            img.verify()
    labels={'pov':'Exploração', 'geral':'Geral', 'aproximacao':'Aproximação',
            'materiais':'Materiais', 'geometria':'Geometria sem material',
            'interesse':'Ponto de interesse', 'planta':'Planta'}
    for key,title in (('a','Necropolis of Stone'),('b','Necropolis of Melancholy'),('c','Necropolis of Saturn')):
        board(ROOT/(key+'_prancha.png'),title,[(folder/(key+'_'+view+'.png'),label)
             for view,label in labels.items()])
    atmosphere=[('mineral_silence','A · Mineral Silence'),('saturnine_haze','B · Saturnine Haze'),
                ('ashen_eternity','C · Ashen Eternity')]
    board(ROOT/'atmosfera.png','Mesma câmera · três densidades de poeira',
          [(folder/('atmosfera_'+key+'.png'),label) for key,label in atmosphere],
          cols=3,thumb=(318,194))
    board(ROOT/'comparacao_exploracao.png','Necrópole Saturnina · câmera de exploração',
          [(folder/(key+'_pov.png'),title) for key,title in
           (('a','A · Stone'),('b','B · Melancholy'),('c','C · Saturn'))],
          cols=3,thumb=(318,194))
    board(ROOT/'comparacao_plantas.png','Necrópole Saturnina · plantas filtradas',
          [(folder/(key+'_planta.png'),title) for key,title in
           (('a','A · Stone'),('b','B · Melancholy'),('c','C · Saturn'))],
          cols=3,thumb=(318,194))
    previews=ROOT/'previews'
    baseline=[previews/(key+'_pov.png') for key in 'abc']
    if all(path.exists() for path in baseline):
        previous=[]
        for key,path in zip('abc',baseline):
            with Image.open(path) as raw:
                dest=previews/(key+'_pov_filtrado_antes.png')
                filter_image(raw.resize((W,H),Image.Resampling.LANCZOS)).save(dest)
                previous.append(dest)
        board(ROOT/'antes_depois.png','Refinamento · antes e depois',
              [(before,key.upper()+' · primeiro passe') if phase==0 else
               (folder/(key+'_pov.png'),key.upper()+' · refinado')
               for phase in range(2) for key,before in zip('abc',previous)],
              cols=3,thumb=(318,194))
    print('24 PNGs conferidos, 804 x 490, 6 pranchas e comparativo se houver prévias')
