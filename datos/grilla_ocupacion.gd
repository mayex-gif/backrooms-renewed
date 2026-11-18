class_name GrillaOcupacion
extends RefCounted
## Registro de rectángulos ocupados en metros. Las salas están alineadas a ejes.

var _rectangulos: Array[Dictionary] = []


## true si el rectángulo no se solapa con las salas registradas.
func esta_libre(rectangulo: Rect2, tolerancia: float = 0.001) -> bool:
	for entrada in _rectangulos:
		var existente: Rect2 = entrada.rectangulo
		var solapa_x := rectangulo.position.x < existente.end.x - tolerancia and rectangulo.end.x > existente.position.x + tolerancia
		var solapa_z := rectangulo.position.y < existente.end.y - tolerancia and rectangulo.end.y > existente.position.y + tolerancia
		if solapa_x and solapa_z:
			return false
	return true


## Registra el rectángulo con el id de sala indicado.
func ocupar(rectangulo: Rect2, id_sala: int) -> void:
	_rectangulos.append({"rectangulo": rectangulo, "id": id_sala})


## Libera un rectángulo (por ejemplo, al descargar una sala lejana).
func liberar(rectangulo: Rect2) -> void:
	for i in range(_rectangulos.size() - 1, -1, -1):
		if _rectangulos[i].rectangulo == rectangulo:
			_rectangulos.remove_at(i)


## Id de la sala que contiene el punto, o -1 si está libre.
func id_en(punto: Vector2) -> int:
	for entrada in _rectangulos:
		if entrada.rectangulo.has_point(punto):
			return entrada.id
	return -1


func cantidad_ocupadas() -> int:
	return _rectangulos.size()
