extends CharacterBody3D
## Controlador en primera persona adaptado del prototipo anterior.

@export var velocidad_caminar := 4.0
@export var velocidad_correr := 6.0
@export var velocidad_agachado := 2.0
@export var velocidad_arrastrarse := 0.8
@export var velocidad_sigilosa := 1.2
@export var velocidad_correr_sprint := 6.0
@export var velocidad_noclip := 12.0
@export var sensibilidad_mouse := 0.003
@export var altura_ojos := 1.55

@onready var cabeza: Node3D = $Cabeza
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var linterna: SpotLight3D = $Cabeza/LuzLinterna
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var agachado := false
var arrastrandose := false
var modo_noclip := false
const ALTURA_CAPSULA_PARADO := 1.8
const ALTURA_CAPSULA_AGACHADO := 1.0
const ALTURA_CAPSULA_ARRASTRADO := 0.65

func _ready() -> void:
	_configurar_controles()
	_configurar_ambiente()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _configurar_ambiente() -> void:
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		return
	var ambiente := world_environment.environment
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.035, 0.033, 0.027)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.55, 0.55, 0.55)
	ambiente.ambient_light_energy = 0.32
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.ssao_enabled = true
	ambiente.ssao_radius = 1.2
	ambiente.ssao_intensity = 1.4
	ambiente.ssil_enabled = true
	ambiente.ssil_radius = 5.0
	ambiente.ssil_intensity = 0.7
	ambiente.sdfgi_enabled = true
	ambiente.sdfgi_cascades = 3
	ambiente.sdfgi_use_occlusion = true
	ambiente.glow_enabled = true
	ambiente.glow_intensity = 0.35
	ambiente.glow_strength = 0.45
	world_environment.add_to_group("entornos_juego")
	world_environment.set_meta("energia_ambiente_base", 0.32)

func _configurar_controles() -> void:
	var teclas := {"adelante": [KEY_W, KEY_UP], "atras": [KEY_S, KEY_DOWN], "izquierda": [KEY_A, KEY_LEFT], "derecha": [KEY_D, KEY_RIGHT], "correr": [KEY_CTRL], "caminar_sigiloso": [KEY_SHIFT], "agachar": [KEY_C], "arrastrarse": [KEY_Z], "linterna": [KEY_F]}
	if OS.is_debug_build():
		teclas["alternar_noclip"] = [KEY_F3]
		teclas["noclip_subir"] = [KEY_E]
		teclas["noclip_bajar"] = [KEY_Q]
	for accion in teclas:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for codigo in teclas[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = codigo
			if not InputMap.action_has_event(accion, evento):
				InputMap.action_add_event(accion, evento)

func _input(event: InputEvent) -> void:
	if _panel_desarrollo_abierto():
		return
	if event.is_action_pressed("linterna"):
		linterna.visible = not linterna.visible
	elif OS.is_debug_build() and event.is_action_pressed("alternar_noclip"):
		modo_noclip = not modo_noclip
		colision.set_deferred("disabled", modo_noclip)
		velocity = Vector3.ZERO
		print("No-clip %s (WASD/mouse, E subir, Q bajar)" % ("ACTIVADO" if modo_noclip else "DESACTIVADO"))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse)
		cabeza.rotation.x = clampf(cabeza.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	if _panel_desarrollo_abierto():
		velocity = Vector3.ZERO
		return
	if modo_noclip:
		var entrada_libre := Input.get_vector("izquierda", "derecha", "adelante", "atras")
		var movimiento_libre := cabeza.global_basis * Vector3(entrada_libre.x, 0.0, entrada_libre.y)
		movimiento_libre += Vector3.UP * (1.0 if Input.is_action_pressed("noclip_subir") else 0.0)
		movimiento_libre -= Vector3.UP * (1.0 if Input.is_action_pressed("noclip_bajar") else 0.0)
		if movimiento_libre.length_squared() > 1.0:
			movimiento_libre = movimiento_libre.normalized()
		global_position += movimiento_libre * velocidad_noclip * delta
		velocity = Vector3.ZERO
		return
	if Input.is_action_just_pressed("agachar"):
		if arrastrandose:
			arrastrandose = false
			agachado = true
		elif agachado:
			if _hay_espacio_para_pararse():
				agachado = false
		else:
			agachado = true
	if Input.is_action_just_pressed("arrastrarse"):
		if arrastrandose:
			if _hay_espacio_para_pararse():
				arrastrandose = false
				agachado = false
		else:
			arrastrandose = true
			agachado = false
	var shape := colision.shape as CapsuleShape3D
	var alto := ALTURA_CAPSULA_ARRASTRADO if arrastrandose else ALTURA_CAPSULA_AGACHADO if agachado else ALTURA_CAPSULA_PARADO
	shape.height = move_toward(shape.height, alto, 4.0 * delta)
	colision.position.y = shape.height * 0.5
	var altura_cabeza := 0.48 if arrastrandose else 1.0 if agachado else altura_ojos
	cabeza.position.y = move_toward(cabeza.position.y, altura_cabeza, 4.0 * delta)
	if not is_on_floor():
		velocity.y -= gravedad * delta
	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var velocidad := velocidad_arrastrarse if arrastrandose else velocidad_agachado if agachado else velocidad_sigilosa if Input.is_action_pressed("caminar_sigiloso") else velocidad_correr_sprint if Input.is_action_pressed("correr") else velocidad_caminar
	var direccion := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
	velocity.x = direccion.x * velocidad if direccion else move_toward(velocity.x, 0.0, velocidad * 8.0 * delta)
	velocity.z = direccion.z * velocidad if direccion else move_toward(velocity.z, 0.0, velocidad * 8.0 * delta)
	move_and_slide()

func _panel_desarrollo_abierto() -> bool:
	for panel in get_tree().get_nodes_in_group("panel_desarrollo"):
		if panel.has_method("esta_abierto") and panel.call("esta_abierto"):
			return true
	return false

func _hay_espacio_para_pararse() -> bool:
	var forma := CapsuleShape3D.new()
	forma.radius = (colision.shape as CapsuleShape3D).radius
	forma.height = ALTURA_CAPSULA_PARADO
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = forma
	query.transform = global_transform * Transform3D(Basis.IDENTITY, Vector3.UP * ALTURA_CAPSULA_PARADO * 0.5)
	query.margin = 0.0
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
