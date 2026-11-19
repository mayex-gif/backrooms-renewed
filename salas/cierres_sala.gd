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
	cuerpo.rotation.y = -socket.direccion * PI / 2.0
	sala.add_child(cuerpo)


## Cuando se quita toda la pared entre un módulo bajo y uno alto, tapa el tramo
## de pared del módulo alto que queda por encima del techo del bajo.
## "sala" y "definicion" son los del módulo BAJO.
static func cierre_pared_completa(sala: Node3D, socket: SocketDef, definicion: SalaDef, alto_bajo: float, alto_alto: float) -> void:
	var horizontal := socket.direccion == Direcciones.Dir.NORTE or socket.direccion == Direcciones.Dir.SUR
	var largo_pared := definicion.ancho_m if horizontal else definicion.largo_m
	var alto_panel := alto_alto - alto_bajo
	var tamano := Vector3(largo_pared, alto_panel, GROSOR) if horizontal else Vector3(GROSOR, alto_panel, largo_pared)
	var cuerpo := _crear_cuerpo("CierreSuperiorAberturaCompleta", tamano)
	if horizontal:
		cuerpo.position = Vector3(largo_pared * 0.5, alto_bajo + alto_panel * 0.5, socket.posicion_local.z)
	else:
		cuerpo.position = Vector3(socket.posicion_local.x, alto_bajo + alto_panel * 0.5, largo_pared * 0.5)
	sala.add_child(cuerpo)


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
