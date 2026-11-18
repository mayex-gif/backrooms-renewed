extends Node3D
## Nivel de recorrido diseñado a mano. Las conexiones y sus coordenadas son fijas.

const PLAN: Array[Dictionary] = [
	{"id": "vestibulo", "tipo": "Gran vestíbulo 20x15 seis salidas", "origen": Vector3(0, 0, 0), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 2, "ancho": 5.0},
		{"indice": 4, "ancho": 5.0}, {"indice": 5, "ancho": 5.0}
	]},
	{"id": "ala_norte", "tipo": "Sala abierta 15x15", "origen": Vector3(-2.5, 0, -15), "sockets": [
		{"indice": 0, "ancho": 1.5}, {"indice": 1, "ancho": 2.5}, {"indice": 2, "ancho": 5.0}
	]},
	{"id": "ala_sur", "tipo": "Sala abierta 15x15", "origen": Vector3(-2.5, 0, 15), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 1, "ancho": 2.5}, {"indice": 2, "ancho": 5.0}
	]},
	{"id": "ala_oeste", "tipo": "Sala abierta 15x15", "origen": Vector3(-15, 0, 0), "sockets": [
		{"indice": 1, "ancho": 5.0}
	]},
	{"id": "ala_este", "tipo": "Sala abierta 15x15", "origen": Vector3(20, 0, 0), "sockets": [
		{"indice": 0, "ancho": 3.5}, {"indice": 3, "ancho": 5.0}
	]},
	{"id": "rotonda", "tipo": "Sala circular 10 m", "origen": Vector3(12.5, 0, -12.5), "sockets": [
		{"indice": 1, "ancho": 2.5}, {"indice": 3, "ancho": 2.5}
	]},
	{"id": "ala_noreste", "tipo": "Sala abierta 15x15", "origen": Vector3(22.5, 0, -15), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 2, "ancho": 3.5, "posicion": Vector3(5, 0, 15)}, {"indice": 3, "ancho": 2.5}
	]},
	{"id": "camara_norte", "tipo": "Sala grande 10x10", "origen": Vector3(25, 0, -25), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 2, "ancho": 3.0}
	]},
	{"id": "camara_alta", "tipo": "Cámara alta 7.5x7.5", "origen": Vector3(26.25, 0, -32.5), "sockets": [
		{"indice": 2, "ancho": 3.0}
	]},
	{"id": "conector_norte", "tipo": "Pasillo corto 5x5", "origen": Vector3(2.5, 0, -20), "sockets": [
		{"indice": 0, "ancho": 1.5}, {"indice": 1, "ancho": 1.5}
	]},
	{"id": "pasaje_bajo", "tipo": "Pasaje bajo para agacharse 5x5", "origen": Vector3(2.5, 0, -25), "sockets": [
		{"indice": 0, "ancho": 1.5}, {"indice": 1, "ancho": 1.5}
	]},
	{"id": "sala_pequena_norte", "tipo": "Sala 5x7.5 en esquina", "origen": Vector3(2.5, 0, -32.5), "sockets": [
		{"indice": 0, "ancho": 1.5}, {"indice": 2, "ancho": 1.5}
	]},
	{"id": "final_norte", "tipo": "Cuarto terminal 5x5", "origen": Vector3(2.5, 0, -37.5), "sockets": [
		{"indice": 0, "ancho": 1.5, "direccion": Direcciones.Dir.SUR, "posicion": Vector3(2.5, 0, 5)}
	]},
	{"id": "camara_sur", "tipo": "Gran sala de columnas 20x20", "origen": Vector3(-5, 0, 30), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 1, "ancho": 2.0}, {"indice": 2, "ancho": 5.0}
	]},
	{"id": "cruce_sur", "tipo": "Cruce 5x5", "origen": Vector3(15, 0, 37.5), "sockets": [
		{"indice": 1, "ancho": 1.5}, {"indice": 3, "ancho": 2.0}
	]},
	{"id": "conector_sur", "tipo": "Pasillo corto 5x5", "origen": Vector3(20, 0, 37.5), "sockets": [
		{"indice": 0, "ancho": 1.5, "direccion": Direcciones.Dir.OESTE, "posicion": Vector3(0, 0, 2.5)},
		{"indice": 1, "ancho": 1.5, "direccion": Direcciones.Dir.ESTE, "posicion": Vector3(5, 0, 2.5)}
	]},
	{"id": "final_sur", "tipo": "Cuarto terminal 5x5", "origen": Vector3(25, 0, 37.5), "sockets": [
		{"indice": 0, "ancho": 1.5, "direccion": Direcciones.Dir.OESTE, "posicion": Vector3(0, 0, 2.5)}
	]},
	{"id": "zona_sur_abierta", "tipo": "Sala abierta 15x15", "origen": Vector3(-2.5, 0, 50), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 2, "ancho": 5.0}
	]},
	{"id": "zona_sur_lateral", "tipo": "Sala abierta 15x15", "origen": Vector3(-2.5, 0, 65), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 1, "ancho": 3.0}
	]},
	{"id": "camara_sureste", "tipo": "Sala grande 10x10", "origen": Vector3(12.5, 0, 67.5), "sockets": [
		{"indice": 1, "ancho": 2.0}, {"indice": 3, "ancho": 3.0}
	]},
	{"id": "cruce_sureste", "tipo": "Cruce 5x5", "origen": Vector3(22.5, 0, 70), "sockets": [
		{"indice": 1, "ancho": 1.5}, {"indice": 3, "ancho": 2.0}
	]},
	{"id": "conector_sureste", "tipo": "Pasillo corto 5x5", "origen": Vector3(27.5, 0, 70), "sockets": [
		{"indice": 0, "ancho": 1.5, "direccion": Direcciones.Dir.OESTE, "posicion": Vector3(0, 0, 2.5)},
		{"indice": 1, "ancho": 1.5, "direccion": Direcciones.Dir.ESTE, "posicion": Vector3(5, 0, 2.5)}
	]},
	{"id": "final_sureste", "tipo": "Cuarto terminal 5x5", "origen": Vector3(32.5, 0, 70), "sockets": [
		{"indice": 0, "ancho": 1.5, "direccion": Direcciones.Dir.OESTE, "posicion": Vector3(0, 0, 2.5)}
	]},
	{"id": "conector_este", "tipo": "Intersección 7.5x7.5", "origen": Vector3(12.5, 0, 18.75), "sockets": [
		{"indice": 1, "ancho": 2.5}, {"indice": 3, "ancho": 2.5}
	]},
	{"id": "zona_este_abierta_a", "tipo": "Sala abierta 15x15", "origen": Vector3(20, 0, 15), "sockets": [
		{"indice": 1, "ancho": 5.0}, {"indice": 3, "ancho": 2.5}
	]},
	{"id": "zona_este_abierta_b", "tipo": "Sala abierta 15x15", "origen": Vector3(35, 0, 15), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 1, "ancho": 3.0},
		{"indice": 2, "ancho": 3.0}, {"indice": 3, "ancho": 5.0}
	]},
	{"id": "camara_este", "tipo": "Sala grande 10x10", "origen": Vector3(50, 0, 17.5), "sockets": [
		{"indice": 1, "ancho": 3.0}, {"indice": 3, "ancho": 3.0}
	]},
	{"id": "columnas_este", "tipo": "Gran sala de columnas 20x20", "origen": Vector3(60, 0, 12.5), "sockets": [
		{"indice": 2, "ancho": 5.0}, {"indice": 3, "ancho": 3.0}
	]},
	{"id": "ala_este_sur_a", "tipo": "Sala abierta 15x15", "origen": Vector3(62.5, 0, 32.5), "sockets": [
		{"indice": 0, "ancho": 5.0}, {"indice": 2, "ancho": 3.0}
	]},
	{"id": "camara_este_sur", "tipo": "Sala grande 10x10", "origen": Vector3(65, 0, 47.5), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 1, "ancho": 2.0}, {"indice": 2, "ancho": 3.0}
	]},
	{"id": "ala_este_sur_b", "tipo": "Sala abierta 15x15", "origen": Vector3(62.5, 0, 57.5), "sockets": [
		{"indice": 0, "ancho": 3.0}
	]},
	{"id": "cruce_este_sur", "tipo": "Cruce 5x5", "origen": Vector3(75, 0, 50), "sockets": [
		{"indice": 1, "ancho": 2.0}, {"indice": 3, "ancho": 2.0}
	]},
	{"id": "camara_extremo_este", "tipo": "Sala grande 10x10", "origen": Vector3(80, 0, 47.5), "sockets": [
		{"indice": 1, "ancho": 3.0}, {"indice": 3, "ancho": 2.0}
	]},
	{"id": "zona_extremo_este_a", "tipo": "Sala abierta 15x15", "origen": Vector3(90, 0, 45), "sockets": [
		{"indice": 1, "ancho": 5.0}, {"indice": 3, "ancho": 3.0}, {"indice": 2, "ancho": 5.0}
	]},
	{"id": "zona_extremo_este_b", "tipo": "Sala abierta 15x15", "origen": Vector3(90, 0, 60), "sockets": [
		{"indice": 0, "ancho": 5.0}
	]},
	{"id": "camara_noreste", "tipo": "Sala grande 10x10", "origen": Vector3(37.5, 0, 5), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 2, "ancho": 3.0}
	]},
	{"id": "ala_noreste_abierta", "tipo": "Sala abierta 15x15", "origen": Vector3(35, 0, -10), "sockets": [
		{"indice": 2, "ancho": 3.0}
	]},
	{"id": "camara_sureste_exterior", "tipo": "Sala grande 10x10", "origen": Vector3(37.5, 0, 30), "sockets": [
		{"indice": 0, "ancho": 3.0}, {"indice": 2, "ancho": 3.0}
	]},
	{"id": "ala_sureste_exterior", "tipo": "Sala abierta 15x15", "origen": Vector3(35, 0, 40), "sockets": [
		{"indice": 0, "ancho": 3.0}
	]}
]

const CONEXIONES: Array[Dictionary] = [
	{"a": "vestibulo", "socket_a": 0, "b": "ala_norte", "socket_b": 2},
	{"a": "vestibulo", "socket_a": 2, "b": "ala_sur", "socket_b": 0},
	{"a": "vestibulo", "socket_a": 4, "b": "ala_este", "socket_b": 3},
	{"a": "vestibulo", "socket_a": 5, "b": "ala_oeste", "socket_b": 1},
	{"a": "ala_norte", "socket_a": 1, "b": "rotonda", "socket_b": 3},
	{"a": "rotonda", "socket_a": 1, "b": "ala_noreste", "socket_b": 3},
	{"a": "ala_noreste", "socket_a": 2, "b": "ala_este", "socket_b": 0},
	{"a": "ala_noreste", "socket_a": 0, "b": "camara_norte", "socket_b": 2},
	{"a": "camara_norte", "socket_a": 0, "b": "camara_alta", "socket_b": 2},
	{"a": "ala_norte", "socket_a": 0, "b": "conector_norte", "socket_b": 1},
	{"a": "conector_norte", "socket_a": 0, "b": "pasaje_bajo", "socket_b": 1},
	{"a": "pasaje_bajo", "socket_a": 0, "b": "sala_pequena_norte", "socket_b": 2},
	{"a": "sala_pequena_norte", "socket_a": 0, "b": "final_norte", "socket_b": 0},
	{"a": "ala_sur", "socket_a": 2, "b": "camara_sur", "socket_b": 0},
	{"a": "camara_sur", "socket_a": 1, "b": "cruce_sur", "socket_b": 3},
	{"a": "cruce_sur", "socket_a": 1, "b": "conector_sur", "socket_b": 0},
	{"a": "conector_sur", "socket_a": 1, "b": "final_sur", "socket_b": 0},
	{"a": "camara_sur", "socket_a": 2, "b": "zona_sur_abierta", "socket_b": 0},
	{"a": "zona_sur_abierta", "socket_a": 2, "b": "zona_sur_lateral", "socket_b": 0},
	{"a": "zona_sur_lateral", "socket_a": 1, "b": "camara_sureste", "socket_b": 3},
	{"a": "camara_sureste", "socket_a": 1, "b": "cruce_sureste", "socket_b": 3},
	{"a": "cruce_sureste", "socket_a": 1, "b": "conector_sureste", "socket_b": 0},
	{"a": "conector_sureste", "socket_a": 1, "b": "final_sureste", "socket_b": 0},
	{"a": "ala_sur", "socket_a": 1, "b": "conector_este", "socket_b": 3},
	{"a": "conector_este", "socket_a": 1, "b": "zona_este_abierta_a", "socket_b": 3},
	{"a": "zona_este_abierta_a", "socket_a": 1, "b": "zona_este_abierta_b", "socket_b": 3},
	{"a": "zona_este_abierta_b", "socket_a": 1, "b": "camara_este", "socket_b": 3},
	{"a": "camara_este", "socket_a": 1, "b": "columnas_este", "socket_b": 3},
	{"a": "columnas_este", "socket_a": 2, "b": "ala_este_sur_a", "socket_b": 0},
	{"a": "ala_este_sur_a", "socket_a": 2, "b": "camara_este_sur", "socket_b": 0},
	{"a": "camara_este_sur", "socket_a": 1, "b": "cruce_este_sur", "socket_b": 3},
	{"a": "camara_este_sur", "socket_a": 2, "b": "ala_este_sur_b", "socket_b": 0},
	{"a": "cruce_este_sur", "socket_a": 1, "b": "camara_extremo_este", "socket_b": 3},
	{"a": "camara_extremo_este", "socket_a": 1, "b": "zona_extremo_este_a", "socket_b": 3},
	{"a": "zona_extremo_este_a", "socket_a": 2, "b": "zona_extremo_este_b", "socket_b": 0},
	{"a": "zona_este_abierta_b", "socket_a": 0, "b": "camara_noreste", "socket_b": 2},
	{"a": "camara_noreste", "socket_a": 0, "b": "ala_noreste_abierta", "socket_b": 2},
	{"a": "zona_este_abierta_b", "socket_a": 2, "b": "camara_sureste_exterior", "socket_b": 0},
	{"a": "camara_sureste_exterior", "socket_a": 2, "b": "ala_sureste_exterior", "socket_b": 0}
]

const JUGADOR = preload("res://jugador/jugador.tscn")
@onready var contenedor: Node3D = $Salas
var cantidad_salas := 30
var multiplicador_grandes := 1.0
var multiplicador_abiertas := 1.0
var jugador: CharacterBody3D

var cantidad_salas_disponibles: int:
	get:
		return PLAN.size()

func _ready() -> void:
	_crear_mapa()
	jugador = JUGADOR.instantiate() as CharacterBody3D
	jugador.name = "Jugador"
	add_child(jugador)
	_jugador_al_inicio()
	print("Plano diseñado cargado: hasta %d salas y %d conexiones, con vestíbulo central y alas abiertas." % [PLAN.size(), CONEXIONES.size()])

func aplicar_configuracion_desarrollo(cantidad: int, peso_grandes: float, peso_abiertas: float) -> void:
	cantidad_salas = clampi(cantidad, 1, PLAN.size())
	multiplicador_grandes = peso_grandes
	multiplicador_abiertas = peso_abiertas
	_crear_mapa()
	_jugador_al_inicio()
	print("Plano reconstruido: %d de %d salas predefinidas." % [cantidad_salas, PLAN.size()])

func _jugador_al_inicio() -> void:
	if jugador != null:
		jugador.global_position = Vector3(10, 0.02, 7.5)
		jugador.velocity = Vector3.ZERO

var cantidad_salas_actuales: int:
	get:
		return contenedor.get_child_count()

func _seleccionar_plan(catalogo: Dictionary) -> Array[Dictionary]:
	var por_id: Dictionary = {}
	for plano in PLAN:
		por_id[plano.id] = plano
	var seleccionadas: Dictionary = {"vestibulo": true}
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261118
	while seleccionadas.size() < cantidad_salas:
		var candidatas: Array[String] = []
		for conexion in CONEXIONES:
			if seleccionadas.has(conexion.a) and not seleccionadas.has(conexion.b):
				if not candidatas.has(conexion.b):
					candidatas.append(conexion.b)
			elif seleccionadas.has(conexion.b) and not seleccionadas.has(conexion.a):
				if not candidatas.has(conexion.a):
					candidatas.append(conexion.a)
		if candidatas.is_empty():
			break
		var pesos: Array[float] = []
		var peso_total := 0.0
		for id in candidatas:
			var plano: Dictionary = por_id[id]
			var definicion: SalaDef = catalogo[plano.tipo]
			var peso := maxf(0.1, definicion.peso)
			if definicion.ancho_m >= 10.0 or definicion.largo_m >= 10.0:
				peso *= multiplicador_grandes
			if definicion.nombre.contains("abierta") or definicion.nombre.contains("vestíbulo") or definicion.nombre.contains("columnas"):
				peso *= multiplicador_abiertas
			pesos.append(peso)
			peso_total += peso
		var eleccion := rng.randf() * peso_total
		for indice in candidatas.size():
			eleccion -= pesos[indice]
			if eleccion <= 0.0:
				seleccionadas[candidatas[indice]] = true
				break
	var resultado: Array[Dictionary] = []
	for plano in PLAN:
		if seleccionadas.has(plano.id):
			resultado.append(plano)
	return resultado

func _crear_mapa() -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	var definiciones: Array[SalaDef] = script_catalogo.call("crear") as Array[SalaDef]
	var catalogo: Dictionary = {}
	for definicion in definiciones:
		catalogo[definicion.nombre] = definicion
	var planos_activos := _seleccionar_plan(catalogo)
	var instancias: Dictionary = {}
	var sockets_por_id: Dictionary = {}
	var alturas_por_id: Dictionary = {}
	var definiciones_por_id: Dictionary = {}
	for plano in planos_activos:
		var nombre: String = plano.tipo
		if not catalogo.has(nombre):
			push_error("El plano solicita una sala que no existe en el catálogo: %s" % nombre)
			continue
		var definicion: SalaDef = catalogo[nombre]
		var sala := definicion.escena.instantiate() as Node3D
		sala.name = String(plano.id).capitalize()
		sala.set("ancho_m", definicion.ancho_m)
		sala.set("largo_m", definicion.largo_m)
		sala.set("alto_m", definicion.alto_m)
		if not definicion.columnas_locales.is_empty():
			sala.set("columnas", definicion.columnas_locales)
		sala.set("semilla_ambiente", 20261118 + instancias.size() * 7919)
		sala.position = plano.origen
		var sockets_sala: Array[SocketDef] = []
		var mapa_sockets: Dictionary = {}
		for regla in plano.sockets:
			var indice: int = regla.indice
			var socket := definicion.sockets[indice].duplicate(true) as SocketDef
			socket.ancho = float(regla.get("ancho", socket.ancho))
			if regla.has("direccion"):
				socket.direccion = int(regla.direccion) as Direcciones.Dir
			if regla.has("posicion"):
				socket.posicion_local = regla.posicion
			sockets_sala.append(socket)
			mapa_sockets[indice] = socket
		sala.set("sockets", sockets_sala)
		contenedor.add_child(sala)
		instancias[plano.id] = sala
		sockets_por_id[plano.id] = mapa_sockets
		alturas_por_id[plano.id] = definicion.alto_m
		definiciones_por_id[plano.id] = definicion
	var conectados: Dictionary = {}
	for conexion in CONEXIONES:
		if not instancias.has(conexion.a) or not instancias.has(conexion.b):
			continue
		var sala_a: Node3D = instancias[conexion.a]
		var sala_b: Node3D = instancias[conexion.b]
		var socket_a: SocketDef = sockets_por_id[conexion.a][conexion.socket_a]
		var socket_b: SocketDef = sockets_por_id[conexion.b][conexion.socket_b]
		conectados["%s:%d" % [conexion.a, conexion.socket_a]] = true
		conectados["%s:%d" % [conexion.b, conexion.socket_b]] = true
		if not is_equal_approx(alturas_por_id[conexion.a], alturas_por_id[conexion.b]):
			var sala_baja: Node3D = sala_a if alturas_por_id[conexion.a] < alturas_por_id[conexion.b] else sala_b
			var socket_bajo: SocketDef = socket_a if alturas_por_id[conexion.a] < alturas_por_id[conexion.b] else socket_b
			_cerrar_sobrepuerta(sala_baja, socket_bajo, minf(alturas_por_id[conexion.a], alturas_por_id[conexion.b]), maxf(alturas_por_id[conexion.a], alturas_por_id[conexion.b]))
	for id in sockets_por_id:
		var sala: Node3D = instancias[id]
		var definicion: SalaDef = definiciones_por_id[id]
		for indice in sockets_por_id[id]:
			if conectados.has("%s:%d" % [id, indice]):
				continue
			_sellar_socket(sala, sockets_por_id[id][indice], definicion.alto_m)

func _sellar_socket(sala: Node3D, socket: SocketDef, alto: float) -> void:
	var script_relleno: Script = load("res://salas/relleno_socket.gd")
	var relleno := script_relleno.new() as Node3D
	relleno.name = "CierreSocketPlano"
	relleno.ancho_hueco = socket.ancho
	relleno.ancho_pasaje = socket.ancho
	relleno.altura = minf(2.45, alto)
	relleno.sellado = true
	relleno.position = socket.posicion_local
	relleno.rotation.y = -socket.direccion * PI / 2.0
	sala.add_child(relleno)

func _cerrar_sobrepuerta(sala: Node3D, socket: SocketDef, altura_baja: float, altura_alta: float) -> void:
	var diferencia := altura_alta - altura_baja
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "PanelSobrePuerta"
	cuerpo.position = socket.posicion_local + Vector3.UP * (altura_baja + diferencia * 0.5)
	cuerpo.rotation.y = -socket.direccion * PI / 2.0
	var caja := BoxShape3D.new()
	caja.size = Vector3(socket.ancho, diferencia, 0.2)
	var colision := CollisionShape3D.new()
	colision.shape = caja
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = caja.size
	visual.mesh = malla
	cuerpo.add_child(visual)
	sala.add_child(cuerpo)
