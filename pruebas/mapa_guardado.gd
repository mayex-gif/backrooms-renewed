extends Node3D
## Carga y permite recorrer user://saves/mapa_actual.json.

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")
const PlanificadorSolapesScript = preload("res://datos/planificador_solapes.gd")
const CierresSalaScript = preload("res://salas/cierres_sala.gd")

const RUTA_MAPA := "user://saves/mapa_actual.json"
var _catalogo: Array[SalaDef] = []
var _instancias: Array[Node3D] = []

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
	var definiciones: Array[SalaDef] = []
	var giros_salas: Array[float] = []
	var origenes: Array[Vector3] = []
	var sockets_instancia: Array[Array] = []
	var huellas: Array[PackedVector2Array] = []
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
		var giros := deg_to_rad(float(item.get("angulo", int(item.get("giros", 0)) * 90)))
		var centro := Vector2(float(item.get("x", 0)), float(item.get("z", 0)))
		if not item.has("angulo"):
			var ancho_legacy := definicion.ancho_m if posmod(int(item.get("giros", 0)), 2) == 0 else definicion.largo_m
			var largo_legacy := definicion.largo_m if posmod(int(item.get("giros", 0)), 2) == 0 else definicion.ancho_m
			centro += Vector2(ancho_legacy, largo_legacy) * 0.5
		var origen := Vector3(centro.x, 0, centro.y)
		var origen_nodo := _origen_nodo(origen, definicion, giros)
		definiciones.append(definicion)
		giros_salas.append(giros)
		origenes.append(origen_nodo)
		sockets_instancia.append(_crear_lista_sockets())
		var huella := _huella_mundo(definicion, centro, giros)
		huellas.append(huella)
		rectangulos.append(GeometriaHuella.limites(huella))
	# Las puertas se calculan en ConexionesMapa (el editor usa el mismo cálculo).
	var modulos: Array[Dictionary] = []
	for i in definiciones.size():
		modulos.append({"id": ids[i], "rect": rectangulos[i], "centro": rectangulos[i].get_center(), "ancho": definiciones[i].ancho_m, "largo": definiciones[i].largo_m, "angulo": giros_salas[i], "poligono": huellas[i]})
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
		for zona in par.poligonos:
			exclusiones_piso[b].append(_poligono_local(zona, origenes[b], giros_salas[b]))
			var recortar_techo := PlanificadorSolapesScript.indice_techo_a_recortar(definiciones[a].alto_m, definiciones[b].alto_m, a, b)
			exclusiones_techo[recortar_techo].append(_poligono_local(zona, origenes[recortar_techo], giros_salas[recortar_techo]))
	var todas: Array[Dictionary] = ConexionesMapaScript.calcular(modulos, estados)
	# Las conexiones cerradas se quedan como pared: no se construye nada para ellas.
	var conexiones: Array[Dictionary] = ConexionesMapaScript.activas(todas)
	print("[MapaGuardado] módulos: %d · puertas: %d · cerradas: %d" % [definiciones.size(), conexiones.size(), todas.size() - conexiones.size()])
	for conexion in conexiones:
		_agregar_puertas_pareadas(conexion, definiciones, giros_salas, origenes, sockets_instancia)
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
		instancia.set("huella_local", definicion.obtener_huella_local())
		instancia.set("columnas", definicion.columnas_locales)
		instancia.set("zonas_suelo_excluidas", exclusiones_piso[i])
		instancia.set("zonas_techo_excluidas", exclusiones_techo[i])
		instancia.set("sockets", sockets_instancia[i])
		print("[MapaGuardado] %s: %d sockets" % [definicion.nombre, sockets_instancia[i].size()])
		instancia.set("semilla_ambiente", i * 7919 + 2026)
		instancia.position = origenes[i]
		instancia.rotation.y = -giros_salas[i]
		salas.add_child(instancia)
		_instancias.append(instancia)
	for conexion in conexiones:
		_cerrar_diferencia_de_altura(conexion, definiciones)
	var inicio: Variant = datos.get("inicio", {})
	if inicio is Dictionary and inicio.has("x") and inicio.has("z"):
		# El ángulo del editor apunta en el plano X/Z; el "adelante" del jugador es -Z.
		var direccion := Vector2.from_angle(deg_to_rad(float(inicio.get("angulo", 0.0))))
		jugador.global_position = Vector3(float(inicio.x), 0.02, float(inicio.z))
		jugador.rotation.y = atan2(-direccion.x, -direccion.y)
	elif not definiciones.is_empty():
		jugador.global_position = Vector3(rectangulos[0].get_center().x, 0.02, rectangulos[0].get_center().y)

func _agregar_puertas_pareadas(conexion: Dictionary, definiciones: Array[SalaDef], giros: Array[float], origenes: Array[Vector3], sockets: Array[Array]) -> void:
	var a: int = conexion.a
	var b: int = conexion.b
	var dir_a: Direcciones.Dir = conexion.dir_a
	var dir_b: Direcciones.Dir = conexion.dir_b
	var punto_a: Vector2 = conexion.punto_a
	var punto_b: Vector2 = conexion.punto_b
	var ancho: float = conexion.ancho
	var completa: bool = conexion.completa
	var sa := SocketDef.new()
	sa.direccion = [Direcciones.Dir.NORTE, Direcciones.Dir.ESTE, Direcciones.Dir.SUR, Direcciones.Dir.OESTE][posmod(int(conexion.get("lado_a", dir_a)), 4)]
	sa.arista = int(conexion.get("arista_a", conexion.get("lado_a", dir_a)))
	sa.rotacion_pared = _rotacion_arista(definiciones[a], sa.arista)
	sa.ancho = ancho
	sa.continuar_sala = completa
	sa.sin_dintel = conexion.sin_dintel
	sa.posicion_local = _punto_local(punto_a, origenes[a], giros[a])
	var sb := SocketDef.new()
	sb.direccion = [Direcciones.Dir.NORTE, Direcciones.Dir.ESTE, Direcciones.Dir.SUR, Direcciones.Dir.OESTE][posmod(int(conexion.get("lado_b", dir_b)), 4)]
	sb.arista = int(conexion.get("arista_b", conexion.get("lado_b", dir_b)))
	sb.rotacion_pared = _rotacion_arista(definiciones[b], sb.arista)
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
	if conexion.completa:
		# Pared quitada entera: el módulo alto queda abierto por encima del techo del bajo.
		if is_equal_approx(alto_a, alto_b):
			return
		var a_es_baja := alto_a < alto_b
		var id_baja := a if a_es_baja else b
		var socket_baja := socket_a if a_es_baja else socket_b
		CierresSalaScript.cierre_pared_completa(_instancias[id_baja], socket_baja, definiciones[id_baja], minf(alto_a, alto_b), maxf(alto_a, alto_b))
	elif conexion.sin_dintel:
		# Abertura de piso a techo entre paredes que no coinciden: el módulo alto
		# necesita un panel sobre el techo del bajo.
		if is_equal_approx(alto_a, alto_b):
			return
		var a_es_alta := alto_a > alto_b
		var id_alta := a if a_es_alta else b
		var socket_alta := socket_a if a_es_alta else socket_b
		CierresSalaScript.panel_sobre_puerta(_instancias[id_alta], socket_alta, minf(alto_a, alto_b), maxf(alto_a, alto_b))
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

func _crear_lista_sockets() -> Array[SocketDef]:
	var sockets: Array[SocketDef] = []
	return sockets

func _agregar_hueco_interseccion(segmento: Dictionary, definiciones: Array[SalaDef], giros: Array[float], origenes: Array[Vector3], sockets: Array[Array]) -> void:
	var indice: int = segmento.modulo
	var inicio: Vector2 = segmento.inicio
	var fin: Vector2 = segmento.fin
	var socket := SocketDef.new()
	socket.arista = int(segmento.arista)
	socket.rotacion_pared = _rotacion_arista(definiciones[indice], socket.arista)
	socket.direccion = Direcciones.Dir.NORTE
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

func _poligono_local(poligono: PackedVector2Array, origen: Vector3, giros: float) -> PackedVector2Array:
	var locales := PackedVector2Array()
	for punto in poligono:
		var local := _punto_local(punto, origen, giros)
		locales.append(Vector2(local.x, local.z))
	return locales

func _rotacion_arista(definicion: SalaDef, indice: int) -> float:
	var huella := definicion.obtener_huella_local()
	var eje := huella[(indice + 1) % huella.size()] - huella[indice]
	return -atan2(eje.y, eje.x)

func _punto_local(punto: Vector2, origen: Vector3, giros: float) -> Vector3:
	var delta := Vector3(punto.x - origen.x, 0, punto.y - origen.z)
	return delta.rotated(Vector3.UP, giros)

func _origen_nodo(centro: Vector3, definicion: SalaDef, angulo: float) -> Vector3:
	var centro_local := Vector3(definicion.ancho_m * 0.5, 0, definicion.largo_m * 0.5)
	return centro - centro_local.rotated(Vector3.UP, -angulo)

func _huella_mundo(definicion: SalaDef, centro: Vector2, angulo: float) -> PackedVector2Array:
	var local := definicion.obtener_huella_local()
	var centro_local := GeometriaHuella.limites(local).get_center()
	var mundo := PackedVector2Array()
	for punto in local:
		mundo.append(centro + (punto - centro_local).rotated(angulo))
	return mundo

func _indice_tipo(nombre: String) -> int:
	for i in _catalogo.size():
		if _catalogo[i].nombre == nombre:
			return i
	return -1
