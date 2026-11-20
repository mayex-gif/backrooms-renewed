class_name ConexionesMapa
extends RefCounted
## Calcula, sin nodos, dónde se abren puertas entre los módulos de un mapa
## personalizado. Lo usan el editor (para mostrar y cambiar las conexiones) y la
## escena jugable (para construirlas), así ambos siempre coinciden.

## Distancia máxima entre dos paredes enfrentadas para considerarlas en contacto.
## Las salas separadas por un hueco NO se conectan: hay que pegarlas.
const TOLERANCIA_PARED := 0.01
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
##   "poligono": vértices de la huella en coordenadas de mundo X/Z.
##   Si falta, centro, ancho, largo y angulo describen un rectángulo.
##   "id": int estable del módulo (opcional; si falta se usa su posición en la lista)
## estados: clave de la conexión (ver clave_de) -> estado elegido a mano. Sin
##   elección, una conexión es una puerta.
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
static func calcular(modulos: Array[Dictionary], estados: Dictionary = {}) -> Array[Dictionary]:
	var conexiones: Array[Dictionary] = []
	for a in modulos.size():
		for b in range(a + 1, modulos.size()):
			var conexion := _conectar_geometria(modulos[a], modulos[b])
			if conexion.is_empty():
				continue
			var clave := clave_de(_id_de(modulos, a), _id_de(modulos, b))
			conexion["a"] = a
			conexion["b"] = b
			conexion["clave"] = clave
			_aplicar_estado(conexion, String(estados.get(clave, "")))
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
			if _se_solapan(modulos[a], modulos[b]):
				pares.append(Vector2i(a, b))
	return pares

static func _se_solapan(a: Dictionary, b: Dictionary) -> bool:
	var va := _vertices_modulo(a)
	var vb := _vertices_modulo(b)
	for puntos in [va, vb]:
		for i in puntos.size():
			var eje: Vector2 = (puntos[(i + 1) % puntos.size()] - puntos[i]).orthogonal().normalized()
			var min_a := va[0].dot(eje)
			var max_a := min_a
			var min_b := vb[0].dot(eje)
			var max_b := min_b
			for p in va:
				min_a = minf(min_a, p.dot(eje))
				max_a = maxf(max_a, p.dot(eje))
			for p in vb:
				min_b = minf(min_b, p.dot(eje))
				max_b = maxf(max_b, p.dot(eje))
			if max_a <= min_b + 0.001 or max_b <= min_a + 0.001:
				return false
	return true

static func _conectar_geometria(a: Dictionary, b: Dictionary) -> Dictionary:
	var va := _vertices_modulo(a)
	var vb := _vertices_modulo(b)
	for lado_a in va.size():
		var inicio_a: Vector2 = va[lado_a]
		var fin_a: Vector2 = va[(lado_a + 1) % va.size()]
		var eje_a := (fin_a - inicio_a).normalized()
		var normal_a := Vector2(eje_a.y, -eje_a.x)
		for lado_b in vb.size():
			var inicio_b: Vector2 = vb[lado_b]
			var fin_b: Vector2 = vb[(lado_b + 1) % vb.size()]
			var eje_b := (fin_b - inicio_b).normalized()
			if eje_a.dot(eje_b) > -0.999:
				continue
			var separacion := (inicio_b - inicio_a).dot(normal_a)
			if separacion < -TOLERANCIA_PARED or separacion > TOLERANCIA_PARED:
				continue
			var desde := maxf(minf(inicio_a.dot(eje_a), fin_a.dot(eje_a)), minf(inicio_b.dot(eje_a), fin_b.dot(eje_a)))
			var hasta := minf(maxf(inicio_a.dot(eje_a), fin_a.dot(eje_a)), maxf(inicio_b.dot(eje_a), fin_b.dot(eje_a)))
			if hasta - desde < PASO_MINIMO:
				continue
			var punto_a := _punto_en_eje(inicio_a, eje_a, desde, normal_a, 0.0)
			var punto_b := _punto_en_eje(inicio_b, eje_a, desde, normal_a, 0.0)
			var min_a := minf(inicio_a.dot(eje_a), fin_a.dot(eje_a))
			var max_a := maxf(inicio_a.dot(eje_a), fin_a.dot(eje_a))
			var min_b := minf(inicio_b.dot(eje_a), fin_b.dot(eje_a))
			var max_b := maxf(inicio_b.dot(eje_a), fin_b.dot(eje_a))
			var a_alineada := absf(min_a - min_b) <= 0.001 and absf(max_a - max_b) <= 0.001 and absf(separacion) <= 0.001
			return _conexion_base(a, b, punto_a + eje_a * ((hasta - desde) * 0.5), punto_b + eje_a * ((hasta - desde) * 0.5), hasta - desde, normal_a, lado_a, lado_b, a_alineada, separacion)
	return {}

static func _conexion_base(modulo_a: Dictionary, modulo_b: Dictionary, punto_a: Vector2, punto_b: Vector2, largo: float, normal: Vector2, lado_a: int, lado_b: int, alineada: bool, separacion: float) -> Dictionary:
	var angulo := atan2(normal.x, -normal.y)
	return {"dir_a": _direccion_lado(lado_a), "dir_b": _direccion_lado(lado_b), "punto_a": punto_a, "punto_b": punto_b, "largo": largo, "ancho": minf(PASO_MAXIMO, largo), "alineada": alineada, "separacion": separacion, "lado_a": lado_a, "lado_b": lado_b, "arista_a": lado_a, "arista_b": lado_b, "normal_a": normal, "tangente": Vector2(-normal.y, normal.x), "angulo_a": angulo}

static func _vertices_modulo(modulo: Dictionary) -> Array[Vector2]:
	var poligono: Variant = modulo.get("poligono", PackedVector2Array())
	if poligono is PackedVector2Array and poligono.size() >= 3:
		var puntos_poligono: Array[Vector2] = []
		for punto in poligono:
			puntos_poligono.append(punto)
		return puntos_poligono
	var rect: Rect2 = modulo.get("rect", Rect2())
	var centro: Vector2 = modulo.get("centro", rect.get_center())
	var medio := Vector2(float(modulo.get("ancho", rect.size.x)), float(modulo.get("largo", rect.size.y))) * 0.5
	var angulo := float(modulo.get("angulo", 0.0))
	var puntos: Array[Vector2] = []
	for local in [Vector2(-medio.x, -medio.y), Vector2(medio.x, -medio.y), Vector2(medio.x, medio.y), Vector2(-medio.x, medio.y)]:
		puntos.append(centro + local.rotated(angulo))
	return puntos

static func _direccion_lado(lado: int) -> Direcciones.Dir:
	return [Direcciones.Dir.NORTE, Direcciones.Dir.ESTE, Direcciones.Dir.SUR, Direcciones.Dir.OESTE][posmod(lado, 4)] as Direcciones.Dir

static func _punto_en_eje(origen: Vector2, eje: Vector2, proyeccion: float, normal: Vector2, distancia: float) -> Vector2:
	return origen + eje * (proyeccion - origen.dot(eje)) + normal * distancia


static func _id_de(modulos: Array[Dictionary], indice: int) -> int:
	return int(modulos[indice].get("id", indice))


## Decide el estado efectivo y, a partir de él, el ancho y si se quita toda la pared.
static func _aplicar_estado(conexion: Dictionary, manual: String) -> void:
	var alineada: bool = conexion.alineada
	var largo: float = conexion.largo
	var es_manual := ESTADOS.has(manual)
	var estado := manual
	if not es_manual:
		estado = ESTADO_PUERTA
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
