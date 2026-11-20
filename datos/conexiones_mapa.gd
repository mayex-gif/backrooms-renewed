class_name ConexionesMapa
extends RefCounted
## Calcula, sin nodos, dónde se abren puertas entre los módulos de un mapa
## personalizado. Lo usan el editor (para mostrar y cambiar las conexiones) y la
## escena jugable (para construirlas), así ambos siempre coinciden.

## Distancia máxima entre dos paredes enfrentadas (hueco o solape) para
## considerarlas contiguas.
const TOLERANCIA_PARED := 1.0
## Largo mínimo de pared compartida para abrir una puerta.
const PASO_MINIMO := 1.5
## Ancho máximo de una puerta común.
const PASO_MAXIMO := 3.5

## Estados posibles de una conexión entre dos módulos contiguos.
## puerta:  un hueco de hasta PASO_MAXIMO centrado en el tramo compartido.
## abierta: quita el tramo compartido bajo el dintel.
## interseccion: elimina el tramo compartido de pared de piso a techo.
## cerrada: pared completa, sin paso.
const ESTADO_PUERTA := "puerta"
const ESTADO_ABIERTA := "abierta"
const ESTADO_INTERSECCION := "interseccion"
const ESTADO_CERRADA := "cerrada"
const ESTADOS := [ESTADO_PUERTA, ESTADO_ABIERTA, ESTADO_CERRADA, ESTADO_INTERSECCION]


## modulos: un Diccionario por módulo con
##   "rect": Rect2 en metros, ya rotado (x, z del mundo)
##   "circular": bool (las salas circulares todavía no reciben puertas)
##   "id": int estable del módulo (opcional; si falta se usa su posición en la lista)
## paredes_abiertas: regla por defecto. Las paredes enteras idénticas y alineadas
##   se abren, salvo que la conexión tenga un estado elegido a mano.
## estados: clave de la conexión (ver clave_de) -> estado elegido a mano.
## Devuelve un Diccionario por conexión (incluidas las cerradas) con:
##   a, b          índices de los dos módulos
##   clave         identifica el par por los ids de sus módulos
##   dir_a, dir_b  hacia dónde mira la puerta de cada módulo (mundo)
##   punto_a/_b    centro de la puerta sobre la pared de cada módulo (x, z)
##   largo         metros de pared compartida
##   alineada      true si las dos paredes coinciden exactamente
##   estado        estado efectivo (puerta / abierta / cerrada / interseccion)
##   manual        true si el estado lo eligió el usuario
##   ancho         ancho de la abertura en metros
##   completa      true si se quita toda la pared
##   sin_dintel    true si la abertura llega hasta el techo
##   separacion    metros entre ambas paredes (negativo = se solapan)
static func calcular(modulos: Array[Dictionary], paredes_abiertas: bool, estados: Dictionary = {}) -> Array[Dictionary]:
	var conexiones: Array[Dictionary] = []
	for a in modulos.size():
		if modulos[a].circular:
			continue
		for b in range(a + 1, modulos.size()):
			if modulos[b].circular:
				continue
			var ra: Rect2 = modulos[a].rect
			var rb: Rect2 = modulos[b].rect
			var solape_x := minf(ra.end.x, rb.end.x) - maxf(ra.position.x, rb.position.x)
			var solape_z := minf(ra.end.y, rb.end.y) - maxf(ra.position.y, rb.position.y)
			if solape_x > 0.001 and solape_z > 0.001:
				continue
			var conexion := _conectar_en_x(ra, rb)
			if conexion.is_empty():
				conexion = _conectar_en_z(ra, rb)
			if conexion.is_empty():
				continue
			var clave := clave_de(_id_de(modulos, a), _id_de(modulos, b))
			conexion["a"] = a
			conexion["b"] = b
			conexion["clave"] = clave
			_aplicar_estado(conexion, paredes_abiertas, String(estados.get(clave, "")))
			conexiones.append(conexion)
	return conexiones


## Solo las conexiones por las que hay que construir algo (sin las cerradas).
static func activas(conexiones: Array[Dictionary]) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for conexion in conexiones:
		if conexion.estado != ESTADO_CERRADA:
			resultado.append(conexion)
	return resultado


## Clave estable de un par de módulos; no depende del orden en que se nombren.
static func clave_de(id_a: int, id_b: int) -> String:
	return "%d:%d" % [mini(id_a, id_b), maxi(id_a, id_b)]


## Estado que sigue al actual al hacer click.
static func siguiente_estado(estado: String) -> String:
	if estado == ESTADO_PUERTA:
		return ESTADO_ABIERTA
	if estado == ESTADO_ABIERTA:
		return ESTADO_CERRADA
	if estado == ESTADO_CERRADA:
		return ESTADO_INTERSECCION
	return ESTADO_PUERTA


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


static func _id_de(modulos: Array[Dictionary], indice: int) -> int:
	return int(modulos[indice].get("id", indice))


## Decide el estado efectivo y, a partir de él, el ancho y si se quita toda la pared.
static func _aplicar_estado(conexion: Dictionary, paredes_abiertas: bool, manual: String) -> void:
	var alineada: bool = conexion.alineada
	var largo: float = conexion.largo
	var es_manual := ESTADOS.has(manual)
	var estado := manual
	if not es_manual:
		estado = ESTADO_INTERSECCION if (paredes_abiertas and alineada) else ESTADO_PUERTA
	conexion["estado"] = estado
	conexion["manual"] = es_manual
	conexion["sin_dintel"] = estado == ESTADO_INTERSECCION
	conexion["completa"] = estado == ESTADO_INTERSECCION and alineada
	# La intersección elimina todo el tramo compartido de pared.
	conexion["ancho"] = largo if estado == ESTADO_INTERSECCION or estado == ESTADO_ABIERTA else minf(PASO_MAXIMO, largo)


## Paredes enfrentadas en X: un módulo a la izquierda del otro.
static func _conectar_en_x(ra: Rect2, rb: Rect2) -> Dictionary:
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
	var alineada := is_equal_approx(ra.size.y, rb.size.y) and is_equal_approx(ra.position.y, rb.position.y)
	return _base(dir_a, punto_a, punto_b, hasta - desde, alineada, separacion)


## Paredes enfrentadas en Z: un módulo arriba (norte) del otro.
static func _conectar_en_z(ra: Rect2, rb: Rect2) -> Dictionary:
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
	var alineada := is_equal_approx(ra.size.x, rb.size.x) and is_equal_approx(ra.position.x, rb.position.x)
	return _base(dir_a, punto_a, punto_b, hasta - desde, alineada, separacion)


static func _base(dir_a: Direcciones.Dir, punto_a: Vector2, punto_b: Vector2, largo: float, alineada: bool, separacion: float) -> Dictionary:
	return {
		"dir_a": dir_a,
		"dir_b": Direcciones.opuesta(dir_a),
		"punto_a": punto_a,
		"punto_b": punto_b,
		"largo": largo,
		"alineada": alineada,
		"separacion": separacion
	}
