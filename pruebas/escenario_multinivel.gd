extends Node3D
## Prototipo transitable de dos plantas; no forma parte aún del generador.

const JUGADOR = preload("res://jugador/jugador.tscn")
const ALTO_PLANTA := 6.0
const CANTIDAD_ESCALONES := 30
const HUELLA_ESCALON := 0.34

func _ready() -> void:
	_crear_caja("Piso inferior", Vector3(10, 0.3, 14), Vector3(0, -0.15, 1), Color(0.58, 0.57, 0.48))
	_crear_caja("Piso superior", Vector3(10, 0.3, 12), Vector3(0, ALTO_PLANTA - 0.15, -8), Color(0.53, 0.53, 0.46))
	var longitud_rampa := sqrt(pow(CANTIDAD_ESCALONES * HUELLA_ESCALON, 2) + pow(ALTO_PLANTA, 2))
	var angulo_rampa := atan2(ALTO_PLANTA, CANTIDAD_ESCALONES * HUELLA_ESCALON)
	var rampa := _crear_caja("Colisión continua de escalera", Vector3(2.0, 0.2, longitud_rampa), Vector3(0, ALTO_PLANTA * 0.5, -1.1), Color(0.45, 0.45, 0.4))
	rampa.rotation.x = angulo_rampa
	for i in CANTIDAD_ESCALONES:
		var elevacion := (float(i + 1) / CANTIDAD_ESCALONES) * ALTO_PLANTA
		var z := 4.0 - (i + 1) * HUELLA_ESCALON
		_crear_visual("Escalon_%02d" % i, Vector3(2.0, 0.08, HUELLA_ESCALON), Vector3(0, elevacion, z), Color(0.45, 0.45, 0.4))
	# Barandas sólidas evitan salir lateralmente de la escalera.
	_crear_caja("Baranda izquierda", Vector3(0.15, ALTO_PLANTA, 10.5), Vector3(-1.1, ALTO_PLANTA * 0.5, -1.1), Color(0.34, 0.34, 0.31))
	_crear_caja("Baranda derecha", Vector3(0.15, ALTO_PLANTA, 10.5), Vector3(1.1, ALTO_PLANTA * 0.5, -1.1), Color(0.34, 0.34, 0.31))
	var jugador := JUGADOR.instantiate() as CharacterBody3D
	jugador.position = Vector3(0, 0.02, 5)
	add_child(jugador)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-52, -20, 0)
	sol.light_energy = 0.65
	add_child(sol)
	var entorno := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.35, 0.37, 0.4)
	ambiente.ambient_light_energy = 0.55
	entorno.environment = ambiente
	add_child(entorno)

func _crear_caja(nombre: String, tamano: Vector3, posicion: Vector3, color: Color) -> StaticBody3D:
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
	return cuerpo

func _crear_visual(nombre: String, tamano: Vector3, posicion: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.name = nombre
	visual.position = posicion
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	add_child(visual)
