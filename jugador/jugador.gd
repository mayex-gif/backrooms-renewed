extends CharacterBody3D
## Controlador en primera persona adaptado del prototipo anterior.

@export var velocidad_caminar := 4.0
@export var velocidad_correr := 6.0
@export var velocidad_agachado := 2.0
@export var velocidad_arrastrarse := 0.8
@export var velocidad_sigilosa := 1.2
@export var velocidad_noclip := 12.0
@export var sensibilidad_mouse := 0.003
@export var altura_ojos := 1.55
@export var intervalo_parpadeo_min_s := 18.0
@export var intervalo_parpadeo_max_s := 40.0
@export var suavizado_linterna := 14.0
@export var distancia_convergencia_luz := 15.0

@onready var cabeza: Node3D = $Cabeza
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var modelo_jugador: Node3D = $ModeloJugador
@onready var conjunto_linterna: Node3D = $Cabeza/Camera3D/ConjuntoLinterna
@onready var modelo_linterna: Node3D = $Cabeza/Camera3D/ConjuntoLinterna/ModeloLinterna
@onready var linterna: SpotLight3D = $Cabeza/Camera3D/ConjuntoLinterna/LuzLinterna
@onready var timer_parpadeo: Timer = $TimerParpadeoLinterna

var animador_jugador: AnimationPlayer
var camara_jugador: Camera3D
var esqueleto_jugador: Skeleton3D
var materiales_lente: Array[StandardMaterial3D] = []
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var agachado := false
var arrastrandose := false
var modo_noclip := false
var linterna_encendida := true
var parpadeo_apagado := false
var transiciones_parpadeo_restantes := 0
var animacion_jugador_actual := ""
var altura_ojos_personaje := 1.55
var escala_personaje := 1.0
var _tiempo_balanceo := 0.0
var _pos_base_conjunto := Vector3(0.28, -0.22, -0.45)
var _rot_base_conjunto := Vector3(-PI / 2.0, 0.0, 0.0)
var _rot_base_modelo := Vector3.ZERO
var _log_anim_timer := 0.0
## Script que corrige la pose del esqueleto (mano con linterna, agachado, arrastrado).
var modificador_pose: SkeletonModifier3D
var mezcla_agachado := 0.0
var mezcla_tumbado := 0.0
var mezcla_linterna := 1.0
var intensidad_gateo := 0.0
var _ultima_anim_impresa := ""

var _pos_camara_base := Vector3(0.0, 0.0, -0.18)
var _tiempo_bobbing_camara := 0.0

## Luz ambiente baja: la iluminación la dan los paneles del techo, no el ambiente.
const ENERGIA_AMBIENTE := 0.025
const MenuPausaScript = preload("res://sistema/menu_pausa.gd")
const PosePersonajeScript = preload("res://jugador/pose_personaje.gd")
## En el GLB la linterna apunta por su eje +Y y mide 21 cm hasta el lente.
const LARGO_LINTERNA := 0.21
const VELOCIDAD_MEZCLA_POSTURA := 6.0
## Imprime el estado de la animación cada medio segundo (solo para depurar).
const DEPURAR_ANIMACION := false
const ALTURA_CAPSULA_PARADO := 1.8
const ALTURA_CAPSULA_AGACHADO := 1.0
const ALTURA_CAPSULA_ARRASTRADO := 0.65

func _ready() -> void:
	_configurar_controles()
	_configurar_ambiente()
	camara_jugador = $Cabeza/Camera3D as Camera3D
	_rot_base_modelo = modelo_jugador.rotation
	_cargar_modelo_seleccionado()
	_desactivar_animation_trees()
	animador_jugador = _buscar_animador_jugador()
	if animador_jugador != null:
		animador_jugador.process_mode = Node.PROCESS_MODE_INHERIT
		animador_jugador.active = true
		if is_zero_approx(animador_jugador.speed_scale):
			animador_jugador.speed_scale = 1.0
	_actualizar_escala_segun_personaje()
	_conectar_linterna_a_mano()
	_aplicar_ajustes()
	timer_parpadeo.timeout.connect(_iniciar_parpadeo_linterna)
	_preparar_materiales_lente()
	_actualizar_luz_linterna()
	_programar_parpadeo_linterna()
	_actualizar_animacion_jugador("idle")
	Ajustes.ajustes_cambiados.connect(_aplicar_ajustes)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _desactivar_animation_trees() -> void:
	var pendientes: Array[Node] = [modelo_jugador]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is AnimationTree:
			(nodo as AnimationTree).active = false
		for hijo in nodo.get_children():
			pendientes.append(hijo)

func _cargar_modelo_seleccionado() -> void:
	var ruta_modelo := "res://assets/modelos/casual/personaje_casual.glb"
	var selector := get_node_or_null("/root/SelectorPersonaje")
	if selector != null and selector.has_method("obtener_ruta_modelo"):
		ruta_modelo = String(selector.call("obtener_ruta_modelo"))
	var escena_modelo := load(ruta_modelo) as PackedScene
	if escena_modelo == null:
		push_warning("No se pudo cargar el personaje '%s'; se usará el modelo casual." % ruta_modelo)
		escena_modelo = load("res://assets/modelos/casual/personaje_casual.glb") as PackedScene
	if escena_modelo == null:
		push_error("Tampoco se pudo cargar el modelo casual de respaldo.")
		return
	for hijo in modelo_jugador.get_children():
		hijo.queue_free()
	var modelo := escena_modelo.instantiate()
	modelo.name = "MallaYRig"
	modelo_jugador.add_child(modelo)

func _actualizar_bobbing_camara(delta: float) -> void:
	if camara_jugador == null:
		return
	var vel_horiz := Vector2(velocity.x, velocity.z).length()
	var en_suelo := is_on_floor() and not modo_noclip
	var moviendose := en_suelo and vel_horiz > 0.15

	var objetivo_offset := Vector3.ZERO
	if moviendose:
		var corriendo := Input.is_action_pressed("correr") and not agachado and not arrastrandose
		var frecuencia := 13.5 if corriendo else (6.5 if arrastrandose else 9.0)
		var amp_y := (0.045 if corriendo else (0.015 if arrastrandose else 0.028)) * escala_personaje
		var amp_x := (0.028 if corriendo else (0.012 if arrastrandose else 0.018)) * escala_personaje
		_tiempo_bobbing_camara += delta * frecuencia
		objetivo_offset = Vector3(
			cos(_tiempo_bobbing_camara * 0.5) * amp_x,
			absf(sin(_tiempo_bobbing_camara)) * amp_y - amp_y * 0.5,
			0.0
		)
	else:
		_tiempo_bobbing_camara = move_toward(_tiempo_bobbing_camara, 0.0, delta * 4.0)

	var extra_z := 0.0
	if cabeza != null and cabeza.rotation.x > 0.0:
		extra_z = -0.06 * escala_personaje * clampf(cabeza.rotation.x / deg_to_rad(80.0), 0.0, 1.0)

	var destino := _pos_camara_base + objetivo_offset + Vector3(0.0, 0.0, extra_z)
	var suavizado := clampf(delta * 12.0, 0.0, 1.0)
	camara_jugador.position = camara_jugador.position.lerp(destino, suavizado)
	
func _actualizar_escala_segun_personaje() -> void:
	var esqueleto := _buscar_esqueleto_jugador()
	if esqueleto == null:
		altura_ojos_personaje = altura_ojos
		_pos_camara_base = Vector3(0.0, 0.03, -0.24)
		if camara_jugador != null:
			camara_jugador.position = _pos_camara_base
		return
	var ojos: Array[int] = []
	for nombre_hueso in ["LeftEye", "RightEye", "eye_l", "eye_r", "Eye_L", "Eye_R"]:
		var indice_ojo := esqueleto.find_bone(nombre_hueso)
		if indice_ojo >= 0 and not ojos.has(indice_ojo):
			ojos.append(indice_ojo)
	var posicion_ojos_mundo := Vector3.ZERO
	if not ojos.is_empty():
		for indice_ojo in ojos:
			var pose_ojo: Transform3D = esqueleto.global_transform * esqueleto.get_bone_global_rest(indice_ojo)
			posicion_ojos_mundo += pose_ojo.origin
		posicion_ojos_mundo /= float(ojos.size())
	else:
		var indice_cabeza := esqueleto.find_bone("head")
		if indice_cabeza < 0:
			indice_cabeza = esqueleto.find_bone("Head")
		if indice_cabeza < 0:
			altura_ojos_personaje = altura_ojos
			_pos_camara_base = Vector3(0.0, 0.03, -0.24)
			if camara_jugador != null:
				camara_jugador.position = _pos_camara_base
			return
		var pose_cabeza: Transform3D = esqueleto.global_transform * esqueleto.get_bone_global_rest(indice_cabeza)
		posicion_ojos_mundo = pose_cabeza.origin + pose_cabeza.basis * Vector3(0.0, 0.11, 0.0)
	var posicion_ojos_local: Vector3 = to_local(posicion_ojos_mundo)
	cabeza.position = posicion_ojos_local
	altura_ojos_personaje = clampf(posicion_ojos_local.y, 1.35, 2.1)
	escala_personaje = clampf(altura_ojos_personaje / maxf(altura_ojos, 0.01), 0.85, 1.3)
	_pos_camara_base = Vector3(0.0, 0.02 * escala_personaje, -0.24 * escala_personaje)
	if camara_jugador != null:
		camara_jugador.position = _pos_camara_base
	var forma := colision.shape as CapsuleShape3D
	if forma != null:
		forma.radius = 0.3 * escala_personaje
		forma.height = ALTURA_CAPSULA_PARADO * escala_personaje
		colision.position.y = forma.height * 0.5

func _process(delta: float) -> void:
	_actualizar_bobbing_camara(delta)
	_actualizar_apuntado_linterna(delta)

## Campo de visión y sombras elegidos por el jugador en Opciones.
func _aplicar_ajustes() -> void:
	if camara_jugador != null:
		camara_jugador.fov = Ajustes.campo_vision
	if linterna != null and "sombras" in Ajustes:
		linterna.shadow_enabled = Ajustes.sombras

func _configurar_ambiente() -> void:
	var world_environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		return
	var ambiente := world_environment.environment
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.0, 0.0, 0.0)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.45, 0.43, 0.38)
	ambiente.ambient_light_energy = ENERGIA_AMBIENTE
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.ssao_enabled = true
	ambiente.ssao_radius = 1.2
	ambiente.ssao_intensity = 1.4
	ambiente.ssil_enabled = Ajustes.rebote_pantalla
	ambiente.ssil_radius = 4.0
	ambiente.ssil_intensity = 1.0
	ambiente.sdfgi_enabled = false
	ambiente.sdfgi_cascades = 3
	ambiente.sdfgi_use_occlusion = true
	ambiente.glow_enabled = true
	ambiente.glow_intensity = 0.25
	ambiente.glow_strength = 0.45
	ambiente.fog_enabled = true
	# La niebla volumétrica casi no se ve con esta densidad y es cara con muchas luces.
	ambiente.volumetric_fog_enabled = false
	ambiente.fog_light_color = Color(0.012, 0.011, 0.008)
	ambiente.fog_density = 0.008
	ambiente.sdfgi_bounce_feedback = 0.0
	world_environment.add_to_group("entornos_juego")
	world_environment.set_meta("energia_ambiente_base", ENERGIA_AMBIENTE)

func _configurar_controles() -> void:
	var teclas := {
		"adelante": [KEY_W, KEY_UP],
		"atras": [KEY_S, KEY_DOWN],
		"izquierda": [KEY_A, KEY_LEFT],
		"derecha": [KEY_D, KEY_RIGHT],
		"correr": [KEY_CTRL],
		"caminar_sigiloso": [KEY_SHIFT],
		"agachar": [KEY_C],
		"arrastrarse": [KEY_Z],
		"linterna": [KEY_F]
	}
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
		_actualizar_postura_modelo(delta)
		_actualizar_animacion_jugador("idle")
		_log_estado_animacion(delta)
		return
	if Input.is_action_just_pressed("agachar"):
		if arrastrandose:
			if _hay_espacio_para_pararse():
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
	if shape != null:
		var alto := ALTURA_CAPSULA_ARRASTRADO * escala_personaje if arrastrandose else ALTURA_CAPSULA_AGACHADO * escala_personaje if agachado else ALTURA_CAPSULA_PARADO * escala_personaje
		shape.height = move_toward(shape.height, alto, 4.0 * delta)
		colision.position.y = shape.height * 0.5
	var altura_cabeza := 0.30 * escala_personaje if arrastrandose else 0.95 * escala_personaje if agachado else altura_ojos_personaje
	cabeza.position.y = move_toward(cabeza.position.y, altura_cabeza, 4.0 * delta)
	if not is_on_floor():
		velocity.y -= gravedad * delta
	var entrada := Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var tiene_input := entrada.length_squared() > 0.01
	var corriendo := Input.is_action_pressed("correr") and not agachado and not arrastrandose
	var velocidad := velocidad_arrastrarse if arrastrandose else velocidad_agachado if agachado else velocidad_sigilosa if Input.is_action_pressed("caminar_sigiloso") else velocidad_correr if corriendo else velocidad_caminar
	var direccion := (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()
	velocity.x = direccion.x * velocidad if direccion else move_toward(velocity.x, 0.0, velocidad * 8.0 * delta)
	velocity.z = direccion.z * velocidad if direccion else move_toward(velocity.z, 0.0, velocidad * 8.0 * delta)
	move_and_slide()
	_actualizar_postura_modelo(delta)
	var vel_horiz := Vector2(velocity.x, velocity.z).length()
	var moviendose := tiene_input or vel_horiz > 0.15
	var animacion := "idle"
	if arrastrandose:
		animacion = "crawl_idle" if not moviendose else "crawl_forward"
	elif agachado:
		animacion = "crouch_idle" if not moviendose else "crouch_walk"
	elif moviendose:
		animacion = "run" if corriendo else "walk"
	_actualizar_animacion_jugador(animacion)
	_actualizar_pose(delta, moviendose and tiene_input, vel_horiz)
	_log_estado_animacion(delta)

## Metros por segundo que recorre el cuerpo con la animación a velocidad 1 (medido en los
## clips). Con speed_scale = velocidad real / este valor, el pie apoyado no patina.
## Si bajás velocidad_caminar / velocidad_correr, la animación se enlentece sola.
func _velocidad_natural_animacion(correr: bool) -> float:
	var guardia := false
	if modificador_pose != null:
		guardia = bool(modificador_pose.get("es_mixamo"))
	if guardia:
		return 3.95 if correr else 1.65
	return 3.6 if correr else 1.06


## Mezcla las posturas y se las pasa a pose_personaje.gd; además ajusta la velocidad
## de la animación a la velocidad real para que los pies no patinen.
func _actualizar_pose(delta: float, moviendose: bool, vel_horiz: float) -> void:
	if animador_jugador != null:
		var corriendo_anim := animacion_jugador_actual.to_lower().ends_with("run")
		var natural := _velocidad_natural_animacion(corriendo_anim)
		var escala := clampf(vel_horiz / natural, 0.3, 3.0) if moviendose else 1.0
		animador_jugador.speed_scale = escala
	var paso := VELOCIDAD_MEZCLA_POSTURA * delta
	mezcla_agachado = move_toward(mezcla_agachado, 1.0 if agachado else 0.0, paso)
	mezcla_tumbado = move_toward(mezcla_tumbado, 1.0 if arrastrandose else 0.0, paso)
	mezcla_linterna = move_toward(mezcla_linterna, 1.0 if linterna_encendida else 0.0, 4.0 * delta)
	intensidad_gateo = move_toward(intensidad_gateo, 1.0 if (moviendose and arrastrandose) else 0.0, 5.0 * delta)
	if modificador_pose == null:
		return
	modificador_pose.set("mezcla_agachado", mezcla_agachado)
	modificador_pose.set("mezcla_tumbado", mezcla_tumbado)
	modificador_pose.set("mezcla_linterna", mezcla_linterna)
	modificador_pose.set("intensidad_gateo", intensidad_gateo)
	if arrastrandose:
		modificador_pose.set("fase_gateo", float(modificador_pose.get("fase_gateo")) + delta * vel_horiz * 6.0)

func _log_estado_animacion(delta: float) -> void:
	if not DEPURAR_ANIMACION or animador_jugador == null:
		return
	_log_anim_timer += delta
	var actual := String(animador_jugador.current_animation)
	if actual != _ultima_anim_impresa or _log_anim_timer >= 0.5:
		_log_anim_timer = 0.0
		_ultima_anim_impresa = actual
		var pos := animador_jugador.current_animation_position if not actual.is_empty() else 0.0
		var largo := animador_jugador.current_animation_length if not actual.is_empty() else 0.0
		print(
			"[Anim] clip='%s' | pos=%.2f / %.2f | playing=%s | active=%s | vel=%.2f" % [
				actual,
				pos,
				largo,
				str(animador_jugador.is_playing()),
				str(animador_jugador.active),
				Vector2(velocity.x, velocity.z).length()
			]
		)

func _actualizar_postura_modelo(delta: float) -> void:
	if modelo_jugador == null:
		return
	var inclinacion_x := 0.0
	var desfase_y := 0.0
	# Con la pose real (pose_personaje.gd) el modelo no se inclina entero.
	if modificador_pose == null and arrastrandose:
		inclinacion_x = deg_to_rad(-65.0)
		desfase_y = -0.35 * escala_personaje
	elif modificador_pose == null and agachado:
		inclinacion_x = deg_to_rad(-18.0)
		desfase_y = -0.22 * escala_personaje
	var rot_objetivo := _rot_base_modelo + Vector3(inclinacion_x, 0.0, 0.0)
	modelo_jugador.rotation.x = lerp_angle(modelo_jugador.rotation.x, rot_objetivo.x, clampf(delta * 10.0, 0.0, 1.0))
	modelo_jugador.position.y = lerpf(modelo_jugador.position.y, desfase_y, clampf(delta * 10.0, 0.0, 1.0))

func _buscar_animador_jugador() -> AnimationPlayer:
	var pendientes: Array[Node] = [modelo_jugador]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is AnimationPlayer:
			return nodo as AnimationPlayer
		for hijo in nodo.get_children():
			pendientes.append(hijo)
	return null

func _conectar_linterna_a_mano() -> void:
	esqueleto_jugador = _buscar_esqueleto_jugador()
	if conjunto_linterna == null or camara_jugador == null:
		return
	if esqueleto_jugador != null:
		var pose := PosePersonajeScript.new()
		pose.name = "PosePersonaje"
		esqueleto_jugador.add_child(pose)
		if pose.preparar(esqueleto_jugador, altura_ojos_personaje):
			pose.camara = camara_jugador
			pose.cabeza_camara = cabeza
			pose.conjunto_linterna = conjunto_linterna
			# La posición y el apuntado de la linterna los fija el script de pose en
			# cada cuadro (mano derecha). Convención: el conjunto mira hacia -Z.
			conjunto_linterna.reparent(self)
			modelo_linterna.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO)
			linterna.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -(LARGO_LINTERNA + 0.01)))
			_quitar_sombra(modelo_linterna)
			modificador_pose = pose
			# Sin cabeza visible la cámara puede ir más cerca, y la mano entra en pantalla.
			_pos_camara_base = Vector3(0.0, 0.0, -0.08)
			return
		pose.queue_free()
	push_warning("No se pudo preparar la mano del personaje; la linterna queda montada a la cámara.")
	if conjunto_linterna.get_parent() != camara_jugador:
		conjunto_linterna.reparent(camara_jugador)
	_pos_base_conjunto = conjunto_linterna.position
	_rot_base_conjunto = conjunto_linterna.rotation

## La linterna no debe proyectar su propia sombra (taparía la luz del lente).
func _quitar_sombra(nodo: Node) -> void:
	if nodo is GeometryInstance3D:
		(nodo as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for hijo in nodo.get_children():
		_quitar_sombra(hijo)

func _actualizar_apuntado_linterna(delta: float) -> void:
	if camara_jugador == null or linterna == null or conjunto_linterna == null:
		return
	if modificador_pose != null:
		# La mano ya sigue a la cámara; solo se converge el haz de luz.
		_apuntar_haz_linterna(delta)
		return
	var vel_horiz := Vector2(velocity.x, velocity.z).length()
	var corriendo := Input.is_action_pressed("correr") and not agachado and not arrastrandose
	var ritmo := (5.5 + vel_horiz * 1.5) if (vel_horiz > 0.15 and is_on_floor()) else 1.5
	var amplitud := (0.012 if corriendo else 0.007) if (vel_horiz > 0.15 and is_on_floor()) else 0.0025
	_tiempo_balanceo += delta * ritmo

	var offset_balanceo := Vector3(
		cos(_tiempo_balanceo * 0.5) * amplitud * 0.8,
		sin(_tiempo_balanceo) * amplitud,
		0.0
	)
	var t := clampf(delta * suavizado_linterna, 0.0, 1.0)
	conjunto_linterna.position = conjunto_linterna.position.lerp(_pos_base_conjunto + offset_balanceo, t)

	var rot_objetivo := _rot_base_conjunto + Vector3(
		sin(_tiempo_balanceo) * amplitud * 1.8,
		cos(_tiempo_balanceo * 0.5) * amplitud * 1.4,
		0.0
	)
	var q_actual := conjunto_linterna.quaternion
	var q_objetivo := Quaternion.from_euler(rot_objetivo)
	conjunto_linterna.quaternion = q_actual.slerp(q_objetivo, t)

	_apuntar_haz_linterna(delta)

## El haz converge hacia el punto que mira la cámara, con un pequeño retraso suave.
func _apuntar_haz_linterna(delta: float) -> void:
	var punto_mira: Vector3 = camara_jugador.global_position + (-camara_jugador.global_basis.z * distancia_convergencia_luz)
	if linterna.global_position.distance_squared_to(punto_mira) > 0.0001:
		var t_look := linterna.global_transform.looking_at(punto_mira, Vector3.UP)
		linterna.global_basis = linterna.global_basis.orthonormalized().slerp(t_look.basis.orthonormalized(), clampf(delta * (suavizado_linterna * 1.5), 0.0, 1.0))

func _buscar_esqueleto_jugador() -> Skeleton3D:
	var pendientes: Array[Node] = [modelo_jugador]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		if nodo is Skeleton3D:
			return nodo as Skeleton3D
		for hijo in nodo.get_children():
			pendientes.append(hijo)
	return null

func _actualizar_animacion_jugador(nombre: String) -> void:
	if animador_jugador == null or not animador_jugador.is_inside_tree():
		print("[AnimDebug] animador nulo o fuera del árbol para '%s'" % nombre)
		return
	var nombre_animacion := _resolver_nombre_animacion(nombre)
	if nombre_animacion.is_empty():
		print("[AnimDebug] sin resolver para '%s' (lista: %s)" % [nombre, str(animador_jugador.get_animation_list())])
		return
	var clip := animador_jugador.get_animation(nombre_animacion)
	if clip != null:
		clip.loop_mode = Animation.LOOP_LINEAR
	animador_jugador.active = true
	if nombre_animacion != animacion_jugador_actual or animador_jugador.current_animation != nombre_animacion or not animador_jugador.is_playing():
		animador_jugador.play(nombre_animacion)
		animacion_jugador_actual = nombre_animacion
		if animador_jugador.current_animation.is_empty():
			print("[AnimFail] pedí='%s' -> elegido='%s' | has=%s | playing=%s | id=%s" % [
				nombre,
				nombre_animacion,
				str(animador_jugador.has_animation(nombre_animacion)),
				str(animador_jugador.is_playing()),
				str(animador_jugador.get_instance_id())
			])

func _resolver_nombre_animacion(nombre: String) -> String:
	if animador_jugador == null:
		return ""
	var objetivo := nombre.to_lower().strip_edges()
	match objetivo:
		"crouch_walk":
			objetivo = "walk"
		"crawl_forward":
			# Arrastrarse: el movimiento de piernas y brazo lo hace pose_personaje.gd.
			objetivo = "idle" if modificador_pose != null else "walk"
		"crouch_idle", "crawl_idle":
			objetivo = "idle"
	var lista := animador_jugador.get_animation_list()
	for anim in lista:
		var s := String(anim)
		if s.to_lower() == objetivo or s.get_slice("/", -1).to_lower() == objetivo:
			return s
	for anim in lista:
		var s := String(anim)
		if s.to_lower() == "idle" or s.get_slice("/", -1).to_lower() == "idle":
			return s
	return String(lista[0]) if not lista.is_empty() else ""

func _normalizar_nombre_animacion(nombre: String) -> String:
	var limpio := nombre.to_lower().strip_edges()
	for sep in [" ", "-", "–", "—", "|"]:
		limpio = limpio.replace(sep, "_")
	while limpio.contains("__"):
		limpio = limpio.replace("__", "_")
	return limpio.trim_prefix("_").trim_suffix("_")

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
	forma.height = ALTURA_CAPSULA_PARADO * escala_personaje
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = forma
	query.transform = global_transform * Transform3D(Basis.IDENTITY, Vector3.UP * forma.height * 0.5)
	query.margin = 0.0
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
