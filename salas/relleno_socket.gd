class_name RellenoSocket
extends Node3D
## Reduce visual y físicamente una abertura ancha a un pasaje centrado más estrecho.
## El eje X local cruza el ancho de la pared; el eje Z es su profundidad.

@export_range(0.1, 20.0, 0.1) var ancho_hueco: float = 2.5
@export_range(0.1, 20.0, 0.1) var ancho_pasaje: float = 1.5
@export_range(0.5, 5.0, 0.1) var altura: float = 2.2
@export_range(0.05, 1.0, 0.05) var profundidad: float = 0.2
@export var sellado := false

func _ready() -> void:
	if ancho_hueco <= 0.0 or ancho_pasaje <= 0.0 or ancho_pasaje > ancho_hueco:
		push_error("RellenoSocket requiere 0 < ancho_pasaje <= ancho_hueco.")
		return
	if sellado:
		_crear_bloque(0.0, ancho_hueco, altura)
		return
	var sobra := (ancho_hueco - ancho_pasaje) * 0.5
	if sobra <= 0.001:
		return
	var centro_lateral := (ancho_hueco + ancho_pasaje) * 0.25
	_crear_bloque(-centro_lateral, sobra, altura)
	_crear_bloque(centro_lateral, sobra, altura)

func _crear_bloque(x: float, ancho: float, alto_bloque: float) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "RellenoLateral"
	cuerpo.position = Vector3(x, alto_bloque * 0.5, 0.0)
	var forma := BoxShape3D.new()
	forma.size = Vector3(ancho, alto_bloque, profundidad)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
	var malla := BoxMesh.new()
	malla.size = forma.size
	var visual := MeshInstance3D.new()
	visual.mesh = malla
	cuerpo.add_child(visual)
	add_child(cuerpo)
