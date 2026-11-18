extends CanvasLayer
## Controles de inspección disponibles solo en ejecuciones de desarrollo (F4).

var _panel: PanelContainer
var _estado: Label
var _check_luz: CheckButton
var _intensidad_luz: HSlider
var _cantidad_salas: SpinBox
var _peso_grandes: HSlider
var _peso_abiertas: HSlider
var _iluminacion_activa := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("panel_desarrollo")
	_crear_interfaz()
	get_tree().scene_changed.connect(_al_cambio_escena)
	_aplicar_iluminacion()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey:
		return
	if event.physical_keycode == KEY_F4 and event.pressed and not event.echo:
		_panel.visible = not _panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED
		_actualizar_modo_actual()
		get_viewport().set_input_as_handled()

func _crear_interfaz() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-300, -265)
	_panel.custom_minimum_size = Vector2(600, 530)
	add_child(_panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	_panel.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "AJUSTES DE DESARROLLO"
	titulo.add_theme_font_size_override("font_size", 22)
	columna.add_child(titulo)
	var ayuda := Label.new()
	ayuda.text = "F4 abre/cierra. Cambiá el conteo y los pesos, y aplicá para ver el plano rediseñado en ejecución."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(ayuda)
	_check_luz = CheckButton.new()
	_check_luz.text = "Iluminación realista"
	_check_luz.button_pressed = true
	_check_luz.toggled.connect(_alterna_iluminacion)
	columna.add_child(_check_luz)
	columna.add_child(_etiqueta("Intensidad de fluorescentes"))
	_intensidad_luz = _crear_slider(columna, 0.0, 2.0, 1.0, 0.05, _cambio_intensidad)
	columna.add_child(_etiqueta("Extensión del mapa (cantidad de salas)"))
	_cantidad_salas = SpinBox.new()
	_cantidad_salas.min_value = 1
	_cantidad_salas.max_value = 300
	_cantidad_salas.step = 1
	_cantidad_salas.value = 30
	_cantidad_salas.value_changed.connect(_cambio_peso)
	columna.add_child(_cantidad_salas)
	columna.add_child(_etiqueta("Peso de salas grandes"))
	_peso_grandes = _crear_slider(columna, 0.25, 3.0, 1.0, 0.05, _cambio_peso)
	columna.add_child(_etiqueta("Peso de espacios abiertos"))
	_peso_abiertas = _crear_slider(columna, 0.25, 3.0, 1.0, 0.05, _cambio_peso)
	var botones := HBoxContainer.new()
	columna.add_child(botones)
	var aplicar := Button.new()
	aplicar.text = "Aplicar al mapa actual"
	aplicar.pressed.connect(_aplicar_mapa)
	botones.add_child(aplicar)
	var cerrar := Button.new()
	cerrar.text = "Cerrar (F4)"
	cerrar.pressed.connect(_cerrar)
	botones.add_child(cerrar)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_estado)

func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	return etiqueta

func _crear_slider(padre: Control, minimo: float, maximo: float, valor: float, paso: float, callback: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = minimo
	slider.max_value = maximo
	slider.value = valor
	slider.step = paso
	slider.custom_minimum_size.x = 500
	slider.value_changed.connect(callback)
	padre.add_child(slider)
	return slider

func _alterna_iluminacion(activa: bool) -> void:
	_iluminacion_activa = activa
	_aplicar_iluminacion()

func _cambio_intensidad(_valor: float) -> void:
	_aplicar_iluminacion()

func _cambio_peso(_valor: float) -> void:
	var escena := get_tree().current_scene
	var maximo := int(_obtener_propiedad(escena, "cantidad_salas_disponibles", 0)) if escena != null else 0
	if maximo > 0 and int(_cantidad_salas.value) >= maximo:
		_estado.text = "El plano está al máximo y ya incluye todas las salas; bajá el conteo para notar el efecto de los pesos."
	else:
		_estado.text = "Al aplicar, los pesos priorizan ramales grandes/abiertos en el plano o tipos de sala en el modo aleatorio."

func _aplicar_iluminacion() -> void:
	if not is_inside_tree():
		return
	var entornos: Array[Node] = get_tree().get_nodes_in_group("entornos_juego")
	var escena := get_tree().current_scene
	if escena != null:
		for encontrado in escena.find_children("*", "WorldEnvironment", true, false):
			if not entornos.has(encontrado):
				entornos.append(encontrado)
	for nodo in entornos:
		var entorno := nodo as WorldEnvironment
		if entorno == null:
			continue
		var ambiente: Environment = entorno.environment
		if ambiente != null:
			ambiente.ambient_light_energy = float(entorno.get_meta("energia_ambiente_base", 0.32)) if _iluminacion_activa else 0.0
	for luz in get_tree().get_nodes_in_group("luces_techo_nodos"):
		luz.visible = _iluminacion_activa
		luz.set_meta("factor_desarrollo", _intensidad_luz.value)
		luz.light_energy = float(luz.get_meta("energia_base", 0.9)) * _intensidad_luz.value
	for panel in get_tree().get_nodes_in_group("paneles_luz"):
		var material := panel.material_override as StandardMaterial3D
		if material != null:
			material.emission_enabled = _iluminacion_activa and bool(panel.get_meta("emite_por_defecto", false))
	for luminaria in get_tree().get_nodes_in_group("luces_techo"):
		luminaria.visible = _iluminacion_activa

func _aplicar_mapa() -> void:
	var escena := get_tree().current_scene
	if escena == null or not escena.has_method("aplicar_configuracion_desarrollo"):
		_estado.text = "Entrá a un modo de juego para reconstruir su mapa."
		return
	escena.call("aplicar_configuracion_desarrollo", int(_cantidad_salas.value), _peso_grandes.value, _peso_abiertas.value)
	_aplicar_iluminacion()
	var salas_actuales := int(_obtener_propiedad(escena, "cantidad_salas_actuales", _obtener_propiedad(escena, "max_salas", _cantidad_salas.value)))
	_estado.text = "Mapa actualizado: %d salas activas (máximo configurado: %d)." % [salas_actuales, int(_cantidad_salas.value)]
	if int(_obtener_propiedad(escena, "cantidad_salas_disponibles", 0)) > 0 and int(_cantidad_salas.value) >= int(_obtener_propiedad(escena, "cantidad_salas_disponibles", 0)):
		_estado.text += " El plano está completo; los pesos se notan al reducir el conteo."

func _actualizar_modo_actual() -> void:
	var escena := get_tree().current_scene
	var admite_ajustes := escena != null and escena.has_method("aplicar_configuracion_desarrollo")
	_cantidad_salas.editable = admite_ajustes
	_peso_grandes.editable = admite_ajustes
	_peso_abiertas.editable = admite_ajustes
	if not admite_ajustes:
		_estado.text = "Los ajustes se activan dentro de uno de los modos de juego."
		return
	var cantidad_actual := int(_obtener_propiedad(escena, "cantidad_salas", _obtener_propiedad(escena, "max_salas", 24)))
	var cantidad_disponible := int(_obtener_propiedad(escena, "cantidad_salas_disponibles", 300))
	_cantidad_salas.max_value = maxf(1.0, cantidad_disponible)
	_cantidad_salas.set_value_no_signal(clampi(cantidad_actual, 1, cantidad_disponible))
	_peso_grandes.set_value_no_signal(float(_obtener_propiedad(escena, "multiplicador_grandes", 1.0)))
	_peso_abiertas.set_value_no_signal(float(_obtener_propiedad(escena, "multiplicador_abiertas", 1.0)))
	_estado.text = "Plano diseñado: el conteo limita su extensión y los pesos eligen ramales conectados. Aleatorio: ajusta el máximo y los pesos del catálogo."

func _obtener_propiedad(objeto: Object, nombre: String, valor_por_defecto: Variant) -> Variant:
	for propiedad in objeto.get_property_list():
		if propiedad.name == nombre:
			return objeto.get(nombre)
	return valor_por_defecto

func _al_cambio_escena() -> void:
	_aplicar_iluminacion()
	_actualizar_modo_actual()

func _cerrar() -> void:
	_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func esta_abierto() -> bool:
	return _panel != null and _panel.visible
