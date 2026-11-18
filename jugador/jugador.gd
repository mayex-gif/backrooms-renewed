extends CharacterBody3D
## Controlador en primera persona adaptado del prototipo anterior.

@export var velocidad_caminar := 4.0
@export var velocidad_correr := 6.0
@export var velocidad_agachado := 2.0
@export var sensibilidad_mouse := 0.003
@export var altura_ojos := 1.55

@onready var cabeza: Node3D = $Cabeza
@onready var colision: CollisionShape3D = $CollisionShape3D
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var agachado := false

func _ready() -> void:
	_configurar_controles()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _configurar_controles() -> void:
	var teclas := {"adelante": [KEY_W, KEY_UP], "atras": [KEY_S, KEY_DOWN], "izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT], "correr": [KEY_SHIFT], "agachar": [KEY_C]}
	for accion in teclas:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for codigo in teclas[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = codigo
			InputMap.action_add_event(accion, evento)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse)
		cabeza.rotation.x = clampf(cabeza.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("agachar"):
		agachado = not agachado
	var shape := colision.shape as CapsuleShape3D
	var alto := 1.0 if agachado else 1.8
	shape.height = move_toward(shape.height, alto, 4.0 * delta)
	colision.position.y = shape.height * 0.5
	cabeza.position.y = move_toward(cabeza.position.y, 1.0 if agachado else altura_ojos, 4.0 * delta)
	if not is_on_floor():
		velocity.y -= gravedad * delta
	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var velocidad := velocidad_agachado if agachado else velocidad_correr if Input.is_action_pressed("correr") else velocidad_caminar
	var direccion := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
	velocity.x = direccion.x * velocidad if direccion else move_toward(velocity.x, 0.0, velocidad * 8.0 * delta)
	velocity.z = direccion.z * velocidad if direccion else move_toward(velocity.z, 0.0, velocidad * 8.0 * delta)
	move_and_slide()
