class_name Colocacion
extends RefCounted
## Resultado de "¿dónde caería esta sala si la conecto a esa puerta?".
## Se calcula SOLO con matemática, sin instanciar la escena. Así se puede
## probar si choca (con la GrillaOcupacion) antes de crear ningún nodo.

## Cuántos giros de 90° horarios hay que darle a la sala (0 a 3).
var giros: int = 0
## Ángulo en radianes para asignar a rotation.y de la escena.
var angulo_y: float = 0.0
## Posición del origen de la sala en el mundo (metros).
var origen: Vector3 = Vector3.ZERO
## Celdas del mundo que ocuparía la sala.
var celdas: Array[Vector2i] = []
## false si el origen no cae sobre la grilla (el diseño de la sala está desalineado).
var alineada: bool = true
## Ancho real del pasaje: el del hueco más angosto de los dos.
var ancho_pasaje: float = 0.0
## Pared de relleno que falta a CADA lado del pasaje, en el hueco más ancho.
var relleno_por_lado: float = 0.0


## sala:           la sala candidata.
## indice_socket:  cuál de sus sockets se usaría para conectar.
## destino_pos:    centro de la puerta existente, en el mundo (metros).
## destino_dir:    hacia dónde mira esa puerta existente (hacia afuera).
## ancho_destino:  ancho de la puerta existente (metros).
static func calcular(
		sala: SalaDef,
		indice_socket: int,
		destino_pos: Vector3,
		destino_dir: Direcciones.Dir,
		ancho_destino: float) -> Colocacion:
	var c := Colocacion.new()
	var socket: SocketDef = sala.sockets[indice_socket]

	# 1. El socket nuevo debe mirar al lado contrario que la puerta existente.
	c.giros = posmod((destino_dir + 2) - socket.direccion, 4)
	c.angulo_y = -c.giros * PI / 2.0  # en Godot, rotation.y positivo es antihorario

	# 2. Los centros de ambos huecos deben coincidir (queda centrado).
	c.origen = destino_pos - Direcciones.rotar_punto(socket.posicion_local, c.giros)

	# 3. Celdas del mundo: origen (ajustado a la grilla) + huella rotada.
	var tam: float = Direcciones.TAMANO_CELDA
	var ox: float = c.origen.x / tam
	var oz: float = c.origen.z / tam
	c.alineada = absf(ox - roundf(ox)) < 0.01 and absf(oz - roundf(oz)) < 0.01
	var origen_celda := Vector2i(roundi(ox), roundi(oz))
	for celda_local in sala.huella:
		c.celdas.append(origen_celda + Direcciones.rotar_celda(celda_local, c.giros))

	# 4. Si los anchos difieren, sobra pared a cada lado del pasaje.
	c.ancho_pasaje = minf(socket.ancho, ancho_destino)
	c.relleno_por_lado = (maxf(socket.ancho, ancho_destino) - c.ancho_pasaje) / 2.0
	return c
