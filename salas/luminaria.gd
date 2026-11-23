extends RefCounted
## Panel fluorescente de techo: placa emisora visible y un foco dirigido hacia
## abajo. Lo comparten las salas rectangulares y las circulares.

const ColorLuz := Color(1.0, 0.97, 0.86)
## Cara inferior común del cielorraso: a ras de la coronación de las paredes.
const PLANO_ENCASTRE_Y := 0.0
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
## Relleno lateral para las paredes (también las altas). Es una luz omni sin
## sombras, apenas por encima del plano del techo para no iluminar el cielorraso.
## Su alcance crece con la altura de la sala para llegar al pie de la pared.
const USAR_REBOTE_PAREDES := true
const ENERGIA_REBOTE_PAREDES := 0.01
## Distancia horizontal (m) a la que se quiere llegar con la luz sobre las paredes.
const SEMILADO_REBOTE_PAREDES := 4.5
## Distancia (m) desde la que se desvanecen las sombras de la luminaria.
const DISTANCIA_SOMBRAS := 50.0
const DISTANCIA_INICIO_DESVANECIMIENTO := 50.0
const DISTANCIA_APAGADO := 50.0
## Semilado nominal (m) del cuadrado que ilumina cada panel en el piso.
const TAMANO_PISO := 10.0
## Abre un poco el cono principal para que alcance las paredes laterales.
const FACTOR_APERTURA_PRINCIPAL := 1.15
## Dónde (0..1 desde el centro) el proyector llega a negro. Debe ser menor que
## 0,7 para que el cuadrado quede dentro del cono y no se recorten las esquinas.
const BORDE_PROYECTOR := 0.6
## Luz de relleno por sala: simula el rebote en paredes y techo sin calcular
## iluminación global. Parte apagada; se puede activar y ajustar en desarrollo.
const USAR_RELLENO := false
const ENERGIA_RELLENO_POR_PANEL := 0.05
const ENERGIA_RELLENO_MAXIMA := 0.25
## Altura del relleno como fracción de la altura de la sala (cerca del techo, así
## sus manchas quedan contra el cielorraso y no en medio de las paredes).
const ALTURA_RELLENO := 0.9
const FluorescenteScript = preload("res://salas/fluorescente.gd")
static var _proyectores_cuadrados: Dictionary = {}


## Godot no tiene luces de área. Un SpotLight3D con esta textura (blanco al
## centro, negro en el borde) deja un pozo de luz cuadrado y suave en el piso.
static func _proyector(borde: float = BORDE_PROYECTOR) -> Texture2D:
	borde = clampf(borde, 0.36, 0.95)
	var clave := snappedf(borde, 0.01)
	if _proyectores_cuadrados.has(clave):
		return _proyectores_cuadrados[clave]
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.35, borde, 1.0])
	gradiente.colors = PackedColorArray([Color.WHITE, Color(0.85, 0.85, 0.85), Color.BLACK, Color.BLACK])
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_SQUARE
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 128
	textura.height = 128
	_proyectores_cuadrados[clave] = textura
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
static func crear(sala: Node3D, posicion: Vector3, ancho: float, largo: float, alto_sala: float, rng: RandomNumberGenerator, modo_forzado: int = -1) -> bool:
	var luminaria := Node3D.new()
	luminaria.name = "PanelFluorescente"
	luminaria.add_to_group("luces_techo")
	luminaria.position = posicion
	var probabilidad_falla := 0.28
	var probabilidad_intermitencia := 0.15
	var arbol := Engine.get_main_loop() as SceneTree
	var desarrollo := arbol.root.get_node_or_null("PanelDesarrollo") if arbol != null else null
	if desarrollo != null:
		probabilidad_falla = float(desarrollo.get("probabilidad_falla"))
		probabilidad_intermitencia = float(desarrollo.get("probabilidad_intermitencia"))
	var funciona := rng.randf() > probabilidad_falla
	var intermitente := funciona and rng.randf() < probabilidad_intermitencia
	var modo_inicial := FluorescenteScript.MODO_ENCENDIDA
	if not funciona:
		modo_inicial = FluorescenteScript.MODO_AVERIADA
	elif intermitente:
		modo_inicial = FluorescenteScript.MODO_INTERMITENTE
	if modo_forzado >= 0:
		modo_inicial = clampi(modo_forzado, FluorescenteScript.MODO_ENCENDIDA, FluorescenteScript.MODO_AVERIADA)
		funciona = modo_inicial != FluorescenteScript.MODO_AVERIADA
		intermitente = modo_inicial == FluorescenteScript.MODO_INTERMITENTE
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
	panel.set_meta("color_apagado", 0.281)
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
	luz.set_meta("altura_hasta_suelo", altura_hasta_suelo)
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
	rebote.set_meta("altura_hasta_suelo", altura_hasta_suelo)
	rebote.set_meta("modo_luz", modo_inicial)
	luminaria.add_child(rebote)
	if USAR_REBOTE_PAREDES:
		var paredes := OmniLight3D.new()
		paredes.name = "ReboteParedes"
		paredes.position = Vector3(0, 0.04, 0)
		paredes.light_color = ColorLuz
		paredes.light_energy = ENERGIA_REBOTE_PAREDES
		paredes.light_specular = 0.0
		paredes.omni_range = sqrt(altura_hasta_suelo * altura_hasta_suelo + SEMILADO_REBOTE_PAREDES * SEMILADO_REBOTE_PAREDES) + 0.5
		paredes.omni_attenuation = 1.0
		paredes.shadow_enabled = false
		paredes.light_bake_mode = Light3D.BAKE_DISABLED
		paredes.add_to_group("luces_techo_nodos")
		paredes.set_meta("energia_base", paredes.light_energy)
		paredes.set_meta("altura_hasta_suelo", altura_hasta_suelo)
		paredes.set_meta("modo_luz", modo_inicial)
		luminaria.add_child(paredes)
	luminaria.set_script(FluorescenteScript)
	luminaria.set("semilla", rng.randi())
	luminaria.set("modo", modo_inicial)
	sala.add_child(luminaria)
	var posicion_global := luminaria.global_position
	luminaria.set_meta("id_editor", "X %.2f · Z %.2f" % [posicion_global.x, posicion_global.z])
	return funciona


## Luz de relleno de una sala: omni sin sombras ni GI; queda invisible si está
## desactivada o si la sala no tiene luminarias operativas.
## "centro_xz" y "radio" describen la huella de la sala en su espacio local.
static func crear_relleno(sala: Node3D, centro_xz: Vector2, radio: float, alto_sala: float, paneles_operativos: int) -> void:
	var luz := OmniLight3D.new()
	luz.name = "RellenoRebote"
	luz.position = Vector3(centro_xz.x, alto_sala * ALTURA_RELLENO, centro_xz.y)
	luz.light_color = Color(1.0, 0.94, 0.8)
	var energia_por_panel := ENERGIA_RELLENO_POR_PANEL
	var energia_maxima := ENERGIA_RELLENO_MAXIMA
	var altura_relleno := ALTURA_RELLENO
	var alcance_extra := 1.0
	var atenuacion := 0.6
	var activo := USAR_RELLENO
	var arbol := Engine.get_main_loop() as SceneTree
	var desarrollo := arbol.root.get_node_or_null("PanelDesarrollo") if arbol != null else null
	if desarrollo != null:
		energia_por_panel = float(desarrollo.get("energia_relleno_por_panel"))
		energia_maxima = float(desarrollo.get("energia_relleno_maxima"))
		altura_relleno = float(desarrollo.get("altura_relleno_sala"))
		alcance_extra = float(desarrollo.get("alcance_extra_relleno"))
		atenuacion = float(desarrollo.get("atenuacion_relleno_sala"))
		activo = bool(desarrollo.get("relleno_sala_activo"))
	luz.position.y = alto_sala * altura_relleno
	luz.light_energy = minf(energia_por_panel * paneles_operativos, energia_maxima)
	luz.light_specular = 0.0
	luz.omni_range = radio + alcance_extra
	luz.omni_attenuation = atenuacion
	luz.shadow_enabled = false
	luz.light_bake_mode = Light3D.BAKE_DISABLED
	var iluminacion_activa := true
	if desarrollo != null:
		iluminacion_activa = bool(desarrollo.get("_iluminacion_activa"))
	luz.visible = activo and iluminacion_activa and paneles_operativos > 0
	luz.add_to_group("rellenos_sala")
	luz.add_to_group("luces_techo_nodos")
	luz.set_meta("energia_base", luz.light_energy)
	luz.set_meta("paneles_operativos", paneles_operativos)
	luz.set_meta("radio_base", radio)
	luz.set_meta("alto_sala", alto_sala)
	luz.set_meta("modo_luz", FluorescenteScript.MODO_ENCENDIDA)
	sala.add_child(luz)
