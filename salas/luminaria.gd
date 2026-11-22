extends RefCounted
## Panel fluorescente de techo: placa emisora visible y un foco dirigido hacia
## abajo. Lo comparten las salas rectangulares y las circulares.

const ColorLuz := Color(1.0, 0.97, 0.86)
## Plano común: cara inferior del panel, placas y cara superior de las vigas.
const PLANO_ENCASTRE_Y := -0.16
const ALTURA_PANEL := 0.04
## Se restan 8 cm al lado del módulo de 1,5 m: 4 cm por lado para librar
## la retícula (7 cm) y dejar una junta de 5 mm.
const MARGEN_PLACA_RETICULA := 0.08
const DESFASE_PLACA_TECHO := 0.005
const DESFASE_CENTRO_PANEL_Y := PLANO_ENCASTRE_Y + DESFASE_PLACA_TECHO + ALTURA_PANEL * 0.5
## En salas altas se reduce gradualmente la atenuación para que la energía
## alcance el piso sin subir el brillo del panel ni de las salas bajas.
const ALTURA_REFERENCIA_ATENUACION := 4.2
const ALTURA_MAXIMA_ATENUACION := 12.0
const ATENUACION_SPOT_NORMAL := 2.0
const ATENUACION_SPOT_SALA_ALTA := 1.2
## Relleno omnidireccional muy local para la pared cercana y el cielorraso.
const ENERGIA_REBOTE_LOCAL := 0.045
const ALCANCE_REBOTE_LOCAL := 2.4
## Distancia (m) desde la que se desvanecen las sombras de la luminaria.
const DISTANCIA_SOMBRAS := 50.0
const DISTANCIA_INICIO_DESVANECIMIENTO := 50.0
const DISTANCIA_APAGADO := 50.0
## Semilado nominal (m) del cuadrado que ilumina cada panel en el piso.
const TAMANO_PISO := 8.0
## Abre un poco el cono principal para que alcance las paredes laterales.
const FACTOR_APERTURA_PRINCIPAL := 1.15
## Dónde (0..1 desde el centro) el proyector llega a negro. Debe ser menor que
## 0,7 para que el cuadrado quede dentro del cono y no se recorten las esquinas.
const BORDE_PROYECTOR := 0.6
## Luz de relleno por sala: simula el rebote en paredes y techo sin calcular
## iluminación global. Energía por panel operativo y tope por sala.
const USAR_RELLENO := false
const ENERGIA_RELLENO_POR_PANEL := 0.05
const ENERGIA_RELLENO_MAXIMA := 0.25
## Altura del relleno como fracción de la altura de la sala (cerca del techo, así
## sus manchas quedan contra el cielorraso y no en medio de las paredes).
const ALTURA_RELLENO := 0.9
const FluorescenteScript = preload("res://salas/fluorescente.gd")

static var _proyector_cuadrado: Texture2D


## Godot no tiene luces de área. Un SpotLight3D con esta textura (blanco al
## centro, negro en el borde) deja un pozo de luz cuadrado y suave en el piso.
static func _proyector() -> Texture2D:
	if _proyector_cuadrado != null:
		return _proyector_cuadrado
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.35, BORDE_PROYECTOR, 1.0])
	gradiente.colors = PackedColorArray([Color.WHITE, Color(0.85, 0.85, 0.85), Color.BLACK, Color.BLACK])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_SQUARE
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 128
	textura.height = 128
	_proyector_cuadrado = textura
	return textura


## Lee la opción de sombras sin depender de que el autoload exista
## (las pruebas del editor corren sin él).
static func _sombras_activas() -> bool:
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return true
	var ajustes := arbol.root.get_node_or_null("Ajustes")
	return ajustes == null or bool(ajustes.get("sombras"))


## "posicion" es el centro del panel; su cara inferior queda al ras de placas y vigas.
## Devuelve true si el panel funciona (encendido o intermitente).
static func crear(sala: Node3D, posicion: Vector3, ancho: float, largo: float, alto_sala: float, rng: RandomNumberGenerator) -> bool:
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
	material.emission_energy_multiplier = FluorescenteScript.EMISION_ENCENDIDA
	panel.material_override = material
	panel.add_to_group("paneles_luz")
	panel.set_meta("emite_por_defecto", funciona and not intermitente)
	luminaria.add_child(panel)
	# El foco queda pegado a la cara inferior del panel.
	var desfase_foco := -(ALTURA_PANEL * 0.5 + 0.001)
	var altura_hasta_suelo := maxf(alto_sala + DESFASE_CENTRO_PANEL_Y + desfase_foco, 0.1)
	var luz := SpotLight3D.new()
	luz.name = "Foco"
	luz.position = Vector3(0, desfase_foco, 0)
	luz.rotation_degrees = Vector3(-90, 0, 0)
	luz.light_color = ColorLuz
	# Mantiene el pozo de luz local; el relleno por sala queda desactivado.
	luz.light_energy = 0.5
	luz.light_specular = 0.5
	luz.light_size = 1.0
	# El proyector llega a negro en BORDE_PROYECTOR; el factor amplía su huella
	# lateral sin cambiar la energía de la lámpara.
	var semilado_haz_piso := TAMANO_PISO * FACTOR_APERTURA_PRINCIPAL
	luz.spot_angle = clampf(rad_to_deg(atan(semilado_haz_piso / (BORDE_PROYECTOR * altura_hasta_suelo))), 20.0, 80.0)
	luz.spot_angle_attenuation = 0.5
	luz.light_projector = _proyector()
	var proporcion_altura := clampf(inverse_lerp(ALTURA_REFERENCIA_ATENUACION, ALTURA_MAXIMA_ATENUACION, altura_hasta_suelo), 0.0, 1.0)
	luz.spot_attenuation = lerpf(ATENUACION_SPOT_NORMAL, ATENUACION_SPOT_SALA_ALTA, proporcion_altura)
	# Alcance hasta la esquina del cuadrado en el piso.
	luz.spot_range = sqrt(altura_hasta_suelo * altura_hasta_suelo + 2.0 * semilado_haz_piso * semilado_haz_piso) + 0.4
	luz.shadow_enabled = _sombras_activas()
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
	var rebote := OmniLight3D.new()
	rebote.name = "ReboteLocal"
	rebote.position = Vector3(0, 0.04, 0)
	rebote.light_color = ColorLuz
	rebote.light_energy = ENERGIA_REBOTE_LOCAL
	rebote.light_specular = 0.0
	rebote.omni_range = ALCANCE_REBOTE_LOCAL
	rebote.omni_attenuation = 1.5
	rebote.shadow_enabled = false
	rebote.light_bake_mode = Light3D.BAKE_DISABLED
	rebote.add_to_group("luces_techo_nodos")
	rebote.set_meta("energia_base", rebote.light_energy)
	rebote.set_meta("modo_luz", modo_inicial)
	luminaria.add_child(rebote)
	luminaria.set_script(FluorescenteScript)
	luminaria.set("semilla", rng.randi())
	luminaria.set("modo", modo_inicial)
	sala.add_child(luminaria)
	var posicion_global := luminaria.global_position
	luminaria.set_meta("id_editor", "X %.2f · Z %.2f" % [posicion_global.x, posicion_global.z])
	return funciona


## Luz de relleno de una sala: una luz omni sin sombras ni cálculo de GI que
## aporta el rebote difuso en paredes y techo. Solo existe si la sala tiene al
## menos un panel operativo, así una sala sin luces sigue a oscuras.
## "centro_xz" y "radio" describen la huella de la sala en su espacio local.
static func crear_relleno(sala: Node3D, centro_xz: Vector2, radio: float, alto_sala: float, paneles_operativos: int) -> void:
	if not USAR_RELLENO or paneles_operativos <= 0:
		return
	var luz := OmniLight3D.new()
	luz.name = "RellenoRebote"
	luz.position = Vector3(centro_xz.x, alto_sala * ALTURA_RELLENO, centro_xz.y)
	luz.light_color = Color(1.0, 0.94, 0.8)
	luz.light_energy = minf(ENERGIA_RELLENO_POR_PANEL * paneles_operativos, ENERGIA_RELLENO_MAXIMA)
	luz.light_specular = 0.0
	luz.omni_range = radio + 1.0
	luz.omni_attenuation = 0.6
	luz.shadow_enabled = false
	luz.light_bake_mode = Light3D.BAKE_DISABLED
	luz.add_to_group("luces_techo_nodos")
	luz.set_meta("energia_base", luz.light_energy)
	luz.set_meta("modo_luz", FluorescenteScript.MODO_ENCENDIDA)
	sala.add_child(luz)
