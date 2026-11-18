class_name SalaDef
extends Resource
## Definición de un tipo de sala: qué escena usa, cuánto espacio ocupa
## (huella), por dónde se conecta (sockets) y cuán seguido aparece.
## Se guarda como recurso (.tres) y se arma desde el Inspector.

@export var nombre: String = "Sala"
@export var escena: PackedScene
@export var ancho_m: float = 5.0
@export var largo_m: float = 5.0
@export var alto_m: float = 4.2

@export_group("Reglas de generación")
## Probabilidad relativa: 100 = común, 10 = rara, 1 = rarísima.
@export var peso: float = 100.0
## Cuántas veces puede aparecer en toda la partida. 0 = sin límite.
@export var limite_maximo: int = 0

@export_group("Forma")
## Celdas que ocupa, en coordenadas locales. La celda (i, j) cubre desde
## (i * 0.5 m, j * 0.5 m) hasta ((i+1) * 0.5 m, (j+1) * 0.5 m).
@export var huella: Array[Vector2i] = []
@export var sockets: Array[SocketDef] = []
@export var columnas_locales: Array[Vector3] = []


## Atajo: huella rectangular con la esquina mínima en el origen de la sala.
## Ejemplo: una sala de 5 x 5 metros son 10 x 10 celdas.
static func huella_rectangular(columnas: int, filas: int) -> Array[Vector2i]:
	var celdas: Array[Vector2i] = []
	for i in columnas:
		for j in filas:
			celdas.append(Vector2i(i, j))
	return celdas

## Aproxima una sala circular conservadoramente: ocupa cada celda que intersecta el radio.
## El origen es la esquina del cuadrado envolvente, igual que en la huella rectangular.
static func huella_circular(radio_celdas: int) -> Array[Vector2i]:
	var celdas: Array[Vector2i] = []
	var diametro := radio_celdas * 2
	var centro := Vector2(float(diametro) * 0.5, float(diametro) * 0.5)
	for x in diametro:
		for z in diametro:
			var punto_cercano := Vector2(
				clampf(centro.x, float(x), float(x + 1)),
				clampf(centro.y, float(z), float(z + 1))
			)
			if punto_cercano.distance_to(centro) <= radio_celdas:
				celdas.append(Vector2i(x, z))
	return celdas


## Devuelve errores de forma/datos que deben corregirse antes de generar.
## Los sockets de este prototipo deben estar en el perímetro del rectángulo
## que contiene la huella; la validación de contornos irregulares queda pendiente.
func validar_forma() -> PackedStringArray:
	var errores := PackedStringArray()
	if huella.is_empty():
		errores.append("La huella está vacía.")
		return errores
	var celdas_vistas: Dictionary = {}
	var min_x := huella[0].x
	var max_x := huella[0].x
	var min_z := huella[0].y
	var max_z := huella[0].y
	for celda in huella:
		if celdas_vistas.has(celda):
			errores.append("La huella repite la celda %s." % celda)
		else:
			celdas_vistas[celda] = true
		min_x = mini(min_x, celda.x)
		max_x = maxi(max_x, celda.x)
		min_z = mini(min_z, celda.y)
		max_z = maxi(max_z, celda.y)
	var escala := Direcciones.TAMANO_CELDA
	var borde_min_x := min_x * escala
	var borde_max_x := (max_x + 1) * escala
	var borde_min_z := min_z * escala
	var borde_max_z := (max_z + 1) * escala
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
		var sobre_borde := false
		var centro_lateral := 0.0
		var inicio_lateral := 0.0
		var fin_lateral := 0.0
		match socket.direccion:
			Direcciones.Dir.NORTE:
				sobre_borde = is_equal_approx(socket.posicion_local.z, borde_min_z)
				centro_lateral = socket.posicion_local.x
				inicio_lateral = borde_min_x
				fin_lateral = borde_max_x
			Direcciones.Dir.SUR:
				sobre_borde = is_equal_approx(socket.posicion_local.z, borde_max_z)
				centro_lateral = socket.posicion_local.x
				inicio_lateral = borde_min_x
				fin_lateral = borde_max_x
			Direcciones.Dir.ESTE:
				sobre_borde = is_equal_approx(socket.posicion_local.x, borde_max_x)
				centro_lateral = socket.posicion_local.z
				inicio_lateral = borde_min_z
				fin_lateral = borde_max_z
			Direcciones.Dir.OESTE:
				sobre_borde = is_equal_approx(socket.posicion_local.x, borde_min_x)
				centro_lateral = socket.posicion_local.z
				inicio_lateral = borde_min_z
				fin_lateral = borde_max_z
			_:
				errores.append("El socket %d tiene una dirección inválida." % indice)
				continue
		if not sobre_borde:
			errores.append("El socket %d no está en el borde que indica su dirección." % indice)
			continue
		var mitad := socket.ancho * 0.5
		if centro_lateral - mitad < inicio_lateral - 0.001 or centro_lateral + mitad > fin_lateral + 0.001:
			errores.append("El socket %d excede el ancho del borde de la huella." % indice)
			continue
		for otro_indice in range(indice + 1, sockets.size()):
			var otro: SocketDef = sockets[otro_indice]
			if otro == null or otro.direccion != socket.direccion:
				continue
			var centro_otro := otro.posicion_local.x if socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR else otro.posicion_local.z
			if absf(centro_lateral - centro_otro) < (socket.ancho + otro.ancho) * 0.5 - 0.001:
				errores.append("Los sockets %d y %d se superponen en el mismo borde." % [indice, otro_indice])
	return errores
