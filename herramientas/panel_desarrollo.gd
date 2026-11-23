extends CanvasLayer
## Controles de iluminación y desarrollo accesibles desde el editor de mapas.

const RUTA_MAPA := "user://saves/mapa_actual.json"
const RUTA_CONFIG_ILUMINACION := "user://iluminacion.cfg"
const LuminariaScript = preload("res://salas/luminaria.gd")

var _panel: PanelContainer
var _estado: Label
var _check_luz: CheckButton
var _intensidad_luz: HSlider
var _cantidad_salas: SpinBox
var _peso_grandes: HSlider
var _peso_abiertas: HSlider
var _pagina_ajustes: VBoxContainer
var _modos_luz_por_id: Dictionary = {}
var _iluminacion_activa := true
var _intensidad_configurada := 0.6
var semilado_haz := 16.5
var borde_proyector := 0.74
var suavidad_borde_haz := 1.25
var emision_panel := 2.5
var temperatura_luz := 1.38
var atenuacion_spot_normal := 2.4
var atenuacion_spot_sala_alta := 1.6
var altura_atenuacion_inicio := 6.1
var altura_atenuacion_fin := 12.6
var tamano_foco := 3.5
var especular_foco := 0.84
var sombra_bias := 0.075
var sombra_normal_bias := 1.9
var sombra_desenfoque := 2.0
var desvanecer_desde := 50.0
var desvanecer_sombras_desde := 50.0
var apagar_desde := 50.0
var rebote_local_activo := true
var energia_rebote_local := 0.06
var alcance_rebote_local := 1.9
var altura_rebote_local := -0.04
var atenuacion_rebote_local := 1.8
var rebote_paredes_activo := true
var energia_rebote_paredes := 0.007
var semilado_rebote_paredes := 2.2
var altura_rebote_paredes := -0.07
var atenuacion_rebote_paredes := 1.0
var especular_rebotes := 0.17
var color_panel_apagado := 0.6
var relleno_sala_activo := false
var energia_relleno_por_panel := 0.035
var energia_relleno_maxima := 0.1
var altura_relleno_sala := 1.0
var alcance_extra_relleno := 1.8
var atenuacion_relleno_sala := 1.0
var probabilidad_falla := 0.0
var probabilidad_intermitencia := 0.0
var parpadeo_encendida_min := 0.25
var parpadeo_encendida_max := 0.9
var parpadeo_apagada_min := 0.18
var parpadeo_apagada_max := 0.8
var variacion_luz_minima := 0.72
var emision_parpadeo_minima := 0.62
var velocidad_encendido := 31.0
var velocidad_apagado := 55.0

const MODO_ENCENDIDA := 0
const MODO_INTERMITENTE := 1
const MODO_AVERIADA := 2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("panel_desarrollo")
	_cargar_configuracion_iluminacion()
	_crear_interfaz()
	get_tree().scene_changed.connect(_al_cambio_escena)
	_cargar_modos_persistidos()
	_aplicar_iluminacion()

func _crear_interfaz() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-400, -375)
	_panel.custom_minimum_size = Vector2(800, 750)
	add_child(_panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 22)
	_panel.add_child(margen)
	var paginas := Control.new()
	paginas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_child(paginas)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paginas.add_child(scroll)
	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columna.add_theme_constant_override("separation", 10)
	_pagina_ajustes = columna
	scroll.add_child(columna)
	var titulo := Label.new()
	titulo.text = "AJUSTES DE DESARROLLO"
	titulo.add_theme_font_size_override("font_size", 22)
	columna.add_child(titulo)
	var ayuda := Label.new()
	ayuda.text = "Controles de iluminación y generación para inspeccionar el mapa actual."
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(ayuda)
	columna.add_child(_etiqueta("Haz principal y panel"))
	_check_luz = CheckButton.new()
	_check_luz.text = "Iluminación realista"
	_check_luz.button_pressed = _iluminacion_activa
	_check_luz.toggled.connect(_alterna_iluminacion)
	columna.add_child(_check_luz)
	columna.add_child(_etiqueta("Intensidad de fluorescentes"))
	var fila_intensidad := HBoxContainer.new()
	columna.add_child(fila_intensidad)
	_intensidad_luz = _crear_slider(fila_intensidad, 0.0, 2.0, _intensidad_configurada, 0.05, _cambio_intensidad)
	var lectura_intensidad := Label.new()
	lectura_intensidad.custom_minimum_size.x = 70.0
	lectura_intensidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lectura_intensidad.text = "%.2f" % _intensidad_configurada
	fila_intensidad.add_child(lectura_intensidad)
	_intensidad_luz.value_changed.connect(func(valor: float) -> void: lectura_intensidad.text = "%.2f" % valor)
	_agregar_deslizador_luz(columna, "semilado_haz", 4.0, 18.0, 0.25)
	_agregar_deslizador_luz(columna, "suavidad_borde_haz", 0.1, 1.5, 0.05)
	_agregar_deslizador_luz(columna, "emision_panel", 0.0, 2.5, 0.05)
	_agregar_deslizador_luz(columna, "temperatura_luz", 0.6, 1.5, 0.01)
	_agregar_deslizador_luz(columna, "borde_proyector", 0.4, 0.9, 0.01)
	_agregar_deslizador_luz(columna, "atenuacion_spot_normal", 0.3, 4.0, 0.05)
	_agregar_deslizador_luz(columna, "atenuacion_spot_sala_alta", 0.3, 4.0, 0.05)
	_agregar_deslizador_luz(columna, "altura_atenuacion_inicio", 1.0, 10.0, 0.1)
	_agregar_deslizador_luz(columna, "altura_atenuacion_fin", 2.0, 20.0, 0.1)
	_agregar_deslizador_luz(columna, "tamano_foco", 0.0, 4.0, 0.05)
	_agregar_deslizador_luz(columna, "especular_foco", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "sombra_bias", 0.001, 0.2, 0.001)
	_agregar_deslizador_luz(columna, "sombra_normal_bias", 0.0, 4.0, 0.05)
	_agregar_deslizador_luz(columna, "sombra_desenfoque", 0.0, 4.0, 0.05)
	_agregar_deslizador_luz(columna, "desvanecer_desde", 5.0, 100.0, 1.0)
	_agregar_deslizador_luz(columna, "desvanecer_sombras_desde", 5.0, 100.0, 1.0)
	_agregar_deslizador_luz(columna, "apagar_desde", 10.0, 150.0, 1.0)
	columna.add_child(HSeparator.new())
	columna.add_child(_etiqueta("Rebote local de cada luminaria"))
	_agregar_casilla_luz(columna, "Rebote local activado", "rebote_local_activo")
	_agregar_deslizador_luz(columna, "energia_rebote_local", 0.0, 0.15, 0.005)
	_agregar_deslizador_luz(columna, "alcance_rebote_local", 0.5, 6.0, 0.1)
	_agregar_deslizador_luz(columna, "altura_rebote_local", -0.25, 0.8, 0.01)
	_agregar_deslizador_luz(columna, "atenuacion_rebote_local", 0.3, 3.0, 0.05)
	columna.add_child(HSeparator.new())
	columna.add_child(_etiqueta("Rebote difuso hacia las paredes"))
	_agregar_casilla_luz(columna, "Rebote a paredes activado", "rebote_paredes_activo")
	_agregar_deslizador_luz(columna, "energia_rebote_paredes", 0.0, 0.05, 0.001)
	_agregar_deslizador_luz(columna, "semilado_rebote_paredes", 1.0, 10.0, 0.1)
	_agregar_deslizador_luz(columna, "altura_rebote_paredes", -0.25, 1.2, 0.01)
	_agregar_deslizador_luz(columna, "atenuacion_rebote_paredes", 0.3, 2.5, 0.05)
	_agregar_deslizador_luz(columna, "especular_rebotes", 0.0, 1.0, 0.01)
	columna.add_child(_etiqueta("Brillo gris de placas apagadas"))
	_agregar_deslizador_luz(columna, "color_panel_apagado", 0.05, 0.6, 0.005)
	columna.add_child(HSeparator.new())
	columna.add_child(_etiqueta("Rebote amplio por sala"))
	_agregar_casilla_luz(columna, "Relleno ambiental por sala", "relleno_sala_activo")
	_agregar_deslizador_luz(columna, "energia_relleno_por_panel", 0.0, 0.2, 0.005)
	_agregar_deslizador_luz(columna, "energia_relleno_maxima", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "altura_relleno_sala", 0.1, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "alcance_extra_relleno", 0.0, 10.0, 0.1)
	_agregar_deslizador_luz(columna, "atenuacion_relleno_sala", 0.1, 2.0, 0.05)
	columna.add_child(HSeparator.new())
	columna.add_child(_etiqueta("Parpadeo y fallas para luminarias nuevas"))
	_agregar_deslizador_luz(columna, "probabilidad_falla", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "probabilidad_intermitencia", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "parpadeo_encendida_min", 0.05, 2.0, 0.05)
	_agregar_deslizador_luz(columna, "parpadeo_encendida_max", 0.1, 3.0, 0.05)
	_agregar_deslizador_luz(columna, "parpadeo_apagada_min", 0.05, 2.0, 0.05)
	_agregar_deslizador_luz(columna, "parpadeo_apagada_max", 0.1, 3.0, 0.05)
	_agregar_deslizador_luz(columna, "variacion_luz_minima", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "emision_parpadeo_minima", 0.0, 1.0, 0.01)
	_agregar_deslizador_luz(columna, "velocidad_encendido", 1.0, 60.0, 1.0)
	_agregar_deslizador_luz(columna, "velocidad_apagado", 1.0, 100.0, 1.0)
	columna.add_child(HSeparator.new())
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
	cerrar.text = "Cerrar panel"
	cerrar.pressed.connect(_cerrar)
	botones.add_child(cerrar)
	var guardar_luces := Button.new()
	guardar_luces.text = "Guardar iluminación"
	guardar_luces.pressed.connect(_guardar_configuracion_iluminacion)
	botones.add_child(guardar_luces)
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

func _agregar_deslizador_luz(padre: Control, propiedad: String, minimo: float, maximo: float, paso: float) -> void:
	padre.add_child(_etiqueta(propiedad.replace("_", " ").capitalize()))
	var fila := HBoxContainer.new()
	padre.add_child(fila)
	var slider := _crear_slider(fila, minimo, maximo, float(get(propiedad)), paso, _cambio_config_luz.bind(propiedad))
	slider.tooltip_text = propiedad
	var lectura := Label.new()
	lectura.custom_minimum_size.x = 70.0
	lectura.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lectura.text = "%.3f" % slider.value
	fila.add_child(lectura)
	slider.value_changed.connect(func(valor: float) -> void: lectura.text = "%.3f" % valor)

func _agregar_casilla_luz(padre: Control, texto: String, propiedad: String) -> void:
	var casilla := CheckButton.new()
	casilla.text = texto
	casilla.button_pressed = bool(get(propiedad))
	casilla.toggled.connect(_cambio_casilla_luz.bind(propiedad))
	padre.add_child(casilla)

func _cambio_config_luz(valor: float, propiedad: String) -> void:
	set(propiedad, valor)
	_aplicar_configuracion_a_luces()

func _cambio_casilla_luz(valor: bool, propiedad: String) -> void:
	set(propiedad, valor)
	_aplicar_configuracion_a_luces()

func _cargar_configuracion_iluminacion() -> void:
	var config := ConfigFile.new()
	if config.load(RUTA_CONFIG_ILUMINACION) != OK:
		return
	for propiedad in _propiedades_numericas_iluminacion():
		set(propiedad, float(config.get_value("luces", propiedad, get(propiedad))))
	for propiedad in ["rebote_local_activo", "rebote_paredes_activo", "relleno_sala_activo"]:
		set(propiedad, bool(config.get_value("luces", propiedad, get(propiedad))))
	_iluminacion_activa = bool(config.get_value("luces", "iluminacion_activa", _iluminacion_activa))
	_intensidad_configurada = float(config.get_value("luces", "intensidad", 1.0))

func _guardar_configuracion_iluminacion() -> void:
	var config := ConfigFile.new()
	for propiedad in _propiedades_numericas_iluminacion() + ["rebote_local_activo", "rebote_paredes_activo", "relleno_sala_activo"]:
		config.set_value("luces", propiedad, get(propiedad))
	config.set_value("luces", "iluminacion_activa", _iluminacion_activa)
	config.set_value("luces", "intensidad", _intensidad_luz.value)
	var error := config.save(RUTA_CONFIG_ILUMINACION)
	_estado.text = "Iluminación guardada en user://iluminacion.cfg." if error == OK else "No se pudo guardar la configuración (error %d)." % error

func _propiedades_numericas_iluminacion() -> Array[String]:
	return ["semilado_haz", "borde_proyector", "suavidad_borde_haz", "emision_panel", "temperatura_luz", "atenuacion_spot_normal", "atenuacion_spot_sala_alta", "altura_atenuacion_inicio", "altura_atenuacion_fin", "tamano_foco", "especular_foco", "sombra_bias", "sombra_normal_bias", "sombra_desenfoque", "desvanecer_desde", "desvanecer_sombras_desde", "apagar_desde", "energia_rebote_local", "alcance_rebote_local", "altura_rebote_local", "atenuacion_rebote_local", "energia_rebote_paredes", "semilado_rebote_paredes", "altura_rebote_paredes", "atenuacion_rebote_paredes", "especular_rebotes", "color_panel_apagado", "energia_relleno_por_panel", "energia_relleno_maxima", "altura_relleno_sala", "alcance_extra_relleno", "atenuacion_relleno_sala", "probabilidad_falla", "probabilidad_intermitencia", "parpadeo_encendida_min", "parpadeo_encendida_max", "parpadeo_apagada_min", "parpadeo_apagada_max", "variacion_luz_minima", "emision_parpadeo_minima", "velocidad_encendido", "velocidad_apagado"]

func _alterna_iluminacion(activa: bool) -> void:
	_iluminacion_activa = activa
	_aplicar_iluminacion()

func _cambio_intensidad(valor: float) -> void:
	_intensidad_configurada = valor
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
	var luminarias := get_tree().get_nodes_in_group("luces_techo")
	var hay_luminaria_operativa := false
	for luminaria in luminarias:
		if int(_obtener_propiedad(luminaria, "modo", MODO_ENCENDIDA)) != MODO_AVERIADA:
			hay_luminaria_operativa = true
			break
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
			# El relleno ambiental no debe simular luminarias cuando todas están averiadas.
			var debe_conservar_relleno := luminarias.is_empty() or hay_luminaria_operativa
			ambiente.ambient_light_energy = float(entorno.get_meta("energia_ambiente_base", 0.32)) if _iluminacion_activa and debe_conservar_relleno else 0.0
	for luz in get_tree().get_nodes_in_group("luces_techo_nodos"):
		var modo := int(luz.get_meta("modo_luz", MODO_ENCENDIDA))
		luz.visible = _iluminacion_activa and modo != MODO_AVERIADA
		luz.set_meta("factor_desarrollo", _intensidad_luz.value)
		if modo == MODO_ENCENDIDA:
			luz.light_energy = float(luz.get_meta("energia_base", 3.2)) * _intensidad_luz.value
		elif modo == MODO_AVERIADA:
			luz.light_energy = 0.0
	for panel in get_tree().get_nodes_in_group("paneles_luz"):
		var material := panel.material_override as StandardMaterial3D
		if material != null:
			var modo := int(panel.get_meta("modo_luz", MODO_ENCENDIDA))
			if modo != MODO_INTERMITENTE:
				material.emission_enabled = _iluminacion_activa and modo == MODO_ENCENDIDA
	for luminaria in get_tree().get_nodes_in_group("luces_techo"):
		luminaria.visible = _iluminacion_activa
	_aplicar_configuracion_a_luces()

func _aplicar_configuracion_a_luces() -> void:
	if not is_inside_tree():
		return
	for luminaria in get_tree().get_nodes_in_group("luces_techo"):
		configurar_luminaria(luminaria)
	for relleno in get_tree().get_nodes_in_group("rellenos_sala"):
		_configurar_relleno_sala(relleno)

func actualizar_relleno_sala(sala: Node) -> void:
	if sala == null:
		return
	var relleno := sala.get_node_or_null("RellenoRebote") as OmniLight3D
	if relleno != null:
		_configurar_relleno_sala(relleno)

func _configurar_relleno_sala(relleno: OmniLight3D) -> void:
	var paneles := 0
	var sala := relleno.get_parent()
	if sala != null:
		for luminaria in sala.get_children():
			if luminaria.is_in_group("luces_techo") and int(_obtener_propiedad(luminaria, "modo", MODO_ENCENDIDA)) != MODO_AVERIADA:
				paneles += 1
	relleno.set_meta("paneles_operativos", paneles)
	var radio := float(relleno.get_meta("radio_base", 1.0))
	relleno.visible = _iluminacion_activa and relleno_sala_activo and paneles > 0
	relleno.light_energy = minf(energia_relleno_por_panel * paneles, energia_relleno_maxima) * _intensidad_configurada
	relleno.position.y = float(relleno.get_meta("alto_sala", 4.0)) * altura_relleno_sala
	relleno.omni_range = radio + alcance_extra_relleno
	relleno.omni_attenuation = atenuacion_relleno_sala

func configurar_luminaria(luminaria: Node) -> void:
	if luminaria == null or not is_instance_valid(luminaria):
		return
	var modo := int(_obtener_propiedad(luminaria, "modo", MODO_ENCENDIDA))
	var foco := luminaria.get_node_or_null("Foco") as SpotLight3D
	var color_actual := Color(1.0, 0.97, 0.86) * temperatura_luz
	if foco != null:
		var altura := float(foco.get_meta("altura_hasta_suelo", 4.0))
		var base := float(foco.get_meta("energia_base", 0.5))
		foco.set_meta("factor_desarrollo", _intensidad_luz.value if _intensidad_luz != null else _intensidad_configurada)
		foco.spot_angle = clampf(rad_to_deg(atan(semilado_haz / (0.6 * maxf(altura, 0.1)))), 20.0, 80.0)
		foco.spot_angle_attenuation = suavidad_borde_haz
		foco.light_projector = LuminariaScript._proyector(borde_proyector)
		foco.spot_range = sqrt(altura * altura + 2.0 * semilado_haz * semilado_haz) + 0.4
		var proporcion_altura := clampf(inverse_lerp(altura_atenuacion_inicio, maxf(altura_atenuacion_inicio + 0.01, altura_atenuacion_fin), altura), 0.0, 1.0)
		foco.spot_attenuation = lerpf(atenuacion_spot_normal, atenuacion_spot_sala_alta, proporcion_altura)
		foco.light_size = tamano_foco
		foco.light_specular = especular_foco
		foco.light_color = color_actual
		foco.shadow_bias = sombra_bias
		foco.shadow_normal_bias = sombra_normal_bias
		foco.shadow_blur = sombra_desenfoque
		foco.distance_fade_enabled = true
		foco.distance_fade_begin = desvanecer_desde
		foco.distance_fade_shadow = desvanecer_sombras_desde
		foco.distance_fade_length = maxf(apagar_desde - desvanecer_desde, 0.0)
		var ajustes := get_node_or_null("/root/Ajustes")
		foco.shadow_enabled = bool(_obtener_propiedad(ajustes, "sombras", true))
		var encendida := bool(_obtener_propiedad(luminaria, "_encendida", modo == MODO_ENCENDIDA))
		foco.light_energy = base * _intensidad_configurada * (1.0 if encendida else 0.0)
		if modo == MODO_ENCENDIDA:
			foco.light_energy = base * _intensidad_configurada
		foco.visible = _iluminacion_activa and modo != MODO_AVERIADA
	for nombre in ["ReboteLocal", "ReboteParedes"]:
		var rebote := luminaria.get_node_or_null(nombre) as OmniLight3D
		if rebote == null:
			continue
		var es_local: bool = nombre == "ReboteLocal"
		var activo: bool = rebote_local_activo if es_local else rebote_paredes_activo
		var energia: float = energia_rebote_local if es_local else energia_rebote_paredes
		var alto: float = altura_rebote_local if es_local else altura_rebote_paredes
		rebote.position.y = alto
		rebote.set_meta("energia_base", energia)
		rebote.light_color = color_actual
		rebote.light_specular = especular_rebotes
		rebote.light_energy = energia * _intensidad_configurada if modo == MODO_ENCENDIDA else 0.0
		rebote.visible = _iluminacion_activa and activo and modo != MODO_AVERIADA
		if es_local:
			rebote.omni_range = alcance_rebote_local
			rebote.omni_attenuation = atenuacion_rebote_local
		else:
			var altura_piso := float(rebote.get_meta("altura_hasta_suelo", 4.0))
			rebote.omni_range = sqrt(altura_piso * altura_piso + semilado_rebote_paredes * semilado_rebote_paredes) + 0.5
			rebote.omni_attenuation = atenuacion_rebote_paredes
	var panel := luminaria.get_node_or_null("PanelEmisor") as MeshInstance3D
	if panel != null:
		panel.set_meta("color_apagado", color_panel_apagado)
		var material := panel.material_override as StandardMaterial3D
		if material != null:
			material.emission = color_actual
			var emision_actual := float(_obtener_propiedad(luminaria, "_emision_actual", emision_panel))
			var emite := modo == MODO_ENCENDIDA or (modo == MODO_INTERMITENTE and bool(_obtener_propiedad(luminaria, "_encendida", false)))
			material.emission_enabled = _iluminacion_activa and emite
			material.emission_energy_multiplier = emision_panel if modo == MODO_ENCENDIDA else emision_actual * emision_panel / 1.3
			material.albedo_color = Color(0.9, 0.9, 0.86) if emite else Color(color_panel_apagado, color_panel_apagado, color_panel_apagado)

func abrir_ajustes_desarrollo() -> void:
	_pagina_ajustes.visible = true
	_panel.visible = true
	_actualizar_modo_actual()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _cargar_modos_persistidos() -> void:
	_modos_luz_por_id.clear()
	if not FileAccess.file_exists(RUTA_MAPA):
		return
	var archivo := FileAccess.open(RUTA_MAPA, FileAccess.READ)
	if archivo == null:
		return
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not datos is Dictionary:
		return
	var modos_guardados: Variant = datos.get("modos_luces", {})
	if modos_guardados is Dictionary:
		for id in modos_guardados:
			_modos_luz_por_id[String(id)] = int(modos_guardados[id])

func _guardar_modos_persistidos() -> void:
	if not FileAccess.file_exists(RUTA_MAPA):
		return
	var archivo_lectura := FileAccess.open(RUTA_MAPA, FileAccess.READ)
	if archivo_lectura == null:
		return
	var datos: Variant = JSON.parse_string(archivo_lectura.get_as_text())
	archivo_lectura.close()
	if not datos is Dictionary:
		return
	datos["modos_luces"] = _modos_luz_por_id.duplicate(true)
	var archivo_escritura := FileAccess.open(RUTA_MAPA, FileAccess.WRITE)
	if archivo_escritura == null:
		return
	archivo_escritura.store_string(JSON.stringify(datos, "\t"))

func _sincronizar_modos_luces() -> void:
	var luces := get_tree().get_nodes_in_group("luces_techo")
	if luces.is_empty():
		return
	# También conserva estados de luces automáticas no creadas en el modo manual.
	var modos_activos: Dictionary = _modos_luz_por_id.duplicate(true)
	for luminaria in luces:
		var id := String(luminaria.get_meta("id_editor", luminaria.name))
		var modo := int(_modos_luz_por_id.get(id, _obtener_propiedad(luminaria, "modo", MODO_ENCENDIDA)))
		if int(_obtener_propiedad(luminaria, "modo", modo)) != modo:
			luminaria.call("configurar_modo", modo)
		modos_activos[id] = modo
	_modos_luz_por_id = modos_activos
	_guardar_modos_persistidos()

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
	var escena := get_tree().current_scene
	if escena != null and escena.scene_file_path == "res://pruebas/mapa_guardado.tscn":
		_cargar_modos_persistidos()
		_sincronizar_modos_luces()
	else:
		_modos_luz_por_id.clear()
	_aplicar_iluminacion()
	_actualizar_modo_actual()
	_panel.visible = false
	_pagina_ajustes.visible = true

func _cerrar() -> void:
	_panel.visible = false
	if get_tree().current_scene != null and not get_tree().current_scene.find_children("Jugador", "CharacterBody3D", true, false).is_empty():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func esta_abierto() -> bool:
	return _panel != null and _panel.visible
