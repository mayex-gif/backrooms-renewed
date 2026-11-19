@tool
extends EditorScript
## Pruebas de ConexionesMapa: las puertas que se generan entre los módulos de un
## mapa personalizado. Se corre igual que prueba_datos.gd: abrir este archivo en
## el editor de scripts y elegir Archivo > Ejecutar (Ctrl+Mayús+X).

const ConexionesMapaScript = preload("res://datos/conexiones_mapa.gd")

var _fallos := 0


func _run() -> void:
	print("=== Pruebas de ConexionesMapa ===")
	_prueba_union_horizontal()
	_prueba_union_vertical()
	_prueba_largo_compartido()
	_prueba_huecos()
	_prueba_pared_completa()
	_prueba_circulares_y_varias_salas()
	_prueba_solapes()
	if _fallos == 0:
		print("=== TODO OK ===")
	else:
		print("=== HAY ", _fallos, " FALLOS ===")


func _chequear(condicion: bool, texto: String) -> void:
	if condicion:
		print("  OK     ", texto)
	else:
		print("  FALLÓ  ", texto)
		_fallos += 1


## Un módulo para ConexionesMapa: rectángulo en metros (x, z, ancho, largo).
func _m(x: float, z: float, ancho: float, largo: float, circular: bool = false) -> Dictionary:
	return {"rect": Rect2(x, z, ancho, largo), "circular": circular}


func _prueba_union_horizontal() -> void:
	print("-- Salas una al lado de la otra")
	var modulos: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 5, 5)]
	var c := ConexionesMapaScript.calcular(modulos, false)
	_chequear(c.size() == 1, "dos salas pegadas generan 1 puerta")
	_chequear(c[0].dir_a == Direcciones.Dir.ESTE and c[0].dir_b == Direcciones.Dir.OESTE, "A mira al ESTE y B al OESTE")
	_chequear(c[0].punto_a == Vector2(5, 2.5) and c[0].punto_b == Vector2(5, 2.5), "ambos centros de puerta en (5; 2,5)")
	_chequear(is_equal_approx(c[0].ancho, 3.5), "ancho máximo de 3,5 m")
	_chequear(not c[0].completa, "sin la opción, la pared no se abre entera")
	_chequear(is_equal_approx(c[0].separacion, 0.0), "separación 0")


func _prueba_union_vertical() -> void:
	print("-- Salas una sobre la otra")
	var modulos: Array[Dictionary] = [_m(0, 0, 5, 5), _m(0, 5, 5, 5)]
	var c := ConexionesMapaScript.calcular(modulos, false)
	_chequear(c.size() == 1, "1 puerta")
	_chequear(c[0].dir_a == Direcciones.Dir.SUR and c[0].dir_b == Direcciones.Dir.NORTE, "A (arriba) mira al SUR y B al NORTE")
	_chequear(c[0].punto_a == Vector2(2.5, 5), "centro de la puerta en (2,5; 5)")
	var invertido: Array[Dictionary] = [_m(0, 5, 5, 5), _m(0, 0, 5, 5)]
	var c2 := ConexionesMapaScript.calcular(invertido, false)
	_chequear(c2[0].dir_a == Direcciones.Dir.NORTE and c2[0].dir_b == Direcciones.Dir.SUR, "si A está abajo, A mira al NORTE")


func _prueba_largo_compartido() -> void:
	print("-- Largo de pared compartida")
	var desfasadas: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 2, 5, 5)]
	var c := ConexionesMapaScript.calcular(desfasadas, false)
	_chequear(c.size() == 1 and is_equal_approx(c[0].ancho, 3.0), "pared compartida de 3 m: puerta de 3 m")
	_chequear(is_equal_approx(c[0].punto_a.y, 3.5), "la puerta queda centrada en la parte compartida (z = 3,5)")
	var esquina: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 5, 5, 5)]
	_chequear(ConexionesMapaScript.calcular(esquina, false).is_empty(), "solo se tocan en una esquina: sin puerta")
	var corta: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 4, 5, 5)]
	_chequear(ConexionesMapaScript.calcular(corta, false).is_empty(), "1,0 m compartido: sin puerta")
	var justa: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 3.5, 5, 5)]
	var cj := ConexionesMapaScript.calcular(justa, false)
	_chequear(cj.size() == 1 and is_equal_approx(cj[0].ancho, 1.5), "1,5 m compartidos: puerta de 1,5 m")


func _prueba_huecos() -> void:
	print("-- Huecos entre salas")
	var hueco: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5.5, 0, 5, 5)]
	var c := ConexionesMapaScript.calcular(hueco, false)
	_chequear(c.size() == 1 and is_equal_approx(c[0].separacion, 0.5), "hueco de 0,5 m: hay puerta y separación 0,5")
	_chequear(c[0].punto_a == Vector2(5, 2.5) and c[0].punto_b == Vector2(5.5, 2.5), "cada puerta queda sobre su propia pared")
	var lejos: Array[Dictionary] = [_m(0, 0, 5, 5), _m(6.5, 0, 5, 5)]
	_chequear(ConexionesMapaScript.calcular(lejos, false).is_empty(), "hueco de 1,5 m: sin puerta")


func _prueba_pared_completa() -> void:
	print("-- Pared completa abierta")
	var iguales: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 5, 5)]
	_chequear(ConexionesMapaScript.calcular(iguales, true)[0].completa, "misma medida y alineadas: se abre toda la pared")
	var desalineadas: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 2, 5, 5)]
	_chequear(not ConexionesMapaScript.calcular(desalineadas, true)[0].completa, "desalineadas: queda una puerta común")
	var distintas: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 5, 7.5)]
	_chequear(not ConexionesMapaScript.calcular(distintas, true)[0].completa, "distinto largo de pared: queda una puerta común")
	var verticales: Array[Dictionary] = [_m(0, 0, 7.5, 5), _m(0, 5, 7.5, 5)]
	_chequear(ConexionesMapaScript.calcular(verticales, true)[0].completa, "también en vertical")


func _prueba_circulares_y_varias_salas() -> void:
	print("-- Circulares y varias salas")
	var con_circular: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 10, 10, true)]
	_chequear(ConexionesMapaScript.calcular(con_circular, false).is_empty(), "las salas circulares todavía no reciben puertas")
	var en_l: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 5, 5), _m(0, 5, 5, 5)]
	var c := ConexionesMapaScript.calcular(en_l, false)
	_chequear(c.size() == 2, "tres salas en L: 2 puertas")
	_chequear(c[0].a == 0 and c[0].b == 1 and c[1].a == 0 and c[1].b == 2, "índices a/b apuntan a los módulos correctos")


func _prueba_solapes() -> void:
	print("-- Superposiciones")
	var solapadas: Array[Dictionary] = [_m(0, 0, 5, 5), _m(3, 3, 5, 5), _m(20, 20, 5, 5)]
	var pares := ConexionesMapaScript.pares_solapados(solapadas)
	_chequear(pares.size() == 1 and pares[0] == Vector2i(0, 1), "se detecta el par (0, 1) y se ignora la sala lejana")
	var tocandose: Array[Dictionary] = [_m(0, 0, 5, 5), _m(5, 0, 5, 5)]
	_chequear(ConexionesMapaScript.pares_solapados(tocandose).is_empty(), "tocarse por el borde no es superponerse")
