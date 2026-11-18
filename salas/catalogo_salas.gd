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
	catalogo.append(sala_columnas)
	var circular := _sala("Sala circular 10 m", 10.0, 10.0, 2.5, 58.0, [
		[Direcciones.Dir.NORTE, Vector3(5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(10, 0, 5)],
		[Direcciones.Dir.SUR, Vector3(5, 0, 10)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 5)]
	], 4.2)
	circular.escena = load("res://salas/sala_circular.tscn")
	catalogo.append(circular)
	var circular_grande := _sala("Sala circular amplia 15 m", 15.0, 15.0, 3.0, 42.0, [
		[Direcciones.Dir.NORTE, Vector3(7.5, 0, 0)],
		[Direcciones.Dir.ESTE, Vector3(15, 0, 7.5)],
		[Direcciones.Dir.SUR, Vector3(7.5, 0, 15)],
		[Direcciones.Dir.OESTE, Vector3(0, 0, 7.5)]
	])
	circular_grande.escena = load("res://salas/sala_circular.tscn")
	catalogo.append(circular_grande)
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
