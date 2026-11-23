extends RefCounted
## Instalaciones que ocupan la cámara técnica sobre el cielorraso.

const RADIO_TUBERIA_AGUA := 0.045
const RADIO_TUBERIA_GAS := 0.03
const ANCHO_BANDEJA := 0.12
const ALTO_BANDEJA := 0.06
## Altura (sobre el cielorraso) a la que están los soportes que cuelgan del forjado.
const ALTURA_FORJADO := 1.85

## Acumula la geometría de cada material en una sola malla (una MeshInstance3D por
## material en vez de cientos de nodos sueltos).
class Acumulador:
	var mallas: Dictionary = {}

	func _surface(material: Material) -> SurfaceTool:
		if not mallas.has(material):
			mallas[material] = SurfaceTool.new()
		return mallas[material]

	func caja(material: Material, centro: Vector3, tam: Vector3, giro_y := 0.0) -> void:
		var m := BoxMesh.new()
		m.size = tam
		_surface(material).append_from(m, 0, Transform3D(Basis(Vector3.UP, giro_y), centro))

	## eje: 0 = a lo largo de X, 1 = vertical, 2 = a lo largo de Z.
	func cilindro(material: Material, centro: Vector3, radio: float, largo: float, eje: int, segmentos := 10) -> void:
		var m := CylinderMesh.new()
		m.top_radius = radio
		m.bottom_radius = radio
		m.height = largo
		m.radial_segments = segmentos
		m.rings = 1
		var base := Basis()
		if eje == 0:
			base = Basis(Vector3.BACK, PI * 0.5)
		elif eje == 2:
			base = Basis(Vector3.RIGHT, PI * 0.5)
		_surface(material).append_from(m, 0, Transform3D(base, centro))

	func volcar(parent: Node3D, nombre: String) -> void:
		for material in mallas:
			var st: SurfaceTool = mallas[material]
			st.set_material(material)
			var instancia := MeshInstance3D.new()
			instancia.name = nombre
			instancia.mesh = st.commit()
			instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(instancia)


## Recorrido de las instalaciones: lo usan el nivel (para construirlas) y el editor
## (para dibujarlas). Cada tramo: {"tipo": "agua"|"ducto"|"gas"|"bandeja", "a": Vector2, "b": Vector2}
## en coordenadas locales (x, z).
static func trazados(huella: PackedVector2Array, zonas_excluidas: Array = []) -> Array[Dictionary]:
	var tramos: Array[Dictionary] = []
	if huella.size() < 3:
		return tramos
	var regiones := GeometriaHuella.diferencia_por_poligonos(huella, zonas_excluidas)
	if regiones.is_empty():
		return tramos
	var limites := GeometriaHuella.limites(huella)
	var centro := limites.get_center()
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
			if extremos.size() == 2 and extremos[1] - extremos[0] >= 0.5:
				tramos.append({"tipo": "agua", "a": Vector2(extremos[0], z), "b": Vector2(extremos[1], z)})
				tramos.append({"tipo": "ducto", "a": Vector2(extremos[0], z), "b": Vector2(extremos[1], z)})
		z += paso
	var x := primera_x
	while x <= limites_x.y + 0.001:
		for region in regiones:
			var extremos := _extremos_corte(region, x, false)
			if extremos.size() == 2 and extremos[1] - extremos[0] >= 0.5:
				tramos.append({"tipo": "gas", "a": Vector2(x, extremos[0]), "b": Vector2(x, extremos[1])})
				tramos.append({"tipo": "bandeja", "a": Vector2(x, extremos[0]), "b": Vector2(x, extremos[1])})
		x += paso
	return tramos


static func crear(parent: Node3D, huella: PackedVector2Array, alto_sala: float, zonas_excluidas: Array = []) -> void:
	var tramos := trazados(huella, zonas_excluidas)
	if tramos.is_empty():
		return
	var m_agua := _material(Color(0.55, 0.36, 0.22), 0.85, 0.45)    # cobre oxidado
	var m_gas := _material(Color(0.78, 0.62, 0.12), 0.1, 0.55)      # amarillo de gas
	var m_bandeja := _material(Color(0.42, 0.42, 0.40), 0.7, 0.5)
	var m_cable := _material(Color(0.07, 0.07, 0.07), 0.0, 0.7)
	var m_ducto := _material(Color(0.52, 0.54, 0.55), 0.8, 0.4)     # chapa galvanizada
	var m_soporte := _material(Color(0.30, 0.30, 0.29), 0.6, 0.6)
	var m_conduit := _material(Color(0.62, 0.62, 0.6), 0.6, 0.45)
	var acum := Acumulador.new()
	var y_cables := alto_sala + 0.32
	var y_agua := alto_sala + 0.48
	var y_gas := alto_sala + 0.66
	var y_ducto := alto_sala + 0.95
	var techo_servicios := alto_sala + ALTURA_FORJADO
	for tramo in tramos:
		var a: Vector2 = tramo.a
		var b: Vector2 = tramo.b
		match String(tramo.tipo):
			"agua":
				_tubo(acum, m_agua, m_soporte, Vector3(a.x, y_agua, a.y), Vector3(b.x, y_agua, b.y), RADIO_TUBERIA_AGUA, techo_servicios, true)
			"ducto":
				_ducto(acum, m_ducto, m_soporte, Vector3(a.x, y_ducto, a.y), Vector3(b.x, y_ducto, b.y), techo_servicios)
			"gas":
				_tubo(acum, m_gas, m_soporte, Vector3(a.x, y_gas, a.y), Vector3(b.x, y_gas, b.y), RADIO_TUBERIA_GAS, techo_servicios, false)
			"bandeja":
				_bandeja(acum, m_bandeja, m_cable, m_conduit, m_soporte, Vector3(a.x, y_cables, a.y), Vector3(b.x, y_cables, b.y), techo_servicios)
	acum.volcar(parent, "ServiciosTecho")

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

## Tubo con bridas cada ~1,5 m y abrazaderas que lo cuelgan del forjado.
static func _tubo(acum: Acumulador, material: Material, soporte: Material, inicio: Vector3, fin: Vector3, radio: float, y_forjado: float, a_lo_largo_x: bool) -> void:
	var largo := inicio.distance_to(fin)
	var centro := (inicio + fin) * 0.5
	var eje := 0 if a_lo_largo_x else 2
	acum.cilindro(material, centro, radio, largo, eje)
	var n := maxi(int(largo / 1.5), 1)
	for i in n + 1:
		var t := (float(i) + 0.5) / float(n + 1) if i < n else -1.0
		if t < 0.0:
			break
		var p := inicio.lerp(fin, t)
		acum.cilindro(soporte, p, radio * 1.35, 0.07, eje, 10)
		var alto := y_forjado - p.y
		acum.cilindro(soporte, Vector3(p.x, p.y + alto * 0.5, p.z), 0.008, alto, 1, 6)


static func _ducto(acum: Acumulador, material: Material, soporte: Material, inicio: Vector3, fin: Vector3, y_forjado: float) -> void:
	var largo := inicio.distance_to(fin)
	var centro := (inicio + fin) * 0.5
	acum.caja(material, centro, Vector3(largo, ALTO_BANDEJA * 2.0, 0.24))
	var n := maxi(int(largo / 1.2), 1)
	for i in n:
		var p := inicio.lerp(fin, (float(i) + 0.5) / float(n))
		acum.caja(soporte, p, Vector3(0.05, ALTO_BANDEJA * 2.0 + 0.03, 0.27))
		var alto := y_forjado - (p.y + ALTO_BANDEJA)
		if alto > 0.05:
			acum.cilindro(soporte, Vector3(p.x, p.y + ALTO_BANDEJA + alto * 0.5, p.z - 0.1), 0.008, alto, 1, 6)
			acum.cilindro(soporte, Vector3(p.x, p.y + ALTO_BANDEJA + alto * 0.5, p.z + 0.1), 0.008, alto, 1, 6)


## Bandeja portacables abierta, con tres cables adentro y un caño conduit al lado.
static func _bandeja(acum: Acumulador, bandeja: Material, cable: Material, conduit: Material, soporte: Material, inicio: Vector3, fin: Vector3, y_forjado: float) -> void:
	var largo := inicio.distance_to(fin)
	var centro := (inicio + fin) * 0.5
	var mitad := ANCHO_BANDEJA * 0.5
	acum.caja(bandeja, centro + Vector3(0, -ALTO_BANDEJA * 0.5, 0), Vector3(ANCHO_BANDEJA, 0.012, largo))
	acum.caja(bandeja, centro + Vector3(-mitad, 0, 0), Vector3(0.012, ALTO_BANDEJA, largo))
	acum.caja(bandeja, centro + Vector3(mitad, 0, 0), Vector3(0.012, ALTO_BANDEJA, largo))
	for dx in [-0.03, 0.0, 0.03]:
		acum.cilindro(cable, centro + Vector3(dx, -ALTO_BANDEJA * 0.5 + 0.02, 0), 0.012, largo * 0.98, 2, 6)
	acum.cilindro(conduit, centro + Vector3(0.12, 0.0, 0), 0.016, largo, 2, 8)
	var n := maxi(int(largo / 1.2), 1)
	for i in n:
		var p := inicio.lerp(fin, (float(i) + 0.5) / float(n))
		acum.caja(soporte, p + Vector3(0, -ALTO_BANDEJA * 0.5 - 0.01, 0), Vector3(ANCHO_BANDEJA + 0.06, 0.012, 0.03))
		var alto := y_forjado - p.y
		acum.cilindro(soporte, Vector3(p.x - mitad - 0.02, p.y + alto * 0.5, p.z), 0.008, alto, 1, 6)
		acum.cilindro(soporte, Vector3(p.x + mitad + 0.02, p.y + alto * 0.5, p.z), 0.008, alto, 1, 6)


static func _material(color: Color, metalico: float, rugosidad: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metalico
	material.roughness = rugosidad
	return material
