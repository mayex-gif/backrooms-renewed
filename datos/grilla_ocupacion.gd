class_name GrillaOcupacion
extends RefCounted
## Registro de qué celdas del mundo están ocupadas y por qué sala.
## Es el "mapa mental" del generador: no tiene nodos, solo un diccionario.

# celda (Vector2i) -> id de la sala que la ocupa (int)
var _celdas: Dictionary = {}


## true si NINGUNA de las celdas está ocupada.
func esta_libre(celdas: Array[Vector2i]) -> bool:
	for c in celdas:
		if _celdas.has(c):
			return false
	return true


## Marca las celdas como ocupadas por la sala "id_sala".
func ocupar(celdas: Array[Vector2i], id_sala: int) -> void:
	for c in celdas:
		_celdas[c] = id_sala


## Libera las celdas (por ejemplo, al descargar una sala lejana).
func liberar(celdas: Array[Vector2i]) -> void:
	for c in celdas:
		_celdas.erase(c)


## Id de la sala que ocupa la celda, o -1 si está libre.
func id_en(celda: Vector2i) -> int:
	return _celdas.get(celda, -1)


func cantidad_ocupadas() -> int:
	return _celdas.size()
