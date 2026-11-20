class_name PlanificadorSolapes
extends RefCounted
## Planifica intersecciones y paredes interiores a partir de huellas convexas.

const EPSILON := 0.001

## Cada par contiene las piezas poligonales de su intersección. Los segmentos
## dividen cada arista allí donde cruza otra huella; sus estados son estables
## mientras no cambie la forma del mapa.
static func calcular(modulos: Array[Dictionary], estados: Dictionary = {}) -> Dictionary:
	var pares: Array[Dictionary] = []
	for a in modulos.size():
		for b in range(a + 1, modulos.size()):
			var poligonos := GeometriaHuella.intersecciones(_poligono(modulos[a]), _poligono(modulos[b]))
			if not poligonos.is_empty():
				pares.append({"a": a, "b": b, "poligonos": poligonos})
	var segmentos: Array[Dictionary] = []
	var ocultos: Array[Dictionary] = []
	for indice in modulos.size():
		var huella := _poligono(modulos[indice])
		for arista in huella.size():
			var inicio := huella[arista]
			var fin := huella[(arista + 1) % huella.size()]
			var cortes: Array[float] = [0.0, 1.0]
			for otro_indice in modulos.size():
				if otro_indice == indice:
					continue
				var otra := _poligono(modulos[otro_indice])
				for otra_arista in otra.size():
					cortes.append_array(_parametros_cruce(inicio, fin, otra[otra_arista], otra[(otra_arista + 1) % otra.size()]))
			cortes.sort()
			var unicos: Array[float] = []
			for corte in cortes:
				var t := clampf(corte, 0.0, 1.0)
				if unicos.is_empty() or absf(t - unicos[-1]) > EPSILON:
					unicos.append(t)
			for corte_indice in range(unicos.size() - 1):
				var desde: float = unicos[corte_indice]
				var hasta: float = unicos[corte_indice + 1]
				if (hasta - desde) * inicio.distance_to(fin) <= EPSILON:
					continue
				var p0 := inicio.lerp(fin, desde)
				var p1 := inicio.lerp(fin, hasta)
				var medio := (p0 + p1) * 0.5
				var pares_internos: Array[int] = []
				var duplicada := false
				var vecinos_duplicados: Array[int] = []
				for otro_indice in modulos.size():
					if otro_indice == indice:
						continue
					var otra := _poligono(modulos[otro_indice])
					if GeometriaHuella.contiene(otra, medio, false):
						pares_internos.append(otro_indice)
					elif otro_indice < indice and _sobre_borde(otra, medio):
						duplicada = true
						vecinos_duplicados.append(otro_indice)
				if not pares_internos.is_empty():
					var clave := _clave_segmento(modulos, indice, arista, desde, hasta, inicio.distance_to(fin))
					var valor_estado: Variant = estados.get(clave, ConexionesMapa.ESTADO_CERRADA)
					var estado := String(valor_estado) if valor_estado is String else (ConexionesMapa.ESTADO_INTERSECCION if bool(valor_estado) else ConexionesMapa.ESTADO_CERRADA)
					segmentos.append({"modulo": indice, "arista": arista, "direccion": arista, "inicio": p0, "fin": p1, "clave": clave, "estado": estado, "abierta": estado == ConexionesMapa.ESTADO_ABIERTA or estado == ConexionesMapa.ESTADO_INTERSECCION, "pares": pares_internos})
				elif duplicada:
					ocultos.append({"modulo": indice, "arista": arista, "inicio": p0, "fin": p1, "estado": ConexionesMapa.ESTADO_INTERSECCION, "pares": vecinos_duplicados})
	return {"pares": pares, "segmentos": segmentos, "ocultos": ocultos}

static func siguiente_estado(estado: String) -> String:
	return ConexionesMapa.siguiente_estado(estado)

## Limita la abertura a la altura máxima del espacio conectado. Si la sala del
## otro lado es más alta, la pared de este módulo puede abrirse hasta su techo.
static func altura_abertura_interseccion(alto_modulo: float, techos_vecinos: Array[float]) -> float:
	if techos_vecinos.is_empty():
		return alto_modulo
	var techo_vecino := 0.0
	for altura in techos_vecinos:
		techo_vecino = maxf(techo_vecino, altura)
	return minf(alto_modulo, techo_vecino)

## La parte de una superficie compartida la aporta la primera sala del mapa.
## Para techos gana la cota mayor; a igual cota también gana la primera.
static func indice_techo_a_recortar(alto_a: float, alto_b: float, indice_a: int, indice_b: int) -> int:
	if alto_a >= alto_b - EPSILON:
		return indice_b
	return indice_a

static func _poligono(modulo: Dictionary) -> PackedVector2Array:
	var poligono: Variant = modulo.get("poligono", PackedVector2Array())
	if poligono is PackedVector2Array and poligono.size() >= 3:
		return GeometriaHuella.normalizar(poligono)
	var rect: Rect2 = modulo.get("rect", Rect2())
	var puntos := GeometriaHuella.rectangulo(rect.size.x, rect.size.y)
	for indice in puntos.size():
		puntos[indice] += rect.position
	return puntos

static func _sobre_borde(poligono: PackedVector2Array, punto: Vector2) -> bool:
	for indice in poligono.size():
		if Geometry2D.get_closest_point_to_segment(punto, poligono[indice], poligono[(indice + 1) % poligono.size()]).distance_to(punto) <= EPSILON:
			return true
	return false

static func _parametros_cruce(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Array[float]:
	var resultado: Array[float] = []
	var r := b - a
	var s := d - c
	var denominador := _cruz(r, s)
	var ca := c - a
	if absf(denominador) > EPSILON:
		var t := _cruz(ca, s) / denominador
		var u := _cruz(ca, r) / denominador
		if t >= -EPSILON and t <= 1.0 + EPSILON and u >= -EPSILON and u <= 1.0 + EPSILON:
			resultado.append(clampf(t, 0.0, 1.0))
	elif absf(_cruz(ca, r)) <= EPSILON and r.length_squared() > EPSILON:
		resultado.append(clampf((c - a).dot(r) / r.length_squared(), 0.0, 1.0))
		resultado.append(clampf((d - a).dot(r) / r.length_squared(), 0.0, 1.0))
	return resultado

static func _cruz(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

static func _clave_segmento(modulos: Array[Dictionary], indice: int, arista: int, desde: float, hasta: float, longitud: float) -> String:
	var id := int(modulos[indice].get("id", indice))
	var inicio_cm := roundi(desde * longitud * 100.0)
	var fin_cm := roundi(hasta * longitud * 100.0)
	return "%d:%d:%d:%d" % [id, arista, inicio_cm, fin_cm]
