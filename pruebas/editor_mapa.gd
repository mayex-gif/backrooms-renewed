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
var _estado: Label
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
## Modo de luz por posición global de luminaria en este mapa.
var _modos_luces: Dictionary = {}
var _siguiente_id := 0
var _hay_cambios := false
var _vista_techo := false
var _boton_vista_techo: Button
var _lista_piezas: ItemList
var _info_sala: Label
var _etiqueta_objetivo: Label
var _spin_angulo: SpinBox
var _boton_duplicar: Button
var _boton_borrar: Button
var _boton_deseleccionar: Button
var _boton_deshacer: Button
var _boton_rehacer: Button
var _etiqueta_cursor: Label
var _dialogo_ayuda: AcceptDialog
var _boton_inicio: Button
## Punto de inicio del jugador: {"x", "z", "angulo"} (grados; 0 = hacia +X, 90 = hacia +Z). Vacío: automático.
var _inicio: Dictionary = {}
var _modo_inicio := false
var _arrastre_inicio := false
var _cursor_mapa := Vector2.ZERO
var _cursor_en_lienzo := false
var _actualizando_ui := false
## Historial para deshacer/rehacer: cada entrada es una foto JSON del mapa.
var _historial: Array[String] = []
var _indice_historial := -1
var _restaurando := false
const MAX_HISTORIAL := 100
const ESCALA_MINIMA := 6.0
const ESCALA_MAXIMA := 80.0

func _ready() -> void:
	var script_catalogo: Script = load("res://salas/catalogo_salas.gd")
	var catalogo_completo := script_catalogo.call("crear") as Array[SalaDef]
	_catalogo = _quitar_duplicados_catalogo(catalogo_completo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	_crear_interfaz()
	if FileAccess.file_exists(_ruta_actual):
		_cargar_ruta(_ruta_actual)
	if _historial.is_empty():
		_registrar_historial()
	queue_redraw()

func _crear_interfaz() -> void:
	var raiz := VBoxContainer.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(raiz)
	raiz.add_child(_crear_barra_superior())
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(cuerpo)
	cuerpo.add_child(_crear_panel_lateral())
	_lienzo = Control.new()
	_lienzo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lienzo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lienzo.clip_contents = true
	_lienzo.draw.connect(_dibujar)
	_lienzo.gui_input.connect(_entrada_lienzo)
	_lienzo.mouse_exited.connect(func() -> void:
		_cursor_en_lienzo = false
		_lienzo.queue_redraw()
	)
	cuerpo.add_child(_lienzo)
	var pie := HBoxContainer.new()
	raiz.add_child(pie)
	_estado = Label.new()
	_estado.custom_minimum_size.y = 28
	_estado.text = "Elegí una pieza a la izquierda y hacé click en el lienzo para colocarla. Botón Ayuda: todos los controles."
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(_estado)
	_etiqueta_cursor = Label.new()
	_etiqueta_cursor.custom_minimum_size.x = 200
	_etiqueta_cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pie.add_child(_etiqueta_cursor)
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
	_actualizar_rotacion_visible()
	_actualizar_botones_historial()

func _crear_barra_superior() -> Control:
	var barra := HFlowContainer.new()
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_agregar_boton(barra, "Guardar", func() -> void: _guardar_actual(true), "Guarda el mapa (Ctrl+S). También se autoguarda en cada cambio.")
	_agregar_boton(barra, "Guardar como", _abrir_guardar, "Guarda el mapa con otro nombre.")
	_agregar_boton(barra, "Cargar", _abrir_cargar, "Abre un mapa guardado.")
	_lista_guardados = OptionButton.new()
	_lista_guardados.tooltip_text = "Mapas guardados en tu carpeta de usuario. Elegir uno lo abre."
	_lista_guardados.item_selected.connect(_seleccionar_guardado)
	barra.add_child(_lista_guardados)
	barra.add_child(VSeparator.new())
	_boton_deshacer = _agregar_boton(barra, "Deshacer", _deshacer, "Deshace el último cambio (Ctrl+Z).")
	_boton_rehacer = _agregar_boton(barra, "Rehacer", _rehacer, "Rehace el cambio deshecho (Ctrl+Y).")
	barra.add_child(VSeparator.new())
	_agregar_boton(barra, "Encuadrar", _encuadrar, "Ajusta el zoom para ver todas las salas (F).")
	_boton_vista_techo = _agregar_boton(barra, "Vista de techo", _alternar_vista_techo, "Muestra las placas del techo y permite cambiar el estado de cada luminaria.")
	_boton_inicio = _agregar_boton(barra, "Punto de inicio", _alternar_modo_inicio, "Elegí dónde y hacia dónde mira el jugador al empezar: click para ubicarlo y arrastrá para girarlo.")
	_boton_inicio.toggle_mode = true
	_agregar_boton(barra, "Limpiar", _limpiar, "Borra todas las salas. Se puede deshacer con Ctrl+Z.")
	barra.add_child(VSeparator.new())
	_agregar_boton(barra, "Jugar", _jugar, "Guarda y abre el mapa en 3D.")
	_agregar_boton(barra, "Ayuda", _mostrar_ayuda, "Lista de controles y colores.")
	_agregar_boton(barra, "Volver", _solicitar_salir, "Vuelve al menú principal.")
	return barra

func _crear_panel_lateral() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 290
	var desplazable := ScrollContainer.new()
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(desplazable)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 6)
	desplazable.add_child(columna)
	columna.add_child(_titulo_seccion("1 · Pieza a colocar"))
	_lista_piezas = ItemList.new()
	_lista_piezas.custom_minimum_size.y = 230
	_lista_piezas.tooltip_text = "Elegí la pieza y hacé click en el lienzo para colocarla."
	for definicion in _catalogo:
		_lista_piezas.add_item("%s  (%.1f × %.1f m)" % [definicion.nombre, definicion.ancho_m, definicion.largo_m])
	if _seleccion < _catalogo.size():
		_lista_piezas.select(_seleccion)
	_lista_piezas.item_selected.connect(_pieza_elegida)
	columna.add_child(_lista_piezas)
	columna.add_child(HSeparator.new())
	columna.add_child(_titulo_seccion("2 · Rotación"))
	_etiqueta_objetivo = Label.new()
	_etiqueta_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_etiqueta_objetivo)
	var giros := HFlowContainer.new()
	for delta in [-90.0, -15.0, -5.0, 5.0, 15.0, 90.0]:
		var paso: float = delta
		_agregar_boton(giros, "%+.0f°" % paso, func() -> void: _girar_objetivo(paso), "Gira %+.0f°. Con el teclado: R y Mayús+R giran ±5°." % paso)
	columna.add_child(giros)
	var fila_angulo := HBoxContainer.new()
	var texto_angulo := Label.new()
	texto_angulo.text = "Ángulo exacto"
	fila_angulo.add_child(texto_angulo)
	_spin_angulo = SpinBox.new()
	_spin_angulo.min_value = 0.0
	_spin_angulo.max_value = 359.5
	_spin_angulo.step = 0.5
	_spin_angulo.suffix = "°"
	_spin_angulo.tooltip_text = "Escribí el ángulo que quieras."
	_spin_angulo.value_changed.connect(_angulo_escrito)
	fila_angulo.add_child(_spin_angulo)
	columna.add_child(fila_angulo)
	columna.add_child(HSeparator.new())
	columna.add_child(_titulo_seccion("3 · Sala seleccionada"))
	_info_sala = Label.new()
	_info_sala.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_info_sala)
	var acciones := HFlowContainer.new()
	_boton_duplicar = _agregar_boton(acciones, "Duplicar", _duplicar_seleccion, "Copia la sala a su costado (Ctrl+D).")
	_boton_borrar = _agregar_boton(acciones, "Eliminar", _borrar_seleccion, "Elimina la sala (Supr o clic derecho).")
	_boton_deseleccionar = _agregar_boton(acciones, "Soltar", _deseleccionar, "Deja de seleccionar la sala (Esc).")
	columna.add_child(acciones)
	return panel

func _titulo_seccion(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 16)
	etiqueta.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	return etiqueta

func _agregar_boton(barra: Container, texto: String, accion: Callable, ayuda: String = "") -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.tooltip_text = ayuda
	boton.pressed.connect(accion)
	barra.add_child(boton)
	return boton

func _pieza_elegida(indice: int) -> void:
	_seleccion = indice
	_seleccion_sala = -1
	_actualizar_rotacion_visible()
	_lista_piezas.release_focus()
	_lienzo.queue_redraw()

func _mostrar_ayuda() -> void:
	if _dialogo_ayuda == null:
		_dialogo_ayuda = AcceptDialog.new()
		_dialogo_ayuda.title = "Controles del editor"
		_dialogo_ayuda.dialog_text = "RATÓN\n  Click en un lugar vacío: coloca la pieza elegida (el fantasma muestra cómo queda y se pega a las paredes cercanas).\n  Click en una sala: la selecciona. Arrastrar: la mueve.\n  Clic derecho sobre una sala: la elimina.\n  Click sobre una marca de color entre salas: cambia su estado (Mayús: vuelve al automático).\n  Alt apretado: desactiva el imán (para superponer salas a propósito).\n  Botón central: mueve el lienzo. Rueda: zoom hacia el cursor.\n\nTECLADO\n  R / Mayús+R: gira 5° (la sala seleccionada o, si no hay, la pieza nueva).\n  Flechas: mueven la sala seleccionada 0,5 m (con Mayús, 0,1 m).\n  Supr: elimina · Ctrl+D: duplica · Ctrl+Z / Ctrl+Y: deshacer / rehacer.\n  Ctrl+S: guarda · F: encuadra todo · Esc: suelta la selección o sale.\n\nCOLORES\n  Verde: puerta · Celeste: pared abierta · Naranja: pared cerrada · Violeta: intersección sin dintel.\n  Rojo translúcido: salas superpuestas."
		add_child(_dialogo_ayuda)
	_dialogo_ayuda.popup_centered(Vector2i(640, 520))

func _girar_pieza(delta: float) -> void:
	_angulo_seleccion = fposmod(_angulo_seleccion + delta, 360.0)
	_actualizar_rotacion_visible()
	_lienzo.queue_redraw()

func _girar_sala(delta: float) -> void:
	if _seleccion_sala < 0 or _seleccion_sala >= _salas.size():
		_estado.text = "Seleccioná una sala para girarla."
		return
	var nuevo_angulo := fposmod(float(_salas[_seleccion_sala].angulo) + delta, 360.0)
	_salas[_seleccion_sala].angulo = nuevo_angulo
	_actualizar_rotacion_visible()
	_cambio_mapa("Sala girada a %.1f°." % nuevo_angulo)

## Gira la sala seleccionada o, si no hay ninguna, la pieza que se va a colocar.
func _girar_objetivo(delta: float) -> void:
	if _seleccion_sala >= 0 and _seleccion_sala < _salas.size():
		_girar_sala(delta)
	else:
		_girar_pieza(delta)

func _angulo_escrito(valor: float) -> void:
	if _actualizando_ui:
		return
	if _seleccion_sala >= 0 and _seleccion_sala < _salas.size():
		_salas[_seleccion_sala].angulo = fposmod(valor, 360.0)
		_actualizar_rotacion_visible()
		_cambio_mapa("Sala girada a %.1f°." % fposmod(valor, 360.0))
	else:
		_angulo_seleccion = fposmod(valor, 360.0)
		_lienzo.queue_redraw()

func _deseleccionar() -> void:
	_seleccion_sala = -1
	_actualizar_rotacion_visible()
	_lienzo.queue_redraw()

## Refresca el panel lateral (datos de la sala, ángulo y botones).
func _actualizar_rotacion_visible() -> void:
	if _info_sala == null:
		return
	var hay_sala := _seleccion_sala >= 0 and _seleccion_sala < _salas.size()
	var angulo := _angulo_seleccion
	if hay_sala:
		var sala: Dictionary = _salas[_seleccion_sala]
		var definicion := _catalogo[_indice_tipo(String(sala.tipo))]
		angulo = float(sala.angulo)
		_info_sala.text = "%s\nCentro: %.1f, %.1f m\nTamaño: %.1f × %.1f × %.1f m\nÁngulo: %.1f°" % [sala.tipo, float(sala.x), float(sala.z), definicion.ancho_m, definicion.largo_m, definicion.alto_m, angulo]
		_etiqueta_objetivo.text = "Se gira la sala seleccionada."
	else:
		_info_sala.text = "Ninguna. Hacé click en una sala para seleccionarla."
		_etiqueta_objetivo.text = "Se gira la pieza nueva (el fantasma en el lienzo)."
	_boton_duplicar.disabled = not hay_sala
	_boton_borrar.disabled = not hay_sala
	_boton_deseleccionar.disabled = not hay_sala
	_actualizando_ui = true
	_spin_angulo.value = angulo
	_actualizando_ui = false

func _duplicar_seleccion() -> void:
	if _seleccion_sala < 0 or _seleccion_sala >= _salas.size():
		return
	var original: Dictionary = _salas[_seleccion_sala]
	var definicion := _catalogo[_indice_tipo(String(original.tipo))]
	var angulo := float(original.angulo)
	var deseado := Vector2(float(original.x) + _rect_sala(original).size.x, float(original.z)).snapped(Vector2(0.5, 0.5))
	var centro := _centro_ajustado(deseado, definicion, angulo, -1)
	var copia := {"id": _siguiente_id, "tipo": String(original.tipo), "x": centro.x, "z": centro.y, "angulo": angulo}
	_siguiente_id += 1
	_salas.append(copia)
	_seleccion_sala = _salas.size() - 1
	_actualizar_rotacion_visible()
	_cambio_mapa("Sala duplicada.")

func _borrar_seleccion() -> void:
	_borrar_indice(_seleccion_sala)

func _mover_seleccion(delta: Vector2) -> void:
	if _seleccion_sala < 0 or _seleccion_sala >= _salas.size():
		return
	_salas[_seleccion_sala].x = float(_salas[_seleccion_sala].x) + delta.x
	_salas[_seleccion_sala].z = float(_salas[_seleccion_sala].z) + delta.y
	_actualizar_rotacion_visible()
	_cambio_mapa("")

## Zoom hacia el punto de pantalla indicado: lo que está bajo el cursor no se corre.
func _zoom(factor: float, punto_pantalla: Vector2) -> void:
	var antes := _punto_mapa(punto_pantalla)
	_escala = clampf(_escala * factor, ESCALA_MINIMA, ESCALA_MAXIMA)
	_desplazamiento_vista = punto_pantalla - _lienzo.size * 0.5 - antes * _escala
	_lienzo.queue_redraw()

## Ajusta zoom y posición para que entren todas las salas.
func _encuadrar() -> void:
	if _salas.is_empty():
		_escala = 24.0
		_desplazamiento_vista = Vector2.ZERO
		_lienzo.queue_redraw()
		return
	var caja := _rect_sala(_salas[0])
	for sala in _salas:
		caja = caja.merge(_rect_sala(sala))
	var tamano := caja.size + Vector2(6.0, 6.0)
	_escala = clampf(minf(_lienzo.size.x / tamano.x, _lienzo.size.y / tamano.y), ESCALA_MINIMA, ESCALA_MAXIMA)
	_desplazamiento_vista = -caja.get_center() * _escala
	_lienzo.queue_redraw()

# ---------------------------------------------------------------- historial
func _foto_mapa() -> String:
	return JSON.stringify({"salas": _salas, "conexiones": _estados_conexion, "solapes": _estados_solape, "luces": _modos_luces, "inicio": _inicio, "siguiente": _siguiente_id})

func _registrar_historial() -> void:
	if _restaurando:
		return
	var foto := _foto_mapa()
	if _indice_historial >= 0 and _historial[_indice_historial] == foto:
		return
	_historial.resize(_indice_historial + 1)
	_historial.append(foto)
	if _historial.size() > MAX_HISTORIAL:
		_historial.remove_at(0)
	_indice_historial = _historial.size() - 1
	_actualizar_botones_historial()

func _deshacer() -> void:
	if _indice_historial <= 0:
		_estado.text = "No hay nada para deshacer."
		return
	_indice_historial -= 1
	_restaurar_foto(_historial[_indice_historial])
	_estado.text = "Cambio deshecho."

func _rehacer() -> void:
	if _indice_historial >= _historial.size() - 1:
		_estado.text = "No hay nada para rehacer."
		return
	_indice_historial += 1
	_restaurar_foto(_historial[_indice_historial])
	_estado.text = "Cambio rehecho."

func _restaurar_foto(foto: String) -> void:
	var datos: Variant = JSON.parse_string(foto)
	if not datos is Dictionary:
		return
	_restaurando = true
	_salas.clear()
	for fila in datos.get("salas", []):
		_salas.append({"id": int(fila.id), "tipo": String(fila.tipo), "x": float(fila.x), "z": float(fila.z), "angulo": float(fila.angulo)})
	_estados_conexion = (datos.get("conexiones", {}) as Dictionary).duplicate()
	_estados_solape = (datos.get("solapes", {}) as Dictionary).duplicate()
	_modos_luces = (datos.get("luces", {}) as Dictionary).duplicate()
	_inicio = (datos.get("inicio", {}) as Dictionary).duplicate()
	_siguiente_id = int(datos.get("siguiente", _siguiente_id))
	_seleccion_sala = -1
	_arrastre = -1
	_actualizar_rotacion_visible()
	_cambio_mapa("")
	_restaurando = false
	_actualizar_botones_historial()

func _actualizar_botones_historial() -> void:
	if _boton_deshacer == null or _boton_rehacer == null:
		return
	_boton_deshacer.disabled = _indice_historial <= 0
	_boton_rehacer.disabled = _indice_historial >= _historial.size() - 1

func _limpiar() -> void:
	_salas.clear()
	_seleccion_sala = -1
	_actualizar_rotacion_visible()
	_desconocidas.clear()
	_estados_conexion.clear()
	_estados_solape.clear()
	_inicio = {}
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
	return JSON.stringify({"version": 5, "conexiones": _estados_conexion, "solapes": _estados_solape, "modos_luces": _modos_luces, "inicio": _inicio, "salas": filas}, "\t")

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
	_modos_luces.clear()
	var estados_guardados: Variant = datos.get("conexiones", {})
	if estados_guardados is Dictionary:
		for clave in estados_guardados:
			if ConexionesMapaScript.ESTADOS.has(String(estados_guardados[clave])):
				_estados_conexion[String(clave)] = String(estados_guardados[clave])
	var solapes_guardados: Variant = datos.get("solapes", {})
	if solapes_guardados is Dictionary:
		_estados_solape = solapes_guardados.duplicate()
	var modos_luces_guardados: Variant = datos.get("modos_luces", {})
	if modos_luces_guardados is Dictionary:
		_modos_luces = modos_luces_guardados.duplicate(true)
	_inicio = {}
	var inicio_guardado: Variant = datos.get("inicio", {})
	if inicio_guardado is Dictionary and inicio_guardado.has("x") and inicio_guardado.has("z"):
		_inicio = {"x": float(inicio_guardado.x), "z": float(inicio_guardado.z), "angulo": float(inicio_guardado.get("angulo", 0.0))}
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
	_seleccion_sala = -1
	_historial.clear()
	_indice_historial = -1
	_registrar_historial()
	_actualizar_rotacion_visible()

func _jugar() -> void:
	if not _guardar_para_jugar():
		return
	get_tree().change_scene_to_file("res://pruebas/mapa_guardado.tscn")

func _guardar_para_jugar() -> bool:
	_guardar_actual(true)
	if _ruta_actual == "user://saves/mapa_actual.json":
		return FileAccess.file_exists(_ruta_actual)
	var copia := FileAccess.open("user://saves/mapa_actual.json", FileAccess.WRITE)
	if copia == null:
		_estado.text = "No se pudo preparar el mapa para jugar."
		return false
	copia.store_string(_serializar())
	return true


func _alternar_vista_techo() -> void:
	_vista_techo = not _vista_techo
	_boton_vista_techo.text = "Volver al plano" if _vista_techo else "Vista de techo"
	if _vista_techo:
		_estado.text = "Techo: cada cuadrado representa una placa. Click en una luz para alternar encendida, intermitente y averiada."
		if _modos_luces.is_empty():
			_estado.text += " Las luces se muestran tras abrir el mapa 3D una vez."
	else:
		_estado.text = "Plano de salas."
	_lienzo.queue_redraw()

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
		_cursor_mapa = _punto_mapa(evento.position)
		_cursor_en_lienzo = true
		_etiqueta_cursor.text = "X %.1f · Z %.1f m" % [_cursor_mapa.x, _cursor_mapa.y]
		if _arrastre_inicio:
			var origen := Vector2(float(_inicio.x), float(_inicio.z))
			_fijar_inicio(origen, _cursor_mapa)
			_lienzo.queue_redraw()
		elif _paneo_activo:
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
		else:
			var sobre_sala := not _vista_techo and _indice_sala_en(_cursor_mapa) >= 0
			_lienzo.mouse_default_cursor_shape = Control.CURSOR_MOVE if sobre_sala else Control.CURSOR_ARROW
			_lienzo.queue_redraw()
	elif evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_MIDDLE and evento.pressed:
			_paneo_activo = true
			_ultima_posicion_paneo = evento.position
		elif evento.button_index == MOUSE_BUTTON_MIDDLE and not evento.pressed:
			_paneo_activo = false
		elif evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed and _arrastre_inicio:
			_arrastre_inicio = false
			_cambio_mapa("Punto de inicio fijado.")
		elif evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed and _arrastre >= 0:
			_arrastre = -1
			_hay_cambios = true
			_guardar_actual()
			_registrar_historial()
			_actualizar_rotacion_visible()
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.15, evento.position)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.15, evento.position)
		elif evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().gui_release_focus()
			var punto_mapa := _punto_mapa(evento.position)
			if _modo_inicio:
				_fijar_inicio(punto_mapa.snapped(Vector2(0.25, 0.25)), punto_mapa)
				_arrastre_inicio = true
				_lienzo.queue_redraw()
				return
			if _vista_techo:
				_cambiar_estado_luz_techo(punto_mapa)
				return
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
			if not _vista_techo:
				_borrar(evento.position)
		_lienzo.queue_redraw()

## El lienzo no tiene foco de teclado, así que las teclas no llegan a su
## gui_input: se escuchan desde el nodo raíz.
func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed:
		return
	var control := tecla.is_command_or_control_pressed()
	var flecha := Vector2.ZERO
	match tecla.keycode:
		KEY_LEFT:
			flecha = Vector2.LEFT
		KEY_RIGHT:
			flecha = Vector2.RIGHT
		KEY_UP:
			flecha = Vector2.UP
		KEY_DOWN:
			flecha = Vector2.DOWN
	if flecha != Vector2.ZERO:
		get_viewport().set_input_as_handled()
		_mover_seleccion(flecha * (0.1 if tecla.shift_pressed else 0.5))
		return
	if tecla.echo:
		return
	match tecla.keycode:
		KEY_R:
			if _vista_techo:
				return
			get_viewport().set_input_as_handled()
			_girar_objetivo(-5.0 if tecla.shift_pressed else 5.0)
		KEY_Z:
			if control:
				get_viewport().set_input_as_handled()
				if tecla.shift_pressed:
					_rehacer()
				else:
					_deshacer()
		KEY_Y:
			if control:
				get_viewport().set_input_as_handled()
				_rehacer()
		KEY_S:
			if control:
				get_viewport().set_input_as_handled()
				_guardar_actual(true)
		KEY_D:
			if control:
				get_viewport().set_input_as_handled()
				_duplicar_seleccion()
		KEY_DELETE, KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			_borrar_seleccion()
		KEY_F:
			if not control:
				get_viewport().set_input_as_handled()
				_encuadrar()
		KEY_F1:
			get_viewport().set_input_as_handled()
			_mostrar_ayuda()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _seleccion_sala >= 0:
				_deseleccionar()
			else:
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

const ALCANCE_AJUSTE := 2.0
const ALCANCE_ALINEAR := 0.75

## Pega la sala a las paredes cercanas. Prueba:
##  - apoyarse contra una pared enfrentada (y alinear sus bordes con los de la vecina),
##  - encajar en un rincón entre dos paredes que no son paralelas.
## Elige la opción más cercana que no se superponga con otra sala.
## Mantener Alt apretado desactiva el imán (sirve para superponer a propósito).
func _centro_ajustado(deseado: Vector2, definicion: SalaDef, angulo_grados: float, ignorar: int) -> Vector2:
	if Input.is_key_pressed(KEY_ALT):
		return deseado
	var nuevos := PackedVector2Array(_vertices_sala({"x": deseado.x, "z": deseado.y}, definicion, deg_to_rad(angulo_grados)))
	var otras := _huellas_de_salas(ignorar)
	var contactos := _contactos_de_ajuste(nuevos, otras)
	contactos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(float(a.delta), float(a.corrimiento)).length() < Vector2(float(b.delta), float(b.corrimiento)).length()
	)
	if contactos.size() > 10:
		contactos.resize(10)
	# Cada candidato: x, y = traslación; z = distancia máxima aceptada.
	var candidatos: Array[Vector3] = []
	for contacto in contactos:
		var normal: Vector2 = contacto.normal
		var tangente: Vector2 = contacto.tangente
		var traslacion := normal * float(contacto.delta) + tangente * float(contacto.corrimiento)
		candidatos.append(Vector3(traslacion.x, traslacion.y, ALCANCE_AJUSTE))
	for x in contactos.size():
		for y in range(x + 1, contactos.size()):
			var n1: Vector2 = contactos[x].normal
			var n2: Vector2 = contactos[y].normal
			var determinante := n1.x * n2.y - n1.y * n2.x
			if absf(determinante) < 0.2:
				continue
			var d1: float = contactos[x].delta
			var d2: float = contactos[y].delta
			candidatos.append(Vector3((d1 * n2.y - n1.y * d2) / determinante, (n1.x * d2 - d1 * n2.x) / determinante, ALCANCE_AJUSTE * 1.5))
	var mejor := deseado
	var mejor_puntaje := INF
	for candidato in candidatos:
		var traslado := Vector2(candidato.x, candidato.y)
		if traslado.length() > candidato.z:
			continue
		if _huella_choca(nuevos, traslado, otras):
			continue
		var toques := 0
		for contacto in contactos:
			var normal_c: Vector2 = contacto.normal
			if absf(traslado.dot(normal_c) - float(contacto.delta)) > 0.02:
				continue
			var tangente_c: Vector2 = contacto.tangente
			var desplazamiento := traslado.dot(tangente_c)
			if desplazamiento >= float(contacto.minimo) - 0.02 and desplazamiento <= float(contacto.maximo) + 0.02:
				toques += 1
		if toques == 0:
			continue
		var puntaje := traslado.length() - 0.6 * (toques - 1)
		if puntaje < mejor_puntaje:
			mejor_puntaje = puntaje
			mejor = deseado + traslado
	return mejor

## Huellas (en metros del mundo) de todas las salas menos la indicada.
func _huellas_de_salas(ignorar: int) -> Array[PackedVector2Array]:
	var huellas: Array[PackedVector2Array] = []
	for k in _salas.size():
		if k == ignorar:
			continue
		var sala_k: Dictionary = _salas[k]
		var definicion_k := _catalogo[_indice_tipo(String(sala_k.tipo))]
		huellas.append(PackedVector2Array(_vertices_sala(sala_k, definicion_k, deg_to_rad(float(sala_k.get("angulo", 0.0))))))
	return huellas

## Pares de paredes enfrentadas (normales opuestas) entre la sala nueva y las otras.
func _contactos_de_ajuste(nuevos: PackedVector2Array, otras: Array[PackedVector2Array]) -> Array[Dictionary]:
	var contactos: Array[Dictionary] = []
	for otra in otras:
		for i in nuevos.size():
			var a0 := nuevos[i]
			var a1 := nuevos[(i + 1) % nuevos.size()]
			var largo_a := a0.distance_to(a1)
			if largo_a < 0.01:
				continue
			var tangente := (a1 - a0) / largo_a
			var normal := Vector2(tangente.y, -tangente.x)
			for j in otra.size():
				var b0 := otra[j]
				var b1 := otra[(j + 1) % otra.size()]
				var largo_b := b0.distance_to(b1)
				if largo_b < 0.01:
					continue
				var tangente_b := (b1 - b0) / largo_b
				var normal_b := Vector2(tangente_b.y, -tangente_b.x)
				if normal.dot(normal_b) > -0.999:
					continue
				var delta := b0.dot(normal) - a0.dot(normal)
				var a_min := minf(a0.dot(tangente), a1.dot(tangente))
				var a_max := maxf(a0.dot(tangente), a1.dot(tangente))
				var b_min := minf(b0.dot(tangente), b1.dot(tangente))
				var b_max := maxf(b0.dot(tangente), b1.dot(tangente))
				# Rango de desplazamiento a lo largo de la pared que deja un paso utilizable.
				var minimo := b_min + ConexionesMapaScript.PASO_MINIMO - a_max
				var maximo := b_max - ConexionesMapaScript.PASO_MINIMO - a_min
				if minimo > maximo:
					continue
				var corrimiento := clampf(0.0, minimo, maximo)
				# Si un borde queda cerca de alinearse con el de la vecina, se alinea.
				var mejor_alineacion := INF
				for alineado in [b_min - a_min, b_max - a_max]:
					var valor: float = alineado
					if valor < minimo or valor > maximo:
						continue
					if absf(valor - corrimiento) > ALCANCE_ALINEAR:
						continue
					if absf(valor - corrimiento) < absf(mejor_alineacion - corrimiento):
						mejor_alineacion = valor
				if mejor_alineacion != INF:
					corrimiento = mejor_alineacion
				contactos.append({"normal": normal, "tangente": tangente, "delta": delta, "minimo": minimo, "maximo": maximo, "corrimiento": corrimiento})
	return contactos

## true si la huella, trasladada, se superpone con alguna de las otras (tocarse no cuenta).
func _huella_choca(huella: PackedVector2Array, traslado: Vector2, otras: Array[PackedVector2Array]) -> bool:
	var movida := PackedVector2Array()
	for punto in huella:
		movida.append(punto + traslado)
	for otra in otras:
		if _huellas_se_superponen(movida, otra):
			return true
	return false

func _huellas_se_superponen(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poligono in [a, b]:
		var puntos: PackedVector2Array = poligono
		for i in puntos.size():
			var eje := (puntos[(i + 1) % puntos.size()] - puntos[i]).orthogonal().normalized()
			var minimo_a := INF
			var maximo_a := -INF
			for punto in a:
				minimo_a = minf(minimo_a, punto.dot(eje))
				maximo_a = maxf(maximo_a, punto.dot(eje))
			var minimo_b := INF
			var maximo_b := -INF
			for punto in b:
				minimo_b = minf(minimo_b, punto.dot(eje))
				maximo_b = maxf(maximo_b, punto.dot(eje))
			if maximo_a <= minimo_b + 0.001 or maximo_b <= minimo_a + 0.001:
				return false
	return true

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

func _alternar_modo_inicio() -> void:
	_modo_inicio = _boton_inicio.button_pressed
	if _modo_inicio:
		_estado.text = "Punto de inicio: hacé click donde aparece el jugador y arrastrá hacia donde mira. Volvé a apretar el botón para seguir editando salas."
	else:
		_estado.text = "Edición de salas."
	_lienzo.queue_redraw()

## Punto de inicio según el cursor: la dirección apunta desde el punto hacia el mouse.
func _fijar_inicio(punto: Vector2, punto_direccion: Vector2) -> void:
	var angulo := float(_inicio.get("angulo", 0.0))
	if punto.distance_to(punto_direccion) > 0.3:
		angulo = rad_to_deg((punto_direccion - punto).angle())
	_inicio = {"x": punto.x, "z": punto.y, "angulo": fposmod(angulo, 360.0)}

func _borrar(posicion: Vector2) -> void:
	_borrar_indice(_indice_sala_en(_punto_mapa(posicion)))

func _borrar_indice(indice: int) -> void:
	if indice < 0 or indice >= _salas.size():
		return
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
	_registrar_historial()
	if not mensaje.is_empty():
		_estado.text = mensaje
	_lienzo.queue_redraw()

func _dibujar() -> void:
	if _lienzo == null:
		return
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color("20211f"))
	var centro := _lienzo.size * 0.5 + _desplazamiento_vista
	if _escala >= 14.0:
		_dibujar_cuadricula(centro, _escala, Color(0.26, 0.26, 0.24), 1.0)
	_dibujar_cuadricula(centro, _escala * 5.0, Color(0.34, 0.34, 0.31), 1.0)
	_lienzo.draw_line(Vector2(0, centro.y), Vector2(_lienzo.size.x, centro.y), Color(0.55, 0.30, 0.30), 1.5)
	_lienzo.draw_line(Vector2(centro.x, 0), Vector2(centro.x, _lienzo.size.y), Color(0.30, 0.50, 0.30), 1.5)
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
		if i == _seleccion_sala:
			color = color.lightened(0.22)
		_lienzo.draw_colored_polygon(poligono, color)
		if _vista_techo:
			_dibujar_tiles_techo(sala, definicion, deg_to_rad(float(sala.get("angulo", 0.0))), centro)
		for e in poligono.size():
			var color_borde := Color(0.30, 0.85, 1.0) if i == _seleccion_sala else Color(0.83, 0.79, 0.62)
			_lienzo.draw_line(poligono[e], poligono[(e + 1) % poligono.size()], color_borde, 3.0 if i == _seleccion_sala else 2.0)
		if not _vista_techo:
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
	_dibujar_inicio(centro)
	_dibujar_fantasma(centro)
	_dibujar_leyenda()

## Marca el punto de inicio: círculo con una flecha hacia donde mira el jugador.
func _dibujar_inicio(centro: Vector2) -> void:
	if _inicio.is_empty():
		return
	var posicion := Vector2(float(_inicio.x), float(_inicio.z))
	var dentro := _indice_sala_en(posicion) >= 0
	var color := Color(0.4, 0.9, 1.0) if dentro else Color(1.0, 0.35, 0.3)
	var direccion := Vector2.from_angle(deg_to_rad(float(_inicio.angulo)))
	var punta := centro + (posicion + direccion * 1.1) * _escala
	var base := centro + posicion * _escala
	_lienzo.draw_circle(base, maxf(6.0, 0.35 * _escala), Color(color, 0.35))
	_lienzo.draw_arc(base, maxf(6.0, 0.35 * _escala), 0.0, TAU, 24, color, 2.0)
	_lienzo.draw_line(base, punta, color, 3.0)
	var lado := direccion.orthogonal() * 0.25 * _escala
	_lienzo.draw_colored_polygon(PackedVector2Array([punta + direccion * 0.3 * _escala, punta + lado, punta - lado]), color)
	var texto := "Inicio" if dentro else "Inicio (fuera de una sala)"
	_lienzo.draw_string(ThemeDB.fallback_font, base + Vector2(10, -10), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func _dibujar_cuadricula(centro: Vector2, paso: float, color: Color, grosor: float) -> void:
	var x := fposmod(centro.x, paso)
	while x < _lienzo.size.x:
		_lienzo.draw_line(Vector2(x, 0), Vector2(x, _lienzo.size.y), color, grosor)
		x += paso
	var z := fposmod(centro.y, paso)
	while z < _lienzo.size.y:
		_lienzo.draw_line(Vector2(0, z), Vector2(_lienzo.size.x, z), color, grosor)
		z += paso

## Vista previa de la pieza elegida bajo el cursor, ya pegada a las paredes cercanas.
func _dibujar_fantasma(centro: Vector2) -> void:
	if _vista_techo or _modo_inicio or not _cursor_en_lienzo or _arrastre >= 0 or _paneo_activo:
		return
	if _indice_sala_en(_cursor_mapa) >= 0:
		return
	var definicion := _catalogo[_seleccion]
	var deseado := _cursor_mapa.snapped(Vector2(0.5, 0.5))
	var ajustado := _centro_ajustado(deseado, definicion, _angulo_seleccion, -1)
	var vertices := _vertices_sala({"x": ajustado.x, "z": ajustado.y}, definicion, deg_to_rad(_angulo_seleccion))
	var poligono := PackedVector2Array()
	for v in vertices:
		poligono.append(centro + v * _escala)
	var superpuesta := _huella_choca(PackedVector2Array(vertices), Vector2.ZERO, _huellas_de_salas(-1))
	var relleno := Color(0.85, 0.45, 0.25, 0.35) if superpuesta else Color(0.45, 0.75, 0.35, 0.35)
	var borde := Color(1.0, 0.65, 0.4, 0.95) if superpuesta else Color(0.7, 1.0, 0.5, 0.95)
	_lienzo.draw_colored_polygon(poligono, relleno)
	var cerrado := poligono.duplicate()
	cerrado.append(poligono[0])
	_lienzo.draw_polyline(cerrado, borde, 2.0)
	var aviso := ""
	if superpuesta:
		aviso = "superpuesta"
	elif ajustado.distance_to(deseado) > 0.01:
		aviso = "pegada"
	if not aviso.is_empty():
		_lienzo.draw_string(ThemeDB.fallback_font, centro + ajustado * _escala - Vector2(24, 0), aviso, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, borde)

## Texto fijo sobre el lienzo: modo, zoom y referencias de color.
func _dibujar_leyenda() -> void:
	var fuente := ThemeDB.fallback_font
	var modo := "Vista de techo" if _vista_techo else "Plano"
	_lienzo.draw_string(fuente, Vector2(12, 20), "%s · zoom %d%% · %d salas" % [modo, roundi(_escala / 24.0 * 100.0), _salas.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.85, 0.8))
	var entradas: Array = []
	if _vista_techo:
		entradas = [["Luz encendida", Color(0.82, 0.79, 0.66)], ["Intermitente", Color(0.76, 0.48, 0.19)], ["Averiada", Color(0.20, 0.20, 0.19)]]
	else:
		entradas = [["Puerta", Color(0.55, 1.0, 0.55)], ["Pared abierta", Color(0.55, 0.95, 1.0)], ["Pared cerrada", Color(1.0, 0.6, 0.2)], ["Intersección", Color(0.85, 0.55, 1.0)]]
	var origen := Vector2(12, _lienzo.size.y - 12 - entradas.size() * 18)
	_lienzo.draw_rect(Rect2(origen - Vector2(6, 6), Vector2(150, entradas.size() * 18 + 8)), Color(0.0, 0.0, 0.0, 0.45))
	for i in entradas.size():
		var entrada: Array = entradas[i]
		var color_entrada: Color = entrada[1]
		var y := origen.y + i * 18 + 10
		_lienzo.draw_rect(Rect2(origen.x, y - 9, 16, 8), color_entrada)
		_lienzo.draw_string(fuente, Vector2(origen.x + 24, y), String(entrada[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.92, 0.86))

func _dibujar_tiles_techo(sala: Dictionary, definicion: SalaDef, angulo: float, centro_lienzo: Vector2) -> void:
	const TAM_TILE := 1.5
	var huella := definicion.obtener_huella_local()
	var limites := GeometriaHuella.limites(huella)
	var centro_local := limites.get_center()
	for x in ceili(limites.size.x / TAM_TILE):
		for z in ceili(limites.size.y / TAM_TILE):
			var x0 := limites.position.x + x * TAM_TILE
			var z0 := limites.position.y + z * TAM_TILE
			var ancho_tile := minf(TAM_TILE, limites.end.x - x0)
			var largo_tile := minf(TAM_TILE, limites.end.y - z0)
			var celda := GeometriaHuella.rectangulo(ancho_tile, largo_tile, Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5))
			var piezas := GeometriaHuella.intersecciones(celda, huella)
			var centro_local_tile := Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5)
			var centro_mundo := Vector2(sala.x, sala.z) + (centro_local_tile - centro_local).rotated(angulo)
			var id_luz := _id_luminaria(centro_mundo)
			var modo_luz := int(_modos_luces.get(id_luz, -1))
			var color_tile := Color(0.44, 0.44, 0.41)
			if modo_luz == 0:
				color_tile = Color(0.82, 0.79, 0.66)
			elif modo_luz == 1:
				color_tile = Color(0.76, 0.48, 0.19)
			elif modo_luz == 2:
				color_tile = Color(0.20, 0.20, 0.19)
			for pieza in piezas:
				var poligono := PackedVector2Array()
				for punto in pieza:
					var mundo := Vector2(sala.x, sala.z) + (punto - centro_local).rotated(angulo)
					poligono.append(centro_lienzo + mundo * _escala)
				_lienzo.draw_colored_polygon(poligono, color_tile)
				for indice in poligono.size():
					_lienzo.draw_line(poligono[indice], poligono[(indice + 1) % poligono.size()], Color(0.12, 0.12, 0.12), 1.0)
			if modo_luz >= 0:
				var color_icono := Color(1.0, 0.95, 0.76)
				if modo_luz == 1:
					color_icono = Color(1.0, 0.66, 0.24)
				elif modo_luz == 2:
					color_icono = Color(0.62, 0.62, 0.59)
				_lienzo.draw_circle(centro_lienzo + centro_mundo * _escala, 4.5, color_icono)

func _cambiar_estado_luz_techo(punto_mapa: Vector2) -> void:
	var id := _luz_techo_en(punto_mapa)
	if id.is_empty():
		_estado.text = "Ese tile no tiene una luminaria para cambiar."
		if _modos_luces.is_empty():
			_estado.text += " Abrí Jugar una vez para cargar las luminarias de este mapa."
		return
	var modo := (int(_modos_luces.get(id, 0)) + 1) % 3
	_modos_luces[id] = modo
	_hay_cambios = true
	_guardar_actual()
	_registrar_historial()
	var estados := ["encendida", "intermitente", "averiada"]
	_estado.text = "Luminaria %s: %s." % [id, estados[modo]]
	_lienzo.queue_redraw()

func _luz_techo_en(punto_mapa: Vector2) -> String:
	const TAM_TILE := 1.5
	var mejor_distancia := INF
	var mejor_id := ""
	for sala in _salas:
		var definicion := _catalogo[_indice_tipo(String(sala.tipo))]
		var huella := definicion.obtener_huella_local()
		var limites := GeometriaHuella.limites(huella)
		var centro_local := limites.get_center()
		var angulo := deg_to_rad(float(sala.get("angulo", 0.0)))
		for x in ceili(limites.size.x / TAM_TILE):
			for z in ceili(limites.size.y / TAM_TILE):
				var x0 := limites.position.x + x * TAM_TILE
				var z0 := limites.position.y + z * TAM_TILE
				var ancho_tile := minf(TAM_TILE, limites.end.x - x0)
				var largo_tile := minf(TAM_TILE, limites.end.y - z0)
				var celda := GeometriaHuella.rectangulo(ancho_tile, largo_tile, Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5))
				var centro_local_tile := Vector2(x0 + ancho_tile * 0.5, z0 + largo_tile * 0.5)
				var centro_mundo := Vector2(sala.x, sala.z) + (centro_local_tile - centro_local).rotated(angulo)
				var id := _id_luminaria(centro_mundo)
				if not _modos_luces.has(id):
					continue
				var piezas := GeometriaHuella.intersecciones(celda, huella)
				for pieza in piezas:
					var poligono: Array[Vector2] = []
					for punto in pieza:
						poligono.append(Vector2(sala.x, sala.z) + (punto - centro_local).rotated(angulo))
					if _distancia_punto_poligono(punto_mapa, poligono) != 0.0:
						continue
					var distancia := punto_mapa.distance_to(centro_mundo)
					if distancia < mejor_distancia:
						mejor_distancia = distancia
						mejor_id = id
	return mejor_id

func _id_luminaria(posicion: Vector2) -> String:
	return "X %.2f · Z %.2f" % [posicion.x, posicion.y]

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
