extends Node3D
## Escena de prueba del personaje, vista desde afuera.
##   V         alterna tercera persona / primera persona
##   Rueda     acerca o aleja la cámara (tercera persona)
##   1 / 2     cambia de personaje (casual / guardia) y reinicia la escena
##   WASD, mouse, C (agacharse), Z (arrastrarse), F (linterna), Ctrl (correr): como en el juego.
## Sirve para revisar poses y animaciones; mandá una captura si algo se ve mal.

const JugadorEscena = preload("res://jugador/jugador.tscn")

var jugador: CharacterBody3D
var camara_externa: Camera3D
var tercera_persona := true
var distancia := 2.6
var etiqueta: Label

func _ready() -> void:
	var suelo := StaticBody3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(60.0, 0.2, 60.0)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	colision.position.y = -0.1
	suelo.add_child(colision)
	var malla := BoxMesh.new()
	malla.size = forma.size
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	visual.position.y = -0.1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.4, 0.28)
	visual.material_override = material
	suelo.add_child(visual)
	add_child(suelo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sol.light_energy = 0.9
	sol.shadow_enabled = true
	add_child(sol)
	var pared := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(6.0, 3.0, 0.3)
	pared.mesh = caja
	pared.position = Vector3(0.0, 1.5, -6.0)
	add_child(pared)
	jugador = JugadorEscena.instantiate()
	jugador.position = Vector3(0.0, 0.05, 0.0)
	add_child(jugador)
	camara_externa = Camera3D.new()
	add_child(camara_externa)
	var capa := CanvasLayer.new()
	etiqueta = Label.new()
	etiqueta.position = Vector2(16.0, 12.0)
	capa.add_child(etiqueta)
	add_child(capa)
	_aplicar_vista()

func _input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_V:
		tercera_persona = not tercera_persona
		_aplicar_vista()
	elif evento is InputEventKey and evento.pressed and not evento.echo and (evento.physical_keycode == KEY_1 or evento.physical_keycode == KEY_2):
		var selector := get_node_or_null("/root/SelectorPersonaje")
		if selector != null:
			selector.call("seleccionar", "casual" if evento.physical_keycode == KEY_1 else "guardia_seguridad")
			get_tree().reload_current_scene()
	elif evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			distancia = maxf(1.0, distancia - 0.2)
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distancia = minf(6.0, distancia + 0.2)

func _aplicar_vista() -> void:
	if tercera_persona:
		camara_externa.make_current()
	else:
		(jugador.get_node("Cabeza/Camera3D") as Camera3D).make_current()
	var pose := jugador.get("modificador_pose") as SkeletonModifier3D
	if pose != null:
		# En tercera persona se ve la cabeza; en primera se oculta por dentro.
		pose.set("ocultar_cabeza", not tercera_persona)
	etiqueta.text = "V: vista  |  1/2: personaje  |  C agacharse  Z arrastrarse  F linterna  Ctrl correr  |  rueda: zoom"

func _process(_delta: float) -> void:
	if not tercera_persona or jugador == null:
		return
	var punto := jugador.global_position + Vector3(0.0, 0.9, 0.0)
	var cuerpo := jugador.global_basis
	camara_externa.global_position = punto + cuerpo * Vector3(0.8, 0.5, distancia)
	camara_externa.look_at(punto, Vector3.UP)
