extends Node3D
## Galería de observación con un vacío profundo y una zona visible pero aislada.

const JUGADOR = preload("res://jugador/jugador.tscn")

func _ready() -> void:
	_crear_caja("Galería segura", Vector3(10, 0.3, 10), Vector3(0, 0, 0), Color(0.52, 0.51, 0.43))
	_crear_caja("Plataforma lejana", Vector3(9, 0.3, 8), Vector3(0, 0, -19), Color(0.48, 0.48, 0.42))
	_crear_caja("Fondo del pozo", Vector3(40, 0.5, 70), Vector3(0, -24, -10), Color(0.24, 0.25, 0.23))
	_crear_caja("Muro lateral este", Vector3(0.5, 24, 55), Vector3(19, -12, -10), Color(0.35, 0.35, 0.32))
	_crear_caja("Muro lateral oeste", Vector3(0.5, 24, 55), Vector3(-19, -12, -10), Color(0.35, 0.35, 0.32))
	_crear_caja("Piso sala visible fondo", Vector3(5, 0.2, 5), Vector3(0, 0.25, -19), Color(0.58, 0.57, 0.48))
	_crear_caja("Pared trasera sala visible", Vector3(5, 3.2, 0.2), Vector3(0, 1.9, -21.4), Color(0.58, 0.57, 0.48))
	_crear_caja("Pared lateral sala visible", Vector3(0.2, 3.2, 5), Vector3(-2.4, 1.9, -19), Color(0.58, 0.57, 0.48))
	_crear_caja("Pared lateral sala visible", Vector3(0.2, 3.2, 5), Vector3(2.4, 1.9, -19), Color(0.58, 0.57, 0.48))
	_crear_luz(Vector3(0, -21, -10), 20.0, 1.3, Color(0.42, 0.55, 0.68))
	_crear_luz(Vector3(0, 6, -19), 12.0, 1.0, Color(0.76, 0.84, 0.72))
	var jugador := JUGADOR.instantiate() as CharacterBody3D
	jugador.position = Vector3(0, 0.02, 2)
	add_child(jugador)
	var ambiente := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_SKY
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.28, 0.31, 0.33)
	entorno.ambient_light_energy = 0.45
	ambiente.environment = entorno
	add_child(ambiente)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48, -25, 0)
	sol.light_energy = 0.45
	add_child(sol)

func _crear_caja(nombre: String, tamano: Vector3, posicion: Vector3, color: Color) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	cuerpo.add_child(visual)
	add_child(cuerpo)

func _crear_luz(posicion: Vector3, alcance: float, energia: float, color: Color) -> void:
	var luz := OmniLight3D.new()
	luz.position = posicion
	luz.omni_range = alcance
	luz.light_energy = energia
	luz.light_color = color
	add_child(luz)
