extends RefCounted
## Materiales compartidos de las superficies arquitectónicas del nivel.

const PARED := "pared"
const PLACA_TECHO := "placa_techo"
const YESO := "yeso"
const PISO := "piso"
const VIDRIO := "vidrio"
const PLENUM := "plenum"

const MATERIAL_PARED: Material = preload("res://assets/texturas/Carpet001/Carpet001_1K-JPG.tres")
const MATERIAL_TECHO: Material = preload("res://assets/texturas/CeilingTiles0013/CeilingTiles0013.tres")
const MATERIAL_YESO: StandardMaterial3D = preload("res://assets/texturas/YesoPintado.tres")
const MATERIAL_PISO: StandardMaterial3D = preload("res://assets/texturas/Piso.tres")
const MATERIAL_VIDRIO: StandardMaterial3D = preload("res://assets/texturas/VidrioVentana.tres")
const MATERIAL_PLENUM: StandardMaterial3D = preload("res://assets/texturas/PlenumOscuro.tres")

static func aplicar(visual: MeshInstance3D, tipo: String) -> void:
	match tipo:
		PARED:
			visual.material_override = MATERIAL_PARED
		PLACA_TECHO:
			visual.material_override = MATERIAL_TECHO
		YESO:
			visual.material_override = MATERIAL_YESO
		PISO:
			visual.material_override = MATERIAL_PISO
		VIDRIO:
			visual.material_override = MATERIAL_VIDRIO
		PLENUM:
			visual.material_override = MATERIAL_PLENUM
