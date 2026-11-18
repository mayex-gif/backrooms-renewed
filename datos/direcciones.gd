class_name Direcciones
extends RefCounted
## Utilidades de direcciones y grilla. No usa nodos: es solo matemática.
##
## Convención de Godot (vista desde arriba):
##   NORTE = -Z, SUR = +Z, ESTE = +X, OESTE = -X
## "Giro" = un giro de 90° en sentido horario visto desde arriba.
## Orden de las direcciones: NORTE -> ESTE -> SUR -> OESTE (cada giro avanza una).

enum Dir { NORTE, ESTE, SUR, OESTE }

## Tamaño de cada celda de la grilla, en metros.
const TAMANO_CELDA: float = 0.5


## Dirección contraria (NORTE <-> SUR, ESTE <-> OESTE).
static func opuesta(d: Dir) -> Dir:
	return posmod(d + 2, 4) as Dir


## Dirección resultante de girar "giros" veces 90° en sentido horario.
static func girar(d: Dir, giros: int) -> Dir:
	return posmod(d + giros, 4) as Dir


## Vector de grilla (x, z) que apunta en esa dirección.
static func vector(d: Dir) -> Vector2i:
	match d:
		Dir.NORTE:
			return Vector2i(0, -1)
		Dir.ESTE:
			return Vector2i(1, 0)
		Dir.SUR:
			return Vector2i(0, 1)
		_:
			return Vector2i(-1, 0)


## Rota un punto en metros "giros" veces 90° horario alrededor del origen.
## Un giro horario transforma (x, z) en (-z, x): NORTE(0,-1) -> ESTE(1,0).
static func rotar_punto(p: Vector3, giros: int) -> Vector3:
	var r: Vector3 = p
	for i in posmod(giros, 4):
		r = Vector3(-r.z, r.y, r.x)
	return r


## Rota una CELDA "giros" veces 90° horario alrededor del origen.
## La celda (i, j) cubre el cuadrado [i, i+1) x [j, j+1) (esquina mínima en
## (i, j)). Al girar el cuadrado, su nueva esquina mínima es (-j-1, i).
static func rotar_celda(c: Vector2i, giros: int) -> Vector2i:
	var r: Vector2i = c
	for i in posmod(giros, 4):
		r = Vector2i(-r.y - 1, r.x)
	return r


## Celda que contiene a un punto del mundo (en metros).
static func celda_de_punto(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TAMANO_CELDA), floori(p.z / TAMANO_CELDA))
