"""Reorganiza as mesmas 55 salas e ligações do estudo ampliado."""
from collections import deque
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent/'expansao'))
from mapa_expandido import ZONES,CELL,LETTERS,axis,adjacent,path_between

OFFSETS=(
    ((0,-2,2),(0,0,1,-2)),
    ((2,0,-2),(2,-1,1,-2)),
    ((-1,2,0),(-2,1,0,2)),
    ((1,-2,2),(1,-2,2,0)),
    ((0,2,-1),(-2,0,2,-1)),
)


def key(zone,room):
    return zone.roman+'-'+room


def center(index,zone,room):
    col=LETTERS.index(room)%4
    row=LETTERS.index(room)//4
    x,y=zone.center(room)
    row_shifts,col_shifts=OFFSETS[index]
    if index==0 and room=='B':
        return x,y
    return x+row_shifts[row],y+col_shifts[col]


def shape(index,zone,room):
    cx,cy=center(index,zone,room)
    serial=LETTERS.index(room)
    rx,ry=zone.sizes(room)
    west=rx-(serial%4==0 and rx>2)
    east=rx-(serial%4==2 and rx>2)
    north=ry+(serial%5==3 and ry<3)
    south=ry-(serial%4==1 and ry>2)
    tiles={(x,y) for x in range(-west,east+1) for y in range(-south,north+1)}
    if index in (0,3,4):
        trim=(1,1,2,2,2)[index]
        tiles={ (x,y) for x,y in tiles
               if not (abs(x)>=2 and abs(y)>=2 and abs(x)+abs(y)>rx+ry-trim) }
    if index in (1,2):
        wing=1 if serial%2==0 else -1
        tiles -= {(x,y) for x,y in tiles if x*wing>=max(2,rx-1) and y<=-max(2,ry-1)}
    if index==2 and room in zone.landmarks:
        tiles |= {(rx+1,0),(rx+1,1)}
    return {(cx+x,cy+y) for x,y in tiles}


def polyline(points):
    result=set()
    for a,b in zip(points,points[1:]):
        if a!=b:
            result.update(axis(a,b))
    return result


def route(a,b,horizontal,offset):
    wx,wy=a
    ex,ey=b
    if horizontal:
        x=(wx+ex)//2+offset
        return polyline((a,(x,wy),(x,ey),b))
    y=(wy+ey)//2+offset
    return polyline((a,(wx,y),(ex,y),b))


def recesses(rooms,centers,occupied,used):
    # Nichos crescem só ao longo da parede da própria sala, longe dos corredores.
    directions=((0,-1),(-1,0),(0,1),(1,0))
    for index,(name,tiles) in enumerate(rooms.items()):
        x,y=centers[name]
        for pass_number in range(2):
            for try_number in range(4):
                dx,dy=directions[(index+try_number+pass_number*2)%4]
                front=max((rx-x)*dx+(ry-y)*dy for rx,ry in tiles)
                p=(x+dx*front,y+dy*front)
                strip={(p[0]+dx+t*dy,p[1]+dy-t*dx) for t in (-1,0,1)}
                border={n for cell in strip for n in adjacent(cell)}
                seen_rooms={occupied[n] for n in border if n in occupied}
                if strip&(used|occupied.keys()) or border&used or seen_rooms!={name}:
                    continue
                tiles.update(strip)
                occupied.update({cell:name for cell in strip})
                break


def design():
    centers={key(zone,r):center(i,zone,r) for i,zone in enumerate(ZONES) for r in zone.rooms}
    rooms={key(zone,r):shape(i,zone,r) for i,zone in enumerate(ZONES) for r in zone.rooms}
    occupied={}
    for name,tiles in rooms.items():
        for tile in tiles:
            assert tile not in occupied,(name,occupied.get(tile),tile)
            occupied[tile]=name
    connections=[]
    for zone in ZONES:
        for a,b in zone.links():
            horizontal=LETTERS.index(a)//4==LETTERS.index(b)//4
            connections.append((key(zone,a),key(zone,b),horizontal))
    for a,b in zip(ZONES,ZONES[1:]):
        connections.append((key(a,a.spine[-1]),key(b,b.spine[0]),False))
    corridors={}
    used=set()
    for left,right,horizontal in connections:
        ends={left,right}
        for offset in (0,-1,1,-2,2,-3,3):
            strand=route(centers[left],centers[right],horizontal,offset)
            foreign={occupied[t] for t in strand if t in occupied}-ends
            hall=strand-rooms[left]-rooms[right]
            if foreign or not hall or hall&used:
                continue
            border={n for t in hall for n in adjacent(t)}
            if border&used or {occupied[t] for t in border if t in occupied}!=ends:
                continue
            seen=set(path_between(hall,next(iter(hall)),(9999,9999))[1])
            if seen!=hall:
                continue
            corridors[left,right]=hall
            used.update(hall)
            break
        else:
            raise ValueError((left,right,centers[left],centers[right]))
    recesses(rooms,centers,occupied,used)
    return centers,rooms,corridors


def endpoints():
    return 'I-B','V-K'


def metrics():
    centers,rooms,corridors=design()
    grid=set().union(*rooms.values(),*corridors.values())
    a,b=endpoints()
    shortest,_=path_between(grid,centers[a],centers[b])
    _,reachable=path_between(grid,centers[a],(9999,9999))
    assert len(reachable)==len(grid)
    assert all(sum(1 for name in rooms if name.split('-')[0]==zone.roman)==11 for zone in ZONES)
    assert len(corridors)==67
    assert 'I-F' in rooms and not path_between(grid-rooms['I-F'],centers[a],centers[b])[0]
    assert all(all(t not in second for n in first for t in adjacent(n))
               for i,first in enumerate(rooms.values()) for second in list(rooms.values())[i+1:])
    assert len(shortest)>=250
    return {'salas':len(rooms),'salas_por_zona':[11]*5,'ligacoes':len(corridors),
            'circuitos_independentes':len(corridors)-len(rooms)+1,'celulas':len(grid),
            'menor_trajeto_celulas':len(shortest),'ruptura_obrigatoria':True}


if __name__=='__main__':
    print(metrics())
