@tool
extends EditorScript
## Comprueba reproducibilidad, variedad y límites de ocupación del generador.

const SEMILLAS: Array[int] = [1, 42, 20261117, 987654321]
const MAX_SALAS := 40

var fallos := 0

func _run() -> void:
	print("=== Pruebas del generador procedural ===")
	var catalogo_script: Script = load("res://salas/catalogo_salas.gd")
	var definiciones: Array[SalaDef] = catalogo_script.call("crear") as Array[SalaDef]
	var huellas: Dictionary = {}
	for semilla in SEMILLAS:
		var primera := GeneradorProcedural.new().generar(definiciones, semilla, MAX_SALAS)
		var segunda := GeneradorProcedural.new().generar(definiciones, semilla, MAX_SALAS)
		var huella_primera := _huella(primera)
		var huella_segunda := _huella(segunda)
		_chequear(huella_primera == huella_segunda, "semilla %d repite distribución" % semilla)
		_chequear(not primera.salas.is_empty(), "semilla %d genera salas" % semilla)
		_chequear(primera.salas.size() <= MAX_SALAS, "semilla %d respeta máximo" % semilla)
		_chequear(_rectangulos_sin_solape(primera.salas), "semilla %d no solapa rectángulos" % semilla)
		if primera.salas.size() < MAX_SALAS:
			_chequear(primera.pendientes == 0, "semilla %d termina al agotar conexiones" % semilla)
		huellas[huella_primera] = true
	_chequear(huellas.size() > 1, "semillas distintas producen mapas distintos")
	if fallos == 0:
		print("=== GENERADOR OK ===")
	else:
		print("=== GENERADOR: %d FALLOS ===" % fallos)

func _huella(resultado: Dictionary) -> String:
	var filas := PackedStringArray()
	for ubicacion in resultado.salas:
		var sala: SalaDef = ubicacion.sala
		filas.append("%s@%s/g%d" % [sala.nombre, ubicacion.origen, ubicacion.giros])
	return " | ".join(filas)

func _rectangulos_sin_solape(salas: Array) -> bool:
	for i in salas.size():
		for j in range(i + 1, salas.size()):
			if salas[i].rectangulo.intersects(salas[j].rectangulo, false):
				return false
	return true

func _chequear(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK     ", descripcion)
	else:
		print("  FALLÓ  ", descripcion)
		fallos += 1
