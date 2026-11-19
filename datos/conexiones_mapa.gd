class_name ConexionesMapa
extends RefCounted
## Calcula, sin nodos, dónde se abren puertas entre los módulos de un mapa
## personalizado. Lo usan el editor (para mostrar las puertas) y la escena
## jugable (para construirlas), así ambos siempre coinciden.

## Distancia máxima entre dos paredes enfrentadas (hueco o solape) para
## considerarlas contiguas.
const TOLERANCIA_PARED := 1.0
## Largo mínimo de pared compartida para abrir una puerta.
const PASO_MINIMO := 1.5
## Ancho máximo de una puerta generada.
const PASO_MAXIMO := 3.5


## modulos: un Diccionario por módulo con
##   "rect": Rect2 en metros, ya rotado (x, z del mundo)
##   "circular": bool (las salas circulares todavía no reciben puertas)
## Devuelve un Diccionario por puerta con:
##   a, b          índices de los dos módulos
##   dir_a, dir_b  hacia dónde mira la puerta de cada módulo (mundo)
##   punto_a/_b    centro de la puerta sobre la pared de cada módulo (x, z)
##   ancho         ancho de la puerta en metros
##   completa      true si se quita toda la pared (solo con paredes_abiertas)
##   separacion    metros entre ambas paredes (negativo = se solapan)
static func calcular(modulos: Array[Dictionary], paredes_abiertas: bool) -> Array[Dictionary]:
	var conexiones: Array[Dictionary] = []
	for a in modulos.size():
		if modulos[a].circular:
			continue
		for b in range(a + 1, modulos.size()):
			if modulos[b].circular:
				continue
			var ra: Rect2 = modulos[a].rect
			var rb: Rect2 = modulos[b].rect
			var conexion := _conectar_en_x(ra, rb, paredes_abiertas)
			if conexion.is_empty():
				conexion = _conectar_en_z(ra, rb, paredes_abiertas)
			if conexion.is_empty():
				continue
			conexion["a"] = a
			conexion["b"] = b
			conexiones.append(conexion)
	return conexiones


## Pares de módulos cuyos rectángulos se superponen (tocarse no cuenta).
static func pares_solapados(modulos: Array[Dictionary]) -> Array[Vector2i]:
	var pares: Array[Vector2i] = []
	for a in modulos.size():
		for b in range(a + 1, modulos.size()):
			var ra: Rect2 = modulos[a].rect
			var rb: Rect2 = modulos[b].rect
			if ra.intersects(rb, false):
				pares.append(Vector2i(a, b))
	return pares


## Paredes enfrentadas en X: un módulo a la izquierda del otro.
static func _conectar_en_x(ra: Rect2, rb: Rect2, paredes_abiertas: bool) -> Dictionary:
	var a_izquierda := absf(ra.end.x - rb.position.x) <= TOLERANCIA_PARED
	var b_izquierda := absf(rb.end.x - ra.position.x) <= TOLERANCIA_PARED
	if not a_izquierda and not b_izquierda:
		return {}
	var desde := maxf(ra.position.y, rb.position.y)
	var hasta := minf(ra.end.y, rb.end.y)
	if hasta - desde < PASO_MINIMO:
		return {}
	var medio := (desde + hasta) * 0.5
	var dir_a := Direcciones.Dir.ESTE if a_izquierda else Direcciones.Dir.OESTE
	var punto_a := Vector2(ra.end.x if a_izquierda else ra.position.x, medio)
	var punto_b := Vector2(rb.position.x if a_izquierda else rb.end.x, medio)
	var separacion := (rb.position.x - ra.end.x) if a_izquierda else (ra.position.x - rb.end.x)
	var completa := paredes_abiertas and is_equal_approx(ra.size.y, rb.size.y) and is_equal_approx(ra.position.y, rb.position.y)
	return _puerta(dir_a, punto_a, punto_b, hasta - desde, completa, separacion)


## Paredes enfrentadas en Z: un módulo arriba (norte) del otro.
static func _conectar_en_z(ra: Rect2, rb: Rect2, paredes_abiertas: bool) -> Dictionary:
	var a_arriba := absf(ra.end.y - rb.position.y) <= TOLERANCIA_PARED
	var b_arriba := absf(rb.end.y - ra.position.y) <= TOLERANCIA_PARED
	if not a_arriba and not b_arriba:
		return {}
	var desde := maxf(ra.position.x, rb.position.x)
	var hasta := minf(ra.end.x, rb.end.x)
	if hasta - desde < PASO_MINIMO:
		return {}
	var medio := (desde + hasta) * 0.5
	var dir_a := Direcciones.Dir.SUR if a_arriba else Direcciones.Dir.NORTE
	var punto_a := Vector2(medio, ra.end.y if a_arriba else ra.position.y)
	var punto_b := Vector2(medio, rb.position.y if a_arriba else rb.end.y)
	var separacion := (rb.position.y - ra.end.y) if a_arriba else (ra.position.y - rb.end.y)
	var completa := paredes_abiertas and is_equal_approx(ra.size.x, rb.size.x) and is_equal_approx(ra.position.x, rb.position.x)
	return _puerta(dir_a, punto_a, punto_b, hasta - desde, completa, separacion)


static func _puerta(dir_a: Direcciones.Dir, punto_a: Vector2, punto_b: Vector2, largo_compartido: float, completa: bool, separacion: float) -> Dictionary:
	return {
		"dir_a": dir_a,
		"dir_b": Direcciones.opuesta(dir_a),
		"punto_a": punto_a,
		"punto_b": punto_b,
		"ancho": minf(PASO_MAXIMO, largo_compartido),
		"completa": completa,
		"separacion": separacion
	}
