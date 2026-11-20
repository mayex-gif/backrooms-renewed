class_name PlanificadorSolapes
extends RefCounted
## Geometría de zonas superpuestas, paredes interiores y propiedad de superficies.

const EPSILON := 0.001

## Devuelve pares y segmentos de pared que quedan dentro de otra sala.
## Cada segmento se puede abrir de forma independiente mediante su clave estable.
static func calcular(modulos: Array[Dictionary], estados: Dictionary = {}) -> Dictionary:
	var pares: Array[Dictionary] = []
	for a in modulos.size():
		for b in range(a + 1, modulos.size()):
			if bool(modulos[a].get("circular", false)) or bool(modulos[b].get("circular", false)):
				continue
			var rect_a: Rect2 = modulos[a].rect
			var rect_b: Rect2 = modulos[b].rect
			var area := _interseccion(rect_a, rect_b)
			if area.size.x > EPSILON and area.size.y > EPSILON:
				pares.append({"a": a, "b": b, "rect": area})
	var segmentos: Array[Dictionary] = []
	var ocultos: Array[Dictionary] = []
	for indice in modulos.size():
		var rect: Rect2 = modulos[indice].rect
		for direccion in range(4):
			var lateral_horizontal := direccion == Direcciones.Dir.NORTE or direccion == Direcciones.Dir.SUR
			var fijo := _coordenada_fija(rect, direccion)
			var desde := rect.position.x if lateral_horizontal else rect.position.y
			var hasta := rect.end.x if lateral_horizontal else rect.end.y
			var cortes: Array[float] = [desde, hasta]
			for par in pares:
				var otro_indice := int(par.b) if int(par.a) == indice else (int(par.a) if int(par.b) == indice else -1)
				if otro_indice < 0:
					continue
				var otro: Rect2 = modulos[otro_indice].rect
				if _dentro_de_otro(fijo, direccion, otro):
					var tramo := _rango_lateral(desde, hasta, otro, lateral_horizontal)
					if tramo.y - tramo.x > EPSILON:
						cortes.append(tramo.x)
						cortes.append(tramo.y)
				elif _pared_coincide(fijo, direccion, otro):
					var tramo := _rango_lateral(desde, hasta, otro, lateral_horizontal)
					if tramo.y - tramo.x > EPSILON:
						cortes.append(tramo.x)
						cortes.append(tramo.y)
			cortes.sort()
			for corte_indice in range(cortes.size() - 1):
				var tramo_desde: float = cortes[corte_indice]
				var tramo_hasta: float = cortes[corte_indice + 1]
				if tramo_hasta - tramo_desde <= EPSILON:
					continue
				var medio := (tramo_desde + tramo_hasta) * 0.5
				var parejas_internas: Array[int] = []
				var pared_repetida_por_anterior := false
				for par in pares:
					var otro_indice := int(par.b) if int(par.a) == indice else (int(par.a) if int(par.b) == indice else -1)
					if otro_indice < 0:
						continue
					var otro: Rect2 = modulos[otro_indice].rect
					if _dentro_de_otro(fijo, direccion, otro) and _punto_en_rango(medio, otro, lateral_horizontal):
						parejas_internas.append(otro_indice)
					elif otro_indice < indice and _pared_coincide(fijo, direccion, otro) and _punto_en_rango(medio, otro, lateral_horizontal):
						pared_repetida_por_anterior = true
				var clave := _clave_segmento(modulos, indice, direccion, lateral_horizontal, tramo_desde, tramo_hasta)
				if not parejas_internas.is_empty():
					var estado_guardado: Variant = estados.get(clave, ConexionesMapa.ESTADO_CERRADA)
					var estado := String(estado_guardado) if estado_guardado is String else (ConexionesMapa.ESTADO_INTERSECCION if bool(estado_guardado) else ConexionesMapa.ESTADO_CERRADA)
					segmentos.append({
						"modulo": indice,
						"direccion": direccion,
						"inicio": Vector2(tramo_desde, fijo) if lateral_horizontal else Vector2(fijo, tramo_desde),
						"fin": Vector2(tramo_hasta, fijo) if lateral_horizontal else Vector2(fijo, tramo_hasta),
						"clave": clave,
						"estado": estado,
						"abierta": estado == ConexionesMapa.ESTADO_ABIERTA or estado == ConexionesMapa.ESTADO_INTERSECCION,
						"pares": parejas_internas
					})
				elif pared_repetida_por_anterior:
					ocultos.append({"modulo": indice, "direccion": direccion, "inicio": Vector2(tramo_desde, fijo) if lateral_horizontal else Vector2(fijo, tramo_desde), "fin": Vector2(tramo_hasta, fijo) if lateral_horizontal else Vector2(fijo, tramo_hasta), "estado": ConexionesMapa.ESTADO_INTERSECCION})
	return {"pares": pares, "segmentos": segmentos, "ocultos": ocultos}

static func siguiente_estado(estado: String) -> String:
	return ConexionesMapa.siguiente_estado(estado)

## Limita una abertura completa al techo más alto de los módulos contiguos.
static func altura_abertura_interseccion(alto_modulo: float, techos_vecinos: Array[float]) -> float:
	if techos_vecinos.is_empty():
		return alto_modulo
	var techo_vecino := 0.0
	for altura in techos_vecinos:
		techo_vecino = maxf(techo_vecino, altura)
	return minf(alto_modulo, techo_vecino)

## Decide qué techo debe retirarse en una superposición anidada.
## Un volumen más alto contenido en otro atraviesa el techo bajo del contenedor;
## un pasaje bajo contenido en una sala alta conserva su propio cielorraso.
static func indice_techo_a_recortar(rect_a: Rect2, alto_a: float, rect_b: Rect2, alto_b: float, indice_a: int, indice_b: int) -> int:
	if is_equal_approx(alto_a, alto_b):
		return indice_b
	var a_contiene_b := rect_a.position.x <= rect_b.position.x + EPSILON and rect_a.position.y <= rect_b.position.y + EPSILON and rect_a.end.x >= rect_b.end.x - EPSILON and rect_a.end.y >= rect_b.end.y - EPSILON
	var b_contiene_a := rect_b.position.x <= rect_a.position.x + EPSILON and rect_b.position.y <= rect_a.position.y + EPSILON and rect_b.end.x >= rect_a.end.x - EPSILON and rect_b.end.y >= rect_a.end.y - EPSILON
	if a_contiene_b and alto_b > alto_a:
		return indice_a
	if b_contiene_a and alto_a > alto_b:
		return indice_b
	return -1

static func _interseccion(a: Rect2, b: Rect2) -> Rect2:
	var inicio := Vector2(maxf(a.position.x, b.position.x), maxf(a.position.y, b.position.y))
	var fin := Vector2(minf(a.end.x, b.end.x), minf(a.end.y, b.end.y))
	return Rect2(inicio, fin - inicio)

static func _coordenada_fija(rect: Rect2, direccion: int) -> float:
	match direccion:
		Direcciones.Dir.NORTE:
			return rect.position.y
		Direcciones.Dir.SUR:
			return rect.end.y
		Direcciones.Dir.ESTE:
			return rect.end.x
		_:
			return rect.position.x

static func _dentro_de_otro(fijo: float, direccion: int, rect: Rect2) -> bool:
	if direccion == Direcciones.Dir.NORTE or direccion == Direcciones.Dir.SUR:
		return fijo > rect.position.y + EPSILON and fijo < rect.end.y - EPSILON
	return fijo > rect.position.x + EPSILON and fijo < rect.end.x - EPSILON

static func _pared_coincide(fijo: float, direccion: int, rect: Rect2) -> bool:
	if direccion == Direcciones.Dir.NORTE or direccion == Direcciones.Dir.SUR:
		return is_equal_approx(fijo, rect.position.y) or is_equal_approx(fijo, rect.end.y)
	return is_equal_approx(fijo, rect.position.x) or is_equal_approx(fijo, rect.end.x)

static func _rango_lateral(desde: float, hasta: float, rect: Rect2, horizontal: bool) -> Vector2:
	var otro_desde := rect.position.x if horizontal else rect.position.y
	var otro_hasta := rect.end.x if horizontal else rect.end.y
	return Vector2(maxf(desde, otro_desde), minf(hasta, otro_hasta))

static func _punto_en_rango(lateral: float, rect: Rect2, horizontal: bool) -> bool:
	var desde := rect.position.x if horizontal else rect.position.y
	var hasta := rect.end.x if horizontal else rect.end.y
	return lateral > desde - EPSILON and lateral < hasta + EPSILON

static func _clave_segmento(modulos: Array[Dictionary], indice: int, direccion: int, horizontal: bool, desde: float, hasta: float) -> String:
	var id := int(modulos[indice].get("id", indice))
	var rect: Rect2 = modulos[indice].rect
	var origen_lateral := rect.position.x if horizontal else rect.position.y
	var inicio := roundi((desde - origen_lateral) * 100.0)
	var fin := roundi((hasta - origen_lateral) * 100.0)
	return "%d:%d:%d:%d" % [id, direccion, inicio, fin]
