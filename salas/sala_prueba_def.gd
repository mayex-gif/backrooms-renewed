extends SalaDef
## Recurso de definición para la sala modular de demostración.

func _init() -> void:
	nombre = "SalaPrueba5x5"
	escena = load("res://salas/sala_prueba.tscn")
	peso = 100.0
	ancho_m = 5.0
	largo_m = 5.0
	var puerta := SocketDef.new()
	puerta.posicion_local = Vector3(2.5, 0.0, 0.0)
	puerta.direccion = Direcciones.Dir.NORTE
	puerta.ancho = 2.5
	var puerta_sur := SocketDef.new()
	puerta_sur.posicion_local = Vector3(2.5, 0.0, 5.0)
	puerta_sur.direccion = Direcciones.Dir.SUR
	puerta_sur.ancho = 2.5
	sockets = [puerta, puerta_sur]
