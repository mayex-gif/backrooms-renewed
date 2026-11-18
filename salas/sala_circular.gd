extends Node3D
## Sala circular facetada con cuatro huecos cardinales para sockets.

@export var radio_m := 5.0
@export var ancho_m := 10.0
@export var largo_m := 10.0
@export var alto_m := 3.2
@export var sockets: Array[SocketDef] = []
@export var semilla_ambiente := 1

func _ready() -> void:
	_crear_cilindro("Piso", 0.2, -0.1)
	_crear_techo_modular()
	var segmentos := 48
	var paso := TAU / segmentos
	for i in segmentos:
		var angulo := (i + 0.5) * paso
		if _es_hueco_de_puerta(angulo, paso):
			continue
		var centro := Vector3(radio_m + sin(angulo) * radio_m, alto_m * 0.5, radio_m - cos(angulo) * radio_m)
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "ParedCircular"
		cuerpo.position = centro
		cuerpo.rotation.y = -angulo
		var forma := BoxShape3D.new()
		forma.size = Vector3(radio_m * paso * 1.03, alto_m, 0.2)
		var colision := CollisionShape3D.new()
		colision.shape = forma
		cuerpo.add_child(colision)
		var visual := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = forma.size
		visual.mesh = malla
		cuerpo.add_child(visual)
		add_child(cuerpo)
	for socket in sockets:
		var altura_puerta := minf(2.45, alto_m)
		if alto_m <= altura_puerta:
			continue
		var dintel := StaticBody3D.new()
		dintel.name = "DintelCircular"
		dintel.position = socket.posicion_local + Vector3.UP * (alto_m + altura_puerta) * 0.5
		dintel.rotation.y = -socket.direccion * PI / 2.0
		var forma_dintel := BoxShape3D.new()
		forma_dintel.size = Vector3(socket.ancho, alto_m - altura_puerta, 0.2)
		var colision_dintel := CollisionShape3D.new()
		colision_dintel.shape = forma_dintel
		dintel.add_child(colision_dintel)
		var malla_dintel := MeshInstance3D.new()
		var box_dintel := BoxMesh.new()
		box_dintel.size = forma_dintel.size
		malla_dintel.mesh = box_dintel
		dintel.add_child(malla_dintel)
		add_child(dintel)

func _crear_techo_modular() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla_ambiente
	# El plenum oscuro tapa el exterior visible a través de huecos del cielorraso.
	_crear_cilindro("Plenum circular", 0.2, alto_m + 0.18)
	var tam_tile := 1.25
	var cantidad := ceili((radio_m * 2.0) / tam_tile)
	for x in cantidad + 1:
		var px := minf(x * tam_tile, radio_m * 2.0)
		var dx := px - radio_m
		var media_luz := sqrt(maxf(0.0, radio_m * radio_m - dx * dx))
		if media_luz > 0.05:
			_crear_viga(Vector3(px, alto_m - 0.12, radio_m), Vector3(0.045, 0.04, media_luz * 2.0))
	for z in cantidad + 1:
		var pz := minf(z * tam_tile, radio_m * 2.0)
		var dz := pz - radio_m
		var media_horizontal := sqrt(maxf(0.0, radio_m * radio_m - dz * dz))
		if media_horizontal > 0.05:
			_crear_viga(Vector3(radio_m, alto_m - 0.12, pz), Vector3(media_horizontal * 2.0, 0.04, 0.045))
	var fase_x := posmod(semilla_ambiente, 3)
	var fase_z := posmod(floori(float(semilla_ambiente) / 3.0), 3)
	for x in cantidad:
		for z in cantidad:
			var centro_x := x * tam_tile + tam_tile * 0.5
			var centro_z := z * tam_tile + tam_tile * 0.5
			var centro_radio := Vector2(centro_x - radio_m, centro_z - radio_m).length()
			if centro_radio > radio_m - 0.45:
				continue
			var valor := rng.randf()
			if valor < 0.065:
				continue
			var tile := _crear_tile(Vector3(centro_x, alto_m - 0.1, centro_z), tam_tile - 0.045, rng)
			if valor > 0.93:
				tile.position.y += rng.randf_range(0.04, 0.12)
				tile.rotation_degrees.z = rng.randf_range(-2.0, 2.0)
			if posmod(x - fase_x, 3) == 0 and posmod(z - fase_z, 3) == 0 and rng.randf() > 0.25:
				_crear_luminaria_techo(Vector3(centro_x, alto_m - 0.155, centro_z), rng)

func _crear_viga(posicion: Vector3, tamano: Vector3) -> void:
	var visual := MeshInstance3D.new()
	visual.name = "ReticulaTecho"
	visual.position = posicion
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	add_child(visual)

func _crear_tile(posicion: Vector3, tamano: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "TileTecho"
	cuerpo.position = posicion
	var forma := BoxShape3D.new()
	forma.size = Vector3(tamano, 0.08, tamano)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = forma.size
	visual.mesh = malla
	cuerpo.add_child(visual)
	add_child(cuerpo)
	return cuerpo

func _crear_luminaria_techo(posicion: Vector3, rng: RandomNumberGenerator) -> void:
	var luminaria := Node3D.new()
	luminaria.name = "PanelFluorescente"
	luminaria.add_to_group("luces_techo")
	luminaria.position = posicion
	var funciona := rng.randf() > 0.28
	var panel := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = Vector3(1.205, 0.04, 1.205)
	panel.mesh = malla
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE if funciona else Color(0.12, 0.12, 0.12)
	material.emission_enabled = funciona
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 1.6
	panel.material_override = material
	panel.add_to_group("paneles_luz")
	panel.set_meta("emite_por_defecto", funciona)
	luminaria.add_child(panel)
	if funciona:
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.96, 0.88)
		luz.light_energy = 0.9
		luz.omni_range = maxf(6.0, alto_m + 2.0)
		luz.shadow_enabled = false
		luz.add_to_group("luces_techo_nodos")
		luz.set_meta("energia_base", luz.light_energy)
		luminaria.add_child(luz)
		if rng.randf() > 0.48:
			luminaria.set_script(load("res://salas/fluorescente.gd"))
			luminaria.set("semilla", rng.randi())
	add_child(luminaria)

func _es_hueco_de_puerta(angulo: float, paso: float) -> bool:
	for socket in sockets:
		var centro := atan2(socket.posicion_local.x - radio_m, -(socket.posicion_local.z - radio_m))
		var diferencia := absf(wrapf(angulo - centro + PI, 0.0, TAU) - PI)
		var medio_ancho := asin(clampf(socket.ancho * 0.5 / radio_m, 0.0, 0.99))
		if diferencia < medio_ancho + paso * 0.55:
			return true
	return false

func _crear_cilindro(nombre: String, alto: float, y: float) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = Vector3(radio_m, y, radio_m)
	var forma := CylinderShape3D.new()
	forma.radius = radio_m
	forma.height = alto
	var colision := CollisionShape3D.new()
	colision.shape = forma
	if nombre == "Techo":
		colision.position.y = alto * 0.5
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = radio_m
	malla.bottom_radius = radio_m
	malla.height = alto
	visual.mesh = malla
	if nombre == "Techo":
		visual.position.y = alto * 0.5
	cuerpo.add_child(visual)
	add_child(cuerpo)
