extends RefCounted
## Catálogo pequeño para probar variedad de dimensiones y ramificaciones.

static func crear(multiplicador_grandes: float = 1.0, multiplicador_abiertas: float = 1.0) -> Array[SalaDef]:
	var catalogo: Array[SalaDef] = []
	# Piezas pequeñas: rectas, giros, bifurcaciones e intersecciones.
	catalogo.append(_sala("Pasillo corto 5x5", 5.0, 5.0, 1.5, 18.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 5)]
	]))
	catalogo.append(_sala("Giro 5x5", 5.0, 5.0, 2.0, 16.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 2.5)]
	]))
	catalogo.append(_sala("Bifurcación 5x5", 5.0, 5.0, 2.0, 20.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 2.5)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 5)]
	]))
	catalogo.append(_sala("Cruce 5x5", 5.0, 5.0, 2.0, 22.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 2.5)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 2.5)]
	]))
	catalogo.append(_sala("Sala con dos salidas en un lado 5x5", 5.0, 5.0, 2.0, 22.0, [
		[Direcciones.Dir.NORTE, Vector3(1.25, 0, 0)],
		[Direcciones.Dir.NORTE, Vector3(3.75, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 5)]
	]))
	catalogo.append(_sala("Pasillo angosto 2.5x5", 2.5, 5.0, 1.5, 28.0, [
		[Direcciones.Dir.NORTE, Vector3(1.25, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(1.25, 0, 5)]
	]))
	catalogo.append(_sala("Pasillo lateral 2.5x7.5", 2.5, 7.5, 1.5, 22.0, [
		[Direcciones.Dir.NORTE, Vector3(1.25, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(1.25, 0, 7.5)]
	]))

	# Salas medianas con salidas desplazadas y combinaciones de tres/cuatro lados.
	catalogo.append(_sala("Sala 7.5x5 con tres salidas", 7.5, 5.0, 2.5, 35.0, [
		[Direcciones.Dir.NORTE, Vector3(3.75, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(7.5, 0, 2.5)],
		[Direcciones.Dir.SUR, Vector3(3.75, 0, 5)]
	]))
	catalogo.append(_sala("Sala 5x7.5 en esquina", 5.0, 7.5, 2.0, 32.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 2.5)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 7.5)]
	]))
	catalogo.append(_sala("Sala angosta 5x5 con accesos desplazados", 5.0, 5.0, 1.5, 18.0, [
		[Direcciones.Dir.NORTE, Vector3(1.5, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(3.5, 0, 5)]
	]))
	catalogo.append(_sala("Cruce compacto 5x5 de tres salidas", 5.0, 5.0, 2.0, 24.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 2.5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 2.5)]
	]))
	catalogo.append(_sala("Intersección 7.5x7.5", 7.5, 7.5, 3.0, 28.0, [
		[Direcciones.Dir.NORTE, Vector3(3.75, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(7.5, 0, 3.75)],
		[Direcciones.Dir.SUR, Vector3(3.75, 0, 7.5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 3.75)]
	]))
	catalogo.append(_sala("Sala 7.5x7.5 de tres salidas", 7.5, 7.5, 2.5, 23.0, [
		[Direcciones.Dir.NORTE, Vector3(3.75, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(7.5, 0, 3.75)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 3.75)]
	]))
	catalogo.append(_sala("Sala amplia 10x7.5", 10.0, 7.5, 3.0, 48.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 3.75)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 7.5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 3.75)]
	]))
	catalogo.append(_sala("Pasillo largo 5x10", 5.0, 10.0, 2.0, 35.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(5, 0, 5)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 10)]
	]))
	catalogo.append(_sala("Sala grande 10x10", 10.0, 10.0, 3.0, 52.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 5)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 10)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 5)]
	]))
	catalogo.append(_sala("Galería larga 5x15", 5.0, 15.0, 2.5, 34.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 15)]
	]))
	catalogo.append(_sala("Pasillo largo 3.75x12.5", 3.75, 12.5, 2.0, 30.0, [
		[Direcciones.Dir.NORTE, Vector3(1.875, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(1.875, 0, 12.5)],
		[Direcciones.Dir.ESTE, Vector3(3.75, 0, 6.25)]
	]))
	catalogo.append(_sala("Sala alargada 12.5x17.5", 12.5, 17.5, 3.0, 42.0, [
		[Direcciones.Dir.NORTE, Vector3(6.25, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(12.5, 0, 8.75)],
		[Direcciones.Dir.SUR, Vector3(6.25, 0, 17.5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 8.75)]
	]))
	catalogo.append(_sala("Gran galería 17.5x10", 17.5, 10.0, 3.0, 36.0, [
		[Direcciones.Dir.NORTE, Vector3(8.75, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(17.5, 0, 5)],
		[Direcciones.Dir.SUR, Vector3(8.75, 0, 10)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 5)]
	]))
	catalogo.append(_sala("Gran galería 10x20", 10.0, 20.0, 3.5, 26.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 20)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 10)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 10)]
	]))

	# Finales con una única salida. El peso bajo evita que dominen el recorrido.
	catalogo.append(_sala("Cuarto terminal 5x5", 5.0, 5.0, 2.5, 12.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)]
	]))
	catalogo.append(_sala("Pasaje bajo para agacharse 5x5", 5.0, 5.0, 1.5, 16.0, [
		[Direcciones.Dir.NORTE, Vector3(2.5, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(2.5, 0, 5)]
	], 1.35))
	catalogo.append(_sala("Cámara alta 7.5x7.5", 7.5, 7.5, 3.0, 24.0, [
		[Direcciones.Dir.NORTE, Vector3(3.75, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(7.5, 0, 3.75)],
		[Direcciones.Dir.SUR, Vector3(3.75, 0, 7.5)]
	], 8.0))
	catalogo.append(_sala("Gran cámara 10x10", 10.0, 10.0, 3.0, 14.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 5)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 10)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 5)]
	], 12.0))
	catalogo.append(_sala("Sala abierta 15x15", 15.0, 15.0, 3.5, 90.0, [
		[Direcciones.Dir.NORTE, Vector3(7.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(15, 0, 7.5)],
		[Direcciones.Dir.SUR, Vector3(7.5, 0, 15)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 7.5)]
	]))
	catalogo.append(_sala("Sala de transición 10x15", 10.0, 15.0, 3.5, 56.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 7.5)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 15)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 7.5)]
	]))
	catalogo.append(_sala("Gran sala abierta 15x20 seis salidas", 15.0, 20.0, 3.5, 105.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.NORTE, Vector3(10, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(15, 0, 10)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 20)],
		[Direcciones.Dir.SUR, Vector3(10, 0, 20)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 10)]
	]))
	catalogo.append(_sala("Gran vestíbulo 20x15 seis salidas", 20.0, 15.0, 3.5, 95.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.NORTE, Vector3(15, 0, 0)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 15)],
		[Direcciones.Dir.SUR, Vector3(15, 0, 15)],
		[Direcciones.Dir.ESTE, Vector3(20, 0, 7.5)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 7.5)]
	]))
	var sala_columnas := _sala("Gran sala de columnas 20x20", 20.0, 20.0, 4.0, 110.0, [
		[Direcciones.Dir.NORTE, Vector3(10, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(20, 0, 10)],
		[Direcciones.Dir.SUR, Vector3(10, 0, 20)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 10)]
	])
	for x in [5.0, 10.0, 15.0]:
		for z in [5.0, 10.0, 15.0]:
			if x == 15.0 and z == 10.0:
				continue # Deja libre el acceso este.
			sala_columnas.columnas_locales.append(Vector3(x, 0, z))
			sala_columnas.columnas_tamanos.append(Vector2(0.7 + float(posmod(int(x + z), 4)) * 0.25, 0.8 + float(posmod(int(x * 2.0 + z), 3)) * 0.3))
	catalogo.append(sala_columnas)
	var sala_columnas_alargada := _sala("Galería abierta 15x25 con columnas", 15.0, 25.0, 3.0, 72.0, [
		[Direcciones.Dir.NORTE, Vector3(7.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(15, 0, 12.5)],
		[Direcciones.Dir.SUR, Vector3(7.5, 0, 25)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 12.5)]
	])
	for x in [3.75, 7.5, 11.25]:
		for z in [5.0, 10.0, 15.0, 20.0]:
			if x == 7.5 and z == 10.0:
				continue
			sala_columnas_alargada.columnas_locales.append(Vector3(x, 0, z))
			sala_columnas_alargada.columnas_tamanos.append(Vector2(0.65 + float(posmod(int(x + z), 4)) * 0.3, 0.7 + float(posmod(int(x * 2.0 + z), 4)) * 0.35))
	catalogo.append(sala_columnas_alargada)
	var huella_circular_chica := GeometriaHuella.circulo(3.75, 24, true)
	var aristas_circulo_chico := _aristas_exteriores_circulo(huella_circular_chica)
	catalogo.append(_sala_poligonal("Sala circular compacta 7.5 m", 7.5, 7.5, 2.0, 34.0, huella_circular_chica, aristas_circulo_chico))
	var huella_circular := GeometriaHuella.circulo(5.0, 32, true)
	var aristas_circulo := _aristas_exteriores_circulo(huella_circular)
	var circular := _sala_poligonal("Sala circular 10 m", 10.0, 10.0, 2.5, 58.0, huella_circular, aristas_circulo, 4.2)
	catalogo.append(circular)
	var huella_circular_grande := GeometriaHuella.circulo(7.5, 32, true)
	var aristas_circulo_grande := _aristas_exteriores_circulo(huella_circular_grande)
	var circular_grande := _sala_poligonal("Sala circular amplia 15 m", 15.0, 15.0, 3.0, 42.0, huella_circular_grande, aristas_circulo_grande)
	catalogo.append(circular_grande)
	var huella_circular_muy_grande := GeometriaHuella.circulo(10.0, 40, true)
	var aristas_circulo_muy_grande := _aristas_exteriores_circulo(huella_circular_muy_grande)
	catalogo.append(_sala_poligonal("Rotonda circular 20 m", 20.0, 20.0, 3.5, 20.0, huella_circular_muy_grande, aristas_circulo_muy_grande))
	catalogo.append(_sala_poligonal("Sala triangular equilátera 5 m", 5.0, 4.33, 2.0, 20.0, PackedVector2Array([
		Vector2(0, 0), Vector2(5, 0), Vector2(2.5, 4.33)
	])))
	catalogo.append(_sala_poligonal("Sala triangular rectángula 5 m", 5.0, 5.0, 2.0, 18.0, PackedVector2Array([
		Vector2(0, 0), Vector2(5, 0), Vector2(0, 5)
	])))
	catalogo.append(_sala_poligonal("Sala triangular 30-60-90", 8.66, 5.0, 2.0, 16.0, PackedVector2Array([
		Vector2(0, 0), Vector2(8.66, 0), Vector2(0, 5)
	])))
	# Cuartos compactos disponibles en todas las alturas usadas por el catálogo.
	# Los cuatro sockets dejan que el editor los conecte desde cualquier lado.
	var alturas_sala_chica: Array[float] = [1.35, 3.2, 4.2, 8.0, 12.0]
	for alto_chico in alturas_sala_chica:
		var sockets_chicos := [
			[Direcciones.Dir.NORTE, Vector3(1.25, 0, 0)],
			[Direcciones.Dir.ESTE, Vector3(2.5, 0, 1.25)],
			[Direcciones.Dir.SUR, Vector3(1.25, 0, 2.5)],
			[Direcciones.Dir.OESTE, Vector3(0, 0, 1.25)]
		]
		catalogo.append(_sala("Sala compacta 2.5x2.5 · %.2f m" % alto_chico, 2.5, 2.5, 1.5, 10.0, sockets_chicos, alto_chico))
	for definicion in catalogo:
		if definicion.ancho_m >= 10.0 or definicion.largo_m >= 10.0:
			definicion.peso *= multiplicador_grandes
		if definicion.nombre.contains("abierta") or definicion.nombre.contains("vestíbulo") or definicion.nombre.contains("columnas"):
			definicion.peso *= multiplicador_abiertas
	return catalogo

static func _sala(nombre: String, ancho: float, largo: float, ancho_puerta: float, peso: float, datos_sockets: Array, alto: float = 4.2) -> SalaDef:
	var definicion := SalaDef.new()
	definicion.nombre = nombre
	definicion.escena = load("res://salas/sala_modular.tscn")
	definicion.ancho_m = ancho
	definicion.largo_m = largo
	definicion.alto_m = alto
	definicion.peso = peso
	var rng_posiciones := RandomNumberGenerator.new()
	var hash_nombre: int = nombre.hash()
	rng_posiciones.seed = hash_nombre if hash_nombre >= 0 else -hash_nombre
	for dato in datos_sockets:
		var socket := SocketDef.new()
		socket.direccion = dato[0]
		socket.posicion_local = dato[1]
		socket.ancho = ancho_puerta
		var es_borde_horizontal := socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR
		var largo_lado := ancho if es_borde_horizontal else largo
		var lateral := socket.posicion_local.x if es_borde_horizontal else socket.posicion_local.z
		if is_equal_approx(lateral, largo_lado * 0.5):
			var desplazamiento_maximo := maxf(0.0, largo_lado * 0.5 - socket.ancho * 0.5 - 0.75)
			if desplazamiento_maximo >= 0.45:
				var desplazamiento := rng_posiciones.randf_range(-desplazamiento_maximo, desplazamiento_maximo)
				if es_borde_horizontal:
					socket.posicion_local.x += desplazamiento
				else:
					socket.posicion_local.z += desplazamiento
		definicion.sockets.append(socket)
	return definicion

static func _sala_poligonal(nombre: String, ancho: float, largo: float, ancho_puerta: float, peso: float, huella: PackedVector2Array, aristas_sockets: Array[int] = [], alto: float = 4.2) -> SalaDef:
	var definicion := _sala(nombre, ancho, largo, ancho_puerta, peso, [])
	definicion.alto_m = alto
	definicion.huella_local = huella
	for arista in huella.size():
		if not aristas_sockets.is_empty() and not aristas_sockets.has(arista):
			continue
		var inicio := huella[arista]
		var fin := huella[(arista + 1) % huella.size()]
		var eje := fin - inicio
		var socket := SocketDef.new()
		socket.arista = arista
		socket.rotacion_pared = -atan2(eje.y, eje.x)
		socket.posicion_local = Vector3((inicio.x + fin.x) * 0.5, 0, (inicio.y + fin.y) * 0.5)
		socket.ancho = minf(ancho_puerta, eje.length() - 0.1)
		definicion.sockets.append(socket)
	return definicion

static func _aristas_exteriores_circulo(huella: PackedVector2Array) -> Array[int]:
	var resultado: Array[int] = []
	for direccion in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		var mejor_arista := -1
		var mejor_proyeccion := -INF
		for arista in huella.size():
			var inicio := huella[arista]
			var fin := huella[(arista + 1) % huella.size()]
			var eje := fin - inicio
			if eje.length() < 1.5:
				continue
			var normal := Vector2(eje.y, -eje.x).normalized()
			var proyeccion := ((inicio + fin) * 0.5).dot(direccion)
			if normal.dot(direccion) > 0.98 and proyeccion > mejor_proyeccion:
				mejor_proyeccion = proyeccion
				mejor_arista = arista
		if mejor_arista >= 0:
			resultado.append(mejor_arista)
	return resultado
