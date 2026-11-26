"""Células e percurso de referência para a maquete das cinco zonas."""

CELL = 4.0

ZONES = (
    ('I', 'Pórtico dos Que Desistiram', 0, 7, (0, 2)),
    ('II', 'Avenida Sepulcral', 8, 20, (0, 11)),
    ('III', 'Claustro da Melancolia', 21, 30, (0, 23)),
    ('IV', 'Ossuário dos Astrônomos', 31, 41, (4, 34)),
    ('V', 'Sepulcro do Sétimo Peso', 42, 54, (4, 46)),
)


def rect(x0, x1, y0, y1):
    return {(x,y) for x in range(x0,x1+1) for y in range(y0,y1+1)}


def octagon(cx, cy, width):
    return {(x+cx,y+cy) for x in range(-width,width+1) for y in range(-width,width+1)
            if abs(x)+abs(y)<=width+width//2}


def layout():
    return (
        rect(-3,3,0,3)|rect(-2,2,4,5)|rect(0,0,6,7),
        rect(-1,1,8,20)|rect(-4,4,10,10)|rect(-4,4,17,17)|
        rect(-4,-4,10,17)|rect(4,4,10,17)|rect(-5,-4,12,13)|rect(4,5,14,15),
        rect(0,0,21,21)|rect(-4,4,22,27)|rect(-2,4,28,28)|rect(4,4,29,30),
        rect(4,4,31,32)|octagon(4,36,4)|rect(4,4,40,41)|rect(-1,0,36,36)|rect(8,9,36,36),
        rect(4,4,42,43)|octagon(4,49,5),
    )


def neighbors(cell):
    x,y=cell
    return ((x-1,y),(x+1,y),(x,y-1),(x,y+1))


def main_route():
    return ([(0,y) for y in range(28)] + [(x,27) for x in range(1,5)] +
            [(4,y) for y in range(28,50)])


def audit_layout(zones):
    cells=set().union(*zones)
    assert sum(map(len,zones))==len(cells)
    route=main_route()
    assert all(cell in cells for cell in route)
    assert all(b in neighbors(a) for a,b in zip(route,route[1:]))
    assert {i for i,zone in enumerate(zones) if any(c in zone for c in route)}==set(range(5))
    visited={route[0]}
    pending=[route[0]]
    while pending:
        for nxt in neighbors(pending.pop()):
            if nxt in cells and nxt not in visited:
                visited.add(nxt)
                pending.append(nxt)
    assert visited==cells
    for side in (-4,4):
        loop=([(x,10) for x in range(min(0,side),max(0,side)+1)] +
              [(side,y) for y in range(11,17)] +
              [(x,17) for x in range(min(0,side),max(0,side)+1)] +
              [(0,y) for y in range(11,17)])
        assert all(cell in zones[1] for cell in loop)
    return {'celulas':len(cells),'por_zona':[len(z) for z in zones],
            'celulas_da_rota_principal':len(route),'lacos_laterais_na_avenida':2}
