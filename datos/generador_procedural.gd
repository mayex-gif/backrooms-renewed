class_name GeneradorProcedural
extends RefCounted
## Construye un mapa de colocaciones reproducible sin instanciar escenas.

var _rng := RandomNumberGenerator.new()
var _grilla := GrillaOcupacion.new()
var _colocadas: Array[Dictionary] = []
var _pendientes: Array[Dictionary] = []
var _avisos: PackedStringArray = PackedStringArray()

## Devuelve {"salas": [...], "semilla": int, "pendientes": int}.
## Una semilla negativa elige una semilla nueva y la devuelve para repetirla.
func generar(definiciones: Array[SalaDef], semilla: int, max_salas: int) -> Dictionary:
	_rng = RandomNumberGenerator.new()
	if semilla == -1:
		_rng.randomize()
	else:
		_rng.seed = semilla
	_grilla = GrillaOcupacion.new()
	_colocadas.clear()
	_pendientes.clear()
	_avisos.clear()
	var definiciones_validas := _validar_definiciones(definiciones)
	if max_salas <= 0:
		return _resultado()
	var inicial := _elegir_definicion_valida(definiciones_validas)
	if inicial == null:
		return _resultado()
	_agregar_sala(inicial, Vector3.ZERO, 0, inicial.huella.duplicate())
	for socket_indice in inicial.sockets.size():
		_agregar_socket_pendiente(0, inicial, socket_indice, Vector3.ZERO, 0)
	while not _pendientes.is_empty() and _colocadas.size() < max_salas:
		var destino: Dictionary = _pendientes.pop_front()
		var opciones := _buscar_colocaciones(definiciones_validas, destino)
		if opciones.is_empty():
			continue
		var elegida: Dictionary = _elegir_ponderada(opciones)
		var sala: SalaDef = elegida.sala
		var id_nuevo := _colocadas.size()
		_agregar_sala(sala, elegida.origen, elegida.giros, elegida.celdas)
		_colocadas[id_nuevo]["conexion"] = {
			"sala_destino_id": destino.sala_id,
			"socket_destino_indice": destino.socket_indice,
			"socket_nuevo_indice": elegida.socket_indice,
			"ancho_pasaje": elegida.ancho_pasaje,
			"relleno_por_lado": elegida.relleno_por_lado
		}
		for socket_indice in sala.sockets.size():
			if socket_indice == elegida.socket_indice:
				continue
			_agregar_socket_pendiente(id_nuevo, sala, socket_indice, elegida.origen, elegida.giros)
	return _resultado()

func _validar_definiciones(definiciones: Array[SalaDef]) -> Array[SalaDef]:
	var validas: Array[SalaDef] = []
	var instancias_vistas: Dictionary = {}
	for indice in definiciones.size():
		var definicion := definiciones[indice]
		if definicion == null:
			_avisos.append("La definición %d es nula y se omitió." % indice)
			continue
		var id := definicion.get_instance_id()
		if instancias_vistas.has(id):
			_avisos.append("La sala '%s' está repetida en el catálogo y se omitió la entrada duplicada." % definicion.nombre)
			continue
		instancias_vistas[id] = true
		var errores := definicion.validar_forma()
		if not is_finite(definicion.peso) or definicion.peso <= 0.0:
			errores.append("El peso debe ser un número finito mayor que cero.")
		if definicion.limite_maximo < 0:
			errores.append("El límite máximo no puede ser negativo.")
		if errores.is_empty():
			validas.append(definicion)
		else:
			_avisos.append("Sala '%s': %s" % [definicion.nombre, "; ".join(errores)])
	return validas

func _elegir_definicion_valida(definiciones: Array[SalaDef]) -> SalaDef:
	var candidatas: Array[Dictionary] = []
	for definicion in definiciones:
		if _puede_aparecer(definicion):
			candidatas.append({"sala": definicion, "peso": definicion.peso})
	if candidatas.is_empty():
		return null
	return _elegir_ponderada(candidatas).sala

func _buscar_colocaciones(definiciones: Array[SalaDef], destino: Dictionary) -> Array[Dictionary]:
	var opciones: Array[Dictionary] = []
	var sockets_viables_por_sala: Dictionary = {}
	for definicion in definiciones:
		if not _puede_aparecer(definicion):
			continue
		for indice in definicion.sockets.size():
			var socket: SocketDef = definicion.sockets[indice]
			var col := Colocacion.calcular(
				definicion,
				indice,
				destino.posicion,
				destino.direccion,
				destino.ancho
			)
			if not col.alineada or not _grilla.esta_libre(col.celdas):
				continue
			var id_recurso := definicion.get_instance_id()
			sockets_viables_por_sala[id_recurso] = sockets_viables_por_sala.get(id_recurso, 0) + 1
			opciones.append({
				"sala": definicion,
				"socket_indice": indice,
				"origen": col.origen,
				"giros": col.giros,
				"angulo_y": col.angulo_y,
				"celdas": col.celdas,
				"ancho_pasaje": col.ancho_pasaje,
				"relleno_por_lado": col.relleno_por_lado,
				"peso": 0.0
			})
	for opcion in opciones:
		var recurso: SalaDef = opcion.sala
		opcion.peso = recurso.peso / float(sockets_viables_por_sala[recurso.get_instance_id()])
	return opciones

func _puede_aparecer(definicion: SalaDef) -> bool:
	if definicion.limite_maximo == 0:
		return true
	var apariciones := 0
	for colocada in _colocadas:
		if colocada.sala == definicion:
			apariciones += 1
	return apariciones < definicion.limite_maximo

func _elegir_ponderada(opciones: Array[Dictionary]) -> Dictionary:
	var peso_total := 0.0
	for opcion in opciones:
		peso_total += opcion.peso
	var objetivo := _rng.randf() * peso_total
	for opcion in opciones:
		objetivo -= opcion.peso
		if objetivo <= 0.0:
			return opcion
	return opciones.back()

func _agregar_sala(definicion: SalaDef, origen: Vector3, giros: int, celdas: Array[Vector2i]) -> void:
	var id := _colocadas.size()
	_grilla.ocupar(celdas, id)
	_colocadas.append({
		"id": id,
		"sala": definicion,
		"origen": origen,
		"giros": giros,
		"angulo_y": -giros * PI / 2.0,
		"celdas": celdas
	})

func _agregar_socket_pendiente(id_sala: int, definicion: SalaDef, indice: int, origen: Vector3, giros: int) -> void:
	var socket: SocketDef = definicion.sockets[indice]
	_pendientes.append({
		"sala_id": id_sala,
		"socket_indice": indice,
		"posicion": origen + Direcciones.rotar_punto(socket.posicion_local, giros),
		"direccion": Direcciones.girar(socket.direccion, giros),
		"ancho": socket.ancho
	})

func _resultado() -> Dictionary:
	return {
		"salas": _colocadas.duplicate(true),
		"semilla": _rng.seed,
		"pendientes": _pendientes.size(),
		"avisos": _avisos.duplicate()
	}
