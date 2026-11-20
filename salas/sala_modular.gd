extends Node3D
## Construye paredes con huecos físicos a partir de las dimensiones y sockets.

@export var ancho_m := 5.0
@export var largo_m := 5.0
@export var alto_m := 4.2
@export var huella_local := PackedVector2Array()
@export var sockets: Array[SocketDef] = []
@export var semilla_ambiente := 1
@export var columnas: Array[Vector3] = []
## Zonas locales donde otra sala ya aporta la superficie de piso o techo.
@export var zonas_suelo_excluidas: Array = []
@export var zonas_techo_excluidas: Array = []

const LuminariaScript = preload("res://salas/luminaria.gd")

func _ready() -> void:
	var huella := _huella()
	_crear_superficie_poligonal("Piso", huella, zonas_suelo_excluidas, -0.1, 0.2)
	_crear_techo_modular()
	_crear_columnas()
	for arista in huella.size():
		_crear_pared_con_huecos(arista, huella)

func _huella() -> PackedVector2Array:
	if huella_local.size() >= 3:
		return GeometriaHuella.normalizar(huella_local)
	return GeometriaHuella.rectangulo(ancho_m, largo_m)

func _socket_en_arista(socket: SocketDef, arista: int) -> bool:
	if socket.arista >= 0:
		return socket.arista == arista
	return socket.direccion == posmod(arista, 4)

func _crear_pared_con_huecos(arista: int, huella: PackedVector2Array) -> void:
	var inicio_arista := huella[arista]
	var fin_arista := huella[(arista + 1) % huella.size()]
	var eje := (fin_arista - inicio_arista).normalized()
	var largo_lado := inicio_arista.distance_to(fin_arista)
	var sockets_lado: Array[SocketDef] = []
	for socket in sockets:
		if _socket_en_arista(socket, arista):
			sockets_lado.append(socket)
	var huecos: Array[Vector2] = []
	var sin_dintel: Array[Vector2] = []
	for socket in sockets_lado:
		if socket.continuar_sala:
			huecos.append(Vector2(0.0, largo_lado))
			sin_dintel.append(Vector2(0.0, largo_lado))
			continue
		var lateral := (Vector2(socket.posicion_local.x, socket.posicion_local.z) - inicio_arista).dot(eje)
		var inicio := clampf(lateral - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(lateral + socket.ancho * 0.5, 0.0, largo_lado)
		if fin <= inicio:
			continue
		huecos.append(Vector2(inicio, fin))
		if socket.sin_dintel or socket.continuar_sala:
			sin_dintel.append(Vector2(inicio, fin))
	huecos = _unir_intervalos(huecos)
	var cursor := 0.0
	for hueco in huecos:
		_crear_tramo_pared(inicio_arista, eje, cursor, hueco.x, "Pared")
		cursor = hueco.y
	_crear_tramo_pared(inicio_arista, eje, cursor, largo_lado, "Pared")
	for socket in sockets_lado:
		if socket.sin_dintel or socket.continuar_sala:
			continue
		var lateral := (Vector2(socket.posicion_local.x, socket.posicion_local.z) - inicio_arista).dot(eje)
		var inicio := clampf(lateral - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(lateral + socket.ancho * 0.5, 0.0, largo_lado)
		for parte in _restar_intervalos(Vector2(inicio, fin), sin_dintel):
			var altura_abertura := socket.altura_abertura_m if socket.altura_abertura_m > 0.0 else 2.45
			_crear_dintel(inicio_arista, eje, (parte.x + parte.y) * 0.5, parte.y - parte.x, altura_abertura)

func _unir_intervalos(intervalos: Array[Vector2]) -> Array[Vector2]:
	intervalos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var unidos: Array[Vector2] = []
	for intervalo in intervalos:
		if unidos.is_empty() or intervalo.x > unidos[-1].y + 0.001:
			unidos.append(intervalo)
		else:
			var anterior: Vector2 = unidos[-1]
			unidos[-1] = Vector2(anterior.x, maxf(anterior.y, intervalo.y))
	return unidos

func _restar_intervalos(base: Vector2, cortes: Array[Vector2]) -> Array[Vector2]:
	var partes: Array[Vector2] = [base]
	for corte in _unir_intervalos(cortes):
		var nuevas: Array[Vector2] = []
		for parte in partes:
			if corte.y <= parte.x or corte.x >= parte.y:
				nuevas.append(parte)
			else:
				if corte.x > parte.x:
					nuevas.append(Vector2(parte.x, minf(corte.x, parte.y)))
				if corte.y < parte.y:
					nuevas.append(Vector2(maxf(corte.y, parte.x), parte.y))
		partes = nuevas
	return partes

func _crear_tramo_pared(inicio_arista: Vector2, eje: Vector2, desde: float, hasta: float, nombre: String) -> void:
	if hasta - desde <= 0.01:
		return
	var punto := inicio_arista + eje * ((desde + hasta) * 0.5)
	var cuerpo := _crear_caja(nombre, Vector3(hasta - desde, alto_m, 0.2), Vector3(punto.x, alto_m * 0.5, punto.y))
	cuerpo.rotation.y = -atan2(eje.y, eje.x)

func _crear_dintel(inicio_arista: Vector2, eje: Vector2, centro: float, ancho: float, altura_abertura: float = 2.45) -> void:
	var altura_puerta := minf(altura_abertura, alto_m)
	if alto_m <= altura_puerta:
		return
	var tamano := Vector3(ancho, alto_m - altura_puerta, 0.2)
	var punto := inicio_arista + eje * centro
	var cuerpo := _crear_caja("Dintel", tamano, Vector3(punto.x, (alto_m + altura_puerta) * 0.5, punto.y))
	cuerpo.rotation.y = -atan2(eje.y, eje.x)

func _crear_caja(nombre: String, tamano: Vector3, posicion: Vector3, da_sombra: bool = true) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var malla := BoxMesh.new()
	malla.size = tamano
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	if not da_sombra:
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cuerpo.add_child(visual)
	add_child(cuerpo)
	return cuerpo

func _crear_superficie_poligonal(nombre: String, base: PackedVector2Array, exclusiones: Array, y: float, alto: float) -> void:
	for pieza in GeometriaHuella.diferencia_por_poligonos(base, exclusiones):
		if absf(GeometriaHuella.area_firmada(pieza)) > 0.01:
			_crear_prisma_poligonal(nombre, pieza, y, alto, true, false)

func _crear_prisma_poligonal(nombre: String, poligono: PackedVector2Array, centro_y: float, alto: float, colision: bool, sombra: bool) -> void:
	if poligono.size() < 3:
		return
	var contenedor: Node3D
	if colision:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = nombre
		cuerpo.position.y = centro_y
		var forma := ConvexPolygonShape3D.new()
		var puntos_3d := PackedVector3Array()
		for punto in poligono:
			puntos_3d.append(Vector3(punto.x, -alto * 0.5, punto.y))
		for punto in poligono:
			puntos_3d.append(Vector3(punto.x, alto * 0.5, punto.y))
		forma.points = puntos_3d
		var colision_fisica := CollisionShape3D.new()
		colision_fisica.shape = forma
		cuerpo.add_child(colision_fisica)
		add_child(cuerpo)
		contenedor = cuerpo
	else:
		contenedor = Node3D.new()
		contenedor.name = nombre
		contenedor.position.y = centro_y
		add_child(contenedor)
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	var indices := Geometry2D.triangulate_polygon(poligono)
	for indice in range(0, indices.size(), 3):
		var a: Vector2 = poligono[indices[indice]]
		var b: Vector2 = poligono[indices[indice + 1]]
		var c: Vector2 = poligono[indices[indice + 2]]
		if _cruz2d(b - a, c - a) > 0.0:
			var temporal := b
			b = c
			c = temporal
		_agregar_triangulo(vertices, normales, Vector3(a.x, alto * 0.5, a.y), Vector3(b.x, alto * 0.5, b.y), Vector3(c.x, alto * 0.5, c.y), Vector3.UP)
		_agregar_triangulo(vertices, normales, Vector3(a.x, -alto * 0.5, a.y), Vector3(c.x, -alto * 0.5, c.y), Vector3(b.x, -alto * 0.5, b.y), Vector3.DOWN)
	for indice in poligono.size():
		var a := poligono[indice]
		var b := poligono[(indice + 1) % poligono.size()]
		var arista := b - a
		var normal := Vector3(arista.y, 0, -arista.x).normalized()
		var a_abajo := Vector3(a.x, -alto * 0.5, a.y)
		var b_abajo := Vector3(b.x, -alto * 0.5, b.y)
		var a_arriba := Vector3(a.x, alto * 0.5, a.y)
		var b_arriba := Vector3(b.x, alto * 0.5, b.y)
		_agregar_triangulo(vertices, normales, a_abajo, b_abajo, b_arriba, normal)
		_agregar_triangulo(vertices, normales, a_abajo, b_arriba, a_arriba, normal)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normales
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	contenedor.add_child(visual)

func _agregar_triangulo(vertices: PackedVector3Array, normales: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	normales.append(normal)
	normales.append(normal)
	normales.append(normal)

func _cruz2d(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

func _crear_columnas() -> void:
	var usadas: Array[Vector2] = []
	for indice in columnas.size():
		var columna := StaticBody3D.new()
		columna.name = "Columna_%02d" % indice
		var base := Vector2(columnas[indice].x, columnas[indice].z)
		var posicion_xz := _buscar_posicion_columna_sin_luz(base, usadas)
		usadas.append(posicion_xz)
		columna.position = Vector3(posicion_xz.x, alto_m * 0.5, posicion_xz.y)
		var tamano := Vector3(1.3, alto_m, 1.3)
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamano
		colision.shape = forma
		columna.add_child(colision)
		var visual := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = tamano
		visual.mesh = malla
		columna.add_child(visual)
		add_child(columna)

func _buscar_posicion_columna_sin_luz(base: Vector2, usadas: Array[Vector2]) -> Vector2:
	var tam_tile := 1.5
	var fase_x := 1
	var fase_z := 1
	var mejor := base
	var mejor_distancia := INF
	for x in ceili(ancho_m / tam_tile):
		for z in ceili(largo_m / tam_tile):
			var es_posicion_luz := posmod(x - fase_x, 3) == 0 and posmod(z - fase_z, 3) == 0
			if es_posicion_luz:
				continue
			var candidata := Vector2((x + 0.5) * tam_tile, (z + 0.5) * tam_tile)
			if candidata.x > ancho_m - 0.65 or candidata.y > largo_m - 0.65:
				continue
			if not GeometriaHuella.contiene(_huella(), candidata):
				continue
			if _cerca_de_puerta(candidata):
				continue
			var ocupada := false
			for usada in usadas:
				if candidata.distance_to(usada) < 1.8:
					ocupada = true
					break
			if ocupada:
				continue
			var distancia := candidata.distance_squared_to(base)
			if distancia < mejor_distancia:
				mejor = candidata
				mejor_distancia = distancia
	return mejor

func _cerca_de_puerta(punto: Vector2) -> bool:
	for socket in sockets:
		var margen := socket.ancho * 0.5 + 0.7
		var huella := _huella()
		for arista in huella.size():
			if not _socket_en_arista(socket, arista):
				continue
			var inicio := huella[arista]
			var fin := huella[(arista + 1) % huella.size()]
			var eje := (fin - inicio).normalized()
			var posicion_socket := Vector2(socket.posicion_local.x, socket.posicion_local.z)
			var centro_lateral := (posicion_socket - inicio).dot(eje)
			var lateral := (punto - inicio).dot(eje)
			if Geometry2D.get_closest_point_to_segment(punto, inicio, fin).distance_to(punto) < 1.5 and absf(lateral - centro_lateral) < margen:
				return true
	return false

func _crear_techo_modular() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla_ambiente
	var tam_tile := 1.5
	var limites := GeometriaHuella.limites(_huella())
	var columnas_tiles := ceili(limites.size.x / tam_tile)
	var filas_tiles := ceili(limites.size.y / tam_tile)
	# Cámara oscura superior: los huecos dejan ver estructura, no el cielo.
	_crear_superficie_poligonal("Plenum superior", _huella(), zonas_techo_excluidas, alto_m + 0.02, 0.2)
	for x in range(columnas_tiles + 1):
		var px := limites.position.x + x * tam_tile
		_crear_viga_techo(GeometriaHuella.rectangulo(0.07, limites.size.y, Vector2(px, limites.get_center().y)), alto_m - 0.12)
	for z in range(filas_tiles + 1):
		var pz := limites.position.y + z * tam_tile
		_crear_viga_techo(GeometriaHuella.rectangulo(limites.size.x, 0.07, Vector2(limites.get_center().x, pz)), alto_m - 0.12)
	for x in columnas_tiles:
		for z in filas_tiles:
			var x0 := limites.position.x + x * tam_tile
			var z0 := limites.position.y + z * tam_tile
			var ancho_tile := minf(tam_tile, limites.end.x - x0)
			var largo_tile := minf(tam_tile, limites.end.y - z0)
			var rect_tile := GeometriaHuella.rectangulo(ancho_tile, largo_tile, Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5))
			var centro := Vector3(x0 + ancho_tile * 0.5, alto_m - 0.1, z0 + largo_tile * 0.5)
			var valor := rng.randf()
			if valor < 0.065:
				continue # Baldosa faltante.
			var piezas := GeometriaHuella.intersecciones(rect_tile, _huella())
			piezas = GeometriaHuella.restar_a_poligonos(piezas, zonas_techo_excluidas)
			for pieza in piezas:
				_crear_prisma_poligonal("TileTecho", pieza, alto_m - 0.1, 0.12, true, false)
			# Las luces siguen un ritmo de paneles de oficina, con variaciones por sala.
			# Esto evita el patrón de puntos aleatorios demasiado denso.
			var fase_x := 1
			var fase_z := 1
			var es_posicion_luz := posmod(x - fase_x, 3) == 0 and posmod(z - fase_z, 3) == 0
			var area_tile_conservada := 0.0
			for pieza in piezas:
				area_tile_conservada += absf(GeometriaHuella.area_firmada(pieza))
			var tile_completo := absf(area_tile_conservada - ancho_tile * largo_tile) <= 0.01
			if es_posicion_luz and valor > 0.10 and tile_completo and piezas.size() == 1:
				LuminariaScript.crear(self, Vector3(centro.x, alto_m - 0.175, centro.z), ancho_tile - 0.025, largo_tile - 0.025, alto_m, rng)

func _crear_viga_techo(base: PackedVector2Array, y: float) -> void:
	var piezas := GeometriaHuella.intersecciones(base, _huella())
	piezas = GeometriaHuella.restar_a_poligonos(piezas, zonas_techo_excluidas)
	for pieza in piezas:
		_crear_prisma_poligonal("ReticulaTecho", pieza, y, 0.06, false, false)
