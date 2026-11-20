class_name SalaDef
extends Resource
## Definición de un tipo de sala: qué escena usa, cuánto espacio ocupa
## (dimensiones), por dónde se conecta (sockets) y cuán seguido aparece.
## Se guarda como recurso (.tres) y se arma desde el Inspector.

@export var nombre: String = "Sala"
@export var escena: PackedScene
@export var ancho_m: float = 5.0
@export var largo_m: float = 5.0
@export var alto_m: float = 4.2
## Contorno convexo local X/Z. Vacío usa el rectángulo definido por ancho/largo.
@export var huella_local: PackedVector2Array = PackedVector2Array()

@export_group("Reglas de generación")
## Probabilidad relativa: 100 = común, 10 = rara, 1 = rarísima.
@export var peso: float = 100.0
## Cuántas veces puede aparecer en toda la partida. 0 = sin límite.
@export var limite_maximo: int = 0

@export_group("Forma")
@export var sockets: Array[SocketDef] = []
@export var columnas_locales: Array[Vector3] = []

func obtener_huella_local() -> PackedVector2Array:
	if huella_local.size() >= 3:
		return GeometriaHuella.normalizar(huella_local)
	return GeometriaHuella.rectangulo(ancho_m, largo_m)

func obtener_arista_socket(socket: SocketDef) -> int:
	return _arista_socket(socket, obtener_huella_local())

func largo_arista_socket(socket: SocketDef) -> float:
	var huella := obtener_huella_local()
	var indice := obtener_arista_socket(socket)
	if indice < 0:
		return 0.0
	return huella[indice].distance_to(huella[(indice + 1) % huella.size()])


## Devuelve errores de forma/datos que deben corregirse antes de generar.
## Los sockets deben estar sobre una arista real de la huella.
func validar_forma() -> PackedStringArray:
	var errores := PackedStringArray()
	if not is_finite(ancho_m) or ancho_m <= 0.0 or not is_finite(largo_m) or largo_m <= 0.0:
		errores.append("El ancho y el largo deben ser finitos y mayores que cero.")
		return errores
	if not huella_local.is_empty():
		if huella_local.size() < 3 or absf(GeometriaHuella.area_firmada(huella_local)) <= GeometriaHuella.EPSILON:
			errores.append("La huella debe tener al menos tres vértices y área positiva.")
			return errores
		if GeometriaHuella.area_firmada(huella_local) < 0.0:
			errores.append("Los vértices de la huella deben recorrer el contorno en sentido antihorario.")
		if not _huella_convexa(huella_local):
			errores.append("La huella debe ser convexa.")
		var limites := GeometriaHuella.limites(huella_local)
		if limites.position.x < -0.001 or limites.position.y < -0.001 or limites.end.x > ancho_m + 0.001 or limites.end.y > largo_m + 0.001:
			errores.append("La huella debe quedar dentro del rectángulo de ancho/largo.")
	var huella := obtener_huella_local()
	for indice in sockets.size():
		var socket := sockets[indice]
		if socket == null:
			errores.append("El socket %d no tiene recurso asignado." % indice)
			continue
		if not is_finite(socket.posicion_local.x) or not is_finite(socket.posicion_local.y) or not is_finite(socket.posicion_local.z):
			errores.append("El socket %d tiene una posición no finita." % indice)
			continue
		if not is_finite(socket.ancho) or socket.ancho <= 0.0:
			errores.append("El socket %d debe tener ancho mayor que cero." % indice)
			continue
		if absf(socket.posicion_local.y) > 0.001:
			errores.append("El socket %d no está a nivel del piso." % indice)
		if socket.arista >= 0 and not is_finite(socket.rotacion_pared):
			errores.append("El socket %d debe definir una rotación de pared finita." % indice)
		var arista_socket := _arista_socket(socket, huella)
		if arista_socket < 0:
			errores.append("El socket %d no está sobre una arista de la huella." % indice)
			continue
		var inicio_arista := huella[arista_socket]
		var fin_arista := huella[(arista_socket + 1) % huella.size()]
		var eje_arista := (fin_arista - inicio_arista).normalized()
		var centro_socket := Vector2(socket.posicion_local.x, socket.posicion_local.z)
		var lateral := (centro_socket - inicio_arista).dot(eje_arista)
		var largo_arista := inicio_arista.distance_to(fin_arista)
		if lateral - socket.ancho * 0.5 < -0.001 or lateral + socket.ancho * 0.5 > largo_arista + 0.001:
			errores.append("El socket %d excede el largo de su arista." % indice)
			continue
		for otro_indice in range(indice + 1, sockets.size()):
			var otro: SocketDef = sockets[otro_indice]
			if otro == null or _arista_socket(otro, huella) != arista_socket:
				continue
			var lateral_otro := (Vector2(otro.posicion_local.x, otro.posicion_local.z) - inicio_arista).dot(eje_arista)
			if absf(lateral - lateral_otro) < (socket.ancho + otro.ancho) * 0.5 - 0.001:
				errores.append("Los sockets %d y %d se superponen en el mismo borde." % [indice, otro_indice])
	return errores

func _arista_socket(socket: SocketDef, huella: PackedVector2Array) -> int:
	if socket.arista >= 0:
		if socket.arista >= huella.size():
			return -1
		var inicio := huella[socket.arista]
		var fin := huella[(socket.arista + 1) % huella.size()]
		return socket.arista if Geometry2D.get_closest_point_to_segment(Vector2(socket.posicion_local.x, socket.posicion_local.z), inicio, fin).distance_to(Vector2(socket.posicion_local.x, socket.posicion_local.z)) <= 0.001 else -1
	for arista in huella.size():
		var inicio := huella[arista]
		var fin := huella[(arista + 1) % huella.size()]
		if Geometry2D.get_closest_point_to_segment(Vector2(socket.posicion_local.x, socket.posicion_local.z), inicio, fin).distance_to(Vector2(socket.posicion_local.x, socket.posicion_local.z)) > 0.001:
			continue
		var eje := (fin - inicio).normalized()
		var normal_exterior := Vector2(eje.y, -eje.x)
		var direccion_esperada := Vector2(0, -1).rotated(float(socket.direccion) * PI / 2.0)
		if normal_exterior.dot(direccion_esperada) > 0.999:
			return arista
	return -1

func _huella_convexa(puntos: PackedVector2Array) -> bool:
	var orientacion := 0.0
	for indice in puntos.size():
		var ab := puntos[(indice + 1) % puntos.size()] - puntos[indice]
		var bc := puntos[(indice + 2) % puntos.size()] - puntos[(indice + 1) % puntos.size()]
		var cruz := ab.x * bc.y - ab.y * bc.x
		if absf(cruz) <= 0.001:
			continue
		if orientacion == 0.0:
			orientacion = signf(cruz)
		elif signf(cruz) != orientacion:
			return false
	return orientacion > 0.0
