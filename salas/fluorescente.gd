extends Node3D
## Fallo intermitente de un panel fluorescente. La semilla queda ligada a la sala.

@export var semilla := 1
@export var intermitente := true

@onready var luz: OmniLight3D = get_node_or_null("OmniLight3D")
var _rng := RandomNumberGenerator.new()
var _reloj := 0.0
var _encendida := true

func _ready() -> void:
	_rng.seed = semilla
	if luz == null or not intermitente:
		set_process(false)

func _process(delta: float) -> void:
	_reloj -= delta
	if _reloj > 0.0:
		return
	_reloj = _rng.randf_range(0.035, 0.22)
	_encendida = not _encendida
	var base := float(luz.get_meta("energia_base", 0.9))
	var factor := float(luz.get_meta("factor_desarrollo", 1.0))
	luz.light_energy = base * factor * (_rng.randf_range(0.08, 0.3) if not _encendida else _rng.randf_range(0.48, 0.85))
