extends PanelContainer
## Pantalla de opciones. Se usa en el menú principal y en el menú de pausa.
## Los cambios se aplican al instante y se guardan al cerrar.

signal cerrado

func _ready() -> void:
	_construir_interfaz()

func _construir_interfaz() -> void:
	for hijo in get_children():
		hijo.queue_free()

	custom_minimum_size = Vector2(560, 0)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)
	var desplazable := ScrollContainer.new()
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desplazable.custom_minimum_size.y = 460
	margen.add_child(desplazable)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 12)
	desplazable.add_child(columna)

	var titulo := Label.new()
	titulo.text = "OPCIONES"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(0.86, 0.82, 0.62))
	columna.add_child(titulo)

	columna.add_child(_seccion("Pantalla"))
	_agregar_casilla(columna, "Pantalla completa", Ajustes.pantalla_completa, func(valor: bool) -> void: Ajustes.pantalla_completa = valor)
	_agregar_casilla(columna, "Sincronización vertical (VSync)", Ajustes.vsync, func(valor: bool) -> void: Ajustes.vsync = valor)
	_agregar_deslizador(columna, "Campo de visión", Ajustes.campo_vision, 60.0, 100.0, 1.0, "°", func(valor: float) -> void: Ajustes.campo_vision = valor)

	columna.add_child(_seccion("Sonido"))
	_agregar_deslizador(columna, "Volumen general", Ajustes.volumen * 100.0, 0.0, 100.0, 1.0, "%", func(valor: float) -> void: Ajustes.volumen = valor / 100.0)

	columna.add_child(_seccion("Controles"))
	_agregar_deslizador(columna, "Sensibilidad del mouse", Ajustes.sensibilidad, 0.2, 3.0, 0.05, "×", func(valor: float) -> void: Ajustes.sensibilidad = valor)

	columna.add_child(_seccion("Calidad gráfica"))
	_agregar_casilla(columna, "Sombras de las luces", Ajustes.sombras, func(valor: bool) -> void: Ajustes.sombras = valor)
	_agregar_casilla(columna, "Rebote de luz en pantalla", Ajustes.rebote_pantalla, func(valor: bool) -> void: Ajustes.rebote_pantalla = valor)
	var nota := Label.new()
	nota.text = "Si el juego va lento, probá desactivar las sombras o el rebote de luz."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.add_theme_font_size_override("font_size", 13)
	nota.add_theme_color_override("font_color", Color(0.70, 0.68, 0.57))
	columna.add_child(nota)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 12)
	columna.add_child(botones)
	var restablecer := Button.new()
	restablecer.text = "Restablecer"
	restablecer.custom_minimum_size = Vector2(150, 42)
	restablecer.pressed.connect(_restablecer)
	botones.add_child(restablecer)
	var cerrar := Button.new()
	cerrar.text = "Volver"
	cerrar.custom_minimum_size = Vector2(150, 42)
	cerrar.pressed.connect(cerrar_panel)
	botones.add_child(cerrar)
	call_deferred("_enfocar_boton", cerrar)

func _enfocar_boton(boton: Button) -> void:
	if is_inside_tree() and is_instance_valid(boton) and boton.is_inside_tree() and boton.visible:
		boton.grab_focus()

func cerrar_panel() -> void:
	Ajustes.guardar()
	cerrado.emit()

func _restablecer() -> void:
	Ajustes.restablecer()
	_construir_interfaz()

func _seccion(texto: String) -> Control:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 18)
	etiqueta.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	return etiqueta

func _agregar_casilla(padre: Container, texto: String, valor: bool, al_cambiar: Callable) -> void:
	var casilla := CheckButton.new()
	casilla.text = texto
	casilla.button_pressed = valor
	casilla.toggled.connect(func(activa: bool) -> void:
		al_cambiar.call(activa)
		Ajustes.aplicar()
	)
	padre.add_child(casilla)

func _agregar_deslizador(padre: Container, texto: String, valor: float, minimo: float, maximo: float, paso: float, unidad: String, al_cambiar: Callable) -> void:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.custom_minimum_size.x = 210
	fila.add_child(etiqueta)
	var deslizador := HSlider.new()
	deslizador.min_value = minimo
	deslizador.max_value = maximo
	deslizador.step = paso
	deslizador.value = valor
	deslizador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deslizador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(deslizador)
	var cifra := Label.new()
	cifra.custom_minimum_size.x = 64
	cifra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cifra.text = _formatear(valor, paso, unidad)
	fila.add_child(cifra)
	deslizador.value_changed.connect(func(nuevo: float) -> void:
		al_cambiar.call(nuevo)
		cifra.text = _formatear(nuevo, paso, unidad)
		Ajustes.aplicar()
	)
	padre.add_child(fila)

func _formatear(valor: float, paso: float, unidad: String) -> String:
	if paso < 1.0:
		return "%.2f%s" % [valor, unidad]
	return "%d%s" % [roundi(valor), unidad]
