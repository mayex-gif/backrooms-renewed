extends Control
## Entrada al nivel diseñado y al generador procedural de pruebas.

const PanelAjustesScript = preload("res://sistema/panel_ajustes.gd")

var _centro_menu: CenterContainer
var _centro_opciones: CenterContainer
var _centro_personajes: CenterContainer
var _boton_personaje: Button

func _ready() -> void:
	_crear_interfaz()

func _crear_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.075, 0.070, 0.052)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_centro_menu = centro
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	centro.add_child(panel)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.14, 0.105, 0.97)
	estilo.border_color = Color(0.50, 0.46, 0.31)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", estilo)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 38)
	margen.add_theme_constant_override("margin_right", 38)
	margen.add_theme_constant_override("margin_top", 30)
	margen.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	margen.add_child(columna)

	var titulo := Label.new()
	titulo.text = "BACKROOMS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(0.86, 0.82, 0.62))
	columna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "Elegí cómo explorar"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 16)
	subtitulo.add_theme_color_override("font_color", Color(0.70, 0.68, 0.57))
	columna.add_child(subtitulo)
	var separador := HSeparator.new()
	columna.add_child(separador)
	_boton_personaje = _crear_boton("Elegir personaje: " + _nombre_personaje_actual(), "Seleccioná el modelo que vas a usar al entrar al nivel.")
	_boton_personaje.pressed.connect(_abrir_selector_personaje)
	columna.add_child(_boton_personaje)

	var plano := _crear_boton("Plano diseñado", "Explorá un nivel amplio con conexiones y recorridos pensados.")
	plano.pressed.connect(_abrir_escena.bind("res://pruebas/escenario_plano.tscn"))
	columna.add_child(plano)
	var aleatorio := _crear_boton("Generación aleatoria", "Conserva el mapa procedural con semilla y expansión por bloques.")
	aleatorio.pressed.connect(_abrir_escena.bind("res://pruebas/escenario_generado.tscn"))
	columna.add_child(aleatorio)
	var editor := _crear_boton("Editor de mapas", "Diseñá un mapa personalizado y guardalo para continuarlo después.")
	editor.pressed.connect(_abrir_escena.bind("res://pruebas/editor_mapa.tscn"))
	columna.add_child(editor)
	if FileAccess.file_exists("user://saves/mapa_actual.json"):
		var continuar_mapa := _crear_boton("Editar último mapa guardado", "Abrí el último mapa para seguir editándolo.")
		continuar_mapa.pressed.connect(_abrir_escena.bind("res://pruebas/editor_mapa.tscn"))
		columna.add_child(continuar_mapa)
		var jugar_mapa := _crear_boton("Jugar último mapa guardado", "Cargá y recorré el mapa personalizado guardado.")
		jugar_mapa.pressed.connect(_abrir_escena.bind("res://pruebas/mapa_guardado.tscn"))
		columna.add_child(jugar_mapa)
	var opciones := _crear_boton("Opciones", "Pantalla completa, sonido, sensibilidad y calidad gráfica.")
	opciones.pressed.connect(_abrir_opciones)
	columna.add_child(opciones)
	var salir := Button.new()
	salir.text = "Salir"
	salir.custom_minimum_size.y = 42
	salir.pressed.connect(_salir)
	columna.add_child(salir)
	plano.grab_focus()

func _crear_boton(texto: String, descripcion: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.tooltip_text = descripcion
	boton.custom_minimum_size.y = 52
	boton.add_theme_font_size_override("font_size", 18)
	return boton

func _abrir_opciones() -> void:
	_centro_menu.hide()
	_centro_opciones = CenterContainer.new()
	_centro_opciones.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_centro_opciones)
	var panel := PanelAjustesScript.new()
	panel.cerrado.connect(_cerrar_opciones)
	_centro_opciones.add_child(panel)

func _abrir_selector_personaje() -> void:
	_centro_menu.hide()
	_centro_personajes = CenterContainer.new()
	_centro_personajes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_centro_personajes)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	_centro_personajes.add_child(panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_%s" % lado, 38)
	for lado in ["top", "bottom"]:
		margen.add_theme_constant_override("margin_%s" % lado, 28)
	panel.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "ELEGIR PERSONAJE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	columna.add_child(titulo)
	var descripcion := Label.new()
	descripcion.text = "La elección se guarda y se aplica al comenzar una partida."
	descripcion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(descripcion)
	var casual := _crear_boton("Explorador casual", "Personaje actual con ropa casual y linterna.")
	casual.pressed.connect(_seleccionar_personaje.bind("casual"))
	columna.add_child(casual)
	var guardia := _crear_boton("Guardia de seguridad", "Uniforme, rig y animaciones idle, caminar y correr.")
	guardia.pressed.connect(_seleccionar_personaje.bind("guardia_seguridad"))
	columna.add_child(guardia)
	var volver := _crear_boton("Volver", "Regresar al menú principal sin cambiar la elección.")
	volver.pressed.connect(_cerrar_selector_personaje)
	columna.add_child(volver)
	casual.grab_focus()

func _seleccionar_personaje(id_personaje: String) -> void:
	var selector := get_node_or_null("/root/SelectorPersonaje")
	if selector == null or not selector.has_method("seleccionar"):
		push_error("No está disponible el selector de personajes.")
		return
	if not bool(selector.call("seleccionar", id_personaje)):
		push_warning("No se pudo guardar la elección; se aplicará en esta sesión.")
	_boton_personaje.text = "Elegir personaje: " + _nombre_personaje_actual()
	_cerrar_selector_personaje()

func _nombre_personaje_actual() -> String:
	var selector := get_node_or_null("/root/SelectorPersonaje")
	if selector != null and selector.has_method("obtener_nombre_actual"):
		return String(selector.call("obtener_nombre_actual"))
	return "Explorador casual"

func _cerrar_selector_personaje() -> void:
	if _centro_personajes != null:
		_centro_personajes.queue_free()
		_centro_personajes = null
	_centro_menu.show()

func _cerrar_opciones() -> void:
	if _centro_opciones != null:
		_centro_opciones.queue_free()
		_centro_opciones = null
	_centro_menu.show()

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") and _centro_opciones != null:
		get_viewport().set_input_as_handled()
		_cerrar_opciones()
	elif evento.is_action_pressed("ui_cancel") and _centro_personajes != null:
		get_viewport().set_input_as_handled()
		_cerrar_selector_personaje()

func _abrir_escena(ruta: String) -> void:
	var error := get_tree().change_scene_to_file(ruta)
	if error != OK:
		push_error("No se pudo abrir %s (error %d)." % [ruta, error])

func _salir() -> void:
	get_tree().quit()
