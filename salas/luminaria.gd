extends RefCounted
## Panel fluorescente de techo: placa emisora visible y un foco dirigido hacia
## abajo. Lo comparten las salas rectangulares y las circulares.

const ColorLuz := Color(1.0, 0.97, 0.86)
## Distancia (m) hasta la que la luz proyecta sombras, y desde la que se apaga.
const DISTANCIA_SOMBRAS := 13.0
const DISTANCIA_APAGADO := 26.0


## "posicion" es la del panel en la sala (a la altura del cielorraso).
static func crear(sala: Node3D, posicion: Vector3, ancho: float, largo: float, alto_sala: float, rng: RandomNumberGenerator) -> void:
	var luminaria := Node3D.new()
	luminaria.name = "PanelFluorescente"
	luminaria.add_to_group("luces_techo")
	luminaria.position = posicion
	var funciona := rng.randf() > 0.28
	var panel := MeshInstance3D.new()
	panel.name = "PanelEmisor"
	var malla := BoxMesh.new()
	malla.size = Vector3(ancho, 0.04, largo)
	panel.mesh = malla
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.86) if funciona else Color(0.12, 0.12, 0.12)
	material.emission_enabled = funciona
	material.emission = ColorLuz
	material.emission_energy_multiplier = 2.2
	panel.material_override = material
	panel.add_to_group("paneles_luz")
	panel.set_meta("emite_por_defecto", funciona)
	luminaria.add_child(panel)
	if funciona:
		var luz := SpotLight3D.new()
		luz.name = "Foco"
		luz.position = Vector3(0, -0.05, 0)
		luz.rotation_degrees = Vector3(-90, 0, 0)
		luz.light_color = ColorLuz
		luz.light_energy = 3.2
		luz.light_specular = 0.5
		luz.spot_range = alto_sala + 3.5
		luz.spot_angle = 64.0
		luz.spot_angle_attenuation = 1.4
		luz.shadow_enabled = true
		luz.shadow_bias = 0.04
		luz.shadow_normal_bias = 1.2
		luz.shadow_blur = 1.6
		luz.distance_fade_enabled = true
		luz.distance_fade_begin = DISTANCIA_APAGADO - 8.0
		luz.distance_fade_shadow = DISTANCIA_SOMBRAS
		luz.distance_fade_length = 8.0
		luz.add_to_group("luces_techo_nodos")
		luz.set_meta("energia_base", luz.light_energy)
		luminaria.add_child(luz)
		if rng.randf() > 0.15:
			luminaria.set_script(load("res://salas/fluorescente.gd"))
			luminaria.set("semilla", rng.randi())
	sala.add_child(luminaria)
