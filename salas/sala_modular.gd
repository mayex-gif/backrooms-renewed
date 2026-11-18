extends Node3D
## Construye paredes con huecos físicos a partir de las dimensiones y sockets.

@export var ancho_m := 5.0
@export var largo_m := 5.0
@export var alto_m := 4.2
@export var sockets: Array[SocketDef] = []
@export var semilla_ambiente := 1
@export var columnas: Array[Vector3] = []

func _ready() -> void:
	_crear_caja("Piso", Vector3(ancho_m, 0.2, largo_m), Vector3(ancho_m * 0.5, -0.1, largo_m * 0.5))
	_crear_techo_modular()
	_crear_columnas()
	for direccion in range(4):
		var sockets_lado: Array[SocketDef] = []
		for socket in sockets:
			if socket.direccion == direccion:
				sockets_lado.append(socket)
		var largo_lado := ancho_m if direccion == Direcciones.Dir.NORTE or direccion == Direcciones.Dir.SUR else largo_m
		sockets_lado.sort_custom(func(a: SocketDef, b: SocketDef) -> bool:
			return _centro_lateral(a) < _centro_lateral(b)
		)
		var cursor := 0.0
		for socket in sockets_lado:
			var inicio := _centro_lateral(socket) - socket.ancho * 0.5
			_crear_tramo_pared(direccion, cursor, inicio, largo_lado, "Pared")
			_crear_dintel(direccion, _centro_lateral(socket), socket.ancho)
			cursor = _centro_lateral(socket) + socket.ancho * 0.5
		_crear_tramo_pared(direccion, cursor, largo_lado, largo_lado, "Pared")

func _centro_lateral(socket: SocketDef) -> float:
	return socket.posicion_local.x if socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR else socket.posicion_local.z

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

func _crear_dintel(direccion: int, centro: float, ancho: float) -> void:
	var altura_puerta := minf(2.45, alto_m)
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

func _crear_columnas() -> void:
	for indice in columnas.size():
		var columna := StaticBody3D.new()
		columna.name = "Columna_%02d" % indice
		columna.position = columnas[indice] + Vector3.UP * (alto_m * 0.5)
		var tamano := Vector3(0.8, alto_m, 0.8)
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

func _crear_techo_modular() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla_ambiente
	var tam_tile := 1.25
	var columnas := ceili(ancho_m / tam_tile)
	var filas := ceili(largo_m / tam_tile)
	# Cámara oscura superior: los huecos dejan ver estructura, no el cielo.
	_crear_caja("Plenum superior", Vector3(ancho_m, 0.2, largo_m), Vector3(ancho_m * 0.5, alto_m + 0.18, largo_m * 0.5))
	for x in columnas + 1:
		var px := minf(x * tam_tile, ancho_m)
		_crear_viga_techo(Vector3(0.045, 0.04, largo_m), Vector3(px, alto_m - 0.12, largo_m * 0.5))
	for z in filas + 1:
		var pz := minf(z * tam_tile, largo_m)
		_crear_viga_techo(Vector3(ancho_m, 0.04, 0.045), Vector3(ancho_m * 0.5, alto_m - 0.12, pz))
	for x in columnas:
		for z in filas:
			var ancho_tile := minf(tam_tile, ancho_m - x * tam_tile)
			var largo_tile := minf(tam_tile, largo_m - z * tam_tile)
			var centro := Vector3(x * tam_tile + ancho_tile * 0.5, alto_m - 0.1, z * tam_tile + largo_tile * 0.5)
			var valor := rng.randf()
			if valor < 0.065:
				continue # Baldosa faltante.
			var tile := _crear_tile(centro, ancho_tile - 0.045, largo_tile - 0.045, rng)
			if valor > 0.93:
				tile.position.y += rng.randf_range(0.04, 0.12)
				tile.rotation_degrees.z = rng.randf_range(-2.0, 2.0)
			# Las luces siguen un ritmo de paneles de oficina, con variaciones por sala.
			# Esto evita el patrón de puntos aleatorios demasiado denso.
			var fase_x := posmod(semilla_ambiente, 3)
			var fase_z := posmod(floori(float(semilla_ambiente) / 3.0), 3)
			var es_posicion_luz := posmod(x - fase_x, 3) == 0 and posmod(z - fase_z, 3) == 0
			if es_posicion_luz and valor > 0.10:
				_crear_luminaria_techo(centro + Vector3(0, -0.055, 0), rng, ancho_tile - 0.045, largo_tile - 0.045)

func _crear_viga_techo(tamano: Vector3, posicion: Vector3) -> void:
	var visual := MeshInstance3D.new()
	visual.name = "ReticulaTecho"
	visual.position = posicion
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	add_child(visual)

func _crear_tile(posicion: Vector3, ancho: float, largo: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "TileTecho"
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = Vector3(ancho, 0.08, largo)
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
		luz.light_energy = 0.9
		luz.omni_range = maxf(6.0, alto_m + 2.0)
		luz.shadow_enabled = false
		luz.add_to_group("luces_techo_nodos")
		luz.set_meta("energia_base", luz.light_energy)
		luminaria.add_child(luz)
		if rng.randf() > 0.48:
			var script_parpadeo: Script = load("res://salas/fluorescente.gd")
			luminaria.set_script(script_parpadeo)
			luminaria.set("semilla", rng.randi())
	add_child(luminaria)
