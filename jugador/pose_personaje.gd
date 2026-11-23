extends SkeletonModifier3D
## Corrige la pose del esqueleto del personaje POR ENCIMA de las animaciones
## (idle / walk / run), que no traen agacharse, arrastrarse ni sostener linterna:
##   - Agacharse: baja la pelvis, inclina el torso y dobla las piernas con IK
##     (los pies siguen pegados al suelo y a la animación de caminar).
##   - Arrastrarse: acuesta el cuerpo boca abajo, arquea el torso para que la
##     cabeza quede a la altura de la cámara y mueve piernas y brazo izquierdo.
##   - Linterna: el brazo derecho (IK) la lleva delante de la cámara y la apunta
##     hacia donde mira el jugador; la mano se cierra alrededor del mango.
##   - Oculta la cabeza (se ve desde adentro en primera persona).
## Todo se calcula en el espacio del esqueleto: no depende de cómo estén
## orientados los ejes de los huesos del GLB. Funciona con los dos rigs del
## proyecto (casual: pelvis/spine_01/...; guardia: Hips/Spine/... de Mixamo).

## Dónde queda el agarre de la linterna respecto de la cámara (espacio de cámara:
## +X derecha, -Y abajo, -Z adelante), en metros.
## Se escala con el tamaño del personaje (largo del brazo).
@export var agarre_en_camara := Vector3(0.15, -0.15, -0.27)
## Distancia del mango que queda dentro del puño, medida desde la base de la linterna.
@export var mango_en_puno := 0.07
## Desplazamiento del centro de la palma respecto de la muñeca.
@export var palma_adelante := 0.045
@export var palma_hacia_adentro := 0.03
## Cierre del puño en radianes (falange 1, 2 y 3 de cada dedo / pulgar).
@export var cierre_dedos := Vector3(1.0, 1.25, 0.9)
@export var cierre_pulgar := Vector3(0.35, 0.45, 0.45)
@export var altura_cuerpo_tumbado := 0.11
@export var inclinacion_agachado := 0.35
@export var ocultar_cabeza := true
## Lo informa preparar(): true si el rig es tipo Mixamo (guardia).
var es_mixamo := false
## Fracción del largo del brazo que se permite extender (menos = codo más flexionado).
@export var extension_maxima := 0.78

# Estado que escribe el jugador cada cuadro.
var camara: Node3D
var cabeza_camara: Node3D
var conjunto_linterna: Node3D
var mezcla_agachado := 0.0
var mezcla_tumbado := 0.0
## 1 = linterna levantada y apuntando; 0 = brazo relajado con la linterna colgando.
var mezcla_linterna := 1.0
var fase_gateo := 0.0
var intensidad_gateo := 0.0

var _esq: Skeleton3D
var _listo := false
## Largo del brazo del personaje respecto del modelo casual (1.0).
var _esc := 1.0
var _alcance_brazo := 0.455
var _idx := {}
var _rest := {}
var _altura_ojos_pie := 1.55
var _cabeza_reposo := Vector3.ZERO
var _d_rest := Vector3.FORWARD
var _u_rest := Vector3.FORWARD
var _n_rest := Vector3.RIGHT
var _eje_dedos := Vector3.RIGHT
var _eje_pulgar := Vector3.RIGHT

## Nombres "de rol" (los del modelo casual) que usa todo este script.
const HUESOS := [
	"pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
	"clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
	"thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r",
	"index_01_r", "index_02_r", "index_03_r", "middle_01_r", "middle_02_r", "middle_03_r",
	"ring_01_r", "ring_02_r", "ring_03_r", "pinky_01_r", "pinky_02_r", "pinky_03_r",
	"thumb_01_r", "thumb_02_r", "thumb_03_r",
]
const DEDOS_DERECHA := ["index", "middle", "ring", "pinky"]
const LARGO_BRAZO_CASUAL := 0.455
const ALTURA_ESCALA_REFERENCIA := 1.55

const MIXAMO_BASE := {
	"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2",
	"neck_01": "Neck", "head": "Head",
}
const MIXAMO_LADO := {
	"clavicle": "Shoulder", "upperarm": "Arm", "lowerarm": "ForeArm", "hand": "Hand",
	"thigh": "UpLeg", "calf": "Leg", "foot": "Foot", "ball": "ToeBase",
}
const MIXAMO_DEDO := {"index": "Index", "middle": "Middle", "ring": "Ring", "pinky": "Pinky", "thumb": "Thumb"}


## Traduce un nombre de rol al hueso real del rig (casual o Mixamo).
func _nombre_real(rol: String, mixamo: bool) -> String:
	if not mixamo:
		return rol
	if MIXAMO_BASE.has(rol):
		return MIXAMO_BASE[rol]
	var partes := rol.split("_")
	var lado := "Left" if partes[-1] == "l" else "Right"
	if MIXAMO_LADO.has(partes[0]):
		return lado + String(MIXAMO_LADO[partes[0]])
	if MIXAMO_DEDO.has(partes[0]):
		return "%sHand%s%d" % [lado, MIXAMO_DEDO[partes[0]], int(partes[1])]
	return rol


## Devuelve false si el esqueleto no tiene los huesos esperados.
func preparar(esqueleto: Skeleton3D, altura_ojos_pie: float) -> bool:
	_esq = esqueleto
	_altura_ojos_pie = altura_ojos_pie
	var mixamo := _esq.find_bone("Hips") >= 0 and _esq.find_bone("pelvis") < 0
	es_mixamo = mixamo
	for nombre in HUESOS:
		var real := _nombre_real(nombre, mixamo)
		var i := _esq.find_bone(real)
		if i < 0:
			push_warning("PosePersonaje: falta el hueso '%s' (%s); se desactivan los ajustes de pose." % [real, nombre])
			return false
		_idx[nombre] = i
		_rest[nombre] = _esq.get_bone_global_rest(i)
	var mano: Transform3D = _rest["hand_r"]
	var medio: Transform3D = _rest["middle_01_r"]
	var indice: Transform3D = _rest["index_01_r"]
	var menique: Transform3D = _rest["pinky_01_r"]
	_d_rest = (medio.origin - mano.origin).normalized()
	_u_rest = (indice.origin - menique.origin).normalized()
	# Normal de la palma: hacia ese lado se cierran los dedos.
	_n_rest = _u_rest.cross(_d_rest).normalized()
	_eje_dedos = _d_rest.cross(_n_rest).normalized()
	_eje_pulgar = _u_rest.cross(_n_rest).normalized()
	var cabeza: Transform3D = _rest["head"]
	_cabeza_reposo = cabeza.origin
	var brazo: Transform3D = _rest["upperarm_r"]
	var codo: Transform3D = _rest["lowerarm_r"]
	var largo_brazo := (codo.origin - brazo.origin).length() + (mano.origin - codo.origin).length()
	_alcance_brazo = largo_brazo
	_esc = clampf(largo_brazo / LARGO_BRAZO_CASUAL, 0.6, 1.8)
	_listo = true
	return true


func _process_modification_with_delta(_delta: float) -> void:
	_procesar()


func _process_modification() -> void:
	_procesar()


func _procesar() -> void:
	if not _listo or camara == null or cabeza_camara == null:
		return
	var arriba_e := _vec_a_esq(Vector3.UP)
	var adelante_e := _vec_a_esq(-_jugador_base().z)
	var derecha_e := adelante_e.cross(arriba_e).normalized()
	# Rotar alrededor de este eje inclina el cuerpo hacia adelante.
	var eje_cabeceo := arriba_e.cross(adelante_e).normalized()

	var pies_l := _pos("foot_l")
	var pies_r := _pos("foot_r")
	var bajo := cabeza_camara.position.y < _altura_ojos_pie - 0.02

	if mezcla_tumbado > 0.001:
		_postura_tumbado(mezcla_tumbado, eje_cabeceo, adelante_e, derecha_e, arriba_e)
	elif bajo or mezcla_agachado > 0.001:
		_postura_agachado(mezcla_agachado, eje_cabeceo, adelante_e, pies_l, pies_r)

	_brazo_linterna(derecha_e, arriba_e, adelante_e)
	# Se escribe siempre: algunos rigs no animan la escala y quedaría escondida.
	_esq.set_bone_pose_scale(_idx["head"], Vector3.ONE * (0.001 if ocultar_cabeza else 1.0))


# ---------------------------------------------------------------- posturas

func _altura_cabeza_objetivo() -> float:
	# El hueso "head" queda a esta altura respecto de la cámara-cabeza.
	return cabeza_camara.position.y - (_altura_ojos_pie - _cabeza_reposo.y)


func _alinear_cabeza_con_camara() -> void:
	var objetivo := Vector3(_cabeza_reposo.x, _altura_cabeza_objetivo(), _cabeza_reposo.z)
	_mover_global(_idx["pelvis"], objetivo - _pos("head"))


func _postura_agachado(w: float, eje: Vector3, adelante: Vector3, pie_l: Vector3, pie_r: Vector3) -> void:
	var base_l := _esq.get_bone_global_pose(_idx["foot_l"]).basis
	var base_r := _esq.get_bone_global_pose(_idx["foot_r"]).basis
	_girar_global(_idx["pelvis"], Basis(eje, w * inclinacion_agachado))
	_alinear_cabeza_con_camara()
	_ik_dos_huesos(_idx["thigh_l"], _idx["calf_l"], _idx["foot_l"], pie_l, adelante)
	_ik_dos_huesos(_idx["thigh_r"], _idx["calf_r"], _idx["foot_r"], pie_r, adelante)
	_fijar_basis_global(_idx["foot_l"], base_l)
	_fijar_basis_global(_idx["foot_r"], base_r)


func _postura_tumbado(w: float, eje: Vector3, adelante: Vector3, derecha: Vector3, arriba: Vector3) -> void:
	# Piernas rectas: se descarta la animación de caminar en las piernas.
	var mezcla_piernas := clampf(w * 1.5, 0.0, 1.0)
	for nombre in ["thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]:
		var i: int = _idx[nombre]
		var reposo := _esq.get_bone_rest(i).basis.get_rotation_quaternion()
		var actual := _esq.get_bone_pose_rotation(i)
		_esq.set_bone_pose_rotation(i, actual.slerp(reposo, mezcla_piernas))
	_girar_global(_idx["pelvis"], Basis(eje, w * PI * 0.5))
	# Arqueo del torso para que la cabeza llegue a la altura de la cámara.
	var largo := maxf((_pos("head") - _pos("pelvis")).length(), 0.3)
	var elevacion := clampf((_altura_cabeza_objetivo() - altura_cuerpo_tumbado) / largo, 0.0, 0.85)
	var alfa := asin(elevacion) * w
	_girar_global(_idx["spine_01"], Basis(eje, -alfa * 0.25))
	_girar_global(_idx["spine_02"], Basis(eje, -alfa * 0.30))
	_girar_global(_idx["spine_03"], Basis(eje, -alfa * 0.30))
	_girar_global(_idx["neck_01"], Basis(eje, -alfa * 0.15))
	_alinear_cabeza_con_camara()
	# Gateo: las rodillas se levantan de a una y el brazo izquierdo tira hacia adelante.
	var g := intensidad_gateo * w
	if g > 0.001:
		_girar_global(_idx["calf_l"], Basis(eje, 0.55 * g * maxf(0.0, sin(fase_gateo))))
		_girar_global(_idx["calf_r"], Basis(eje, 0.55 * g * maxf(0.0, -sin(fase_gateo))))
	var hombro_l := _pos("upperarm_l")
	var tiron := 0.10 * _esc * intensidad_gateo * sin(fase_gateo + PI)
	var objetivo := hombro_l + adelante * (0.30 * _esc + tiron) - derecha * 0.14 * _esc
	objetivo.y = 0.05
	var polo := -derecha + arriba * 0.5
	var muneca_anim := _pos("hand_l")
	_ik_dos_huesos(_idx["upperarm_l"], _idx["lowerarm_l"], _idx["hand_l"], muneca_anim.lerp(objetivo, w), polo)


# ----------------------------------------------------------- brazo y linterna

func _brazo_linterna(derecha: Vector3, arriba: Vector3, adelante: Vector3) -> void:
	var m := clampf(mezcla_linterna, 0.0, 1.0)
	var mano: int = _idx["hand_r"]
	var hombro: int = _idx["upperarm_r"]
	var codo: int = _idx["lowerarm_r"]
	var q_anim := (_esq.get_bone_global_pose(mano).basis.orthonormalized() * _basis_reposo("hand_r").inverse()).get_rotation_quaternion()

	# Cámara y dirección de la mirada, en espacio del esqueleto.
	var transformada_esq := _esq.global_transform
	var cam_pos := transformada_esq.affine_inverse() * camara.global_position
	var cam_base := transformada_esq.basis.inverse() * camara.global_basis
	var apuntar := (-cam_base.z).normalized()
	var q_apuntar := Quaternion(_u_rest, apuntar)
	var q_mano := q_anim.slerp(q_apuntar, m)

	var agarre_obj := cam_pos + cam_base * (agarre_en_camara * _esc)
	agarre_obj.y = maxf(agarre_obj.y, 0.06)
	var muneca_obj := agarre_obj - (q_apuntar * (_d_rest * palma_adelante + _n_rest * palma_hacia_adentro) * _esc)
	# El brazo no se estira del todo: si el agarre queda lejos, se acerca al hombro.
	var desde_hombro := muneca_obj - _pos("upperarm_r")
	var maximo := _alcance_brazo * extension_maxima
	if desde_hombro.length() > maximo:
		muneca_obj = _pos("upperarm_r") + desde_hombro.normalized() * maximo
	var muneca_anim := _pos("hand_r")
	if m > 0.001:
		var polo_anim := (_pos("lowerarm_r") - _pos("upperarm_r")).normalized()
		var polo_nuevo := (derecha * 0.25 - arriba * 0.9 - adelante * 0.1).normalized()
		var polo := polo_anim.lerp(polo_nuevo, m).normalized()
		_ik_dos_huesos(hombro, codo, mano, muneca_anim.lerp(muneca_obj, m), polo)
	_fijar_basis_global(mano, Basis(q_mano) * _basis_reposo("hand_r"))
	_cerrar_puno(q_mano)

	# La linterna se coloca respecto de la mano ya posada.
	if conjunto_linterna == null:
		return
	var muneca := _pos("hand_r")
	var agarre := muneca + q_mano * (_d_rest * palma_adelante + _n_rest * palma_hacia_adentro) * _esc
	var eje_linterna := (q_mano * _u_rest).normalized()
	var arriba_l := (cam_base.y * m + (q_mano * -_n_rest) * (1.0 - m))
	if absf(arriba_l.normalized().dot(eje_linterna)) > 0.98:
		arriba_l = cam_base.x
	var orient := Basis.looking_at(eje_linterna, arriba_l.normalized())
	var base_pos := agarre - eje_linterna * mango_en_puno
	var en_esqueleto := Transform3D(orient, base_pos)
	var en_mundo := transformada_esq * en_esqueleto
	en_mundo.basis = en_mundo.basis.orthonormalized()
	conjunto_linterna.global_transform = en_mundo


func _cerrar_puno(q_mano: Quaternion) -> void:
	var eje := (q_mano * _eje_dedos).normalized()
	for dedo in DEDOS_DERECHA:
		for k in 3:
			var angulo := cierre_dedos[k]
			_girar_global(_idx["%s_0%d_r" % [dedo, k + 1]], Basis(eje, angulo))
	var eje_p := (q_mano * _eje_pulgar).normalized()
	for k in 3:
		_girar_global(_idx["thumb_0%d_r" % (k + 1)], Basis(eje_p, cierre_pulgar[k]))


# ------------------------------------------------------------------ utilidades

func _jugador_base() -> Basis:
	# Orientación del jugador (el nodo del que cuelga la cámara-cabeza).
	return cabeza_camara.get_parent().global_basis


func _vec_a_esq(v_mundo_o_jugador: Vector3) -> Vector3:
	# Convierte un vector expresado en el mundo al espacio del esqueleto.
	# Vector3.UP se interpreta como "arriba del mundo".
	return (_esq.global_transform.basis.inverse() * v_mundo_o_jugador).normalized()


func _pos(nombre: String) -> Vector3:
	return _esq.get_bone_global_pose(_idx[nombre]).origin


func _basis_reposo(nombre: String) -> Basis:
	var t: Transform3D = _rest[nombre]
	return t.basis.orthonormalized()


func _girar_global(hueso: int, r: Basis) -> void:
	var actual := _esq.get_bone_global_pose(hueso).basis.orthonormalized()
	_fijar_basis_global(hueso, r * actual)


func _fijar_basis_global(hueso: int, b: Basis) -> void:
	var padre := _esq.get_bone_parent(hueso)
	var base_padre := Basis.IDENTITY
	if padre >= 0:
		base_padre = _esq.get_bone_global_pose(padre).basis.orthonormalized()
	_esq.set_bone_pose_rotation(hueso, (base_padre.inverse() * b.orthonormalized()).get_rotation_quaternion())


func _mover_global(hueso: int, delta: Vector3) -> void:
	var padre := _esq.get_bone_parent(hueso)
	var base_padre := Basis.IDENTITY
	if padre >= 0:
		base_padre = _esq.get_bone_global_pose(padre).basis
	_esq.set_bone_pose_position(hueso, _esq.get_bone_pose_position(hueso) + base_padre.inverse() * delta)


func _alinear_hueso(hueso: int, desde: Vector3, hasta: Vector3) -> void:
	if desde.length() < 0.00001 or hasta.length() < 0.00001:
		return
	_girar_global(hueso, Basis(Quaternion(desde.normalized(), hasta.normalized())))


## IK analítico de dos huesos (hombro-codo-muñeca o cadera-rodilla-tobillo).
## "polo" indica hacia qué lado se dobla la articulación del medio.
func _ik_dos_huesos(a: int, b: int, c: int, objetivo: Vector3, polo: Vector3) -> void:
	var pa := _esq.get_bone_global_pose(a).origin
	var pb := _esq.get_bone_global_pose(b).origin
	var pc := _esq.get_bone_global_pose(c).origin
	var l1 := (pb - pa).length()
	var l2 := (pc - pb).length()
	if l1 < 0.001 or l2 < 0.001:
		return
	var hacia := objetivo - pa
	if hacia.length() < 0.001:
		return
	var dir := hacia.normalized()
	var d := clampf(hacia.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.005)
	var perp := polo - dir * polo.dot(dir)
	if perp.length() < 0.0001:
		perp = dir.cross(Vector3.UP)
	perp = perp.normalized()
	var x := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - x * x, 0.0))
	var codo := pa + dir * x + perp * h
	_alinear_hueso(a, pb - pa, codo - pa)
	var pb2 := _esq.get_bone_global_pose(b).origin
	var pc2 := _esq.get_bone_global_pose(c).origin
	_alinear_hueso(b, pc2 - pb2, (pa + dir * d) - pb2)
