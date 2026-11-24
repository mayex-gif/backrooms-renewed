extends RefCounted
## Rejilla del cielorraso (placas de 1,5 m).
## Está anclada al mundo: los bordes de las placas caen en múltiplos de 1,5 m,
## de modo que las vigas, placas y luces de salas e intersecciones coinciden
## de forma continua sin desfasarse entre sí. Si la sala está girada un ángulo
## que no es múltiplo de 90° se centra en la huella local.

const TAMANO := 1.5
const TOLERANCIA := 0.0005

## limites: rectángulo de la huella en coordenadas locales de la sala.
## origen: posición en el mundo (x, z) del origen local de la sala.
## eje_x / eje_z: direcciones en el mundo (x, z) de los ejes locales X y Z.
## Devuelve {"origen": Vector2 local de la esquina de la rejilla, "columnas": int, "filas": int}.
static func calcular(limites: Rect2, origen: Vector2 = Vector2.ZERO, eje_x: Vector2 = Vector2.RIGHT, eje_z: Vector2 = Vector2.DOWN) -> Dictionary:
	if _alineado(eje_x) and _alineado(eje_z):
		var x := _eje(limites.position.x, limites.end.x, origen, eje_x)
		var z := _eje(limites.position.y, limites.end.y, origen, eje_z)
		return {"origen": Vector2(x.x, z.x), "columnas": int(x.y), "filas": int(z.y)}
	var columnas := maxi(1, ceili(limites.size.x / TAMANO))
	var filas := maxi(1, ceili(limites.size.y / TAMANO))
	return {
		"origen": limites.position + (limites.size - Vector2(columnas, filas) * TAMANO) * 0.5,
		"columnas": columnas,
		"filas": filas,
	}


## Índice de placa en la rejilla del mundo, para decidir dónde van las luces.
static func indice_mundo(coordenada: float) -> int:
	return roundi((coordenada - TAMANO * 0.5) / TAMANO)


static func _alineado(eje: Vector2) -> bool:
	return maxf(absf(eje.x), absf(eje.y)) > 0.9999


## Devuelve Vector2(inicio_local, cantidad) para un eje coordinado con el mundo.
static func _eje(minimo: float, maximo: float, origen: Vector2, eje: Vector2) -> Vector2:
	var componente := origen.x if absf(eje.x) > 0.5 else origen.y
	var signo := signf(eje.x) if absf(eje.x) > 0.5 else signf(eje.y)
	var desfase := posmod(-signo * componente, TAMANO)
	var inicio := floorf((minimo - desfase + TOLERANCIA) / TAMANO) * TAMANO + desfase
	var cantidad := maxi(1, ceili((maximo - inicio - TOLERANCIA) / TAMANO))
	return Vector2(inicio, float(cantidad))

