"""Aplica o filtro de EXODUS às cinco vistas de apresentação."""
from pathlib import Path
import sys
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent.parent))
from galeria import board, filter_image

preview='preview' in sys.argv
folder=ROOT/('previa' if preview else 'galeria')
folder.mkdir(exist_ok=True)
names=(('camara','Câmara · primeira pessoa'),('limiar','Depois do pórtico'),
       ('sepulcro','Aproximação do sepulcro'),('gravidades','Teto, parede e escadaria'),
       ('planta','Planta com teto removido'),('geometria','Corte sem materiais'))
files=[]
for key,label in names:
    source=ROOT/('previa' if preview else 'raw')/(key+'.png')
    output=folder/(key+'_filtro.png' if preview else key+'.png')
    with Image.open(source) as raw:
        rgb=raw.convert('RGB')
        if preview:
            rgb=rgb.resize((804,490),Image.Resampling.LANCZOS)
        assert rgb.size==(804,490)
        image=rgb if key=='geometria' else filter_image(rgb)
        assert (ImageChops.difference(image,rgb).getbbox() is not None)==(key!='geometria')
        image.save(output)
    with Image.open(output) as verify:
        verify.verify()
    files.append((output,label))
board(folder/'prancha.png','Ruptura · interior da Necrópole Saturnina',files,2,(388,236))
print('6 PNGs em 804 × 490, 5 filtrados e 1 corte sem materiais')
