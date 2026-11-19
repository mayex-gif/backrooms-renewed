extends Control
## Editor 2D simple de módulos. Guarda diseños JSON en el espacio del usuario.

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")

var _catalogo: Array[SalaDef] = []
var _salas: Array[Dictionary] = []
var _seleccion := 0
var _giros := 0
var _escala := 24.0
var _lienzo: Control
var _selector: OptionButton
var _estado: Label
var _dialogo: FileDialog
var _ruta_actual := "user://saves/mapa_actual.json"
var _lista_guardados: OptionButton
var _arrastre := -1
var _desfase_arrastre := Vector2.ZERO
var _paredes_abiertas := false
var _check_paredes: CheckButton
## Módulos del archivo cuyo tipo ya no existe en el catálogo. Se conservan tal
## cual para que el autoguardado no los borre del JSON.
var _desconocidas: Array = []

func _ready() -> void:
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	_catalogo = script_catalogo.call("crear") as Array[SalaDef]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	_crear_interfaz()
	if FileAccess.file_exists(_ruta_actual):
		_cargar_ruta(_ruta_actual)
	queue_redraw()

func _crear_interfaz() -> void:
	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(columna)
	var barra := HBoxContainer.new()
	barra.custom_minimum_size.y = 48
	columna.add_child(barra)
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for definicion in _catalogo:
		_selector.add_item("%s  (%.1f × %.1f m)" % [definicion.nombre, definicion.ancho_m, definicion.largo_m])
	_selector.item_selected.connect(func(indice: int) -> void: _seleccion = indice)
	barra.add_child(_selector)
	_agregar_boton(barra, "Girar", _girar)
	_agregar_boton(barra, "Guardar", _guardar_actual)
	_agregar_boton(barra, "Guardar como", _abrir_guardar)
	_agregar_boton(barra, "Jugar", _jugar)
	_agregar_boton(barra, "Cargar", _abrir_cargar)
	_lista_guardados = OptionButton.new()
	_lista_guardados.item_selected.connect(_seleccionar_guardado)
	barra.add_child(_lista_guardados)
	_check_paredes = CheckButton.new()
	_check_paredes.text = "Pared completa abierta"
	_check_paredes.toggled.connect(func(activo: bool) -> void:
		_paredes_abiertas = activo
		_guardar_actual()
		_lienzo.queue_redraw()
	)
	barra.add_child(_check_paredes)
	_agregar_boton(barra, "Limpiar", _limpiar)
	_agregar_boton(barra, "Volver", func() -> void: get_tree().change_scene_to_file("res://pruebas/menu_principal.tscn"))
	_lienzo = Control.new()
	_lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lienzo.draw.connect(_dibujar)
	_lienzo.gui_input.connect(_entrada_lienzo)
	columna.add_child(_lienzo)
	_estado = Label.new()
	_estado.custom_minimum_size.y = 28
	_estado.text = "Click: colocar · arrastrar: mover · botón derecho: borrar · rueda: zoom · R: girar · verde: puerta · celeste: pared abierta · rojo: salas superpuestas"
	columna.add_child(_estado)
	_dialogo = FileDialog.new()
	_dialogo.access = FileDialog.ACCESS_FILESYSTEM
	_dialogo.add_filter("*.json", "Mapa JSON")
	add_child(_dialogo)
	_dialogo.file_selected.connect(_archivo_elegido)
	_actualizar_guardados()

func _agregar_boton(barra: HBoxContainer, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.pressed.connect(accion)
	barra.add_child(boton)

func _girar() -> void:
	_giros = posmod(_giros + 1, 4)
	_estado.text = "Giro seleccionado: %d°" % (_giros * 90)

func _limpiar() -> void:
	_salas.clear()
	_desconocidas.clear()
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
		_estado.text = "Mapa guardado: %s" % ruta
		_actualizar_guardados()
	else:
		_cargar_ruta(ruta)
	_lienzo.queue_redraw()
	_actualizar_guardados()

func _guardar_actual() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var archivo := FileAccess.open(_ruta_actual, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo guardar el mapa."
		return
	archivo.store_string(_serializar())
	_estado.text = "Guardado: %s" % _ruta_actual.get_file()
	_actualizar_guardados()

## Texto JSON del mapa actual. Conserva los módulos de tipo desconocido.
func _serializar() -> String:
	var filas: Array = _salas.map(func(s: Dictionary) -> Dictionary: return {"tipo": s.tipo, "x": s.x, "z": s.z, "giros": s.giros})
	filas.append_array(_desconocidas)
	return JSON.stringify({"version": 1, "paredes_abiertas": _paredes_abiertas, "salas": filas}, "\t")

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
	_paredes_abiertas = bool(datos.get("paredes_abiertas", false))
	# Sin señal: si no, el CheckButton dispara _guardar_actual() con la lista de
	# salas vacía y pisa el archivo que estaba abierto antes de este.
	_check_paredes.set_pressed_no_signal(_paredes_abiertas)
	for fila in datos.salas:
		if _indice_tipo(String(fila.get("tipo", ""))) >= 0:
			_salas.append({"tipo": fila.tipo, "x": float(fila.x), "z": float(fila.z), "giros": int(fila.giros)})
		else:
			_desconocidas.append(fila)
	for i in _salas.size():
		var existente := _rect_sala(_salas[i])
		var deseado := existente.position
		var reparado := _ajustar_a_vecino(deseado, existente.size, i)
		_salas[i].x = reparado.x
		_salas[i].z = reparado.y
	_ruta_actual = ruta
	var aviso := ""
	if not _desconocidas.is_empty():
		aviso += " · %d módulos de un tipo que ya no existe se conservan sin mostrarse" % _desconocidas.size()
	var solapes := ConexionesMapaScript.pares_solapados(_modulos_para_conexiones()).size()
	if solapes > 0:
		aviso += " · %d pares de salas superpuestas (en rojo)" % solapes
	_cambio_mapa("")
	# _cambio_mapa guarda y deja "Guardado: ..." en la barra; el aviso va después.
	_estado.text = "Mapa cargado para editar: %s%s" % [ruta.get_file(), aviso]

func _jugar() -> void:
	_guardar_actual()
	get_tree().change_scene_to_file("res://pruebas/mapa_guardado.tscn")

func _indice_tipo(nombre: String) -> int:
	for i in _catalogo.size():
		if _catalogo[i].nombre == nombre:
			return i
	return -1

func _entrada_lienzo(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and _arrastre >= 0:
		var deseado := (_punto_mapa(evento.position) - _desfase_arrastre).snapped(Vector2(0.5, 0.5))
		var tamano := _rect_sala(_salas[_arrastre]).size
		var p := _ajustar_a_vecino(deseado, tamano, _arrastre)
		if _hay_solape(Rect2(p, tamano), _arrastre):
			_estado.text = "Esa posición se superpone con otra sala; la pieza se queda en el último lugar válido."
		else:
			_salas[_arrastre].x = p.x
			_salas[_arrastre].z = p.y
		_lienzo.queue_redraw()
	elif evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed and _arrastre >= 0:
			_arrastre = -1
			_guardar_actual()
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_escala = minf(60.0, _escala * 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_escala = maxf(8.0, _escala / 1.15)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			_arrastre = _indice_sala_en(_punto_mapa(evento.position))
			if _arrastre >= 0:
				var r := _rect_sala(_salas[_arrastre])
				_desfase_arrastre = _punto_mapa(evento.position) - r.position
			else:
				_colocar(evento.position)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_RIGHT:
			_borrar(evento.position)
		_lienzo.queue_redraw()

## El lienzo no tiene foco de teclado, así que las teclas no llegan a su
## gui_input: se escuchan desde el nodo raíz.
func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla != null and tecla.pressed and not tecla.echo and tecla.keycode == KEY_R:
		_girar()
		get_viewport().set_input_as_handled()

func _hay_solape(rect: Rect2, ignorar: int) -> bool:
	for i in _salas.size():
		if i != ignorar and rect.intersects(_rect_sala(_salas[i]), false):
			return true
	return false

func _es_circular(definicion: SalaDef) -> bool:
	return definicion.escena != null and definicion.escena.resource_path.ends_with("sala_circular.tscn")

## Datos mínimos de cada sala para ConexionesMapa (el mismo cálculo que usa la escena jugable).
func _modulos_para_conexiones() -> Array[Dictionary]:
	var modulos: Array[Dictionary] = []
	for sala in _salas:
		modulos.append({"rect": _rect_sala(sala), "circular": _es_circular(_catalogo[_indice_tipo(sala.tipo)])})
	return modulos

func _colocar(posicion: Vector2) -> void:
	var definicion := _catalogo[_seleccion]
	var ancho := definicion.ancho_m if _giros % 2 == 0 else definicion.largo_m
	var largo := definicion.largo_m if _giros % 2 == 0 else definicion.ancho_m
	var centro := _lienzo.size * 0.5
	var deseado := ((posicion - centro) / _escala - Vector2(ancho, largo) * 0.5).snapped(Vector2(0.5, 0.5))
	var origen := _ajustar_a_vecino(deseado, Vector2(ancho, largo), -1)
	var rect := Rect2(origen, Vector2(ancho, largo))
	for existente in _salas:
		if rect.intersects(_rect_sala(existente), false):
			_estado.text = "Esa sala se superpone con otra."
			return
	_salas.append({"tipo": definicion.nombre, "x": origen.x, "z": origen.y, "giros": _giros})
	_cambio_mapa("Sala colocada en (%.1f, %.1f)." % [origen.x, origen.y])

func _rect_sala(sala: Dictionary) -> Rect2:
	var indice := _indice_tipo(sala.tipo)
	var definicion := _catalogo[indice]
	var ancho := definicion.ancho_m if int(sala.giros) % 2 == 0 else definicion.largo_m
	var largo := definicion.largo_m if int(sala.giros) % 2 == 0 else definicion.ancho_m
	return Rect2(Vector2(sala.x, sala.z), Vector2(ancho, largo))

func _ajustar_a_vecino(deseado: Vector2, tamano: Vector2, ignorar: int) -> Vector2:
	var mejor := deseado
	var mejor_distancia := 1.25
	for i in _salas.size():
		if i == ignorar:
			continue
		var vecino := _rect_sala(_salas[i])
		var z := clampf(deseado.y, vecino.position.y - tamano.y + 1.5, vecino.end.y - 1.5)
		var x := clampf(deseado.x, vecino.position.x - tamano.x + 1.5, vecino.end.x - 1.5)
		var opciones: Array[Vector2] = [Vector2(vecino.end.x, z), Vector2(vecino.position.x - tamano.x, z), Vector2(x, vecino.end.y), Vector2(x, vecino.position.y - tamano.y)]
		for opcion in opciones:
			var distancia := opcion.distance_to(deseado)
			if distancia < mejor_distancia:
				mejor = opcion.snapped(Vector2(0.5, 0.5))
				mejor_distancia = distancia
	return mejor

func _borrar(posicion: Vector2) -> void:
	var indice := _indice_sala_en(_punto_mapa(posicion))
	if indice >= 0:
		_salas.remove_at(indice)
		_cambio_mapa("Sala eliminada.")

func _punto_mapa(posicion: Vector2) -> Vector2:
	return (posicion - _lienzo.size * 0.5) / _escala

func _indice_sala_en(punto: Vector2) -> int:
	for i in range(_salas.size() - 1, -1, -1):
		if _rect_sala(_salas[i]).has_point(punto):
			return i
	return -1

func _cambio_mapa(mensaje: String) -> void:
	_estado.text = mensaje
	_lienzo.queue_redraw()
	_guardar_actual()

func _dibujar() -> void:
	if _lienzo == null:
		return
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color("20211f"))
	var paso := _escala * 5.0
	var centro := _lienzo.size * 0.5
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
		var dibujado := Rect2(centro + rect.position * _escala, rect.size * _escala)
		var circular: bool = modulos[i].circular
		var color := Color(0.47, 0.42, 0.27) if not circular else Color(0.30, 0.43, 0.38)
		if solapadas.has(i):
			color = Color(0.62, 0.22, 0.20)
		_lienzo.draw_rect(dibujado, color)
		_lienzo.draw_rect(dibujado, Color(0.83, 0.79, 0.62), false, 2.0)
		var etiqueta: String = sala.tipo + (" (sin puertas por ahora)" if circular else "")
		_lienzo.draw_string(ThemeDB.fallback_font, dibujado.position + Vector2(5, 18), etiqueta, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	for conexion in ConexionesMapaScript.calcular(modulos, _paredes_abiertas):
		_dibujar_puerta(conexion, centro)

## Marca verde cada puerta que va a generarse; celeste si se abre toda la pared.
func _dibujar_puerta(conexion: Dictionary, centro: Vector2) -> void:
	var vertical: bool = conexion.dir_a == Direcciones.Dir.ESTE or conexion.dir_a == Direcciones.Dir.OESTE
	var mitad := (Vector2(0.0, conexion.ancho) if vertical else Vector2(conexion.ancho, 0.0)) * 0.5 * _escala
	var color := Color(0.55, 0.95, 1.0) if conexion.completa else Color(0.55, 1.0, 0.55)
	for clave in ["punto_a", "punto_b"]:
		var punto: Vector2 = centro + conexion[clave] * _escala
		_lienzo.draw_line(punto - mitad, punto + mitad, color, 5.0)
