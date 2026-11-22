extends RefCounted
## Panel fluorescente de techo: placa emisora visible y un foco dirigido hacia
## abajo. Lo comparten las salas rectangulares y las circulares.

const ColorLuz := Color(1.0, 0.97, 0.86)
## Plano común: cara inferior del panel, placas y cara superior de las vigas.
const PLANO_ENCASTRE_Y := -0.16
const ALTURA_PANEL := 0.04
const DESFASE_CENTRO_PANEL_Y := PLANO_ENCASTRE_Y + ALTURA_PANEL * 0.5
## Distancia (m) desde la que se desvanecen las sombras de la luminaria.
const DISTANCIA_SOMBRAS := 13.0
const DISTANCIA_INICIO_DESVANECIMIENTO := 30.0
const DISTANCIA_APAGADO := 40.0
const RADIO_ILUMINADO_EN_SUELO := 2.25
const FluorescenteScript = preload("res://salas/fluorescente.gd")


## "posicion" es el centro del panel; su cara inferior queda al ras de placas y vigas.
static func crear(sala: Node3D, posicion: Vector3, ancho: float, largo: float, alto_sala: float, rng: RandomNumberGenerator) -> void:
	var luminaria := Node3D.new()
	luminaria.name = "PanelFluorescente"
	luminaria.add_to_group("luces_techo")
	luminaria.position = posicion
	var funciona := rng.randf() > 0.28
	var intermitente := funciona and rng.randf() > 0.85
	var modo_inicial := FluorescenteScript.MODO_ENCENDIDA
	if not funciona:
		modo_inicial = FluorescenteScript.MODO_AVERIADA
	elif intermitente:
		modo_inicial = FluorescenteScript.MODO_INTERMITENTE
	var panel := MeshInstance3D.new()
	panel.name = "PanelEmisor"
	var malla := BoxMesh.new()
	malla.size = Vector3(ancho, ALTURA_PANEL, largo)
	panel.mesh = malla
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.86) if funciona else Color(0.12, 0.12, 0.12)
	material.emission_enabled = funciona and not intermitente
	material.emission = ColorLuz
	material.emission_energy_multiplier = 2.2
	panel.material_override = material
	panel.add_to_group("paneles_luz")
	panel.set_meta("emite_por_defecto", funciona and not intermitente)
	luminaria.add_child(panel)
	var luz := SpotLight3D.new()
	luz.name = "Foco"
	luz.position = Vector3(0, 3.02, 0)
	luz.rotation_degrees = Vector3(-90, 0, 0)
	luz.light_color = ColorLuz
	luz.light_energy = 1.25
	luz.light_specular = 0.5
	luz.light_size = 1.0
	var altura_hasta_suelo := maxf(alto_sala, 0.1)
	luz.spot_range = altura_hasta_suelo + 0.25
	luz.spot_attenuation = 2.0
	# Ajusta el cono para cubrir unos 2,25 m de radio al llegar al piso.
	luz.spot_angle = clampf(rad_to_deg(atan(RADIO_ILUMINADO_EN_SUELO / altura_hasta_suelo)), 18.0, 55.0)
	luz.spot_angle_attenuation = 0.25
	luz.shadow_enabled = true
	luz.shadow_bias = 0.04
	luz.shadow_normal_bias = 1.2
	luz.shadow_blur = 1.6
	luz.distance_fade_enabled = true
	luz.distance_fade_begin = DISTANCIA_INICIO_DESVANECIMIENTO
	luz.distance_fade_shadow = DISTANCIA_SOMBRAS
	luz.distance_fade_length = DISTANCIA_APAGADO - DISTANCIA_INICIO_DESVANECIMIENTO
	luz.add_to_group("luces_techo_nodos")
	luz.set_meta("energia_base", luz.light_energy)
	luminaria.add_child(luz)
	luminaria.set_script(FluorescenteScript)
	luminaria.set("semilla", rng.randi())
	luminaria.set("modo", modo_inicial)
	sala.add_child(luminaria)
	var posicion_global := luminaria.global_position
	luminaria.set_meta("id_editor", "X %.2f · Z %.2f" % [posicion_global.x, posicion_global.z])
