extends Control
## Editor 2D simple de módulos. Guarda diseños JSON en el espacio del usuario.

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")
const PlanificadorSolapesScript = preload("res://datos/planificador_solapes.gd")

var _catalogo: Array[SalaDef] = []
var _salas: Array[Dictionary] = []
var _seleccion := 0
var _angulo_seleccion := 0.0
var _escala := 24.0
var _desplazamiento_vista := Vector2.ZERO
var _lienzo: Control
var _selector: OptionButton
var _estado: Label
var _rotacion_visible: Label
var _dialogo: FileDialog
var _dialogo_salida: ConfirmationDialog
var _ruta_actual := "user://saves/mapa_actual.json"
var _lista_guardados: OptionButton
var _arrastre := -1
var _seleccion_sala := -1
var _desfase_arrastre := Vector2.ZERO
var _paneo_activo := false
var _ultima_posicion_paneo := Vector2.ZERO
## Módulos del archivo cuyo tipo ya no existe en el catálogo. Se conservan tal
## cual para que el autoguardado no los borre del JSON.
var _desconocidas: Array = []
## Nombres retirados del catálogo del editor, conservados como equivalentes geométricos.
var _alias_tipos: Dictionary = {}
## Estado elegido a mano para cada conexión: clave (ConexionesMapa.clave_de) -> estado.
var _estados_conexion: Dictionary = {}
## Estado por tramo interior superpuesto: true lo abre, false lo conserva como tabique.
var _estados_solape: Dictionary = {}
var _siguiente_id := 0
var _hay_cambios := false

func _ready() -> void:
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	var catalogo_completo := script_catalogo.call("crear") as Array[SalaDef]
	_catalogo = _quitar_duplicados_catalogo(catalogo_completo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	_crear_interfaz()
	if FileAccess.file_exists(_ruta_actual):
		_cargar_ruta(_ruta_actual)
	queue_redraw()

func _crear_interfaz() -> void:
	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(columna)
	var barra := HFlowContainer.new()
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_child(barra)
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for definicion in _catalogo:
		_selector.add_item("%s  (%.1f × %.1f m)" % [definicion.nombre, definicion.ancho_m, definicion.largo_m])
	_selector.item_selected.connect(func(indice: int) -> void:
		_seleccion = indice
		_seleccion_sala = -1
		_actualizar_rotacion_visible()
		_lienzo.queue_redraw()
	)
	barra.add_child(_selector)
	_agregar_boton(barra, "Pieza −5°", func() -> void: _girar_pieza(-5.0))
	_agregar_boton(barra, "Pieza +5°", func() -> void: _girar_pieza(5.0))
	_agregar_boton(barra, "Sala −5°", func() -> void: _girar_sala(-5.0))
	_agregar_boton(barra, "Sala +5°", func() -> void: _girar_sala(5.0))
	_rotacion_visible = Label.new()
	_rotacion_visible.custom_minimum_size.x = 170
	barra.add_child(_rotacion_visible)
	_actualizar_rotacion_visible()
	_agregar_boton(barra, "Guardar", func() -> void: _guardar_actual(true))
	_agregar_boton(barra, "Guardar como", _abrir_guardar)
	_agregar_boton(barra, "Jugar", _jugar)
	_agregar_boton(barra, "Cargar", _abrir_cargar)
	_lista_guardados = OptionButton.new()
	_lista_guardados.item_selected.connect(_seleccionar_guardado)
	barra.add_child(_lista_guardados)
	_agregar_boton(barra, "Limpiar", _limpiar)
	_agregar_boton(barra, "Volver", _solicitar_salir)
	_lienzo = Control.new()
	_lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lienzo.draw.connect(_dibujar)
	_lienzo.gui_input.connect(_entrada_lienzo)
	columna.add_child(_lienzo)
	_estado = Label.new()
	_estado.custom_minimum_size.y = 28
	_estado.text = "Click: colocar/cambiar · arrastrar: mover sala · R/Mayús+R: girar ±5° · botón central: mover lienzo · rueda: zoom · clic derecho: borrar · Escape: salir"
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_child(_estado)
	_dialogo_salida = ConfirmationDialog.new()
	_dialogo_salida.title = "Salir del editor"
	_dialogo_salida.dialog_text = "Hay cambios en el mapa. ¿Querés guardar y salir? Los cambios también se autoguardan en mapa_actual.json."
	_dialogo_salida.ok_button_text = "Guardar y salir"
	_dialogo_salida.add_button("Salir", true, "salir")
	_dialogo_salida.confirmed.connect(_guardar_y_salir)
	_dialogo_salida.custom_action.connect(_accion_salida)
	add_child(_dialogo_salida)
	_dialogo = FileDialog.new()
	_dialogo.access = FileDialog.ACCESS_FILESYSTEM
	_dialogo.add_filter("*.json", "Mapa JSON")
	add_child(_dialogo)
	_dialogo.file_selected.connect(_archivo_elegido)
	_actualizar_guardados()

func _agregar_boton(barra: Container, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(accion)
	barra.add_child(boton)

func _girar_pieza(delta: float) -> void:
	_angulo_seleccion = fposmod(_angulo_seleccion + delta, 360.0)
	_actualizar_rotacion_visible()
	_lienzo.queue_redraw()

func _girar_sala(delta: float) -> void:
	if _seleccion_sala < 0 or _seleccion_sala >= _salas.size():
		_estado.text = "Seleccioná una sala para girarla."
		return
	var propuesta: Dictionary = _salas[_seleccion_sala].duplicate()
	propuesta.angulo = fposmod(float(propuesta.angulo) + delta, 360.0)
	_salas[_seleccion_sala].angulo = propuesta.angulo
	_actualizar_rotacion_visible()
	_cambio_mapa("Sala girada a %.0f°." % float(propuesta.angulo))

func _actualizar_rotacion_visible() -> void:
	if _rotacion_visible == null:
		return
	if _seleccion_sala >= 0 and _seleccion_sala < _salas.size():
		_rotacion_visible.text = "Sala: %.0f° · Pieza: %.0f°" % [float(_salas[_seleccion_sala].angulo), _angulo_seleccion]
	else:
		_rotacion_visible.text = "Pieza: %.0f°" % _angulo_seleccion

func _limpiar() -> void:
	_salas.clear()
	_seleccion_sala = -1
	_actualizar_rotacion_visible()
	_desconocidas.clear()
	_estados_conexion.clear()
	_estados_solape.clear()
	_cambio_mapa("Mapa limpio.")

func _abrir_guardar() -> void:
	_dialogo.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_dialogo.current_dir = ProjectSettings.globalize_path("user://saves")
	_dialogo.current_file = "mapa_personalizado.json"
	_dialogo.popup_centered(Vector2i(760, 520))

func _abrir_cargar() -> void:
	_dialogo.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialogo.popup_centered(Vector2i(760, 520))

func _archivo_elegido(ruta: String) -> void:
	if _dialogo.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		var archivo := FileAccess.open(ruta, FileAccess.WRITE)
		if archivo == null:
			_estado.text = "No se pudo guardar el archivo."
			return
		archivo.store_string(_serializar())
		_ruta_actual = ruta
		_hay_cambios = false
		_estado.text = "Mapa guardado: %s" % ruta
		_actualizar_guardados()
	else:
		_cargar_ruta(ruta)
	_lienzo.queue_redraw()
	_actualizar_guardados()

func _guardar_actual(marcar_guardado: bool = false) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var archivo := FileAccess.open(_ruta_actual, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo guardar el mapa."
		return
	archivo.store_string(_serializar())
	if marcar_guardado:
		_hay_cambios = false
	_estado.text = "Guardado: %s" % _ruta_actual.get_file()
	_actualizar_guardados()

## Texto JSON del mapa actual. Conserva los módulos de tipo desconocido.
func _serializar() -> String:
	var filas: Array = _salas.map(func(s: Dictionary) -> Dictionary: return {"id": s.id, "tipo": s.tipo, "x": s.x, "z": s.z, "angulo": s.angulo})
	filas.append_array(_desconocidas)
	return JSON.stringify({"version": 4, "conexiones": _estados_conexion, "solapes": _estados_solape, "salas": filas}, "\t")

func _actualizar_guardados() -> void:
	if _lista_guardados == null:
		return
	_lista_guardados.clear()
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return
	dir.list_dir_begin()
	var nombre := dir.get_next()
	while not nombre.is_empty():
		if not dir.current_is_dir() and nombre.ends_with(".json"):
			_lista_guardados.add_item(nombre)
			_lista_guardados.set_item_metadata(_lista_guardados.item_count - 1, "user://saves/" + nombre)
		nombre = dir.get_next()
	dir.list_dir_end()

func _seleccionar_guardado(indice: int) -> void:
	var ruta := String(_lista_guardados.get_item_metadata(indice))
	if ruta.is_empty():
		return
	_cargar_ruta(ruta)

func _cargar_ruta(ruta: String) -> void:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_estado.text = "No se pudo abrir el mapa guardado."
		return
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if not datos is Dictionary or not datos.has("salas"):
		_estado.text = "El archivo no contiene un mapa válido."
		return
	_salas.clear()
	_desconocidas.clear()
	_estados_conexion.clear()
	_estados_solape.clear()
	var estados_guardados: Variant = datos.get("conexiones", {})
	if estados_guardados is Dictionary:
		for clave in estados_guardados:
			if ConexionesMapaScript.ESTADOS.has(String(estados_guardados[clave])):
				_estados_conexion[String(clave)] = String(estados_guardados[clave])
	var solapes_guardados: Variant = datos.get("solapes", {})
	if solapes_guardados is Dictionary:
		_estados_solape = solapes_guardados.duplicate()
	# Los mapas viejos no traen "id": se usa la posición de la fila en el archivo
	# (mapa_guardado.gd aplica la misma regla).
	_siguiente_id = 0
	var posicion_fila := 0
	for fila in datos.salas:
		var id_fila := int(fila.get("id", posicion_fila))
		_siguiente_id = maxi(_siguiente_id, id_fila + 1)
		var tipo_original := String(fila.get("tipo", ""))
		var tipo := String(_alias_tipos.get(tipo_original, tipo_original))
		if _indice_tipo(tipo) >= 0:
			var definicion := _catalogo[_indice_tipo(tipo)]
			var angulo := float(fila.get("angulo", int(fila.get("giros", 0)) * 90))
			var centro := Vector2(float(fila.x), float(fila.z))
			if not fila.has("angulo"):
				var cuarto := posmod(int(fila.get("giros", 0)), 4)
				var ancho := definicion.ancho_m if cuarto % 2 == 0 else definicion.largo_m
				var largo := definicion.largo_m if cuarto % 2 == 0 else definicion.ancho_m
				centro += Vector2(ancho, largo) * 0.5
			_salas.append({"id": id_fila, "tipo": tipo, "x": centro.x, "z": centro.y, "angulo": angulo})
		else:
			_desconocidas.append(fila)
		posicion_fila += 1
	_ruta_actual = ruta
	var aviso := ""
	if not _desconocidas.is_empty():
		aviso += " · %d módulos de un tipo que ya no existe se conservan sin mostrarse" % _desconocidas.size()
	var modulos_cargados := _modulos_para_conexiones()
	var pares_solape := ConexionesMapaScript.pares_solapados(modulos_cargados)
	if not pares_solape.is_empty():
		aviso += " · %d pares de salas se superponen; revisá sus paredes interiores" % pares_solape.size()
	_guardar_actual()
	_hay_cambios = false
	_estado.text = "Mapa cargado para editar: %s%s" % [ruta.get_file(), aviso]
	_actualizar_rotacion_visible()

func _jugar() -> void:
	_guardar_actual(true)
	get_tree().change_scene_to_file("res://pruebas/mapa_guardado.tscn")

func _solicitar_salir() -> void:
	if _hay_cambios:
		_dialogo_salida.popup_centered()
	else:
		get_tree().change_scene_to_file("res://pruebas/menu_principal.tscn")

func _guardar_y_salir() -> void:
	_guardar_actual(true)
	get_tree().change_scene_to_file("res://pruebas/menu_principal.tscn")

func _accion_salida(accion: StringName) -> void:
	if accion == "salir":
		# El mapa actual ya fue autoguardado en user://saves.
		get_tree().change_scene_to_file("res://pruebas/menu_principal.tscn")

func _indice_tipo(nombre: String) -> int:
	for i in _catalogo.size():
		if _catalogo[i].nombre == nombre:
			return i
	return -1

func _entrada_lienzo(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		if _paneo_activo:
			_desplazamiento_vista += evento.position - _ultima_posicion_paneo
			_ultima_posicion_paneo = evento.position
			_lienzo.queue_redraw()
		elif _arrastre >= 0:
			var centro_deseado := (_punto_mapa(evento.position) - _desfase_arrastre).snapped(Vector2(0.5, 0.5))
			var propuesta: Dictionary = _salas[_arrastre].duplicate()
			var definicion := _catalogo[_indice_tipo(String(propuesta.tipo))]
			var centro_ajustado := _centro_ajustado(centro_deseado, definicion, float(propuesta.angulo), _arrastre)
			_salas[_arrastre].x = centro_ajustado.x
			_salas[_arrastre].z = centro_ajustado.y
			_lienzo.queue_redraw()
	elif evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_MIDDLE and evento.pressed:
			_paneo_activo = true
			_ultima_posicion_paneo = evento.position
		elif evento.button_index == MOUSE_BUTTON_MIDDLE and not evento.pressed:
			_paneo_activo = false
		elif evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed and _arrastre >= 0:
			_arrastre = -1
			_hay_cambios = true
			_guardar_actual()
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_escala = minf(60.0, _escala * 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_escala = maxf(8.0, _escala / 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			var punto_mapa := _punto_mapa(evento.position)
			var clave_solape := _segmento_solape_en(punto_mapa)
			if not clave_solape.is_empty():
				var plan_actual: Dictionary = PlanificadorSolapesScript.calcular(_modulos_para_conexiones(), _estados_solape)
				var actual := ConexionesMapaScript.ESTADO_CERRADA
				for tramo in plan_actual.segmentos:
					if tramo.clave == clave_solape:
						actual = String(tramo.estado)
				var nuevo := PlanificadorSolapesScript.siguiente_estado(actual)
				_estados_solape[clave_solape] = nuevo
				_cambio_mapa("Pared interior: %s." % nuevo)
				return
			var clave_conexion := _conexion_en(punto_mapa)
			if not clave_conexion.is_empty():
				_cambiar_conexion(clave_conexion, evento.shift_pressed)
				return
			_arrastre = _indice_sala_en(punto_mapa)
			if _arrastre >= 0:
				_seleccion_sala = _arrastre
				_actualizar_rotacion_visible()
				_desfase_arrastre = _punto_mapa(evento.position) - Vector2(_salas[_arrastre].x, _salas[_arrastre].z)
			else:
				_seleccion_sala = -1
				_actualizar_rotacion_visible()
				_colocar(evento.position)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_RIGHT:
			_borrar(evento.position)
		_lienzo.queue_redraw()

## El lienzo no tiene foco de teclado, así que las teclas no llegan a su
## gui_input: se escuchan desde el nodo raíz.
func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla != null and tecla.pressed and not tecla.echo and tecla.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		var delta := -5.0 if tecla.shift_pressed else 5.0
		if _seleccion_sala >= 0 and _seleccion_sala < _salas.size():
			_girar_sala(delta)
		else:
			_girar_pieza(delta)
	elif tecla != null and tecla.pressed and not tecla.echo and tecla.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_solicitar_salir()

## Datos mínimos de cada sala para ConexionesMapa (el mismo cálculo que usa la escena jugable).
func _modulos_para_conexiones() -> Array[Dictionary]:
	var modulos: Array[Dictionary] = []
	for sala in _salas:
		var definicion := _catalogo[_indice_tipo(sala.tipo)]
		var angulo := deg_to_rad(float(sala.get("angulo", 0.0)))
		modulos.append({"id": sala.id, "rect": _rect_sala(sala), "centro": Vector2(sala.x, sala.z), "ancho": definicion.ancho_m, "largo": definicion.largo_m, "angulo": angulo, "poligono": PackedVector2Array(_vertices_sala(sala, definicion, angulo))})
	return modulos

func _colocar(posicion: Vector2) -> void:
	var definicion := _catalogo[_seleccion]
	var centro_deseado := _punto_mapa(posicion).snapped(Vector2(0.5, 0.5))
	var centro := _centro_ajustado(centro_deseado, definicion, _angulo_seleccion, -1)
	var nueva := {"tipo": definicion.nombre, "x": centro.x, "z": centro.y, "angulo": _angulo_seleccion}
	var id_nuevo := _siguiente_id
	_siguiente_id += 1
	nueva["id"] = id_nuevo
	_salas.append(nueva)
	_seleccion_sala = _salas.size() - 1
	_actualizar_rotacion_visible()
	_cambio_mapa("Sala colocada en (%.1f, %.1f), giro %.0f°." % [centro.x, centro.y, _angulo_seleccion])

## Ajusta cualquier par de aristas opuestas usando su normal y tangente.
func _centro_ajustado(deseado: Vector2, definicion: SalaDef, angulo_grados: float, ignorar: int) -> Vector2:
	const ALCANCE_AJUSTE := 1.25
	var nuevos := _vertices_sala({"x": deseado.x, "z": deseado.y}, definicion, deg_to_rad(angulo_grados))
	var mejor := deseado
	var mejor_distancia := ALCANCE_AJUSTE
	for indice in _salas.size():
		if indice == ignorar:
			continue
		var otra: Dictionary = _salas[indice]
		var definicion_otra := _catalogo[_indice_tipo(String(otra.tipo))]
		var existentes := _vertices_sala(otra, definicion_otra, deg_to_rad(float(otra.angulo)))
		for i in nuevos.size():
			var inicio_nuevo := nuevos[i]
			var fin_nuevo := nuevos[(i + 1) % nuevos.size()]
			var eje_nuevo := (fin_nuevo - inicio_nuevo).normalized()
			var normal := Vector2(eje_nuevo.y, -eje_nuevo.x)
			var tangente := eje_nuevo
			var plano_nuevo := inicio_nuevo.dot(normal)
			var nuevo_min := minf(inicio_nuevo.dot(tangente), fin_nuevo.dot(tangente))
			var nuevo_max := maxf(inicio_nuevo.dot(tangente), fin_nuevo.dot(tangente))
			for j in existentes.size():
				var inicio_otro := existentes[j]
				var fin_otro := existentes[(j + 1) % existentes.size()]
				var eje_otro := (fin_otro - inicio_otro).normalized()
				var normal_otro := Vector2(eje_otro.y, -eje_otro.x)
				if normal.dot(normal_otro) > -0.999:
					continue
				var plano_otro := inicio_otro.dot(normal)
				var otro_min := minf(inicio_otro.dot(tangente), fin_otro.dot(tangente))
				var otro_max := maxf(inicio_otro.dot(tangente), fin_otro.dot(tangente))
				var desplazamiento_min := otro_min + ConexionesMapaScript.PASO_MINIMO - nuevo_max
				var desplazamiento_max := otro_max - ConexionesMapaScript.PASO_MINIMO - nuevo_min
				if desplazamiento_min > desplazamiento_max:
					continue
				var delta_t := clampf(0.0, desplazamiento_min, desplazamiento_max)
				var candidato := deseado + normal * (plano_otro - plano_nuevo) + tangente * delta_t
				var propuesta := _trasladar_poligono(nuevos, candidato - deseado)
				var bloqueada := false
				for k in _salas.size():
					if k == ignorar or k == indice:
						continue
					var vecina: Dictionary = _salas[k]
					var def_vecina := _catalogo[_indice_tipo(String(vecina.tipo))]
					var huella_vecina := _vertices_sala(vecina, def_vecina, deg_to_rad(float(vecina.angulo)))
					if _poligonos_intersectan(propuesta, huella_vecina):
						bloqueada = true
						break
				if bloqueada:
					continue
				var distancia := candidato.distance_to(deseado)
				if distancia < mejor_distancia:
					mejor = candidato
					mejor_distancia = distancia
	return mejor

func _trasladar_poligono(poligono: Array[Vector2], desplazamiento: Vector2) -> Array[Vector2]:
	var trasladado: Array[Vector2] = []
	for punto in poligono:
		trasladado.append(punto + desplazamiento)
	return trasladado

func _rect_sala(sala: Dictionary) -> Rect2:
	var indice := _indice_tipo(sala.tipo)
	var definicion := _catalogo[indice]
	var angulo := deg_to_rad(float(sala.get("angulo", int(sala.get("giros", 0)) * 90)))
	var puntos := _vertices_sala(sala, definicion, angulo)
	var min_x := puntos[0].x
	var max_x := puntos[0].x
	var min_y := puntos[0].y
	var max_y := puntos[0].y
	for p in puntos:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func _vertices_sala(sala: Dictionary, definicion: SalaDef, angulo: float) -> Array[Vector2]:
	var centro := Vector2(float(sala.x), float(sala.z))
	var huella := definicion.obtener_huella_local()
	var centro_local := GeometriaHuella.limites(huella).get_center()
	var puntos: Array[Vector2] = []
	for local in huella:
		puntos.append(centro + (local - centro_local).rotated(angulo))
	return puntos

func _poligonos_intersectan(a: Array[Vector2], b: Array[Vector2]) -> bool:
	for poligono in [a, b]:
		for i in poligono.size():
			var eje: Vector2 = (poligono[(i + 1) % poligono.size()] - poligono[i]).orthogonal().normalized()
			var proy_a := _proyectar_poligono(a, eje)
			var proy_b := _proyectar_poligono(b, eje)
			if proy_a.y <= proy_b.x + 0.001 or proy_b.y <= proy_a.x + 0.001:
				return false
	return true

func _proyectar_poligono(puntos: Array[Vector2], eje: Vector2) -> Vector2:
	var minimo := puntos[0].dot(eje)
	var maximo := minimo
	for punto in puntos:
		minimo = minf(minimo, punto.dot(eje))
		maximo = maxf(maximo, punto.dot(eje))
	return Vector2(minimo, maximo)

func _distancia_punto_poligono(punto: Vector2, vertices: Array[Vector2]) -> float:
	var dentro := false
	for i in vertices.size():
		var a := vertices[i]
		var b := vertices[(i + 1) % vertices.size()]
		if Geometry2D.get_closest_point_to_segment(punto, a, b).distance_to(punto) <= 0.001:
			return 0.0
		if ((a.y > punto.y) != (b.y > punto.y)) and punto.x < (b.x - a.x) * (punto.y - a.y) / (b.y - a.y) + a.x:
			dentro = not dentro
	return 0.0 if dentro else INF

## Clave de la conexión cuya marca está cerca de un punto del mapa ("" si no hay).
func _conexion_en(punto: Vector2) -> String:
	var cercana := ""
	var mejor := 0.7
	for conexion in ConexionesMapaScript.calcular(_modulos_para_conexiones(), _estados_conexion):
		var mitad := maxf(conexion.ancho, 1.5) * 0.5
		var desvio: Vector2 = conexion.get("tangente", Vector2.RIGHT) * mitad
		for lado in ["punto_a", "punto_b"]:
			var centro: Vector2 = conexion[lado]
			var cerca := Geometry2D.get_closest_point_to_segment(punto, centro - desvio, centro + desvio)
			var distancia := cerca.distance_to(punto)
			if distancia < mejor:
				mejor = distancia
				cercana = conexion.clave
	return cercana

	## Click recorre los estados; Mayús vuelve al modo automático.
func _cambiar_conexion(clave: String, restablecer: bool) -> void:
	var actual: Dictionary = {}
	for conexion in ConexionesMapaScript.calcular(_modulos_para_conexiones(), _estados_conexion):
		if conexion.clave == clave:
			actual = conexion
	if actual.is_empty():
		return
	if restablecer:
		_estados_conexion.erase(clave)
		_cambio_mapa("Conexión %s: vuelve al modo automático." % clave)
	else:
		var nuevo := ConexionesMapaScript.siguiente_estado(String(actual.estado))
		_estados_conexion[clave] = nuevo
		_cambio_mapa("Conexión %s: %s." % [clave, nuevo])

func _borrar(posicion: Vector2) -> void:
	var indice := _indice_sala_en(_punto_mapa(posicion))
	if indice >= 0:
		var id_borrado: int = _salas[indice].id
		_salas.remove_at(indice)
		if _seleccion_sala == indice:
			_seleccion_sala = -1
		elif _seleccion_sala > indice:
			_seleccion_sala -= 1
		_actualizar_rotacion_visible()
		for clave in _estados_conexion.keys():
			var partes := String(clave).split(":")
			if partes.size() == 2 and (int(partes[0]) == id_borrado or int(partes[1]) == id_borrado):
				_estados_conexion.erase(clave)
		for clave in _estados_solape.keys():
			if String(clave).begins_with("%d:" % id_borrado):
				_estados_solape.erase(clave)
		_cambio_mapa("Sala eliminada.")

func _punto_mapa(posicion: Vector2) -> Vector2:
	return (posicion - _lienzo.size * 0.5 - _desplazamiento_vista) / _escala

func _indice_sala_en(punto: Vector2) -> int:
	for i in range(_salas.size() - 1, -1, -1):
		var sala := _salas[i]
		var definicion := _catalogo[_indice_tipo(String(sala.tipo))]
		if _distancia_punto_poligono(punto, _vertices_sala(sala, definicion, deg_to_rad(float(sala.get("angulo", 0.0))))) == 0.0:
			return i
	return -1

func _cambio_mapa(mensaje: String) -> void:
	_hay_cambios = true
	_guardar_actual()
	if not mensaje.is_empty():
		_estado.text = mensaje
	_lienzo.queue_redraw()

func _dibujar() -> void:
	if _lienzo == null:
		return
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color("20211f"))
	var paso := _escala * 5.0
	var centro := _lienzo.size * 0.5 + _desplazamiento_vista
	for x in range(0, ceili(_lienzo.size.x / paso) + 1):
		var px := fposmod(centro.x, paso) + x * paso
		_lienzo.draw_line(Vector2(px, 0), Vector2(px, _lienzo.size.y), Color(0.32, 0.32, 0.29), 1.0)
	for z in range(0, ceili(_lienzo.size.y / paso) + 1):
		var pz := fposmod(centro.y, paso) + z * paso
		_lienzo.draw_line(Vector2(0, pz), Vector2(_lienzo.size.x, pz), Color(0.32, 0.32, 0.29), 1.0)
	var modulos := _modulos_para_conexiones()
	var solapadas := {}
	for par in ConexionesMapaScript.pares_solapados(modulos):
		solapadas[par.x] = true
		solapadas[par.y] = true
	for i in _salas.size():
		var sala := _salas[i]
		var rect := _rect_sala(sala)
		var definicion := _catalogo[_indice_tipo(sala.tipo)]
		var vertices := _vertices_sala(sala, definicion, deg_to_rad(float(sala.get("angulo", 0.0))))
		var poligono := PackedVector2Array()
		for v in vertices:
			poligono.append(centro + v * _escala)
		var color := Color(0.47, 0.42, 0.27)
		if solapadas.has(i):
			color = Color(0.62, 0.22, 0.20)
		_lienzo.draw_colored_polygon(poligono, color)
		for e in poligono.size():
			var color_borde := Color(0.30, 0.85, 1.0) if i == _seleccion_sala else Color(0.83, 0.79, 0.62)
			_lienzo.draw_line(poligono[e], poligono[(e + 1) % poligono.size()], color_borde, 3.0 if i == _seleccion_sala else 2.0)
		var etiqueta: String = sala.tipo + (" · %.0f°" % float(sala.get("angulo", 0.0)))
		_lienzo.draw_string(ThemeDB.fallback_font, centro + Vector2(sala.x, sala.z) * _escala - Vector2(definicion.ancho_m * _escala * 0.5, 0), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	for conexion in ConexionesMapaScript.calcular(modulos, _estados_conexion):
		_dibujar_puerta(conexion, centro)
	var plan_solapes: Dictionary = PlanificadorSolapesScript.calcular(modulos, _estados_solape)
	for par in plan_solapes.pares:
		for area in par.poligonos:
			var puntos := PackedVector2Array()
			for punto in area:
				puntos.append(centro + punto * _escala)
			_lienzo.draw_colored_polygon(puntos, Color(0.8, 0.2, 0.18, 0.18))
	for segmento in plan_solapes.segmentos:
		var color := Color(0.55, 1.0, 0.55)
		match String(segmento.estado):
			ConexionesMapaScript.ESTADO_ABIERTA:
				color = Color(0.55, 0.95, 1.0)
			ConexionesMapaScript.ESTADO_CERRADA:
				color = Color(1.0, 0.6, 0.2)
			ConexionesMapaScript.ESTADO_INTERSECCION:
				color = Color(0.85, 0.55, 1.0)
		_lienzo.draw_line(centro + segmento.inicio * _escala, centro + segmento.fin * _escala, color, 6.0)

func _segmento_solape_en(punto: Vector2) -> String:
	var plan: Dictionary = PlanificadorSolapesScript.calcular(_modulos_para_conexiones(), _estados_solape)
	var cercana := ""
	var mejor := 0.45
	for segmento in plan.segmentos:
		var distancia := Geometry2D.get_closest_point_to_segment(punto, segmento.inicio, segmento.fin).distance_to(punto)
		if distancia < mejor:
			mejor = distancia
			cercana = String(segmento.clave)
	return cercana

## Marca cada conexión: verde puerta, celeste pared abierta, naranja pared cerrada.
## Un punto blanco indica que el estado lo eligió el usuario.
func _dibujar_puerta(conexion: Dictionary, centro: Vector2) -> void:
	var cerrada: bool = conexion.estado == ConexionesMapaScript.ESTADO_CERRADA
	var largo: float = conexion.largo if cerrada else conexion.ancho
	var tangente: Vector2 = conexion.get("tangente", Vector2.RIGHT)
	var mitad := tangente * largo * 0.5 * _escala
	var color := Color(0.55, 1.0, 0.55)
	if conexion.estado == ConexionesMapaScript.ESTADO_ABIERTA:
		color = Color(0.55, 0.95, 1.0)
	elif conexion.estado == ConexionesMapaScript.ESTADO_INTERSECCION:
		color = Color(0.85, 0.55, 1.0)
	elif cerrada:
		color = Color(1.0, 0.6, 0.2)
	for clave in ["punto_a", "punto_b"]:
		var punto: Vector2 = centro + conexion[clave] * _escala
		_lienzo.draw_line(punto - mitad, punto + mitad, color, 5.0)
		if conexion.manual:
			_lienzo.draw_circle(punto, 4.0, Color.WHITE)

## En el editor los sockets de catálogo no controlan las conexiones: se eligen
## sobre el mapa. Se conserva una pieza por geometría, altura y forma especial.
func _quitar_duplicados_catalogo(completo: Array[SalaDef]) -> Array[SalaDef]:
	var resultado: Array[SalaDef] = []
	var representantes := {}
	for definicion in completo:
		var firma := _firma_geometria(definicion)
		if representantes.has(firma):
			_alias_tipos[definicion.nombre] = String(representantes[firma])
		else:
			representantes[firma] = definicion.nombre
			resultado.append(definicion)
	return resultado

func _firma_geometria(definicion: SalaDef) -> String:
	var puntos: Array[String] = []
	for punto in definicion.obtener_huella_local():
		puntos.append("%.3f,%.3f" % [punto.x, punto.y])
	var columnas: Array[String] = []
	for posicion in definicion.columnas_locales:
		columnas.append("%.2f,%.2f,%.2f" % [posicion.x, posicion.y, posicion.z])
	columnas.sort()
	return "%.2f|%.2f|%.2f|%s|%s" % [definicion.ancho_m, definicion.largo_m, definicion.alto_m, ";".join(puntos), ";".join(columnas)]
