extends Node3D
## Carga y permite recorrer user://saves/mapa_actual.json.

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")
const PlanificadorSolapesScript = preload("res://datos/planificador_solapes.gd")
const CierresSalaScript = preload("res://salas/cierres_sala.gd")

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
	var ids: Array[int] = []
	var posicion_fila := -1
	for item in datos.salas:
		posicion_fila += 1
		var indice := _indice_tipo(String(item.get("tipo", "")))
		if indice < 0:
			continue
		# Sin "id" (mapas viejos) vale la posición de la fila, igual que en el editor.
		ids.append(int(item.get("id", posicion_fila)))
		var definicion := _catalogo[indice]
		var giros := int(item.get("giros", 0))
		var origen := Vector3(float(item.get("x", 0)), 0, float(item.get("z", 0)))
		var origen_nodo := _origen_nodo(origen, definicion, giros)
		definiciones.append(definicion)
		giros_salas.append(giros)
		origenes.append(origen_nodo)
		sockets_instancia.append(_crear_lista_sockets())
		var ancho := definicion.ancho_m if giros % 2 == 0 else definicion.largo_m
		var largo := definicion.largo_m if giros % 2 == 0 else definicion.ancho_m
		rectangulos.append(Rect2(Vector2(origen.x, origen.z), Vector2(ancho, largo)))
	# Las puertas se calculan en ConexionesMapa (el editor usa el mismo cálculo).
	var modulos: Array[Dictionary] = []
	for i in definiciones.size():
		modulos.append({"id": ids[i], "rect": rectangulos[i], "circular": _es_circular(definiciones[i])})
	var estados: Dictionary = {}
	var guardados: Variant = datos.get("conexiones", {})
	if guardados is Dictionary:
		estados = guardados
	var estados_solape: Dictionary = {}
	var solapes_guardados: Variant = datos.get("solapes", {})
	if solapes_guardados is Dictionary:
		estados_solape = solapes_guardados
	var plan_solapes: Dictionary = PlanificadorSolapesScript.calcular(modulos, estados_solape)
	var exclusiones_piso: Array = []
	var exclusiones_techo: Array = []
	for i in definiciones.size():
		exclusiones_piso.append([])
		exclusiones_techo.append([])
	for par in plan_solapes.pares:
		var a: int = par.a
		var b: int = par.b
		var zona: Rect2 = par.rect
		exclusiones_piso[b].append(_rectangulo_local(zona, origenes[b], giros_salas[b]))
		var alto_a := definiciones[a].alto_m
		var alto_b := definiciones[b].alto_m
		var indice_techo_recortado := PlanificadorSolapesScript.indice_techo_a_recortar(rectangulos[a], alto_a, rectangulos[b], alto_b, a, b)
		if indice_techo_recortado >= 0:
			exclusiones_techo[indice_techo_recortado].append(_rectangulo_local(zona, origenes[indice_techo_recortado], giros_salas[indice_techo_recortado]))
	var todas: Array[Dictionary] = ConexionesMapaScript.calcular(modulos, _paredes_abiertas, estados)
	# Las conexiones cerradas se quedan como pared: no se construye nada para ellas.
	var conexiones: Array[Dictionary] = ConexionesMapaScript.activas(todas)
	print("[MapaGuardado] módulos: %d · puertas: %d · cerradas: %d" % [definiciones.size(), conexiones.size(), todas.size() - conexiones.size()])
	for conexion in conexiones:
		_agregar_puertas_pareadas(conexion, giros_salas, origenes, sockets_instancia)
		_crear_piso_puente(conexion.punto_a, conexion.punto_b, conexion.ancho)
	for segmento in plan_solapes.segmentos:
		if String(segmento.estado) != ConexionesMapaScript.ESTADO_CERRADA:
			_agregar_hueco_interseccion(segmento, definiciones, giros_salas, origenes, sockets_instancia)
	for segmento in plan_solapes.ocultos:
		_agregar_hueco_interseccion(segmento, definiciones, giros_salas, origenes, sockets_instancia)
	for i in definiciones.size():
		var definicion := definiciones[i]
		var instancia := definicion.escena.instantiate() as Node3D
		instancia.set("ancho_m", definicion.ancho_m)
		instancia.set("largo_m", definicion.largo_m)
		instancia.set("alto_m", definicion.alto_m)
		if _es_circular(definicion):
			instancia.set("radio_m", minf(definicion.ancho_m, definicion.largo_m) * 0.5)
			for socket in definicion.sockets:
				sockets_instancia[i].append(socket.duplicate(true))
		else:
			instancia.set("columnas", definicion.columnas_locales)
			instancia.set("zonas_suelo_excluidas", exclusiones_piso[i])
			instancia.set("zonas_techo_excluidas", exclusiones_techo[i])
		instancia.set("sockets", sockets_instancia[i])
		print("[MapaGuardado] %s: %d sockets" % [definicion.nombre, sockets_instancia[i].size()])
		instancia.set("semilla_ambiente", i * 7919 + 2026)
		instancia.position = origenes[i]
		instancia.rotation.y = -giros_salas[i] * PI / 2.0
		salas.add_child(instancia)
		_instancias.append(instancia)
	for conexion in conexiones:
		_cerrar_diferencia_de_altura(conexion, definiciones)
	_cerrar_salidas_sin_conexion(definiciones, sockets_instancia)
	if not definiciones.is_empty():
		jugador.global_position = Vector3(rectangulos[0].get_center().x, 0.02, rectangulos[0].get_center().y)

func _agregar_puertas_pareadas(conexion: Dictionary, giros: Array[int], origenes: Array[Vector3], sockets: Array[Array]) -> void:
	var a: int = conexion.a
	var b: int = conexion.b
	var dir_a: Direcciones.Dir = conexion.dir_a
	var dir_b: Direcciones.Dir = conexion.dir_b
	var punto_a: Vector2 = conexion.punto_a
	var punto_b: Vector2 = conexion.punto_b
	var ancho: float = conexion.ancho
	var completa: bool = conexion.completa
	var sa := SocketDef.new()
	sa.direccion = Direcciones.girar(dir_a, -giros[a])
	sa.ancho = ancho
	sa.continuar_sala = completa
	sa.sin_dintel = conexion.sin_dintel
	sa.posicion_local = _punto_local(punto_a, origenes[a], giros[a])
	var sb := SocketDef.new()
	sb.direccion = Direcciones.girar(dir_b, -giros[b])
	sb.ancho = ancho
	sb.continuar_sala = completa
	sb.sin_dintel = conexion.sin_dintel
	sb.posicion_local = _punto_local(punto_b, origenes[b], giros[b])
	sockets[a].append(sa)
	sockets[b].append(sb)
	# Se guardan para tapar después las diferencias de altura (_cerrar_diferencia_de_altura).
	conexion["socket_a"] = sa
	conexion["socket_b"] = sb

## Si los dos módulos unidos tienen techos distintos, tapa lo que queda abierto.
func _cerrar_diferencia_de_altura(conexion: Dictionary, definiciones: Array[SalaDef]) -> void:
	var a: int = conexion.a
	var b: int = conexion.b
	var socket_a: SocketDef = conexion.socket_a
	var socket_b: SocketDef = conexion.socket_b
	var alto_a := definiciones[a].alto_m
	var alto_b := definiciones[b].alto_m
	if conexion.sin_dintel:
		return
	if conexion.completa:
		# Pared quitada entera: el módulo alto queda abierto por encima del techo del bajo.
		if is_equal_approx(alto_a, alto_b):
			return
		var a_es_baja := alto_a < alto_b
		var id_baja := a if a_es_baja else b
		var socket_baja := socket_a if a_es_baja else socket_b
		CierresSalaScript.cierre_pared_completa(_instancias[id_baja], socket_baja, definiciones[id_baja], minf(alto_a, alto_b), maxf(alto_a, alto_b))
	else:
		# Puerta común: solo importa si una de las dos es más baja que la puerta estándar.
		var puerta_a := minf(CierresSalaScript.ALTO_PUERTA, alto_a)
		var puerta_b := minf(CierresSalaScript.ALTO_PUERTA, alto_b)
		if is_equal_approx(puerta_a, puerta_b):
			return
		var a_es_mayor := puerta_a > puerta_b
		var id_mayor := a if a_es_mayor else b
		var socket_mayor := socket_a if a_es_mayor else socket_b
		CierresSalaScript.panel_sobre_puerta(_instancias[id_mayor], socket_mayor, minf(puerta_a, puerta_b), maxf(puerta_a, puerta_b))

func _es_circular(definicion: SalaDef) -> bool:
	return definicion.escena.resource_path.ends_with("sala_circular.tscn")

func _crear_lista_sockets() -> Array[SocketDef]:
	var sockets: Array[SocketDef] = []
	return sockets

func _agregar_hueco_interseccion(segmento: Dictionary, definiciones: Array[SalaDef], giros: Array[int], origenes: Array[Vector3], sockets: Array[Array]) -> void:
	var indice: int = segmento.modulo
	var inicio: Vector2 = segmento.inicio
	var fin: Vector2 = segmento.fin
	var direccion: Direcciones.Dir = segmento.direccion
	var socket := SocketDef.new()
	socket.direccion = Direcciones.girar(direccion, -giros[indice])
	var largo := inicio.distance_to(fin)
	var estado := String(segmento.estado)
	if estado == ConexionesMapaScript.ESTADO_PUERTA:
		socket.ancho = minf(ConexionesMapaScript.PASO_MAXIMO, largo)
	else:
		socket.ancho = largo
	if estado == ConexionesMapaScript.ESTADO_INTERSECCION:
		var pares: Array = segmento.get("pares", [])
		if pares.is_empty():
			socket.sin_dintel = true
		else:
			var techos_solapados: Array[float] = []
			for otro_indice in pares:
				techos_solapados.append(definiciones[int(otro_indice)].alto_m)
			socket.altura_abertura_m = PlanificadorSolapesScript.altura_abertura_interseccion(definiciones[indice].alto_m, techos_solapados)
			socket.sin_dintel = socket.altura_abertura_m >= definiciones[indice].alto_m - 0.001
	else:
		socket.sin_dintel = false
	socket.posicion_local = _punto_local((inicio + fin) * 0.5, origenes[indice], giros[indice])
	sockets[indice].append(socket)

func _rectangulo_local(rect: Rect2, origen: Vector3, giros: int) -> Rect2:
	var esquinas: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	var locales: Array[Vector2] = []
	for esquina in esquinas:
		var local := _punto_local(esquina, origen, giros)
		locales.append(Vector2(local.x, local.z))
	var min_x := locales[0].x
	var max_x := locales[0].x
	var min_z := locales[0].y
	var max_z := locales[0].y
	for local in locales:
		min_x = minf(min_x, local.x)
		max_x = maxf(max_x, local.x)
		min_z = minf(min_z, local.y)
		max_z = maxf(max_z, local.y)
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))

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
		if _es_circular(definiciones[i]):
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
