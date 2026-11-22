extends Node3D
## Comportamiento configurable de un panel: estable, intermitente o averiado.

const MODO_ENCENDIDA := 0
const MODO_INTERMITENTE := 1
const MODO_AVERIADA := 2
## Qué tan rápido sube el brillo al encender y baja al apagar (1/segundo).
## El encendido es gradual para que el pozo de luz no aparezca de golpe.
const VELOCIDAD_ENCENDIDO := 22.0
const VELOCIDAD_APAGADO := 60.0
## Brillo del panel encendido. Más alto que ~1,5 lo vuelve un blanco plano sin detalle.
const EMISION_ENCENDIDA := 1.3
const COLOR_PANEL_ENCENDIDO := Color(0.9, 0.9, 0.86)
const COLOR_PANEL_APAGADO := Color(0.281, 0.281, 0.281, 1.0)

@export var semilla := 1
@export_enum("Encendida", "Intermitente", "No funciona") var modo := MODO_ENCENDIDA

@onready var luz: Light3D = get_node_or_null("Foco")
@onready var rebote: OmniLight3D = get_node_or_null("ReboteLocal")
@onready var rebote_paredes: OmniLight3D = get_node_or_null("ReboteParedes")
@onready var panel: MeshInstance3D = get_node_or_null("PanelEmisor")
var _rng := RandomNumberGenerator.new()
var _reloj := 0.0
var _encendida := false
var _energia_objetivo := 0.0
var _emision_objetivo := 0.0
var _energia_actual := 0.0
var _emision_actual := 0.0

func _ready() -> void:
	_rng.seed = semilla
	_aplicar_modo()

func configurar_modo(nuevo_modo: int) -> void:
	modo = clampi(nuevo_modo, MODO_ENCENDIDA, MODO_AVERIADA)
	if is_node_ready():
		_aplicar_modo()
		var panel_desarrollo := get_node_or_null("/root/PanelDesarrollo")
		if panel_desarrollo != null and panel_desarrollo.has_method("actualizar_relleno_sala"):
			panel_desarrollo.call("actualizar_relleno_sala", get_parent())

func _aplicar_modo() -> void:
	set_process(modo == MODO_INTERMITENTE and luz != null)
	_encendida = false
	_reloj = 0.12
	_energia_objetivo = 0.0
	_emision_objetivo = 0.0
	_energia_actual = 0.0
	_emision_actual = 0.0
	if luz != null:
		luz.visible = modo != MODO_AVERIADA
		var base := float(luz.get_meta("energia_base", 3.2))
		luz.light_energy = base if modo == MODO_ENCENDIDA else 0.0
	if rebote != null:
		rebote.visible = modo != MODO_AVERIADA
		var energia_rebote := float(rebote.get_meta("energia_base", 0.045))
		rebote.light_energy = energia_rebote if modo == MODO_ENCENDIDA else 0.0
	if rebote_paredes != null:
		rebote_paredes.visible = modo != MODO_AVERIADA
		var energia_paredes := float(rebote_paredes.get_meta("energia_base", 0.07))
		rebote_paredes.light_energy = energia_paredes if modo == MODO_ENCENDIDA else 0.0
	if modo == MODO_INTERMITENTE:
		_actualizar_emision(0.0)
		_actualizar_color_panel(false)
	elif modo == MODO_AVERIADA:
		_actualizar_emision(0.0)
		_actualizar_color_panel(false)
	else:
		_actualizar_emision(EMISION_ENCENDIDA)
		_actualizar_color_panel(true)
	if luz != null:
		luz.set_meta("modo_luz", modo)
	if rebote != null:
		rebote.set_meta("modo_luz", modo)
	if rebote_paredes != null:
		rebote_paredes.set_meta("modo_luz", modo)
	if panel != null:
		panel.set_meta("modo_luz", modo)
	var panel_desarrollo := get_node_or_null("/root/PanelDesarrollo")
	if panel_desarrollo != null and panel_desarrollo.has_method("configurar_luminaria"):
		panel_desarrollo.call("configurar_luminaria", self)

func _process(delta: float) -> void:
	_reloj -= delta
	var velocidad_encender := VELOCIDAD_ENCENDIDO
	var velocidad_apagar := VELOCIDAD_APAGADO
	var encendida_min := 0.25
	var encendida_max := 0.9
	var apagada_min := 0.18
	var apagada_max := 0.55
	var variacion_minima := 0.72
	var emision_minima := 0.62
	var panel_desarrollo := get_node_or_null("/root/PanelDesarrollo")
	if panel_desarrollo != null:
		velocidad_encender = float(panel_desarrollo.get("velocidad_encendido"))
		velocidad_apagar = float(panel_desarrollo.get("velocidad_apagado"))
		encendida_min = float(panel_desarrollo.get("parpadeo_encendida_min"))
		encendida_max = float(panel_desarrollo.get("parpadeo_encendida_max"))
		apagada_min = float(panel_desarrollo.get("parpadeo_apagada_min"))
		apagada_max = float(panel_desarrollo.get("parpadeo_apagada_max"))
		variacion_minima = float(panel_desarrollo.get("variacion_luz_minima"))
		emision_minima = float(panel_desarrollo.get("emision_parpadeo_minima"))
	if _reloj <= 0.0:
		_encendida = not _encendida
		_reloj = _rng.randf_range(minf(apagada_min, apagada_max), maxf(apagada_min, apagada_max)) if not _encendida else _rng.randf_range(minf(encendida_min, encendida_max), maxf(encendida_min, encendida_max))
		var base := float(luz.get_meta("energia_base", 3.2))
		var factor := float(luz.get_meta("factor_desarrollo", 1.0))
		var variacion := _rng.randf_range(clampf(variacion_minima, 0.0, 1.0), 1.0) if _encendida else 0.0
		_energia_objetivo = base * factor * variacion
		var emision_maxima := EMISION_ENCENDIDA
		if panel_desarrollo != null:
			emision_maxima = float(panel_desarrollo.get("emision_panel"))
		_emision_objetivo = _rng.randf_range(emision_maxima * clampf(emision_minima, 0.0, 1.0), emision_maxima) if _encendida else 0.0
		_actualizar_color_panel(_encendida)
		if rebote != null:
			var base_rebote := float(rebote.get_meta("energia_base", 0.045))
			rebote.light_energy = base_rebote * factor * variacion
		if rebote_paredes != null:
			var base_paredes := float(rebote_paredes.get_meta("energia_base", 0.07))
			rebote_paredes.light_energy = base_paredes * factor * variacion
	# Sube suave y baja rápido, como un tubo que se enciende y se corta.
	var velocidad := velocidad_encender if _energia_objetivo > _energia_actual else velocidad_apagar
	var k := 1.0 - exp(-velocidad * delta)
	_energia_actual = lerpf(_energia_actual, _energia_objetivo, k)
	_emision_actual = lerpf(_emision_actual, _emision_objetivo, k)
	if _energia_actual < 0.01 and _energia_objetivo == 0.0:
		_energia_actual = 0.0
	if _emision_actual < 0.02 and _emision_objetivo == 0.0:
		_emision_actual = 0.0
	luz.light_energy = _energia_actual
	_actualizar_emision(_emision_actual)

func _actualizar_emision(intensidad: float) -> void:
	if panel == null:
		return
	var material := panel.material_override as StandardMaterial3D
	if material == null:
		return
	material.emission_enabled = intensidad > 0.0
	material.emission_energy_multiplier = intensidad
	var panel_desarrollo := get_node_or_null("/root/PanelDesarrollo")
	if panel_desarrollo != null:
		material.emission_energy_multiplier *= float(panel_desarrollo.get("emision_panel")) / EMISION_ENCENDIDA

func _actualizar_color_panel(funciona: bool) -> void:
	if panel == null:
		return
	var material := panel.material_override as StandardMaterial3D
	if material == null:
		return
	var gris := COLOR_PANEL_APAGADO.r
	if panel.has_meta("color_apagado"):
		gris = float(panel.get_meta("color_apagado"))
	material.albedo_color = COLOR_PANEL_ENCENDIDO if funciona else Color(gris, gris, gris)
