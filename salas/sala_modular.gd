extends Node3D
## Construye paredes con huecos físicos a partir de las dimensiones y sockets.

@export var ancho_m := 5.0
@export var largo_m := 5.0
@export var alto_m := 4.2
@export var sockets: Array[SocketDef] = []
@export var semilla_ambiente := 1
@export var columnas: Array[Vector3] = []
## Zonas locales donde otra sala ya aporta la superficie de piso o techo.
@export var zonas_suelo_excluidas: Array = []
@export var zonas_techo_excluidas: Array = []

func _ready() -> void:
	_crear_superficie_recortada("Piso", Rect2(0, 0, ancho_m, largo_m), zonas_suelo_excluidas, -0.1, 0.2)
	_crear_techo_modular()
	_crear_columnas()
	for direccion in range(4):
		var sockets_lado: Array[SocketDef] = []
		for socket in sockets:
			if socket.direccion == direccion:
				sockets_lado.append(socket)
		var pared_abierta_completa := false
		for socket in sockets_lado:
			pared_abierta_completa = pared_abierta_completa or socket.continuar_sala
		if pared_abierta_completa:
			continue
		_crear_pared_con_huecos(direccion, sockets_lado)

func _centro_lateral(socket: SocketDef) -> float:
	return socket.posicion_local.x if socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR else socket.posicion_local.z

func _crear_pared_con_huecos(direccion: int, sockets_lado: Array[SocketDef]) -> void:
	var largo_lado := ancho_m if direccion == Direcciones.Dir.NORTE or direccion == Direcciones.Dir.SUR else largo_m
	var huecos: Array[Vector2] = []
	var sin_dintel: Array[Vector2] = []
	for socket in sockets_lado:
		var inicio := clampf(_centro_lateral(socket) - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(_centro_lateral(socket) + socket.ancho * 0.5, 0.0, largo_lado)
		if fin <= inicio:
			continue
		huecos.append(Vector2(inicio, fin))
		if socket.sin_dintel:
			sin_dintel.append(Vector2(inicio, fin))
	huecos = _unir_intervalos(huecos)
	var cursor := 0.0
	for hueco in huecos:
		_crear_tramo_pared(direccion, cursor, hueco.x, largo_lado, "Pared")
		cursor = hueco.y
	_crear_tramo_pared(direccion, cursor, largo_lado, largo_lado, "Pared")
	for socket in sockets_lado:
		if socket.sin_dintel:
			continue
		var inicio := clampf(_centro_lateral(socket) - socket.ancho * 0.5, 0.0, largo_lado)
		var fin := clampf(_centro_lateral(socket) + socket.ancho * 0.5, 0.0, largo_lado)
		for parte in _restar_intervalos(Vector2(inicio, fin), sin_dintel):
			var altura_abertura := socket.altura_abertura_m if socket.altura_abertura_m > 0.0 else 2.45
			_crear_dintel(direccion, (parte.x + parte.y) * 0.5, parte.y - parte.x, altura_abertura)

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

func _crear_tramo_pared(direccion: int, desde: float, hasta: float, largo_lado: float, nombre: String) -> void:
	if hasta - desde <= 0.01:
		return
	var centro := (desde + hasta) * 0.5
	var tamano := Vector3(hasta - desde, alto_m, 0.2)
	var posicion := Vector3(centro, alto_m * 0.5, 0.0)
	if direccion == Direcciones.Dir.SUR:
		posicion.z = largo_m
	elif direccion == Direcciones.Dir.ESTE:
		tamano = Vector3(0.2, alto_m, hasta - desde)
		posicion = Vector3(ancho_m, alto_m * 0.5, centro)
	elif direccion == Direcciones.Dir.OESTE:
		tamano = Vector3(0.2, alto_m, hasta - desde)
		posicion = Vector3(0.0, alto_m * 0.5, centro)
	_crear_caja(nombre, tamano, posicion)

func _crear_dintel(direccion: int, centro: float, ancho: float, altura_abertura: float = 2.45) -> void:
	var altura_puerta := minf(altura_abertura, alto_m)
	if alto_m <= altura_puerta:
		return
	var tamano := Vector3(ancho, alto_m - altura_puerta, 0.2)
	var posicion := Vector3(centro, (alto_m + altura_puerta) * 0.5, 0.0)
	if direccion == Direcciones.Dir.SUR:
		posicion.z = largo_m
	elif direccion == Direcciones.Dir.ESTE:
		tamano = Vector3(0.2, alto_m - altura_puerta, ancho)
		posicion = Vector3(ancho_m, (alto_m + altura_puerta) * 0.5, centro)
	elif direccion == Direcciones.Dir.OESTE:
		tamano = Vector3(0.2, alto_m - altura_puerta, ancho)
		posicion = Vector3(0.0, (alto_m + altura_puerta) * 0.5, centro)
	_crear_caja("Dintel", tamano, posicion)

func _crear_caja(nombre: String, tamano: Vector3, posicion: Vector3) -> void:
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
	cuerpo.add_child(visual)
	add_child(cuerpo)

func _crear_superficie_recortada(nombre: String, rect: Rect2, exclusiones: Array, y: float, alto: float) -> void:
	for pieza in _restar_rectangulos(rect, exclusiones):
		if pieza.size.x <= 0.01 or pieza.size.y <= 0.01:
			continue
		_crear_caja(nombre, Vector3(pieza.size.x, alto, pieza.size.y), Vector3(pieza.get_center().x, y, pieza.get_center().y))

func _restar_rectangulos(base: Rect2, exclusiones: Array) -> Array[Rect2]:
	var piezas: Array[Rect2] = [base]
	for exclusion in exclusiones:
		var nuevas: Array[Rect2] = []
		for pieza in piezas:
			var inicio := Vector2(maxf(pieza.position.x, exclusion.position.x), maxf(pieza.position.y, exclusion.position.y))
			var fin := Vector2(minf(pieza.end.x, exclusion.end.x), minf(pieza.end.y, exclusion.end.y))
			if fin.x - inicio.x <= 0.001 or fin.y - inicio.y <= 0.001:
				nuevas.append(pieza)
				continue
			if inicio.y > pieza.position.y:
				nuevas.append(Rect2(pieza.position, Vector2(pieza.size.x, inicio.y - pieza.position.y)))
			if fin.y < pieza.end.y:
				nuevas.append(Rect2(Vector2(pieza.position.x, fin.y), Vector2(pieza.size.x, pieza.end.y - fin.y)))
			if inicio.x > pieza.position.x:
				nuevas.append(Rect2(Vector2(pieza.position.x, inicio.y), Vector2(inicio.x - pieza.position.x, fin.y - inicio.y)))
			if fin.x < pieza.end.x:
				nuevas.append(Rect2(Vector2(fin.x, inicio.y), Vector2(pieza.end.x - fin.x, fin.y - inicio.y)))
		piezas = nuevas
	return piezas

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
		match socket.direccion:
			Direcciones.Dir.NORTE:
				if punto.y < 1.5 and absf(punto.x - socket.posicion_local.x) < margen:
					return true
			Direcciones.Dir.SUR:
				if punto.y > largo_m - 1.5 and absf(punto.x - socket.posicion_local.x) < margen:
					return true
			Direcciones.Dir.ESTE:
				if punto.x > ancho_m - 1.5 and absf(punto.y - socket.posicion_local.z) < margen:
					return true
			Direcciones.Dir.OESTE:
				if punto.x < 1.5 and absf(punto.y - socket.posicion_local.z) < margen:
					return true
	return false

func _crear_techo_modular() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla_ambiente
	var tam_tile := 1.5
	var columnas := ceili(ancho_m / tam_tile)
	var filas := ceili(largo_m / tam_tile)
	# Cámara oscura superior: los huecos dejan ver estructura, no el cielo.
	_crear_superficie_recortada("Plenum superior", Rect2(0, 0, ancho_m, largo_m), zonas_techo_excluidas, alto_m + 0.02, 0.2)
	for x in columnas + 1:
		var px := minf(x * tam_tile, ancho_m)
		_crear_viga_techo(Vector3(0.07, 0.06, largo_m), Vector3(px, alto_m - 0.12, largo_m * 0.5))
	for z in filas + 1:
		var pz := minf(z * tam_tile, largo_m)
		_crear_viga_techo(Vector3(ancho_m, 0.06, 0.07), Vector3(ancho_m * 0.5, alto_m - 0.12, pz))
	for x in columnas:
		for z in filas:
			var ancho_tile := minf(tam_tile, ancho_m - x * tam_tile)
			var largo_tile := minf(tam_tile, largo_m - z * tam_tile)
			var centro := Vector3(x * tam_tile + ancho_tile * 0.5, alto_m - 0.1, z * tam_tile + largo_tile * 0.5)
			var valor := rng.randf()
			if valor < 0.065:
				continue # Baldosa faltante.
			var rect_tile := Rect2(x * tam_tile, z * tam_tile, ancho_tile, largo_tile)
			var piezas: Array[Rect2] = []
			for pieza in _restar_rectangulos(rect_tile, zonas_techo_excluidas):
				if pieza.size.x > 0.05 and pieza.size.y > 0.05:
					piezas.append(pieza)
			for pieza in piezas:
				var centro_pieza := Vector3(pieza.get_center().x, alto_m - 0.1, pieza.get_center().y)
				var tile := _crear_tile(centro_pieza, pieza.size.x - 0.025, pieza.size.y - 0.025, rng)
				if valor > 0.93 and piezas.size() == 1:
					tile.position.y += rng.randf_range(0.04, 0.12)
					tile.rotation_degrees.z = rng.randf_range(-2.0, 2.0)
			# Las luces siguen un ritmo de paneles de oficina, con variaciones por sala.
			# Esto evita el patrón de puntos aleatorios demasiado denso.
			var fase_x := 1
			var fase_z := 1
			var es_posicion_luz := posmod(x - fase_x, 3) == 0 and posmod(z - fase_z, 3) == 0
			if es_posicion_luz and valor > 0.10 and not piezas.is_empty():
				var pieza_luz: Rect2 = piezas[0]
				for pieza in piezas:
					if pieza.size.x * pieza.size.y > pieza_luz.size.x * pieza_luz.size.y:
						pieza_luz = pieza
				var centro_luz := Vector3(pieza_luz.get_center().x, alto_m - 0.175, pieza_luz.get_center().y)
				if _lejos_de_pared(centro_luz, 1.1):
					_crear_luminaria_techo(centro_luz, rng, pieza_luz.size.x - 0.025, pieza_luz.size.y - 0.025)

func _lejos_de_pared(centro: Vector3, margen: float) -> bool:
	return centro.x >= margen and centro.x <= ancho_m - margen and centro.z >= margen and centro.z <= largo_m - margen

func _crear_viga_techo(tamano: Vector3, posicion: Vector3) -> void:
	var huella := Rect2(posicion.x - tamano.x * 0.5, posicion.z - tamano.z * 0.5, tamano.x, tamano.z)
	for pieza in _restar_rectangulos(huella, zonas_techo_excluidas):
		if pieza.size.x <= 0.01 or pieza.size.y <= 0.01:
			continue
		var visual := MeshInstance3D.new()
		visual.name = "ReticulaTecho"
		visual.position = Vector3(pieza.get_center().x, posicion.y, pieza.get_center().y)
		var malla := BoxMesh.new()
		malla.size = Vector3(pieza.size.x, tamano.y, pieza.size.y)
		visual.mesh = malla
		add_child(visual)

func _crear_tile(posicion: Vector3, ancho: float, largo: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "TileTecho"
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = Vector3(ancho, 0.12, largo)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = forma.size
	visual.mesh = malla
	cuerpo.add_child(visual)
	add_child(cuerpo)
	return cuerpo

func _crear_luminaria_techo(posicion: Vector3, rng: RandomNumberGenerator, ancho: float, largo: float) -> void:
	var luminaria := Node3D.new()
	luminaria.name = "PanelFluorescente"
	luminaria.add_to_group("luces_techo")
	luminaria.position = posicion
	var funciona := rng.randf() > 0.28
	var panel := MeshInstance3D.new()
	panel.name = "PanelEmisor"
	var malla := BoxMesh.new()
	malla.size = Vector3(ancho, 0.04, largo)
	panel.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE if funciona else Color(0.12, 0.12, 0.12)
	material.emission_enabled = funciona
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 1.6
	panel.material_override = material
	panel.add_to_group("paneles_luz")
	panel.set_meta("emite_por_defecto", funciona)
	luminaria.add_child(panel)
	if funciona:
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.96, 0.88)
		luz.light_energy = 0.75
		luz.omni_range = maxf(4.5, alto_m + 0.8)
		luz.shadow_enabled = false
		luz.add_to_group("luces_techo_nodos")
		luz.set_meta("energia_base", luz.light_energy)
		luminaria.add_child(luz)
		if rng.randf() > 0.15:
			var script_parpadeo: Script = load("res://salas/fluorescente.gd")
			luminaria.set_script(script_parpadeo)
			luminaria.set("semilla", rng.randi())
	add_child(luminaria)
