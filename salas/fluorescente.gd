extends Node3D
## Fallo intermitente de un panel fluorescente. La semilla queda ligada a la sala.

@export var semilla := 1
@export var intermitente := true

@onready var luz: Light3D = get_node_or_null("Foco")
@onready var panel: MeshInstance3D = get_node_or_null("PanelEmisor")
var _rng := RandomNumberGenerator.new()
var _reloj := 0.0
var _encendida := false

func _ready() -> void:
	_rng.seed = semilla
	if luz == null or not intermitente:
		set_process(false)
		return
	_reloj = 0.12
	luz.light_energy = 0.0
	_actualizar_emision(0.0)

func _process(delta: float) -> void:
	_reloj -= delta
	if _reloj > 0.0:
		return
	_encendida = not _encendida
	_reloj = _rng.randf_range(0.18, 0.55) if not _encendida else _rng.randf_range(0.25, 0.9)
	var base := float(luz.get_meta("energia_base", 0.9))
	var factor := float(luz.get_meta("factor_desarrollo", 1.0))
	luz.light_energy = base * factor * _rng.randf_range(0.72, 1.0) if _encendida else 0.0
	_actualizar_emision(_rng.randf_range(1.0, 1.6) if _encendida else 0.0)

func _actualizar_emision(intensidad: float) -> void:
	if panel == null:
		return
	var material := panel.material_override as StandardMaterial3D
	if material == null:
		return
	material.emission_enabled = intensidad > 0.0
	material.emission_energy_multiplier = intensidad
