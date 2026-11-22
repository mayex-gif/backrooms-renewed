extends CanvasLayer
## Menú de pausa: Continuar, Opciones, Ajustes de desarrollo, Volver al menú y Salir.
## Se abre con Escape durante el juego y se cierra con Escape.

const PanelAjustesScript = preload("res://sistema/panel_ajustes.gd")
const MENU_PRINCIPAL := "res://pruebas/menu_principal.tscn"

var _contenedor: CenterContainer
var _principal: PanelContainer
var _opciones: PanelContainer
var _apertura_ms := 0

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("menu_pausa")
	_apertura_ms = Time.get_ticks_msec()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var velo := ColorRect.new()
	velo.color = Color(0.0, 0.0, 0.0, 0.62)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	_contenedor = CenterContainer.new()
	_contenedor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_contenedor)
	_crear_principal()

func _crear_principal() -> void:
	_principal = PanelContainer.new()
	_principal.custom_minimum_size = Vector2(440, 0)
	_contenedor.add_child(_principal)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 26)
	_principal.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(0.86, 0.82, 0.62))
	columna.add_child(titulo)
	columna.add_child(HSeparator.new())
	var continuar := _boton(columna, "Continuar", _continuar)
	_boton(columna, "Opciones", _abrir_opciones)
	if OS.is_debug_build() and get_node_or_null("/root/PanelDesarrollo") != null:
		_boton(columna, "Ajustes de desarrollo", _abrir_desarrollo)
	_boton(columna, "Volver al menú principal", _volver_al_menu)
	_boton(columna, "Salir del juego", func() -> void: get_tree().quit())
	continuar.call_deferred("grab_focus")

func _boton(padre: Container, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 48
	boton.add_theme_font_size_override("font_size", 18)
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton

func _input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("ui_cancel"):
		return
	# La misma pulsación que abrió el menú no debe cerrarlo.
	if Time.get_ticks_msec() - _apertura_ms < 200:
		return
	get_viewport().set_input_as_handled()
	if _opciones != null:
		_cerrar_opciones()
	else:
		_continuar()

func _continuar() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()

func _abrir_opciones() -> void:
	_principal.hide()
	_opciones = PanelAjustesScript.new()
	_opciones.cerrado.connect(_cerrar_opciones)
	_contenedor.add_child(_opciones)

func _cerrar_opciones() -> void:
	if _opciones != null:
		_opciones.queue_free()
		_opciones = null
	_principal.show()

func _abrir_desarrollo() -> void:
	var panel := get_node_or_null("/root/PanelDesarrollo")
	queue_free()
	if panel != null:
		panel.call("abrir_ajustes_desarrollo")

func _volver_al_menu() -> void:
	get_tree().change_scene_to_file(MENU_PRINCIPAL)
	queue_free()
