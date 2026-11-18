extends Node3D
## Carga y permite recorrer user://saves/mapa_actual.json.

const RUTA_MAPA := "user://saves/mapa_actual.json"
var _catalogo: Array[SalaDef] = []
var _instancias: Array[Node3D] = []
var _paredes_abiertas := false

func _ready() -> void:
	var catalogo_script: Script = load("res://salas/catalogo_salas.gd")
	_catalogo = catalogo_script.call("crear") as Array[SalaDef]
	var salas := Node3D.new()
	salas.name = "Salas"
	add_child(salas)
	var jugador_scene: PackedScene = load("res://jugador/jugador.tscn")
	var jugador := jugador_scene.instantiate() as CharacterBody3D
	add_child(jugador)
	if not FileAccess.file_exists(RUTA_MAPA):
		push_warning("No hay mapa guardado en %s." % RUTA_MAPA)
		return
	var archivo := FileAccess.open(RUTA_MAPA, FileAccess.READ)
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if not datos is Dictionary or not datos.has("salas"):
		push_error("El archivo de mapa guardado no es válido.")
		return
	_paredes_abiertas = bool(datos.get("paredes_abiertas", false))
	var definiciones: Array[SalaDef] = []
	var giros_salas: Array[int] = []
	var origenes: Array[Vector3] = []
	var sockets_instancia: Array[Array] = []
	var rectangulos: Array[Rect2] = []
	for item in datos.salas:
		var indice := _indice_tipo(String(item.get("tipo", "")))
		if indice < 0:
			continue
		var definicion := _catalogo[indice]
		var giros := int(item.get("giros", 0))
		var origen := Vector3(float(item.get("x", 0)), 0, float(item.get("z", 0)))
		var origen_nodo := _origen_nodo(origen, definicion, giros)
		definiciones.append(definicion)
		giros_salas.append(giros)
		origenes.append(origen_nodo)
		sockets_instancia.append([])
		var ancho := definicion.ancho_m if giros % 2 == 0 else definicion.largo_m
		var largo := definicion.largo_m if giros % 2 == 0 else definicion.ancho_m
		rectangulos.append(Rect2(Vector2(origen.x, origen.z), Vector2(ancho, largo)))
	_generar_conexiones_adyacentes(definiciones, giros_salas, origenes, rectangulos, sockets_instancia)
	for i in definiciones.size():
		var definicion := definiciones[i]
		var instancia := definicion.escena.instantiate() as Node3D
		instancia.set("ancho_m", definicion.ancho_m)
		instancia.set("largo_m", definicion.largo_m)
		instancia.set("alto_m", definicion.alto_m)
		if definicion.escena.resource_path.ends_with("sala_circular.tscn"):
			instancia.set("radio_m", minf(definicion.ancho_m, definicion.largo_m) * 0.5)
			for socket in definicion.sockets:
				sockets_instancia[i].append(socket.duplicate(true))
		instancia.set("sockets", sockets_instancia[i])
		instancia.set("semilla_ambiente", i * 7919 + 2026)
		instancia.position = origenes[i]
		instancia.rotation.y = -giros_salas[i] * PI / 2.0
		salas.add_child(instancia)
		_instancias.append(instancia)
	_cerrar_salidas_sin_conexion(definiciones, sockets_instancia)
	if not definiciones.is_empty():
		jugador.global_position = Vector3(rectangulos[0].get_center().x, 0.02, rectangulos[0].get_center().y)

func _generar_conexiones_adyacentes(definiciones: Array[SalaDef], giros: Array[int], origenes: Array[Vector3], rectangulos: Array[Rect2], sockets: Array[Array]) -> void:
	for a in definiciones.size():
		if definiciones[a].escena.resource_path.ends_with("sala_circular.tscn"):
			continue
		for b in range(a + 1, definiciones.size()):
			if definiciones[b].escena.resource_path.ends_with("sala_circular.tscn"):
				continue
			var ra := rectangulos[a]
			var rb := rectangulos[b]
			if absf(ra.end.x - rb.position.x) <= 1.0 or absf(rb.end.x - ra.position.x) <= 1.0:
				var desde := maxf(ra.position.y, rb.position.y)
				var hasta := minf(ra.end.y, rb.end.y)
				if hasta - desde >= 1.5:
					var a_esta_izquierda := absf(ra.end.x - rb.position.x) <= 1.0
					var dir_a := Direcciones.Dir.ESTE if a_esta_izquierda else Direcciones.Dir.OESTE
					var dir_b := Direcciones.opuesta(dir_a)
					var punto_a := Vector2(ra.end.x if a_esta_izquierda else ra.position.x, (desde + hasta) * 0.5)
					var punto_b := Vector2(rb.position.x if a_esta_izquierda else rb.end.x, (desde + hasta) * 0.5)
					var ancho_paso := minf(3.5, hasta - desde)
					var completa := _paredes_abiertas and is_equal_approx(ra.size.y, rb.size.y) and is_equal_approx(ra.position.y, rb.position.y)
					_agregar_puertas_pareadas(a, b, dir_a, dir_b, punto_a, punto_b, ancho_paso, completa, definiciones, giros, origenes, sockets)
					_crear_piso_puente(punto_a, punto_b, ancho_paso)
			elif absf(ra.end.y - rb.position.y) <= 1.0 or absf(rb.end.y - ra.position.y) <= 1.0:
				var desde := maxf(ra.position.x, rb.position.x)
				var hasta := minf(ra.end.x, rb.end.x)
				if hasta - desde >= 1.5:
					var a_esta_arriba := absf(ra.end.y - rb.position.y) <= 1.0
					var dir_a := Direcciones.Dir.SUR if a_esta_arriba else Direcciones.Dir.NORTE
					var dir_b := Direcciones.opuesta(dir_a)
					var punto_a := Vector2((desde + hasta) * 0.5, ra.end.y if a_esta_arriba else ra.position.y)
					var punto_b := Vector2((desde + hasta) * 0.5, rb.position.y if a_esta_arriba else rb.end.y)
					var ancho_paso := minf(3.5, hasta - desde)
					var completa := _paredes_abiertas and is_equal_approx(ra.size.x, rb.size.x) and is_equal_approx(ra.position.x, rb.position.x)
					_agregar_puertas_pareadas(a, b, dir_a, dir_b, punto_a, punto_b, ancho_paso, completa, definiciones, giros, origenes, sockets)
					_crear_piso_puente(punto_a, punto_b, ancho_paso)

func _agregar_puertas_pareadas(a: int, b: int, dir_a: Direcciones.Dir, dir_b: Direcciones.Dir, punto_a: Vector2, punto_b: Vector2, ancho: float, completa: bool, definiciones: Array[SalaDef], giros: Array[int], origenes: Array[Vector3], sockets: Array[Array]) -> void:
	var sa := SocketDef.new()
	sa.direccion = Direcciones.girar(dir_a, -giros[a])
	sa.ancho = ancho
	sa.continuar_sala = completa
	sa.posicion_local = _punto_local(punto_a, origenes[a], giros[a])
	var sb := SocketDef.new()
	sb.direccion = Direcciones.girar(dir_b, -giros[b])
	sb.ancho = ancho
	sb.continuar_sala = completa
	sb.posicion_local = _punto_local(punto_b, origenes[b], giros[b])
	sockets[a].append(sa)
	sockets[b].append(sb)

func _crear_piso_puente(punto_a: Vector2, punto_b: Vector2, ancho: float) -> void:
	var delta := punto_b - punto_a
	if delta.length() < 0.02:
		return
	var cuerpo := StaticBody3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(maxf(0.2, absf(delta.x)), 0.2, maxf(0.2, ancho if absf(delta.x) > 0.01 else absf(delta.y)))
	if absf(delta.x) <= 0.01:
		forma.size = Vector3(ancho, 0.2, maxf(0.2, absf(delta.y)))
	cuerpo.position = Vector3((punto_a.x + punto_b.x) * 0.5, -0.1, (punto_a.y + punto_b.y) * 0.5)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = forma.size
	visual.mesh = malla
	cuerpo.add_child(visual)
	add_child(cuerpo)

func _punto_local(punto: Vector2, origen: Vector3, giros: int) -> Vector3:
	var delta := Vector3(punto.x - origen.x, 0, punto.y - origen.z)
	return Direcciones.rotar_punto(delta, posmod(4 - giros, 4))

func _cerrar_salidas_sin_conexion(definiciones: Array[SalaDef], sockets: Array[Array]) -> void:
	for i in definiciones.size():
		if definiciones[i].escena.resource_path.ends_with("sala_circular.tscn"):
			for socket in definiciones[i].sockets:
				_agregar_cierre(_instancias[i], socket, definiciones[i].alto_m)

func _agregar_cierre(sala: Node3D, socket: SocketDef, altura: float) -> void:
	var relleno := (load("res://salas/relleno_socket.gd") as Script).new() as Node3D
	relleno.set("ancho_hueco", socket.ancho)
	relleno.set("ancho_pasaje", socket.ancho)
	relleno.set("sellado", true)
	relleno.set("altura", altura)
	relleno.position = socket.posicion_local
	relleno.rotation.y = -socket.direccion * PI / 2.0
	sala.add_child(relleno)

func _origen_nodo(origen: Vector3, definicion: SalaDef, giros: int) -> Vector3:
	match posmod(giros, 4):
		1:
			return origen + Vector3(definicion.largo_m, 0, 0)
		2:
			return origen + Vector3(definicion.ancho_m, 0, definicion.largo_m)
		3:
			return origen + Vector3(0, 0, definicion.ancho_m)
	return origen

func _indice_tipo(nombre: String) -> int:
	for i in _catalogo.size():
		if _catalogo[i].nombre == nombre:
			return i
	return -1
