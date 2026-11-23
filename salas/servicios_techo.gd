extends RefCounted
## Instalaciones que ocupan la cámara técnica sobre el cielorraso.

const RADIO_TUBERIA_AGUA := 0.045
const RADIO_TUBERIA_GAS := 0.03
const ANCHO_BANDEJA := 0.12
const ALTO_BANDEJA := 0.06

static func crear(parent: Node3D, huella: PackedVector2Array, alto_sala: float, zonas_excluidas: Array = []) -> void:
	if huella.size() < 3:
		return
	var regiones := GeometriaHuella.diferencia_por_poligonos(huella, zonas_excluidas)
	if regiones.is_empty():
		return
	var limites := GeometriaHuella.limites(huella)
	var centro := limites.get_center()
	var material_agua := _material(Color(0.16, 0.22, 0.25), 0.35)
	var material_gas := _material(Color(0.28, 0.23, 0.15), 0.3)
	var material_cables := _material(Color(0.24, 0.23, 0.2), 0.25)
	var material_ducto := _material(Color(0.2, 0.19, 0.16), 0.2)

	# El tendido queda en la mitad inferior del plenum para ser visible desde
	# placas faltantes y no tocar las placas levantadas.
	var y_agua := alto_sala + 0.48
	var y_gas := alto_sala + 0.66
	var y_cables := alto_sala + 0.32
	var y_ducto := alto_sala + 0.95
	var limites_z := Vector2(limites.position.y, limites.end.y)
	var limites_x := Vector2(limites.position.x, limites.end.x)
	var paso := 3.0
	var primera_z := centro.y
	while primera_z - paso >= limites_z.x + 0.25:
		primera_z -= paso
	while primera_z + paso <= limites_z.y - 0.25:
		primera_z += paso
	var primera_x := centro.x
	while primera_x - paso >= limites_x.x + 0.25:
		primera_x -= paso
	while primera_x + paso <= limites_x.y - 0.25:
		primera_x += paso

	var z := primera_z
	while z <= limites_z.y + 0.001:
		for region in regiones:
			var extremos := _extremos_corte(region, z, true)
			if extremos.size() == 2:
				_agregar_tuberia(parent, Vector3(extremos[0], y_agua, z), Vector3(extremos[1], y_agua, z), RADIO_TUBERIA_AGUA, material_agua, "TuberiaAgua")
				_agregar_ducto(parent, Vector3(extremos[0], y_ducto, z), Vector3(extremos[1], y_ducto, z), material_ducto)
		z += paso

	var x := primera_x
	while x <= limites_x.y + 0.001:
		for region in regiones:
			var extremos := _extremos_corte(region, x, false)
			if extremos.size() == 2:
				_agregar_tuberia(parent, Vector3(x, y_gas, extremos[0]), Vector3(x, y_gas, extremos[1]), RADIO_TUBERIA_GAS, material_gas, "TuberiaGas")
				_agregar_bandeja(parent, Vector3(x, y_cables, extremos[0]), Vector3(x, y_cables, extremos[1]), material_cables)
		x += paso

static func _extremos_corte(huella: PackedVector2Array, cota: float, horizontal: bool) -> PackedFloat32Array:
	var cruces := PackedFloat32Array()
	for indice in huella.size():
		var a := huella[indice]
		var b := huella[(indice + 1) % huella.size()]
		var perpendicular_a := a.y if horizontal else a.x
		var perpendicular_b := b.y if horizontal else b.x
		if is_equal_approx(perpendicular_a, perpendicular_b):
			continue
		if cota < minf(perpendicular_a, perpendicular_b) or cota >= maxf(perpendicular_a, perpendicular_b):
			continue
		var t := (cota - perpendicular_a) / (perpendicular_b - perpendicular_a)
		var paralelo_a := a.x if horizontal else a.y
		var paralelo_b := b.x if horizontal else b.y
		cruces.append(lerpf(paralelo_a, paralelo_b, t))
	if cruces.size() < 2:
		return PackedFloat32Array()
	cruces.sort()
	return PackedFloat32Array([cruces[0], cruces[-1]])

static func _agregar_tuberia(parent: Node3D, inicio: Vector3, fin: Vector3, radio: float, material: StandardMaterial3D, nombre: String) -> void:
	var largo := inicio.distance_to(fin)
	if largo < 0.5:
		return
	var tubo := MeshInstance3D.new()
	tubo.name = nombre
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = largo
	malla.radial_segments = 8
	tubo.mesh = malla
	tubo.position = (inicio + fin) * 0.5
	if absf(fin.x - inicio.x) > absf(fin.z - inicio.z):
		tubo.rotation.z = PI * 0.5
	else:
		tubo.rotation.x = PI * 0.5
	tubo.material_override = material
	tubo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(tubo)

static func _agregar_ducto(parent: Node3D, inicio: Vector3, fin: Vector3, material: StandardMaterial3D) -> void:
	var largo := inicio.distance_to(fin)
	if largo < 0.5:
		return
	var ducto := MeshInstance3D.new()
	ducto.name = "DuctoVentilacion"
	var malla := BoxMesh.new()
	malla.size = Vector3(largo, ALTO_BANDEJA * 2.0, 0.22)
	ducto.mesh = malla
	ducto.position = (inicio + fin) * 0.5
	if absf(fin.x - inicio.x) <= absf(fin.z - inicio.z):
		ducto.rotation.y = PI * 0.5
	ducto.material_override = material
	ducto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ducto)

static func _agregar_bandeja(parent: Node3D, inicio: Vector3, fin: Vector3, material: StandardMaterial3D) -> void:
	var largo := inicio.distance_to(fin)
	if largo < 0.5:
		return
	var bandeja := MeshInstance3D.new()
	bandeja.name = "BandejaElectricidad"
	var malla := BoxMesh.new()
	malla.size = Vector3(largo, ALTO_BANDEJA, ANCHO_BANDEJA)
	bandeja.mesh = malla
	bandeja.position = (inicio + fin) * 0.5
	bandeja.rotation.y = PI * 0.5
	bandeja.material_override = material
	bandeja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(bandeja)

static func _material(color: Color, metalness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalness
	material.roughness = 0.75
	material.emission_enabled = true
	material.emission = color * 0.18
	return material
