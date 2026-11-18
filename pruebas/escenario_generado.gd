extends Node3D
## Vista simple para inspeccionar el mapa calculado por GeneradorProcedural.

## -1 genera un mapa distinto cada vez. Al crear el mapa se guarda su semilla para repetirlo.
@export var semilla := -1
@export_range(1, 100000, 1) var max_salas := 24
@export_range(4, 64, 1) var salas_por_extension := 12
@export_range(4.0, 30.0, 1.0) var distancia_extension := 6.0
@export var imprimir_huella_completa := false
var multiplicador_grandes := 1.0
var multiplicador_abiertas := 1.0
@onready var contenedor: Node3D = $Salas
@onready var jugador: CharacterBody3D = $Jugador

var _limites_minimos := Vector2.ZERO
var _limites_maximos := Vector2.ZERO
var _reloj_extension := 0.0
var _cantidad_previa := 0
var _sin_mas_mapa := false
var _primer_mapa := true

func _ready() -> void:
	add_to_group("escenario_procedural")
	_crear_mapa()

func aplicar_configuracion_desarrollo(cantidad: int, peso_grandes: float, peso_abiertas: float) -> void:
	max_salas = maxi(1, cantidad)
	multiplicador_grandes = peso_grandes
	multiplicador_abiertas = peso_abiertas
	_sin_mas_mapa = false
	_primer_mapa = true
	_crear_mapa()
	_reloj_extension = 2.0

func _physics_process(delta: float) -> void:
	_reloj_extension = maxf(0.0, _reloj_extension - delta)
	if _reloj_extension > 0.0 or _sin_mas_mapa:
		return
	var posicion := Vector2(jugador.global_position.x, jugador.global_position.z)
	var cerca_del_borde := (
		posicion.x < _limites_minimos.x + distancia_extension
		or posicion.x > _limites_maximos.x - distancia_extension
		or posicion.y < _limites_minimos.y + distancia_extension
		or posicion.y > _limites_maximos.y - distancia_extension
	)
	if cerca_del_borde:
		max_salas += salas_por_extension
		_crear_mapa()
		_reloj_extension = 2.0
		if _cantidad_mapa_actual <= _cantidad_previa:
			_sin_mas_mapa = true
			push_warning("La semilla %d agotó las ubicaciones alcanzables; no se puede ampliar más este mapa." % semilla)

var _cantidad_mapa_actual := 0

func _crear_mapa() -> void:
	_cantidad_previa = _cantidad_mapa_actual
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	var definiciones: Array[SalaDef] = script_catalogo.call("crear", multiplicador_grandes, multiplicador_abiertas) as Array[SalaDef]
	var generador := GeneradorProcedural.new()
	var resultado := generador.generar(definiciones, semilla, max_salas)
	semilla = resultado.semilla
	_cantidad_mapa_actual = resultado.salas.size()
	_actualizar_limites(resultado.salas)
	if _primer_mapa and not resultado.salas.is_empty():
		var inicio: Dictionary = resultado.salas[0]
		var primera_sala: SalaDef = inicio.sala
		jugador.global_position = inicio.origen + Vector3(primera_sala.ancho_m * 0.5, 0.02, primera_sala.largo_m * 0.5)
		_primer_mapa = false
	var resumen := PackedStringArray()
	var tipos_usados: Dictionary = {}
	var instancias: Array[Node3D] = []
	var sockets_conectados: Dictionary = {}
	for ubicacion in resultado.salas:
		var sala_def: SalaDef = ubicacion.sala
		if imprimir_huella_completa:
			resumen.append("%02d:%s@%s/g%d" % [ubicacion.id, sala_def.nombre, ubicacion.origen, ubicacion.giros])
		tipos_usados[sala_def.nombre] = tipos_usados.get(sala_def.nombre, 0) + 1
		var instancia := sala_def.escena.instantiate() as Node3D
		instancia.set("ancho_m", sala_def.ancho_m)
		instancia.set("largo_m", sala_def.largo_m)
		instancia.set("alto_m", sala_def.alto_m)
		if not sala_def.columnas_locales.is_empty():
			instancia.set("columnas", sala_def.columnas_locales)
		instancia.set("sockets", sala_def.sockets)
		instancia.set("semilla_ambiente", semilla + ubicacion.id * 7919)
		instancia.position = ubicacion.origen
		instancia.rotation.y = ubicacion.angulo_y
		contenedor.add_child(instancia)
		instancias.append(instancia)
	for ubicacion in resultado.salas:
		if not ubicacion.has("conexion"):
			continue
		var relleno_def: Dictionary = ubicacion.conexion
		var sala_destino: SalaDef = resultado.salas[relleno_def.sala_destino_id].sala
		var sala_nueva: SalaDef = ubicacion.sala
		var socket_destino: SocketDef = sala_destino.sockets[relleno_def.socket_destino_indice]
		var socket_nuevo: SocketDef = sala_nueva.sockets[relleno_def.socket_nuevo_indice]
		sockets_conectados["%d:%d" % [relleno_def.sala_destino_id, relleno_def.socket_destino_indice]] = true
		sockets_conectados["%d:%d" % [ubicacion.id, relleno_def.socket_nuevo_indice]] = true
		var sala_ancha_id: int = relleno_def.sala_destino_id if socket_destino.ancho > socket_nuevo.ancho else ubicacion.id
		var socket_ancho: SocketDef = socket_destino if socket_destino.ancho > socket_nuevo.ancho else socket_nuevo
		if relleno_def.relleno_por_lado > 0.001:
			_agregar_relleno(instancias[sala_ancha_id], socket_ancho, maxf(socket_destino.ancho, socket_nuevo.ancho), relleno_def.ancho_pasaje, false, 2.3, "RellenoSocket_%d" % ubicacion.id)
		if not is_equal_approx(sala_destino.alto_m, sala_nueva.alto_m):
			var sala_baja_id: int = relleno_def.sala_destino_id if sala_destino.alto_m < sala_nueva.alto_m else ubicacion.id
			var socket_bajo: SocketDef = socket_destino if sala_destino.alto_m < sala_nueva.alto_m else socket_nuevo
			var alto_bajo: float = minf(sala_destino.alto_m, sala_nueva.alto_m)
			var alto_alto: float = maxf(sala_destino.alto_m, sala_nueva.alto_m)
			_agregar_panel_superior(instancias[sala_baja_id], socket_bajo, alto_bajo, alto_alto)
	for ubicacion in resultado.salas:
		var sala_def: SalaDef = ubicacion.sala
		for socket_indice in sala_def.sockets.size():
			if sockets_conectados.has("%d:%d" % [ubicacion.id, socket_indice]):
				continue
			var socket: SocketDef = sala_def.sockets[socket_indice]
			_agregar_relleno(instancias[ubicacion.id], socket, socket.ancho, socket.ancho, true, sala_def.alto_m, "CierreSocket_%d_%d" % [ubicacion.id, socket_indice])
	print("Mapa generado: %d salas, semilla %d, %d salidas sin conectar." % [resultado.salas.size(), resultado.semilla, resultado.pendientes])
	print("Tipos usados: %s" % [tipos_usados])
	if imprimir_huella_completa:
		print("Huella reproducible: %s" % " | ".join(resumen))
	for aviso in resultado.avisos:
		push_warning(aviso)
	if _cantidad_previa > 0:
		print("Exploración extendida: ahora hay %d salas." % _cantidad_mapa_actual)

func _actualizar_limites(salas: Array) -> void:
	if salas.is_empty():
		return
	_limites_minimos = Vector2(INF, INF)
	_limites_maximos = Vector2(-INF, -INF)
	for ubicacion in salas:
		var definicion: SalaDef = ubicacion.sala
		var ancho := definicion.ancho_m if posmod(ubicacion.giros, 2) == 0 else definicion.largo_m
		var largo := definicion.largo_m if posmod(ubicacion.giros, 2) == 0 else definicion.ancho_m
		var origen := Vector2(ubicacion.origen.x, ubicacion.origen.z)
		_limites_minimos.x = minf(_limites_minimos.x, origen.x)
		_limites_minimos.y = minf(_limites_minimos.y, origen.y)
		_limites_maximos.x = maxf(_limites_maximos.x, origen.x + ancho)
		_limites_maximos.y = maxf(_limites_maximos.y, origen.y + largo)

func _agregar_relleno(sala: Node3D, socket: SocketDef, ancho_hueco: float, ancho_pasaje: float, sellado: bool, altura: float, nombre: String) -> void:
	var script_relleno: Script = load("res://salas/relleno_socket.gd")
	var relleno: Node3D = script_relleno.new() as Node3D
	relleno.name = nombre
	relleno.set("ancho_hueco", ancho_hueco)
	relleno.set("ancho_pasaje", ancho_pasaje)
	relleno.set("sellado", sellado)
	relleno.set("altura", altura)
	relleno.set("profundidad", 0.2)
	relleno.position = socket.posicion_local
	relleno.rotation.y = -socket.direccion * PI / 2.0
	sala.add_child(relleno)

func _agregar_panel_superior(sala: Node3D, socket: SocketDef, alto_bajo: float, alto_alto: float) -> void:
	var alto_panel := alto_alto - alto_bajo
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "PanelSobrePuerta"
	cuerpo.position = socket.posicion_local + Vector3.UP * (alto_bajo + alto_panel * 0.5)
	cuerpo.rotation.y = -socket.direccion * PI / 2.0
	var forma := BoxShape3D.new()
	forma.size = Vector3(socket.ancho, alto_panel, 0.2)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = forma.size
	visual.mesh = malla
	cuerpo.add_child(visual)
	sala.add_child(cuerpo)
