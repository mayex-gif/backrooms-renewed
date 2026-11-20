class_name Colocacion
extends RefCounted
## Alinea una arista de una sala con un socket existente sin instanciar nodos.

var giros: int = 0
var angulo_y: float = 0.0
var origen: Vector3 = Vector3.ZERO
var rectangulo: Rect2 = Rect2()
var huella_mundo: PackedVector2Array = PackedVector2Array()
var ancho_pasaje: float = 0.0
var relleno_por_lado: float = 0.0

static func calcular(sala: SalaDef, indice_socket: int, destino_pos: Vector3, destino_dir: Direcciones.Dir, ancho_destino: float, destino_rotacion_pared: float = INF) -> Colocacion:
	var c := Colocacion.new()
	var socket: SocketDef = sala.sockets[indice_socket]
	var rotacion_pared_local := socket.rotacion_pared if socket.arista >= 0 else -float(socket.direccion) * PI / 2.0
	var rotacion_pared_destino := destino_rotacion_pared
	if is_inf(rotacion_pared_destino):
		rotacion_pared_destino = -float(destino_dir) * PI / 2.0
	# En contornos convexos CCW, aristas de salas enfrentadas tienen normales opuestas.
	c.angulo_y = rotacion_pared_destino + PI - rotacion_pared_local
	c.giros = posmod(roundi(-c.angulo_y / (PI * 0.5)), 4)
	var posicion_socket := socket.posicion_local.rotated(Vector3.UP, c.angulo_y)
	c.origen = destino_pos - posicion_socket
	var puntos_mundo := PackedVector2Array()
	for punto in sala.obtener_huella_local():
		var rotado := punto.rotated(-c.angulo_y)
		puntos_mundo.append(Vector2(c.origen.x + rotado.x, c.origen.z + rotado.y))
	c.huella_mundo = GeometriaHuella.normalizar(puntos_mundo)
	c.rectangulo = GeometriaHuella.limites(c.huella_mundo)
	c.ancho_pasaje = minf(socket.ancho, ancho_destino)
	c.relleno_por_lado = (maxf(socket.ancho, ancho_destino) - c.ancho_pasaje) * 0.5
	return c
