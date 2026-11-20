class_name GrillaOcupacion
extends RefCounted
## Registro espacial de huellas en metros; conserva wrappers para Rect2 antiguos.

var _huellas: Array[Dictionary] = []


## true si el rectángulo no se solapa con las salas registradas.
func esta_libre(rectangulo: Rect2, tolerancia: float = 0.001) -> bool:
	for entrada in _huellas:
		var existente: Rect2 = entrada.rectangulo
		var solapa_x := rectangulo.position.x < existente.end.x - tolerancia and rectangulo.end.x > existente.position.x + tolerancia
		var solapa_z := rectangulo.position.y < existente.end.y - tolerancia and rectangulo.end.y > existente.position.y + tolerancia
		if solapa_x and solapa_z and _poligonos_solapan(_rect_a_poligono(rectangulo), entrada.poligono, tolerancia):
			return false
	return true

func esta_libre_huella(poligono: PackedVector2Array, tolerancia: float = 0.001) -> bool:
	var limites_nuevos := GeometriaHuella.limites(poligono)
	for entrada in _huellas:
		var limites_existentes: Rect2 = entrada.rectangulo
		if limites_nuevos.position.x < limites_existentes.end.x - tolerancia and limites_nuevos.end.x > limites_existentes.position.x + tolerancia and limites_nuevos.position.y < limites_existentes.end.y - tolerancia and limites_nuevos.end.y > limites_existentes.position.y + tolerancia:
			if _poligonos_solapan(poligono, entrada.poligono, tolerancia):
				return false
	return true


## Registra el rectángulo con el id de sala indicado.
func ocupar(rectangulo: Rect2, id_sala: int) -> void:
	ocupar_huella(_rect_a_poligono(rectangulo), id_sala)

func ocupar_huella(poligono: PackedVector2Array, id_sala: int) -> void:
	_huellas.append({"rectangulo": GeometriaHuella.limites(poligono), "poligono": poligono.duplicate(), "id": id_sala})


## Libera un rectángulo (por ejemplo, al descargar una sala lejana).
func liberar(rectangulo: Rect2) -> void:
	for i in range(_huellas.size() - 1, -1, -1):
		if _huellas[i].rectangulo == rectangulo:
			_huellas.remove_at(i)


## Id de la sala que contiene el punto, o -1 si está libre.
func id_en(punto: Vector2) -> int:
	for entrada in _huellas:
		if GeometriaHuella.contiene(entrada.poligono, punto):
			return entrada.id
	return -1


func cantidad_ocupadas() -> int:
	return _huellas.size()

func _rect_a_poligono(rectangulo: Rect2) -> PackedVector2Array:
	var poligono := GeometriaHuella.rectangulo(rectangulo.size.x, rectangulo.size.y)
	for indice in poligono.size():
		poligono[indice] += rectangulo.position
	return poligono

func _poligonos_solapan(a: PackedVector2Array, b: PackedVector2Array, tolerancia: float) -> bool:
	for poligono in [a, b]:
		for indice in poligono.size():
			var eje := (poligono[(indice + 1) % poligono.size()] - poligono[indice]).orthogonal().normalized()
			var proyeccion_a := _proyectar(a, eje)
			var proyeccion_b := _proyectar(b, eje)
			if proyeccion_a.y <= proyeccion_b.x + tolerancia or proyeccion_b.y <= proyeccion_a.x + tolerancia:
				return false
	return true

func _proyectar(poligono: PackedVector2Array, eje: Vector2) -> Vector2:
	var minimo := poligono[0].dot(eje)
	var maximo := minimo
	for punto in poligono:
		minimo = minf(minimo, punto.dot(eje))
		maximo = maxf(maximo, punto.dot(eje))
	return Vector2(minimo, maximo)
