class_name CierresSala
extends RefCounted
## Paneles que tapan los huecos que quedan cuando dos módulos unidos por una
## puerta tienen alturas distintas. Misma forma que los de escenario_generado.gd.

## Altura de las puertas (la misma que usa sala_modular.gd).
const ALTO_PUERTA := 2.45
const GROSOR := 0.2


## Tapa, sobre la puerta de "sala", el tramo entre la abertura baja y la alta.
## Se usa cuando las dos puertas de una unión miden distinto de alto.
static func panel_sobre_puerta(sala: Node3D, socket: SocketDef, alto_bajo: float, alto_alto: float) -> void:
	var alto_panel := alto_alto - alto_bajo
	var cuerpo := _crear_cuerpo("PanelSobrePuerta", Vector3(socket.ancho, alto_panel, GROSOR))
	cuerpo.position = socket.posicion_local + Vector3.UP * (alto_bajo + alto_panel * 0.5)
	cuerpo.rotation.y = _rotacion_socket(socket)
	sala.add_child(cuerpo)


## Cuando se quita toda la pared entre un módulo bajo y uno alto, tapa el tramo
## de pared del módulo alto que queda por encima del techo del bajo.
## "sala" y "definicion" son los del módulo BAJO.
static func cierre_pared_completa(sala: Node3D, socket: SocketDef, definicion: SalaDef, alto_bajo: float, alto_alto: float) -> void:
	var alto_panel := alto_alto - alto_bajo
	var indice_arista := definicion.obtener_arista_socket(socket)
	if indice_arista < 0:
		return
	var huella := definicion.obtener_huella_local()
	var inicio := huella[indice_arista]
	var fin := huella[(indice_arista + 1) % huella.size()]
	var largo_pared := inicio.distance_to(fin)
	var centro_pared := (inicio + fin) * 0.5
	var tamano := Vector3(largo_pared, alto_panel, GROSOR)
	var cuerpo := _crear_cuerpo("CierreSuperiorAberturaCompleta", tamano)
	cuerpo.position = Vector3(centro_pared.x, alto_bajo + alto_panel * 0.5, centro_pared.y)
	cuerpo.rotation.y = _rotacion_socket(socket)
	sala.add_child(cuerpo)

static func _rotacion_socket(socket: SocketDef) -> float:
	if socket.arista >= 0:
		return socket.rotacion_pared
	if socket.rotacion_radial >= 0.0:
		return -socket.rotacion_radial
	return -socket.direccion * PI / 2.0


static func _crear_cuerpo(nombre: String, tamano: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	var forma := BoxShape3D.new()
	forma.size = tamano
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	visual.mesh = malla
	cuerpo.add_child(visual)
	return cuerpo
