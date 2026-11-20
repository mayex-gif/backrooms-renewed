class_name GeometriaHuella
extends RefCounted
## Operaciones comunes sobre huellas convexas del plano (coordenadas X/Z).

const EPSILON := 0.0001

static func rectangulo(ancho: float, largo: float, centro: Vector2 = Vector2(-INF, -INF)) -> PackedVector2Array:
	var origen := Vector2.ZERO if centro.x == -INF else centro - Vector2(ancho, largo) * 0.5
	return PackedVector2Array([origen, origen + Vector2(ancho, 0.0), origen + Vector2(ancho, largo), origen + Vector2(0.0, largo)])

static func circulo(radio: float, segmentos: int = 32, omitir_cardinales: bool = false) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var paso_cardinal := maxi(1, floori(float(segmentos) / 4.0))
	for indice in segmentos:
		if omitir_cardinales and posmod(indice, paso_cardinal) == 0:
			continue
		var angulo := TAU * float(indice) / float(segmentos)
		puntos.append(Vector2(radio + cos(angulo) * radio, radio + sin(angulo) * radio))
	return puntos

static func area_firmada(poligono: PackedVector2Array) -> float:
	var suma := 0.0
	for indice in poligono.size():
		var a := poligono[indice]
		var b := poligono[(indice + 1) % poligono.size()]
		suma += a.x * b.y - b.x * a.y
	return suma * 0.5

static func normalizar(poligono: PackedVector2Array) -> PackedVector2Array:
	var limpio := PackedVector2Array()
	for punto in poligono:
		if limpio.is_empty() or limpio[-1].distance_to(punto) > EPSILON:
			limpio.append(punto)
	if limpio.size() > 2 and limpio[0].distance_to(limpio[-1]) <= EPSILON:
		limpio.remove_at(limpio.size() - 1)
	if area_firmada(limpio) < 0.0:
		limpio.reverse()
	return limpio

static func transformar(poligono: PackedVector2Array, centro: Vector2, angulo: float) -> PackedVector2Array:
	var resultado := PackedVector2Array()
	var origen := centro
	for punto in poligono:
		resultado.append(origen + punto.rotated(angulo))
	return resultado

static func centrar_local(poligono: PackedVector2Array) -> PackedVector2Array:
	var caja := limites(poligono)
	var centro := caja.get_center()
	var resultado := PackedVector2Array()
	for punto in poligono:
		resultado.append(punto - centro)
	return resultado

static func limites(poligono: PackedVector2Array) -> Rect2:
	if poligono.is_empty():
		return Rect2()
	var minimo := poligono[0]
	var maximo := poligono[0]
	for punto in poligono:
		minimo = minimo.min(punto)
		maximo = maximo.max(punto)
	return Rect2(minimo, maximo - minimo)

static func contiene(poligono: PackedVector2Array, punto: Vector2, borde_incluido: bool = true) -> bool:
	if poligono.size() < 3:
		return false
	var dentro := false
	for indice in poligono.size():
		var a := poligono[indice]
		var b := poligono[(indice + 1) % poligono.size()]
		if Geometry2D.get_closest_point_to_segment(punto, a, b).distance_to(punto) <= EPSILON:
			return borde_incluido
		if (a.y > punto.y) != (b.y > punto.y):
			var cruce_x := (b.x - a.x) * (punto.y - a.y) / (b.y - a.y) + a.x
			if punto.x < cruce_x:
				dentro = not dentro
	return dentro

static func intersecciones(a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
	var resultado: Array[PackedVector2Array] = []
	for poligono in Geometry2D.intersect_polygons(normalizar(a), normalizar(b)):
		var limpio := normalizar(poligono)
		if limpio.size() >= 3 and absf(area_firmada(limpio)) > EPSILON:
			resultado.append(limpio)
	return resultado

## Resta un polígono convexo y devuelve piezas convexas, sin introducir huecos.
static func diferencia_convexa(sujeto: PackedVector2Array, recorte: PackedVector2Array) -> Array[PackedVector2Array]:
	var original := normalizar(sujeto)
	var clip := normalizar(recorte)
	var piezas: Array[PackedVector2Array] = []
	if original.size() < 3 or clip.size() < 3:
		if original.size() >= 3:
			piezas.append(original)
		return piezas
	var resto := original
	for indice in clip.size():
		var inicio := clip[indice]
		var fin := clip[(indice + 1) % clip.size()]
		var fuera := _recortar_semiplano(resto, inicio, fin, false)
		if fuera.size() >= 3 and absf(area_firmada(fuera)) > EPSILON:
			piezas.append(fuera)
		resto = _recortar_semiplano(resto, inicio, fin, true)
		if resto.size() < 3:
			break
	if piezas.is_empty() and resto.size() >= 3:
		# El recorte no atravesó el sujeto; si este queda fuera, conservarlo.
		var interseccion := intersecciones(original, clip)
		if interseccion.is_empty():
			piezas.append(original)
	return piezas

static func diferencia_por_poligonos(base: PackedVector2Array, recortes: Array) -> Array[PackedVector2Array]:
	var piezas: Array[PackedVector2Array] = []
	var inicial := normalizar(base)
	if inicial.size() < 3:
		return piezas
	piezas.append(inicial)
	for recorte_variant in recortes:
		var recorte: PackedVector2Array = recorte_variant
		var siguientes: Array[PackedVector2Array] = []
		for pieza in piezas:
			siguientes.append_array(diferencia_convexa(pieza, recorte))
		piezas = siguientes
		if piezas.is_empty():
			break
	return piezas

static func restar_a_poligonos(bases: Array[PackedVector2Array], recortes: Array) -> Array[PackedVector2Array]:
	var salida: Array[PackedVector2Array] = []
	for base in bases:
		salida.append_array(diferencia_por_poligonos(base, recortes))
	return salida

static func _recortar_semiplano(poligono: PackedVector2Array, a: Vector2, b: Vector2, mantener_dentro: bool) -> PackedVector2Array:
	var salida := PackedVector2Array()
	if poligono.is_empty():
		return salida
	var orientacion := 1.0 if area_firmada(poligono) >= 0.0 else -1.0
	var anterior := poligono[-1]
	var dist_anterior := _producto_cruzado(b - a, anterior - a) * orientacion
	var anterior_dentro := dist_anterior >= -EPSILON if mantener_dentro else dist_anterior <= EPSILON
	for actual in poligono:
		var dist_actual := _producto_cruzado(b - a, actual - a) * orientacion
		var actual_dentro := dist_actual >= -EPSILON if mantener_dentro else dist_actual <= EPSILON
		if actual_dentro != anterior_dentro:
			var denominador := dist_anterior - dist_actual
			if absf(denominador) > EPSILON:
				salida.append(anterior.lerp(actual, clampf(dist_anterior / denominador, 0.0, 1.0)))
		if actual_dentro:
			salida.append(actual)
		anterior = actual
		dist_anterior = dist_actual
		anterior_dentro = actual_dentro
	return normalizar(salida)

static func _producto_cruzado(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x
