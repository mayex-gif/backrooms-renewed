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
	var aperturas_completas: Dictionary = {}
	for ubicacion in resultado.salas:
		if not ubicacion.has("conexion") or posmod(semilla + ubicacion.id * 31, 2) != 0:
			continue
		var conexion: Dictionary = ubicacion.conexion
		var id_destino: int = conexion.sala_destino_id
		var socket_destino_indice: int = conexion.socket_destino_indice
		var socket_nuevo_indice: int = conexion.socket_nuevo_indice
		var definicion_destino: SalaDef = resultado.salas[id_destino].sala
		var definicion_nueva: SalaDef = ubicacion.sala
		var socket_destino: SocketDef = definicion_destino.sockets[socket_destino_indice]
		var socket_nuevo: SocketDef = definicion_nueva.sockets[socket_nuevo_indice]
		if _es_unico_socket_del_lado(definicion_destino, socket_destino) and _es_unico_socket_del_lado(definicion_nueva, socket_nuevo) and _lados_coinciden(definicion_destino, socket_destino, definicion_nueva, socket_nuevo):
			aperturas_completas["%d:%d" % [id_destino, socket_destino_indice]] = true
			aperturas_completas["%d:%d" % [ubicacion.id, socket_nuevo_indice]] = true
	for ubicacion in resultado.salas:
		var sala_def: SalaDef = ubicacion.sala
		if imprimir_huella_completa:
			resumen.append("%02d:%s@%s/g%d" % [ubicacion.id, sala_def.nombre, ubicacion.origen, ubicacion.giros])
		tipos_usados[sala_def.nombre] = tipos_usados.get(sala_def.nombre, 0) + 1
		var instancia := sala_def.escena.instantiate() as Node3D
		instancia.set("ancho_m", sala_def.ancho_m)
		instancia.set("largo_m", sala_def.largo_m)
		instancia.set("alto_m", sala_def.alto_m)
		instancia.set("huella_local", sala_def.obtener_huella_local())
		if not sala_def.columnas_locales.is_empty():
			instancia.set("columnas", sala_def.columnas_locales)
			instancia.set("columnas_tamanos", sala_def.columnas_tamanos)
		var sockets_instancia: Array[SocketDef] = []
		for indice_socket in sala_def.sockets.size():
			var socket_copia := sala_def.sockets[indice_socket].duplicate(true) as SocketDef
			socket_copia.continuar_sala = aperturas_completas.has("%d:%d" % [ubicacion.id, indice_socket])
			sockets_instancia.append(socket_copia)
		instancia.set("sockets", sockets_instancia)
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
		var apertura_completa := aperturas_completas.has("%d:%d" % [relleno_def.sala_destino_id, relleno_def.socket_destino_indice])
		if relleno_def.relleno_por_lado > 0.001 and not apertura_completa:
			var alto_sala_ancha: float = sala_destino.alto_m if sala_ancha_id == relleno_def.sala_destino_id else sala_nueva.alto_m
			var alto_abertura_ancha := minf(2.45, alto_sala_ancha)
			_agregar_relleno(instancias[sala_ancha_id], socket_ancho, maxf(socket_destino.ancho, socket_nuevo.ancho), relleno_def.ancho_pasaje, false, alto_abertura_ancha, "RellenoSocket_%d" % ubicacion.id)
		if not is_equal_approx(sala_destino.alto_m, sala_nueva.alto_m):
			var sala_baja_id: int = relleno_def.sala_destino_id if sala_destino.alto_m < sala_nueva.alto_m else ubicacion.id
			var socket_bajo: SocketDef = socket_destino if sala_destino.alto_m < sala_nueva.alto_m else socket_nuevo
			var alto_bajo: float = minf(sala_destino.alto_m, sala_nueva.alto_m)
			var alto_alto: float = maxf(sala_destino.alto_m, sala_nueva.alto_m)
			if apertura_completa:
				var definicion_baja: SalaDef = resultado.salas[sala_baja_id].sala
				_agregar_cierre_superior_completo(instancias[sala_baja_id], socket_bajo, definicion_baja, alto_bajo, alto_alto)
			else:
				var alto_abertura_destino := minf(2.45, sala_destino.alto_m)
				var alto_abertura_nueva := minf(2.45, sala_nueva.alto_m)
				if not is_equal_approx(alto_abertura_destino, alto_abertura_nueva):
					var id_abertura_mayor: int = relleno_def.sala_destino_id if alto_abertura_destino > alto_abertura_nueva else ubicacion.id
					var socket_abertura_mayor: SocketDef = socket_destino if alto_abertura_destino > alto_abertura_nueva else socket_nuevo
					_agregar_panel_superior(instancias[id_abertura_mayor], socket_abertura_mayor, minf(alto_abertura_destino, alto_abertura_nueva), maxf(alto_abertura_destino, alto_abertura_nueva))
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
		var rect: Rect2 = ubicacion.rectangulo
		_limites_minimos.x = minf(_limites_minimos.x, rect.position.x)
		_limites_minimos.y = minf(_limites_minimos.y, rect.position.y)
		_limites_maximos.x = maxf(_limites_maximos.x, rect.end.x)
		_limites_maximos.y = maxf(_limites_maximos.y, rect.end.y)

func _es_unico_socket_del_lado(definicion: SalaDef, socket: SocketDef) -> bool:
	var arista := definicion.obtener_arista_socket(socket)
	for otro in definicion.sockets:
		if otro != socket and definicion.obtener_arista_socket(otro) == arista:
			return false
	return true

func _lados_coinciden(def_a: SalaDef, socket_a: SocketDef, def_b: SalaDef, socket_b: SocketDef) -> bool:
	var largo_a := def_a.largo_arista_socket(socket_a)
	var largo_b := def_b.largo_arista_socket(socket_b)
	if not is_equal_approx(largo_a, largo_b):
		return false
	var arista_a := def_a.obtener_arista_socket(socket_a)
	var arista_b := def_b.obtener_arista_socket(socket_b)
	var huella_a := def_a.obtener_huella_local()
	var huella_b := def_b.obtener_huella_local()
	var eje_a := (huella_a[(arista_a + 1) % huella_a.size()] - huella_a[arista_a]).normalized()
	var eje_b := (huella_b[(arista_b + 1) % huella_b.size()] - huella_b[arista_b]).normalized()
	var medio_a := (huella_a[arista_a] + huella_a[(arista_a + 1) % huella_a.size()]) * 0.5
	var medio_b := (huella_b[arista_b] + huella_b[(arista_b + 1) % huella_b.size()]) * 0.5
	return absf(eje_a.dot(eje_b)) > 0.999 and socket_a.posicion_local.distance_to(Vector3(medio_a.x, 0, medio_a.y)) <= 0.001 and socket_b.posicion_local.distance_to(Vector3(medio_b.x, 0, medio_b.y)) <= 0.001

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
	relleno.rotation.y = _rotacion_socket(socket)
	sala.add_child(relleno)

func _agregar_panel_superior(sala: Node3D, socket: SocketDef, alto_bajo: float, alto_alto: float) -> void:
	var alto_panel := alto_alto - alto_bajo
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "PanelSobrePuerta"
	cuerpo.position = socket.posicion_local + Vector3.UP * (alto_bajo + alto_panel * 0.5)
	cuerpo.rotation.y = _rotacion_socket(socket)
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

func _agregar_cierre_superior_completo(sala: Node3D, socket: SocketDef, definicion: SalaDef, alto_bajo: float, alto_alto: float) -> void:
	var largo_pared := definicion.largo_arista_socket(socket)
	var alto_panel := alto_alto - alto_bajo
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "CierreSuperiorAberturaCompleta"
	var caja := BoxShape3D.new()
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	cuerpo.position = socket.posicion_local + Vector3.UP * (alto_bajo + alto_panel * 0.5)
	cuerpo.rotation.y = _rotacion_socket(socket)
	caja.size = Vector3(largo_pared, alto_panel, 0.2)
	visual.position = Vector3.ZERO
	malla.size = caja.size
	visual.mesh = malla
	var colision := CollisionShape3D.new()
	colision.shape = caja
	cuerpo.add_child(colision)
	cuerpo.add_child(visual)
	sala.add_child(cuerpo)

func _rotacion_socket(socket: SocketDef) -> float:
	if socket.arista >= 0:
		return socket.rotacion_pared
	return -float(socket.direccion) * PI / 2.0
