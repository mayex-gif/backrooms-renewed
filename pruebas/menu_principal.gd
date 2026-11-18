extends Control
## Entrada al nivel diseñado y al generador procedural de pruebas.

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
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 700)
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

func _abrir_escena(ruta: String) -> void:
	var error := get_tree().change_scene_to_file(ruta)
	if error != OK:
		push_error("No se pudo abrir %s (error %d)." % [ruta, error])

func _salir() -> void:
	get_tree().quit()
