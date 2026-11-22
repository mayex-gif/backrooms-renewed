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
@export var intervalo_parpadeo_min_s := 18.0
@export var intervalo_parpadeo_max_s := 40.0

@onready var cabeza: Node3D = $Cabeza
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var conjunto_linterna: Node3D = $Cabeza/Camera3D/ConjuntoLinterna
@onready var modelo_linterna: Node3D = $Cabeza/Camera3D/ConjuntoLinterna/ModeloLinterna
@onready var linterna: SpotLight3D = $Cabeza/Camera3D/ConjuntoLinterna/LuzLinterna
@onready var timer_parpadeo: Timer = $TimerParpadeoLinterna
@onready var animador_jugador: AnimationPlayer = _buscar_animador_jugador()
var materiales_lente: Array[StandardMaterial3D] = []
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var agachado := false
var arrastrandose := false
var modo_noclip := false
var linterna_encendida := true
var parpadeo_apagado := false
var transiciones_parpadeo_restantes := 0
var animacion_jugador_actual := ""
## Luz ambiente baja: la iluminación la dan los paneles del techo, no el ambiente.
const ENERGIA_AMBIENTE := 0.025
const MenuPausaScript = preload("res://sistema/menu_pausa.gd")
const ALTURA_CAPSULA_PARADO := 1.8
const ALTURA_CAPSULA_AGACHADO := 1.0
const ALTURA_CAPSULA_ARRASTRADO := 0.65

func _ready() -> void:
	_configurar_controles()
	_configurar_ambiente()
	_aplicar_ajustes()
	_conectar_linterna_a_mano()
	timer_parpadeo.timeout.connect(_iniciar_parpadeo_linterna)
	_preparar_materiales_lente()
	_actualizar_luz_linterna()
	_programar_parpadeo_linterna()
	_actualizar_animacion_jugador("idle")
	Ajustes.ajustes_cambiados.connect(_aplicar_ajustes)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Campo de visión elegido por el jugador en Opciones.
func _aplicar_ajustes() -> void:
	var camara := get_node_or_null("Cabeza/Camera3D") as Camera3D
	if camara != null:
		camara.fov = Ajustes.campo_vision

func _configurar_ambiente() -> void:
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		return
	var ambiente := world_environment.environment
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.035, 0.033, 0.027)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.5, 0.5, 0.46)
	ambiente.ambient_light_energy = ENERGIA_AMBIENTE
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.ssao_enabled = true
	ambiente.ssao_radius = 1.2
	ambiente.ssao_intensity = 1.4
	# Rebote en pantalla: estable, sin horneado y sin recalcular al mover luces.
	ambiente.ssil_enabled = Ajustes.rebote_pantalla
	ambiente.ssil_radius = 4.0
	ambiente.ssil_intensity = 1.0
	ambiente.sdfgi_enabled = false
	ambiente.sdfgi_cascades = 3
	ambiente.sdfgi_use_occlusion = true
	ambiente.glow_enabled = true
	ambiente.glow_intensity = 0.35
	ambiente.glow_strength = 0.45
	# Niebla leve y oscura: da profundidad a los pasillos largos sin esconder las salas.
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.1, 0.095, 0.075)
	ambiente.fog_density = 0.008
	ambiente.sdfgi_bounce_feedback = 0.0
	world_environment.add_to_group("entornos_juego")
	world_environment.set_meta("energia_ambiente_base", ENERGIA_AMBIENTE)

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
		linterna_encendida = not linterna_encendida
		_actualizar_luz_linterna()
	elif OS.is_debug_build() and event.is_action_pressed("alternar_noclip"):
		modo_noclip = not modo_noclip
		colision.set_deferred("disabled", modo_noclip)
		velocity = Vector3.ZERO
		print("No-clip %s (WASD/mouse, E subir, Q bajar)" % ("ACTIVADO" if modo_noclip else "DESACTIVADO"))
	elif event.is_action_pressed("ui_cancel"):
		_mostrar_dialogo_salida()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse * Ajustes.sensibilidad)
		cabeza.rotate_x(-event.relative.y * sensibilidad_mouse * Ajustes.sensibilidad)
		cabeza.rotation.x = clampf(cabeza.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _mostrar_dialogo_salida() -> void:
	var escena := get_tree().current_scene
	if escena == null or escena.get_node_or_null("MenuPausa") != null:
		return
	var menu := MenuPausaScript.new()
	menu.name = "MenuPausa"
	escena.add_child(menu)

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
		_actualizar_animacion_jugador("idle")
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
	var moviendose := entrada.length_squared() > 0.01 and Vector2(velocity.x, velocity.z).length_squared() > 0.01
	var animacion := "idle"
	if arrastrandose:
		animacion = "crawl_idle" if not moviendose else "crawl_forward"
	elif agachado:
		animacion = "crouch_idle" if not moviendose else "crouch_walk"
	elif moviendose:
		animacion = "run" if Input.is_action_pressed("correr") else "walk"
	_actualizar_animacion_jugador(animacion)

func _buscar_animador_jugador() -> AnimationPlayer:
	var pendientes: Array[Node] = [$ModeloJugador]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is AnimationPlayer:
			return nodo as AnimationPlayer
		for hijo in nodo.get_children():
			pendientes.append(hijo)
	return null

func _conectar_linterna_a_mano() -> void:
	var esqueleto := _buscar_esqueleto_jugador()
	if esqueleto == null or esqueleto.find_bone("hand_r") < 0:
		push_warning("No se encontró el hueso hand_r; la linterna queda montada a la cámara.")
		return
	var sujecion := BoneAttachment3D.new()
	sujecion.name = "SujecionLinterna"
	sujecion.bone_name = "hand_r"
	esqueleto.add_child(sujecion)
	conjunto_linterna.reparent(sujecion)
	# En el GLB la linterna apunta por su eje +Y; este giro orienta el lente
	# hacia el frente (-Z) y conserva la luz junto al modelo en la mano derecha.
	conjunto_linterna.transform = Transform3D(Basis.from_euler(Vector3(-PI / 2.0, 0.0, 0.0)), Vector3(0.0, -0.07, 0.035))

func _buscar_esqueleto_jugador() -> Skeleton3D:
	var pendientes: Array[Node] = [$ModeloJugador]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is Skeleton3D:
			return nodo as Skeleton3D
		for hijo in nodo.get_children():
			pendientes.append(hijo)
	return null

func _actualizar_animacion_jugador(nombre: String) -> void:
	if animador_jugador == null:
		return
	var nombre_animacion := _resolver_nombre_animacion(nombre)
	# Este personaje no trae ciclos de agachado ni de gateo. Si se incorpora
	# luego un clip compatible, se seleccionará; mientras tanto usamos locomoción
	# disponible para que el cuerpo no se congele al moverse en esas posturas.
	if nombre_animacion.is_empty() and nombre.begins_with("crawl_"):
		nombre_animacion = _resolver_nombre_animacion("idle" if nombre.ends_with("idle") else "walk")
	if nombre_animacion.is_empty() and nombre.begins_with("crouch_"):
		nombre_animacion = _resolver_nombre_animacion("walk" if nombre.ends_with("walk") else "idle")
	if nombre_animacion.is_empty():
		nombre_animacion = _resolver_nombre_animacion("idle")
	if nombre_animacion.is_empty() or nombre_animacion == animacion_jugador_actual:
		return
	animacion_jugador_actual = nombre_animacion
	var clip := animador_jugador.get_animation(nombre_animacion)
	if clip != null:
		clip.loop_mode = Animation.LOOP_LINEAR
	animador_jugador.play(nombre_animacion, 0.18)

func _resolver_nombre_animacion(nombre: String) -> String:
	var candidatos := [nombre, "default_library/" + nombre]
	for candidato in candidatos:
		if animador_jugador.has_animation(candidato):
			return candidato
	for disponible in animador_jugador.get_animation_list():
		var final_nombre := String(disponible).get_slice("/", -1).to_lower()
		if final_nombre == nombre.to_lower():
			return disponible
	return ""

func _programar_parpadeo_linterna() -> void:
	var espera_minima := maxf(1.0, minf(intervalo_parpadeo_min_s, intervalo_parpadeo_max_s))
	var espera_maxima := maxf(espera_minima, maxf(intervalo_parpadeo_min_s, intervalo_parpadeo_max_s))
	timer_parpadeo.start(randf_range(espera_minima, espera_maxima))

func _iniciar_parpadeo_linterna() -> void:
	if not linterna_encendida:
		_programar_parpadeo_linterna()
		return
	transiciones_parpadeo_restantes = randi_range(4, 8)
	_alternar_parpadeo_linterna()

func _alternar_parpadeo_linterna() -> void:
	parpadeo_apagado = not parpadeo_apagado
	transiciones_parpadeo_restantes -= 1
	_actualizar_luz_linterna()
	if transiciones_parpadeo_restantes > 0:
		timer_parpadeo.start(randf_range(0.045, 0.12))
		return
	parpadeo_apagado = false
	_actualizar_luz_linterna()
	_programar_parpadeo_linterna()

func _preparar_materiales_lente() -> void:
	_recopilar_materiales_lente(modelo_linterna)

func _recopilar_materiales_lente(nodo: Node) -> void:
	if nodo is MeshInstance3D:
		var malla := nodo as MeshInstance3D
		if malla.mesh != null:
			for superficie in malla.mesh.get_surface_count():
				var material := malla.get_active_material(superficie) as StandardMaterial3D
				if material == null or not material.emission_enabled:
					continue
				var copia := material.duplicate() as StandardMaterial3D
				malla.set_surface_override_material(superficie, copia)
				materiales_lente.append(copia)
	for hijo in nodo.get_children():
		_recopilar_materiales_lente(hijo)

func _actualizar_luz_linterna() -> void:
	var visible := linterna_encendida and not parpadeo_apagado
	linterna.visible = visible
	for material in materiales_lente:
		material.emission_energy_multiplier = 1.0 if visible else 0.0

func _panel_desarrollo_abierto() -> bool:
	# El menú de pausa también detiene al jugador y a la cámara.
	if not get_tree().get_nodes_in_group("menu_pausa").is_empty():
		return true
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
