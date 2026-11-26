"""Mostra as vistas da Ruptura com a mesma LUT dos estudos anteriores."""
from pathlib import Path
import sys
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from galeria import board, filter_image

VIEWS=(
    ('exploracao','Exploração'),('margem','Na margem'),('fenda','Fenda e escada'),
    ('geral','Vista geral'),('planta','Planta'),('geometria','Sem materiais'),
    ('rua_invertida','Rua invertida'),
)

preview='preview' in sys.argv
folder=ROOT/('previa' if preview else 'galeria')
folder.mkdir(exist_ok=True)
for key,_ in VIEWS:
    source=ROOT/('previa' if preview else 'raw')/(key+'.png')
    with Image.open(source) as raw:
        if preview:
            raw=raw.resize((804,490),Image.Resampling.LANCZOS)
        assert raw.size==(804,490)
        image=raw.convert('RGB') if key=='geometria' else filter_image(raw)
        assert (ImageChops.difference(image,raw.convert('RGB')).getbbox() is not None)==(key!='geometria')
        edited=folder/(key+'_filtro.png' if preview else key+'.png')
        image.save(edited)
    with Image.open(edited) as verified:
        verified.verify()

def select(key):
    return folder/(key+'_filtro.png' if preview else key+'.png')

if preview:
    board(folder/'prancha.png','Ruptura · conferência de enquadramento',
          [(select(key),label) for key,label in VIEWS],3,(303,185))
else:
    board(ROOT/'prancha.png','Necrópole Saturnina · Ruptura',
          [(select(key),label) for key,label in VIEWS],2,(388,236))
    board(ROOT/'planta_e_geometria.png','Fenda, percurso e arquitetura invertida',
          [(select(key),label) for key,label in VIEWS if key in {'planta','geometria'}],2,(392,239))
print('7 imagens verificadas · 6 filtradas e 1 sem materiais')
