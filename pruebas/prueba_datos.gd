@tool
extends EditorScript
## Pruebas de la capa de datos.
## Cómo correrlas: abrí este archivo en el editor de scripts de Godot y
## elegí Archivo > Ejecutar (o Ctrl+Mayús+X). El resultado sale en el panel "Salida".

var _fallos: int = 0


func _run() -> void:
	print("=== Pruebas de la capa de datos ===")
	_prueba_rotaciones()
	_prueba_union_de_salas()
	_prueba_choque_en_grilla()
	_prueba_anchos_distintos()
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


## Sala de 5 x 5 m (10 x 10 celdas) con un socket al norte, centrado.
func _sala_de_prueba() -> SalaDef:
	var s := SalaDef.new()
	s.nombre = "Prueba5x5"
	s.huella = SalaDef.huella_rectangular(10, 10)
	var sock := SocketDef.new()
	sock.posicion_local = Vector3(2.5, 0.0, 0.0)  # centro del borde norte
	sock.direccion = Direcciones.Dir.NORTE
	sock.ancho = 2.5
	s.sockets = [sock]
	return s


func _prueba_rotaciones() -> void:
	print("-- Rotaciones")
	_chequear(Direcciones.opuesta(Direcciones.Dir.NORTE) == Direcciones.Dir.SUR, "opuesta de NORTE es SUR")
	_chequear(Direcciones.girar(Direcciones.Dir.NORTE, 1) == Direcciones.Dir.ESTE, "un giro horario: NORTE -> ESTE")
	_chequear(Direcciones.girar(Direcciones.Dir.OESTE, 1) == Direcciones.Dir.NORTE, "un giro horario: OESTE -> NORTE")
	# Girar el vector NORTE (0,-1) una vez debe dar el vector ESTE (1,0).
	var p: Vector3 = Direcciones.rotar_punto(Vector3(0, 0, -1), 1)
	_chequear(p.is_equal_approx(Vector3(1, 0, 0)), "rotar_punto NORTE una vez da ESTE")
	# Cuatro giros dejan la celda donde estaba.
	_chequear(Direcciones.rotar_celda(Vector2i(3, 7), 4) == Vector2i(3, 7), "cuatro giros de una celda = la misma celda")
	# El área rotada debe tener la misma cantidad de celdas.
	_chequear(Direcciones.celda_de_punto(Vector3(0.49, 0, 0.51)) == Vector2i(0, 1), "celda_de_punto usa el piso (floor)")


func _prueba_union_de_salas() -> void:
	print("-- Unión de dos salas")
	var sala := _sala_de_prueba()
	# Puerta existente: en el borde ESTE de una sala A (que ocupa x 0..5, z 0..5),
	# centro en (5, 0, 2.5), mirando al ESTE.
	var col := Colocacion.calcular(sala, 0, Vector3(5, 0, 2.5), Direcciones.Dir.ESTE, 2.5)
	_chequear(col.giros == 3, "giros esperados = 3 (NORTE debe pasar a mirar OESTE)")
	_chequear(col.origen.is_equal_approx(Vector3(5, 0, 5)), "origen esperado (5, 0, 5), salió " + str(col.origen))
	_chequear(col.alineada, "el origen cae sobre la grilla")
	_chequear(col.celdas.size() == 100, "ocupa 100 celdas")
	_chequear(is_equal_approx(col.angulo_y, -1.5 * PI), "ángulo Y = -270° (-1.5 PI)")
	# La sala B debe ocupar x 5..10 m, z 0..5 m => celdas x 10..19, z 0..9.
	var min_x := 9999
	var max_x := -9999
	var min_z := 9999
	var max_z := -9999
	for c in col.celdas:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y)
		max_z = maxi(max_z, c.y)
	_chequear(min_x == 10 and max_x == 19 and min_z == 0 and max_z == 9,
			"celdas en x 10..19, z 0..9 (salió x %d..%d, z %d..%d)" % [min_x, max_x, min_z, max_z])
	# El socket de B, ya colocado, debe quedar exactamente sobre la puerta de A.
	var socket_b := sala.sockets[0]
	var pos_socket_b := col.origen + Direcciones.rotar_punto(socket_b.posicion_local, col.giros)
	_chequear(pos_socket_b.is_equal_approx(Vector3(5, 0, 2.5)), "los dos huecos coinciden en el mundo")


func _prueba_choque_en_grilla() -> void:
	print("-- Detección de choques")
	var sala := _sala_de_prueba()
	var grilla := GrillaOcupacion.new()
	# La sala A ocupa celdas 0..9 x 0..9.
	grilla.ocupar(SalaDef.huella_rectangular(10, 10), 1)
	var col := Colocacion.calcular(sala, 0, Vector3(5, 0, 2.5), Direcciones.Dir.ESTE, 2.5)
	_chequear(grilla.esta_libre(col.celdas), "B pegada a A (sin solaparse) está libre")
	grilla.ocupar(col.celdas, 2)
	_chequear(not grilla.esta_libre(col.celdas), "colocar B otra vez ahora choca")
	_chequear(grilla.id_en(Vector2i(0, 0)) == 1 and grilla.id_en(Vector2i(10, 0)) == 2, "ids de sala correctos por celda")
	_chequear(grilla.cantidad_ocupadas() == 200, "200 celdas ocupadas")
	grilla.liberar(col.celdas)
	_chequear(grilla.cantidad_ocupadas() == 100 and grilla.id_en(Vector2i(10, 0)) == -1, "liberar deja solo A")


func _prueba_anchos_distintos() -> void:
	print("-- Anchos distintos")
	var sala := _sala_de_prueba()  # socket de 2.5 m
	# Puerta existente de 5 m: el pasaje es de 2.5 m y sobra 1.25 m por lado.
	var col := Colocacion.calcular(sala, 0, Vector3(5, 0, 2.5), Direcciones.Dir.ESTE, 5.0)
	_chequear(is_equal_approx(col.ancho_pasaje, 2.5), "pasaje = el más angosto (2.5 m)")
	_chequear(is_equal_approx(col.relleno_por_lado, 1.25), "relleno por lado = 1.25 m")
	# Puerta existente de 1.5 m contra socket de 2.5 m: sobra 0.5 por lado.
	var col2 := Colocacion.calcular(sala, 0, Vector3(5, 0, 2.5), Direcciones.Dir.ESTE, 1.5)
	_chequear(is_equal_approx(col2.ancho_pasaje, 1.5), "pasaje = 1.5 m")
	_chequear(is_equal_approx(col2.relleno_por_lado, 0.5), "relleno por lado = 0.5 m")
