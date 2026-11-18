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

@export_group("Reglas de generación")
## Probabilidad relativa: 100 = común, 10 = rara, 1 = rarísima.
@export var peso: float = 100.0
## Cuántas veces puede aparecer en toda la partida. 0 = sin límite.
@export var limite_maximo: int = 0

@export_group("Forma")
@export var sockets: Array[SocketDef] = []
@export var columnas_locales: Array[Vector3] = []


## Devuelve errores de forma/datos que deben corregirse antes de generar.
## Los sockets deben estar sobre el perímetro del rectángulo envolvente.
func validar_forma() -> PackedStringArray:
	var errores := PackedStringArray()
	if not is_finite(ancho_m) or ancho_m <= 0.0 or not is_finite(largo_m) or largo_m <= 0.0:
		errores.append("El ancho y el largo deben ser finitos y mayores que cero.")
		return errores
	var borde_min_x := 0.0
	var borde_max_x := ancho_m
	var borde_min_z := 0.0
	var borde_max_z := largo_m
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
			errores.append("El socket %d excede el ancho del borde de la sala." % indice)
			continue
		for otro_indice in range(indice + 1, sockets.size()):
			var otro: SocketDef = sockets[otro_indice]
			if otro == null or otro.direccion != socket.direccion:
				continue
			var centro_otro := otro.posicion_local.x if socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR else otro.posicion_local.z
			if absf(centro_lateral - centro_otro) < (socket.ancho + otro.ancho) * 0.5 - 0.001:
				errores.append("Los sockets %d y %d se superponen en el mismo borde." % [indice, otro_indice])
	return errores
