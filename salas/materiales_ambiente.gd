extends RefCounted
## Materiales compartidos de las superficies arquitectónicas del nivel.
## Paredes y piso usan proyección "triplanar" en coordenadas de mundo: no necesitan
## UVs, la textura no se estira en las paredes largas y continúa entre salas.
## Si falta una textura se usa un color liso parecido (el juego no se rompe).

const PARED := "pared"
const PLACA_TECHO := "placa_techo"
## Placa cortada por una pared: sin el borde dibujado, para que no se vea mal recortada.
const PLACA_RECORTADA := "placa_recortada"
const YESO := "yeso"
const PISO := "piso"
const VIDRIO := "vidrio"
const PLENUM := "plenum"

const CARPETA := "res://assets/texturas/backrooms/"
## Metros que abarca una repetición de la textura de alfombra.
const METROS_PARED := 1.0
const METROS_PISO := 1.3
## Multiplican el color de la textura. El piso es el mismo dibujo, más oscuro.
const TINTE_PARED := Color(1.0, 1.0, 1.0)
const TINTE_PISO := Color(0.66, 0.56, 0.36)
const BRILLO_PLACA := 1.0
const VARIANTES_PLACA := 3

## Material de pared original del proyecto (alfombra en shader).
const MATERIAL_PARED: Material = preload("res://assets/texturas/Carpet001/Carpet001_1K-JPG.tres")
const MATERIAL_YESO: StandardMaterial3D = preload("res://assets/texturas/YesoPintado.tres")
const MATERIAL_VIDRIO: StandardMaterial3D = preload("res://assets/texturas/VidrioVentana.tres")
const MATERIAL_PLENUM: StandardMaterial3D = preload("res://assets/texturas/PlenumOscuro.tres")

static var _cache: Dictionary = {}


## "semilla" solo importa para PLACA_TECHO: elige entre placa limpia o manchada.
static func aplicar(visual: MeshInstance3D, tipo: String, semilla: int = 0) -> void:
	match tipo:
		PARED:
			visual.material_override = MATERIAL_PARED
		PISO:
			visual.material_override = _alfombra("piso", METROS_PISO, TINTE_PISO)
		PLACA_TECHO:
			visual.material_override = _placa(_variante(semilla))
		PLACA_RECORTADA:
			visual.material_override = _placa_recortada()
		YESO:
			visual.material_override = MATERIAL_YESO
		VIDRIO:
			visual.material_override = MATERIAL_VIDRIO
		PLENUM:
			visual.material_override = MATERIAL_PLENUM


## 70 % de placas limpias, 20 % con una mancha leve y 10 % con una marcada.
static func _variante(semilla: int) -> int:
	var valor := absi(semilla) % 10
	if valor < 7:
		return 0
	return 1 if valor < 9 else 2


static func _textura(archivo: String) -> Texture2D:
	var ruta := CARPETA + archivo
	if not ResourceLoader.exists(ruta):
		return null
	return load(ruta) as Texture2D


static func _alfombra(clave: String, metros: float, tinte: Color) -> StandardMaterial3D:
	if _cache.has(clave):
		return _cache[clave]
	var material := StandardMaterial3D.new()
	var color := _textura("alfombra_color.jpg")
	if color != null:
		material.albedo_texture = color
		material.albedo_color = tinte
	else:
		material.albedo_color = Color(0.58, 0.47, 0.24) * tinte
	var normal := _textura("alfombra_normal.png")
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
	var rugosidad := _textura("alfombra_rugosidad.jpg")
	if rugosidad != null:
		material.roughness_texture = rugosidad
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 1.0 if rugosidad != null else 0.92
	material.metallic_specular = 0.2
	var escala := 1.0 / maxf(metros, 0.01)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(escala, escala, escala)
	_cache[clave] = material
	return material


## Placa completa de 1,5 m: una imagen por placa (usa las UV de la caja).
static func _placa(variante: int) -> StandardMaterial3D:
	var clave := "placa_%d" % variante
	if _cache.has(clave):
		return _cache[clave]
	var material := StandardMaterial3D.new()
	var color := _textura("techo_placa_%d_color.jpg" % variante)
	if color != null:
		material.albedo_texture = color
		material.albedo_color = Color(BRILLO_PLACA, BRILLO_PLACA, BRILLO_PLACA)
	else:
		material.albedo_color = Color(0.86, 0.845, 0.78) * BRILLO_PLACA
	var normal := _textura("techo_placa_normal.png")
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
	var rugosidad := _textura("techo_placa_rugosidad.jpg")
	if rugosidad != null:
		material.roughness_texture = rugosidad
		material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.roughness = 1.0 if rugosidad != null else 0.9
	_cache[clave] = material
	return material


static func _placa_recortada() -> StandardMaterial3D:
	if _cache.has("placa_recortada"):
		return _cache["placa_recortada"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.84, 0.82, 0.76) * BRILLO_PLACA
	material.roughness = 0.92
	_cache["placa_recortada"] = material
	return material
